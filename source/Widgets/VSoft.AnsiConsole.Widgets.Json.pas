unit VSoft.AnsiConsole.Widgets.Json;

(*
  TJsonText - renders a JSON string with per-token syntax colouring and
  re-indentation. Uses a minimal hand-rolled tokenizer (not a validator);
  malformed input degrades to "colour what I can".

  Default palette:
    braces         Grey
    brackets       Grey
    member name    Blue
    colon          Yellow
    comma          Grey
    string literal Red
    number         Lime
    boolean        Lime
    null           Grey
*)

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
  IJsonText = interface(IRenderable)
    ['{E7F1C3B4-5A9D-4E2F-8B60-1C2D3F4E5A70}']
    function WithIndent(value : Integer) : IJsonText;
    function WithBracesStyle(const value : TAnsiStyle) : IJsonText;
    function WithBracketsStyle(const value : TAnsiStyle) : IJsonText;
    function WithMemberStyle(const value : TAnsiStyle) : IJsonText;
    function WithColonStyle(const value : TAnsiStyle) : IJsonText;
    function WithCommaStyle(const value : TAnsiStyle) : IJsonText;
    function WithStringStyle(const value : TAnsiStyle) : IJsonText;
    function WithNumberStyle(const value : TAnsiStyle) : IJsonText;
    function WithBooleanStyle(const value : TAnsiStyle) : IJsonText;
    function WithNullStyle(const value : TAnsiStyle) : IJsonText;
  end;

  TJsonText = class(TInterfacedObject, IRenderable, IJsonText)
  strict private
    FJson        : string;
    FIndent      : Integer;
    FBracesStyle : TAnsiStyle;
    FBracketsStyle : TAnsiStyle;
    FMemberStyle : TAnsiStyle;
    FColonStyle  : TAnsiStyle;
    FCommaStyle  : TAnsiStyle;
    FStringStyle : TAnsiStyle;
    FNumberStyle : TAnsiStyle;
    FBooleanStyle: TAnsiStyle;
    FNullStyle   : TAnsiStyle;
  public
    constructor Create(const json : string);

    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;

    function WithIndent(value : Integer) : IJsonText;
    function WithBracesStyle(const value : TAnsiStyle) : IJsonText;
    function WithBracketsStyle(const value : TAnsiStyle) : IJsonText;
    function WithMemberStyle(const value : TAnsiStyle) : IJsonText;
    function WithColonStyle(const value : TAnsiStyle) : IJsonText;
    function WithCommaStyle(const value : TAnsiStyle) : IJsonText;
    function WithStringStyle(const value : TAnsiStyle) : IJsonText;
    function WithNumberStyle(const value : TAnsiStyle) : IJsonText;
    function WithBooleanStyle(const value : TAnsiStyle) : IJsonText;
    function WithNullStyle(const value : TAnsiStyle) : IJsonText;
  end;

function Json(const json : string) : IJsonText;

implementation

function Json(const json : string) : IJsonText;
begin
  result := TJsonText.Create(json);
end;

{ TJsonText }

constructor TJsonText.Create(const json : string);
begin
  inherited Create;
  FJson := json;
  FIndent := 2;
  FBracesStyle   := TAnsiStyle.Plain.WithForeground(TAnsiColor.Grey);
  FBracketsStyle := TAnsiStyle.Plain.WithForeground(TAnsiColor.Grey);
  FMemberStyle   := TAnsiStyle.Plain.WithForeground(TAnsiColor.DeepSkyBlue4_2);
  FColonStyle    := TAnsiStyle.Plain.WithForeground(TAnsiColor.Yellow);
  FCommaStyle    := TAnsiStyle.Plain.WithForeground(TAnsiColor.Grey);
  FStringStyle   := TAnsiStyle.Plain.WithForeground(TAnsiColor.Red);
  FNumberStyle   := TAnsiStyle.Plain.WithForeground(TAnsiColor.Lime);
  FBooleanStyle  := TAnsiStyle.Plain.WithForeground(TAnsiColor.Lime);
  FNullStyle     := TAnsiStyle.Plain.WithForeground(TAnsiColor.Grey);
end;

