program Table;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole;

var
  t : ITable;
begin
  t := Widgets.Table.WithBorder(TTableBorderKind.Rounded);
  t.AddColumn('[bold]Name[/]', TAlignment.Left);
  t.AddColumn('[bold]Score[/]', TAlignment.Right);
  t.AddRow(['Alice', '128']);
  t.AddRow(['Bob',   ' 96']);
  t.AddRow(['Carol', '142']);
  AnsiConsole.Write(t);
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
