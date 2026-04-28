program Breakdown;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole;

var
  brk : IBreakdownChart;
begin
  brk := Widgets.BreakdownChart;
  brk.AddItem('Elixir', 35, TAnsiColor.Fuchsia);
  brk.AddItem('C#',     27, TAnsiColor.Aqua);
  brk.AddItem('Ruby',   15, TAnsiColor.Red);
  brk.WithWidth(50);
  AnsiConsole.Write(brk);
  AnsiConsole.WriteLine;
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
