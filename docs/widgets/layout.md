---
title: Layout
description: Recursive row/column splitter with named regions, sizes, and ratios — a TUI-style window manager for console widgets.
---

# Layout

`ILayout` is a recursive splitter. Each node is either a leaf (wrapping an
`IRenderable`) or an internal node split by rows or columns. Named regions
let you reach into the tree later and swap content via `Update`.

## When to use

- Dashboards with header / sidebar / main / footer regions.
- Any layout where multiple panels need fixed sizes or ratios.
- Anywhere you'd reach for a TUI window manager.

For simpler horizontal/vertical stacks without sized regions, use
[Columns](./columns.md) / [Rows](./rows.md). For aligned columnar data, use
[Grid](./grid.md).

## Basic usage

```pascal
var
  root, hdr, body, side, main, foot : ILayout;
begin
  root := Widgets.Layout('root');
  hdr  := Widgets.Layout('header').WithSize(3);
  side := Widgets.Layout('side').WithRatio(1);
  main := Widgets.Layout('main').WithRatio(2);
  body := Widgets.Layout('body');
  body.SplitColumns([side, main]);
  foot := Widgets.Layout('footer').WithSize(1);
  root.SplitRows([hdr, body, foot]);

  hdr.Update(Widgets.Markup('[bold yellow]Dashboard[/]'));
  side.Update(Widgets.Markup('sidebar'));
  main.Update(Widgets.Markup('main content'));
  foot.Update(Widgets.Markup('[grey]press q to quit[/]'));

  root.WithHeight(24);
  AnsiConsole.Write(root);
end;
```

## Size strategies

A node can be **fixed**, **ratio'd**, or **default**:

| Method | Effect |
| --- | --- |
| `WithSize(value)` | Exactly `value` cells (in the splitting axis). |
| `WithRatio(value)` | Take `value`/total-ratio of the leftover space. |
| `WithMinimumSize(value)` | Floor on the size — the node won't shrink below this. |
| `WithVisible(value)` | When `False` the region collapses to zero size. |
| `WithHeight(value)` | Used at the **root** to set the overall layout height. |

If a child has neither a fixed size nor a ratio, it's treated as ratio 1.

## Splits

| Method | Effect |
| --- | --- |
| `SplitRows(children)` | Split this node vertically into the given children. |
| `SplitColumns(children)` | Split this node horizontally. |
| `Update(renderable)` | Set the leaf content. Replaces previous content. |
| `FindByName(name) : ILayout` | Locate a descendant by its name string. |

## Updating a region

Once built, you can change a region's content with `Update`:

```pascal
side := root.FindByName('side');
side.Update(Widgets.Panel(newContent));
AnsiConsole.Write(root);
```

This is the typical pattern when combined with [Live display](../live/live-display.md)
to redraw a dashboard in place.

## Configuration recap

```pascal
hdr  := Widgets.Layout('header').WithSize(3).WithMinimumSize(3);
side := Widgets.Layout('side').WithRatio(1).WithMinimumSize(20);
main := Widgets.Layout('main').WithRatio(2);
foot := Widgets.Layout('footer').WithSize(1).WithVisible(showFooter);
```

## API reference

- [`Widgets.Layout()`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — anonymous root.
- [`Widgets.Layout(name)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — named layout node.
- [`ILayout`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.Layout.pas) — interface.

## See also

- [Live display](../live/live-display.md) — refresh a layout in place.
- [Panel](./panel.md) — the typical leaf content for a layout region.
- [Rows](./rows.md) / [Columns](./columns.md) — simpler alternatives.
