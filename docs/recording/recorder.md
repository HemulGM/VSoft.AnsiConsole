---
title: Recorder
description: Capture rendered output and replay it as plain text or styled HTML.
---

# Recorder

`IRecorder` wraps an `IAnsiConsole` and captures every rendered segment.
Capture once, then export as **plain text** (escape codes stripped),
**styled HTML** (CSS-coloured spans), or via a custom `IAnsiConsoleEncoder`.

## When to use

- Generating shareable demos / bug reports of console output.
- Golden-file tests for rich rendering (capture once, diff later).
- Producing browser-friendly HTML snapshots of CLI sessions.

## Basic usage

```pascal
uses
  System.IOUtils,
  VSoft.AnsiConsole;

var
  rec      : IRecorder;
  htmlPath : string;
begin
  rec := AnsiConsole.Recorder;
  rec.Write(Widgets.Markup('[bold]Captured[/] [yellow]demo[/]'));
  rec.WriteLine;
  rec.Write(Widgets.Panel(Widgets.Text('hi')).WithHeader('panel'));

  // Replay as plain text on the real console:
  AnsiConsole.WriteLine;
  AnsiConsole.MarkupLine('[bold]ExportText:[/]');
  AnsiConsole.WriteLine;
  AnsiConsole.Write(rec.ExportText);

  // Save the same capture as standalone HTML:
  htmlPath := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP'))
              + 'Recorder-demo.html';
  TFile.WriteAllText(htmlPath, rec.ExportHtml);
end;
```

`AnsiConsole.Recorder` (no arg) wraps the singleton; pass a captured console
for tests:

```pascal
rec := AnsiConsole.Recorder(myCapturedConsole);
```

## Static recording shortcuts

For convenience, `AnsiConsole` exposes a Spectre-style start/export/stop
flow that wraps the singleton:

```pascal
AnsiConsole.StartRecording;
try
  AnsiConsole.MarkupLine('[bold]Hi[/]');
  AnsiConsole.Write(Widgets.Panel('body').WithHeader('A panel'));
finally
  // The recorder is still active here; export as needed:
  TFile.WriteAllText('demo.html', AnsiConsole.ExportHtml);
  AnsiConsole.StopRecording;
end;
```

While recording, *every* `AnsiConsole.X` write is captured. `StopRecording`
restores the prior console.

::: tip
Spectre's facade method is `Record()` but `record` is reserved in Delphi -
hence the `StartRecording` / `StopRecording` pair.
:::

## Export formats

| Method | Format |
| --- | --- |
| `ExportText` | Plain text (escape codes stripped). |
| `ExportHtml` | Standalone HTML with CSS-coloured spans, ready to drop into a browser or a bug report. |
| `Export(encoder)` | Custom encoder implementing `IAnsiConsoleEncoder`. |

## Custom encoders

Implement `IAnsiConsoleEncoder` to convert the captured segment stream into
your own format - SVG, markdown with HTML spans, terminal-replayable
ANSI, etc.:

```pascal
type
  TMyEncoder = class(TInterfacedObject, IAnsiConsoleEncoder)
  public
    function Encode(const segments : TAnsiSegments) : string;
  end;
```

Then:

```pascal
output := rec.Export(TMyEncoder.Create);
```

## API reference

- [`AnsiConsole.Recorder`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — wrap a console.
- [`AnsiConsole.StartRecording`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) / [`StopRecording`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) — facade shortcuts.
- [`AnsiConsole.ExportText`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) / [`ExportHtml`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas) / [`ExportCustom`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`IRecorder`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Console/VSoft.AnsiConsole.Recorder.pas) — interface.
- [`IAnsiConsoleEncoder`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Console/VSoft.AnsiConsole.Recorder.pas) — encoder interface.
- Demo: [`demos/snippets/Recorder`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/Recorder).

## See also

- [Architecture](../getting-started/architecture.md) — segment pipeline.
- [Capabilities](../reference/capabilities.md) — colour-system handling for HTML export.
