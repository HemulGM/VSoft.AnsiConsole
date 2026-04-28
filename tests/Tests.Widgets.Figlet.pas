unit Tests.Widgets.Figlet;

{
  Figlet text widget tests - row count and bundled-font height.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Widgets.Figlet;

type
  [TestFixture]
  TFigletTests = class
  public
    [Test] procedure RendersHeightRows;
    [Test] procedure FontHasStandardHeight;
    [Test] procedure EmptyText_RendersBlank;
    [Test] procedure WithColor_EmitsTrueColorSGR;
    [Test] procedure WithAlignmentRight_PadsLeft;
    [Test] procedure LongerText_RendersWiderOutput;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Types,
  Testing.AnsiConsole,
  VSoft.AnsiConsole.Internal.FigletFont;

function BuildPlain(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.NoColors, width, True, result, sink);
end;

procedure TFigletTests.RendersHeightRows;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  lines   : TStringDynArray;
  nonEmpty, i : Integer;
begin
  console := BuildPlain(80, sink);
  console.Write(FigletText('AB'));
  lines := SplitString(sink.Text, #10);
  nonEmpty := 0;
  for i := 0 to High(lines) do
    if Trim(lines[i]) <> '' then Inc(nonEmpty);
  // Standard font has 6-row characters; we expect 6 non-empty text rows.
  Assert.IsTrue(nonEmpty >= 5, Format('Expected at least 5 non-empty rows, got %d', [nonEmpty]));
end;

procedure TFigletTests.FontHasStandardHeight;
var
  font : TFigletFont;
begin
  font := DefaultFigletFont;
  Assert.AreEqual(6, font.Height, 'Standard FIGlet font height is 6');
end;

procedure TFigletTests.EmptyText_RendersBlank;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(FigletText(''));
  output := Trim(sink.Text);
  Assert.AreEqual('', output, 'Empty FIGlet should produce no visible glyphs');
end;

procedure TFigletTests.WithColor_EmitsTrueColorSGR;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // True-color console so we can verify the color flowed through.
  BuildCapturedConsole(TColorSystem.TrueColor, 80, True, console, sink);
  console.Write(FigletText('A').WithColor(TAnsiColor.Lime));
  Assert.IsTrue(Pos('38;2;0;255;0', sink.Text) > 0,
    'WithColor(Lime) should emit a true-color foreground SGR');
end;

procedure TFigletTests.WithAlignmentRight_PadsLeft;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  lines   : TStringDynArray;
  i, leadingSpaces : Integer;
  candidateLine : string;
begin
  // FigletText('A') is much narrower than 80 cells. With right alignment
  // the rendered glyph should be preceded by leading whitespace on each
  // line that contains glyph content.
  console := BuildPlain(80, sink);
  console.Write(FigletText('A').WithAlignment(TAlignment.Right));
  lines := SplitString(sink.Text, #10);
  leadingSpaces := 0;
  for i := 0 to High(lines) do
  begin
    candidateLine := lines[i];
    if Trim(candidateLine) = '' then Continue;
    leadingSpaces := 0;
    while (leadingSpaces < Length(candidateLine))
      and (candidateLine[leadingSpaces + 1] = ' ') do
      Inc(leadingSpaces);
    Break;
  end;
  Assert.IsTrue(leadingSpaces > 10,
    Format('Right-aligned FIGlet should have substantial left padding (got %d)',
      [leadingSpaces]));
end;

procedure TFigletTests.LongerText_RendersWiderOutput;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  short, long : Integer;
  lines : TStringDynArray;
  i : Integer;
  curWidth : Integer;
begin
  console := BuildPlain(80, sink);
  console.Write(FigletText('A'));
  short := 0;
  lines := SplitString(sink.Text, #10);
  for i := 0 to High(lines) do
  begin
    curWidth := Length(TrimRight(lines[i]));
    if curWidth > short then short := curWidth;
  end;

  console := BuildPlain(80, sink);
  console.Write(FigletText('AAAA'));
  long := 0;
  lines := SplitString(sink.Text, #10);
  for i := 0 to High(lines) do
  begin
    curWidth := Length(TrimRight(lines[i]));
    if curWidth > long then long := curWidth;
  end;

  Assert.IsTrue(long > short,
    Format('"AAAA" should render wider than "A" (short=%d, long=%d)',
      [short, long]));
end;

initialization
  TDUnitX.RegisterTestFixture(TFigletTests);

end.
