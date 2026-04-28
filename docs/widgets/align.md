---
title: Align
description: Wraps a child renderable and positions it horizontally within the available width.
---

# Align

`IAlign` wraps a single child and positions it left / centre / right within
the available width. Useful for centring a panel, justifying a markup label,
or forcing a child to sit on the right edge.

## When to use

- Centring a fixed-width widget (logo, panel, calendar) in the middle of the
  terminal.
- Right-aligning a status line or footer.

For per-line text alignment, [`Markup`](./markup.md) and
[`Paragraph`](./paragraph.md) carry their own `WithAlignment` setters; reach
for `Align` only when you want to position a *whole widget* horizontally.

## Basic usage

```pascal
AnsiConsole.Write(
  Widgets.Align(Widgets.Markup('[bold]centered[/]'), TAlignment.Center));

AnsiConsole.Write(
  Widgets.Align(Widgets.Markup('[italic]right[/]'), TAlignment.Right));
```

In a wider container the difference becomes obvious - the left edge of the
child moves accordingly.

## Configuration

| Method | Purpose |
| --- | --- |
| `WithAlignment(value)` | Change horizontal alignment — `TAlignment.Left` / `Center` / `Right`. |
| `WithVerticalAlignment(value)` | Vertical positioning when the parent has slack — `TVerticalAlignment.Top` / `Middle` / `Bottom`. |

```pascal
AnsiConsole.Write(
  Widgets.Align(panel, TAlignment.Center)
    .WithVerticalAlignment(TVerticalAlignment.Middle));
```

## API reference

- [`Widgets.Align(child, alignment)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`IAlign`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.Align.pas)

## See also

- [Padder](./padder.md) — when you also want padding around the child.
- [Panel](./panel.md) — for a bordered, centered region.
- [Markup](./markup.md) / [Paragraph](./paragraph.md) — for per-line alignment.
