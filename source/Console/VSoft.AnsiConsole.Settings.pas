unit VSoft.AnsiConsole.Settings;

{
  TAnsiConsoleSettings - Spectre-style settings record + factory.

  Detection-by-default model: each Ansi/ColorSystem/Interactive field is a
  three-state enum (Detect / On / Off). For the Detect values we run the
  matching probe in VSoft.AnsiConsole.Detection; for On/Off we honour the
  override as-is.

  When `Enrichment` is True (default) the resulting capabilities are then
  walked through the CI enrichers from VSoft.AnsiConsole.Enrichment, which
  typically clear Interactive on hosted runners.

  CreateAnsiConsoleFromSettings builds and returns a fully wired IAnsiConsole.
}

interface

uses
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Capabilities,
  VSoft.AnsiConsole.Rendering.AnsiWriter,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Enrichment;

type
  TAnsiConsoleSettings = record
  public
    Ansi        : TAnsiSupport;
    ColorSystem : TColorSystemSupport;
    Interactive : TInteractionSupport;
    { When non-nil, this is wired as the console output. When nil, the
      factory falls back to the platform default (stdout on Windows,
      currently the only supported platform). }
    Output      : IAnsiOutput;
    { When True (default), DefaultEnrichers run after detection so common
      CI envs (GitHub Actions, Travis, ...) automatically disable the
      Interactive flag. Set False to opt out entirely. }
    Enrichment  : Boolean;
    { Optional list of custom enrichers. nil/empty => use DefaultEnrichers.
      Ignored entirely when Enrichment is False. }
    Enrichers   : TArray<IProfileEnricher>;
    { Width / Height. <= 0 means "auto-detect from console". }
    Width       : Integer;
    Height      : Integer;
    class function Default : TAnsiConsoleSettings; static;
  end;

{ Builds capabilities by running detection probes for any Detect-marked
  field of `settings`, applying any non-Detect overrides, then optionally
  running enrichers. Pure - does not touch console output. }
function BuildCapabilities(const settings : TAnsiConsoleSettings) : TCapabilities;

{ Builds and returns an IAnsiConsole using the rules above. }
function CreateAnsiConsoleFromSettings(const settings : TAnsiConsoleSettings) : IAnsiConsole;

implementation

uses
  VSoft.AnsiConsole.Detection;

class function TAnsiConsoleSettings.Default : TAnsiConsoleSettings;
begin
  result.Ansi        := TAnsiSupport.Detect;
  result.ColorSystem := TColorSystemSupport.Detect;
  result.Interactive := TInteractionSupport.Detect;
  result.Output      := nil;
  result.Enrichment  := True;
  SetLength(result.Enrichers, 0);
  result.Width       := 0;
  result.Height      := 0;
end;

function ColorSystemSupportToColorSystem(value : TColorSystemSupport) : TColorSystem;
begin
  case value of
    TColorSystemSupport.NoColors  : result := TColorSystem.NoColors;
    TColorSystemSupport.Legacy    : result := TColorSystem.Legacy;
    TColorSystemSupport.Standard  : result := TColorSystem.Standard;
    TColorSystemSupport.EightBit      : result := TColorSystem.EightBit;
    TColorSystemSupport.TrueColor : result := TColorSystem.TrueColor;
  else
    result := TColorSystem.Standard;  // TColorSystemSupport.Detect handled by caller
  end;
end;

function BuildCapabilities(const settings : TAnsiConsoleSettings) : TCapabilities;
var
  ansi        : Boolean;
  interactive : Boolean;
  unicode     : Boolean;
  legacy      : Boolean;
  color       : TColorSystem;
  enrichers   : TArray<IProfileEnricher>;
begin
  // ANSI support
  case settings.Ansi of
    TAnsiSupport.On  : ansi := True;
    TAnsiSupport.Off : ansi := False;
  else
    ansi := DetectAnsiSupport;
  end;

  // Color system
  if settings.ColorSystem = TColorSystemSupport.Detect then
  begin
    if ansi then
      color := DetectColorSystem
    else
      color := TColorSystem.NoColors;
  end
  else
    color := ColorSystemSupportToColorSystem(settings.ColorSystem);

  // Interactive
  case settings.Interactive of
    TInteractionSupport.On  : interactive := True;
    TInteractionSupport.Off : interactive := False;
  else
    interactive := DetectInteractive;
  end;

  // Unicode + legacy console flag are always probed - no override.
  unicode := DetectUnicode;
  legacy  := DetectLegacyConsole;

  result := TCapabilities.Create(color, ansi, unicode, interactive);
  result := result.WithIsLegacyConsole(legacy);
  result := result.WithLinks(DetectLinks(ansi));

  if settings.Enrichment then
  begin
    enrichers := settings.Enrichers;
    if Length(enrichers) = 0 then
      enrichers := DefaultEnrichers;
    result := ApplyEnrichers(result, enrichers);
  end;
end;

function CreateAnsiConsoleFromSettings(const settings : TAnsiConsoleSettings) : IAnsiConsole;
var
  caps  : TCapabilities;
  out_  : IAnsiOutput;
  w, h  : Integer;
begin
  caps := BuildCapabilities(settings);

  out_ := settings.Output;
  if out_ = nil then
  begin
    // Fall through to the default console factory; it constructs the
    // appropriate platform-default output and probes width/height.
    result := CreateDefaultAnsiConsole;
    result.Profile.Capabilities := caps;
    if settings.Width > 0 then
      result.Profile.Width := settings.Width;
    if settings.Height > 0 then
      result.Profile.Height := settings.Height;
    Exit;
  end;

  w := settings.Width;
  h := settings.Height;
  if w <= 0 then w := 80;
  if h <= 0 then h := 24;
  result := CreateAnsiConsole(out_, caps, w, h);
end;

end.
