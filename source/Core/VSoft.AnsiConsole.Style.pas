unit VSoft.AnsiConsole.Style;

{
  TAnsiStyle - value-type text styling (foreground, background, decorations,
  optional hyperlink). Zero-initialised style is "Plain" (no colors, no
  decorations, no link).
}

interface

uses
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color;

type
  TAnsiStyle = record
  strict private
    FForeground  : TAnsiColor;
    FBackground  : TAnsiColor;
    FDecorations : TAnsiDecorations;
    FLink        : string;
  public
    { Factories }
    class function Plain : TAnsiStyle; static;
    class function Create(const fg : TAnsiColor) : TAnsiStyle; overload; static;
    class function Create(const fg, bg : TAnsiColor) : TAnsiStyle; overload; static;
    class function Create(const fg, bg : TAnsiColor; decorations : TAnsiDecorations) : TAnsiStyle; overload; static;
    { Parse a style expression (Spectre-compatible). The text may include
      surrounding brackets - "[red bold on blue]" and "red bold on blue"
      both parse identically. Parse raises EConvertError on malformed
      input; TryParse returns False instead. }
    class function Parse(const text : string) : TAnsiStyle; static;
    class function TryParse(const text : string; out value : TAnsiStyle) : Boolean; static;

    { Returns a copy of Self with the given field replaced. }
    function WithForeground(const value : TAnsiColor) : TAnsiStyle;
    function WithBackground(const value : TAnsiColor) : TAnsiStyle;
    function WithDecorations(const value : TAnsiDecorations) : TAnsiStyle;
    function WithLink(const value : string) : TAnsiStyle;

    { Overlays `other` on top of Self:
        - if other.Foreground is not default it wins, else keep Self.Foreground.
        - background likewise.
        - decorations are unioned.
        - link: other wins if non-empty. }
    function Combine(const other : TAnsiStyle) : TAnsiStyle;

    function IsPlain : Boolean;
    function Equals(const other : TAnsiStyle) : Boolean;
    { Reverse of Parse: emits a space-separated style expression suitable
      for wrapping in markup brackets, e.g. 'red bold on blue link=http://x'.
      Returns '' for the Plain style. }
    function ToMarkup : string;

    property Foreground  : TAnsiColor       read FForeground;
    property Background  : TAnsiColor       read FBackground;
    property Decorations : TAnsiDecorations read FDecorations;
    property Link        : string           read FLink;
  end;

implementation

uses
  System.SysUtils,
  VSoft.AnsiConsole.Markup.Parser;

{ TAnsiStyle }

class function TAnsiStyle.Plain : TAnsiStyle;
begin
  result.FForeground  := TAnsiColor.Default;
  result.FBackground  := TAnsiColor.Default;
  result.FDecorations := [];
  result.FLink        := '';
end;

class function TAnsiStyle.Create(const fg : TAnsiColor) : TAnsiStyle;
begin
  result.FForeground  := fg;
  result.FBackground  := TAnsiColor.Default;
  result.FDecorations := [];
  result.FLink        := '';
end;

class function TAnsiStyle.Create(const fg, bg : TAnsiColor) : TAnsiStyle;
begin
  result.FForeground  := fg;
  result.FBackground  := bg;
  result.FDecorations := [];
  result.FLink        := '';
end;

class function TAnsiStyle.Create(const fg, bg : TAnsiColor; decorations : TAnsiDecorations) : TAnsiStyle;
begin
  result.FForeground  := fg;
  result.FBackground  := bg;
  result.FDecorations := decorations;
  result.FLink        := '';
end;

function TAnsiStyle.WithForeground(const value : TAnsiColor) : TAnsiStyle;
begin
  result := Self;
  result.FForeground := value;
end;

function TAnsiStyle.WithBackground(const value : TAnsiColor) : TAnsiStyle;
begin
  result := Self;
  result.FBackground := value;
end;

function TAnsiStyle.WithDecorations(const value : TAnsiDecorations) : TAnsiStyle;
begin
  result := Self;
  result.FDecorations := value;
end;

function TAnsiStyle.WithLink(const value : string) : TAnsiStyle;
begin
  result := Self;
  result.FLink := value;
end;

function TAnsiStyle.Combine(const other : TAnsiStyle) : TAnsiStyle;
begin
  result := Self;
  if not other.FForeground.IsDefault then
    result.FForeground := other.FForeground;
  if not other.FBackground.IsDefault then
    result.FBackground := other.FBackground;
  result.FDecorations := result.FDecorations + other.FDecorations;
  if other.FLink <> '' then
    result.FLink := other.FLink;
end;

function TAnsiStyle.IsPlain : Boolean;
begin
  result := FForeground.IsDefault and FBackground.IsDefault
        and (FDecorations = []) and (FLink = '');
end;

function TAnsiStyle.Equals(const other : TAnsiStyle) : Boolean;
begin
  result := FForeground.Equals(other.FForeground)
        and FBackground.Equals(other.FBackground)
        and (FDecorations = other.FDecorations)
        and (FLink = other.FLink);
end;

class function TAnsiStyle.TryParse(const text : string; out value : TAnsiStyle) : Boolean;
var
  s : string;
begin
  s := Trim(text);
  // Tolerate the bracketed form so callers can pass either
  // 'red bold' or '[red bold]'.
  if (Length(s) >= 2) and (s[1] = '[') and (s[Length(s)] = ']') then
    s := Trim(Copy(s, 2, Length(s) - 2));
  result := ParseStyleExpr(s, value);
end;

class function TAnsiStyle.Parse(const text : string) : TAnsiStyle;
begin
  if not TryParse(text, result) then
    raise EConvertError.CreateFmt('Invalid style "%s"', [text]);
end;

function TAnsiStyle.ToMarkup : string;
const
  DECO_NAMES : array[TAnsiDecoration] of string = (
    'bold', 'dim', 'italic', 'underline', 'blink', 'rapidblink',
    'invert', 'conceal', 'strikethrough'
  );
var
  parts : string;
  d     : TAnsiDecoration;

  procedure Append(const word : string);
  begin
    if word = '' then Exit;
    if parts = '' then
      parts := word
    else
      parts := parts + ' ' + word;
  end;
begin
  parts := '';
  for d := Low(TAnsiDecoration) to High(TAnsiDecoration) do
    if d in FDecorations then
      Append(DECO_NAMES[d]);
  if not FForeground.IsDefault then
    Append(FForeground.ToMarkup);
  if not FBackground.IsDefault then
  begin
    Append('on');
    Append(FBackground.ToMarkup);
  end;
  if FLink <> '' then
    Append('link=' + FLink);
  result := parts;
end;

end.
