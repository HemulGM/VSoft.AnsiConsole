---
title: Text prompt
description: Free-form string input with default values, validators, secret masking, and typed parsing.
---

# Text prompt

`ITextPrompt` collects a string from the user, with optional default value,
validator, masking (passwords), and choices (autocomplete). For typed input
(`Integer`, `TDateTime`, `Boolean`, enums...) use `ITextPrompt<T>` via
`AnsiConsole.Ask<T>`.

## When to use

- Any place you'd reach for `Readln` but want validation, defaults, or
  styled output.
- Password / secret entry (with `WithSecret`).
- Quick `Ask` and `Confirm` shortcuts for common cases.

## Basic usage

The shortest form is `AnsiConsole.Ask`:

```pascal
var
  name : string;
begin
  name := AnsiConsole.Ask('[bold]Name[/]', 'World');
  AnsiConsole.MarkupLine('Hello, [green]%s[/]!', [name]);
end;
```

`Ask(prompt, default)` creates a one-shot text prompt with the supplied
default and returns the user's answer. The prompt string is markup.

Typed Ask:

```pascal
var
  port : Integer;
begin
  port := AnsiConsole.Ask<Integer>('Port', 8080);
end;
```

## Using a configurable prompt

For more control, build an `ITextPrompt` and call `.Show(AnsiConsole.Console)`
or pass it to `AnsiConsole.Prompt`:

```pascal
var
  prompt : ITextPrompt;
  email  : string;
begin
  prompt := AnsiConsole.TextPrompt
              .WithTitle('[yellow]Email[/]')
              .WithDefault('me@example.com')
              .WithValidator(
                function(const value : string) : TPromptValidationResult
                begin
                  if Pos('@', value) > 0 then
                    result := TPromptValidationResult.Valid
                  else
                    result := TPromptValidationResult.Invalid('Must contain @');
                end);

  email := AnsiConsole.Prompt(prompt);
end;
```

## Configuration

| Method | Purpose |
| --- | --- |
| `WithTitle(value)` | Markup title shown above the input. |
| `WithDefault(value)` | Default returned when the user presses Enter on empty input. |
| `WithValidator(fn)` | Validation function returning `TPromptValidationResult.Valid` or `Invalid(message)`. |
| `WithSecret(value)` | Mask input with `*` (default mask). |
| `WithMask(char)` | Custom mask character. |
| `WithChoices(values)` | Restrict input to a fixed list (rejects other values). |
| `WithChoiceCaseSensitive(value)` | Case sensitivity for the choice match. |
| `WithShowDefaultValue(value)` | Hide the default annotation on the prompt line. |
| `WithAllowEmpty(value)` | Allow empty input even with no default. |

## Cancel handling

Cancelling (Esc / Ctrl-C) raises `EPromptCancelled`. Wrap in `try / except`
when you need to clean up:

```pascal
try
  name := AnsiConsole.Ask('Name');
except
  on EPromptCancelled do
    AnsiConsole.MarkupLine('[yellow]Cancelled.[/]');
end;
```

## Typed prompts

`AnsiConsole.Ask<T>` supports any type the built-in RTTI parser handles
(`Integer`, `Int64`, `Double`, `TDateTime`, `Boolean`, enum, `string`).
For custom types, build an `ITextPrompt<T>` directly:

```pascal
prompt := TextPrompt<TGuid>.Create
            .WithParser(function(const s : string; out v : TGuid) : Boolean
                        begin
                          // ... parse and set v
                        end);
```

## API reference

- [`AnsiConsole.Ask`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) / `Ask<T>` — convenience.
- [`AnsiConsole.TextPrompt`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — builder.
- [`AnsiConsole.Prompt(prompt)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — show a configured prompt.
- [`ITextPrompt`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Prompts/VSoft.AnsiConsole.Prompts.Text.pas)
- Demo: [`demos/snippets/Prompts`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/Prompts).

## See also

- [Confirmation prompt](./confirmation-prompt.md) — yes/no shortcut.
- [Selection prompt](./selection-prompt.md) — pick one from a list.
