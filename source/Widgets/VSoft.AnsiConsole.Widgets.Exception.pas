unit VSoft.AnsiConsole.Widgets.Exception;

{
  TExceptionWidget - pretty-prints a Delphi Exception with optional rich
  tokenization of its stack trace.

  Header line:
       <ExceptionType>: <Message>

  Per stack frame:
       at <method> in <path>:<lineNumber>

  Each token has its own style on IExceptionStyle. TExceptionFormats flags
  collapse paths/types/methods, suppress the trace, or wrap the path with
  an OSC 8 hyperlink. Delphi's Exception class doesn't carry a structured
  trace, so callers feed the trace as a plain string (one frame per line)
  collected from madExcept / JclDebug / EurekaLog / their own walker.

  Backward compat: WithClassNameStyle / WithMessageStyle / WithFrameStyle
  remain on the interface; they map to the matching IExceptionStyle slots
  (ExceptionType / Message / Dimmed) so existing code keeps working.
}

{$SCOPEDENUMS ON}

interface

uses
  System.SysUtils,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering;

type
  { Spectre-compatible per-token style sheet. Each property maps to a
    discrete category emitted by the trace tokenizer. }
  IExceptionStyle = interface
    ['{0F4E5D6C-3B2A-4F1E-9B70-5C4D3E2F1B01}']
    function GetMessage : TAnsiStyle;
    function GetExceptionType : TAnsiStyle;
    function GetMethod : TAnsiStyle;
    function GetParameterType : TAnsiStyle;
    function GetParameterName : TAnsiStyle;
    function GetParenthesis : TAnsiStyle;
    function GetPath : TAnsiStyle;
    function GetLineNumber : TAnsiStyle;
    function GetDimmed : TAnsiStyle;
    function GetNonEmphasized : TAnsiStyle;
    function WithMessage(const value : TAnsiStyle) : IExceptionStyle;
    function WithExceptionType(const value : TAnsiStyle) : IExceptionStyle;
    function WithMethod(const value : TAnsiStyle) : IExceptionStyle;
    function WithParameterType(const value : TAnsiStyle) : IExceptionStyle;
    function WithParameterName(const value : TAnsiStyle) : IExceptionStyle;
    function WithParenthesis(const value : TAnsiStyle) : IExceptionStyle;
    function WithPath(const value : TAnsiStyle) : IExceptionStyle;
    function WithLineNumber(const value : TAnsiStyle) : IExceptionStyle;
    function WithDimmed(const value : TAnsiStyle) : IExceptionStyle;
    function WithNonEmphasized(const value : TAnsiStyle) : IExceptionStyle;
    property StyleMessage       : TAnsiStyle read GetMessage;
    property StyleExceptionType : TAnsiStyle read GetExceptionType;
    property StyleMethod        : TAnsiStyle read GetMethod;
    property StyleParameterType : TAnsiStyle read GetParameterType;
    property StyleParameterName : TAnsiStyle read GetParameterName;
    property StyleParenthesis   : TAnsiStyle read GetParenthesis;
    property StylePath          : TAnsiStyle read GetPath;
    property StyleLineNumber    : TAnsiStyle read GetLineNumber;
    property StyleDimmed        : TAnsiStyle read GetDimmed;
    property StyleNonEmphasized : TAnsiStyle read GetNonEmphasized;
  end;

  TExceptionFormat = (
    ShortenPaths,     // ExtractFileName(path) on emit
    ShortenTypes,     // strip namespace from "A.B.Type.Method" -> "Type.Method"
    ShortenMethods,   // strip everything but the method name itself
    ShowLinks,        // wrap path token in an OSC 8 file:// link
    NoStackTrace      // skip the trace block entirely
  );
  TExceptionFormats = set of TExceptionFormat;

  TExceptionStyle = class(TInterfacedObject, IExceptionStyle)
  strict private
    FMessage       : TAnsiStyle;
    FExceptionType : TAnsiStyle;
    FMethod        : TAnsiStyle;
    FParameterType : TAnsiStyle;
    FParameterName : TAnsiStyle;
    FParenthesis   : TAnsiStyle;
    FPath          : TAnsiStyle;
    FLineNumber    : TAnsiStyle;
    FDimmed        : TAnsiStyle;
    FNonEmphasized : TAnsiStyle;
  public
    constructor Create;
    function GetMessage : TAnsiStyle;
    function GetExceptionType : TAnsiStyle;
    function GetMethod : TAnsiStyle;
    function GetParameterType : TAnsiStyle;
    function GetParameterName : TAnsiStyle;
    function GetParenthesis : TAnsiStyle;
    function GetPath : TAnsiStyle;
    function GetLineNumber : TAnsiStyle;
    function GetDimmed : TAnsiStyle;
    function GetNonEmphasized : TAnsiStyle;
    function WithMessage(const value : TAnsiStyle) : IExceptionStyle;
    function WithExceptionType(const value : TAnsiStyle) : IExceptionStyle;
    function WithMethod(const value : TAnsiStyle) : IExceptionStyle;
    function WithParameterType(const value : TAnsiStyle) : IExceptionStyle;
    function WithParameterName(const value : TAnsiStyle) : IExceptionStyle;
    function WithParenthesis(const value : TAnsiStyle) : IExceptionStyle;
    function WithPath(const value : TAnsiStyle) : IExceptionStyle;
    function WithLineNumber(const value : TAnsiStyle) : IExceptionStyle;
    function WithDimmed(const value : TAnsiStyle) : IExceptionStyle;
    function WithNonEmphasized(const value : TAnsiStyle) : IExceptionStyle;
  end;

  IExceptionWidget = interface(IRenderable)
    ['{0F4E5D6C-3B2A-4F1E-9B70-5C4D3E2F1A00}']
    function WithStackTrace(const trace : string) : IExceptionWidget;
    function WithClassNameStyle(const value : TAnsiStyle) : IExceptionWidget;
    function WithMessageStyle(const value : TAnsiStyle) : IExceptionWidget;
    function WithFrameStyle(const value : TAnsiStyle) : IExceptionWidget;
    function WithFormats(const value : TExceptionFormats) : IExceptionWidget;
    function WithStyle(const value : IExceptionStyle) : IExceptionWidget;
  end;

  TExceptionWidget = class(TInterfacedObject, IRenderable, IExceptionWidget)
  strict private
    FClassName  : string;
    FMessage    : string;
    FStackTrace : string;
    FStyle      : IExceptionStyle;
    FFormats    : TExceptionFormats;
  public
    constructor Create(const e : Exception); overload;
    constructor Create(const className, message : string); overload;

    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;

    function WithStackTrace(const trace : string) : IExceptionWidget;
    function WithClassNameStyle(const value : TAnsiStyle) : IExceptionWidget;
    function WithMessageStyle(const value : TAnsiStyle) : IExceptionWidget;
    function WithFrameStyle(const value : TAnsiStyle) : IExceptionWidget;
    function WithFormats(const value : TExceptionFormats) : IExceptionWidget;
    function WithStyle(const value : IExceptionStyle) : IExceptionWidget;
  end;

