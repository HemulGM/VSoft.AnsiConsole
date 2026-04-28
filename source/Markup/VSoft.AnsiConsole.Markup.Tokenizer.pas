unit VSoft.AnsiConsole.Markup.Tokenizer;

{
  Markup tokenizer. Consumes a string like:
      "[red bold]hello[/] world [[escaped]]"
  and produces a flat list of tokens:
      TMarkupTokenKind.Open("red bold"), TMarkupTokenKind.Text("hello"), TMarkupTokenKind.Close(""), TMarkupTokenKind.Text(" world ["), TMarkupTokenKind.Text("escaped]")
  (adjacent text tokens may be produced - they are merged by the parser.)

  Rules:
    [[  -> literal '['
    ]]  -> literal ']'
    [tag] or [/] or [/tag]
    unescaped ']' inside a tag is an error.
    unterminated '[' at end of string is an error.
}

{$SCOPEDENUMS ON}

interface

uses
  System.SysUtils;


type
  TMarkupTokenKind = (Text, Open, Close);

  TMarkupToken = record
    Kind  : TMarkupTokenKind;
    Value : string;   // text content, or tag body (without the '[' ']')
  end;

  TMarkupTokens = TArray<TMarkupToken>;

  EMarkupParseError = class(Exception)
  public
    Position : Integer;
    constructor Create(const msg : string; pos : Integer);
  end;

function TokenizeMarkup(const markup : string) : TMarkupTokens;

implementation

{ EMarkupParseError }

constructor EMarkupParseError.Create(const msg : string; pos : Integer);
begin
  inherited CreateFmt('%s (at position %d)', [msg, pos]);
  Position := pos;
end;

function TokenizeMarkup(const markup : string) : TMarkupTokens;
var
  i, n    : Integer;
  buf     : string;
  tagEnd  : Integer;
  tagBody : string;

  procedure PushText;
  begin
    if buf = '' then Exit;
    SetLength(result, Length(result) + 1);
    result[High(result)].Kind := TMarkupTokenKind.Text;
    result[High(result)].Value := buf;
    buf := '';
  end;

  procedure PushToken(kind : TMarkupTokenKind; const value : string);
  begin
    SetLength(result, Length(result) + 1);
    result[High(result)].Kind  := kind;
    result[High(result)].Value := value;
  end;

begin
  SetLength(result, 0);
  buf := '';
  i := 1;
  n := Length(markup);

  while i <= n do
  begin
    if markup[i] = '[' then
    begin
      if (i < n) and (markup[i + 1] = '[') then
      begin
        buf := buf + '[';
        Inc(i, 2);
        Continue;
      end;

      // find matching ']'
      tagEnd := i + 1;
      while (tagEnd <= n) and (markup[tagEnd] <> ']') do
        Inc(tagEnd);
      if tagEnd > n then
        raise EMarkupParseError.Create('Unterminated markup tag', i);

      PushText;
      tagBody := Copy(markup, i + 1, tagEnd - i - 1);
      if (Length(tagBody) > 0) and (tagBody[1] = '/') then
        PushToken(TMarkupTokenKind.Close, Trim(Copy(tagBody, 2, MaxInt)))
      else
        PushToken(TMarkupTokenKind.Open, tagBody);
      i := tagEnd + 1;
      Continue;
    end;

    if markup[i] = ']' then
    begin
      if (i < n) and (markup[i + 1] = ']') then
      begin
        buf := buf + ']';
        Inc(i, 2);
        Continue;
      end;
      raise EMarkupParseError.Create('Unescaped '']''', i);
    end;

    buf := buf + markup[i];
    Inc(i);
  end;

  PushText;
end;

end.
