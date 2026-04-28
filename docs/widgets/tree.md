---
title: Tree
description: Hierarchical data display with branch glyphs (fork / last / continue) and configurable guide kinds.
---

# Tree

`ITree` renders hierarchical data with branch-drawing glyphs. Each node can
have any number of children; branches use fork / last / continue guides.

![Tree screenshot](/images/tree.png)

## When to use

- Project trees, file systems, package dependencies.
- Anywhere you want indented hierarchy with visual connectors.

For interactive picks from a hierarchy, see
[Hierarchical selection](../prompts/hierarchical-selection.md).

## Basic usage

```pascal
var
  t   : ITree;
  src : ITreeNode;
begin
  t := Widgets.Tree('[bold]Project[/]');
  src := t.AddNode('source');
  src.AddNode('VSoft.AnsiConsole.Color.pas');
  src.AddNode('VSoft.AnsiConsole.Style.pas');
  t.AddNode('tests');
  AnsiConsole.Write(t);
end;
```

Renders:

```
Project
├── source
│   ├── VSoft.AnsiConsole.Color.pas
│   └── VSoft.AnsiConsole.Style.pas
└── tests
```

## Building the tree

The root accepts either a markup string or any renderable:

```pascal
t := Widgets.Tree('[bold yellow]src[/]');
t := Widgets.Tree(Widgets.Panel(Widgets.Text('root')));
```

Each `AddNode` call returns the new `ITreeNode`, so you can drill in:

```pascal
core := t.AddNode('Core');
core.AddNode('Color');
core.AddNode('Style');

widgets := t.AddNode('Widgets');
table := widgets.AddNode('Table');
table.AddNode('Borders');
```

## Configuration

| Method | Purpose |
| --- | --- |
| `WithGuide(kind)` | Glyph set — `TTreeGuideKind.Ascii` / `Line` (default) / `Heavy` / `Double` / `Bold`. |
| `WithStyle(value)` | Style applied to the guide glyphs. |
| `WithExpanded(value)` | When `False`, render only the root and immediate children. |

```pascal
AnsiConsole.Write(
  Widgets.Tree('[bold]Project[/]')
    .WithGuide(TTreeGuideKind.Heavy)
    .WithStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua)));
```

## Composition

Markup tags inside node labels:

```pascal
t.AddNode('[red]TODO: cross-platform[/]');
t.AddNode('[green]build ok[/]');
t.AddNode('[yellow]tests pending[/]');
```

Nodes can hold any renderable:

```pascal
node := t.AddNode(Widgets.Panel(Widgets.Markup('inline panel')));
```

## API reference

- [`Widgets.Tree(root : IRenderable)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`Widgets.Tree(rootMarkup : string)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`ITree`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.Tree.pas) — interface.
- Demo: [`demos/snippets/Tree`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/Tree).

## See also

- [Tree guides reference](../reference/tree-guides.md) — every `TTreeGuideKind` glyph.
- [Hierarchical selection](../prompts/hierarchical-selection.md) — interactive tree picker.
- [Panel](./panel.md) — wrapping a tree in a bordered region.
