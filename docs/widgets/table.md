---
title: Table
description: Bordered tabular data with columns, rows, headers, footers, and 19 border styles.
---

# Table

`ITable` is the headline data widget — a fully-featured bordered table with
columns, rows, optional title and footer, 19 border styles, per-column
alignment, and markup-aware cells.

![Table screenshot](/images/table.png)

## When to use

- Tabular data with headers - product lists, query results, build summaries.
- Anywhere a [Grid](./grid.md) starts feeling under-featured (need borders,
  headers, footers, captions).

## Basic usage

```pascal
var
  t : ITable;
begin
  t := Widgets.Table.WithBorder(TTableBorderKind.Rounded);
  t.AddColumn('[bold]Name[/]', TAlignment.Left);
  t.AddColumn('[bold]Score[/]', TAlignment.Right);
  t.AddRow(['Alice', '128']);
  t.AddRow(['Bob',   ' 96']);
  t.AddRow(['Carol', '142']);
  AnsiConsole.Write(t);
end;
```

Renders:

```
╭───────┬───────╮
│ Name  │ Score │
├───────┼───────┤
│ Alice │   128 │
│ Bob   │    96 │
│ Carol │   142 │
╰───────┴───────╯
```

## Adding columns

Three overloads for `AddColumn`:

```pascal
t.AddColumn('Header');                              // auto-width, left-aligned
t.AddColumn('Header', TAlignment.Right);            // auto-width, custom alignment
t.AddColumn('Header',                               // full control
            TGridColumnWidth.Fixed, 12,             //   width strategy + value
            TAlignment.Right);
```

The header string is parsed as markup, so `[bold]Header[/]` works.

## Adding rows

```pascal
t.AddRow(['Alice', '128']);                                  // strings
t.AddRow([Widgets.Markup('[red]Bob[/]'), Widgets.Text('96')]); // mixed renderables
```

Empty / spacer row:

```pascal
t.AddEmptyRow;
```

Bulk operations:

```pascal
t.InsertRow(2, ['inserted', 'here']);
t.RemoveRow(1);
t.UpdateCell(0, 1, '999');                          // (rowIdx, colIdx, value)
```

## Footers

```pascal
t.AddFooter(['', '[bold cyan]Total: 366[/]']);
t.WithShowFooters(True);
```

The footer must have the same column count as the table.

## Configuration

| Method | Purpose |
| --- | --- |
| `WithBorder(kind)` | One of 19 `TTableBorderKind`s — `Ascii`, `Rounded`, `Heavy`, `Markdown`, `Simple`, etc. See [Table border reference](../reference/table-borders.md). |
| `WithBorder(value : ITableBorder)` | Pass a custom border instance. |
| `WithBorderStyle(value)` | Style applied to border characters. |
| `WithTitle(value : string)` | Caption rendered above the table. Markup supported. |
| `WithCaption(value : string)` | Caption rendered below. |
| `WithShowHeader(value)` | Hide / show the header row. Default `True`. |
| `WithShowFooters(value)` | Hide / show the footer row. Default `False`. |
| `WithShowRowSeparators(value)` | Inter-row horizontal separators. Default `False`. |
| `WithExpand(value)` | Fill available width. |
| `WithColumnNoWrap(i, value)` | Mark a column as no-wrap (clip instead of fold). |

```pascal
t.WithTitle('[yellow bold]Q3 Results[/]')
 .WithCaption('Source: internal dashboard')
 .WithBorder(TTableBorderKind.Heavy)
 .WithBorderStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Cyan2))
 .WithExpand(True)
 .WithShowFooters(True);
```

## Markup in cells

Pass a markup string and let `AddRow` wrap it for you:

```pascal
t.AddRow(['Alice',
          '[green]OK[/]',
          '[bold]128[/]']);
```

Or pass renderables for richer cells:

```pascal
t.AddRow([Widgets.Markup('[red]Bob[/]'),
          Widgets.Panel(Widgets.Text('inset'))]);
```

## Composition

Tables work great inside panels:

```pascal
AnsiConsole.Write(
  Widgets.Panel(t).WithHeader('Q3 Results'));
```

And inside live displays for real-time updates - see [Live display](../live/live-display.md).

## API reference

- [`Widgets.Table`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — empty table.
- [`ITable`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.Table.pas) — interface.
- Demo: [`demos/snippets/Table`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/Table).

## See also

- [Table border reference](../reference/table-borders.md) — every `TTableBorderKind` glyph.
- [Grid](./grid.md) — for borderless tabular layouts.
- [Panel](./panel.md) — wrapping a table with a heading box.
- [Live display](../live/live-display.md) — refreshing a table in place.
