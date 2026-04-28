---
title: Capabilities reference
description: How VSoft.AnsiConsole detects terminal capabilities — colour system, unicode support, interactivity, CI environments.
---

# Capabilities reference

When the singleton `IAnsiConsole` initialises, it builds a `IProfile`
describing the terminal's capabilities. Every render decision - colour
downsampling, unicode-vs-ASCII glyph choice, prompt-vs-skip - flows from
this profile.

## What's detected

Each `IProfile` carries:

| Property | Meaning |
| --- | --- |
| `ColorSystem` | One of `TColorSystem.NoColors` / `Legacy` / `Standard` / `EightBit` / `TrueColor`. |
| `Unicode` | `Boolean` — true if the terminal can render wide-character glyphs. |
| `Width` / `Height` | Terminal dimensions in cells (auto-redetected each render). |
| `Interactive` | `Boolean` — true if stdin is a TTY (prompts allowed). |
| `Ansi` | `Boolean` — true if VT escape sequences are supported. |

Access via `AnsiConsole.Profile`:

```pascal
if AnsiConsole.Profile.Capabilities.Unicode then
  AnsiConsole.WriteLine('Unicode supported')
else
  AnsiConsole.WriteLine('Falling back to ASCII');
```

## Detection rules

The detection logic lives in
[`source/Profile/VSoft.AnsiConsole.Detection.pas`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Profile/VSoft.AnsiConsole.Detection.pas).

### VT100 / ANSI

Probed by calling `SetConsoleMode(ENABLE_VIRTUAL_TERMINAL_PROCESSING)` and
reading back. We do **not** use `GetVersionEx` - on Windows 10/11 it
returns Windows 8.2 for unmanifested exes because of the compatibility
shim.

### Colour system

Picked from a combination of:

- The presence of `ENABLE_VIRTUAL_TERMINAL_PROCESSING` (gates anything above
  `Legacy`).
- Environment variables: `COLORTERM` (`truecolor` / `24bit`),
  `TERM_PROGRAM`, `TERM`.
- Heuristics for known terminals (Windows Terminal, ConEmu, VS Code).

Override at runtime:

```pascal
profile := AnsiConsole.Profile;
profile.WithColorSystem(TColorSystem.Standard);   // force 16-colour
```

Or via `TAnsiConsoleSettings`:

```pascal
settings := TAnsiConsoleSettings.Default;
settings.ColorSystem := TColorSystemSupport.TrueColor;
console := AnsiConsole.CreateFromSettings(settings);
```

### Unicode

Detected from the active code page. Force it explicitly via settings if
the heuristic gets it wrong (e.g. legacy terminal with a unicode font).

### Interactive

`stdin.IsTTY` from `VSoft.System.Console`. False inside CI / piped scripts
- prompts then return defaults instead of blocking.

## CI enrichers

Profile *enrichers* override defaults when running under known CI systems.
Each enricher checks an env var and tweaks the profile:

| CI | Detected via | Effect |
| --- | --- | --- |
| GitHub Actions | `GITHUB_ACTIONS=true` | Disables interactivity, raises colour to TrueColor. |
| GitLab CI | `GITLAB_CI=true` | Disables interactivity. |
| Travis | `TRAVIS=true` | Disables interactivity. |
| AppVeyor | `APPVEYOR=true` | Disables interactivity. |
| Jenkins | `JENKINS_URL` set | Disables interactivity. |
| TeamCity | `TEAMCITY_VERSION` set | Disables interactivity. |
| Bitbucket Pipelines | `BITBUCKET_BUILD_NUMBER` set | Disables interactivity. |

The enricher list lives in
[`source/Profile/VSoft.AnsiConsole.Enrichment.pas`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Profile/VSoft.AnsiConsole.Enrichment.pas).
You can plug your own `IProfileEnricher` by extending the registry; in CI
this means progress bars don't try to redraw and prompts don't block on a
non-existent terminal.

## Building a custom profile

For tests / non-interactive flows, build an `IAnsiConsole` directly with
explicit settings:

```pascal
settings := TAnsiConsoleSettings.Default;
settings.ColorSystem := TColorSystemSupport.NoColors;
settings.Interactive := TInteractionSupport.Off;
console := AnsiConsole.CreateFromSettings(settings);
AnsiConsole.SetConsole(console);
```

`TColorSystemSupport` and `TInteractionSupport` add a `Detect` value — when
set, the corresponding enricher / detector decides at runtime. The library
default is `Detect` for everything.

## See also

- [Architecture](../getting-started/architecture.md) — pipeline overview.
- [Colours](./colors.md) — how the colour system affects rendering.
- [Recorder](../recording/recorder.md) — captures bypass the profile and
  retain full RGB; capability handling is on the encoder.
