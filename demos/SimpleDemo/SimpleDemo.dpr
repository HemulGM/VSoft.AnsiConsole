program SimpleDemo;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  VSoft.AnsiConsole.Types in '..\..\source\Core\VSoft.AnsiConsole.Types.pas',
  VSoft.AnsiConsole.Color in '..\..\source\Core\VSoft.AnsiConsole.Color.pas',
  VSoft.AnsiConsole.Emoji in '..\..\source\Core\VSoft.AnsiConsole.Emoji.pas',
  VSoft.AnsiConsole.Style in '..\..\source\Core\VSoft.AnsiConsole.Style.pas',
  VSoft.AnsiConsole.Segment in '..\..\source\Core\VSoft.AnsiConsole.Segment.pas',
  VSoft.AnsiConsole.Measurement in '..\..\source\Core\VSoft.AnsiConsole.Measurement.pas',
  VSoft.AnsiConsole.Internal.Cell.Tables in '..\..\source\Internal\VSoft.AnsiConsole.Internal.Cell.Tables.pas',
  VSoft.AnsiConsole.Internal.Cell in '..\..\source\Internal\VSoft.AnsiConsole.Internal.Cell.pas',
  VSoft.AnsiConsole.Internal.SegmentOps in '..\..\source\Internal\VSoft.AnsiConsole.Internal.SegmentOps.pas',
  VSoft.AnsiConsole.Rendering in '..\..\source\Rendering\VSoft.AnsiConsole.Rendering.pas',
  VSoft.AnsiConsole.Rendering.AnsiWriter in '..\..\source\Rendering\VSoft.AnsiConsole.Rendering.AnsiWriter.pas',
  VSoft.AnsiConsole.Capabilities in '..\..\source\Profile\VSoft.AnsiConsole.Capabilities.pas',
  VSoft.AnsiConsole.Detection in '..\..\source\Profile\VSoft.AnsiConsole.Detection.pas',
  VSoft.AnsiConsole.Enrichment in '..\..\source\Profile\VSoft.AnsiConsole.Enrichment.pas',
  VSoft.AnsiConsole.Profile in '..\..\source\Profile\VSoft.AnsiConsole.Profile.pas',
  VSoft.AnsiConsole.Console in '..\..\source\Console\VSoft.AnsiConsole.Console.pas',
  VSoft.AnsiConsole.Settings in '..\..\source\Console\VSoft.AnsiConsole.Settings.pas',
  VSoft.AnsiConsole.Cursor in '..\..\source\Console\VSoft.AnsiConsole.Cursor.pas',
  VSoft.AnsiConsole.Markup.Tokenizer in '..\..\source\Markup\VSoft.AnsiConsole.Markup.Tokenizer.pas',
  VSoft.AnsiConsole.Markup.Parser in '..\..\source\Markup\VSoft.AnsiConsole.Markup.Parser.pas',
  VSoft.AnsiConsole.Borders.Box in '..\..\source\Borders\VSoft.AnsiConsole.Borders.Box.pas',
  VSoft.AnsiConsole.Borders.Table in '..\..\source\Borders\VSoft.AnsiConsole.Borders.Table.pas',
  VSoft.AnsiConsole.Borders.Tree in '..\..\source\Borders\VSoft.AnsiConsole.Borders.Tree.pas',
  VSoft.AnsiConsole.Widgets.Text in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Text.pas',
  VSoft.AnsiConsole.Widgets.Markup in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Markup.pas',
  VSoft.AnsiConsole.Widgets.Rule in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Rule.pas',
  VSoft.AnsiConsole.Widgets.Paragraph in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Paragraph.pas',
  VSoft.AnsiConsole.Widgets.Padder in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Padder.pas',
  VSoft.AnsiConsole.Widgets.Align in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Align.pas',
  VSoft.AnsiConsole.Widgets.Rows in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Rows.pas',
  VSoft.AnsiConsole.Widgets.Columns in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Columns.pas',
  VSoft.AnsiConsole.Widgets.Grid in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Grid.pas',
  VSoft.AnsiConsole.Widgets.Panel in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Panel.pas',
  VSoft.AnsiConsole.Widgets.Table in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Table.pas',
  VSoft.AnsiConsole.Widgets.Tree in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Tree.pas',
  VSoft.AnsiConsole.Input in '..\..\source\Console\VSoft.AnsiConsole.Input.pas',
  VSoft.AnsiConsole.Prompts.Common in '..\..\source\Prompts\VSoft.AnsiConsole.Prompts.Common.pas',
  VSoft.AnsiConsole.Prompts.Hierarchy in '..\..\source\Prompts\VSoft.AnsiConsole.Prompts.Hierarchy.pas',
  VSoft.AnsiConsole.Prompts.Text in '..\..\source\Prompts\VSoft.AnsiConsole.Prompts.Text.pas',
  VSoft.AnsiConsole.Prompts.Text.Generic in '..\..\source\Prompts\VSoft.AnsiConsole.Prompts.Text.Generic.pas',
  VSoft.AnsiConsole.Prompts.Confirm in '..\..\source\Prompts\VSoft.AnsiConsole.Prompts.Confirm.pas',
  VSoft.AnsiConsole.Prompts.Select in '..\..\source\Prompts\VSoft.AnsiConsole.Prompts.Select.pas',
  VSoft.AnsiConsole.Prompts.MultiSelect in '..\..\source\Prompts\VSoft.AnsiConsole.Prompts.MultiSelect.pas',
  VSoft.AnsiConsole.Live.Exclusivity in '..\..\source\Live\VSoft.AnsiConsole.Live.Exclusivity.pas',
  VSoft.AnsiConsole.Live.Display in '..\..\source\Live\VSoft.AnsiConsole.Live.Display.pas',
  VSoft.AnsiConsole.Live.Spinners in '..\..\source\Live\VSoft.AnsiConsole.Live.Spinners.pas',
  VSoft.AnsiConsole.Live.Status in '..\..\source\Live\VSoft.AnsiConsole.Live.Status.pas',
  VSoft.AnsiConsole.Live.Progress in '..\..\source\Live\VSoft.AnsiConsole.Live.Progress.pas',
  VSoft.AnsiConsole.Widgets.Canvas in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Canvas.pas',
  VSoft.AnsiConsole.Widgets.BarChart in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.BarChart.pas',
  VSoft.AnsiConsole.Widgets.BreakdownChart in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.BreakdownChart.pas',
  VSoft.AnsiConsole.Widgets.Calendar in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Calendar.pas',
  VSoft.AnsiConsole.Widgets.TextPath in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.TextPath.pas',
  VSoft.AnsiConsole.Widgets.Layout in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Layout.pas',
  VSoft.AnsiConsole.Widgets.Figlet in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Figlet.pas',
  VSoft.AnsiConsole.Internal.FigletFont in '..\..\source\Internal\VSoft.AnsiConsole.Internal.FigletFont.pas',
  VSoft.AnsiConsole.Internal.Fonts.Standard in '..\..\source\Internal\VSoft.AnsiConsole.Internal.Fonts.Standard.pas',
  VSoft.AnsiConsole.Widgets.Json in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Json.pas',
  VSoft.AnsiConsole.Widgets.Exception in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Exception.pas',
  VSoft.AnsiConsole.Recorder in '..\..\source\Console\VSoft.AnsiConsole.Recorder.pas',
  VSoft.AnsiConsole in '..\..\source\VSoft.AnsiConsole.pas';

