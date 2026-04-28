program VSoft.AnsiConsole.Tests;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF}
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types in '..\source\Core\VSoft.AnsiConsole.Types.pas',
  VSoft.AnsiConsole.Color in '..\source\Core\VSoft.AnsiConsole.Color.pas',
  VSoft.AnsiConsole.Emoji in '..\source\Core\VSoft.AnsiConsole.Emoji.pas',
  VSoft.AnsiConsole.Style in '..\source\Core\VSoft.AnsiConsole.Style.pas',
  VSoft.AnsiConsole.Segment in '..\source\Core\VSoft.AnsiConsole.Segment.pas',
  VSoft.AnsiConsole.Measurement in '..\source\Core\VSoft.AnsiConsole.Measurement.pas',
  VSoft.AnsiConsole.Internal.Cell.Tables in '..\source\Internal\VSoft.AnsiConsole.Internal.Cell.Tables.pas',
  VSoft.AnsiConsole.Internal.Cell in '..\source\Internal\VSoft.AnsiConsole.Internal.Cell.pas',
  VSoft.AnsiConsole.Internal.SegmentOps in '..\source\Internal\VSoft.AnsiConsole.Internal.SegmentOps.pas',
  VSoft.AnsiConsole.Rendering in '..\source\Rendering\VSoft.AnsiConsole.Rendering.pas',
  VSoft.AnsiConsole.Rendering.AnsiWriter in '..\source\Rendering\VSoft.AnsiConsole.Rendering.AnsiWriter.pas',
  VSoft.AnsiConsole.Capabilities in '..\source\Profile\VSoft.AnsiConsole.Capabilities.pas',
  VSoft.AnsiConsole.Detection in '..\source\Profile\VSoft.AnsiConsole.Detection.pas',
  VSoft.AnsiConsole.Enrichment in '..\source\Profile\VSoft.AnsiConsole.Enrichment.pas',
  VSoft.AnsiConsole.Profile in '..\source\Profile\VSoft.AnsiConsole.Profile.pas',
  VSoft.AnsiConsole.Console in '..\source\Console\VSoft.AnsiConsole.Console.pas',
  VSoft.AnsiConsole.Settings in '..\source\Console\VSoft.AnsiConsole.Settings.pas',
  VSoft.AnsiConsole.Cursor in '..\source\Console\VSoft.AnsiConsole.Cursor.pas',
  VSoft.AnsiConsole.Markup.Tokenizer in '..\source\Markup\VSoft.AnsiConsole.Markup.Tokenizer.pas',
  VSoft.AnsiConsole.Markup.Parser in '..\source\Markup\VSoft.AnsiConsole.Markup.Parser.pas',
  VSoft.AnsiConsole.Borders.Box in '..\source\Borders\VSoft.AnsiConsole.Borders.Box.pas',
  VSoft.AnsiConsole.Borders.Table in '..\source\Borders\VSoft.AnsiConsole.Borders.Table.pas',
  VSoft.AnsiConsole.Borders.Tree in '..\source\Borders\VSoft.AnsiConsole.Borders.Tree.pas',
  VSoft.AnsiConsole.Widgets.Text in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Text.pas',
  VSoft.AnsiConsole.Widgets.Markup in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Markup.pas',
  VSoft.AnsiConsole.Widgets.Rule in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Rule.pas',
  VSoft.AnsiConsole.Widgets.Paragraph in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Paragraph.pas',
  VSoft.AnsiConsole.Widgets.Padder in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Padder.pas',
  VSoft.AnsiConsole.Widgets.Align in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Align.pas',
  VSoft.AnsiConsole.Widgets.Rows in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Rows.pas',
  VSoft.AnsiConsole.Widgets.Columns in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Columns.pas',
  VSoft.AnsiConsole.Widgets.Grid in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Grid.pas',
  VSoft.AnsiConsole.Widgets.Panel in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Panel.pas',
  VSoft.AnsiConsole.Widgets.Table in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Table.pas',
  VSoft.AnsiConsole.Widgets.Tree in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Tree.pas',
  VSoft.AnsiConsole.Widgets.Canvas in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Canvas.pas',
  VSoft.AnsiConsole.Widgets.BarChart in '..\source\Widgets\VSoft.AnsiConsole.Widgets.BarChart.pas',
  VSoft.AnsiConsole.Widgets.BreakdownChart in '..\source\Widgets\VSoft.AnsiConsole.Widgets.BreakdownChart.pas',
  VSoft.AnsiConsole.Widgets.Calendar in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Calendar.pas',
  VSoft.AnsiConsole.Widgets.TextPath in '..\source\Widgets\VSoft.AnsiConsole.Widgets.TextPath.pas',
  VSoft.AnsiConsole.Widgets.Layout in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Layout.pas',
  VSoft.AnsiConsole.Widgets.Figlet in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Figlet.pas',
  VSoft.AnsiConsole.Internal.FigletFont in '..\source\Internal\VSoft.AnsiConsole.Internal.FigletFont.pas',
  VSoft.AnsiConsole.Internal.Fonts.Standard in '..\source\Internal\VSoft.AnsiConsole.Internal.Fonts.Standard.pas',
  VSoft.AnsiConsole.Widgets.Json in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Json.pas',
  VSoft.AnsiConsole.Widgets.Exception in '..\source\Widgets\VSoft.AnsiConsole.Widgets.Exception.pas',
  VSoft.AnsiConsole.Recorder in '..\source\Console\VSoft.AnsiConsole.Recorder.pas',
  VSoft.AnsiConsole.Input in '..\source\Console\VSoft.AnsiConsole.Input.pas',
  VSoft.AnsiConsole.Prompts.Common in '..\source\Prompts\VSoft.AnsiConsole.Prompts.Common.pas',
  VSoft.AnsiConsole.Prompts.Hierarchy in '..\source\Prompts\VSoft.AnsiConsole.Prompts.Hierarchy.pas',
  VSoft.AnsiConsole.Prompts.Text in '..\source\Prompts\VSoft.AnsiConsole.Prompts.Text.pas',
  VSoft.AnsiConsole.Prompts.Text.Generic in '..\source\Prompts\VSoft.AnsiConsole.Prompts.Text.Generic.pas',
  VSoft.AnsiConsole.Prompts.Confirm in '..\source\Prompts\VSoft.AnsiConsole.Prompts.Confirm.pas',
  VSoft.AnsiConsole.Prompts.Select in '..\source\Prompts\VSoft.AnsiConsole.Prompts.Select.pas',
  VSoft.AnsiConsole.Prompts.MultiSelect in '..\source\Prompts\VSoft.AnsiConsole.Prompts.MultiSelect.pas',
  VSoft.AnsiConsole.Live.Exclusivity in '..\source\Live\VSoft.AnsiConsole.Live.Exclusivity.pas',
  VSoft.AnsiConsole.Live.Display in '..\source\Live\VSoft.AnsiConsole.Live.Display.pas',
  VSoft.AnsiConsole.Live.Spinners in '..\source\Live\VSoft.AnsiConsole.Live.Spinners.pas',
  VSoft.AnsiConsole.Live.Status in '..\source\Live\VSoft.AnsiConsole.Live.Status.pas',
  VSoft.AnsiConsole.Live.Progress in '..\source\Live\VSoft.AnsiConsole.Live.Progress.pas',
  VSoft.AnsiConsole in '..\source\VSoft.AnsiConsole.pas',
  Tests.Widgets.Exception in 'Tests.Widgets.Exception.pas',
  Tests.Recorder in 'Tests.Recorder.pas',
  Tests.Widgets.Json in 'Tests.Widgets.Json.pas',
  Tests.Widgets.Figlet in 'Tests.Widgets.Figlet.pas',
  Tests.Widgets.LayoutAreas in 'Tests.Widgets.LayoutAreas.pas',
  Tests.Widgets.TextPath in 'Tests.Widgets.TextPath.pas',
  Tests.Widgets.Canvas in 'Tests.Widgets.Canvas.pas',
  Tests.Widgets.Calendar in 'Tests.Widgets.Calendar.pas',
  Tests.Widgets.BreakdownChart in 'Tests.Widgets.BreakdownChart.pas',
  Tests.Widgets.BarChart in 'Tests.Widgets.BarChart.pas',
  Tests.Widgets.Cell in 'Tests.Widgets.Cell.pas',
  Tests.Widgets.Paragraph in 'Tests.Widgets.Paragraph.pas',
  Tests.Cursor in 'Tests.Cursor.pas',
  Tests.Live.Spinners in 'Tests.Live.Spinners.pas',
  Tests.Widgets in 'Tests.Widgets.pas',
  Tests.Color in 'Tests.Color.pas',
  Tests.Widgets.Layout in 'Tests.Widgets.Layout.pas',
  Tests.Markup in 'Tests.Markup.pas',
  Tests.Prompts in 'Tests.Prompts.pas',
  Tests.Enrichment in 'Tests.Enrichment.pas',
  Tests.Widgets.Table in 'Tests.Widgets.Table.pas',
  Tests.Style in 'Tests.Style.pas',
  Tests.Widgets.Tree in 'Tests.Widgets.Tree.pas',
  Tests.Facade in 'Tests.Facade.pas',
  Tests.Live in 'Tests.Live.pas',
  Tests.Capabilities in 'Tests.Capabilities.pas',
  Tests.Emoji in 'Tests.Emoji.pas',
  Tests.Borders.Table in 'Tests.Borders.Table.pas',
  Tests.Internal.Cell in 'Tests.Internal.Cell.pas',
  Tests.Internal.SegmentOps in 'Tests.Internal.SegmentOps.pas',
  Testing.ConsoleInput in 'Testing.ConsoleInput.pas',
  Tests.Borders.Tree in 'Tests.Borders.Tree.pas',
  Tests.Borders in 'Tests.Borders.pas',
  Testing.AnsiConsole in 'Testing.AnsiConsole.pas',
  Tests.AnsiWriter in 'Tests.AnsiWriter.pas';

{$IFNDEF TESTINSIGHT}
var
  runner  : ITestRunner;
  results : IRunResults;
  logger  : ITestLogger;
  nunitLogger : ITestLogger;
{$ENDIF}
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    TDUnitX.CheckCommandLine;
    runner := TDUnitX.CreateRunner;
    runner.UseRTTI := false;
    runner.FailsOnNoAsserts := False;

    logger := TDUnitXConsoleLogger.Create(True);
    runner.AddLogger(logger);

    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    TDUnitX.Options.ExitBehavior := TDUnitXExitBehavior.Pause;
    {$ENDIF}

    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ENDIF}
end.