function ExceptionWidget(const e : Exception) : IExceptionWidget; overload;
function ExceptionWidget(const className, message : string) : IExceptionWidget; overload;
function ExceptionStyle : IExceptionStyle;

implementation

function ExceptionWidget(const e : Exception) : IExceptionWidget;
begin
  result := TExceptionWidget.Create(e);
end;

function ExceptionWidget(const className, message : string) : IExceptionWidget;
begin
  result := TExceptionWidget.Create(className, message);
end;

function ExceptionStyle : IExceptionStyle;
begin
  result := TExceptionStyle.Create;
end;

{ TExceptionStyle }

constructor TExceptionStyle.Create;
begin
  inherited Create;
  // Defaults follow Spectre.Console's ExceptionStyle conventions.
  FMessage       := TAnsiStyle.Plain.WithForeground(TAnsiColor.White);
  FExceptionType := TAnsiStyle.Plain.WithForeground(TAnsiColor.Red).WithDecorations([TAnsiDecoration.Bold]);
  FMethod        := TAnsiStyle.Plain.WithForeground(TAnsiColor.Yellow);
  FParameterType := TAnsiStyle.Plain.WithForeground(TAnsiColor.Blue);
  FParameterName := TAnsiStyle.Plain.WithForeground(TAnsiColor.Silver);
  FParenthesis   := TAnsiStyle.Plain.WithForeground(TAnsiColor.Silver);
  FPath          := TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua);
  FLineNumber    := TAnsiStyle.Plain.WithForeground(TAnsiColor.Blue);
  FDimmed        := TAnsiStyle.Plain.WithForeground(TAnsiColor.Grey);
  FNonEmphasized := TAnsiStyle.Plain.WithForeground(TAnsiColor.Silver);
end;

function TExceptionStyle.GetMessage       : TAnsiStyle; begin result := FMessage; end;
function TExceptionStyle.GetExceptionType : TAnsiStyle; begin result := FExceptionType; end;
function TExceptionStyle.GetMethod        : TAnsiStyle; begin result := FMethod; end;
function TExceptionStyle.GetParameterType : TAnsiStyle; begin result := FParameterType; end;
function TExceptionStyle.GetParameterName : TAnsiStyle; begin result := FParameterName; end;
function TExceptionStyle.GetParenthesis   : TAnsiStyle; begin result := FParenthesis; end;
function TExceptionStyle.GetPath          : TAnsiStyle; begin result := FPath; end;
function TExceptionStyle.GetLineNumber    : TAnsiStyle; begin result := FLineNumber; end;
function TExceptionStyle.GetDimmed        : TAnsiStyle; begin result := FDimmed; end;
function TExceptionStyle.GetNonEmphasized : TAnsiStyle; begin result := FNonEmphasized; end;

