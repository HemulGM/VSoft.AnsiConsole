---
title: Multi-selection prompt
description: Checkbox-style picker — toggle multiple choices and Enter to confirm.
---

# Multi-selection prompt

`IMultiSelectionPrompt<T>` is the checkbox cousin of
[`SelectionPrompt`](./selection-prompt.md). Space toggles a choice;
Enter confirms; the prompt returns a `TArray<T>` of selected values.

## When to use

- Feature toggles - "which tests to run", "which packages to install".
- Multi-select filters - "include these regions".

## Basic usage

```pascal
var
  picker  : IMultiSelectionPrompt<string>;
  picked  : TArray<string>;
  i       : Integer;
begin
  picker := AnsiConsole.MultiSelectionPrompt<string>
              .WithTitle('[bold]Pick one or more[/]')
              .WithInstructionsText('[grey](space to toggle, enter to confirm)[/]');
  picker.AddChoice('Markup');
  picker.AddChoice('Tables');
  picker.AddChoice('Trees');
  picker.AddChoice('Progress');

  picked := picker.Show(AnsiConsole.Console);

  for i := 0 to High(picked) do
    AnsiConsole.MarkupLine('  - [green]%s[/]', [picked[i]]);
end;
```

## Configuration

| Method | Purpose |
| --- | --- |
| `WithTitle(value)` | Markup title above the list. |
| `WithInstructionsText(value)` | Hint text under the title (defaults to standard instructions). |
| `WithSearchEnabled(value)` | Type-to-filter. |
| `WithPageSize(value)` | Visible choices at a time. |
| `WithCycle(value)` | Wrap navigation. |
| `WithRequired(value)` | Force at least one selection (default `False`). |
| `WithSelectionMode(value)` | `TSelectionMode.Leaf` (default — only leaves selectable, parents toggle expansion) or `Independent` (every node selectable). |

## Pre-selected choices

Mark choices as pre-selected:

```pascal
choice := picker.AddChoice('Markup');
choice.IsSelected := True;
```

Or use the convenience overload:

```pascal
picker.AddChoice('Markup', True);   // pre-selected
```

## Cancel handling

Esc raises `EPromptCancelled`. Confirming with no selections returns an
empty array (unless `WithRequired(True)`, which loops until at least one
is selected).

## API reference

- [`AnsiConsole.MultiSelectionPrompt<T>`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`AnsiConsole.Prompt<T>(multiSelectionPrompt)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — show a configured prompt.
- [`IMultiSelectionPrompt<T>`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Prompts/VSoft.AnsiConsole.Prompts.MultiSelect.pas)

## See also

- [Selection prompt](./selection-prompt.md) — single-pick variant.
- [Hierarchical selection](./hierarchical-selection.md) — nested-choice variant.
