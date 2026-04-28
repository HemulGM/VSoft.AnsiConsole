program Figlet;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole;

begin
  AnsiConsole.Write(
    Widgets.FigletText('Hello Delphi')
      .WithColor(TAnsiColor.Aqua)
      .WithAlignment(TAlignment.Left));
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
