---
title: ExceptionWidget
description: Renders a Delphi Exception with class name, message, and tokenized stack trace.
---

# ExceptionWidget

`IExceptionWidget` pretty-prints an `Exception`. Class name, message,
and stack frames each get their own style; the trace tokeniser splits each
frame into method / parameter type / parameter name / parenthesis / path /
line-number tokens you can style independently.

## When to use

- Crash reporting in long-running CLIs.
- Better-than-default error rendering inside `try / except`.
- Capturing styled stack traces for [Recorder](../recording/recorder.md)
  HTML export.

## Basic usage

```pascal
try
  raise EInOutError.Create('disk full');
except
  on E : Exception do
    AnsiConsole.Write(
      Widgets.ExceptionWidget(E)
        .WithStackTrace(
          'MyApp.Storage.Save in C:\src\MyApp\Storage.pas:142' + sLineBreak +
          'MyApp.Worker.Run  in C:\src\MyApp\Worker.pas:56'    + sLineBreak +
          'MyApp.Main')
        .WithFormats([TExceptionFormat.ShortenPaths,
                      TExceptionFormat.ShortenMethods]));
end;
```

The trace string follows the convention `<method> in <path>:<lineno>` per
line. Delphi's `Exception` class doesn't carry a structured trace, so the
caller supplies it - typically from madExcept, JclDebug, EurekaLog, or a
hand-rolled walker.

## Configuration

| Method | Purpose |
| --- | --- |
| `WithStackTrace(value)` | Multi-line trace string. |
| `WithFormats(values)` | Set of `TExceptionFormat` flags. |
| `WithStyle(value : IExceptionStyle)` | Per-token style sheet. |
| `WithClassNameStyle(value)` / `WithMessageStyle(value)` / `WithFrameStyle(value)` | Backwards-compatible per-section setters. |

`TExceptionFormat` flags:

| Flag | Effect |
| --- | --- |
| `ShortenPaths` | `ExtractFileName(path)` on emit. |
| `ShortenTypes` | `'A.B.Type.Method'` -> `'Type.Method'`. |
| `ShortenMethods` | `'A.B.Type.Method'` -> `'Method'`. |
| `ShowLinks` | Wrap path tokens in OSC 8 file:// links. |
| `NoStackTrace` | Skip the trace block entirely. |

## Per-token style sheet

Build a richer style via [`Widgets.ExceptionStyle`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas):

```pascal
AnsiConsole.Write(
  Widgets.ExceptionWidget(E)
    .WithStyle(
      Widgets.ExceptionStyle
        .WithMethod(TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua))
        .WithPath(TAnsiStyle.Plain.WithForeground(TAnsiColor.Grey))
        .WithLineNumber(TAnsiStyle.Plain.WithForeground(TAnsiColor.Yellow))));
```

The full set of styleable tokens: Message, ExceptionType, Method,
ParameterType, ParameterName, Parenthesis, Path, LineNumber, Dimmed,
NonEmphasized.

## Without an Exception instance

For tests / post-mortem dumps where you have raw strings:

```pascal
AnsiConsole.Write(
  Widgets.ExceptionWidget('EInOutError', 'disk full')
    .WithStackTrace(traceText));
```

## Convenience: `AnsiConsole.WriteException`

```pascal
on E : Exception do
  AnsiConsole.WriteException(E);
```

Equivalent to writing a default-styled `ExceptionWidget(E)` directly.

## API reference

- [`Widgets.ExceptionWidget(e)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`Widgets.ExceptionWidget(className, message)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`Widgets.ExceptionStyle`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`AnsiConsole.WriteException`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`IExceptionWidget`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.Exception.pas) — interface.
- Demo: [`demos/snippets/ExceptionDemo`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/ExceptionDemo).

## See also

- [Recorder](../recording/recorder.md) — capture an exception widget render and export as HTML.
- [Styles reference](../reference/styles.md).
