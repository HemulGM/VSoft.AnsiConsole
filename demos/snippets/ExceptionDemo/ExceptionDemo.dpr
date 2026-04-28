program ExceptionDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  VSoft.AnsiConsole;

begin
  try
    raise EInOutError.Create('disk full');
  except
    on E : Exception do
      AnsiConsole.Write(
        Widgets.ExceptionWidget(E)
          .WithStackTrace(
            'MyApp.Storage.Save in C:\src\MyApp\Storage.pas:142' + sLineBreak +
            'MyApp.Worker.Run  in C:\src\MyApp\Worker.pas:56'    + sLineBreak +
            'MyApp.Main')
          .WithFormats([TExceptionFormat.ShortenPaths,
                         TExceptionFormat.ShortenMethods]));
  end;
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
