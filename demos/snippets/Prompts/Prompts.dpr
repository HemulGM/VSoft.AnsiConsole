program Prompts;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole.Prompts.Select,
  VSoft.AnsiConsole;

var
  name    : string;
  proceed : Boolean;
  theme   : string;
begin
  name    := AnsiConsole.Ask('[bold]Name[/]', 'Delphi');
  proceed := AnsiConsole.Confirm('Proceed?', True);
  if proceed then
  begin
    theme := AnsiConsole.SelectionPrompt<string>
               .WithTitle('Pick a theme')
               .AddChoice('light', 'Light')
               .AddChoice('dark',  'Dark')
               .AddChoice('hc',    'High contrast')
               .Show(AnsiConsole.Console);

    AnsiConsole.MarkupLine('Hello [bold]' + name +
      '[/], theme = [aqua]' + theme + '[/]');
  end;
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
