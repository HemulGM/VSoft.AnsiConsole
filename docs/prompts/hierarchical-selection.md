---
title: Hierarchical selection
description: Pick from a tree of choices — parents expand on Enter, leaves select.
---

# Hierarchical selection

Both [`SelectionPrompt<T>`](./selection-prompt.md) and
[`MultiSelectionPrompt<T>`](./multi-selection-prompt.md) support **nested**
choices via `AddChoiceHierarchy`. Parents toggle expansion when activated;
leaves are the only thing the user can pick (by default).

![Hierarchy screenshot](/images/hierarchy.png)

## When to use

- Region pickers (continent → country).
- Module pickers (group → module).
- Anywhere a flat list would be too long but the structure is naturally
  hierarchical.

## Basic usage

```pascal
var
  picker            : ISelectionPrompt<string>;
  americas, asia,
  oceania           : ISelectionItem<string>;
  region            : string;
begin
  picker := AnsiConsole.SelectionPrompt<string>
              .WithTitle('[yellow]Pick a region[/] [grey50](Enter to expand)[/]');

  oceania := picker.AddChoiceHierarchy('Oceania', '[bold]Oceania[/]');
  oceania.AddChild('au', 'Australia');
  oceania.AddChild('nz', 'New Zealand');
  oceania.AddChild('fi', 'Fiji');
  oceania.IsExpanded := True;     // pre-open this branch

  americas := picker.AddChoiceHierarchy('Americas', '[bold]Americas[/]');
  americas.AddChild('us', 'United States');
  americas.AddChild('ca', 'Canada');
  americas.AddChild('br', 'Brazil');

  asia := picker.AddChoiceHierarchy('Asia', '[bold]Asia[/]');
  asia.AddChild('cn', 'China');
  asia.AddChild('jp', 'Japan');
  asia.AddChild('kr', 'South Korea');

  region := picker.Show(AnsiConsole.Console);
  AnsiConsole.MarkupLine('You picked: [lime]%s[/]', [region]);
end;
```

## Selection modes

`TSelectionMode` controls whether parents are themselves selectable:

| Mode | Behaviour |
| --- | --- |
| `Leaf` (default) | Only leaves selectable. Enter on a parent toggles expansion. |
| `Independent` | Every node selectable in its own right. Useful when a parent has a meaningful "no specific child" value. |

```pascal
picker.WithSelectionMode(TSelectionMode.Independent);
```

## Multi-selection variant

The same hierarchy API works on `IMultiSelectionPrompt<T>`:

```pascal
picker := AnsiConsole.MultiSelectionPrompt<string>;
features := picker.AddChoiceHierarchy('frontend', 'Front-end');
features.AddChild('vue', 'Vue');
features.AddChild('react', 'React');
```

Use `IMultiSelectionItem<T>` instead of `ISelectionItem<T>` for the parent
type when working with multi-selection (it adds `Select` / `IsSelected`).

## Configuration

Beyond `WithSelectionMode`, the rest of the prompt configuration is
inherited from [`SelectionPrompt<T>`](./selection-prompt.md) /
[`MultiSelectionPrompt<T>`](./multi-selection-prompt.md):
`WithTitle`, `WithSearchEnabled`, `WithPageSize`, `WithCycle`, etc.

## API reference

- [`ISelectionPrompt<T>.AddChoiceHierarchy`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Prompts/VSoft.AnsiConsole.Prompts.Select.pas)
- [`IMultiSelectionPrompt<T>.AddChoiceHierarchy`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Prompts/VSoft.AnsiConsole.Prompts.MultiSelect.pas)
- [`ISelectionItem<T>`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Prompts/VSoft.AnsiConsole.Prompts.Hierarchy.pas)
- [`IMultiSelectionItem<T>`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Prompts/VSoft.AnsiConsole.Prompts.Hierarchy.pas)
- Demo: [`demos/snippets/Hierarchy`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/Hierarchy).

## See also

- [Selection prompt](./selection-prompt.md).
- [Multi-selection prompt](./multi-selection-prompt.md).
