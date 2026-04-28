---
title: TextPath
description: Renders a file system path with each segment styled separately and ellipsis when over-long.
---

# TextPath

`ITextPath` renders a file path with one style per segment - separator,
folder, root, leaf - and shrinks intelligently when the available width
won't fit the full path.

## When to use

- Showing the current file in a build/watch tool.
- Path display inside a tight panel where overflow is likely.
- Any place where a regular string would just truncate ugly.

## Basic usage

```pascal
AnsiConsole.Write(
  Widgets.TextPath('C:\Users\vincent\Github\VSoftTechnologies\VSoft.AnsiConsole\source\Widgets\VSoft.AnsiConsole.Widgets.Figlet.pas'));
```

When the available width is less than the path, it ellipsises the middle
segments while keeping the leaf and root visible:

```
C:\…\Widgets\VSoft.AnsiConsole.Widgets.Figlet.pas
```

## Configuration

| Method | Purpose |
| --- | --- |
| `WithRootStyle(value)` | Style for the drive / root segment (`C:` / `\\server\share\` / `/`). |
| `WithSeparatorStyle(value)` | Style for the separator chars (`\` / `/`). |
| `WithStemStyle(value)` | Style for the directory portion of each segment. |
| `WithLeafStyle(value)` | Style for the final filename segment. |
| `WithAlignment(value)` | Alignment within the available width. |

```pascal
AnsiConsole.Write(
  Widgets.TextPath(p)
    .WithSeparatorStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Grey))
    .WithLeafStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua).WithDecorations([TAnsiDecoration.Bold])));
```

## API reference

- [`Widgets.TextPath(path)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`ITextPath`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.TextPath.pas) — interface.

## See also

- [Markup](./markup.md) — when you want manual style control over arbitrary text.
- [Styles reference](../reference/styles.md).
