---
title: Padder
description: Adds configurable left / right / top / bottom whitespace around any renderable.
---

# Padder

`IPadder` wraps a child renderable and adds whitespace around it - useful
when you want spacing without a [Panel](./panel.md)'s border.

## When to use

- Visually separating content blocks without drawing a border.
- Indenting a block of output relative to its surroundings.
- Adjusting spacing inside a panel that doesn't carry enough internal
  padding by itself.

## Basic usage

```pascal
AnsiConsole.Write(
  Widgets.Padder(Widgets.Markup('[bold]content[/]'))
    .WithPadding(TPadding.Create(2, 1, 2, 1)));   // left, top, right, bottom
```

## Configuration

| Method | Purpose |
| --- | --- |
| `WithPadding(value : TPadding)` | Set padding on all four sides via a `TPadding` record. |

The `TPadding` record's constructor takes `(left, top, right, bottom)` cell
counts. Build one inline:

```pascal
panel := Widgets.Padder(content).WithPadding(TPadding.Create(4, 0, 4, 0));
```

A symmetric padding factory may also be useful:

```pascal
TPadding.Symmetric(2)        // 2 cells on every side
TPadding.Create(0, 1, 0, 1)  // 1 cell top + bottom only
```

## Composition

Padder is often used to indent a paragraph or block:

```pascal
AnsiConsole.Write(Widgets.Padder(longParagraph)
                    .WithPadding(TPadding.Create(4, 0, 0, 0)));
```

Or to add breathing room around a chart inside a panel:

```pascal
AnsiConsole.Write(
  Widgets.Panel(
    Widgets.Padder(barChart).WithPadding(TPadding.Create(1, 0, 1, 0)))
    .WithHeader('Chart'));
```

## API reference

- [`Widgets.Padder(child)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — wraps any `IRenderable`.
- [`IPadder`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.Padder.pas) — interface.

## See also

- [Panel](./panel.md) — when you also want a border.
- [Align](./align.md) — for horizontal alignment without padding.
