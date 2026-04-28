unit VSoft.AnsiConsole.Internal.FigletFont;

{
  FIGlet font (.flf) parser + in-memory representation.

  A .flf file starts with a header line:
    flf2a<hardblank> <height> <baseline> <max-length> <old-layout> <comment-lines> [<print-direction> <full-layout> <codetag-count>]
  followed by <comment-lines> comment lines, then one FIGlet character per
  <height> lines.

  Each character is <height> lines tail-terminated by '@' at the end of each
  line and a final '@@' on the last line. Occurrences of <hardblank> are
  replaced with literal spaces. Characters are indexed starting at 32 (space)
  unless an explicit numeric index prefix precedes the block.
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TFigletCharacter = record
    Index : Integer;
    Width : Integer;
    Lines : TArray<string>;
  end;

  TFigletFont = class
  strict private
    FHeight    : Integer;
    FBaseline  : Integer;
    FMaxLength : Integer;
    FChars     : TDictionary<Integer, TFigletCharacter>;
    FBlank     : TFigletCharacter;
  public
    constructor Create(const source : AnsiString);
    destructor  Destroy; override;
    function GetCharacter(code : Integer) : TFigletCharacter;
    function GetWidth(const s : string) : Integer;
    function GetCharacters(const s : string) : TArray<TFigletCharacter>;
    property Height    : Integer read FHeight;
    property Baseline  : Integer read FBaseline;
    property MaxLength : Integer read FMaxLength;
  end;

{ Returns the bundled Standard.flf parsed into a singleton TFigletFont.
  Caller must NOT free. }
function DefaultFigletFont : TFigletFont;

implementation

uses
  VSoft.AnsiConsole.Internal.Cell,
  VSoft.AnsiConsole.Internal.Fonts.Standard;

var
  GDefaultFont : TFigletFont = nil;

function DefaultFigletFont : TFigletFont;
begin
  if GDefaultFont = nil then
    GDefaultFont := TFigletFont.Create(GetStandardFontText);
  result := GDefaultFont;
end;

function SplitLines(const s : AnsiString) : TArray<AnsiString>;
var
  i     : Integer;
  start : Integer;
  count : Integer;
  ch    : AnsiChar;
begin
  SetLength(result, 0);
  count := 0;
  start := 1;
  for i := 1 to Length(s) do
  begin
    ch := s[i];
    if ch = #10 then
    begin
      SetLength(result, count + 1);
      if (i > start) and (s[i - 1] = #13) then
        result[count] := Copy(s, start, i - start - 1)
      else
        result[count] := Copy(s, start, i - start);
      Inc(count);
      start := i + 1;
    end;
  end;
  if start <= Length(s) then
  begin
    SetLength(result, count + 1);
    result[count] := Copy(s, start, Length(s) - start + 1);
  end;
end;

{ TFigletFont }

constructor TFigletFont.Create(const source : AnsiString);
var
  lines       : TArray<AnsiString>;
  header      : AnsiString;
  hardblank   : AnsiChar;
  commentLines: Integer;
  parts       : TArray<AnsiString>;
  p           : Integer;
  idx         : Integer;
  curIdx      : Integer;
  overridden  : Boolean;
  hasOverride : Boolean;
  buffer      : TArray<AnsiString>;
  bufCount    : Integer;
  line        : AnsiString;
  charLines   : TArray<string>;
  ch          : TFigletCharacter;
  s           : AnsiString;
  j           : Integer;
  cleaned     : AnsiString;
  tmp         : AnsiString;
  cwidth      : Integer;
  i           : Integer;
  newIdx      : Integer;
  sigNum      : Integer;

  function SplitWords(const input : AnsiString) : TArray<AnsiString>;
  var
    k, st, n : Integer;
  begin
    SetLength(result, 0);
    n := 0;
    st := 1;
    for k := 1 to Length(input) do
    begin
      if (input[k] = ' ') or (input[k] = #9) then
      begin
        if k > st then
        begin
          SetLength(result, n + 1);
          result[n] := Copy(input, st, k - st);
          Inc(n);
        end;
        st := k + 1;
      end;
    end;
    if st <= Length(input) then
    begin
      SetLength(result, n + 1);
      result[n] := Copy(input, st, Length(input) - st + 1);
    end;
  end;

  function TryParseIndex(const s : AnsiString; out resultIdx : Integer) : Boolean;
  var
    value : Int64;
    tmp   : string;
  begin
    tmp := string(s);
    if (Length(tmp) >= 2) and (tmp[1] = '0') and ((tmp[2] = 'x') or (tmp[2] = 'X')) then
    begin
      if TryStrToInt64('$' + Copy(tmp, 3, MaxInt), value) then
      begin
        resultIdx := Integer(value);
        result := True;
        Exit;
      end;
      result := False;
      Exit;
    end;
    result := TryStrToInt64(tmp, value);
    if result then resultIdx := Integer(value);
  end;

begin
  inherited Create;
  FChars := TDictionary<Integer, TFigletCharacter>.Create;

  lines := SplitLines(source);
  if Length(lines) = 0 then
    raise EInvalidOperation.Create('FIGlet font empty');

  header := lines[0];
  parts := SplitWords(header);
  if Length(parts) < 6 then
    raise EInvalidOperation.Create('FIGlet header too short');

  if Length(parts[0]) < 6 then
    raise EInvalidOperation.Create('FIGlet header signature invalid');

  // signature: 'flf2a' followed by hardblank char
  if (parts[0][1] <> 'f') or (parts[0][2] <> 'l') or (parts[0][3] <> 'f') or
     (parts[0][4] <> '2') or (parts[0][5] <> 'a') then
    raise EInvalidOperation.Create('FIGlet signature not "flf2a"');

  hardblank := parts[0][6];
  FHeight     := StrToInt(string(parts[1]));
  FBaseline   := StrToInt(string(parts[2]));
  FMaxLength  := StrToInt(string(parts[3]));
  sigNum      := StrToInt(string(parts[4]));  // old-layout (ignored)
  commentLines:= StrToInt(string(parts[5]));

  if sigNum < 0 then ;  // silence unused

  curIdx := 32;
  overridden  := False;
  hasOverride := False;
  SetLength(buffer, 0);
  bufCount := 0;

  p := 1 + commentLines;  // lines[0] is header, next commentLines are comments

  while p < Length(lines) do
  begin
    line := lines[p];

    if (Length(line) = 0) or (line[Length(line)] <> '@') then
    begin
      // May be a code-tag override line: "<number> <description>"
      parts := SplitWords(line);
      if (Length(parts) > 0) and TryParseIndex(parts[0], newIdx) then
      begin
        curIdx := newIdx;
        overridden := True;
        hasOverride := True;
      end;
      Inc(p);
      Continue;
    end;

    if hasOverride and not overridden then
      raise EInvalidOperation.Create('FIGlet char has no override index');

    // Strip trailing '@' chars (one at EOL, two on final char line)
    cleaned := line;
    while (Length(cleaned) > 0) and (cleaned[Length(cleaned)] = '@') do
      Delete(cleaned, Length(cleaned), 1);
    // Replace hardblank with space
    tmp := cleaned;
    for j := 1 to Length(tmp) do
      if tmp[j] = hardblank then tmp[j] := ' ';

    SetLength(buffer, bufCount + 1);
    buffer[bufCount] := tmp;
    Inc(bufCount);

    if (Length(line) >= 2) and (line[Length(line)] = '@') and (line[Length(line) - 1] = '@') then
    begin
      // End of character block
      SetLength(charLines, bufCount);
      cwidth := 0;
      for i := 0 to bufCount - 1 do
      begin
        s := buffer[i];
        charLines[i] := string(s);
        if Length(s) > cwidth then
          cwidth := Length(s);
      end;
      // Pad all lines to cwidth
      for i := 0 to bufCount - 1 do
        while Length(charLines[i]) < cwidth do
          charLines[i] := charLines[i] + ' ';

      ch.Index := curIdx;
      ch.Width := cwidth;
      ch.Lines := charLines;
      FChars.AddOrSetValue(curIdx, ch);

      SetLength(buffer, 0);
      bufCount := 0;

      if not hasOverride then
        Inc(curIdx);
      overridden := False;
    end;

    Inc(p);
  end;

  // Build a blank fallback character of width 1
  idx := FHeight;
  SetLength(FBlank.Lines, idx);
  for i := 0 to idx - 1 do
    FBlank.Lines[i] := ' ';
  FBlank.Index := 32;
  FBlank.Width := 1;
end;

destructor TFigletFont.Destroy;
begin
  FChars.Free;
  inherited;
end;

function TFigletFont.GetCharacter(code : Integer) : TFigletCharacter;
begin
  if not FChars.TryGetValue(code, result) then
    result := FBlank;
end;

function TFigletFont.GetCharacters(const s : string) : TArray<TFigletCharacter>;
var
  i, count : Integer;
begin
  SetLength(result, Length(s));
  count := 0;
  for i := 1 to Length(s) do
  begin
    result[count] := GetCharacter(Ord(s[i]));
    Inc(count);
  end;
  SetLength(result, count);
end;

function TFigletFont.GetWidth(const s : string) : Integer;
var
  i : Integer;
begin
  result := 0;
  for i := 1 to Length(s) do
    Inc(result, GetCharacter(Ord(s[i])).Width);
end;

initialization

finalization
  FreeAndNil(GDefaultFont);

end.
