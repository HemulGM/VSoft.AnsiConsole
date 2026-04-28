program Progress;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  VSoft.AnsiConsole;

begin
  AnsiConsole.Progress.Start(
    procedure(const ctx : IProgress)
    var
      download : IProgressTask;
      process  : IProgressTask;
    begin
      download := ctx.AddTask('Downloading', 100);
      process  := ctx.AddTask('Processing',  100);
      while not (download.IsFinished and process.IsFinished) do
      begin
        if not download.IsFinished then download.Increment(2);
        if download.Percentage > 30 then process.Increment(1);
        Sleep(60);
      end;
    end);
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
