program Calendar;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole;

begin
  AnsiConsole.Write(
    Widgets.Calendar(2026, 4, 25)
      .WithCulture('en-GB'));
  AnsiConsole.WriteLine;
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