function TExceptionStyle.WithMessage(const value : TAnsiStyle) : IExceptionStyle;
begin FMessage := value; result := Self; end;

function TExceptionStyle.WithExceptionType(const value : TAnsiStyle) : IExceptionStyle;
begin FExceptionType := value; result := Self; end;

function TExceptionStyle.WithMethod(const value : TAnsiStyle) : IExceptionStyle;
begin FMethod := value; result := Self; end;

function TExceptionStyle.WithParameterType(const value : TAnsiStyle) : IExceptionStyle;
begin FParameterType := value; result := Self; end;

function TExceptionStyle.WithParameterName(const value : TAnsiStyle) : IExceptionStyle;
begin FParameterName := value; result := Self; end;

function TExceptionStyle.WithParenthesis(const value : TAnsiStyle) : IExceptionStyle;
begin FParenthesis := value; result := Self; end;

function TExceptionStyle.WithPath(const value : TAnsiStyle) : IExceptionStyle;
begin FPath := value; result := Self; end;

function TExceptionStyle.WithLineNumber(const value : TAnsiStyle) : IExceptionStyle;
begin FLineNumber := value; result := Self; end;

function TExceptionStyle.WithDimmed(const value : TAnsiStyle) : IExceptionStyle;
begin FDimmed := value; result := Self; end;

function TExceptionStyle.WithNonEmphasized(const value : TAnsiStyle) : IExceptionStyle;
begin FNonEmphasized := value; result := Self; end;

{ TExceptionWidget }

constructor TExceptionWidget.Create(const e : Exception);
begin
  if e = nil then
    Create('Exception', '')
  else
    Create(e.ClassName, e.Message);
end;

constructor TExceptionWidget.Create(const className, message : string);
begin
  inherited Create;
  FClassName := className;
  FMessage   := message;
  FStyle     := ExceptionStyle;  // a fresh defaulted style sheet
  FFormats   := [];
end;

function TExceptionWidget.WithStackTrace(const trace : string) : IExceptionWidget;
begin
  FStackTrace := trace;
  result := Self;
end;

function TExceptionWidget.WithClassNameStyle(const value : TAnsiStyle) : IExceptionWidget;
begin
  FStyle.WithExceptionType(value);
  result := Self;
end;

function TExceptionWidget.WithMessageStyle(const value : TAnsiStyle) : IExceptionWidget;
begin
  FStyle.WithMessage(value);
  result := Self;
end;

function TExceptionWidget.WithFrameStyle(const value : TAnsiStyle) : IExceptionWidget;
begin
  // Frame style governs the dimmed `   at ` prefix tokens.
  FStyle.WithDimmed(value);
  result := Self;
end;

function TExceptionWidget.WithFormats(const value : TExceptionFormats) : IExceptionWidget;
begin
  FFormats := value;
  result := Self;
end;

function TExceptionWidget.WithStyle(const value : IExceptionStyle) : IExceptionWidget;
begin
  if value <> nil then
    FStyle := value;
  result := Self;
end;

function TExceptionWidget.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
begin
  result := TMeasurement.Create(1, maxWidth);
end;

{ Splits `trace` on CR/LF boundaries into an array of non-empty lines. }
function SplitTrace(const trace : string) : TArray<string>;
var
  i, start, count : Integer;
  line            : string;
