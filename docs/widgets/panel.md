---
title: Panel
description: A bordered box that wraps a single renderable child, with an optional inline header and footer.
---

# Panel

`IPanel` draws a bordered box around any renderable. It supports an inline
header and footer, six border kinds, configurable padding, and an `Expand`
mode for full-width layout.

![Panel screenshot](/images/panel.png)

## When to use

- Highlighting a region of output - errors, warnings, summary boxes.
- Wrapping text or another widget so it visually stands apart.
- Grouping related fields with a heading.

## Basic usage

```pascal
AnsiConsole.Write(
  Widgets.Panel(Widgets.Markup('[bold]hello[/] world'))
    .WithHeader('Greeting')
    .WithBorder(TBoxBorderKind.Rounded));
```

Renders:

```
╭── Greeting ───────╮
│ hello world       │
╰───────────────────╯
```

The body can be any `IRenderable`:

```pascal
panel := Widgets.Panel(table).WithHeader('Results');
panel := Widgets.Panel(tree).WithHeader('Project');
panel := Widgets.Panel(barChart).WithBorder(TBoxBorderKind.Heavy);
```

## Configuration

| Method | Purpose |
| --- | --- |
| `WithHeader(value)` | Inline header rendered on the top border. Markup is supported. |
| `WithFooter(value)` | Inline footer on the bottom border. |
| `WithBorder(kind)` | Border glyphs — `Square` / `Rounded` / `Heavy` / `Double` / `Ascii` / `None`. |
| `WithBorder(value : IBoxBorder)` | Pass a custom `IBoxBorder` instance. |
| `WithBorderStyle(value)` | Style (colour / decorations) applied to the border characters. |
| `WithPadding(cells)` | Inner whitespace around the body. Default `1`. |
| `WithExpand(value)` | When `True` the panel fills the available width. Default `False` (panel sizes to content). |

```pascal
AnsiConsole.Write(
  Widgets.Panel(Widgets.Markup('[lime]operational[/]'))
    .WithHeader('[bold yellow]System status[/]')
    .WithFooter('Last checked: 10:24 UTC')
    .WithBorder(TBoxBorderKind.Heavy)
    .WithBorderStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua))
    .WithPadding(2)
    .WithExpand(True));
```

## Composition

Panels nest:

```pascal
AnsiConsole.Write(
  Widgets.Panel(
    Widgets.Panel(Widgets.Text('inner'))
      .WithBorder(TBoxBorderKind.Square))
    .WithHeader('outer')
    .WithBorder(TBoxBorderKind.Rounded));
```

A panel with a markup string body is shorthand:

```pascal
// Equivalent to: Widgets.Panel(Widgets.Markup('[b]hi[/]')).WithHeader(...)
Widgets.Panel('[b]hi[/]').WithHeader('Greeting');
```

## API reference

- [`Widgets.Panel(child)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — wraps any `IRenderable`.
- [`Widgets.Panel(markup)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — markup-string shortcut.
- [`IPanel`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.Panel.pas) — full interface.
- Demo: [`demos/snippets/PanelRule`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/PanelRule).

## See also

- [Box border reference](../reference/box-borders.md) — every `TBoxBorderKind` glyph.
- [Padder](./padder.md) — when you only need padding and no border.
- [Rule](./rule.md) — for a separator without a body.
- [Layout](./layout.md) — when you need multiple panels arranged side-by-side.
