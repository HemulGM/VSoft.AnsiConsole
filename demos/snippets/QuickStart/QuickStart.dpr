program QuickStart;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole;

begin
  AnsiConsole.MarkupLine('[bold yellow]Hello[/] [italic]world[/]!');
  AnsiConsole.MarkupLine(
    'Numbers: [red]1[/], [green]2[/], [blue]3[/] :rocket:');
  AnsiConsole.WriteLine;
  AnsiConsole.WriteLine;
  AnsiConsole.Write('Press <Enter> to quit...');

  Readln;
end.
