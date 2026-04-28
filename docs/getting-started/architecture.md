---
title: Architecture
description: How VSoft.AnsiConsole's render pipeline fits together — segments, renderables, the AnsiConsole facade, and the Widgets record.
---

# Architecture

VSoft.AnsiConsole is a verbatim port of [Spectre.Console](https://spectreconsole.net/)'s
segment-based rendering model, adapted to Delphi idioms (interfaces +
value-typed records instead of classes + extension methods).

## Pipeline

```
AnsiConsole (static facade)
    -> IAnsiConsole -> RenderPipeline -> IRenderable.Render()
        -> TAnsiSegments
            -> TAnsiWriter -> IAnsiOutput
```

Top to bottom:

- **`AnsiConsole`** is a sealed class with class methods only. It owns the
  singleton console and is the entry point for everything that touches the
  terminal: `Write`, `Markup`, `Clear`, `Cursor`, `Status`, `Progress`,
  `Prompt`, `Recorder`. It does **not** build widgets — that's the
  [`Widgets`](#the-widgets-companion) record's job.
- **`IAnsiConsole`** is the singleton's interface — the actual console
  abstraction. Has a `Profile` (capabilities + dimensions), an output
  target, and a write path.
- **`IRenderable`** is the widget interface. Two methods: `Measure(opts,
  maxWidth)` returns a min/max measurement; `Render(opts, maxWidth)` returns
  a `TAnsiSegments`. Every widget — `IPanel`, `ITable`, `ITree`,
  `IBarChart`, the lot — implements this.
- **`TAnsiSegment`** is a value-type record holding `(text, style, flags)`.
  Flags distinguish text vs linebreak vs whitespace vs raw control code.
  A widget renders into a flat list of these.
- **`TAnsiWriter`** consumes segments and emits SGR / CSI / OSC byte
  sequences for the active colour system. It tracks the currently-emitted
  style and resets between segments with different styles. Under
  `TColorSystem.NoColors` it emits no escapes at all.
- **`IAnsiOutput`** is the byte sink — usually `stdout` but can be a
  capturing test sink (see [Recorder](../recording/recorder.md)) or any
  custom stream.

## The two facades

The library exposes its public API through **two** static types in
[`source/VSoft.AnsiConsole.pas`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas):

### `AnsiConsole` — operations on the active console

```pascal
AnsiConsole.WriteLine('hello');
AnsiConsole.MarkupLine('[red bold]error[/]');
AnsiConsole.Clear;
AnsiConsole.Cursor.Hide;

AnsiConsole.Status.Start('Working...', procedure(const ctx : IStatus)
  begin
    Sleep(1500);
    ctx.SetStatus('Almost done...');
    Sleep(500);
  end);
```

Everything on `AnsiConsole` either writes to the singleton, reads its state,
or builds a configurator (status / progress / prompt) bound to it.

### The `Widgets` companion — pure-construction factories

```pascal
panel  := Widgets.Panel(Widgets.Markup('[b]hi[/]'));
table  := Widgets.Table.WithBorder(TTableBorderKind.Rounded);
tree   := Widgets.Tree('[bold]root[/]');
border := Widgets.BoxBorder(TBoxBorderKind.Heavy);

AnsiConsole.Write(panel);
```

`Widgets` is a record full of `class function` factories. None of them touch
the console - they just build a value-typed widget you then `Write` or
embed inside another widget.

::: tip Why two types?
Splitting widget construction from console I/O keeps the local-variable
shadow trap at bay. The bare unit-level free function `Panel(...)` clashed
with locals like `var panel: IPanel`; routing all construction through
`Widgets.Panel(...)` makes the shadow problem disappear from user code.
:::

## Capability detection

When the singleton initialises, it calls `Profile.Detection` to figure out:

- **Whether VT100 is supported** — probed by calling
  `SetConsoleMode(ENABLE_VIRTUAL_TERMINAL_PROCESSING)` and reading back.
  We do **not** use `GetVersionEx`; on Windows 10/11 it returns Windows 8.2
  for unmanifested exes because of the compatibility shim.
- **Colour system** — `NoColors`, `Legacy` (16), `Standard` (16+8),
  `EightBit` (256), `TrueColor` (16M), per the `TColorSystem` enum. Picked
  from registry hints, env vars, and probing.
- **Unicode glyph support** — code page detection.
- **Whether stdin is interactive** — for prompts / live displays to gate
  themselves off in CI.

A handful of profile *enrichers* override these defaults when running on
GitHub Actions, AppVeyor, Travis, GitLab CI, Jenkins, TeamCity, or Bitbucket
Pipelines - so progress bars don't try to redraw and prompts don't block.
See [Capabilities reference](../reference/capabilities.md).

## What you build vs what the framework does

You build a tree of `IRenderable`s by composing widgets:

```pascal
var
  table  : ITable;
  panel  : IPanel;
begin
  table := Widgets.Table.WithBorder(TTableBorderKind.Rounded);
  table.AddColumn('Name');
  table.AddColumn('Score');
  table.AddRow(['Alice', '128']);

  panel := Widgets.Panel(table).WithHeader('Results');
  AnsiConsole.Write(panel);
end;
```

The framework:

1. Calls `panel.Measure` to figure out width.
2. Calls `panel.Render(opts, width)`, which recursively renders the table
   inside its border, padded out to the panel's content width.
3. Hands the resulting `TAnsiSegments` to the writer, which emits the
   appropriate ANSI escapes for the active colour system (or strips them
   under `NoColors`).

You never see the segments or the bytes - they're an internal contract.
Custom widgets implement `IRenderable` and produce segments the same way
the built-ins do.

## Threading

The singleton console is mutex-guarded. [Status](../live/status.md) and
[Progress](../live/progress.md) drive their refresh from a background
thread; the user's action runs on the calling thread; segments flow through
the same `IAnsiConsole` lock so output stays serialised.

## Where to go next

- [Markup widget](../widgets/markup.md) — the `[red bold]hi[/]` syntax.
- [Capabilities reference](../reference/capabilities.md) — the detection
  rules in detail.
- [`source/VSoft.AnsiConsole.pas`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — XMLDOC for every public method.
