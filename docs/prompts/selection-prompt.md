---
title: Selection prompt
description: Single-pick list with arrow-key navigation, search-as-you-type, and rich choice rendering.
---

# Selection prompt

`ISelectionPrompt<T>` presents a list of choices and returns the one the
user picks. Navigate with arrow keys, hit Enter to confirm, type to filter,
Esc to cancel. Each choice carries a value of type `T`.

## When to use

- Picking one option from a fixed list - region, theme, environment.
- Anywhere `Confirm` is too coarse and a free-form `Ask` is too open.

For multiple picks, use [Multi-selection](./multi-selection-prompt.md). For
nested choices, use [Hierarchical selection](./hierarchical-selection.md).

## Basic usage

```pascal
var
  picker : ISelectionPrompt<string>;
  region : string;
begin
  picker := AnsiConsole.SelectionPrompt<string>
              .WithTitle('[yellow]Pick a region[/]');
  picker.AddChoice('us-east-1');
  picker.AddChoice('eu-west-1');
  picker.AddChoice('ap-southeast-2');
  picker.AddChoice('sa-east-1');

  region := picker.Show(AnsiConsole.Console);
  AnsiConsole.MarkupLine('You picked: [lime]%s[/]', [region]);
end;
```

## Choices with separate values and display labels

Pick the value type and supply a display string per choice:

```pascal
type
  TRegion = (Useast1, Euwest1, Apsoutheast2, Saeast1);

var
  picker : ISelectionPrompt<TRegion>;
  region : TRegion;
begin
  picker := AnsiConsole.SelectionPrompt<TRegion>
              .WithTitle('Pick a region')
              .WithSearchEnabled(True);
  picker.AddChoice(TRegion.Useast1,      'US East (N. Virginia)');
  picker.AddChoice(TRegion.Euwest1,      'EU (Ireland)');
  picker.AddChoice(TRegion.Apsoutheast2, 'Asia Pacific (Sydney)');
  picker.AddChoice(TRegion.Saeast1,      'South America (São Paulo)');

  region := picker.Show(AnsiConsole.Console);
end;
```

The display label is rendered as markup; the underlying value is what gets
returned.

## Configuration

| Method | Purpose |
| --- | --- |
| `WithTitle(value)` | Markup title shown above the list. |
| `WithSearchEnabled(value)` | Type-to-filter; matched substrings are highlighted. |
| `WithSearchHighlightStyle(value)` | Style for matched substrings. |
| `WithPageSize(value)` | Visible choices at a time; the list scrolls. Default 10. |
| `WithCycle(value)` | Wrap navigation when the user presses Up at the top / Down at the bottom. |
| `WithMoreChoicesText(value)` | Custom hint text when more choices are below the visible area. |

```pascal
picker
  .WithTitle('Pick one')
  .WithPageSize(8)
  .WithSearchEnabled(True)
  .WithCycle(True);
```

## Adding choices

Several patterns:

```pascal
picker.AddChoice(value);                          // value as label
picker.AddChoice(value, displayMarkup);           // separate label
picker.AddChoiceGroup('Group label', [a, b, c]);  // labelled group
```

For nested choices, use `AddChoiceHierarchy` -
see [Hierarchical selection](./hierarchical-selection.md).

## Cancel handling

Esc raises `EPromptCancelled`.

## API reference

- [`AnsiConsole.SelectionPrompt<T>`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — builder.
- [`AnsiConsole.Prompt<T>(selectionPrompt)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — show a configured prompt.
- [`ISelectionPrompt<T>`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Prompts/VSoft.AnsiConsole.Prompts.Select.pas)
- Demo: [`demos/snippets/Prompts`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/Prompts).

## See also

- [Multi-selection](./multi-selection-prompt.md).
- [Hierarchical selection](./hierarchical-selection.md).
- [Confirmation prompt](./confirmation-prompt.md).
