unit VSoft.AnsiConsole.Markup.Parser;

{
  Markup parser. Converts a tokenized markup string into a flat array of
  styled segments.

  Style grammar inside a tag body (whitespace-separated):
    decoration : bold | dim | italic | underline | blink | invert | strikethrough
    color      : named-color | #RRGGBB | #RGB
    link       : 'link' | 'link=<url>'
    background : 'on' color
  Any number of these in any order. "on" must be followed by a color.

  Unknown tokens are ignored rather than raising, so the renderer stays
  resilient to minor user typos - call ValidateMarkup from tests if strictness
  is needed.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment;

function ParseMarkup(const markup : string) : TAnsiSegments; overload;
function ParseMarkup(const markup : string; const baseStyle : TAnsiStyle) : TAnsiSegments; overload;

{ Parses a style expression like "red bold on blue" into a TAnsiStyle. }
function ParseStyleExpr(const expr : string; out style : TAnsiStyle) : Boolean;

implementation

uses
  VSoft.AnsiConsole.Markup.Tokenizer,
  VSoft.AnsiConsole.Emoji;

function TryLookupNamedColor(const name : string; out color : TAnsiColor) : Boolean;
begin
  result := TAnsiColor.TryFromName(name, color);
end;

function TryLookupDecoration(const name : string; out d : TAnsiDecoration) : Boolean;
var
  lname : string;
begin
  lname := LowerCase(name);
  result := True;
  if      lname = 'bold'           then d := TAnsiDecoration.Bold
  else if lname = 'dim'            then d := TAnsiDecoration.Dim
  else if lname = 'italic'         then d := TAnsiDecoration.Italic
  else if lname = 'underline'      then d := TAnsiDecoration.Underline
  else if lname = 'blink'          then d := TAnsiDecoration.SlowBlink
  else if lname = 'rapidblink'     then d := TAnsiDecoration.RapidBlink
  else if lname = 'invert'         then d := TAnsiDecoration.Invert
  else if lname = 'reverse'        then d := TAnsiDecoration.Invert
  else if lname = 'conceal'        then d := TAnsiDecoration.Conceal
  else if lname = 'strikethrough'  then d := TAnsiDecoration.Strikethrough
  else if lname = 'strike'         then d := TAnsiDecoration.Strikethrough
  else result := False;
end;

function TryParseColor(const token : string; out color : TAnsiColor) : Boolean;
begin
  if (token <> '') and (token[1] = '#') then
  begin
    try
      color := TAnsiColor.FromHex(token);
      result := True;
    except
      result := False;
    end;
    Exit;
  end;
  result := TryLookupNamedColor(token, color);
end;

function SplitWords(const s : string) : TArray<string>;
var
  i, start : Integer;
begin
  SetLength(result, 0);
  start := 1;
  i := 1;
  while i <= Length(s) do
  begin
    if (s[i] = ' ') or (s[i] = #9) then
    begin
      if i > start then
      begin
        SetLength(result, Length(result) + 1);
        result[High(result)] := Copy(s, start, i - start);
      end;
      start := i + 1;
    end;
    Inc(i);
  end;
  if i > start then
  begin
    SetLength(result, Length(result) + 1);
    result[High(result)] := Copy(s, start, i - start);
  end;
end;

function ParseStyleExpr(const expr : string; out style : TAnsiStyle) : Boolean;
var
  words     : TArray<string>;
  i         : Integer;
  word, low : string;
  expectBg  : Boolean;
  color     : TAnsiColor;
  deco      : TAnsiDecoration;
  decos     : TAnsiDecorations;
  fg, bg    : TAnsiColor;
  link      : string;
  hasFG, hasBG : Boolean;
begin
  style := TAnsiStyle.Plain;
  expectBg := False;
  decos := [];
  fg := TAnsiColor.Default;
  bg := TAnsiColor.Default;
  link := '';
  hasFG := False;
  hasBG := False;
  result := False;

  words := SplitWords(Trim(expr));
  if Length(words) = 0 then
    Exit;

  for i := 0 to High(words) do
  begin
    word := words[i];
    if word = '' then Continue;
    low := LowerCase(word);

    if low = 'on' then
    begin
      expectBg := True;
      Continue;
    end;

    if (low = 'link') or (Pos('link=', low) = 1) then
    begin
      if low = 'link' then
        link := ''   // link will be empty - consumer treats as no-op
      else
        link := Copy(word, 6, MaxInt);
      Continue;
    end;

    if TryParseColor(word, color) then
    begin
      if expectBg then
      begin
        bg := color;
        hasBG := True;
        expectBg := False;
      end
      else
      begin
        fg := color;
        hasFG := True;
      end;
      Continue;
    end;

    if TryLookupDecoration(word, deco) then
    begin
      Include(decos, deco);
      Continue;
    end;

    // Unknown token - ignore but do not flag as success-only.
  end;

  if hasFG then style := style.WithForeground(fg);
  if hasBG then style := style.WithBackground(bg);
  if link <> '' then
  begin
    // OSC 8 alone is invisible: terminals don't auto-decorate hyperlinks,
    // so a bare [link=...] segment looks identical to plain text and the
    // user can't tell it's clickable. Match Rich's convention by adding
    // underline when the tag specifies no decoration of its own. Any
    // explicit decoration tokens win, so [bold link=...] stays bold-only.
    if decos = [] then
      Include(decos, TAnsiDecoration.Underline);
    style := style.WithLink(link);
  end;
  if decos <> [] then style := style.WithDecorations(decos);

  result := True;
end;

function ParseMarkup(const markup : string) : TAnsiSegments;
begin
  result := ParseMarkup(markup, TAnsiStyle.Plain);
end;

procedure EmitText(var segs : TAnsiSegments; var count : Integer;
                      const text : string; const style : TAnsiStyle);
var
  buf       : string;
  i         : Integer;
  ch        : Char;
begin
  if text = '' then Exit;
  buf := '';
  for i := 1 to Length(text) do
  begin
    ch := text[i];
    if ch = #10 then
    begin
      if buf <> '' then
      begin
        SetLength(segs, count + 1);
        segs[count] := TAnsiSegment.Text(TEmoji.Replace(buf), style);
        Inc(count);
        buf := '';
      end;
      SetLength(segs, count + 1);
      segs[count] := TAnsiSegment.LineBreak;
      Inc(count);
    end
    else if ch = #13 then
    begin
      // swallow CR - LF drives the line break
    end
    else
      buf := buf + ch;
  end;
  if buf <> '' then
  begin
    SetLength(segs, count + 1);
    segs[count] := TAnsiSegment.Text(TEmoji.Replace(buf), style);
    Inc(count);
  end;
end;

function ParseMarkup(const markup : string; const baseStyle : TAnsiStyle) : TAnsiSegments;
var
  tokens : TMarkupTokens;
  stack  : TStack<TAnsiStyle>;
  i      : Integer;
  tok    : TMarkupToken;
  tagStyle, topStyle, combined : TAnsiStyle;
  count  : Integer;
begin
  tokens := TokenizeMarkup(markup);
  SetLength(result, 0);
  count := 0;

  stack := TStack<TAnsiStyle>.Create;
  try
    stack.Push(baseStyle);

    for i := 0 to High(tokens) do
    begin
      tok := tokens[i];
      case tok.Kind of
        TMarkupTokenKind.Text:
          begin
            topStyle := stack.Peek;
            EmitText(result, count, tok.Value, topStyle);
          end;
        TMarkupTokenKind.Open:
          begin
            ParseStyleExpr(tok.Value, tagStyle);
            topStyle := stack.Peek;
            combined := topStyle.Combine(tagStyle);
            stack.Push(combined);
          end;
        TMarkupTokenKind.Close:
          begin
            if stack.Count > 1 then
              stack.Pop;
            // else: unbalanced - silently ignore for robustness.
          end;
      end;
    end;
  finally
    stack.Free;
  end;

  SetLength(result, count);
end;

end.
