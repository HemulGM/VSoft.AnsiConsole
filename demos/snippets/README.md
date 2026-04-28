# Snippet demos

One self-contained Delphi project per code snippet in the [main README](../../README.md#showcase).

| Folder            | Snippet                                        |
|-------------------|-----------------------------------------------|
| `QuickStart`      | The Hello-world quick-start snippet           |
| `Markup`          | Markup & colour                               |
| `Table`           | Tables                                        |
| `Tree`            | Trees                                         |
| `PanelRule`       | Panels & rules                                |
| `Progress`        | Multi-task progress bars                      |
| `Status`          | Status spinner                                |
| `Prompts`         | Text + Confirm + Selection prompts            |
| `Hierarchy`       | Hierarchical (multi-level) selection          |
| `Calendar`        | Calendar widget                               |
| `BarChart`        | Bar chart                                     |
| `Breakdown`       | Breakdown chart                               |
| `Canvas`          | Canvas pixel widget                           |
| `Figlet`          | FIGlet text                                   |
| `Json`            | Pretty-printed JSON                           |
| `ExceptionDemo`   | Exception widget                              |
| `Recorder`        | Recorder + HTML export                        |

## How they're wired up

Each demo is intentionally minimal:

- The `.dpr` only `uses VSoft.AnsiConsole` (and a couple of widget units when
  the snippet needs an interface type or enum). **No** `unit in '...path...'`
  clauses pull source files directly into the program — those would be
  duplicated 17 times.
- The `.dproj` does **not** add `DCCReference` entries for the library
  source. Instead, `DCC_UnitSearchPath` is set to all the `..\..\..\source\*`
  sub-folders, so the compiler discovers the units the same way it would for
  any DPM-installed package.
- `VSoft.System.Console` (the only runtime dependency) is resolved from the
  DPM cache via `$(DPMSearch)` in the same path. Run
  `dpm install VSoft.System.Console` once for the project to pick it up,
  or restore via the IDE's DPM panel.

## Running

```
cd demos\snippets\QuickStart
msbuild QuickStart.dproj /p:Config=Debug /p:Platform=Win64
.\Win64\Debug\QuickStart.exe
```

Or just open the `.dproj` in the Delphi IDE and press F9.
