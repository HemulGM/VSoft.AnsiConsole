---
title: Live display
description: In-place redraw of any renderable — swap the content via `ctx.Update` while your action runs.
---

# Live display

`AnsiConsole.LiveDisplay` is a generic in-place renderer. Pass an initial
`IRenderable`; inside the action callback the `ILiveDisplay` context lets
you `Update` the renderable (or `Refresh` after mutating one in place) and
the new frame replaces the old without scrolling.

## When to use

- Building a dashboard that updates every few seconds.
- Animating a widget (e.g. a [Table](../widgets/table.md) being assembled
  row-by-row).
- Anything where [Status](./status.md) and [Progress](./progress.md) don't
  fit but you still want flicker-free redraws.

## Basic usage

```pascal
var
  table : ITable;
begin
  table := Widgets.Table;

  AnsiConsole.LiveDisplay(table)
    .WithAutoClear(False)
    .WithOverflow(TLiveOverflow.Ellipsis)
    .Start(
      procedure(const ctx : ILiveDisplay)
      begin
        table.AddColumn('Module');
        ctx.Refresh;
        Sleep(200);

        table.AddColumn('Status');
        ctx.Refresh;
        Sleep(200);

        table.AddRow(['Alpha', 'OK']);
        ctx.Refresh;
        Sleep(300);

        table.AddRow(['Beta', 'OK']);
        ctx.Refresh;
        Sleep(300);
      end);
end;
```

The `table` instance is mutated; `ctx.Refresh` redraws using the same
renderable. To replace the whole renderable (e.g. swap from a `Table` to a
`Panel(Table)` at the end), use `ctx.Update`:

```pascal
ctx.Update(Widgets.Panel(table).WithHeader('Done'));
```

## Configuration

| Method | Purpose |
| --- | --- |
| `WithAutoClear(value)` | Clear the live region when the action exits. Default `True`. Pass `False` to keep the final frame visible. |
| `WithOverflow(value)` | What happens when the renderable is taller than the terminal — `TLiveOverflow.Visible` (let the terminal scroll), `Crop` (drop excess lines silently), `Ellipsis` (drop with `…` indicator). |
| `WithCropping(value)` | When cropping, which end to drop — `TLiveCropping.Top` (keep the bottom; matches Spectre's default) or `Bottom`. |

## The ILiveDisplay context

| Member | Purpose |
| --- | --- |
| `Update(renderable)` | Replace the displayed renderable. |
| `Refresh` | Re-render the current renderable in place — useful when you mutated it. |

## Threading

The action runs on the calling thread. If your widget is mutated from a
background thread, that's safe - all writes go through the underlying
console's lock - but you'll typically call `Refresh` after each batch of
mutations to make sure the on-screen frame is up to date.

## Explicit console

```pascal
AnsiConsole.LiveDisplay(myCapturedConsole, table).Start(...);
```

There's also a Spectre-named alias `AnsiConsole.Live(initial)`.

## API reference

- [`AnsiConsole.LiveDisplay(initial)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — singleton-bound.
- [`AnsiConsole.LiveDisplay(console, initial)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — explicit console.
- [`AnsiConsole.Live(initial)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — Spectre-named alias.
- [`ILiveDisplayConfig`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Live/VSoft.AnsiConsole.Live.Display.pas)
- [`ILiveDisplay`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Live/VSoft.AnsiConsole.Live.Display.pas)
- HeroDemo's table-reveal section is a worked example: [`demos/HeroDemo/HeroDemo.dpr`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/demos/HeroDemo/HeroDemo.dpr).

## See also

- [Status](./status.md) — opinionated single-task spinner.
- [Progress](./progress.md) — multi-task tracker.
- [Layout](../widgets/layout.md) — for region-based dashboards.
