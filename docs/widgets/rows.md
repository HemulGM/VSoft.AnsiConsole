---
title: Rows
description: Stacks renderables vertically — one per line, no borders, no gutters.
---

# Rows

`IRows` is the simplest vertical container. Each child renders on its own
row, in order. No borders, no headers, no padding.

## When to use

- Stacking widgets vertically when you don't need a [Panel](./panel.md)
  border or [Layout](./layout.md)'s sized regions.
- Building dashboards by composing several widgets top-to-bottom.

## Basic usage

```pascal
var
  rs : IRows;
begin
  rs := Widgets.Rows;
  rs.Add(Widgets.Markup('[bold]Status[/]'));
  rs.Add(Widgets.Markup('[green]All systems operational[/]'));
  rs.Add(Widgets.Rule);
  rs.Add(Widgets.Markup('Last checked: 10:24 UTC'));
  AnsiConsole.Write(rs);
end;
```

## Configuration

`Rows` is intentionally minimal:

| Method | Purpose |
| --- | --- |
| `Add(child : IRenderable) : IRows` | Append a row. Returns Self for chaining. |

```pascal
AnsiConsole.Write(
  Widgets.Rows
    .Add(Widgets.Markup('[bold]header[/]'))
    .Add(Widgets.Rule)
    .Add(Widgets.Markup('body line 1'))
    .Add(Widgets.Markup('body line 2')));
```

## Composition

Rows works inside panels, table cells, and layout regions:

```pascal
AnsiConsole.Write(
  Widgets.Panel(
    Widgets.Rows
      .Add(Widgets.Markup('[bold]Title[/]'))
      .Add(Widgets.Markup('Subtitle'))
      .Add(Widgets.Rule)
      .Add(table)));
```

## API reference

- [`Widgets.Rows`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — empty row stack.
- [`IRows`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.Rows.pas) — interface.

## See also

- [Columns](./columns.md) — horizontal counterpart.
- [Grid](./grid.md) — when you need columnar alignment too.
- [Layout](./layout.md) — for sized vertical/horizontal regions.
