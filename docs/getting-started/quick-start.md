---
title: Quick start
description: A first VSoft.AnsiConsole program in under a minute.
---

# Quick start

Once the library is [installed](./installation.md), every program follows the
same shape:

1. `uses VSoft.AnsiConsole;`
2. Call class methods on the static `AnsiConsole` facade for I/O.
3. Build widgets with the `Widgets` factory record and pass them to
   `AnsiConsole.Write`.

## Hello world

```pascal
program Hello;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole;

begin
  AnsiConsole.MarkupLine('[bold yellow]Hello[/] [italic]world[/]!');
  AnsiConsole.MarkupLine('Numbers: [red]1[/], [green]2[/], [blue]3[/] :rocket:');
end.
```

Two things to notice:

- **Markup tags** like `[bold yellow]` and `[italic]` style the surrounding
  text. Closing tag is `[/]`. See the [markup syntax reference](../reference/markup-syntax.md)
  for the full grammar.
- **Emoji shortcodes** like `:rocket:` resolve to the corresponding unicode
  glyph. See the [emoji reference](../reference/emoji.md).

Run it. You'll see styled coloured output if your terminal supports ANSI -
which it does on every modern Windows Terminal, VS Code integrated terminal,
PowerShell 7+, ConEmu, and pretty much anything not running cmd.exe from
Windows 7.

::: tip
The first call to any `AnsiConsole.X` method lazily constructs a singleton
`IAnsiConsole` with capabilities auto-detected from the host terminal. No
explicit setup needed.
:::

## Building a widget

Widgets are values you build with the [`Widgets`](../widgets/markup.md)
factory record and write with `AnsiConsole.Write`.

```pascal
program Greeting;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole;

var
  panel : IPanel;
begin
  panel := Widgets.Panel(Widgets.Markup('[bold]hello[/] world'))
             .WithHeader('Greeting')
             .WithBorder(TBoxBorderKind.Rounded);

  AnsiConsole.Write(panel);
end.
```

That renders:

```
╭── Greeting ───────╮
│ hello world       │
╰───────────────────╯
```

## Markup vs Write

Two methods for emitting text. Pick by intent:

- `AnsiConsole.MarkupLine('[bold]hi[/]')` — **parses** BBCode-style tags.
  Use this for styled output.
- `AnsiConsole.WriteLine('[bold]hi[/]')` — **literal**, no parsing. The
  brackets appear verbatim.

The widget form is `Widgets.Markup('[bold]hi[/]')`, which returns an
`IMarkup` you can embed in panels, table cells, etc.

## What's next

- [Architecture](./architecture.md) — how segments, renderables, and the
  ANSI writer fit together.
- [Markup widget](../widgets/markup.md) — full BBCode grammar.
- [Panel](../widgets/panel.md), [Table](../widgets/table.md),
  [Tree](../widgets/tree.md) — the headline widgets.
- [Status](../live/status.md) and [Progress](../live/progress.md) — live
  displays for long-running work.
- [Prompts](../prompts/text-prompt.md) — `Ask`, `Confirm`,
  `SelectionPrompt<T>`.

Or browse the runnable demo snippets at
[`demos/snippets/`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets) -
every widget has one.
