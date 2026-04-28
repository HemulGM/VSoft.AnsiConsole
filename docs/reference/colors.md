---
title: Colours reference
description: Named colours, the 256 palette, truecolor, and how the active colour system downsamples.
---

# Colours reference

`TAnsiColor` is a value-type record describing a foreground or background
colour. Build them by name, by 256-palette index, by RGB, or by hex.

## Building colours

```pascal
// Named — the 16 ANSI colours plus a handful of extended names
TAnsiColor.Red
TAnsiColor.Aqua
TAnsiColor.Lime
TAnsiColor.Cyan2
TAnsiColor.Grey

// 256-palette index (0-255)
TAnsiColor.FromIndex(202)

// 24-bit RGB
TAnsiColor.FromRGB(255, 136, 0)

// Hex
TAnsiColor.FromHex('#ff8800')
TAnsiColor.FromHex('ff8800')          // # is optional
```

A zero-initialised `TAnsiColor` (no constructor call) means **default** —
"use the terminal's default for this slot". `IsDefault` returns `True`.

## Named colours

The 16 ANSI base colours are always available. They map to the 30-37 / 40-47
SGR codes (and 90-97 / 100-107 for the bright variants):

| Name | SGR fg | SGR bg |
| --- | --- | --- |
| `Black` | 30 | 40 |
| `Maroon` | 31 | 41 |
| `Green` | 32 | 42 |
| `Olive` | 33 | 43 |
| `Navy` | 34 | 44 |
| `Purple` | 35 | 45 |
| `Teal` | 36 | 46 |
| `Silver` | 37 | 47 |
| `Grey` | 90 | 100 |
| `Red` | 91 | 101 |
| `Lime` | 92 | 102 |
| `Yellow` | 93 | 103 |
| `Blue` | 94 | 104 |
| `Fuchsia` | 95 | 105 |
| `Aqua` | 96 | 106 |
| `White` | 97 | 107 |

Plus extended names that resolve into the 256-palette: `Cyan2`,
`Aquamarine1`, `DodgerBlue1`, etc. See
[`source/Core/VSoft.AnsiConsole.Color.pas`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Core/VSoft.AnsiConsole.Color.pas)
for the full named-colour list.

## In markup

The same names work as markup tokens (lowercase by convention):

```
[red]hi[/]
[bold cyan2]hi[/]
[#ff8800 on #1e90ff]warm on cool[/]
```

## Capability-aware downsampling

The active console's `Profile.Capabilities.ColorSystem` determines how a
`TAnsiColor` actually emits:

| `TColorSystem` | What's emitted |
| --- | --- |
| `NoColors` | Nothing. SGR escapes are stripped. |
| `Legacy` | 8 colours (SGR 30-37 / 40-47); brights downsampled. |
| `Standard` | 16 colours (adds SGR 90-97 / 100-107). |
| `EightBit` | 256 colours (`38;5;n` / `48;5;n`). |
| `TrueColor` | 24-bit RGB (`38;2;r;g;b` / `48;2;r;g;b`). |

A `TAnsiColor.FromRGB` value renders perfectly under `TrueColor`,
gracefully downsamples to the nearest 256 entry under `EightBit`, and
further to the closest of 16 / 8 colours under `Standard` / `Legacy`. You
get colour where it's supported and clean text where it isn't.

See [Capabilities](./capabilities.md) for how the colour system is detected.

## Helpers

```pascal
// Blend two colours by a 0..1 fade factor — used by the indeterminate
// progress bar pulse.
mid := TAnsiColor.Red.Blend(TAnsiColor.Yellow, 0.5);

// Compare two colours for equality
if c1.Equals(c2) then ...

// Render to debug-friendly string
s := c.ToString;     // e.g. 'rgb(255,136,0)' or '#ff8800'
```

## See also

- [Markup syntax](./markup-syntax.md) — using colours inside markup tags.
- [Styles](./styles.md) — combining colours with decorations into a `TAnsiStyle`.
- [Capabilities](./capabilities.md) — colour-system detection.
- [Canvas](../widgets/canvas.md) — for pixel-level RGB rendering.
