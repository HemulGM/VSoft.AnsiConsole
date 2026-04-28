---
title: Progress
description: Multi-task progress tracker with configurable columns — description, bar, percentage, spinner, elapsed, remaining, etc.
---

# Progress

`AnsiConsole.Progress` displays a live, multi-task progress tracker. Each
task is one row; the columns - description, bar, percentage, spinner,
elapsed, remaining time, downloaded bytes, transfer speed - are
user-configurable.

![Progress screenshot](/images/progress.png)

## When to use

- Anything with measurable work - downloads, batch processing, build steps.
- Single tasks too (just add one) - the per-task speed / ETA computations
  are useful even on their own.

For indeterminate single-task spinners, [Status](./status.md) is simpler.

## Basic usage

```pascal
AnsiConsole.Progress.Start(
  procedure(const ctx : IProgress)
  var
    download : IProgressTask;
    process  : IProgressTask;
  begin
    download := ctx.AddTask('Downloading', 100);
    process  := ctx.AddTask('Processing',  100);
    while not (download.IsFinished and process.IsFinished) do
    begin
      if not download.IsFinished then download.Increment(2);
      if download.Percentage > 30 then process.Increment(1);
      Sleep(60);
    end;
  end);
```

Each `AddTask(description, maxValue)` returns an `IProgressTask` you mutate
inside the action. A background ticker thread redraws the board every
~100ms.

## Configuring columns

```pascal
AnsiConsole.Progress
  .WithColumns([
    Widgets.DescriptionColumn,
    Widgets.ProgressBarColumn(40),
    Widgets.PercentageColumn,
    Widgets.SpinnerColumn,
    Widgets.RemainingTimeColumn])
  .Start(
    procedure(const ctx : IProgress)
    begin
      // ...
    end);
```

Available column factories on the [`Widgets`](../widgets/markup.md) record:

| Factory | What it shows |
| --- | --- |
| `DescriptionColumn` | The label passed to `AddTask`. Markup supported. |
| `ProgressBarColumn` | Filled / unfilled bar. |
| `ProgressBarColumn(width)` | Bar capped at `width` cells; `-1` = no cap. |
| `PercentageColumn` | `42%` |
| `ElapsedColumn` | `hh:mm:ss` since `StartTask`. |
| `RemainingTimeColumn` | `hh:mm:ss` ETA (or `**:**:**` if indeterminate). |
| `SpinnerColumn` / `SpinnerColumn(kind)` | Animated spinner. |
| `DownloadedColumn` | `512 KB / 1 MB` formatted bytes. |
| `TransferSpeedColumn` | `256 KB/s` rolling average. |

## Configuration

| Method | Purpose |
| --- | --- |
| `WithColumns(array)` | Set the column list. |
| `WithAutoClear(value)` | Clear the entire board when the action exits. Default `False`. |
| `WithHideCompleted(value)` | Hide tasks that have reached their max. |
| `WithRefreshMs(value)` | Ticker interval (ms). Default ~100ms. |
| `WithAutoRefresh(value)` | Suppress the ticker; you drive redraw via `ctx.Refresh`. |
| `WithRenderHook(hook)` | Wrap the rendered board in a custom renderable each tick - useful for adding a panel/header around the live region. |

```pascal
AnsiConsole.Progress
  .WithColumns([Widgets.DescriptionColumn, Widgets.ProgressBarColumn(40), Widgets.PercentageColumn])
  .WithAutoClear(True)
  .Start(...);
```

## The IProgress context

Inside the action, `ctx : IProgress` exposes:

| Member | Purpose |
| --- | --- |
| `AddTask(description, maxValue) : IProgressTask` | Start a task. |
| `AddTask(description, maxValue, autoStart : Boolean)` | Defer auto-start. |
| `AddTaskAt(description, index, maxValue, autoStart)` | Insert at a specific row index. |
| `AddTaskBefore(description, refTask, ...)` / `AddTaskAfter(...)` | Relative-position inserts. |
| `IsFinished : Boolean` | All tasks complete? |
| `Refresh` | Force a redraw. |

## The IProgressTask handle

| Member | Purpose |
| --- | --- |
| `Increment(by : Double = 1)` | Bump the value. |
| `StartTask` / `StopTask` | Manual lifecycle when `autoStart = False`. |
| `IsFinished : Boolean` | `Value >= MaxValue`. |
| `Value` / `MaxValue` (rw) | Direct numeric access. |
| `Description` (rw) | Update the label after creation. |
| `IsIndeterminate` (rw) | When `True` the bar pulses, percentage stops counting. |
| `Percentage` | Read-only computed value. |
| `Speed` | Steps/sec rolling average over a 30s window. |
| `RemainingMs` | ETA based on speed. |

## Indeterminate tasks

```pascal
t := ctx.AddTask('Pre-flight checks', 0);
t.IsIndeterminate := True;
// later, when work becomes measurable:
t.MaxValue := 200;
t.IsIndeterminate := False;
```

The progress bar pulses while indeterminate (a cosine-fade animation).

## Explicit console

```pascal
AnsiConsole.Progress(myCapturedConsole).Start(...);
```

## API reference

- [`AnsiConsole.Progress`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`AnsiConsole.Progress(console)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`IProgressConfig`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Live/VSoft.AnsiConsole.Live.Progress.pas)
- [`IProgress`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Live/VSoft.AnsiConsole.Live.Progress.pas)
- [`IProgressTask`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Live/VSoft.AnsiConsole.Live.Progress.pas)
- Demo: [`demos/snippets/Progress`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/Progress).

## See also

- [Status](./status.md) — single indeterminate task.
- [Live display](./live-display.md) — generic in-place updates for non-progress widgets.
- [Spinners reference](../reference/spinners.md).
