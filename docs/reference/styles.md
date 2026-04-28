---
title: Styles reference
description: TAnsiStyle — combining colour, background, decorations, and link into a single value.
---

# Styles reference

`TAnsiStyle` is a value-type record bundling foreground, background, text
decorations, and an optional hyperlink target. Most widget setters and the
markup parser produce / consume styles.

## Building a style

Always start from `TAnsiStyle.Plain` and chain `WithXxx` setters:

```pascal
style := TAnsiStyle.Plain
           .WithForeground(TAnsiColor.Aqua)
           .WithBackground(TAnsiColor.Maroon)
           .WithDecorations([TAnsiDecoration.Bold, TAnsiDecoration.Underline]);
```

`TAnsiStyle.Plain` returns an empty style — no colours, no decorations.
`Empty` is a synonym.

::: warning
Do **not** `FillChar` a `TAnsiStyle` to zero. The record contains a managed
`FLink` string field; clobbering it with `FillChar` corrupts the heap. Use
`TAnsiStyle.Plain` instead.
:::

## Fluent setters

| Method | Purpose |
| --- | --- |
| `WithForeground(value : TAnsiColor)` | Set foreground colour. |
| `WithBackground(value : TAnsiColor)` | Set background colour. |
| `WithDecorations(value : TAnsiDecorations)` | Replace the decoration set. |
| `WithDecoration(value : TAnsiDecoration)` | Add a single decoration. |
| `WithoutDecoration(value : TAnsiDecoration)` | Remove one decoration. |
| `WithLink(value : string)` | OSC 8 hyperlink target. |
| `Combine(other : TAnsiStyle)` | Merge two styles — `other` overrides where set. |

All methods return a new `TAnsiStyle`; the receiver is unchanged.

## Decorations

`TAnsiDecorations = set of TAnsiDecoration`. Available decorations:

| Member | SGR code | Effect |
| --- | --- | --- |
| `Bold` | 1 | Heavy weight |
| `Dim` | 2 | Reduced intensity |
| `Italic` | 3 | Italic / cursive |
| `Underline` | 4 | Underline |
| `SlowBlink` | 5 | Slow blink |
| `RapidBlink` | 6 | Rapid blink |
| `Invert` | 7 | Swap fg/bg |
| `Conceal` | 8 | Hide text |
| `Strikethrough` | 9 | Line through |

```pascal
[TAnsiDecoration.Bold, TAnsiDecoration.Italic, TAnsiDecoration.Underline]
```

Many terminals don't render every decoration. `Conceal` is rare; `Italic`
support varies; `Strikethrough` works on most modern terminals.

## When to use TAnsiStyle vs markup

- **Markup** (`[red bold]hi[/]`) is best for inline text where the styling
  varies word-by-word.
- **`TAnsiStyle`** is best for widget-wide style settings (border style,
  spinner style, panel border style, table title style, etc.) where the
  whole widget shares one style.

The markup parser ultimately produces segments tagged with `TAnsiStyle`
values — the two systems are equivalent under the hood; markup is the
notation.

## Combining

```pascal
base    := TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua);
emphasis := TAnsiStyle.Plain.WithDecorations([TAnsiDecoration.Bold]);

result := base.Combine(emphasis);     // bold aqua
```

`Combine` is right-biased: properties set on the right argument override
the left. Properties left at default on the right are inherited from the
left.

## Plain style

```pascal
TAnsiStyle.Plain         // explicit empty style
TAnsiStyle.Empty         // alias
```

## See also

- [Colours](./colors.md) — `TAnsiColor` builders.
- [Markup syntax](./markup-syntax.md) — the styled-text mini-language.
