program BarChart;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole;

var
  chart : IBarChart;
begin
  chart := Widgets.BarChart.WithLabel('[bold]Languages[/]');
  chart.AddItem('Pascal', 80, TAnsiColor.Aqua);
  chart.AddItem('Go',     45, TAnsiColor.Lime);
  chart.AddItem('Rust',   60, TAnsiColor.Red);
  chart.WithWidth(40);
  AnsiConsole.Write(chart);
  AnsiConsole.WriteLine;
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
