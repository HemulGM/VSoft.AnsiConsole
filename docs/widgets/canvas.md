---
title: Canvas
description: A pixel grid for rendering RGB images using half-block characters.
---

# Canvas

`ICanvas` is a fixed-size grid of cells you paint by RGB. Each cell renders
as a unicode half-block character, so a canvas of *width* × *height* cells
displays at *width* × *(height/2)* visual pixels - effectively doubling
vertical resolution.

## When to use

- Tiny image-like rendering in the terminal.
- Heatmaps, density plots, sprites.
- Anywhere you need direct pixel-level colour control.

## Basic usage

```pascal
var
  cnv  : ICanvas;
  x, y : Integer;
begin
  cnv := Widgets.Canvas(40, 20);
  for y := 0 to 19 do
    for x := 0 to 39 do
      cnv.SetPixel(x, y, TAnsiColor.FromRGB(x * 6, y * 12, 128));
  AnsiConsole.Write(cnv);
end;
```

## Configuration

| Method | Purpose |
| --- | --- |
| `SetPixel(x, y, color)` | Paint a single cell. |
| `WithMaxWidth(cells)` | Scale down when displayed if the canvas is wider than `cells`. |
| `WithPixelWidth(cells)` | Width of each "pixel" in cells (default 1). |

The half-block trick: `SetPixel(x, 0)` paints the upper half of cell row 0;
`SetPixel(x, 1)` paints the lower half. The widget figures out which
character to emit (`▀`, `▄`, `█`, or space) based on the two stacked pixels'
colours.

## Scaling

Build a 40×20 logical canvas but constrain it to 10 cells wide:

```pascal
cnv := Widgets.Canvas(40, 20).WithMaxWidth(10);
```

The widget downsamples on render.

## API reference

- [`Widgets.Canvas(width, height)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — fresh canvas.
- [`ICanvas`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.Canvas.pas) — interface.
- Demo: [`demos/snippets/Canvas`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/Canvas).

## See also

- [Colours reference](../reference/colors.md) — `TAnsiColor.FromRGB` / `FromHsv` / etc.
