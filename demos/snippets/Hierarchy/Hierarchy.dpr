program Hierarchy;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole.Prompts.Hierarchy,
  VSoft.AnsiConsole.Prompts.Select,
  VSoft.AnsiConsole;

var
  picker   : ISelectionPrompt<string>;
  americas,
  asia,
  oceania : ISelectionItem<string>;
  region         : string;
begin
  picker := AnsiConsole.SelectionPrompt<string>
              .WithTitle('[yellow]Pick a region[/] [grey50](Enter to expand)[/]');

  oceania := picker.AddChoiceHierarchy('Oceania', '[bold]Oceania[/]');
  oceania.AddChild('au', 'Australia');
  oceania.AddChild('nz', 'New Zealand');
  oceania.AddChild('fi', 'Fiji');
  oceania.IsExpanded := True; // pre-open this branch

  americas := picker.AddChoiceHierarchy('Americas', '[bold]Americas[/]');
  americas.AddChild('us', 'United States');
  americas.AddChild('ca', 'Canada');
  americas.AddChild('br', 'Brazil');
  americas.IsExpanded := false;

  asia := picker.AddChoiceHierarchy('Asia', '[bold]Asia[/]');
  asia.AddChild('cn', 'China');
  asia.AddChild('jp', 'Japan');
  asia.AddChild('kr', 'South Korea');
  asia.IsExpanded := false;



  region := picker.Show(AnsiConsole.Console);

  AnsiConsole.MarkupLine('You picked: [lime]' + region + '[/]');
  AnsiConsole.WriteLine;
  Write('Press <Enter> to quit...');
  Readln;
end.
