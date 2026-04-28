---
title: Installation
description: Install VSoft.AnsiConsole via DPM or by adding the source folder to your project's unit search path.
---

# Installation

VSoft.AnsiConsole targets **Delphi XE3 and later** on **Windows**. Linux and
macOS support is structured for but not yet shipped.

## Dependencies

| Package | Version | Purpose |
| --- | --- | --- |
| [`VSoft.System.Console`](https://github.com/VSoftTechnologies/VSoft.System.Console) | 1.1.4+ | Low-level primitives: keyboard input (`TConsoleKey`/`TConsoleKeyInfo`), terminal dimensions, raw write helpers. |
| [`VSoft.DUnitX`](https://github.com/VSoftTechnologies/DUnitX) | 0.4.5+ | _Test-only_. Required for running the 500+ unit tests in `tests/`, not for consumers. |


## Manual

1. Clone the repo:

   ```sh
   git clone https://github.com/VSoftTechnologies/VSoft.AnsiConsole.git
   ```

2. Add `source/` (and its subfolders) to your project's **unit search path**.
3. Add the [`VSoft.System.Console`](https://github.com/VSoftTechnologies/VSoft.System.Console) DCP to your project's package references.

## Project setup

In your `.dpr` (or any unit), add a single `uses` line:

```pascal
uses
  VSoft.AnsiConsole;
```

That brings in the [`AnsiConsole`](../widgets/markup.md) static facade, the
[`Widgets`](../widgets/markup.md) factory record, every public interface
alias (`IRenderable`, `IPanel`, `ITable`, `IProgress`, `ITree`, etc.), and
the value-typed records `TAnsiColor` and `TAnsiStyle`.

::: tip
You don't need to import the individual widget units (`VSoft.AnsiConsole.Widgets.Panel`,
etc.). The facade unit re-exports everything you need, and using it directly
avoids the local-variable shadowing trap that the bare unit-level factory
functions can cause.
:::

## Runtime package

A pre-built runtime package ships at
`packages/RAD Studio 12.0/VSoft.AnsiConsoleR.dproj`. If you want to consume
the library as a `.dcp` instead of compiling sources into your application,
build that package and reference it.

## Verify

Save the following as `Hello.dpr` and run it:

```pascal
program Hello;

{$APPTYPE CONSOLE}

uses
  VSoft.AnsiConsole;

begin
  AnsiConsole.MarkupLine('[bold yellow]Hello[/] [italic]world[/]!');
end.
```

If the output appears in colour, you're ready. Move on to
[Quick start](./quick-start.md).
