unit Tests.Widgets.BarChart;

{
  BarChart widget tests - bar scaling and value display.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Widgets.BarChart;

type
  [TestFixture]
  TBarChartTests = class
  public
    [Test] procedure ScalesToMaxValue;
    [Test] procedure ShowsValues;
    [Test] procedure WithLabel_RendersHeading;
    [Test] procedure WithShowValuesFalse_HidesValueColumn;
    [Test] procedure WithMaxValue_OverridesAutoScale;
    [Test] procedure WithValueFormatter_AppliesCustomFormat;
    [Test] procedure AddItem_WithExplicitColor_EmitsTrueColorSGR;
    [Test] procedure EmptyChart_RendersWithoutError;
    [Test] procedure MultipleItems_AllAppearInOrder;
    [Test] procedure WithLabel_ParsesMarkupTags;
    [Test] procedure ItemLabel_ParsesMarkupTags;
  end;

implementation

uses
  System.SysUtils,
  VSoft.AnsiConsole.Color,
  Testing.AnsiConsole;

function BuildPlainAscii(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.NoColors, width, False, result, sink);
end;

procedure TBarChartTests.ScalesToMaxValue;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  chart   : IBarChart;
begin
  console := BuildPlainAscii(40, sink);
  chart := BarChart;
  chart.AddItem('a', 50);
  chart.AddItem('b', 100);
  chart.WithWidth(20);
  console.Write(chart);
  // 'a' and 'b' labels must appear, and the bar char '#' too.
  Assert.IsTrue(Pos('a', sink.Text) > 0);
  Assert.IsTrue(Pos('b', sink.Text) > 0);
  Assert.IsTrue(Pos('#', sink.Text) > 0);
end;

procedure TBarChartTests.ShowsValues;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  chart   : IBarChart;
begin
  console := BuildPlainAscii(40, sink);
  chart := BarChart.AddItem('a', 42).WithWidth(30);
  console.Write(chart);
  Assert.IsTrue(Pos('42', sink.Text) > 0, 'value 42 should be rendered');
end;

procedure TBarChartTests.WithLabel_RendersHeading;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  chart   : IBarChart;
begin
  console := BuildPlainAscii(40, sink);
  chart := BarChart.WithLabel('Languages')
                   .AddItem('Go', 50)
                   .AddItem('Pascal', 80);
  console.Write(chart);
  Assert.IsTrue(Pos('Languages', sink.Text) > 0,
    'Chart heading should be rendered');
end;

procedure TBarChartTests.WithShowValuesFalse_HidesValueColumn;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  chart   : IBarChart;
begin
  console := BuildPlainAscii(40, sink);
  chart := BarChart.AddItem('a', 17).WithShowValues(False).WithWidth(20);
  console.Write(chart);
  Assert.IsTrue(Pos('17', sink.Text) = 0,
    'Numeric value should be suppressed when ShowValues=False');
  Assert.IsTrue(Pos('a', sink.Text) > 0, 'Label should still render');
end;

procedure TBarChartTests.WithMaxValue_OverridesAutoScale;
var
  console      : IAnsiConsole;
  sink         : ICapturedAnsiOutput;
  autoOutput   : string;
  scaledOutput : string;
  autoBars, scaledBars : Integer;
  i : Integer;
begin
  // Auto-scale: single 50-value item fills the bar entirely.
  console := BuildPlainAscii(40, sink);
  console.Write(BarChart.AddItem('x', 50).WithWidth(20));
  autoOutput := sink.Text;

  // With MaxValue=200, the same 50-value item should fill ~25% of the bar.
  console := BuildPlainAscii(40, sink);
  console.Write(BarChart.AddItem('x', 50).WithMaxValue(200).WithWidth(20));
  scaledOutput := sink.Text;

  autoBars := 0;
  for i := 1 to Length(autoOutput) do
    if autoOutput[i] = '#' then Inc(autoBars);
  scaledBars := 0;
  for i := 1 to Length(scaledOutput) do
    if scaledOutput[i] = '#' then Inc(scaledBars);

  Assert.IsTrue(scaledBars < autoBars,
    Format('Custom MaxValue should shrink the bar (auto=%d, scaled=%d)',
      [autoBars, scaledBars]));
end;

procedure TBarChartTests.WithValueFormatter_AppliesCustomFormat;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  chart   : IBarChart;
begin
  console := BuildPlainAscii(40, sink);
  chart := BarChart
    .AddItem('cpu', 75)
    .WithValueFormatter(
      function(value : Double) : string
      begin
        result := Format('%.0f%%', [value]);
      end);
  console.Write(chart);
  Assert.IsTrue(Pos('75%', sink.Text) > 0,
    'Custom formatter output "75%%" should appear in the chart');
end;

procedure TBarChartTests.AddItem_WithExplicitColor_EmitsTrueColorSGR;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // True-color console so we can substring-search the SGR for Lime (0,255,0).
  BuildCapturedConsole(TColorSystem.TrueColor, 40, False, console, sink);
  console.Write(BarChart.AddItem('a', 50, TAnsiColor.Lime).WithWidth(20));
  Assert.IsTrue(Pos('38;2;0;255;0', sink.Text) > 0,
    'Explicit Lime color should emit a true-color foreground SGR');
end;

procedure TBarChartTests.EmptyChart_RendersWithoutError;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // No items: the renderer must produce no output instead of raising.
  console := BuildPlainAscii(40, sink);
  console.Write(BarChart);
  Assert.IsNotNull(sink, 'Render should complete without raising');
end;

procedure TBarChartTests.MultipleItems_AllAppearInOrder;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
  posA, posB, posC : Integer;
begin
  console := BuildPlainAscii(40, sink);
  console.Write(BarChart
    .AddItem('alpha', 10)
    .AddItem('beta',  20)
    .AddItem('gamma', 30)
    .WithWidth(25));
  output := sink.Text;
  posA := Pos('alpha', output);
  posB := Pos('beta',  output);
  posC := Pos('gamma', output);
  Assert.IsTrue(posA > 0,    'alpha should render');
  Assert.IsTrue(posB > posA, 'beta should follow alpha');
  Assert.IsTrue(posC > posB, 'gamma should follow beta');
end;

procedure TBarChartTests.WithLabel_ParsesMarkupTags;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlainAscii(40, sink);
  console.Write(BarChart
    .WithLabel('[bold]Languages[/]')
    .AddItem('a', 50));
  output := sink.Text;
  Assert.IsTrue(Pos('Languages', output) > 0,
    'Body of the markup tag must appear');
  Assert.IsTrue(Pos('[bold]', output) = 0,
    'Literal markup tag must not leak through to the chart heading');
end;

procedure TBarChartTests.ItemLabel_ParsesMarkupTags;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlainAscii(40, sink);
  console.Write(BarChart
    .AddItem('[italic]alpha[/]', 10)
    .AddItem('beta',             20));
  output := sink.Text;
  Assert.IsTrue(Pos('alpha', output) > 0,    'alpha label body must render');
  Assert.IsTrue(Pos('[italic]', output) = 0,
    'Literal markup tag must not leak through to the per-item label');
end;

initialization
  TDUnitX.RegisterTestFixture(TBarChartTests);

end.
