---
title: BarChart
description: Vertical bar chart with labelled, coloured items and optional value display.
---

# BarChart

`IBarChart` renders a vertical bar chart - one row per item, each with a
label, a horizontal filled bar, and an optional numeric value.

![BarChart screenshot](/images/barchart.png)

## When to use

- Showing scalar metrics across categories - language usage, error counts,
  benchmark results.
- Quick comparative summaries.

For percentage-of-whole stacked bars, use [BreakdownChart](./breakdownchart.md).

## Basic usage

```pascal
var
  chart : IBarChart;
begin
  chart := Widgets.BarChart.WithLabel('[bold]Languages[/]');
  chart.AddItem('Pascal', 80, TAnsiColor.Aqua);
  chart.AddItem('Go',     45, TAnsiColor.Lime);
  chart.AddItem('Rust',   60, TAnsiColor.Red);
  chart.WithWidth(40);
  AnsiConsole.Write(chart);
end;
```

## Configuration

| Method | Purpose |
| --- | --- |
| `WithLabel(value)` | Title above the chart. Markup supported. |
| `WithLabelAlignment(value)` | `TAlignment.Left` / `Center` / `Right` for the label. |
| `WithWidth(value)` | Total chart width in cells. |
| `WithMaxValue(value)` | Override the implicit max (default = max of all items). |
| `WithShowValues(value)` | Append the numeric value next to each bar. |

```pascal
chart
  .WithLabel('[bold yellow]Build times[/]')
  .WithLabelAlignment(TAlignment.Left)
  .WithWidth(60)
  .WithShowValues(True);
```

## Adding items

```pascal
chart.AddItem('label', value, TAnsiColor.Red);
```

`value` is a `Double`. Color is a `TAnsiColor` (use the named constants like
`TAnsiColor.Aqua` or build a custom one with `TAnsiColor.FromRGB(r, g, b)`).

## API reference

- [`Widgets.BarChart`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — empty chart.
- [`IBarChart`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.BarChart.pas) — interface.
- Demo: [`demos/snippets/BarChart`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/BarChart).

## See also

- [BreakdownChart](./breakdownchart.md) — single horizontal stacked bar.
- [Colours reference](../reference/colors.md).
