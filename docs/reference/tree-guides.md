---
title: Tree guides reference
description: Every TTreeGuideKind — the branch-drawing glyphs used by Tree.
---

# Tree guides reference

`TTreeGuideKind` enumerates the glyph sets used by [Tree](../widgets/tree.md)
to draw branches: the vertical "continue" line, the fork at sibling
positions, the L-shape at the last child, and the horizontal arm.

## Available kinds

| Kind | Glyphs |
| --- | --- |
| `Ascii` | `\|`, `+`, `` ` ``, `-` (always ASCII). |
| `Line` (default) | `─ │ ├ └` |
| `Heavy` | `━ ┃ ┣ ┗` |
| `Double` | `═ ║ ╠ ╚` |
| `Bold` | Alias for `Heavy`. |

Non-unicode terminals automatically fall back to `Ascii`, regardless of the
configured kind.

## Glyph parts

`TTreeGuidePart`:

| Part | Used for |
| --- | --- |
| `Space` | Empty depth slot (when an ancestor is the last child). |
| `Continue` | Vertical line at a depth where an ancestor isn't the last child. |
| `Fork` | Branch at a node that has more siblings below. |
| `Last` | Branch at the last child of its parent. |
| `Horizontal` | The horizontal arm before the node label. |

## Usage

```pascal
tree := Widgets.Tree('root').WithGuide(TTreeGuideKind.Heavy);
```

Get an `ITreeGuide` instance directly:

```pascal
guide := Widgets.TreeGuide(TTreeGuideKind.Double);
```

## Custom guides

Implement `ITreeGuide` to ship a custom glyph set. Your impl returns a
`Char` per `TTreeGuidePart` plus the kind.

## See also

- [Tree](../widgets/tree.md) — primary consumer.
- [Box borders](./box-borders.md) / [Table borders](./table-borders.md) —
  the other glyph-set enums in the library.
