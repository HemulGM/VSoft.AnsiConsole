unit VSoft.AnsiConsole.Console;

{
  IAnsiConsole - the public interface to a rich-output console. One instance
  per output sink; the facade (`AnsiConsole` in VSoft.AnsiConsole.pas) caches
  a default instance that writes to stdout.

  TDefaultAnsiConsole wires up:
    - a Win32 stdout sink (TWin32StdOutput) that uses WriteConsoleW for
      console output and WriteFile for redirected output.
    - a Profile built from detected capabilities.
    - a TAnsiWriter for segment-to-ANSI emission.
    - a pass-through RenderPipeline.

  Thread-safety: a critical section guards the write path. Phase 5 will
  formalise this as an exclusivity mode for live display.

  Phase 1 is Windows-only; POSIX arrives in Phase 7.
}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Rendering.AnsiWriter,
  VSoft.AnsiConsole.Capabilities,
  VSoft.AnsiConsole.Profile,
  VSoft.AnsiConsole.Input;

type
  IAnsiConsole = interface
    ['{C6F5A1FE-68B2-4E6C-9B2E-7FD6A4E1A84B}']
    function  GetProfile : IProfile;
    function  GetPipeline : IRenderPipeline;
    function  GetInput : IConsoleInput;
    procedure SetInput(const value : IConsoleInput);

    procedure Write(const renderable : IRenderable); overload;
    procedure Write(const segs : TAnsiSegments); overload;
    procedure WriteLine; overload;
    procedure WriteLine(const renderable : IRenderable); overload;
    procedure Clear(home : Boolean = True);

    property Profile  : IProfile        read GetProfile;
    property Pipeline : IRenderPipeline read GetPipeline;
    property Input    : IConsoleInput   read GetInput write SetInput;
  end;

