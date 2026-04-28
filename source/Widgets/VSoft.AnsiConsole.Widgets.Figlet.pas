unit VSoft.AnsiConsole.Widgets.Figlet;

{
  TFigletText - renders a string as large ASCII-art characters using a
  FIGlet .flf font. Ships with the embedded "Standard" font; consumers who
  want a different font can pass a pre-parsed TFigletFont.

  Wraps words across lines when the full text exceeds maxWidth.
}

interface

uses
  System.SysUtils,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Internal.FigletFont;

type
  IFigletText = interface(IRenderable)
    ['{F1A5D3E4-2B7C-4A8F-9D60-5E4D3B2A1C00}']
    function WithColor(const value : TAnsiColor) : IFigletText;
    function WithAlignment(value : TAlignment) : IFigletText;
    function WithPad(value : Boolean) : IFigletText;
  end;

  TFigletText = class(TInterfacedObject, IRenderable, IFigletText)
  strict private
    FFont      : TFigletFont;
    FText      : string;
    FColor     : TAnsiColor;
    FAlignment : TAlignment;
    FPad       : Boolean;
    function GetRows(maxWidth : Integer) : TArray<TArray<TFigletCharacter>>;
  public
    constructor Create(const text : string); overload;
    constructor Create(const font : TFigletFont; const text : string); overload;
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
    function WithColor(const value : TAnsiColor) : IFigletText;
    function WithAlignment(value : TAlignment) : IFigletText;
    function WithPad(value : Boolean) : IFigletText;
  end;

function FigletText(const text : string) : IFigletText; overload;
function FigletText(const font : TFigletFont; const text : string) : IFigletText; overload;

implementation

uses
  VSoft.AnsiConsole.Internal.Cell;

function FigletText(const text : string) : IFigletText;
begin
  result := TFigletText.Create(text);
end;

function FigletText(const font : TFigletFont; const text : string) : IFigletText;
begin
  result := TFigletText.Create(font, text);
end;

{ TFigletText }

constructor TFigletText.Create(const text : string);
begin
  Create(DefaultFigletFont, text);
end;

constructor TFigletText.Create(const font : TFigletFont; const text : string);
begin
  inherited Create;
  FFont := font;
  FText := text;
  FColor := TAnsiColor.Default;
  FAlignment := TAlignment.Left;
end;

function TFigletText.WithColor(const value : TAnsiColor) : IFigletText;
begin
  FColor := value;
  result := Self;
end;

function TFigletText.WithAlignment(value : TAlignment) : IFigletText;
begin
  FAlignment := value;
  result := Self;
end;

function TFigletText.WithPad(value : Boolean) : IFigletText;
begin
  FPad := value;
  result := Self;
end;

function TFigletText.GetRows(maxWidth : Integer) : TArray<TArray<TFigletCharacter>>;
var
  words    : TArray<string>;
  i, j     : Integer;
  start    : Integer;
  currentRow : TArray<TFigletCharacter>;
  totalW   : Integer;
  wordChars: TArray<TFigletCharacter>;
  wordW    : Integer;
  rowCount : Integer;
  charCount: Integer;
  ch       : TFigletCharacter;
  k        : Integer;
  wCount   : Integer;
