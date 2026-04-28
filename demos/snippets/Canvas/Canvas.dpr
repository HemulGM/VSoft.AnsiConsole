program Canvas;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole;

var
  cnv  : ICanvas;
  x, y : Integer;
begin
  cnv := Widgets.Canvas(40, 20);
  for y := 0 to 19 do
    for x := 0 to 39 do
      cnv.SetPixel(x, y, TAnsiColor.FromRGB(x * 6, y * 12, 128));
  AnsiConsole.Write(cnv);
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
