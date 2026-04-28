---
title: Table borders reference
description: Every TTableBorderKind — 19 styles from minimal to heavy, ascii to markdown.
---

# Table borders reference

`TTableBorderKind` enumerates the glyph sets used by [Table](../widgets/table.md).
Each has a unicode form (where applicable) and an ASCII fallback; non-unicode
terminals automatically use the fallback.

## Available kinds

| Kind | Description |
| --- | --- |
| `None` | Whitespace - columns sit in plain text. |
| `Ascii` | `+`, `-`, `\|`. Always ASCII. |
| `Ascii2` | ASCII with cell verticals on header sides. |
| `AsciiDoubleHead` | ASCII with `=` in the header separator. |
| `Square` (default) | `─ │ ┌` etc. |
| `Rounded` | Like `Square` but with rounded corners. |
| `Heavy` | `━ ┃ ┏ ...` |
| `HeavyEdge` | Heavy outer edges + light inner separators. |
| `HeavyHead` | Heavy top + heavy header separator, light elsewhere. |
| `Double` | `═ ║ ╔ ...` |
| `DoubleEdge` | Double outer edges + light inner separators. |
| `Minimal` | Only the cell vertical and the header separator. |
| `MinimalHeavyHead` | Minimal with a heavy header separator. |
| `MinimalDoubleHead` | Minimal with a double header separator. |
| `Simple` | Only the header separator dashes; no verticals. |
| `SimpleHeavy` | Simple but with heavy header separator. |
| `Horizontal` | Dashes for every horizontal line, no verticals. |
| `Minimalist` | Header underline + space cell separator only. |
| `Markdown` | Pipes + dashes, GitHub-compatible. |

`Markdown` is special - the resulting output is valid GitHub-flavoured
markdown that pastes cleanly into PRs and issues:

```
| Name  | Score |
|-------|-------|
| Alice |   128 |
| Bob   |    96 |
```

## Usage

```pascal
table := Widgets.Table.WithBorder(TTableBorderKind.Rounded);
```

Get an `ITableBorder` instance directly:

```pascal
border := Widgets.TableBorder(TTableBorderKind.Heavy);
```

## Glyph parts

`TTableBorderPart`:

```
TopLeft    Top    TopMid    TopRight
CellLeft           CellMid           CellRight
HeadLeft   Head   HeadMid   HeadRight
BottomLeft Bottom BottomMid BottomRight
```

Custom borders implement `ITableBorder` and return a `Char` for every
`TTableBorderPart` value plus the kind.

## See also

- [Table](../widgets/table.md) — primary consumer.
- [Box borders](./box-borders.md) — separate enum for panel glyphs.
- [Tree guides](./tree-guides.md) — separate enum for tree branch glyphs.
