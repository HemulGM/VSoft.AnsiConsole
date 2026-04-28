---
title: Columns
description: Stacks renderables horizontally side-by-side, sharing the available width.
---

# Columns

`IColumns` lays out children horizontally. Children share the available
width; tall children wrap their lines vertically as needed.

## When to use

- Side-by-side widgets without column-width control - just split the row.
- Building summary dashboards.

For column-width control (auto / fixed / star) and row-by-row data, use
[Grid](./grid.md). For a bordered table with headers, use [Table](./table.md).

## Basic usage

```pascal
var
  cs : IColumns;
begin
  cs := Widgets.Columns;
  cs.Add(Widgets.Markup('[aqua]left column[/]'));
  cs.Add(Widgets.Markup('[yellow]middle column[/]'));
  cs.Add(Widgets.Markup('[lime]right column[/]'));
  AnsiConsole.Write(cs);
end;
```

## Configuration

| Method | Purpose |
| --- | --- |
| `Add(child : IRenderable) : IColumns` | Append a column. Returns Self for chaining. |

```pascal
AnsiConsole.Write(
  Widgets.Columns
    .Add(Widgets.Panel(Widgets.Markup('[red]left[/]')))
    .Add(Widgets.Panel(Widgets.Markup('[green]middle[/]')))
    .Add(Widgets.Panel(Widgets.Markup('[blue]right[/]'))));
```

## API reference

- [`Widgets.Columns`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — empty column stack.
- [`IColumns`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.Columns.pas) — interface.

## See also

- [Grid](./grid.md) — when you need column-width control.
- [Rows](./rows.md) — vertical counterpart.
- [Layout](./layout.md) — for named, sized regions with nested splits.
