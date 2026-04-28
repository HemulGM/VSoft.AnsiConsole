program Status;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  VSoft.AnsiConsole;

begin
  AnsiConsole.Status.Start('[yellow]Connecting...[/]',
    procedure(const ctx : IStatus)
    begin
      Sleep(1500);
      ctx.SetStatus('[green]Authenticated.[/] Fetching data...');
      Sleep(1500);
    end);
  AnsiConsole.MarkupLine('Data downloaded :check_mark_button:');
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
