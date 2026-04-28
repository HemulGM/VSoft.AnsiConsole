program PanelRule;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole;

begin
  AnsiConsole.Write(Widgets.Rule('Section'));
  AnsiConsole.Write(
    Widgets.Panel(Widgets.Markup('[bold]hello[/] world'))
      .WithHeader('Greeting')
      .WithBorder(TBoxBorderKind.Rounded));
  AnsiConsole.WriteLine;
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
