---
title: Paragraph
description: A wrapping text container with alignment, justification, and overflow control.
---

# Paragraph

`IParagraph` renders a block of text that **wraps** at the available width.
It supports alignment (left / centre / right), full justification (insert
spaces between words to align both edges), and configurable overflow
behaviour when content exceeds the available height.

## When to use

- Long-form text blocks that should reflow when the terminal resizes.
- Lorem-ipsum-style body copy in a panel or layout cell.

For short single-line styled text, use [Markup](./markup.md). For literal
unwrapped text, use [Text](./text.md).

## Basic usage

```pascal
AnsiConsole.Write(
  Widgets.Paragraph('Lorem ipsum dolor sit amet, consectetur ' +
                    'adipiscing elit. Quisque in metus sed sapien...'));
```

## Three alignments + full justification

```pascal
AnsiConsole.Write(
  Widgets.Paragraph('[green]left aligned[/]')
    .WithAlignment(TAlignment.Left));
AnsiConsole.Write(
  Widgets.Paragraph('[yellow]centered[/]')
    .WithAlignment(TAlignment.Center));
AnsiConsole.Write(
  Widgets.Paragraph('[blue]right aligned[/]')
    .WithAlignment(TAlignment.Right));
```

## Configuration

| Method | Purpose |
| --- | --- |
| `WithAlignment(value)` | `TAlignment.Left` / `Center` / `Right`. |
| `WithOverflow(value)` | Word-too-long handling — `TOverflow.Fold` (break mid-word), `Crop` (drop overflow), `Ellipsis` (truncate with `…`). |

Markup tags inside the paragraph text style segments individually:

```pascal
AnsiConsole.Write(
  Widgets.Paragraph(
    'Status: [green]OK[/]. Latency: [bold]42ms[/]. ' +
    'Click [link=https://example.com]here[/].'));
```

## Composition

Paragraphs are commonly used inside panels:

```pascal
AnsiConsole.Write(
  Widgets.Panel(
    Widgets.Paragraph(longBodyText).WithAlignment(TAlignment.Left))
    .WithHeader('Article'));
```

## API reference

- [`Widgets.Paragraph()`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — empty.
- [`Widgets.Paragraph(text)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — with content.
- [`Widgets.Paragraph(text, style)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — with content and base style.

## See also

- [Markup](./markup.md) — for inline styling.
- [Text](./text.md) — for unwrapped literal text.
- [Panel](./panel.md) — common container for paragraphs.
