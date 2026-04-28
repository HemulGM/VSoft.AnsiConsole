program Markup;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole;

begin
  // Simple colored text
  AnsiConsole.MarkupLine('[green]Success![/]');
  AnsiConsole.MarkupLine('[red]Error occurred[/]');

  // Multiple colors in one line
  AnsiConsole.MarkupLine('[blue]Info:[/] Processing [yellow]3[/] items...');

  // Text decorations
  AnsiConsole.MarkupLine('[bold]Bold text[/]');
  AnsiConsole.MarkupLine('[italic]Italic text[/]');
  AnsiConsole.MarkupLine('[underline]Underlined text[/]');

  // Combined styles
  AnsiConsole.MarkupLine('[bold red]Critical error[/]');
  AnsiConsole.MarkupLine('[bold green on black]Highlighted success[/]');
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
