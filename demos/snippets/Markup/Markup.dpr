program Markup;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole;

begin
  AnsiConsole.MarkupLine('[bold red on yellow]Important[/] message');
  AnsiConsole.MarkupLine('Link: [link=https://github.com]click here[/]');
  AnsiConsole.MarkupLine('[#ff8800]Custom hex colour[/]');
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
