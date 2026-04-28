---
title: Confirmation prompt
description: Yes/no question with a default answer.
---

# Confirmation prompt

`IConfirmationPrompt` asks a yes/no question. Press `y` for yes, `n` for no,
Enter for the default. Returns a `Boolean`.

## When to use

- "Continue?" / "Are you sure?" / "Overwrite?" gates.
- Anywhere a one-shot `Boolean` decision is needed.

## Basic usage

The shortest form:

```pascal
if AnsiConsole.Confirm('Proceed?', True) then
  RunBuild
else
  AnsiConsole.MarkupLine('[yellow]Aborted.[/]');
```

`Confirm(prompt, default)` returns `True` for yes, `False` for no.

## Configurable form

For more control, build an `IConfirmationPrompt`:

```pascal
var
  prompt : IConfirmationPrompt;
begin
  prompt := AnsiConsole.ConfirmationPrompt
              .WithTitle('[bold red]Delete files?[/]')
              .WithDefault(False)
              .WithYesText('delete')
              .WithNoText('cancel');

  if AnsiConsole.Prompt(prompt) then
    DoDelete;
end;
```

## Configuration

| Method | Purpose |
| --- | --- |
| `WithTitle(value)` | Markup title shown above the input. |
| `WithDefault(value)` | Returned when the user presses Enter. |
| `WithYesText(value)` / `WithNoText(value)` | Override the default `y` / `n` labels. |
| `WithShowDefaultValue(value)` | Hide the default-value annotation. |

## Cancel handling

Same as text prompts: Esc / Ctrl-C raises `EPromptCancelled`.

## API reference

- [`AnsiConsole.Confirm`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — convenience.
- [`AnsiConsole.ConfirmationPrompt`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — builder.
- [`AnsiConsole.Prompt(confirmationPrompt)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — show a configured prompt.
- [`IConfirmationPrompt`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Prompts/VSoft.AnsiConsole.Prompts.Confirm.pas)

## See also

- [Text prompt](./text-prompt.md) — for arbitrary string answers.
- [Selection prompt](./selection-prompt.md) — for fixed-choice pickers.
