program Json;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole;
var
  jsonText : IJsonText;
begin
  jsonText := Widgets.Json(
      '{"name":"Vincent","skills":["Delphi","Pascal"],"active":true}');
  AnsiConsole.Write(jsonText);
  AnsiConsole.WriteLine;
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