function TJsonText.WithIndent(value : Integer) : IJsonText;
begin
  if value < 0 then value := 0;
  FIndent := value;
  result := Self;
end;

function TJsonText.WithBracesStyle(const value : TAnsiStyle) : IJsonText;
begin FBracesStyle := value; result := Self; end;

function TJsonText.WithBracketsStyle(const value : TAnsiStyle) : IJsonText;
begin FBracketsStyle := value; result := Self; end;

function TJsonText.WithMemberStyle(const value : TAnsiStyle) : IJsonText;
begin FMemberStyle := value; result := Self; end;

function TJsonText.WithColonStyle(const value : TAnsiStyle) : IJsonText;
begin FColonStyle := value; result := Self; end;

function TJsonText.WithCommaStyle(const value : TAnsiStyle) : IJsonText;
begin FCommaStyle := value; result := Self; end;

function TJsonText.WithStringStyle(const value : TAnsiStyle) : IJsonText;
begin FStringStyle := value; result := Self; end;

function TJsonText.WithNumberStyle(const value : TAnsiStyle) : IJsonText;
begin FNumberStyle := value; result := Self; end;

function TJsonText.WithBooleanStyle(const value : TAnsiStyle) : IJsonText;
begin FBooleanStyle := value; result := Self; end;

function TJsonText.WithNullStyle(const value : TAnsiStyle) : IJsonText;
begin FNullStyle := value; result := Self; end;

function TJsonText.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
begin
  // Conservative: we don't know the rendered width without emitting; report
  // the full maxWidth so callers reserve enough room.
  result := TMeasurement.Create(1, maxWidth);
end;

