---
title: Spinners reference
description: All 90 built-in spinner kinds plus how to build a custom one from frame strings.
---

# Spinners reference

`TSpinnerKind` enumerates 90 built-in spinner styles, ported from
Spectre.Console's set (which itself ports
[`cli-spinners`](https://github.com/sindresorhus/cli-spinners)). Use them
with [Status](../live/status.md), as columns in
[Progress](../live/progress.md) via
[`Widgets.SpinnerColumn`](../widgets/markup.md), or directly with
`Widgets.Spinner`.

## Available kinds

90 in total. Common picks:

| Kind | Frames | Notes |
| --- | --- | --- |
| `Default` | depends on terminal | The Spectre default. |
| `Dots` | 10 | `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏` |
| `Dots2` | 10 | Different dot pattern. |
| `Line` | 4 | `- \ \| /` — works in any terminal. |
| `Arc` | 8 | Quarter arcs spinning. |
| `Earth` | 3 | `🌍 🌎 🌏` |
| `Moon` | 8 | Lunar phases. |
| `Hearts` | 6 | `💛 💙 💜 💚 ❤️ 🧡` |
| `BouncingBar` | 16 | Heavy bar bouncing. |
| `Runner` | 1+ | A running figure. |
| `Material` | 38 | Long, smooth Material Design rotation. |
| `Pong` | 14 | Classic Pong-style ball. |
| `Pipe` | 8 | ASCII-safe box drawing. |
| `Clock` | 12 | Clock-face hours. |
| `Hamburger` | 3 | Three rows of bun. |

The full list (90 entries) lives in the `TSpinnerKind` enum at
[`source/Live/VSoft.AnsiConsole.Live.Spinners.pas`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Live/VSoft.AnsiConsole.Live.Spinners.pas).

## Unicode vs ASCII

Many spinners use unicode glyphs. When the active console doesn't support
unicode, the spinner factory falls back to a simple line-style ASCII set
(`-`, `\`, `|`, `/`) so the animation still works. Spinners that already
use ASCII glyphs (`Ascii`, `Line`, `Pipe`, etc.) keep their own frames
regardless of the unicode flag.

```pascal
Widgets.Spinner(TSpinnerKind.Earth)        // unicode default
Widgets.Spinner(TSpinnerKind.Earth, False) // forces ASCII fallback
```

## Custom spinners

Build one from a list of frames + a per-frame interval (ms):

```pascal
custom := Widgets.Spinner(
            TArray<string>.Create('(>    )', '( >   )', '(  >  )',
                                  '(   > )', '(    >)',
                                  '(   < )', '(  <  )', '( <   )', '(<    )'),
            100);

AnsiConsole.Status
  .WithSpinner(custom)
  .Start('working...', proc);
```

The frame list cycles with wrap-around; intervals shorter than the terminal
refresh rate are clamped.

## Random spinner

For variety in a long-running CLI, pick a random built-in:

```pascal
spinner := AnsiConsole.RandomSpinner;
```

## API reference

- [`TSpinnerKind`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Live/VSoft.AnsiConsole.Live.Spinners.pas) — the full enum.
- [`Widgets.Spinner(kind)`](../widgets/markup.md) — build an `ISpinner`.
- [`Widgets.Spinner(kind, unicode)`](../widgets/markup.md) — explicit unicode handling.
- [`Widgets.Spinner(frames, intervalMs)`](../widgets/markup.md) — custom.
- [`AnsiConsole.RandomSpinner`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — random pick.
- [`ISpinner`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Live/VSoft.AnsiConsole.Live.Spinners.pas) — interface.

## See also

- [Status](../live/status.md) — primary consumer.
- [Progress](../live/progress.md) — `SpinnerColumn` uses these too.