{ Factory - builds a console using auto-detected capabilities, wired to
  the process's standard output. }
function CreateDefaultAnsiConsole : IAnsiConsole;

{ Factory - builds a console with a user-supplied output (useful for tests
  or for redirecting to files/streams). }
function CreateAnsiConsole(const output : IAnsiOutput;
                             const caps : TCapabilities;
                             width, height : Integer) : IAnsiConsole;

implementation

uses
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Detection
  {$IFDEF MSWINDOWS}, Winapi.Windows{$ENDIF};

type
  TAnsiConsoleImpl = class(TInterfacedObject, IAnsiConsole)
  strict private
    FProfile  : IProfile;
    FWriter   : IAnsiWriter;
    FPipeline : IRenderPipeline;
    FInput    : IConsoleInput;
    FLock     : TCriticalSection;
    FOwnedDim : Boolean; // if true, refresh width/height from live console

    procedure RefreshDimensions;
    function  BuildRenderOptions : TRenderOptions;
    function  GetProfile : IProfile;
    function  GetPipeline : IRenderPipeline;
    function  GetInput : IConsoleInput;
    procedure SetInput(const value : IConsoleInput);
  public
    constructor Create(const profile : IProfile; autoRefreshDimensions : Boolean);
    destructor Destroy; override;

    procedure Write(const renderable : IRenderable); overload;
    procedure Write(const segs : TAnsiSegments); overload;
    procedure WriteLine; overload;
    procedure WriteLine(const renderable : IRenderable); overload;
    procedure Clear(home : Boolean = True);
  end;

{$IFDEF MSWINDOWS}
type
  TWin32StdOutput = class(TInterfacedObject, IAnsiOutput)
  strict private
    FHandle : THandle;
    FIsConsole : Boolean;
    FEnsuredVt : Boolean;
    procedure EnsureVirtualTerminal;
  public
    constructor Create;
    procedure Write(const s : string);
    procedure Flush;
  end;

constructor TWin32StdOutput.Create;
var
  mode : DWORD;
begin
  inherited Create;
  FHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  FIsConsole := (FHandle <> INVALID_HANDLE_VALUE) and GetConsoleMode(FHandle, mode);
  EnsureVirtualTerminal;
  // Match what modern console apps (Python, Rich, .NET 6+) do: switch the
  // console output code page to UTF-8 once at startup, then write UTF-8
  // bytes via WriteFile. Windows Terminal's emoji shaper composes flag
  // pairs and other multi-codepoint sequences correctly along this path,
  // whereas the WriteConsoleW (UTF-16) path leaves regional indicator
  // pairs uncomposed on some font/system combinations.
  if FIsConsole then
    SetConsoleOutputCP(65001);   // CP_UTF8
end;

procedure TWin32StdOutput.EnsureVirtualTerminal;
const
  ENABLE_VIRTUAL_TERMINAL_PROCESSING = $0004;
var
  mode : DWORD;
begin
  if FEnsuredVt then
    Exit;
  FEnsuredVt := True;
  if not FIsConsole then
    Exit;
  if GetConsoleMode(FHandle, mode) then
  begin
    if (mode and ENABLE_VIRTUAL_TERMINAL_PROCESSING) = 0 then
      SetConsoleMode(FHandle, mode or ENABLE_VIRTUAL_TERMINAL_PROCESSING);
  end;
end;

procedure TWin32StdOutput.Write(const s : string);
var
  written : DWORD;
  bytes   : TBytes;
begin
  if s = '' then Exit;

  // Always encode as UTF-8 and write via WriteFile. We set the console
  // output code page to UTF-8 in the constructor, so this works for both
  // an attached console and a redirected handle. The previous WriteConsoleW
  // path mis-rendered some grapheme clusters (regional indicator pairs
  // for flag emoji, in particular) on Windows Terminal.
  bytes := TEncoding.UTF8.GetBytes(s);
  if Length(bytes) > 0 then
    WriteFile(FHandle, bytes[0], Length(bytes), written, nil);
end;

procedure TWin32StdOutput.Flush;
begin
  if FIsConsole then
    Exit;
  FlushFileBuffers(FHandle);
end;

function GetConsoleDimensions(out width, height : Integer) : Boolean;
var
  h    : THandle;
  info : TConsoleScreenBufferInfo;
begin
  h := GetStdHandle(STD_OUTPUT_HANDLE);
  if (h = INVALID_HANDLE_VALUE) or not GetConsoleScreenBufferInfo(h, info) then
  begin
    width := 80;
    height := 24;
    result := False;
    Exit;
  end;
  width := info.srWindow.Right - info.srWindow.Left + 1;
  height := info.srWindow.Bottom - info.srWindow.Top + 1;
  if width <= 0 then width := 80;
  if height <= 0 then height := 24;
  result := True;
end;
{$ENDIF}

{ TAnsiConsoleImpl }

constructor TAnsiConsoleImpl.Create(const profile : IProfile; autoRefreshDimensions : Boolean);
begin
  inherited Create;
  FProfile  := profile;
  FWriter   := TAnsiWriter.Create(profile.Output);
  FPipeline := CreateRenderPipeline;
  FInput    := CreateDefaultConsoleInput;
  FLock     := TCriticalSection.Create;
  FOwnedDim := autoRefreshDimensions;
end;

destructor TAnsiConsoleImpl.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure TAnsiConsoleImpl.RefreshDimensions;
{$IFDEF MSWINDOWS}
var
  w, h : Integer;
{$ENDIF}
begin
  if not FOwnedDim then
    Exit;
  {$IFDEF MSWINDOWS}
  if GetConsoleDimensions(w, h) then
  begin
    FProfile.Width := w;
    FProfile.Height := h;
  end;
  {$ENDIF}
end;

function TAnsiConsoleImpl.BuildRenderOptions : TRenderOptions;
var
  caps : TCapabilities;
begin
  caps := FProfile.Capabilities;
  result := TRenderOptions.Create(FProfile.Width, FProfile.Height, caps.ColorSystem);
  result := result.WithLegacyConsole(caps.IsLegacyConsole);
  result := result.WithUnicode(caps.Unicode);
  result := result.WithInteractive(caps.Interactive);
  result := result.WithSupportsLinks(caps.Links);
end;

function TAnsiConsoleImpl.GetProfile : IProfile;
begin
  result := FProfile;
end;

function TAnsiConsoleImpl.GetPipeline : IRenderPipeline;
begin
  result := FPipeline;
end;

function TAnsiConsoleImpl.GetInput : IConsoleInput;
begin
  result := FInput;
end;

procedure TAnsiConsoleImpl.SetInput(const value : IConsoleInput);
begin
  if value <> nil then
    FInput := value
  else
    FInput := CreateDefaultConsoleInput;
end;

procedure TAnsiConsoleImpl.Write(const renderable : IRenderable);
var
  options : TRenderOptions;
  items   : TRenderables;
  segs    : TAnsiSegments;
  i       : Integer;
begin
  if renderable = nil then
    Exit;

  FLock.Enter;
  try
    RefreshDimensions;
    options := BuildRenderOptions;

    SetLength(items, 1);
    items[0] := renderable;
    items := FPipeline.Process(options, items);

    for i := 0 to High(items) do
    begin
      segs := items[i].Render(options, options.Width);
      FWriter.WriteSegments(segs, options);
    end;
    FWriter.Reset;
    FWriter.Flush;
  finally
    FLock.Leave;
  end;
end;

procedure TAnsiConsoleImpl.Write(const segs : TAnsiSegments);
var
  options : TRenderOptions;
begin
  FLock.Enter;
  try
    RefreshDimensions;
    options := BuildRenderOptions;
    FWriter.WriteSegments(segs, options);
    FWriter.Reset;
    FWriter.Flush;
  finally
    FLock.Leave;
  end;
end;

procedure TAnsiConsoleImpl.WriteLine;
var
  segs : TAnsiSegments;
begin
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.LineBreak;
  Write(segs);
end;

procedure TAnsiConsoleImpl.WriteLine(const renderable : IRenderable);
var
  segs : TAnsiSegments;
begin
  Write(renderable);
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.LineBreak;
  Write(segs);
end;

procedure TAnsiConsoleImpl.Clear(home : Boolean);
var
  segs : TAnsiSegments;
begin
  SetLength(segs, 1);
  if home then
    segs[0] := TAnsiSegment.ControlCode(ESC + '[2J' + ESC + '[H')
  else
    segs[0] := TAnsiSegment.ControlCode(ESC + '[2J');
  Write(segs);
end;

{ Factories }

function CreateDefaultAnsiConsole : IAnsiConsole;
var
  output  : IAnsiOutput;
  caps    : TCapabilities;
  profile : IProfile;
  w, h    : Integer;
begin
  {$IFDEF MSWINDOWS}
  output := TWin32StdOutput.Create;
  caps   := DetectCapabilities;
  if not GetConsoleDimensions(w, h) then
  begin
    w := 80;
    h := 24;
  end;
  profile := TProfile.Create(output, caps, w, h);
  result := TAnsiConsoleImpl.Create(profile, True);
  {$ELSE}
  raise ENotSupportedException.Create('VSoft.AnsiConsole Phase 1 supports Windows only.');
  {$ENDIF}
end;

function CreateAnsiConsole(const output : IAnsiOutput;
                             const caps : TCapabilities;
                             width, height : Integer) : IAnsiConsole;
var
  profile : IProfile;
begin
  profile := TProfile.Create(output, caps, width, height);
  result := TAnsiConsoleImpl.Create(profile, False);
end;

end.
