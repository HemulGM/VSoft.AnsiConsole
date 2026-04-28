---
title: Text
description: A renderable wrapping plain literal text with no markup parsing.
---

# Text

`IText` renders a plain string verbatim. No markup parsing — every character
is literal.

## When to use

- Embedding a string inside another widget (table cell, panel body, column)
  where you want **no** styling and no `[` `]` interpretation.
- Otherwise, prefer [`AnsiConsole.WriteLine`](../getting-started/quick-start.md)
  or [`Markup`](./markup.md) for direct output.

::: tip
For styled text, use [`Markup`](./markup.md). For wrapped paragraphs with
alignment / justification, use [`Paragraph`](./paragraph.md).
:::

## Basic usage

```pascal
AnsiConsole.Write(Widgets.Text('Plain unstyled text'));
```

With an explicit base style:

```pascal
AnsiConsole.Write(
  Widgets.Text('Styled text',
    TAnsiStyle.Plain
      .WithForeground(TAnsiColor.Aqua)
      .WithDecorations([TAnsiDecoration.Bold])));
```

## Configuration

`IText` is intentionally minimal — there are no further configuration knobs.
For more control (alignment, overflow), use [`Paragraph`](./paragraph.md) or
[`Markup`](./markup.md).

## Composition

Text widgets are commonly used as table cells, grid rows, or column items
when you want literal content rather than markup:

```pascal
table.AddRow([Widgets.Text('plain'),
              Widgets.Markup('[red]styled[/]')]);
```

## API reference

- [`Widgets.Text(value)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — plain text.
- [`Widgets.Text(value, style)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — text with a base style.

## See also

- [Markup](./markup.md) — for styled inline content.
- [Paragraph](./paragraph.md) — wrapping text with alignment.
- [Styles](../reference/styles.md) — building `TAnsiStyle` values.
