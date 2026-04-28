program HeroDemo;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Console,
  System.Classes,
  VSoft.AnsiConsole;

procedure RunDemo;
var
  table : ITable;
begin
  console.Clear;

  // Start with mundane terminal output
  console.WriteLine('test results log:');
  console.WriteLine('module_a: pass');
  console.WriteLine('module_b: pass');
  console.WriteLine('module_c: fail');
  console.WriteLine('module_d: pass');
  TThread.Sleep(1000);
  console.WriteLine('rethinking display format:');
  TThread.Sleep(1500);
  AnsiConsole.WriteLine;



  // Science-y status messages
  AnsiConsole.Status
    .WithAutoRefresh(True)
    .WithSpinner(TSpinnerKind.Dots)
    .Start('[grey]Detecting suboptimal display format...[/]',
      procedure(const ctx : IStatus)
      begin
        TThread.Sleep(1500);
        ctx.SetSpinner(TSpinnerKind.Arc).SetStatus('[yellow]Initializing Enhancement Protocol v2.1...[/]');
        TThread.Sleep(1500);
        ctx.SetSpinner(TSpinnerKind.Runner).SetStatus('[cyan]Calibrating visual enhancement matrices...[/]');
        TThread.Sleep(1500);
      end);

  TThread.Sleep(300);
  console.Clear;

  // Progress with technical operations
  AnsiConsole.Progress
    .WithAutoClear(False)
    .WithColumns([
      Widgets.DescriptionColumn,
      Widgets.ProgressBarColumn(40),
      Widgets.PercentageColumn,
      Widgets.SpinnerColumn])
    .Start(
      procedure(const ctx : IProgress)
      var
        quantumTask : IProgressTask;
        neuralTask  : IProgressTask;
        photonTask  : IProgressTask;
      begin
        quantumTask := ctx.AddTask('[cyan]Quantum flux optimization[/] :rocket:', 150);
        neuralTask  := ctx.AddTask('[green]Neural interface calibration[/] :robot:', 150);
        photonTask  := ctx.AddTask('[yellow]Photon emission tuning[/] :flying_saucer:', 150);

        while not ctx.IsFinished do
        begin
          TThread.Sleep(25);
          quantumTask.Increment(3.8);
          TThread.Sleep(25);
          neuralTask.Increment(4.2);
          TThread.Sleep(25);
          photonTask.Increment(5.5);
        end;
      end);

  TThread.Sleep(800);
  console.Clear;

  // Rebuild with Live - science facility style
  table := Widgets.Table;

  AnsiConsole.LiveDisplay(table)
    .WithAutoClear(False)
    .WithOverflow(TLiveOverflow.Ellipsis)
    .Start(
      procedure(const ctx : ILiveDisplay)
      var
        pnl : IPanel;
      begin
        // Initialise data matrix. Our ITable doesn't expose post-creation
        // column access, so the bold-white headers from the Spectre demo's
        // later ".Columns[i].Header(...)" calls are applied up-front here.
        table.AddColumn('[bold white]Test Module[/]'); ctx.Refresh; TThread.Sleep(200);
        table.AddColumn('[bold white]Status[/]');      ctx.Refresh; TThread.Sleep(200);
        table.AddColumn('[bold white]Efficiency[/]');  ctx.Refresh; TThread.Sleep(200);
        table.AddColumn('[bold white]Notes[/]');       ctx.Refresh; TThread.Sleep(200);

        // Populate test results
        table.AddRow(['Module Alpha', '[green]OPERATIONAL[/]', '[cyan]98.2%[/]', 'Exceeding parameters']);
        ctx.Refresh; TThread.Sleep(300);
        table.AddRow(['Module Beta',  '[green]OPERATIONAL[/]', '[cyan]94.7%[/]', 'Within tolerance']);
        ctx.Refresh; TThread.Sleep(300);
        table.AddRow(['Module Gamma', '[red]ANOMALY[/]',       '[yellow]43.1%[/]', '[yellow]Recalibration required[/]']);
        ctx.Refresh; TThread.Sleep(300);
        table.AddRow(['Module Delta', '[green]OPERATIONAL[/]', '[cyan]99.8%[/]', 'Optimal performance']);
        ctx.Refresh; TThread.Sleep(300);

        // Apply facility styling
        table.WithBorderStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Cyan2));
        ctx.Refresh; TThread.Sleep(400);
        table.WithBorder(TTableBorderKind.Simple);
        ctx.Refresh; TThread.Sleep(400);
        table.WithExpand(True);
        ctx.Refresh; TThread.Sleep(400);

        // Statistical footer (column index 2 only; rest blank)
        table.AddFooter(['', '', '[bold cyan]83.95% AVG[/]', '']).WithShowFooters(True);
        ctx.Refresh; TThread.Sleep(400);

        // Encase in facility-standard panel
        pnl := Widgets.Panel(table)
          .WithHeader('[bold yellow][[ FACILITY MONITORING SYSTEM v4.7.2 ]][/]')
          .WithBorderStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Grey))
          .WithBorder(TBoxBorderKind.Rounded)
          .WithExpand(True);
        ctx.Update(pnl);
        TThread.Sleep(600);
      end);

  // Final status
  TThread.Sleep(500);
  console.WriteLine;
  AnsiConsole.MarkupLine('[bold green]> Display optimization complete. Science continues.[/]');
end;

begin
  try
    RunDemo;
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
