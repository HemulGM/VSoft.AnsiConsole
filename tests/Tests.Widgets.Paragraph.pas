unit Tests.Widgets.Paragraph;

{
  Paragraph widget tests - mixed-style Append, alignment, overflow,
  embedded line breaks, and wrapping behaviour.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Widgets.Paragraph;

type
  [TestFixture]
  TParagraphTests = class
  public
    [Test] procedure Empty_RendersNothing;
    [Test] procedure SingleAppend_RendersText;
    [Test] procedure MultipleAppends_Concatenate;
    [Test] procedure StyledAppend_EmitsSGR;
    [Test] procedure EmbeddedLineBreak_StartsNewLine;
    [Test] procedure WrapsAtMaxWidth;
    [Test] procedure WithAlignmentRight_PadsLeft;
    [Test] procedure WithAlignmentCenter_PadsBothSides;
    [Test] procedure WithOverflowEllipsis_TruncatesLong;
    [Test] procedure FactoryWithText_PreloadsContent;
  end;

implementation

uses
  System.SysUtils,
  Testing.AnsiConsole;

function BuildPlain(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.NoColors, width, True, result, sink);
end;

function BuildTrueColor(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.TrueColor, width, True, result, sink);
end;

procedure TParagraphTests.Empty_RendersNothing;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildPlain(40, sink);
  console.Write(Paragraph);
  Assert.AreEqual('', Trim(sink.Text),
    'Empty paragraph should produce no visible output');
end;

procedure TParagraphTests.SingleAppend_RendersText;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildPlain(40, sink);
  console.Write(Paragraph.Append('hello'));
  Assert.IsTrue(Pos('hello', sink.Text) > 0);
end;

procedure TParagraphTests.MultipleAppends_Concatenate;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  para    : IParagraph;
begin
  console := BuildPlain(40, sink);
  para := Paragraph;
  para.Append('one ');
  para.Append('two ');
  para.Append('three');
  console.Write(para);
  Assert.IsTrue(Pos('one two three', sink.Text) > 0,
    'Successive Append calls should concatenate inline');
end;

procedure TParagraphTests.StyledAppend_EmitsSGR;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  para    : IParagraph;
begin
  console := BuildTrueColor(40, sink);
  para := Paragraph;
  para.Append('plain ');
  para.Append('lime', TAnsiStyle.Plain.WithForeground(TAnsiColor.Lime));
  para.Append(' tail');
  console.Write(para);
  Assert.IsTrue(Pos('38;2;0;255;0', sink.Text) > 0,
    'Styled span should emit a true-color foreground SGR');
  Assert.IsTrue(Pos('plain', sink.Text) > 0);
  Assert.IsTrue(Pos('lime',  sink.Text) > 0);
  Assert.IsTrue(Pos('tail',  sink.Text) > 0);
end;

procedure TParagraphTests.EmbeddedLineBreak_StartsNewLine;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
  posLine1, posLine2 : Integer;
begin
  console := BuildPlain(40, sink);
  console.Write(Paragraph.Append('first'#10'second'));
  output := sink.Text;
  posLine1 := Pos('first',  output);
  posLine2 := Pos('second', output);
  Assert.IsTrue(posLine1 > 0);
  Assert.IsTrue(posLine2 > posLine1);
  Assert.IsTrue(Pos(#10, Copy(output, posLine1, posLine2 - posLine1)) > 0,
    'Embedded LF should start a new render line');
end;

procedure TParagraphTests.WrapsAtMaxWidth;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
  i, lf   : Integer;
begin
  // 40 chars in a 10-wide console must wrap onto multiple lines.
  console := BuildPlain(10, sink);
  console.Write(Paragraph.Append(StringOfChar('a', 40)));
  output := sink.Text;
  lf := 0;
  for i := 1 to Length(output) do
    if output[i] = #10 then Inc(lf);
  Assert.IsTrue(lf >= 3,
    Format('40-char run in 10-wide console should wrap at least 4 lines (got %d breaks)', [lf]));
end;

procedure TParagraphTests.WithAlignmentRight_PadsLeft;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(20, sink);
  console.Write(Paragraph.Append('hi').WithAlignment(TAlignment.Right));
  output := sink.Text;
  // Right-aligned in a 20-wide row: 'hi' should be preceded by spaces and
  // sit at the right edge of a 20-cell line.
  Assert.IsTrue(Pos('  hi', output) > 0,
    'Right-aligned text must have leading whitespace');
  Assert.IsTrue(Length(TrimRight(output)) > 2,
    'Output should be padded out to the right edge');
end;

procedure TParagraphTests.WithAlignmentCenter_PadsBothSides;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
  posHi, leadingSpaces : Integer;
begin
  console := BuildPlain(20, sink);
  console.Write(Paragraph.Append('hi').WithAlignment(TAlignment.Center));
  output := sink.Text;
  posHi := Pos('hi', output);
  Assert.IsTrue(posHi > 1, 'Centered text should have leading spaces');
  leadingSpaces := posHi - 1;
  // 20 - 2 = 18 padding cells split roughly half/half = 9 leading.
  Assert.IsTrue((leadingSpaces >= 8) and (leadingSpaces <= 10),
    Format('Centered "hi" in 20-wide row should have ~9 leading spaces (got %d)',
      [leadingSpaces]));
end;

procedure TParagraphTests.WithOverflowEllipsis_TruncatesLong;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  // TOverflow.Ellipsis: lines wider than maxWidth get truncated with an ASCII
  // '...' suffix consuming the last 3 cells of the line.
  console := BuildPlain(8, sink);
  console.Write(Paragraph.Append('abcdefghijklmnop').WithOverflow(TOverflow.Ellipsis));
  output := sink.Text;
  Assert.IsTrue(Pos('...', output) > 0,
    'Overflow ellipsis should append "..." to the truncated line');
  Assert.IsTrue(Pos('p', output) = 0,
    'Trailing characters should be dropped to make room for the ellipsis');
end;

procedure TParagraphTests.FactoryWithText_PreloadsContent;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // Paragraph(text) overload preloads the first span.
  console := BuildPlain(40, sink);
  console.Write(Paragraph('preloaded'));
  Assert.IsTrue(Pos('preloaded', sink.Text) > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TParagraphTests);

end.