{ Skip whitespace chars (space, tab, CR, LF). Returns new position. }
function SkipWs(const s : string; pos : Integer) : Integer;
begin
  while (pos <= Length(s)) and ((s[pos] = ' ') or (s[pos] = #9)
        or (s[pos] = #10) or (s[pos] = #13)) do
    Inc(pos);
  result := pos;
end;

{ Reads a JSON string literal starting at `pos` (s[pos] = '"'). Returns the
  entire raw literal including surrounding quotes, updates `pos` past the
  closing quote. Handles backslash escapes. }
function ReadString(const s : string; var pos : Integer) : string;
var
  start : Integer;
begin
  start := pos;
  Inc(pos);  // skip opening quote
  while pos <= Length(s) do
  begin
    if s[pos] = '\' then
    begin
      if pos + 1 <= Length(s) then
        Inc(pos, 2)
      else
        Inc(pos);
      Continue;
    end;
    if s[pos] = '"' then
    begin
      Inc(pos);
      Break;
    end;
    Inc(pos);
  end;
  result := Copy(s, start, pos - start);
end;

{ Reads a number starting at `pos`. Accepts sign, digits, decimal, exponent. }
function ReadNumber(const s : string; var pos : Integer) : string;
var
  start : Integer;
begin
  start := pos;
  if (pos <= Length(s)) and (s[pos] = '-') then Inc(pos);
  while (pos <= Length(s)) and (s[pos] >= '0') and (s[pos] <= '9') do
    Inc(pos);
  if (pos <= Length(s)) and (s[pos] = '.') then
  begin
    Inc(pos);
    while (pos <= Length(s)) and (s[pos] >= '0') and (s[pos] <= '9') do
      Inc(pos);
  end;
  if (pos <= Length(s)) and ((s[pos] = 'e') or (s[pos] = 'E')) then
  begin
    Inc(pos);
    if (pos <= Length(s)) and ((s[pos] = '+') or (s[pos] = '-')) then Inc(pos);
    while (pos <= Length(s)) and (s[pos] >= '0') and (s[pos] <= '9') do
      Inc(pos);
  end;
  result := Copy(s, start, pos - start);
end;

{ Reads an identifier (true / false / null). }
function ReadIdent(const s : string; var pos : Integer) : string;
var
  start : Integer;
begin
  start := pos;
  while (pos <= Length(s)) and
        (((s[pos] >= 'a') and (s[pos] <= 'z')) or
         ((s[pos] >= 'A') and (s[pos] <= 'Z'))) do
    Inc(pos);
  result := Copy(s, start, pos - start);
end;

function TJsonText.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  count   : Integer;
  pos     : Integer;
  depth   : Integer;
  expectKey : Boolean;
  s       : string;
  ch      : Char;
  tok     : string;
  pad     : string;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

  procedure PushNewlineAndIndent;
  begin
    Push(TAnsiSegment.LineBreak);
    if (FIndent > 0) and (depth > 0) then
    begin
      pad := StringOfChar(' ', FIndent * depth);
      Push(TAnsiSegment.Whitespace(pad));
    end;
  end;

  function PeekNext(p : Integer) : Char;
  begin
    p := SkipWs(s, p);
    if p <= Length(s) then
      result := s[p]
    else
      result := #0;
  end;

begin
  SetLength(result, 0);
  count := 0;
  s := FJson;
  pos := SkipWs(s, 1);
  depth := 0;
  expectKey := False;

  // Silence unused params
  if (options.Width < 0) or (maxWidth < 0) then ;

  while pos <= Length(s) do
  begin
    ch := s[pos];

    case ch of
      '{':
      begin
        Push(TAnsiSegment.Text('{', FBracesStyle));
        Inc(pos);
        Inc(depth);
        expectKey := True;
        pos := SkipWs(s, pos);
        if (pos <= Length(s)) and (s[pos] = '}') then
        begin
          // empty object - emit on same line
          Push(TAnsiSegment.Text('}', FBracesStyle));
          Inc(pos);
          Dec(depth);
          expectKey := False;
        end
        else
          PushNewlineAndIndent;
      end;

      '}':
      begin
        Dec(depth);
        PushNewlineAndIndent;
        Push(TAnsiSegment.Text('}', FBracesStyle));
        Inc(pos);
        expectKey := False;
      end;

      '[':
      begin
        Push(TAnsiSegment.Text('[', FBracketsStyle));
        Inc(pos);
        Inc(depth);
        pos := SkipWs(s, pos);
        if (pos <= Length(s)) and (s[pos] = ']') then
        begin
          Push(TAnsiSegment.Text(']', FBracketsStyle));
          Inc(pos);
          Dec(depth);
        end
        else
          PushNewlineAndIndent;
      end;

      ']':
      begin
        Dec(depth);
        PushNewlineAndIndent;
        Push(TAnsiSegment.Text(']', FBracketsStyle));
        Inc(pos);
      end;

      ',':
      begin
        Push(TAnsiSegment.Text(',', FCommaStyle));
        Inc(pos);
        expectKey := PeekNext(pos) = '"';
        // Whether we're inside an object or array, next token is a new item
        PushNewlineAndIndent;
      end;

      ':':
      begin
        Push(TAnsiSegment.Text(':', FColonStyle));
        Push(TAnsiSegment.Whitespace(' '));
        Inc(pos);
        expectKey := False;
      end;

      '"':
      begin
        tok := ReadString(s, pos);
        if expectKey then
        begin
          Push(TAnsiSegment.Text(tok, FMemberStyle));
          // Key done - next token should be ':'; flip flag so subsequent
          // string is treated as value.
          expectKey := False;
        end
        else
          Push(TAnsiSegment.Text(tok, FStringStyle));
      end;

      '-', '0'..'9':
      begin
        tok := ReadNumber(s, pos);
        Push(TAnsiSegment.Text(tok, FNumberStyle));
      end;

      ' ', #9, #10, #13:
        Inc(pos);

      'a'..'z', 'A'..'Z':
      begin
        tok := ReadIdent(s, pos);
        if SameText(tok, 'null') then
          Push(TAnsiSegment.Text(tok, FNullStyle))
        else if SameText(tok, 'true') or SameText(tok, 'false') then
          Push(TAnsiSegment.Text(tok, FBooleanStyle))
        else
          // Unknown token - emit verbatim with plain style so malformed
          // input doesn't spin forever.
          Push(TAnsiSegment.Text(tok, TAnsiStyle.Plain));
        if tok = '' then Inc(pos);  // safety: always advance
      end;

    else
      // Unknown char - emit and skip
      Push(TAnsiSegment.Text(ch));
      Inc(pos);
    end;

    pos := SkipWs(s, pos);
  end;
end;

end.
