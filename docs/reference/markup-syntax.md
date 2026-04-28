---
title: Markup syntax reference
description: Full grammar of the BBCode-style markup language.
---

# Markup syntax reference

Markup is the BBCode-style mini-language used by `AnsiConsole.Markup`,
`AnsiConsole.MarkupLine`, `Widgets.Markup`, and any widget that accepts a
markup string (panel headers, table cells, tree node labels, etc.).

## Basic syntax

```
[<style>]<text>[/]
```

`<style>` is a space-separated list of style tokens. `<text>` is the styled
content. The closing `[/]` reverts to the surrounding style. Tags **nest**;
the closing `[/]` always closes the most recent open tag.

```
[red]hello[/]                              red
[red bold]hello[/]                         red and bold
[red on yellow]hello[/]                    red on yellow background
[bold]b[red]r[/]b[/]                       'b' bold, 'r' bold-red, last 'b' bold
```

## Style tokens

| Token | Effect |
| --- | --- |
| `red`, `blue`, `green`, ... | Named foreground colour. See [colours reference](./colors.md). |
| `on yellow` | Background colour. |
| `#ff8800` | Hex foreground colour. |
| `#ff8800 on #1e90ff` | Hex foreground + background. |
| `bold`, `italic`, `underline`, `strikethrough`, `dim`, `invert`, `conceal`, `slowblink`, `rapidblink` | Decorations. |

Mix freely:

```
[bold red on #ffe4b5]important[/]
[#ff8800 italic]warm[/]
```

## Hyperlinks

`[link=URL]text[/]` emits an OSC 8 hyperlink. Modern terminals (Windows
Terminal, iTerm2, GNOME Terminal, ConEmu) make the wrapped text clickable.

```
Visit [link=https://example.com]our site[/].
```

If the URL itself is the visible text, omit the value:

```
[link]https://example.com[/]
```

## Emoji shortcodes

`:name:` substitutes a unicode emoji glyph at parse time:

```
:rocket:     -> 🚀
:check_mark_button:  -> ✅
:warning:    -> ⚠️
```

See [emoji reference](./emoji.md) for the list.

## Escapes

Use `[[` for a literal `[`, and `]]` for a literal `]`:

```
[[escaped]]    -> [escaped]
```

Inside a tag body, an unescaped `]` is a parse error.

For arbitrary text that might contain `[`, use `AnsiConsole.EscapeMarkup`:

```pascal
AnsiConsole.MarkupLine('Got input: [yellow]%s[/]',
                        [AnsiConsole.EscapeMarkup(userInput)]);
```

## Errors

The parser raises `EMarkupParseError` (defined in
[`VSoft.AnsiConsole.Markup.Tokenizer`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Markup/VSoft.AnsiConsole.Markup.Tokenizer.pas))
on:

- Unterminated tag (missing `]`).
- Unescaped `]` inside a tag body.
- Stack underflow (closing `[/]` with no matching open tag).

## See also

- [Markup widget](../widgets/markup.md) — the renderable form.
- [Colours](./colors.md) — named colour list.
- [Styles](./styles.md) — when to use `TAnsiStyle` vs markup.
- [Emoji](./emoji.md) — full shortcode catalogue.
