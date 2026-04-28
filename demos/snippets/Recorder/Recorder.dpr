program Recorder;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  VSoft.AnsiConsole;

var
  rec      : IRecorder;
  htmlPath : string;
begin
  rec := AnsiConsole.Recorder;
  rec.Write(Widgets.Markup('[bold]Captured[/] [yellow]demo[/]'));
  rec.WriteLine;
  rec.Write(Widgets.Panel(Widgets.Text('hi')).WithHeader('panel'));

  AnsiConsole.WriteLine;
  AnsiConsole.WriteLine;
  AnsiConsole.MarkupLine('[bold]ExportText:[/]');
  AnsiConsole.WriteLine;
  Write(rec.ExportText);

  htmlPath := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP'))
              + 'Recorder-demo.html';
  TFile.WriteAllText(htmlPath, rec.ExportHtml);
  AnsiConsole.WriteLine;
  AnsiConsole.MarkupLine('[green]HTML written to:[/] [aqua]' + htmlPath + '[/]');

  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
