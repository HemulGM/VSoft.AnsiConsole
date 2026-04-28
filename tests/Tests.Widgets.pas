unit Tests.Widgets;

{
  End-to-end widget tests: render via a captured console, assert on the
  emitted ANSI string or segment count.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Widgets.Text,
  VSoft.AnsiConsole.Widgets.Markup,
  VSoft.AnsiConsole.Widgets.Rule;

type
  [TestFixture]
  TWidgetTests = class
  public
    [Test] procedure Text_Plain_EmitsString;
    [Test] procedure Text_Styled_EmitsSGR;
    [Test] procedure Markup_InlineStyled_EmitsSGR;
    [Test] procedure Rule_NoTitle_FillsWidth;
    [Test] procedure Rule_WithTitle_Centres;
    [Test] procedure Rule_AsciiBorder_UsesDash;
    [Test] procedure Markup_Length_CountsCharsExcludingMarkup;
    [Test] procedure Markup_Lines_CountsExplicitLineBreaks;
    [Test] procedure Markup_Lines_EmptySource_IsZero;

    [Test] procedure Text_Empty_RendersNothing;
    [Test] procedure Text_WithLineBreak_SplitsLines;
    [Test] procedure Markup_EscapeMarkup_DoublesOpeningBracket;
    [Test] procedure Markup_NestedTags_CombineStyles;
    [Test] procedure Markup_OverflowEllipsis_TruncatesWideLine;
    [Test] procedure Rule_StyleAppliesToBorder;
    [Test] procedure Rule_AlignmentLeft_TitleAtStart;
    [Test] procedure Rule_AlignmentRight_TitleAtEnd;
  end;

implementation

uses
  System.SysUtils,
  Testing.AnsiConsole;

const
  ESC = #27;

procedure TWidgetTests.Text_Plain_EmitsString;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  BuildCapturedConsole(TColorSystem.TrueColor, 40, True, console, sink);
  console.Write(Text('hello'));
  Assert.AreEqual('hello', sink.Text);
end;

procedure TWidgetTests.Text_Styled_EmitsSGR;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  style   : TAnsiStyle;
begin
  BuildCapturedConsole(TColorSystem.Standard, 40, True, console, sink);
  style := TAnsiStyle.Plain.WithForeground(TAnsiColor.Red).WithDecorations([TAnsiDecoration.Bold]);
  console.Write(Text('X', style));
  // No leading SGR reset - the writer skips it when no style is on the wire yet.
  Assert.AreEqual(ESC + '[1;91mX' + ESC + '[0m', sink.Text);
end;

procedure TWidgetTests.Markup_InlineStyled_EmitsSGR;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  BuildCapturedConsole(TColorSystem.Standard, 40, True, console, sink);
  console.Write(Markup('[red]hi[/]'));
  Assert.Contains(sink.Text, 'hi');
  Assert.Contains(sink.Text, '91');    // bright-red FG under standard
  Assert.Contains(sink.Text, ESC + '[0m');
end;

procedure TWidgetTests.Rule_NoTitle_FillsWidth;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  i, w    : Integer;
  count   : Integer;
  text    : string;
begin
  w := 20;
  BuildCapturedConsole(TColorSystem.TrueColor, w, True, console, sink);
  console.Write(Rule);
  text := sink.Text;
  // Count occurrences of the unicode light horizontal line (U+2500).
  count := 0;
  for i := 1 to Length(text) do
    if text[i] = #$2500 then
      Inc(count);
  Assert.AreEqual(w, count);
end;

procedure TWidgetTests.Rule_WithTitle_Centres;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  BuildCapturedConsole(TColorSystem.TrueColor, 20, True, console, sink);
  console.Write(Rule('abc'));
  Assert.Contains(sink.Text, ' abc ');
end;

procedure TWidgetTests.Rule_AsciiBorder_UsesDash;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  BuildCapturedConsole(TColorSystem.TrueColor, 10, False, console, sink);  // unicode = False
  console.Write(Rule);
  Assert.AreEqual(StringOfChar('-', 10), sink.Text);
end;

procedure TWidgetTests.Markup_Length_CountsCharsExcludingMarkup;
var
  m : IMarkup;
begin
  m := Markup('[red]hello[/] world');
  // The bracketed style metadata is consumed by the parser and doesn't
  // count toward Length. 'hello world' = 11 chars.
  Assert.AreEqual(11, m.Length);
end;

procedure TWidgetTests.Markup_Lines_CountsExplicitLineBreaks;
var
  m : IMarkup;
begin
  m := Markup('one'#10'two'#10'three');
  Assert.AreEqual(3, m.Lines);
end;

procedure TWidgetTests.Markup_Lines_EmptySource_IsZero;
begin
  Assert.AreEqual(0, Markup('').Lines);
end;

procedure TWidgetTests.Text_Empty_RendersNothing;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  BuildCapturedConsole(TColorSystem.NoColors, 40, True, console, sink);
  console.Write(Text(''));
  Assert.AreEqual('', sink.Text, 'Empty Text widget should produce no output');
end;

procedure TWidgetTests.Text_WithLineBreak_SplitsLines;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
  posA, posB : Integer;
begin
  BuildCapturedConsole(TColorSystem.NoColors, 40, True, console, sink);
  console.Write(Text('aaa'#10'bbb'));
  output := sink.Text;
  posA := Pos('aaa', output);
  posB := Pos('bbb', output);
  Assert.IsTrue(posA > 0);
  Assert.IsTrue(posB > posA);
  Assert.IsTrue(Pos(#10, Copy(output, posA, posB - posA)) > 0,
    'Embedded LF should produce a line break in the rendered Text');
end;

procedure TWidgetTests.Markup_EscapeMarkup_DoublesOpeningBracket;
begin
  // EscapeMarkup turns "[" into "[[" so the parser sees a literal bracket.
  Assert.AreEqual('plain [[bracket]', EscapeMarkup('plain [bracket]'),
    'Open bracket should be doubled; close bracket left alone');
  Assert.AreEqual('no brackets here', EscapeMarkup('no brackets here'),
    'Strings without brackets should pass through unchanged');
end;

procedure TWidgetTests.Markup_NestedTags_CombineStyles;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  // [red][bold]X[/][/]: outer red still applies to X, inner bold layered on
  // top. TColorSystem.TrueColor exposes both as SGR codes - red is 38;2;255;0;0 and
  // bold is SGR 1.
  BuildCapturedConsole(TColorSystem.TrueColor, 40, True, console, sink);
  console.Write(Markup('[red][bold]X[/][/]'));
  output := sink.Text;
  Assert.IsTrue(Pos('38;2;255;0;0', output) > 0, 'Outer red colour should survive nesting');
  Assert.IsTrue(Pos('1',            output) > 0, 'Inner bold (SGR 1) should layer on');
  Assert.IsTrue(Pos('X',            output) > 0, 'Body text should render');
end;

procedure TWidgetTests.Markup_OverflowEllipsis_TruncatesWideLine;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // Markup widget with WithOverflow(TOverflow.Ellipsis) on a 26-char input in an
  // 8-cell console: the truncated line ends in '...'.
  BuildCapturedConsole(TColorSystem.NoColors, 8, True, console, sink);
  console.Write(Markup('abcdefghijklmnopqrstuvwxyz').WithOverflow(TOverflow.Ellipsis));
  Assert.IsTrue(Pos('...', sink.Text) > 0,
    'Ellipsis overflow should append "..." when content exceeds maxWidth');
  Assert.IsTrue(Pos('z', sink.Text) = 0,
    'Trailing characters should be dropped to make room for the ellipsis');
end;

procedure TWidgetTests.Rule_StyleAppliesToBorder;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // True-color console + Lime rule style => RGB(0,255,0) wraps the rule
  // line glyphs.
  BuildCapturedConsole(TColorSystem.TrueColor, 20, True, console, sink);
  console.Write(Rule.WithStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Lime)));
  Assert.IsTrue(Pos('38;2;0;255;0', sink.Text) > 0,
    'Rule.WithStyle should drive the border-glyph SGR colour');
end;

procedure TWidgetTests.Rule_AlignmentLeft_TitleAtStart;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
  posTitle : Integer;
begin
  // Left-aligned title sits near the start of the rule line, not centred.
  BuildCapturedConsole(TColorSystem.NoColors, 30, True, console, sink);
  console.Write(Rule('hi').WithAlignment(TAlignment.Left));
  output := sink.Text;
  posTitle := Pos('hi', output);
  Assert.IsTrue(posTitle > 0, 'Title should appear');
  // Left-aligned: the title should sit in the first half of the rule.
  Assert.IsTrue(posTitle < 15,
    Format('Left alignment should put "hi" near the start (got col %d / 30)',
      [posTitle]));
end;

procedure TWidgetTests.Rule_AlignmentRight_TitleAtEnd;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
  posTitle : Integer;
begin
  BuildCapturedConsole(TColorSystem.NoColors, 30, True, console, sink);
  console.Write(Rule('hi').WithAlignment(TAlignment.Right));
  output := sink.Text;
  posTitle := Pos('hi', output);
  Assert.IsTrue(posTitle > 0, 'Title should appear');
  // Right-aligned: the title should sit in the second half.
  Assert.IsTrue(posTitle > 15,
    Format('Right alignment should put "hi" near the end (got col %d / 30)',
      [posTitle]));
end;

initialization
  TDUnitX.RegisterTestFixture(TWidgetTests);

end.
