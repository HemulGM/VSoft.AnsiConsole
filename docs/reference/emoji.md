---
title: Emoji reference
description: 1500+ emoji shortcodes you can drop into any markup string.
---

# Emoji reference

VSoft.AnsiConsole ships with the full standard emoji shortcode list - the
same `:name:` set you've seen on GitHub, Slack, Discord, and Spectre.Console.
1500+ entries.

## Usage

Anywhere markup is parsed, `:name:` substitutes the corresponding unicode
glyph:

```pascal
AnsiConsole.MarkupLine('Building :rocket:');
AnsiConsole.MarkupLine('All tests passed :check_mark_button:');
AnsiConsole.MarkupLine('[red]Failed[/] :x:');
```

That's `MarkupLine`, `Markup`, `Widgets.Markup`, panel headers, table
cells, tree node labels - any consumer of markup-formatted text.

## Direct lookup

Resolve a shortcode to its glyph in code without going through markup:

```pascal
glyph := AnsiConsole.Emoji('rocket');     // returns '🚀'
glyph := AnsiConsole.Emoji(':rocket:');   // colons are accepted too
```

Returns the empty string when the shortcode is unknown.

## In-place replacement

For arbitrary text that may contain shortcodes:

```pascal
out := TEmoji.Replace(input);
```

`TEmoji` lives in [`source/Core/VSoft.AnsiConsole.Emoji.pas`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Core/VSoft.AnsiConsole.Emoji.pas).

## Common shortcodes

| Shortcode | Glyph | Use case |
| --- | --- | --- |
| `:rocket:` | 🚀 | Launch / deploy |
| `:check_mark_button:` | ✅ | Success |
| `:x:` | ❌ | Failure |
| `:warning:` | ⚠️ | Warning |
| `:bulb:` | 💡 | Tip / idea |
| `:fire:` | 🔥 | Hot / on-fire metric |
| `:robot:` | 🤖 | Bot / automation |
| `:wrench:` | 🔧 | Build / config |
| `:hourglass:` | ⏳ | Slow / pending |
| `:tada:` | 🎉 | Celebration |
| `:zap:` | ⚡ | Fast / electric |
| `:sparkles:` | ✨ | New feature |
| `:bug:` | 🐛 | Bug |
| `:lock:` | 🔒 | Security |
| `:globe_with_meridians:` | 🌐 | Network / global |

The full list (1500+ entries, generated from the Unicode CLDR
short-names) lives at
[`source/Core/VSoft.AnsiConsole.Emoji.pas`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Core/VSoft.AnsiConsole.Emoji.pas).

## Terminal support

Modern terminals (Windows Terminal, iTerm2, GNOME Terminal, ConEmu) display
emoji glyphs natively. Older terminals may show tofu (□) for some glyphs.
The library doesn't try to detect emoji support - your terminal's font
ultimately decides.

## See also

- [Markup syntax](./markup-syntax.md) — embedding shortcodes inside tags.
- [Quick start](../getting-started/quick-start.md).