begin
  // Split FText into whitespace-separated words
  SetLength(words, 0);
  wCount := 0;
  start := 1;
  for i := 1 to Length(FText) do
  begin
    if (FText[i] = ' ') or (FText[i] = #9) then
    begin
      if i > start then
      begin
        SetLength(words, wCount + 1);
        words[wCount] := Copy(FText, start, i - start);
        Inc(wCount);
      end;
      start := i + 1;
    end;
  end;
  if start <= Length(FText) then
  begin
    SetLength(words, wCount + 1);
    words[wCount] := Copy(FText, start, Length(FText) - start + 1);
  end;

  SetLength(result, 0);
  rowCount := 0;
  SetLength(currentRow, 0);
  charCount := 0;
  totalW := 0;

  for i := 0 to High(words) do
  begin
    wordChars := FFont.GetCharacters(words[i]);
    wordW := 0;
    for j := 0 to High(wordChars) do
      Inc(wordW, wordChars[j].Width);

    if (wordW + totalW < maxWidth) or (totalW = 0) then
    begin
      // Append word + trailing space character (space has a figlet glyph)
      for j := 0 to High(wordChars) do
      begin
        SetLength(currentRow, charCount + 1);
        currentRow[charCount] := wordChars[j];
        Inc(charCount);
      end;
      Inc(totalW, wordW);
      // add a space between words if not the last
      if (i < High(words)) then
      begin
        ch := FFont.GetCharacter(Ord(' '));
        SetLength(currentRow, charCount + 1);
        currentRow[charCount] := ch;
        Inc(charCount);
        Inc(totalW, ch.Width);
      end;
    end
    else
    begin
      // Flush current row
      SetLength(result, rowCount + 1);
      result[rowCount] := currentRow;
      Inc(rowCount);
      SetLength(currentRow, 0);
      charCount := 0;
      totalW := 0;

      // If the word itself is wider than maxWidth, split into chunks that
      // fit individually.
      if wordW > maxWidth then
      begin
        for k := 0 to High(wordChars) do
        begin
          if totalW + wordChars[k].Width > maxWidth then
          begin
            SetLength(result, rowCount + 1);
            result[rowCount] := currentRow;
            Inc(rowCount);
            SetLength(currentRow, 0);
            charCount := 0;
            totalW := 0;
          end;
          SetLength(currentRow, charCount + 1);
          currentRow[charCount] := wordChars[k];
          Inc(charCount);
          Inc(totalW, wordChars[k].Width);
        end;
      end
      else
      begin
        for j := 0 to High(wordChars) do
        begin
          SetLength(currentRow, charCount + 1);
          currentRow[charCount] := wordChars[j];
          Inc(charCount);
          Inc(totalW, wordChars[j].Width);
        end;
      end;
    end;
  end;

  if Length(currentRow) > 0 then
  begin
    SetLength(result, rowCount + 1);
    result[rowCount] := currentRow;
  end;
end;

function TFigletText.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
var
  w : Integer;
begin
  w := FFont.GetWidth(FText);
  if w > maxWidth then w := maxWidth;
  if w < 1 then w := 1;
  result := TMeasurement.Create(w, w);
end;

function TFigletText.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  rows    : TArray<TArray<TFigletCharacter>>;
  i, j, k : Integer;
  count   : Integer;
  lineText: string;
  lineWidth : Integer;
  leftPad, rightPad : Integer;
  style   : TAnsiStyle;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;

  if not FColor.IsDefault then
    style := TAnsiStyle.Plain.WithForeground(FColor)
  else
    style := TAnsiStyle.Plain;

  rows := GetRows(maxWidth);

  for i := 0 to High(rows) do
  begin
    for j := 0 to FFont.Height - 1 do
    begin
      lineText := '';
      lineWidth := 0;
      for k := 0 to High(rows[i]) do
      begin
        if j <= High(rows[i][k].Lines) then
        begin
          lineText := lineText + rows[i][k].Lines[j];
          Inc(lineWidth, rows[i][k].Width);
        end;
      end;

      if lineWidth > maxWidth then
      begin
        lineText := Copy(lineText, 1, maxWidth);
        lineWidth := maxWidth;
      end;

      leftPad  := 0;
      rightPad := 0;
      case FAlignment of
        TAlignment.Left :
        begin
          // Pad=True extends each line to maxWidth with trailing
          // whitespace; Pad=False (default) leaves the line where its
          // content ends.
          if FPad and (lineWidth < maxWidth) then
            rightPad := maxWidth - lineWidth;
        end;
        TAlignment.Center :
        begin
          leftPad := (maxWidth - lineWidth) div 2;
          if leftPad < 0 then leftPad := 0;
          if FPad then
          begin
            rightPad := maxWidth - lineWidth - leftPad;
            if rightPad < 0 then rightPad := 0;
          end;
        end;
        TAlignment.Right :
        begin
          leftPad := maxWidth - lineWidth;
          if leftPad < 0 then leftPad := 0;
        end;
      end;

      if leftPad > 0 then
        Push(TAnsiSegment.Whitespace(StringOfChar(' ', leftPad)));
      Push(TAnsiSegment.Text(lineText, style));
      if rightPad > 0 then
        Push(TAnsiSegment.Whitespace(StringOfChar(' ', rightPad)));

      Push(TAnsiSegment.LineBreak);
    end;
  end;
end;

end.