begin
  SetLength(result, 0);
  count := 0;
  start := 1;
  for i := 1 to Length(trace) do
  begin
    if (trace[i] = #10) or (trace[i] = #13) then
    begin
      if i > start then
      begin
        line := Copy(trace, start, i - start);
        if Trim(line) <> '' then
        begin
          SetLength(result, count + 1);
          result[count] := line;
          Inc(count);
        end;
      end;
      start := i + 1;
    end;
  end;
  if start <= Length(trace) then
  begin
    line := Copy(trace, start, Length(trace) - start + 1);
    if Trim(line) <> '' then
    begin
      SetLength(result, count + 1);
      result[count] := line;
    end;
  end;
end;

{ Strips an optional 'at ' prefix and any leading whitespace. }
function StripAtPrefix(const s : string) : string;
begin
  result := TrimLeft(s);
  if (Length(result) >= 3) and (LowerCase(Copy(result, 1, 3)) = 'at ') then
    result := TrimLeft(Copy(result, 4, MaxInt));
end;

{ Splits "MyUnit.TClass.DoWork in C:\path\file.pas:42" into method, path,
  lineNum. Missing path/line yield ''. The "in" delimiter is expected to be
  surrounded by spaces; the trailing ':<digits>' (optionally with a 'line '
  prefix) is recognised when present. }
procedure ParseTraceLine(const raw : string;
                          out method, path, lineNum : string);
var
  body     : string;
  inPos    : Integer;
  colonPos : Integer;
  candidate : string;
  digit    : string;
  i        : Integer;
  ok       : Boolean;
begin
  method := '';
  path := '';
  lineNum := '';

  body := StripAtPrefix(raw);
  inPos := Pos(' in ', body);
  if inPos = 0 then
  begin
    method := Trim(body);
    Exit;
  end;

  method := Trim(Copy(body, 1, inPos - 1));
  path := Trim(Copy(body, inPos + 4, MaxInt));

  // Look for trailing ':<digits>' with optional 'line ' word in front.
  colonPos := 0;
  for i := Length(path) downto 1 do
    if path[i] = ':' then
    begin
      colonPos := i;
      Break;
    end;
  if colonPos = 0 then Exit;

  candidate := Trim(Copy(path, colonPos + 1, MaxInt));
  if (Length(candidate) >= 5) and (LowerCase(Copy(candidate, 1, 5)) = 'line ') then
    candidate := Trim(Copy(candidate, 6, MaxInt));
  if candidate = '' then Exit;

  ok := True;
  digit := '';
  for i := 1 to Length(candidate) do
  begin
    if (candidate[i] >= '0') and (candidate[i] <= '9') then
      digit := digit + candidate[i]
    else
    begin
      ok := False;
      Break;
    end;
  end;
  if ok and (digit <> '') then
  begin
    lineNum := digit;
    path := Trim(Copy(path, 1, colonPos - 1));
  end;
end;

{ Returns everything after the last '.' in s. If no dot, returns s. }
function LastSegment(const s : string) : string;
var
  i : Integer;
begin
  for i := Length(s) downto 1 do
    if s[i] = '.' then
    begin
      result := Copy(s, i + 1, MaxInt);
      Exit;
    end;
  result := s;
end;

{ Returns the last two dot-separated segments of s ("Type.Method"). If s
  has fewer than two segments, returns s unchanged. }
function LastTwoSegments(const s : string) : string;
var
  i, dotsSeen, secondDot : Integer;
begin
  dotsSeen := 0;
  secondDot := 0;
  for i := Length(s) downto 1 do
  begin
    if s[i] = '.' then
    begin
      Inc(dotsSeen);
      if dotsSeen = 2 then
      begin
        secondDot := i;
        Break;
      end;
    end;
  end;
  if secondDot = 0 then
    result := s
  else
    result := Copy(s, secondDot + 1, MaxInt);
end;

function TExceptionWidget.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  count   : Integer;
  lines   : TArray<string>;
  i       : Integer;
  method, path, lineNum : string;
  pathStyle : TAnsiStyle;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;

  // Silence unused-parameter hints; both already feed the writer downstream.
  if (options.Width < 0) or (maxWidth < 0) then ;

  // Header line: "<TypeName>: <message>"
  Push(TAnsiSegment.Text(FClassName, FStyle.GetExceptionType));
  if FMessage <> '' then
  begin
    Push(TAnsiSegment.Text(': ', FStyle.GetExceptionType));
    Push(TAnsiSegment.Text(FMessage, FStyle.GetMessage));
  end;

  if (TExceptionFormat.NoStackTrace in FFormats) or (FStackTrace = '') then Exit;

  lines := SplitTrace(FStackTrace);
  for i := 0 to High(lines) do
  begin
    ParseTraceLine(lines[i], method, path, lineNum);

    // Method shortening: ShortenMethods is the more aggressive of the two.
    if TExceptionFormat.ShortenMethods in FFormats then
      method := LastSegment(method)
    else if TExceptionFormat.ShortenTypes in FFormats then
      method := LastTwoSegments(method);

    // Path shortening: drop directory portion entirely.
    if (path <> '') and (TExceptionFormat.ShortenPaths in FFormats) then
      path := ExtractFileName(path);

    Push(TAnsiSegment.LineBreak);
    Push(TAnsiSegment.Text('   at ', FStyle.GetDimmed));
    if method <> '' then
      Push(TAnsiSegment.Text(method, FStyle.GetMethod));

    if path <> '' then
    begin
      Push(TAnsiSegment.Text(' in ', FStyle.GetDimmed));
      pathStyle := FStyle.GetPath;
      if TExceptionFormat.ShowLinks in FFormats then
        pathStyle := pathStyle.WithLink('file:///' + path);
      Push(TAnsiSegment.Text(path, pathStyle));
      if lineNum <> '' then
      begin
        Push(TAnsiSegment.Text(':', FStyle.GetDimmed));
        Push(TAnsiSegment.Text(lineNum, FStyle.GetLineNumber));
      end;
    end;
  end;
end;

end.
