---
title: Box borders reference
description: Every TBoxBorderKind glyph set, used by Panel and any other box-bordered widget.
---

# Box borders reference

`TBoxBorderKind` enumerates the glyph sets used by [Panel](../widgets/panel.md)
and other box-bordered widgets. Each kind has a unicode form and an ASCII
fallback; non-unicode terminals automatically use the fallback.

## Available kinds

| Kind | Unicode preview | ASCII fallback |
| --- | --- | --- |
| `Square` (default) | `┌─┬─┐ │ ├─┼─┤ │ └─┴─┘` | `+-+ \| +-+` |
| `Rounded` | `╭─┬─╮ │ ├─┼─┤ │ ╰─┴─╯` | `+-+ \| +-+` |
| `Heavy` | `┏━┳━┓ ┃ ┣━╋━┫ ┃ ┗━┻━┛` | `+-+ \| +-+` |
| `Double` | `╔═╦═╗ ║ ╠═╬═╣ ║ ╚═╩═╝` | `+-+ \| +-+` |
| `Ascii` | `+-+-+ \| +-+-+ \| +-+-+` | same |
| `None` | (whitespace) | (whitespace) |

`Ascii` is forced regardless of terminal capability. `None` produces a
border-less panel — useful for nesting where the inner widget has its own
visual separation.

## Usage

In code:

```pascal
panel := Widgets.Panel(child).WithBorder(TBoxBorderKind.Rounded);
```

Get an `IBoxBorder` instance directly:

```pascal
border := Widgets.BoxBorder(TBoxBorderKind.Heavy);
```

## Glyph parts

The `TBoxBorderPart` enum names the individual glyph slots:

```
TopLeft    Top    TopRight
Left              Right
BottomLeft Bottom BottomRight
HeaderLeft        HeaderRight
```

`HeaderLeft` and `HeaderRight` sit immediately to the left and right of an
inline panel header. By default they're equal to `Left` / `Right`, so the
header text reads inline with the top border.

Getting a glyph:

```pascal
ch := border.GetPart(TBoxBorderPart.TopLeft, options.Unicode);
```

When `unicode = False`, the ASCII fallback is returned regardless of the
kind.

## Custom borders

Implement `IBoxBorder` directly if you need a custom glyph set. Your impl
returns a `Char` for every `TBoxBorderPart` value plus your `Kind` value.

## See also

- [Panel](../widgets/panel.md) — primary consumer.
- [Table borders](./table-borders.md) — separate enum for table glyphs.
- [Tree guides](./tree-guides.md) — separate enum for tree branch glyphs.
