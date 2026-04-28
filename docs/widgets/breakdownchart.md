---
title: BreakdownChart
description: A single horizontal stacked bar that splits a total into proportional coloured segments with a legend.
---

# BreakdownChart

`IBreakdownChart` renders a single horizontal bar split into coloured
segments proportional to each item's value. Below the bar sits a legend
showing labels and values.

## When to use

- Showing parts-of-a-whole - language mix in a repo, share of resources, etc.
- Compact alternative to a pie chart (which terminals don't render well).

For per-category vertical bars, use [BarChart](./barchart.md).

## Basic usage

```pascal
var
  brk : IBreakdownChart;
begin
  brk := Widgets.BreakdownChart;
  brk.AddItem('Elixir', 35, TAnsiColor.Fuchsia);
  brk.AddItem('C#',     27, TAnsiColor.Aqua);
  brk.AddItem('Ruby',   15, TAnsiColor.Red);
  brk.WithWidth(50);
  AnsiConsole.Write(brk);
end;
```

## Configuration

| Method | Purpose |
| --- | --- |
| `WithWidth(value)` | Bar width in cells. |
| `WithShowPercentage(value)` | Show a `(NN%)` next to each legend item. Default `True`. |
| `WithShowTags(value)` | Show legend tags (the colour swatch + label). Default `True`. |
| `WithShowTagValues(value)` | Show the numeric value next to each tag. |
| `WithCompact(value)` | Render the legend on a single line (or wrapped tightly). |

## Adding items

```pascal
brk.AddItem('label', value, TAnsiColor.Red);
```

## API reference

- [`Widgets.BreakdownChart`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — empty chart.
- [`IBreakdownChart`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.BreakdownChart.pas) — interface.
- Demo: [`demos/snippets/Breakdown`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/Breakdown).

## See also

- [BarChart](./barchart.md) — multiple bars instead of one stacked.
- [Colours reference](../reference/colors.md).
