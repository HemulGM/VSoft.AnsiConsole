unit VSoft.AnsiConsole.Rendering.AnsiWriter;

{
  TAnsiWriter - emits ANSI/SGR/OSC escape sequences for segment arrays,
  honouring the color system and unicode capabilities declared in
  TRenderOptions.

  Output strategy (simple but correct): when a segment's style differs from
  the currently-emitted style, emit SGR 0 (full reset) and then emit the new
  style's full code set. This wastes a few bytes vs. diff-based emission but
  keeps the implementation small and provably correct.
}

interface

uses
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Rendering;

type
  { Minimal output sink abstraction. TAnsiWriter does not know or care whether
    the other end is a console, a redirected stream, or a test string buffer. }
  IAnsiOutput = interface
    ['{4DD5C56A-9A38-4F27-A3F5-2CD9AE5C6A1C}']
    procedure Write(const s : string);
    procedure Flush;
  end;

  IAnsiWriter = interface
    ['{A6E6F3F6-1C95-4A74-B2A7-1A1E27D47F12}']
    procedure WriteSegment(const seg : TAnsiSegment; const options : TRenderOptions);
    procedure WriteSegments(const segs : TAnsiSegments; const options : TRenderOptions);
    procedure Reset;
    procedure Flush;
    function  Output : IAnsiOutput;
  end;

  TAnsiWriter = class(TInterfacedObject, IAnsiWriter)
  strict private
    FOutput  : IAnsiOutput;
    FCurrent : TAnsiStyle;   // style currently in effect on the wire
    FLinkId  : Integer;
    FInLink  : Boolean;

    procedure EmitRaw(const s : string);
    procedure EmitSGRReset;
    procedure ApplyStyle(const target : TAnsiStyle; const options : TRenderOptions);
    procedure BeginLink(const url : string);
    procedure EndLink;
  public
    constructor Create(const output : IAnsiOutput);

    procedure WriteSegment(const seg : TAnsiSegment; const options : TRenderOptions);
    procedure WriteSegments(const segs : TAnsiSegments; const options : TRenderOptions);
    procedure Reset;
    procedure Flush;
    function  Output : IAnsiOutput;
  end;

{ Low-level code builders - exposed for testability. }
function BuildDecorationCodes(const decorations : TAnsiDecorations) : string;
function BuildForegroundCode(const c : TAnsiColor; const options : TRenderOptions) : string;
function BuildBackgroundCode(const c : TAnsiColor; const options : TRenderOptions) : string;
function BuildStyleCodes(const style : TAnsiStyle; const options : TRenderOptions) : string;

const
  ESC = #27;
  ST  = #27'\';    // String Terminator for OSC
  BEL = #7;

implementation

uses
  System.SysUtils;

function DecorationSGR(d : TAnsiDecoration) : Integer;
begin
  case d of
    TAnsiDecoration.Bold          : result := 1;
    TAnsiDecoration.Dim           : result := 2;
    TAnsiDecoration.Italic        : result := 3;
    TAnsiDecoration.Underline     : result := 4;
    TAnsiDecoration.SlowBlink     : result := 5;
    TAnsiDecoration.RapidBlink    : result := 6;
    TAnsiDecoration.Invert        : result := 7;
    TAnsiDecoration.Conceal       : result := 8;
    TAnsiDecoration.Strikethrough : result := 9;
  else
    result := 0;
  end;
end;

function BuildDecorationCodes(const decorations : TAnsiDecorations) : string;
var
  d     : TAnsiDecoration;
  first : Boolean;
begin
  result := '';
  first := True;
  for d := Low(TAnsiDecoration) to High(TAnsiDecoration) do
  begin
    if d in decorations then
    begin
      if first then
        first := False
      else
        result := result + ';';
      result := result + IntToStr(DecorationSGR(d));
    end;
  end;
end;

function ClosestLevel(v : Byte) : Integer;
const
  LEVELS : array[0..5] of Integer = (0, 95, 135, 175, 215, 255);
var
  i    : Integer;
  best : Integer;
  d, bestDist : Integer;
begin
  best := 0;
  bestDist := MaxInt;
  for i := 0 to 5 do
  begin
    d := Abs(Integer(v) - LEVELS[i]);
    if d < bestDist then
    begin
      bestDist := d;
      best := i;
    end;
  end;
  result := best;
end;

function QuantizeRGBTo256(r, g, b : Byte) : Byte;
var
  rr, gg, bb : Integer;
begin
  // map each channel to 6-level cube {0,95,135,175,215,255}, index 16 + 36*r + 6*g + b
  rr := ClosestLevel(r);
  gg := ClosestLevel(g);
  bb := ClosestLevel(b);
  result := Byte(16 + rr * 36 + gg * 6 + bb);
end;

function BuildColorCode(const c : TAnsiColor; const options : TRenderOptions;
                         isForeground : Boolean) : string;
var
  effective : TAnsiColor;
  idx       : Integer;
  base      : Integer;
begin
  result := '';
  if c.IsDefault then
    Exit;

  case options.ColorSystem of
    TColorSystem.NoColors:
      Exit;

    TColorSystem.Legacy, TColorSystem.Standard:
      begin
        effective := c.ToNearest(options.ColorSystem);
        idx := effective.Number;
        if idx < 0 then
          Exit;
        if isForeground then
          base := 30
        else
          base := 40;
        if idx < 8 then
          result := IntToStr(base + idx)
        else
          // bright: 90..97 (fg) or 100..107 (bg)
          result := IntToStr(base + 60 + (idx - 8));
      end;

    TColorSystem.EightBit:
      begin
        if c.HasPaletteIndex then
          idx := c.Number
        else
          idx := QuantizeRGBTo256(c.R, c.G, c.B);
        if isForeground then
          result := '38;5;' + IntToStr(idx)
        else
          result := '48;5;' + IntToStr(idx);
      end;

    TColorSystem.TrueColor:
      begin
        if isForeground then
          result := Format('38;2;%d;%d;%d', [c.R, c.G, c.B])
        else
          result := Format('48;2;%d;%d;%d', [c.R, c.G, c.B]);
      end;
  end;
