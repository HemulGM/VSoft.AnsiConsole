unit Tests.Widgets.BreakdownChart;

{
  BreakdownChart widget tests - segmented full-width bar with tag labels.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Widgets.BreakdownChart;

type
  [TestFixture]
  TBreakdownChartTests = class
  public
    [Test] procedure FullWidth;
    [Test] procedure ShowsTags;
    [Test] procedure WithShowTagsFalse_HidesTagRow;
    [Test] procedure WithShowTagValuesFalse_KeepsLabelsOnly;
    [Test] procedure WithCompactFalse_AddsBlankLineBeforeTags;
    [Test] procedure WithValueFormatter_FormatsTagValues;
    [Test] procedure ItemColor_EmitsTrueColorSGR;
    [Test] procedure EmptyChart_RendersWithoutError;
    [Test] procedure ItemLabel_ParsesMarkupTags;
  end;

implementation

uses
  System.SysUtils,
  Testing.AnsiConsole;

function BuildPlainAscii(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.NoColors, width, False, result, sink);
end;

procedure TBreakdownChartTests.FullWidth;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  chart   : IBreakdownChart;
begin
  console := BuildPlainAscii(40, sink);
  chart := BreakdownChart
           .AddItem('x', 30, TAnsiColor.Red)
           .AddItem('y', 70, TAnsiColor.Blue)
           .WithWidth(20);
  console.Write(chart);
  Assert.IsTrue(Pos('#', sink.Text) > 0, 'ASCII breakdown should emit "#"');
end;

procedure TBreakdownChartTests.ShowsTags;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  chart   : IBreakdownChart;
begin
  console := BuildPlainAscii(60, sink);
  chart := BreakdownChart
           .AddItem('alpha', 10, TAnsiColor.Red)
           .AddItem('beta', 20, TAnsiColor.Blue);
  console.Write(chart);
  Assert.IsTrue(Pos('alpha', sink.Text) > 0);
  Assert.IsTrue(Pos('beta',  sink.Text) > 0);
end;

procedure TBreakdownChartTests.WithShowTagsFalse_HidesTagRow;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildPlainAscii(40, sink);
  console.Write(BreakdownChart
    .AddItem('alpha', 10, TAnsiColor.Red)
    .AddItem('beta',  20, TAnsiColor.Blue)
    .WithShowTags(False)
    .WithWidth(20));
  Assert.IsTrue(Pos('alpha', sink.Text) = 0,
    'Tag row should be suppressed when ShowTags=False');
  Assert.IsTrue(Pos('beta',  sink.Text) = 0);
  // Bar should still render.
  Assert.IsTrue(Pos('#', sink.Text) > 0, 'Bar should still render');
end;

procedure TBreakdownChartTests.WithShowTagValuesFalse_KeepsLabelsOnly;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildPlainAscii(60, sink);
  console.Write(BreakdownChart
    .AddItem('alpha', 17, TAnsiColor.Red)
    .AddItem('beta',  23, TAnsiColor.Blue)
    .WithShowTagValues(False));
  Assert.IsTrue(Pos('alpha', sink.Text) > 0, 'Labels should still render');
  Assert.IsTrue(Pos('beta',  sink.Text) > 0);
  Assert.IsTrue(Pos('17', sink.Text) = 0,
    'Numeric value should not appear when ShowTagValues=False');
  Assert.IsTrue(Pos('23', sink.Text) = 0);
end;

procedure TBreakdownChartTests.WithCompactFalse_AddsBlankLineBeforeTags;

  function CountLF(const s : string) : Integer;
  var
    i : Integer;
  begin
    result := 0;
    for i := 1 to Length(s) do
      if s[i] = #10 then Inc(result);
  end;

var
  console     : IAnsiConsole;
  sink        : ICapturedAnsiOutput;
  compactLfs, nonCompactLfs : Integer;
begin
  // Compact mode (default): bar -> tags on the next line.
  console := BuildPlainAscii(60, sink);
  console.Write(BreakdownChart
    .AddItem('alpha', 10, TAnsiColor.Red)
    .AddItem('beta',  20, TAnsiColor.Blue)
    .AddItem('gamma', 30, TAnsiColor.Green)
    .WithCompact(True));
  compactLfs := CountLF(sink.Text);

  // Non-compact mode: an extra blank line separates the bar from the tags,
  // adding exactly one more line break than the compact form.
  console := BuildPlainAscii(60, sink);
  console.Write(BreakdownChart
    .AddItem('alpha', 10, TAnsiColor.Red)
    .AddItem('beta',  20, TAnsiColor.Blue)
    .AddItem('gamma', 30, TAnsiColor.Green)
    .WithCompact(False));
  nonCompactLfs := CountLF(sink.Text);

  Assert.IsTrue(nonCompactLfs > compactLfs,
    Format('Non-compact should add at least one more line break than compact ' +
           '(compact=%d, nonCompact=%d)', [compactLfs, nonCompactLfs]));
end;

procedure TBreakdownChartTests.WithValueFormatter_FormatsTagValues;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildPlainAscii(60, sink);
  console.Write(BreakdownChart
    .AddItem('cpu', 75, TAnsiColor.Red)
    .WithValueFormatter(
      function(value : Double) : string
      begin
        result := Format('%.0f%%', [value]);
      end));
  Assert.IsTrue(Pos('75%', sink.Text) > 0,
    'Custom formatter "75%%" should appear in the tag value');
end;

procedure TBreakdownChartTests.ItemColor_EmitsTrueColorSGR;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  BuildCapturedConsole(TColorSystem.TrueColor, 40, False, console, sink);
  console.Write(BreakdownChart
    .AddItem('a', 10, TAnsiColor.Lime)   // RGB 0,255,0
    .AddItem('b', 10, TAnsiColor.Red)
    .WithWidth(20));
  Assert.IsTrue(Pos('38;2;0;255;0', sink.Text) > 0,
    'Lime segment should emit a true-color foreground SGR');
end;

procedure TBreakdownChartTests.EmptyChart_RendersWithoutError;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildPlainAscii(40, sink);
  console.Write(BreakdownChart);   // no items
  Assert.IsNotNull(sink, 'Render should not raise when there are no items');
end;

procedure TBreakdownChartTests.ItemLabel_ParsesMarkupTags;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlainAscii(60, sink);
  console.Write(BreakdownChart
    .AddItem('[bold]Elixir[/]', 35, TAnsiColor.Fuchsia)
    .AddItem('Ruby',             15, TAnsiColor.Red)
    .WithWidth(30));
  output := sink.Text;
  Assert.IsTrue(Pos('Elixir', output) > 0,
    'Body of the markup tag must appear in the tag row');
  Assert.IsTrue(Pos('[bold]', output) = 0,
    'Literal markup tag must not leak through to the breakdown tag label');
end;

initialization
  TDUnitX.RegisterTestFixture(TBreakdownChartTests);

end.
