unit VSoft.AnsiConsole.Recorder;

{
  IRecorder - IAnsiConsole decorator that captures every `Write(IRenderable)`
  call and can export the recorded stream via a pluggable encoder.

  Built-in encoders:
    TextEncoder  - plain text (renders each renderable through a TColorSystem.NoColors
                   console and concatenates the output).
    HtmlEncoder  - inline-styled HTML inside a <pre> block; segment styles
                   become <span style="..."> CSS.

  Custom encoders implement IAnsiConsoleEncoder and are passed to
  IRecorder.Export(encoder). The encoder receives the captured profile +
  the IRenderable stream and returns the encoded string.

  Usage:

    rec := Recorder(AnsiConsole.Console);
    rec.Write(Markup('[red]hello[/]'));
    text := rec.ExportText;                    // backwards-compatible
    html := rec.ExportHtml;                    // backwards-compatible
    json := rec.Export(MyJsonEncoder);         // pluggable

  The recorder forwards every write to the wrapped console, so recording is
  transparent from the user's perspective.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Rendering.AnsiWriter,
  VSoft.AnsiConsole.Profile,
  VSoft.AnsiConsole.Capabilities,
  VSoft.AnsiConsole.Input,
  VSoft.AnsiConsole.Console;

type
  { Pluggable encoder for IRecorder.Export. Implementations walk the
    recorded IRenderable stream and produce a string in their target
    format (text, HTML, JSON, SVG, ...). }
  IAnsiConsoleEncoder = interface
    ['{F4A2C1D8-7B6E-4F51-9C03-2E5D8B4F1A60}']
    function Encode(const profile : IProfile;
                     const recorded : TArray<IRenderable>) : string;
  end;

  IRecorder = interface(IAnsiConsole)
    ['{7B3F1D4C-9A2E-4F5A-B6D8-3C2E1F0A4B50}']
    function ExportText : string;
    function ExportHtml : string;
    function Export(const encoder : IAnsiConsoleEncoder) : string;
    procedure Reset;
  end;

  TRecorder = class(TInterfacedObject, IAnsiConsole, IRecorder)
  strict private
    FInner    : IAnsiConsole;
    FRecorded : TList<IRenderable>;
    function SnapshotRecorded : TArray<IRenderable>;
  public
    constructor Create(const inner : IAnsiConsole);
    destructor  Destroy; override;

    { IAnsiConsole - delegate to FInner except Write(IRenderable) which also records. }
    function  GetProfile : IProfile;
    function  GetPipeline : IRenderPipeline;
    function  GetInput : IConsoleInput;
    procedure SetInput(const value : IConsoleInput);
    procedure Write(const renderable : IRenderable); overload;
    procedure Write(const segs : TAnsiSegments); overload;
    procedure WriteLine; overload;
    procedure WriteLine(const renderable : IRenderable); overload;
    procedure Clear(home : Boolean = True);

    { IRecorder }
    function ExportText : string;
    function ExportHtml : string;
    function Export(const encoder : IAnsiConsoleEncoder) : string;
    procedure Reset;
  end;

function Recorder(const inner : IAnsiConsole) : IRecorder;

{ Built-in encoder factories. Both are stateless and can be reused
  across multiple Export calls. }
function TextEncoder : IAnsiConsoleEncoder;
function HtmlEncoder : IAnsiConsoleEncoder;

implementation

uses
  VSoft.AnsiConsole.Measurement;

{ Renderable that emits a single line-break segment. Used by WriteLine /
  WriteLine(renderable) so the recorded stream captures the trailing
  newline that the inner console emits. Without this, exports would join
  consecutive Write(...) + WriteLine results onto the same line. }
type
  TLineBreakRenderable = class(TInterfacedObject, IRenderable)
  public
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
  end;

function TLineBreakRenderable.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
begin
  result := TMeasurement.Create(0, 0);
end;

function TLineBreakRenderable.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
begin
  SetLength(result, 1);
  result[0] := TAnsiSegment.LineBreak;
end;

{ Minimal in-memory IAnsiOutput used by the text encoder to capture the
  rendered stream without touching the real terminal. }
type
  TCaptureOutput = class(TInterfacedObject, IAnsiOutput)
  strict private
    FBuffer : TStringBuilder;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Write(const s : string);
    procedure Flush;
    function  Text : string;
  end;

constructor TCaptureOutput.Create;
begin
  inherited Create;
  FBuffer := TStringBuilder.Create;
end;

destructor TCaptureOutput.Destroy;
begin
  FBuffer.Free;
  inherited;
end;

procedure TCaptureOutput.Write(const s : string);
begin
  FBuffer.Append(s);
end;

procedure TCaptureOutput.Flush;
begin
end;

function TCaptureOutput.Text : string;
begin
  result := FBuffer.ToString;
end;

{ Built-in TextEncoder ------------------------------------------------------- }

type
  TTextEncoder = class(TInterfacedObject, IAnsiConsoleEncoder)
  public
    function Encode(const profile : IProfile;
                     const recorded : TArray<IRenderable>) : string;
  end;

function TTextEncoder.Encode(const profile : IProfile;
                              const recorded : TArray<IRenderable>) : string;
var
  caps   : TCapabilities;
  sink   : TCaptureOutput;
  output : IAnsiOutput;
  c      : IAnsiConsole;
  i      : Integer;
  width  : Integer;
  height : Integer;
begin
  width := profile.Width;
  height := profile.Height;
  caps := TCapabilities.Create(TColorSystem.NoColors, False, profile.Capabilities.Unicode, False);

  sink := TCaptureOutput.Create;
  output := sink;
  c := CreateAnsiConsole(output, caps, width, height);

  for i := 0 to High(recorded) do
    c.Write(recorded[i]);

  result := sink.Text;
end;

function TextEncoder : IAnsiConsoleEncoder;
begin
  result := TTextEncoder.Create;
end;

{ Built-in HtmlEncoder ------------------------------------------------------- }

function HtmlEscape(const s : string) : string;
var
  i  : Integer;
  sb : TStringBuilder;
  ch : Char;
begin
  sb := TStringBuilder.Create;
  try
    for i := 1 to Length(s) do
    begin
      ch := s[i];
      case ch of
        '&': sb.Append('&amp;');
        '<': sb.Append('&lt;');
        '>': sb.Append('&gt;');
        '"': sb.Append('&quot;');
      else
        sb.Append(ch);
      end;
    end;
    result := sb.ToString;
  finally
    sb.Free;
  end;
end;

function ColorToCss(const c : TAnsiColor) : string;
begin
  if c.IsDefault then
    result := ''
  else
    result := Format('#%.2x%.2x%.2x', [c.R, c.G, c.B]);
end;

function StyleToCss(const s : TAnsiStyle) : string;
var
  sb     : TStringBuilder;
  fg, bg : string;
begin
  sb := TStringBuilder.Create;
  try
    fg := ColorToCss(s.Foreground);
    bg := ColorToCss(s.Background);
    if fg <> '' then
    begin
      sb.Append('color:');
      sb.Append(fg);
      sb.Append(';');
    end;
    if bg <> '' then
    begin
      sb.Append('background-color:');
      sb.Append(bg);
      sb.Append(';');
    end;
    if TAnsiDecoration.Bold in s.Decorations then
      sb.Append('font-weight:bold;');
    if TAnsiDecoration.Italic in s.Decorations then
      sb.Append('font-style:italic;');
    if TAnsiDecoration.Underline in s.Decorations then
      sb.Append('text-decoration:underline;');
    if TAnsiDecoration.Strikethrough in s.Decorations then
      sb.Append('text-decoration:line-through;');
    result := sb.ToString;
  finally
    sb.Free;
  end;
end;

type
  THtmlEncoder = class(TInterfacedObject, IAnsiConsoleEncoder)
  public
    function Encode(const profile : IProfile;
                     const recorded : TArray<IRenderable>) : string;
  end;

function THtmlEncoder.Encode(const profile : IProfile;
                              const recorded : TArray<IRenderable>) : string;
var
  sb      : TStringBuilder;
  options : TRenderOptions;
  i, j    : Integer;
  segs    : TAnsiSegments;
  css     : string;
  escaped : string;
  seg     : TAnsiSegment;
begin
  options := TRenderOptions.Create(profile.Width, profile.Height, TColorSystem.TrueColor);
  options := options.WithUnicode(profile.Capabilities.Unicode);

  sb := TStringBuilder.Create;
  try
    sb.Append('<pre style="font-family:Consolas,Menlo,monospace;background-color:#000;color:#ddd;padding:8px">');

    for i := 0 to High(recorded) do
    begin
      segs := recorded[i].Render(options, profile.Width);
      for j := 0 to High(segs) do
      begin
        seg := segs[j];
        if seg.IsLineBreak then
        begin
          sb.Append(sLineBreak);
          Continue;
        end;
        if seg.IsControlCode then
          Continue;  // skip raw control codes in HTML
        escaped := HtmlEscape(seg.Value);
        css := StyleToCss(seg.Style);
        if css = '' then
          sb.Append(escaped)
        else
        begin
          sb.Append('<span style="');
          sb.Append(css);
          sb.Append('">');
          sb.Append(escaped);
          sb.Append('</span>');
        end;
      end;
    end;

    sb.Append('</pre>');
    result := sb.ToString;
  finally
    sb.Free;
  end;
end;

function HtmlEncoder : IAnsiConsoleEncoder;
begin
  result := THtmlEncoder.Create;
end;

{ TRecorder ----------------------------------------------------------------- }

function Recorder(const inner : IAnsiConsole) : IRecorder;
begin
  result := TRecorder.Create(inner);
end;

constructor TRecorder.Create(const inner : IAnsiConsole);
begin
  inherited Create;
  if inner = nil then
    raise Exception.Create('Recorder requires a non-nil inner console');
  FInner := inner;
  FRecorded := TList<IRenderable>.Create;
end;

destructor TRecorder.Destroy;
begin
  FRecorded.Free;
  inherited;
end;

function TRecorder.GetProfile : IProfile;
begin
  result := FInner.Profile;
end;

function TRecorder.GetPipeline : IRenderPipeline;
begin
  result := FInner.Pipeline;
end;

function TRecorder.GetInput : IConsoleInput;
begin
  result := FInner.Input;
end;

procedure TRecorder.SetInput(const value : IConsoleInput);
begin
  FInner.Input := value;
end;

procedure TRecorder.Write(const renderable : IRenderable);
begin
  if renderable = nil then Exit;
  FRecorded.Add(renderable);
  FInner.Write(renderable);
end;

procedure TRecorder.Write(const segs : TAnsiSegments);
begin
  FInner.Write(segs);
end;

procedure TRecorder.WriteLine;
begin
  // Record the trailing line break so exports preserve the newline that
  // the inner console emits.
  FRecorded.Add(TLineBreakRenderable.Create);
  FInner.WriteLine;
end;

procedure TRecorder.WriteLine(const renderable : IRenderable);
begin
  if renderable <> nil then
    FRecorded.Add(renderable);
  FRecorded.Add(TLineBreakRenderable.Create);
  FInner.WriteLine(renderable);
end;

procedure TRecorder.Clear(home : Boolean);
begin
  FInner.Clear(home);
end;

procedure TRecorder.Reset;
begin
  FRecorded.Clear;
end;

function TRecorder.SnapshotRecorded : TArray<IRenderable>;
var
  i : Integer;
begin
  SetLength(result, FRecorded.Count);
  for i := 0 to FRecorded.Count - 1 do
    result[i] := FRecorded[i];
end;

function TRecorder.Export(const encoder : IAnsiConsoleEncoder) : string;
begin
  if encoder = nil then
    raise Exception.Create('Recorder.Export: encoder must not be nil');
  result := encoder.Encode(FInner.Profile, SnapshotRecorded);
end;

function TRecorder.ExportText : string;
begin
  result := Export(TextEncoder);
end;

function TRecorder.ExportHtml : string;
begin
  result := Export(HtmlEncoder);
end;

end.