end;

function BuildForegroundCode(const c : TAnsiColor; const options : TRenderOptions) : string;
begin
  result := BuildColorCode(c, options, True);
end;

function BuildBackgroundCode(const c : TAnsiColor; const options : TRenderOptions) : string;
begin
  result := BuildColorCode(c, options, False);
end;

function AppendCode(const current, extra : string) : string;
begin
  if extra = '' then
    result := current
  else if current = '' then
    result := extra
  else
    result := current + ';' + extra;
end;

function BuildStyleCodes(const style : TAnsiStyle; const options : TRenderOptions) : string;
var
  codes : string;
begin
  codes := '';
  if options.ColorSystem <> TColorSystem.NoColors then
  begin
    codes := AppendCode(codes, BuildDecorationCodes(style.Decorations));
    codes := AppendCode(codes, BuildForegroundCode(style.Foreground, options));
    codes := AppendCode(codes, BuildBackgroundCode(style.Background, options));
  end;
  result := codes;
end;

{ TAnsiWriter }

constructor TAnsiWriter.Create(const output : IAnsiOutput);
begin
  inherited Create;
  FOutput  := output;
  FCurrent := TAnsiStyle.Plain;
  FLinkId  := 0;
  FInLink  := False;
end;

procedure TAnsiWriter.EmitRaw(const s : string);
begin
  if s <> '' then
    FOutput.Write(s);
end;

procedure TAnsiWriter.EmitSGRReset;
begin
  EmitRaw(ESC + '[0m');
end;

procedure TAnsiWriter.ApplyStyle(const target : TAnsiStyle; const options : TRenderOptions);
var
  codes : string;
begin
  // Under TColorSystem.NoColors we never emit escape sequences and must not update
  // FCurrent either - doing so would fool Reset into emitting ESC[0m despite
  // nothing having been written.
  if options.ColorSystem = TColorSystem.NoColors then
    Exit;

  if target.Equals(FCurrent) then
    Exit;

  // Closing-out order matches Spectre's wire format: SGR reset first, then
  // OSC 8 close. Windows Terminal treats the OSC 8 boundary as the link
  // grouping anchor; running styles into the close (or styles between an
  // open and the text) breaks WT's clickable-link detection.
  if not FCurrent.IsPlain then
    EmitSGRReset;
  if FInLink and (target.Link <> FCurrent.Link) then
    EndLink;

  // Open the new link BEFORE emitting SGR codes so the OSC 8 wraps the
  // styled text, mirroring Spectre's emission order.
  if options.SupportsLinks and not FInLink and (target.Link <> '') then
    BeginLink(target.Link);

  codes := BuildStyleCodes(target, options);
  if codes <> '' then
    EmitRaw(ESC + '[' + codes + 'm');

  FCurrent := target;
end;

procedure TAnsiWriter.BeginLink(const url : string);
begin
  // Always include `id=N`. Without an id parameter Windows Terminal accepts
  // the OSC 8 sequence but won't make the wrapped text clickable - it treats
  // the run as un-grouped style state. Spectre's `Link` class makes the same
  // call: every link gets a unique id so multi-cell text registers as one
  // hyperlink rather than per-cell fragments.
  Inc(FLinkId);
  EmitRaw(ESC + ']8;id=' + IntToStr(FLinkId) + ';' + url + ST);
  FInLink := True;
end;

procedure TAnsiWriter.EndLink;
begin
  if FInLink then
  begin
    EmitRaw(ESC + ']8;;' + ST);
    FInLink := False;
  end;
end;

procedure TAnsiWriter.WriteSegment(const seg : TAnsiSegment; const options : TRenderOptions);
begin
  if seg.IsLineBreak then
  begin
    // SGR reset BEFORE OSC 8 close, matching Spectre: WT only registers
    // the hyperlink when the styled text and its OSC 8 close are emitted
    // in this order.
    if not FCurrent.IsPlain then
    begin
      EmitSGRReset;
      FCurrent := TAnsiStyle.Plain;
    end;
    if FInLink then
      EndLink;
    EmitRaw(sLineBreak);
    Exit;
  end;

  if seg.IsControlCode then
  begin
    EmitRaw(seg.Value);
    Exit;
  end;

  ApplyStyle(seg.Style, options);
  EmitRaw(seg.Value);
end;

procedure TAnsiWriter.WriteSegments(const segs : TAnsiSegments; const options : TRenderOptions);
var
  i : Integer;
begin
  for i := 0 to High(segs) do
    WriteSegment(segs[i], options);
end;

procedure TAnsiWriter.Reset;
begin
  // SGR reset before OSC 8 close - same ordering as the linebreak handler.
  if not FCurrent.IsPlain then
  begin
    EmitSGRReset;
    FCurrent := TAnsiStyle.Plain;
  end;
  if FInLink then
    EndLink;
end;

procedure TAnsiWriter.Flush;
begin
  if FOutput <> nil then
    FOutput.Flush;
end;

function TAnsiWriter.Output : IAnsiOutput;
begin
  result := FOutput;
end;

end.
