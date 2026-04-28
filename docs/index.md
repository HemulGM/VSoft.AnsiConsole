---
layout: home
title: VSoft.AnsiConsole
titleTemplate: Rich console output for Delphi
description: Tables, trees, live progress, prompts, syntax-coloured exceptions, ANSI colour, hyperlinks, emoji, FIGlet text, calendars, charts, recorder + HTML export — composable widgets for Delphi terminals.

hero:
  name: VSoft.AnsiConsole
  text: Rich console output for Delphi
  tagline: Tables, trees, live progress, prompts, syntax-coloured exceptions — composable widgets that render through a unified pipeline.
  image:
    src: /images/readme-demo.png
    alt: VSoft.AnsiConsole hero screenshot
  actions:
    - theme: brand
      text: Get started
      link: /getting-started/quick-start
    - theme: alt
      text: Browse widgets
      link: /widgets/markup
    - theme: alt
      text: View on GitHub
      link: https://github.com/VSoftTechnologies/VSoft.AnsiConsole

features:
  - title: BBCode-style markup
    details: '`[red bold on yellow]hi[/]` — nestable tags, hex colours, OSC 8 hyperlinks, 1500+ named emoji shortcodes.'
  - title: Composable widgets
    details: Panels, tables, trees, grids, layouts, paragraphs, calendars, bar charts, FIGlet text, JSON pretty-printer — all renderables you nest however you like.
  - title: Live displays
    details: Status spinners, multi-task progress trackers, in-place live displays — refresh automatically on a background thread while your action runs.
  - title: Prompts
    details: TextPrompt, ConfirmationPrompt, SelectionPrompt&lt;T&gt;, MultiSelectionPrompt&lt;T&gt; with search-as-you-type, hierarchical choices, validators, defaults, and cancel handling.
  - title: Recorder &amp; export
    details: Capture rendered output and re-emit it as plain text or styled HTML — useful for golden tests, bug reports, and shareable demos.
  - title: 24-bit / 256 / 16 colour with auto-detection
    details: Capability-aware downsampling per terminal. Built-in profile enrichers detect GitHub Actions, AppVeyor, Travis, GitLab CI, Jenkins, TeamCity and disable interactive features automatically.
---

## Standing on the shoulders of giants

VSoft.AnsiConsole is a from-scratch Delphi port that borrows freely - and
gratefully - from the projects that pioneered rich console rendering on
other platforms. The widget catalogue, render pipeline, markup grammar,
and prompt design all closely mirror prior art so existing knowledge
transfers directly; the Delphi idioms (interfaces, fluent builders,
value-typed records) are native.

### Spectre.Console (.NET)

[Spectre.Console](https://github.com/spectreconsole/spectre.console) is the
direct ancestor. The widget surface, border styles, segment-based render
pipeline, prompt design, status / progress / live-display contracts, and
the recorder all follow Spectre's model very closely. Where there's an
obvious right answer in Spectre, this library uses it. Spectre's
documentation at [spectreconsole.net](https://spectreconsole.net) is a
fantastic companion read - many of the conceptual sections there apply
verbatim.

### Rich (Python)

[Rich](https://github.com/Textualize/rich) by Will McGugan is the project
that pioneered most of these ideas - the segment / renderable model, the
markup syntax, the live display pattern. Spectre.Console (and by
extension this library) owes Rich an enormous debt. Several README
examples and the `Markdown` widget approach were lifted directly from
Rich's walk-through.

### Upstream data tables

A handful of mechanical imports power the polish:

- **xterm-256 colour palette** - the exact RGB values for indices 0..255.
- **Unicode 15.1 cell-width tables** - so wide / combining / zero-width
  characters measure correctly.
- **`cli-spinners`** - 90 named spinner kinds, courtesy of
  [Sindre Sorhus](https://github.com/sindresorhus/cli-spinners).
- **FIGlet font data** - the Standard font is bundled; the `.flf` parser
  follows the [FIGlet 2.0 spec](http://www.jave.de/figlet/figfont.html).
- **Emoji shortcodes** - ~1500 entries generated from the Unicode CLDR
  short-name list, matching the same shortcode set you've seen on
  GitHub, Slack, Discord, and Spectre.

Each generated unit carries an attribution comment at the top citing the
upstream source.

### Why a Delphi port?

Delphi doesn't have a first-class equivalent to Spectre or Rich. Building
a CLI tool that needs colour, tables, prompts, or live displays usually
means reaching for `Crt`, custom escape-code helpers, or shelling out to
PowerShell. This library exists so a Delphi developer can `uses
VSoft.AnsiConsole;` and get the same polish as their .NET / Python
counterparts - without porting half the toolchain.
