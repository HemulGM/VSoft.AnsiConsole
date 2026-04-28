---
title: FigletText
description: Large ASCII-art text using the FIGlet font format.
---

# FigletText

`IFigletText` renders a string in oversized ASCII-art letters - the classic
FIGlet effect, suitable for splash screens, banners, and big "DONE!"
moments.

## When to use

- Boot banners and CLI splash screens.
- Section headers in interactive tools.
- Anywhere a regular [Markup](./markup.md) line is too understated.

## Basic usage

```pascal
AnsiConsole.Write(
  Widgets.FigletText('Hello Delphi')
    .WithColor(TAnsiColor.Aqua)
    .WithAlignment(TAlignment.Left));
```

That renders something like:

```
 _   _      _ _         ____       _       _     _
| | | | ___| | | ___   |  _ \  ___| |_ __ | |__ (_)
| |_| |/ _ \ | |/ _ \  | | | |/ _ \ | '_ \| '_ \| |
|  _  |  __/ | | (_) | | |_| |  __/ | |_) | | | | |
|_| |_|\___|_|_|\___/  |____/ \___|_| .__/|_| |_|_|
                                    |_|
```

## Configuration

| Method | Purpose |
| --- | --- |
| `WithColor(color)` | Foreground colour for the rendered glyphs. |
| `WithAlignment(value)` | Horizontal alignment within the available width. |
| `WithFont(font)` | Use a different FIGlet font (a `TFigletFont` value). |

The default font is "Standard" (the classic FIGlet face). The library ships
the Standard font built-in; loading custom `.flf` fonts is possible via the
`TFigletFont` API.

## API reference

- [`Widgets.FigletText(text)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — default font.
- [`Widgets.FigletText(font, text)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — custom font.
- [`IFigletText`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.Figlet.pas) — interface.
- Demo: [`demos/snippets/Figlet`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/Figlet).

## See also

- [Markup](./markup.md) — for normal-sized styled text.
- [Colours reference](../reference/colors.md).
