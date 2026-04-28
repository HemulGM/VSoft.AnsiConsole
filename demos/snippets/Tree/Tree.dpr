program Tree;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole;

var
  t   : ITree;
  src : ITreeNode;
begin
  t := Widgets.Tree('[bold]Project[/]');
  src := t.AddNode('source');
  src.AddNode('VSoft.AnsiConsole.Color.pas');
  src.AddNode('VSoft.AnsiConsole.Style.pas');
  t.AddNode('tests');
  AnsiConsole.Write(t);
  AnsiConsole.WriteLine;
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
