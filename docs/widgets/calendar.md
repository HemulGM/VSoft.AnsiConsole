---
title: Calendar
description: A month-grid calendar with a highlighted date and locale-aware formatting.
---

# Calendar

`ICalendar` renders a month grid with the supplied date highlighted. Day-of-week
headers are localised; first-day-of-week and language come from the host
culture or an explicit override.

![Calendar screenshot](/images/calendar.png)

## When to use

- Date pickers in CLIs.
- Schedule overviews, "today" banners.
- Anywhere you need to show a month and call out a specific day.

## Basic usage

```pascal
AnsiConsole.Write(
  Widgets.Calendar(2026, 4, 25)
    .WithCulture('en-GB'));
```

Three constructor overloads:

```pascal
Widgets.Calendar(2026, 4)            // April 2026, day 1 highlighted
Widgets.Calendar(2026, 4, 25)        // April 2026, day 25 highlighted
Widgets.Calendar(EncodeDate(2026, 4, 25))  // from a TDateTime
```

## Configuration

| Method | Purpose |
| --- | --- |
| `WithCulture(name)` | Locale for day/month names — `'en-US'`, `'en-GB'`, `'fr-FR'`, `'de-DE'`, etc. |
| `WithBorder(kind)` | One of the `TTableBorderKind`s. Default `Square`. |
| `WithHeaderStyle(value)` | Style for day-of-week headers. |
| `WithHighlightStyle(value)` | Style for the highlighted date cell. |
| `WithBorderStyle(value)` | Style for the border characters. |

```pascal
AnsiConsole.Write(
  Widgets.Calendar(2026, 4, 25)
    .WithCulture('fr-FR')
    .WithBorder(TTableBorderKind.Rounded)
    .WithHeaderStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua))
    .WithHighlightStyle(TAnsiStyle.Plain.WithBackground(TAnsiColor.Yellow)));
```

## Adding events (markers)

You can add per-day markers shown alongside the calendar:

```pascal
cal := Widgets.Calendar(2026, 4, 25);
cal.AddCalendarEvent('Sprint review', 2026, 4, 14);
cal.AddCalendarEvent('Release',       2026, 4, 25);
AnsiConsole.Write(cal);
```

## API reference

- [`Widgets.Calendar(year, month)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`Widgets.Calendar(year, month, day)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`Widgets.Calendar(date)`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/VSoft.AnsiConsole.pas)
- [`ICalendar`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/blob/main/source/Widgets/VSoft.AnsiConsole.Widgets.Calendar.pas) — interface.
- Demo: [`demos/snippets/Calendar`](https://github.com/VSoftTechnologies/VSoft.AnsiConsole/tree/main/demos/snippets/Calendar).

## See also

- [Table border reference](../reference/table-borders.md).
