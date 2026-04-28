---
title: Status
description: Animated spinner with a status message, refreshed in place while a long-running action runs.
---

# Status

`AnsiConsole.Status` displays a spinner and a status message that
auto-refreshes while your action runs on the calling thread. Inside the
action, an `IStatus` context lets you swap message, spinner kind, and
spinner style on the fly.

## When to use

- Single-task long-running work where you don't have meaningful progress
  measurements - "Connecting...", "Authenticating...", "Compiling...".

For multi-task progress with measurable work and per-task percentages, use
[Progress](./progress.md). For an arbitrary in-place redraw of any
renderable, use [Live display](./live-display.md).

## Basic usage

```pascal
AnsiConsole.Status.Start('[yellow]Connecting...[/]',
  procedure(const ctx : IStatus)
  begin
    Sleep(1500);
    ctx.SetStatus('[green]Authenticated.[/] Fetching data...');
    Sleep(1500);
  end);
AnsiConsole.MarkupLine('Data downloaded :check_mark_button:');
```

The action runs on the calling thread; a background ticker thread refreshes
the spinner. When the action returns, the spinner clears and execution
continues.

## Configuring the display

Fluent setters before `Start`:

```pascal
AnsiConsole.Status
  .WithSpinner(TSpinnerKind.Dots)
  .WithSpinnerStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua))
  .WithMessageStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Yellow))
  .Start('Working...', procedure(const ctx : IStatus) begin Sleep(2000); end);
```

| Method | Purpose |
| --- | --- |
| `WithSpinner(kind)` | Pick a built-in `TSpinnerKind`. |
| `WithSpinner(spinner)` | Pass a custom `ISpinner`. |
| `WithSpinnerStyle(value)` | Style applied to the spinner glyphs. |
| `WithMessageStyle(value)` | Base style for the message (markup overrides per-segment). |
| `WithAutoRefresh(value)` | When `False` the ticker thread is suppressed; you drive redraw via `ctx.Refresh`. Default `True`. |

## Mutating in-flight

The `IStatus` context handed to your action lets you change message,
spinner, and spinner style:

```pascal
AnsiConsole.Status
  .WithSpinner(TSpinnerKind.Dots)
  .Start('[grey]Detecting display...[/]',
    procedure(const ctx : IStatus)
    begin
      Sleep(1500);
      ctx.SetSpinner(TSpinnerKind.Arc)
         .SetStatus('[yellow]Initialising...[/]');
      Sleep(1500);

      ctx.SetSpinner(TSpinnerKind.Runner)
         .SetStatus('[cyan]Calibrating matrices...[/]');
      Sleep(1500);
    end);
```

Setters return the context for chaining. There's also `ctx.Refresh` for
forcing an immediate redraw (useful when `AutoRefresh = False`).

| Member | Purpose |
| --- | --- |
| `GetStatus` / `SetStatus(value)` | Read / change the message. |
| `GetSpinner` / `SetSpinner(kind\|spinner)` | Read / change the spinner. |
| `GetSpinnerStyle` / `SetSpinnerStyle(value)` | Read / change the spinner style. |
| `Refresh` | Force a redraw. |

## Explicit console

For tests / recording you can pass a captured console:

```pascal
AnsiConsole.Status(myCapturedConsole)
  .WithSpinner(TSpinnerKind.Arc)
  .Start('Working...', proc);
```

## API reference

- [`AnsiConsole.Status`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — singleton-bound.
- [`AnsiConsole.Status(console)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — explicit console.
- [`IStatusConfig`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Live/VSoft.AnsiConsole.Live.Status.pas) — config interface.
- [`IStatus`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Live/VSoft.AnsiConsole.Live.Status.pas) — action context.
- Demo: [`demos/snippets/Status`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/Status).

## See also

- [Spinners reference](../reference/spinners.md) — every `TSpinnerKind`.
- [Progress](./progress.md) — multi-task progress trackers.
- [Live display](./live-display.md) — generic in-place updates.
