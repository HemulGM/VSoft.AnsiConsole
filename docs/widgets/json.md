---
title: JsonText
description: Pretty-prints and syntax-highlights JSON for terminal display.
---

# JsonText

`IJsonText` renders a JSON string with consistent indentation and
syntax-highlighting for keys, strings, numbers, booleans, and `null`.

## When to use

- API response viewers in CLIs.
- Config dump commands.
- Inspecting structured logs.

## Basic usage

```pascal
var
  jsonText : IJsonText;
begin
  jsonText := Widgets.Json(
    '{"name":"Vincent","skills":["Delphi","Pascal"],"active":true}');
  AnsiConsole.Write(jsonText);
end;
```

Renders (in colour):

```
{
  "name": "Vincent",
  "skills": ["Delphi", "Pascal"],
  "active": true
}
```

with keys in one colour, strings in another, numbers/booleans/null in a
third, etc.

## Configuration

| Method | Purpose |
| --- | --- |
| `WithBracesStyle(value)` | Style for `{`, `}`, `[`, `]`. |
| `WithMemberStyle(value)` | Style for object keys (the strings before `:`). |
| `WithStringStyle(value)` | Style for string values. |
| `WithNumberStyle(value)` | Style for numeric literals. |
| `WithBooleanStyle(value)` | Style for `true` / `false`. |
| `WithNullStyle(value)` | Style for `null`. |
| `WithCommaStyle(value)` | Style for `,`. |

```pascal
AnsiConsole.Write(
  Widgets.Json(payload)
    .WithMemberStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua))
    .WithStringStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Lime)));
```

## Composition

Wrap in a panel for context:

```pascal
AnsiConsole.Write(
  Widgets.Panel(Widgets.Json(payload))
    .WithHeader('Response'));
```

## API reference

- [`Widgets.Json(source)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`IJsonText`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.Json.pas) — interface.
- Demo: [`demos/snippets/Json`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/Json).

## See also

- [Styles reference](../reference/styles.md) — building `TAnsiStyle` values.
