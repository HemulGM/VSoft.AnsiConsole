---
title: Markup
description: BBCode-style inline styling — colours, decorations, hex tags, hyperlinks, emoji shortcodes — for any string you write.
---

# Markup

Markup is a BBCode-style mini-language for embedding styled spans inside
plain strings. `[red bold]hello[/]` styles "hello" red and bold. Tags nest;
escapes use `[[` and `]]`.

## When to use

- For **direct console output**, use the procedural form
  [`AnsiConsole.Markup`](../getting-started/quick-start.md) /
  `AnsiConsole.MarkupLine`.
- For a **renderable widget** (something to embed in a panel, table cell,
  or column), use `Widgets.Markup(source)` which returns an `IMarkup`.

## Basic usage

```pascal
AnsiConsole.MarkupLine('[bold red on yellow]Important[/] message');
AnsiConsole.MarkupLine('Link: [link=https://example.com]click here[/]');
AnsiConsole.MarkupLine('[#ff8800]Custom hex colour[/]');
```

As a widget embedded in another:

```pascal
AnsiConsole.Write(
  Widgets.Panel(Widgets.Markup('[bold]hello[/] world'))
    .WithHeader('Greeting')
    .WithBorder(TBoxBorderKind.Rounded));
```

## Tag grammar

| Form | Effect |
| --- | --- |
| `[red]hi[/]` | Foreground colour |
| `[on yellow]hi[/]` | Background colour |
| `[red on yellow]hi[/]` | Both |
| `[bold italic]hi[/]` | Decorations (bold / italic / underline / strikethrough / dim / invert / conceal / blink) |
| `[#ff8800]hi[/]` | Hex colour |
| `[#ff8800 on #1e90ff]hi[/]` | Hex foreground + background |
| `[link=https://example.com]click[/]` | OSC 8 hyperlink |
| `:rocket:` | Emoji shortcode |
| `[[` `]]` | Literal `[` and `]` |

Tags **nest**: `[bold][red]hi[/][/]` is bold-red. The closing `[/]` always
closes the most recent open tag. Closing the wrong tag raises
`EMarkupParseError`.

See the full [markup syntax reference](../reference/markup-syntax.md) for
edge cases and grammar details.

## Configuration

`Widgets.Markup(...)` returns `IMarkup` with these knobs:

| Method | Purpose |
| --- | --- |
| `WithAlignment(value)` | Justify within container — `TAlignment.Left` / `Center` / `Right`. |
| `WithOverflow(value)` | What to do when the string exceeds available width — `TOverflow.Fold` (wrap), `Crop` (truncate), `Ellipsis` (truncate with `…`). |

```pascal
AnsiConsole.Write(
  Widgets.Markup('[italic]centered[/]').WithAlignment(TAlignment.Center));
```

## Embedding markup in widgets

Many widget factories accept a markup overload directly:

```pascal
// Panel with markup body
panel := Widgets.Panel('[bold]hello[/] world');

// Tree with markup root
tree := Widgets.Tree('[bold yellow]src[/]');

// Table with markup cells (just put the markup string in the row)
table.AddRow(['[red]Alice[/]', '128']);
```

Inside `AnsiConsole.MarkupLine`, the formatted version splices arguments
in *after* parsing, so format args are treated as literal text:

```pascal
AnsiConsole.MarkupLine('User: [green]%s[/]', [userName]);
```

## Escaping

Use `AnsiConsole.EscapeMarkup` to safely embed user-supplied text that
might contain `[` or `]`:

```pascal
AnsiConsole.MarkupLine('Got input: [yellow]%s[/]',
                        [AnsiConsole.EscapeMarkup(userInput)]);
```

This converts `[` to `[[` and `]` to `]]`.

## API reference

- [`AnsiConsole.Markup`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — procedural form, writes immediately.
- [`AnsiConsole.MarkupLine`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — writes + newline.
- [`Widgets.Markup`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — widget form.
- Demo: [`demos/snippets/Markup`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/Markup).

## See also

- [Markup syntax reference](../reference/markup-syntax.md) — full grammar.
- [Colours](../reference/colors.md) — named colours, 256-palette, truecolor.
- [Styles](../reference/styles.md) — when to use `TAnsiStyle` vs markup.
- [Emoji](../reference/emoji.md) — the `:name:` shortcode list.