var
  srcTree           : ITree;
  projTree          : ITree;
  core, widgets, docs : ITreeNode;
  themePicker : ISelectionPrompt<string>;
  featurePicker : IMultiSelectionPrompt<string>;
  regionPicker  : ISelectionPrompt<string>;
  americas, europe, asia : ISelectionItem<string>;
  region        : string;
  name          : string;
  age           : Integer;
  proceed       : Boolean;
  theme         : string;
  features      : TArray<string>;
  i             : Integer;
  featureList   : string;
  cnv           : ICanvas;
  chart         : IBarChart;
  brk           : IBreakdownChart;
  cal           : ICalendar;
  tp            : ITextPath;
  rootLayout    : ILayout;
  leftPane      : ILayout;
  centerPane    : ILayout;
  rightPane     : ILayout;
  x, y          : Integer;
  rec           : IRecorder;
  htmlPath      : string;
  exFake        : Exception;
begin
  try
    AnsiConsole.MarkupLine('[yellow bold]VSoft.AnsiConsole[/] Phase 1 demo');
    AnsiConsole.Write(Widgets.Rule('Markup'));
    AnsiConsole.WriteLine;

    AnsiConsole.MarkupLine('[red]red[/]  [green]green[/]  [blue]blue[/]  [yellow]yellow[/]  [aqua]aqua[/]  [fuchsia]fuchsia[/]');
    AnsiConsole.MarkupLine('[maroon]maroon[/]  [navy]navy[/]  [teal]teal[/]  [olive]olive[/]  [purple]purple[/]  [silver]silver[/]');
    AnsiConsole.MarkupLine('[bold]bold[/]  [italic]italic[/]  [underline]underline[/]  [strikethrough]strike[/]  [invert]invert[/]');
    AnsiConsole.MarkupLine('[bold italic underline]all three decorations[/]');
    AnsiConsole.MarkupLine('background: [black on yellow] black on yellow [/]');
    AnsiConsole.MarkupLine('hex color: [#ff8800]orange (#ff8800)[/]');
    AnsiConsole.MarkupLine('rgb block: [#1e90ff on #ffe4b5] dodger blue on moccasin [/]');
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('Text widget'));
    AnsiConsole.WriteLine;
    AnsiConsole.Write(Widgets.Text('Plain unstyled text'));
    AnsiConsole.WriteLine;
    AnsiConsole.Write(Widgets.Text('Styled text',
      TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua).WithDecorations([TAnsiDecoration.Italic])));
    AnsiConsole.WriteLine;
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('Rule variants'));
    AnsiConsole.WriteLine;
    AnsiConsole.Write(Widgets.Rule('Centered').WithAlignment(TAlignment.Center));
    AnsiConsole.WriteLine;
    AnsiConsole.Write(Widgets.Rule('Left').WithAlignment(TAlignment.Left));
    AnsiConsole.WriteLine;
    AnsiConsole.Write(Widgets.Rule('Right').WithAlignment(TAlignment.Right));
    AnsiConsole.WriteLine;
    AnsiConsole.Write(Widgets.Rule('Heavy').WithBorder(TRuleBorder.Heavy));
    AnsiConsole.WriteLine;
    AnsiConsole.Write(Widgets.Rule('Double').WithBorder(TRuleBorder.Double));
    AnsiConsole.WriteLine;
    AnsiConsole.Write(Widgets.Rule('Ascii').WithBorder(TRuleBorder.Ascii));
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('Layout'));
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Align(Widgets.Markup('[bold]centered[/]'), TAlignment.Center));
    AnsiConsole.WriteLine;
    AnsiConsole.Write(Widgets.Align(Widgets.Markup('[italic]right[/]'), TAlignment.Right));
    AnsiConsole.WriteLine;
    AnsiConsole.MarkupLine(':money_with_wings: :rocket:');
    AnsiConsole.WriteLine;
    AnsiConsole.Write(
      Widgets.Columns
        .Add(Widgets.Markup('[aqua]left column[/]'))
        .Add(Widgets.Markup('[yellow]middle column[/]'))
        .Add(Widgets.Markup('[lime]right column[/]'))
    );
    AnsiConsole.WriteLine;

    AnsiConsole.Write(
      Widgets.Grid
        .AddFixedColumn(8)
        .AddStarColumn(1)
        .AddFixedColumn(6)
        .WithGutter(2)
        .AddRow([Widgets.Markup('[bold]Name[/]'),  Widgets.Markup('[bold]Description[/]'), Widgets.Markup('[bold]Qty[/]')])
        .AddRow([Widgets.Markup('[red]apple[/]'),  Widgets.Text('crunchy and sweet'),       Widgets.Text('12')])
        .AddRow([Widgets.Markup('[#ff8800]mango[/]'), Widgets.Text('tropical, juicy'),     Widgets.Text('3')])
    );
    AnsiConsole.WriteLine;

    AnsiConsole.Write(
      Widgets.Panel(Widgets.Markup('[green]hello from inside a panel[/]'))
        .WithHeader('Panel')
        .WithFooter('v1.0')
    );
    AnsiConsole.WriteLine;

    AnsiConsole.Write(
      Widgets.Panel(Widgets.Text('rounded border panel'))
        .WithBorder(TBoxBorderKind.Rounded)
        .WithBorderStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua))
    );
    AnsiConsole.WriteLine;

    AnsiConsole.Write(
      Widgets.Panel(Widgets.Text('heavy border'))
        .WithBorder(TBoxBorderKind.Heavy)
        .WithBorderStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Red))
    );
    AnsiConsole.WriteLine;

    AnsiConsole.Write(
      Widgets.Panel(Widgets.Text('double border'))
        .WithBorder(TBoxBorderKind.Double)
        .WithHeader('double')
    );
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('Data'));
    AnsiConsole.WriteLine;

    AnsiConsole.Write(
      Widgets.Table
        .WithTitle('[bold]Inventory[/]')
        .WithCaption('3 rows shown')
        .WithBorder(TTableBorderKind.Square)
        .AddColumn('[bold]Name[/]')
        .AddColumn('[bold]Description[/]')
        .AddColumn('[bold]Qty[/]', TAlignment.Right)
        .AddRow(['[red]apple[/]',    'crunchy and sweet', '12'])
        .AddRow(['[#ff8800]mango[/]', 'tropical, juicy',   '3'])
        .AddRow(['[yellow]banana[/]', 'long and yellow',   '7'])
    );
    AnsiConsole.WriteLine;

    AnsiConsole.Write(
      Widgets.Table
        .WithBorder(TTableBorderKind.Markdown)
        .AddColumn('File')
        .AddColumn('Size', TAlignment.Right)
        .AddRow(['readme.md', '1.2 KB'])
        .AddRow(['main.pas',  '14.7 KB'])
    );
    AnsiConsole.WriteLine;

    // Tree demo - local ITreeNodes make sibling-vs-child explicit.
    srcTree := Widgets.Tree('[bold yellow]src[/]');
    core := srcTree.AddNode('[aqua]Core[/]');
    core.AddNode('Color.pas');
    core.AddNode('Style.pas');
    core.AddNode('Segment.pas');
    widgets := srcTree.AddNode('[aqua]Widgets[/]');
    widgets.AddNode('Text.pas');
    widgets.AddNode('Panel.pas');
    widgets.AddNode('Table.pas');
    widgets.AddNode('Tree.pas');
    docs := srcTree.AddNode('[aqua]docs[/]');
    docs.AddNode('README.md');
    AnsiConsole.Write(srcTree);
    AnsiConsole.WriteLine;
    AnsiConsole.WriteLine;

    projTree := Widgets.Tree('[bold]Project[/]').WithGuide(TTreeGuideKind.Heavy);
    projTree.AddNode('[green]build ok[/]');
    projTree.AddNode('[yellow]tests pending[/]');
    projTree.AddNode('[red]TODO: cross-platform[/]');
    AnsiConsole.Write(projTree);
    AnsiConsole.WriteLine;

    // Live section is gated behind a CLI arg so the default run stays
    // non-interactive. Run as: SimpleDemo.exe live
    if (ParamCount > 0) and SameText(ParamStr(1), 'live') then
    begin
      AnsiConsole.Write(Widgets.Rule('Live'));
      AnsiConsole.WriteLine;

      AnsiConsole.Status
        .WithSpinner(skDots)
        .Start('[yellow]Processing...[/]',
          procedure(const ctx : IStatus)
          begin
            Sleep(1500);
            ctx.SetStatus('[yellow]Nearly done...[/]');
            Sleep(1000);
          end);

      // Showcase a handful of the 90 built-in spinner kinds. Each runs for
      // ~1.5 seconds so you can eyeball the motion + message together.
      AnsiConsole.WriteLine;
      AnsiConsole.WriteLine('[bold]Spinner gallery[/]');
      AnsiConsole.WriteLine;

      AnsiConsole.Status.WithSpinner(skClock)
        .Start('[aqua]Clock spinner[/]', procedure(const ctx : IStatus) begin Sleep(1500); end);

      AnsiConsole.Status.WithSpinner(skEarth)
        .Start('[lime]Earth spinner[/]', procedure(const ctx : IStatus) begin Sleep(1500); end);

      AnsiConsole.Status.WithSpinner(skBouncingBar)
        .Start('[yellow]Bouncing bar[/]', procedure(const ctx : IStatus) begin Sleep(1500); end);

      AnsiConsole.Status.WithSpinner(skMoon)
        .Start('[fuchsia]Moon phases[/]', procedure(const ctx : IStatus) begin Sleep(2000); end);

      AnsiConsole.Status.WithSpinner(skHearts)
        .Start('[red]Hearts[/]', procedure(const ctx : IStatus) begin Sleep(1500); end);

      AnsiConsole.Status.WithSpinner(skArc)
        .Start('[aqua]Arc (minimal unicode)[/]', procedure(const ctx : IStatus) begin Sleep(1500); end);

      AnsiConsole.Status.WithSpinner(skMaterial)
        .Start('[silver]Material (long cycle)[/]', procedure(const ctx : IStatus) begin Sleep(2500); end);

      AnsiConsole.Status.WithSpinner(skPong)
        .Start('[grey]Pong[/]', procedure(const ctx : IStatus) begin Sleep(2000); end);

      AnsiConsole.Status.WithSpinner(skPipe)
        .Start('[olive]Pipe (ASCII-safe box drawing)[/]', procedure(const ctx : IStatus) begin Sleep(1500); end);

      // Custom spinner built from a user-supplied frame list + interval.
      // Same idea as deriving from Spectre's Spinner class - any ISpinner
      // works, either a full implementor or one built by the overload below.
      AnsiConsole.Status
        .WithSpinner(Widgets.Spinner(
          TArray<string>.Create('(>    )', '( >   )', '(  >  )', '(   > )', '(    >)',
                                '(   < )', '(  <  )', '( <   )', '(<    )'),
          100))
        .Start('[aqua]Custom spinner[/]',
          procedure(const ctx : IStatus) begin Sleep(2000); end);
      AnsiConsole.WriteLine;

      // Direct port of Spectre's showcase ProgressSample.cs
      // (https://github.com/spectreconsole/website/blob/main/Spectre.Docs.Examples/Showcase/ProgressSample.cs).
      // Five tasks advance at randomised speeds; a sixth ('Preparing for
      // descent') stays indeterminate-and-pulsing until the others all
      // finish, then flips to determinate and ramps to completion.
      RandSeed := 42;  // matches `new Random(42)` in the C# sample
      Progress(AnsiConsole.Console)
        .WithColumns([
          Widgets.DescriptionColumn,
          Widgets.ProgressBarColumn(40),
          Widgets.PercentageColumn,
          Widgets.RemainingTimeColumn,
          Widgets.SpinnerColumn(skDefault)])
        .Start(
          procedure(const ctx : IProgress)
          var
            tasks      : TArray<IProgressTask>;
            speeds     : TArray<Double>;
            launchTask : IProgressTask;
            i          : Integer;
            allDone    : Boolean;
          begin
            SetLength(tasks, 5);
            SetLength(speeds, 5);
            tasks[0] := ctx.AddTask('Reticulating splines');
            speeds[0] := Random * 2 + 1.1;
            tasks[1] := ctx.AddTask('Hydrating caches');
            speeds[1] := Random * 2 + 1.0;
            tasks[2] := ctx.AddTask('Consulting the oracle');
            speeds[2] := Random * 2 + 1.2;
            tasks[3] := ctx.AddTask('Negotiating with upstream');
            speeds[3] := Random * 2 + 1.05;
            tasks[4] := ctx.AddTask('Defenestrating legacy code');
            speeds[4] := Random * 2 + 1.4;

            launchTask := ctx.AddTask('Preparing for descent', 100, False);
            launchTask.IsIndeterminate := True;

            while not ctx.IsFinished do
            begin
              for i := 0 to High(tasks) do
                if not tasks[i].IsFinished then
                  tasks[i].Increment(Random * speeds[i]);

              allDone := True;
              for i := 0 to High(tasks) do
                if not tasks[i].IsFinished then begin allDone := False; Break; end;

              if allDone and (not launchTask.IsStarted) then
              begin
                launchTask.StartTask;
                launchTask.IsIndeterminate := False;
              end;

              if launchTask.IsStarted and (not launchTask.IsFinished) then
                launchTask.Increment(Random * 3 + 1);

              Sleep(80);
            end;
          end);

      // Column-rich progress: spinner + description + bar + bytes + speed + ETA.
      // AutoStart=False lets us show the "pending" state (spinner space
      // empty) before the task actually begins.
      AnsiConsole.WriteLine;
      AnsiConsole.MarkupLine('[bold]Transfer view[/]');
      Progress(AnsiConsole.Console)
        .WithColumns([
          Widgets.SpinnerColumn(skDots),
          Widgets.DescriptionColumn,
          Widgets.ProgressBarColumn(30),
          Widgets.DownloadedColumn,
          Widgets.TransferSpeedColumn,
          Widgets.RemainingTimeColumn])
        .Start(
          procedure(const ctx : IProgress)
          var
            file1, file2 : IProgressTask;
            i : Integer;
          begin
            // 5 MB and 2 MB "downloads"
            file1 := ctx.AddTask('installer.msi', 5 * 1024 * 1024);
            file2 := ctx.AddTask('release-notes.pdf', 2 * 1024 * 1024, False);
            for i := 1 to 40 do
            begin
              file1.Increment(5 * 1024 * 1024 / 40);
              if i = 10 then file2.StartTask;
              if i > 10 then file2.Increment(2 * 1024 * 1024 / 30);
              Sleep(60);
            end;
          end);

      // Styled columns: each built-in column exposes fluent With*Style methods.
      AnsiConsole.WriteLine;
      AnsiConsole.MarkupLine('[bold]Styled columns[/]');
      Progress(AnsiConsole.Console)
        .WithColumns([
          Widgets.SpinnerColumn(skArrow2)
            .WithStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Fuchsia))
            .WithCompletedStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Lime))
            .WithCompletedText('DONE'),
          Widgets.DescriptionColumn
            .WithStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.White).WithDecorations([TAnsiDecoration.Bold])),
          Widgets.ProgressBarColumn(25)
            .WithCompletedStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Fuchsia))
            .WithFinishedStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Lime))
            .WithRemainingStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Navy)),
          Widgets.PercentageColumn
            .WithStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Fuchsia))
            .WithCompletedStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Lime).WithDecorations([TAnsiDecoration.Bold])),
          Widgets.ElapsedColumn
            .WithStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Silver))])
        .Start(
          procedure(const ctx : IProgress)
          var
            a, b : IProgressTask;
            i : Integer;
          begin
            a := ctx.AddTask('alpha', 100);
            b := ctx.AddTask('beta', 100);
            for i := 1 to 20 do
            begin
              a.Increment(5);
              if i > 4 then b.Increment(6);
              Sleep(70);
            end;
          end);

      // Indeterminate task: no known end - spinner + pulsing bar.
      AnsiConsole.WriteLine;
      AnsiConsole.MarkupLine('[bold]Indeterminate task[/]');
      Progress(AnsiConsole.Console)
        .WithColumns([
          Widgets.SpinnerColumn(skDots),
          Widgets.DescriptionColumn,
          Widgets.ProgressBarColumn(40),
          Widgets.ElapsedColumn])
        .Start(
          procedure(const ctx : IProgress)
          var
            t : IProgressTask;
          begin
            t := ctx.AddTask('Indexing...', 100);
            t.IsIndeterminate := True;
            Sleep(2500);
            // Task reveals its real size, flips to determinate, and finishes.
            t.IsIndeterminate := False;
            t.SetValue(100);
          end);

      AnsiConsole.MarkupLine('[green]Done![/]');
      AnsiConsole.Write(Widgets.Rule);
      AnsiConsole.WriteLine;
    end;

    AnsiConsole.Write(Widgets.Rule('Prompts'));
    AnsiConsole.WriteLine;

    name := AnsiConsole.Ask('[bold]Name[/]', 'World');
    // Generic typed prompt - parses Integer via the built-in RTTI
    // dispatcher; default applied on Enter-with-empty-input.
    age := AnsiConsole.Ask<Integer>('[bold]Age[/]', 30);
    proceed := AnsiConsole.Confirm('[bold]Proceed[/]?', True);

    if proceed then
    begin
      themePicker := AnsiConsole.SelectionPrompt<string>
                        .WithTitle('[bold]Pick a theme[/]')
                        .AddChoice('light', 'Light')
                        .AddChoice('dark',  'Dark')
                        .AddChoice('high-contrast', 'High contrast');
      theme := themePicker.Show(AnsiConsole.Console);

      // Multi-level / hierarchical selection. AddChoiceHierarchy returns
      // an ISelectionItem<T> on which AddChild nests further nodes; the
      // returned child is itself an ISelectionItem<T> so trees can grow
      // arbitrarily deep. In the default TSelectionMode.Leaf mode (Spectre default),
      // Enter on a parent expands/collapses its subtree and only leaves
      // are returned as the result.
      regionPicker := AnsiConsole.SelectionPrompt<string>
                          .WithTitle('[bold]Pick a region[/] '
                            + '[grey50](Enter on a category to expand it)[/]');
      americas := regionPicker.AddChoiceHierarchy('americas', '[bold]Americas[/]');
      americas.AddChild('us',     'United States');
      americas.AddChild('ca',     'Canada');
      americas.AddChild('br',     'Brazil');
      americas.AddChild('ar',     'Argentina');
      europe := regionPicker.AddChoiceHierarchy('europe', '[bold]Europe[/]');
      europe.AddChild('gb', 'United Kingdom');
      europe.AddChild('fr', 'France');
      europe.AddChild('de', 'Germany');
      europe.AddChild('es', 'Spain');
      asia := regionPicker.AddChoiceHierarchy('asia', '[bold]Asia[/]');
      asia.AddChild('cn', 'China');
      asia.AddChild('jp', 'Japan');
      asia.AddChild('kr', 'Korea');
      asia.AddChild('in', 'India');
      // Pre-expand Europe so the user can see a sub-tree without having
      // to expand it themselves first.
      europe.IsExpanded := True;
      region := regionPicker.Show(AnsiConsole.Console);

      featurePicker := AnsiConsole.MultiSelectionPrompt<string>
                          .WithTitle('[bold]Enable features[/]')
                          .AddChoice('colors',   'Colors', True)
                          .AddChoice('markup',   'Markup')
                          .AddChoice('widgets',  'Widgets')
                          .AddChoice('prompts',  'Prompts')
                          .Required(1);
      features := featurePicker.Show(AnsiConsole.Console);

      featureList := '';
      for i := 0 to High(features) do
      begin
        if i > 0 then featureList := featureList + ', ';
        featureList := featureList + features[i];
      end;

      AnsiConsole.Write(
        Widgets.Panel(
          Widgets.Markup(
            '[bold]Hello[/] ' + name + ' (age ' + IntToStr(age) + ')!' + sLineBreak +
            'Theme: [aqua]' + theme + '[/]' + sLineBreak +
            'Region: [lime]' + region + '[/]' + sLineBreak +
            'Features: [yellow]' + featureList + '[/]'))
          .WithHeader('Summary')
          .WithBorder(TBoxBorderKind.Rounded)
      );
      AnsiConsole.WriteLine;
    end;

    AnsiConsole.Write(Widgets.Rule);
    AnsiConsole.WriteLine;

    // Phase 6 section: advanced widgets. Gated behind: SimpleDemo.exe phase6
    AnsiConsole.Write(Widgets.Rule('Figlet'));
    AnsiConsole.WriteLine;
    AnsiConsole.Write(Widgets.FigletText('Hello').WithColor(TAnsiColor.Aqua));
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('Canvas'));
    AnsiConsole.WriteLine;
    cnv := Widgets.Canvas(20, 20);
    for x := 0 to 19 do
      for y := 0 to 19 do
        if (x + y) mod 2 = 0 then
          cnv.SetPixel(x, y, TAnsiColor.Red)
        else if (x * y) mod 5 = 0 then
          cnv.SetPixel(x, y, TAnsiColor.Blue);
    AnsiConsole.Write(cnv);
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('Canvas (scaled to 10 cells)'));
    AnsiConsole.WriteLine;
    // Same 20x20 source canvas, downsampled to 10 cells wide via
    // nearest-neighbour. Aspect ratio is preserved, so the rendered grid
    // is roughly half-resolution.
    cnv := Widgets.Canvas(20, 20).WithMaxWidth(10);
    for x := 0 to 19 do
      for y := 0 to 19 do
        if (x + y) mod 2 = 0 then
          cnv.SetPixel(x, y, TAnsiColor.Red)
        else if (x * y) mod 5 = 0 then
          cnv.SetPixel(x, y, TAnsiColor.Blue);
    AnsiConsole.Write(cnv);
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('BarChart'));
    AnsiConsole.WriteLine;
    chart := Widgets.BarChart
               .WithLabel('Language popularity')
               .AddItem('C#',     83, TAnsiColor.Aqua)
               .AddItem('Rust',   75, TAnsiColor.Red)
               .AddItem('Delphi', 42, TAnsiColor.Yellow)
               .AddItem('Go',     60, TAnsiColor.Lime)
               .AddItem('Python', 92, TAnsiColor.Blue);
    AnsiConsole.Write(chart);
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('BreakdownChart'));
    AnsiConsole.WriteLine;
    brk := Widgets.BreakdownChart
             .AddItem('Code',  2800, TAnsiColor.Aqua)
             .AddItem('Docs',   450, TAnsiColor.Lime)
             .AddItem('Tests', 1100, TAnsiColor.Yellow)
             .AddItem('Other',  300, TAnsiColor.Fuchsia);
    AnsiConsole.Write(brk);
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('Calendar'));
    AnsiConsole.WriteLine;
    cal := Widgets.Calendar(2026, 4, 25)
             .AddCalendarEvent('Release', 2026, 4, 15);
    AnsiConsole.Write(cal);
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('Calendar (fr-FR culture)'));
    AnsiConsole.WriteLine;
    cal := Widgets.Calendar(2026, 4, 25)
             .WithCulture('fr-FR')
             .WithFirstDayOfWeek(1)   // Monday-first, matches French convention
             .AddCalendarEvent('Sortie', 2026, 4, 15);
    AnsiConsole.Write(cal);
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('TextPath'));
    AnsiConsole.WriteLine;
    tp := Widgets.TextPath('C:\Users\vincent\Github\VSoftTechnologies\VSoft.AnsiConsole\source\Widgets\VSoft.AnsiConsole.Widgets.Figlet.pas')
            .WithLeafStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Lime))
            .WithRootStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua))
            .WithStemStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Silver));
    AnsiConsole.Write(tp);
    AnsiConsole.WriteLine;
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('Layout'));
    AnsiConsole.WriteLine;
    leftPane := Widgets.Layout('left').Update(
                  Widgets.Panel(Widgets.Markup('[aqua]left pane[/]'))
                    .WithHeader('left'));
    centerPane := Widgets.Layout('center').Update(
                    Widgets.Panel(Widgets.Markup('[yellow]main area[/]'))
                      .WithHeader('main'))
                  .WithRatio(2);
    rightPane := Widgets.Layout('right').Update(
                   Widgets.Panel(Widgets.Markup('[lime]right pane[/]'))
                     .WithHeader('right'));
    rootLayout := Widgets.Layout('root');
    rootLayout.SplitColumns([leftPane, centerPane, rightPane]);
    rootLayout.WithHeight(7);
    AnsiConsole.Write(rootLayout);
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule);
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('JsonText'));
    AnsiConsole.WriteLine;
    AnsiConsole.Write(Widgets.Json(
      '{"name":"VSoft.AnsiConsole","version":"0.7","tags":["delphi","console"],'
      + '"counts":{"widgets":14,"phases":7},"released":true,"notes":null}'));
    AnsiConsole.WriteLine;
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('Exception'));
    AnsiConsole.WriteLine;
    exFake := Exception.Create('Access denied');
    try
      AnsiConsole.Write(
        Widgets.ExceptionWidget(exFake)
          .WithStackTrace(
            'DoWork at Main.pas:42'#10 +
            'Run at Main.pas:10'#10 +
            'System.Start at System.pas:1234'));
    finally
      exFake.Free;
    end;
    AnsiConsole.WriteLine;
    AnsiConsole.WriteLine;

    AnsiConsole.Write(Widgets.Rule('Recorder'));
    AnsiConsole.WriteLine;
    rec := AnsiConsole.Recorder;
    rec.Write(Widgets.Markup('[aqua]recorded[/] [yellow]hello[/]'));
    rec.WriteLine;
    rec.Write(Widgets.Panel(Widgets.Text('wrapped content')).WithHeader('in the recorder'));
    AnsiConsole.WriteLine;
    htmlPath := GetEnvironmentVariable('TEMP');
    if htmlPath = '' then htmlPath := GetCurrentDir;
    htmlPath := IncludeTrailingPathDelimiter(htmlPath) + 'SimpleDemo-recording.html';
    with TStringList.Create do
    try
      Text := rec.ExportHtml;
      SaveToFile(htmlPath);
    finally
      Free;
    end;
    AnsiConsole.MarkupLine('[green]HTML written to: [/][aqua]' + htmlPath + '[/]');

    AnsiConsole.Write(Widgets.Rule);
    AnsiConsole.WriteLine;

    Readln;
  except
    on E: EPromptCancelled do
      AnsiConsole.MarkupLine('[yellow]Cancelled by user.[/]');
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
