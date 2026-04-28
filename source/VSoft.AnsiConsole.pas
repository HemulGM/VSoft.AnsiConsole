unit VSoft.AnsiConsole;

{
  VSoft.AnsiConsole - Spectre.Console-style rich console output for Delphi.

  This unit is the single entry point for consumers. It re-exports the key
  types and provides a static facade `AnsiConsole` with class methods for
  the most common operations:

      uses VSoft.AnsiConsole;
      begin
        AnsiConsole.WriteLine('[red bold]Hello[/] [underline]world[/]!');
        AnsiConsole.Write(Widgets.Rule('Section'));
      end.

  The first use of any method that touches the terminal lazily constructs a
  singleton IAnsiConsole via CreateDefaultAnsiConsole. For test doubles or
  custom output (streams, loggers), construct an IAnsiConsole via
  VSoft.AnsiConsole.Console.CreateAnsiConsole and use its methods directly.
}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Emoji,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Capabilities,
  VSoft.AnsiConsole.Enrichment,
  VSoft.AnsiConsole.Profile,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Settings,
  VSoft.AnsiConsole.Cursor,
  VSoft.AnsiConsole.Borders.Box,
  VSoft.AnsiConsole.Borders.Table,
  VSoft.AnsiConsole.Borders.Tree,
  VSoft.AnsiConsole.Widgets.Text,
  VSoft.AnsiConsole.Widgets.Markup,
  VSoft.AnsiConsole.Widgets.Rule,
  VSoft.AnsiConsole.Widgets.Paragraph,
  VSoft.AnsiConsole.Widgets.Padder,
  VSoft.AnsiConsole.Widgets.Align,
  VSoft.AnsiConsole.Widgets.Rows,
  VSoft.AnsiConsole.Widgets.Columns,
  VSoft.AnsiConsole.Widgets.Grid,
  VSoft.AnsiConsole.Widgets.Panel,
  VSoft.AnsiConsole.Widgets.Table,
  VSoft.AnsiConsole.Widgets.Tree,
  VSoft.AnsiConsole.Input,
  VSoft.AnsiConsole.Prompts.Common,
  VSoft.AnsiConsole.Prompts.Text,
  VSoft.AnsiConsole.Prompts.Text.Generic,
  VSoft.AnsiConsole.Prompts.Confirm,
  VSoft.AnsiConsole.Prompts.Hierarchy,
  VSoft.AnsiConsole.Prompts.Select,
  VSoft.AnsiConsole.Prompts.MultiSelect,
  VSoft.AnsiConsole.Live.Exclusivity,
  VSoft.AnsiConsole.Live.Display,
  VSoft.AnsiConsole.Live.Spinners,
  VSoft.AnsiConsole.Live.Status,
  VSoft.AnsiConsole.Live.Progress,
  VSoft.AnsiConsole.Widgets.Canvas,
  VSoft.AnsiConsole.Widgets.BarChart,
  VSoft.AnsiConsole.Widgets.BreakdownChart,
  VSoft.AnsiConsole.Widgets.Calendar,
  VSoft.AnsiConsole.Widgets.TextPath,
  VSoft.AnsiConsole.Widgets.Layout,
  VSoft.AnsiConsole.Widgets.Figlet,
  VSoft.AnsiConsole.Widgets.Json,
  VSoft.AnsiConsole.Widgets.Exception,
  VSoft.AnsiConsole.Recorder;

type
  { Re-exported types so consumers only need to `uses VSoft.AnsiConsole`. }
  TAnsiColor       = VSoft.AnsiConsole.Color.TAnsiColor;
  TAnsiStyle       = VSoft.AnsiConsole.Style.TAnsiStyle;

  IProfileEnricher       = VSoft.AnsiConsole.Enrichment.IProfileEnricher;
  TAnsiConsoleSettings   = VSoft.AnsiConsole.Settings.TAnsiConsoleSettings;
  TAnsiDecoration  = VSoft.AnsiConsole.Types.TAnsiDecoration;
  TAnsiDecorations = VSoft.AnsiConsole.Types.TAnsiDecorations;
  TColorSystem     = VSoft.AnsiConsole.Types.TColorSystem;
  TAlignment         = VSoft.AnsiConsole.Types.TAlignment;
  TVerticalAlignment = VSoft.AnsiConsole.Types.TVerticalAlignment;
  TOverflow          = VSoft.AnsiConsole.Types.TOverflow;
  TRuleBorder      = VSoft.AnsiConsole.Widgets.Rule.TRuleBorder;
  TBoxBorderKind   = VSoft.AnsiConsole.Borders.Box.TBoxBorderKind;
  TTableBorderKind = VSoft.AnsiConsole.Borders.Table.TTableBorderKind;
  TTreeGuideKind   = VSoft.AnsiConsole.Borders.Tree.TTreeGuideKind;
  TGridColumnWidth = VSoft.AnsiConsole.Widgets.Grid.TGridColumnWidth;

  IRenderable      = VSoft.AnsiConsole.Rendering.IRenderable;
  IAnsiConsole     = VSoft.AnsiConsole.Console.IAnsiConsole;
  IAnsiConsoleCursor = VSoft.AnsiConsole.Cursor.IAnsiConsoleCursor;
  TCursorDirection = VSoft.AnsiConsole.Cursor.TCursorDirection;
  IText            = VSoft.AnsiConsole.Widgets.Text.IText;
  IMarkup          = VSoft.AnsiConsole.Widgets.Markup.IMarkup;
  IRule            = VSoft.AnsiConsole.Widgets.Rule.IRule;
  IParagraph       = VSoft.AnsiConsole.Widgets.Paragraph.IParagraph;
  IBoxBorder       = VSoft.AnsiConsole.Borders.Box.IBoxBorder;
  ITableBorder     = VSoft.AnsiConsole.Borders.Table.ITableBorder;
  ITreeGuide       = VSoft.AnsiConsole.Borders.Tree.ITreeGuide;
  IPadder          = VSoft.AnsiConsole.Widgets.Padder.IPadder;
  TPadding         = VSoft.AnsiConsole.Widgets.Padder.TPadding;
  IAlign           = VSoft.AnsiConsole.Widgets.Align.IAlign;
  IRows            = VSoft.AnsiConsole.Widgets.Rows.IRows;
  IColumns         = VSoft.AnsiConsole.Widgets.Columns.IColumns;
  IGrid            = VSoft.AnsiConsole.Widgets.Grid.IGrid;
  IPanel           = VSoft.AnsiConsole.Widgets.Panel.IPanel;
  ITable           = VSoft.AnsiConsole.Widgets.Table.ITable;
  ITableTitle      = VSoft.AnsiConsole.Widgets.Table.ITableTitle;
  ITableCell       = VSoft.AnsiConsole.Widgets.Table.ITableCell;
  ITree            = VSoft.AnsiConsole.Widgets.Tree.ITree;
  ITreeNode        = VSoft.AnsiConsole.Widgets.Tree.ITreeNode;

  IConsoleInput            = VSoft.AnsiConsole.Input.IConsoleInput;
  ITextPrompt              = VSoft.AnsiConsole.Prompts.Text.ITextPrompt;
  IConfirmationPrompt      = VSoft.AnsiConsole.Prompts.Confirm.IConfirmationPrompt;
  TPromptValidationResult  = VSoft.AnsiConsole.Prompts.Common.TPromptValidationResult;
  TTextPromptValidator     = VSoft.AnsiConsole.Prompts.Text.TTextPromptValidator;
  EPromptCancelled         = VSoft.AnsiConsole.Prompts.Common.EPromptCancelled;
  { ISelectionPrompt<T> / IMultiSelectionPrompt<T> live in
    VSoft.AnsiConsole.Prompts.Selection / .MultiSelection. Generic interface
    aliases aren't reliable across Delphi versions, so users `uses` those
    units directly when they need the types - the unit references are
    already pulled in through this facade's `uses` clause for compilation. }

  ILiveDisplay             = VSoft.AnsiConsole.Live.Display.ILiveDisplay;
  ILiveDisplayConfig       = VSoft.AnsiConsole.Live.Display.ILiveDisplayConfig;
  TLiveDisplayAction       = VSoft.AnsiConsole.Live.Display.TLiveDisplayAction;
  TLiveOverflow            = VSoft.AnsiConsole.Live.Display.TLiveOverflow;
  TLiveCropping            = VSoft.AnsiConsole.Live.Display.TLiveCropping;
  ISpinner                 = VSoft.AnsiConsole.Live.Spinners.ISpinner;
  TSpinnerKind             = VSoft.AnsiConsole.Live.Spinners.TSpinnerKind;
  IStatus                  = VSoft.AnsiConsole.Live.Status.IStatus;
  IStatusConfig            = VSoft.AnsiConsole.Live.Status.IStatusConfig;
  TStatusAction            = VSoft.AnsiConsole.Live.Status.TStatusAction;
  IProgress                = VSoft.AnsiConsole.Live.Progress.IProgress;
  IProgressTask            = VSoft.AnsiConsole.Live.Progress.IProgressTask;
  IProgressColumn          = VSoft.AnsiConsole.Live.Progress.IProgressColumn;
  IProgressConfig          = VSoft.AnsiConsole.Live.Progress.IProgressConfig;
  IDescriptionColumn       = VSoft.AnsiConsole.Live.Progress.IDescriptionColumn;
  IProgressBarColumn       = VSoft.AnsiConsole.Live.Progress.IProgressBarColumn;
  IPercentageColumn        = VSoft.AnsiConsole.Live.Progress.IPercentageColumn;
  IElapsedColumn           = VSoft.AnsiConsole.Live.Progress.IElapsedColumn;
  IRemainingTimeColumn     = VSoft.AnsiConsole.Live.Progress.IRemainingTimeColumn;
  ISpinnerColumn           = VSoft.AnsiConsole.Live.Progress.ISpinnerColumn;
  IDownloadedColumn        = VSoft.AnsiConsole.Live.Progress.IDownloadedColumn;
  ITransferSpeedColumn     = VSoft.AnsiConsole.Live.Progress.ITransferSpeedColumn;
  TFileSizeBase            = VSoft.AnsiConsole.Live.Progress.TFileSizeBase;
  TProgressAction          = VSoft.AnsiConsole.Live.Progress.TProgressAction;
  ELiveDisplayBusy         = VSoft.AnsiConsole.Live.Exclusivity.ELiveDisplayBusy;

  { Phase 6 advanced widgets. }
  ICanvas          = VSoft.AnsiConsole.Widgets.Canvas.ICanvas;
  IBarChart        = VSoft.AnsiConsole.Widgets.BarChart.IBarChart;
  IBreakdownChart  = VSoft.AnsiConsole.Widgets.BreakdownChart.IBreakdownChart;
  ICalendar        = VSoft.AnsiConsole.Widgets.Calendar.ICalendar;
  ITextPath        = VSoft.AnsiConsole.Widgets.TextPath.ITextPath;
  ILayout          = VSoft.AnsiConsole.Widgets.Layout.ILayout;
  IFigletText      = VSoft.AnsiConsole.Widgets.Figlet.IFigletText;
  TBarValueFormatter       = VSoft.AnsiConsole.Widgets.BarChart.TBarValueFormatter;
  TBreakdownValueFormatter = VSoft.AnsiConsole.Widgets.BreakdownChart.TBreakdownValueFormatter;

  { Phase 7 polish widgets. }
  IJsonText        = VSoft.AnsiConsole.Widgets.Json.IJsonText;
  IExceptionWidget = VSoft.AnsiConsole.Widgets.Exception.IExceptionWidget;
  IExceptionStyle  = VSoft.AnsiConsole.Widgets.Exception.IExceptionStyle;
  TExceptionFormat  = VSoft.AnsiConsole.Widgets.Exception.TExceptionFormat;
  TExceptionFormats = VSoft.AnsiConsole.Widgets.Exception.TExceptionFormats;
  IRecorder        = VSoft.AnsiConsole.Recorder.IRecorder;
  IAnsiConsoleEncoder = VSoft.AnsiConsole.Recorder.IAnsiConsoleEncoder;

type
  /// <summary>
  /// Static facade for writing rich content (markup, widgets, prompts, live
  /// displays, recordings) to the active terminal. Owns operations that touch
  /// the singleton <see cref="IAnsiConsole"/>; widget construction lives on
  /// the <see cref="Widgets"/> companion record.
  /// </summary>
  /// <remarks>
  /// The first call to any method that touches the terminal lazily constructs
  /// a singleton <see cref="IAnsiConsole"/> with capabilities auto-detected
  /// from the host terminal. Tests and recording flows can swap the singleton
  /// with <see cref="SetConsole"/> or use the explicit-console overloads on
  /// <see cref="Status"/> / <see cref="Progress"/> / <see cref="LiveDisplay"/>.
  /// </remarks>
  AnsiConsole = class sealed
  strict private
    class var FConsole      : IAnsiConsole;
    class var FLock         : TCriticalSection;
    class var FCurrentStyle       : TAnsiStyle;
    class var FRecorder           : IRecorder;
    class var FRecordingPrevious  : IAnsiConsole;
    class function GetConsole : IAnsiConsole; static;
    class function  GetForeground : TAnsiColor; static;
    class procedure SetForeground(const value : TAnsiColor); static;
    class function  GetBackground : TAnsiColor; static;
    class procedure SetBackground(const value : TAnsiColor); static;
    class function  GetDecoration : TAnsiDecorations; static;
    class procedure SetDecoration(const value : TAnsiDecorations); static;
  public
    class constructor Create;
    class destructor  Destroy;

    /// <summary>
    /// Replaces the singleton console with a custom one (typically used by
    /// tests that need a captured output). Pass <c>nil</c> to revert to the
    /// auto-detected default.
    /// </summary>
    /// <param name="value">The replacement console, or <c>nil</c> to reset.</param>
    class procedure SetConsole(const value : IAnsiConsole); static;

    /// <summary>
    /// Builds a fresh <see cref="IAnsiConsole"/> from the supplied
    /// <see cref="TAnsiConsoleSettings"/>. The returned console is independent
    /// of the static facade - call <see cref="SetConsole"/> afterwards if you
    /// want subsequent <c>AnsiConsole.*</c> calls to flow through it.
    /// </summary>
    /// <param name="settings">Settings struct describing capabilities and IO targets.</param>
    /// <returns>A new console instance.</returns>
    class function CreateFromSettings(const settings : TAnsiConsoleSettings) : IAnsiConsole; static;

    /// <summary>
    /// The active singleton console. Lazily auto-detected on first use; can be
    /// replaced via <see cref="SetConsole"/>.
    /// </summary>
    class property Console : IAnsiConsole read GetConsole;

    /// <summary>
    /// The mutable foreground colour applied to the next <c>Write</c> /
    /// <c>Markup</c> call as the base style. Mirrors Spectre's
    /// <c>AnsiConsole.Foreground</c>. Use <see cref="ResetColors"/> or
    /// <see cref="Reset"/> to clear.
    /// </summary>
    class property Foreground : TAnsiColor       read GetForeground write SetForeground;
    /// <summary>
    /// The mutable background colour applied to the next <c>Write</c> /
    /// <c>Markup</c> call as the base style.
    /// </summary>
    class property Background : TAnsiColor       read GetBackground write SetBackground;
    /// <summary>
    /// The mutable text decorations (bold, italic, underline, etc.) applied
    /// to the next <c>Write</c> / <c>Markup</c> call as the base style.
    /// </summary>
    class property Decoration : TAnsiDecorations read GetDecoration write SetDecoration;

    /// <summary>Renders the supplied widget and writes its segments to the console.</summary>
    /// <param name="renderable">A widget produced by <see cref="Widgets"/> or any custom <see cref="IRenderable"/>.</param>
    class procedure Write(const renderable : IRenderable); overload; static;
    /// <summary>Writes a literal string to the console - markup tags are NOT parsed. Use <see cref="Markup"/> for styled output.</summary>
    /// <param name="value">Literal text. Special characters are written verbatim.</param>
    class procedure Write(const value : string); overload; static;
    /// <summary>Writes the decimal representation of an integer.</summary>
    class procedure Write(value : Integer); overload; static;
    /// <summary>Writes the decimal representation of a 64-bit integer.</summary>
    class procedure Write(value : Int64); overload; static;
    /// <summary>Writes the floating-point value using the default Delphi format.</summary>
    class procedure Write(value : Double); overload; static;
    /// <summary>Writes <c>"True"</c> or <c>"False"</c>.</summary>
    class procedure Write(value : Boolean); overload; static;
    /// <summary>Writes a single character.</summary>
    class procedure Write(value : Char); overload; static;
    /// <summary>Writes a Format-style literal string with arguments spliced in. No markup parsing.</summary>
    /// <param name="fmt">A <c>System.SysUtils.Format</c> format string.</param>
    /// <param name="args">Format arguments.</param>
    class procedure Write(const fmt : string; const args : array of const); overload; static;
    /// <summary>Writes a newline.</summary>
    class procedure WriteLine; overload; static;
    /// <summary>Writes a literal string followed by a newline. No markup parsing.</summary>
    class procedure WriteLine(const value : string); overload; static;
    /// <summary>Renders the supplied widget, writes its segments, then writes a newline.</summary>
    class procedure WriteLine(const renderable : IRenderable); overload; static;
    /// <summary>Writes an integer followed by a newline.</summary>
    class procedure WriteLine(value : Integer); overload; static;
    /// <summary>Writes a 64-bit integer followed by a newline.</summary>
    class procedure WriteLine(value : Int64); overload; static;
    /// <summary>Writes a floating-point value followed by a newline.</summary>
    class procedure WriteLine(value : Double); overload; static;
    /// <summary>Writes a boolean followed by a newline.</summary>
    class procedure WriteLine(value : Boolean); overload; static;
    /// <summary>Writes a single character followed by a newline.</summary>
    class procedure WriteLine(value : Char); overload; static;
    /// <summary>Writes a Format-style literal string with arguments spliced in, then a newline.</summary>
    class procedure WriteLine(const fmt : string; const args : array of const); overload; static;

    /// <summary>
    /// Parses BBCode-style markup and writes the styled segments to the
    /// console. Tags like <c>[red bold]hello[/]</c>, <c>[link=...]</c>, and
    /// hex colours <c>[#ff8800]</c> are supported. Use <c>[[</c> and <c>]]</c>
    /// to embed literal brackets.
    /// </summary>
    /// <param name="value">Markup-formatted string.</param>
    class procedure Markup(const value : string); overload; static;
    /// <summary>Parses a Format-style markup string with arguments spliced in.</summary>
    /// <param name="fmt">Markup format string.</param>
    /// <param name="args">Format arguments.</param>
    class procedure Markup(const fmt : string; const args : array of const); overload; static;
    /// <summary>Parses markup and writes the styled segments followed by a newline.</summary>
    class procedure MarkupLine(const value : string); overload; static;
    /// <summary>Parses a Format-style markup string with arguments spliced in, then writes a newline.</summary>
    class procedure MarkupLine(const fmt : string; const args : array of const); overload; static;

    /// <summary>Clears the screen and moves the cursor to the home position.</summary>
    class procedure Clear; overload; static;
    /// <summary>
    /// Clears the screen. When <paramref name="home"/> is <c>True</c> the
    /// cursor is also moved to the upper-left corner.
    /// </summary>
    /// <param name="home">If <c>True</c>, move the cursor to (1,1) after clearing.</param>
    class procedure Clear(home : Boolean); overload; static;

    /// <summary>Hides the terminal cursor (DECTCEM off).</summary>
    class procedure HideCursor; static;
    /// <summary>Shows the terminal cursor (DECTCEM on).</summary>
    class procedure ShowCursor; static;
    /// <summary>Clears the current foreground / background colours used by <see cref="Write"/> and <see cref="Markup"/>.</summary>
    class procedure ResetColors; static;
    /// <summary>Clears the current text decorations (bold, italic, etc.).</summary>
    class procedure ResetDecoration; static;
    /// <summary>Clears all current style state - foreground, background, and decorations.</summary>
    class procedure Reset; static;
    /// <summary>
    /// Runs <paramref name="action"/> inside the terminal's alternate-screen
    /// buffer (DECSET 1049). On exit the previous screen contents are
    /// restored - useful for full-screen TUIs that should not pollute the
    /// scroll-back buffer.
    /// </summary>
    /// <param name="action">Anonymous procedure to run while the alt-screen is active.</param>
    class procedure AlternateScreen(const action : TProc); static;
    /// <summary>Sets the terminal window title via OSC 0.</summary>
    /// <param name="title">New title text.</param>
    class procedure SetWindowTitle(const title : string); static;
    /// <summary>
    /// Emits a raw control sequence (escape codes etc.) on the current
    /// console. Escape hatch for callers that need a CSI sequence not
    /// covered by <see cref="Cursor"/>, <see cref="Reset"/>, etc.
    /// </summary>
    /// <param name="sequence">The raw bytes to emit; no validation is performed.</param>
    class procedure WriteAnsi(const sequence : string); static;
    /// <summary>
    /// Returns a randomly-chosen built-in spinner. Useful for status / progress widgets when you don't want to pick a specific kind.
    /// </summary>
    class function  RandomSpinner : ISpinner; static;
    /// <summary>
    /// Escapes markup metacharacters in <paramref name="value"/> so the
    /// result, when fed back through <see cref="Markup"/>, renders the
    /// original text verbatim. Mirrors Spectre's <c>Markup.Escape</c>.
    /// </summary>
    /// <param name="value">Arbitrary text to escape.</param>
    /// <returns>Escape-safe markup string.</returns>
    class function  EscapeMarkup(const value : string) : string; static;

    /// <summary>
    /// Looks up the unicode glyph for a known emoji shortcode (e.g.
    /// <c>:rocket:</c> -> <c>"🚀"</c>). Returns the empty string
    /// when the shortcode is unknown. For in-place substitution of
    /// <c>:name:</c> patterns inside arbitrary text, use <c>TEmoji.Replace</c>.
    /// </summary>
    /// <param name="shortcode">Emoji name without surrounding colons (e.g. <c>"rocket"</c>) or with them.</param>
    /// <returns>The unicode character(s), or empty string when unknown.</returns>
    class function  Emoji(const shortcode : string) : string; static;

    /// <summary>
    /// Returns a cursor wrapper bound to the current console, exposing
    /// Show / Hide / SetPosition / MoveUp / MoveDown / MoveLeft / MoveRight.
    /// Cheap; no caching.
    /// </summary>
    class function  Cursor : IAnsiConsoleCursor; static;
    /// <summary>The active console's profile (capabilities, dimensions, colour system).</summary>
    class function  Profile : IProfile; static;
    /// <summary>
    /// Renders <paramref name="e"/> using <see cref="Widgets.ExceptionWidget"/>
    /// with default styling and writes the result to the console.
    /// </summary>
    /// <param name="e">The exception to display.</param>
    class procedure WriteException(const e : Exception); static;

    { Widget factories live on the `Widgets` static class - see below.
      `AnsiConsole` only owns operations that touch the singleton console
      (Write, Markup-procedure, Live, Status, Progress, Cursor, Prompt). }

    /// <summary>Builds an empty <see cref="ITextPrompt"/> for asking a free-form string. Configure with <c>WithDefault</c>, <c>WithValidator</c>, etc., then call <c>Show(AnsiConsole.Console)</c> or pass to <see cref="Prompt"/>.</summary>
    class function  TextPrompt : ITextPrompt; static;
    /// <summary>Builds an empty <see cref="IConfirmationPrompt"/> for yes/no questions.</summary>
    class function  ConfirmationPrompt : IConfirmationPrompt; static;
    /// <summary>Convenience for displaying a one-shot text prompt and returning the user's answer.</summary>
    /// <param name="prompt">The question shown to the user.</param>
    /// <returns>The user's typed answer.</returns>
    class function  Ask(const prompt : string) : string; overload; static;
    /// <summary>Convenience for displaying a one-shot text prompt with a default answer.</summary>
    /// <param name="prompt">The question shown to the user.</param>
    /// <param name="default_">Default value used when the user just hits Enter.</param>
    class function  Ask(const prompt, default_ : string) : string; overload; static;
    /// <summary>Convenience for displaying a one-shot Yes/No prompt.</summary>
    /// <param name="prompt">The question shown to the user.</param>
    /// <returns><c>True</c> if the user answered yes.</returns>
    class function  Confirm(const prompt : string) : Boolean; overload; static;
    /// <summary>Convenience for displaying a one-shot Yes/No prompt with a default answer.</summary>
    /// <param name="prompt">The question shown to the user.</param>
    /// <param name="default_">The answer used when the user just hits Enter.</param>
    class function  Confirm(const prompt : string; default_ : Boolean) : Boolean; overload; static;
    /// <summary>Builds an empty <see cref="ISelectionPrompt"/> for picking one item from a list. Configure choices with <c>AddChoice</c> and call <c>Show</c>.</summary>
    class function  SelectionPrompt<T> : ISelectionPrompt<T>; static;
    /// <summary>Builds an empty <see cref="IMultiSelectionPrompt"/> for picking multiple items from a list with checkbox-style selection.</summary>
    class function  MultiSelectionPrompt<T> : IMultiSelectionPrompt<T>; static;
    /// <summary>
    /// Generic typed Ask. <typeparamref name="T"/> is parsed via the built-in
    /// RTTI parser (<c>Integer</c>, <c>Int64</c>, <c>Double</c>,
    /// <c>TDateTime</c>, <c>Boolean</c>, enum, <c>string</c>) or a user-supplied
    /// parser passed via <c>TextPrompt&lt;T&gt;.Create.WithParser</c>.
    /// </summary>
    /// <param name="prompt">The question shown to the user.</param>
    class function  Ask<T>(const prompt : string) : T; overload; static;
    /// <summary>Generic typed Ask with a default value.</summary>
    /// <param name="prompt">The question shown to the user.</param>
    /// <param name="default_">Default value used when the user hits Enter.</param>
    class function  Ask<T>(const prompt : string; const default_ : T) : T; overload; static;

    /// <summary>Shows a configured <see cref="ITextPrompt"/> using the singleton console and returns the result. Mirrors Spectre's <c>AnsiConsole.Prompt&lt;T&gt;</c>.</summary>
    class function  Prompt(const prompt : ITextPrompt) : string; overload; static;
    /// <summary>Shows a configured <see cref="IConfirmationPrompt"/> using the singleton console.</summary>
    class function  Prompt(const prompt : IConfirmationPrompt) : Boolean; overload; static;
    /// <summary>Shows a configured generic <see cref="ITextPrompt"/> and returns the parsed value.</summary>
    class function  Prompt<T>(const prompt : ITextPrompt<T>) : T; overload; static;
    /// <summary>Shows a configured single-selection prompt and returns the picked item.</summary>
    class function  Prompt<T>(const prompt : ISelectionPrompt<T>) : T; overload; static;
    /// <summary>Shows a configured multi-selection prompt and returns the array of picked items.</summary>
    class function  Prompt<T>(const prompt : IMultiSelectionPrompt<T>) : TArray<T>; overload; static;

    /// <summary>
    /// Starts an in-place live display - useful for redrawing a renderable
    /// (table, panel, custom widget) repeatedly in the same screen region
    /// without scrolling. Configure refresh / overflow then call <c>Start</c>.
    /// </summary>
    /// <param name="initial">The initial renderable to display; replace it from inside the action via <c>ctx.Update(...)</c>.</param>
    class function  LiveDisplay(const initial : IRenderable) : ILiveDisplayConfig; overload; static;
    /// <summary>Same as <see cref="LiveDisplay(IRenderable)"/> but writes to an explicit console (typically a captured one for tests).</summary>
    /// <param name="console">Target console.</param>
    /// <param name="initial">Initial renderable.</param>
    class function  LiveDisplay(const console : IAnsiConsole; const initial : IRenderable) : ILiveDisplayConfig; overload; static;
    /// <summary>Spectre-named alias for <see cref="LiveDisplay(IRenderable)"/>.</summary>
    class function  Live(const initial : IRenderable) : ILiveDisplayConfig; static;
    /// <summary>
    /// Starts a status display - an animated spinner with a status message,
    /// rendered while a long-running action runs. Configure spinner / style /
    /// auto-refresh and call <c>Start(message, action)</c>.
    /// </summary>
    class function  Status : IStatusConfig; overload; static;
    /// <summary>Same as <see cref="Status"/> but writes to an explicit console.</summary>
    class function  Status(const console : IAnsiConsole) : IStatusConfig; overload; static;
    /// <summary>
    /// Starts a multi-task progress tracker - one row per task with
    /// configurable columns (description / bar / percentage / spinner /
    /// elapsed / remaining / etc.). Configure columns and call <c>Start</c>.
    /// </summary>
    class function  Progress : IProgressConfig; overload; static;
    /// <summary>Same as <see cref="Progress"/> but writes to an explicit console.</summary>
    class function  Progress(const console : IAnsiConsole) : IProgressConfig; overload; static;
    /// <summary>
    /// Wraps an <see cref="IAnsiConsole"/> in a recorder that captures every
    /// rendered segment for later export as plain text or styled HTML. Pass
    /// <c>nil</c> to record the singleton console.
    /// </summary>
    /// <param name="inner">Console to record, or <c>nil</c> to record the singleton.</param>
    /// <returns>A recorder wrapping the target console.</returns>
    class function  Recorder(const inner : IAnsiConsole = nil) : IRecorder; static;

    /// <summary>
    /// Starts recording the singleton console. Subsequent <c>AnsiConsole.*</c>
    /// calls are captured and can be exported via <see cref="ExportText"/>,
    /// <see cref="ExportHtml"/>, or <see cref="ExportCustom"/>. Call
    /// <see cref="StopRecording"/> to restore the prior console.
    /// </summary>
    /// <remarks>Spectre's facade method is <c>Record()</c> but <c>record</c> is reserved in Delphi, hence the renamed pair.</remarks>
    class procedure StartRecording; static;
    /// <summary>Stops recording and restores the prior console.</summary>
    class procedure StopRecording; static;
    /// <summary>Exports the recorded output as plain text (escape codes stripped).</summary>
    /// <returns>The captured text.</returns>
    class function  ExportText : string; static;
    /// <summary>Exports the recorded output as styled HTML (CSS-coloured spans).</summary>
    /// <returns>The HTML markup.</returns>
    class function  ExportHtml : string; static;
    /// <summary>Exports the recorded output through a custom encoder.</summary>
    /// <param name="encoder">Encoder that converts segments into the desired format.</param>
    class function  ExportCustom(const encoder : IAnsiConsoleEncoder) : string; static;
  end;

  /// <summary>
  /// Pure-construction factories for every widget, border, spinner, and
  /// progress column. None of these touch the console - they build a
  /// value-typed widget that you then pass to <see cref="AnsiConsole.Write"/>,
  /// embed inside another widget (e.g. <see cref="Panel"/>, <see cref="Table"/>),
  /// or feed to a live builder.
  /// </summary>
  /// <remarks>
  /// Centralising these on <c>Widgets</c> avoids the local-variable shadowing
  /// problems that free factory functions caused (e.g. <c>var text : string</c>
  /// shadowing the free <c>Text(...)</c> function).
  /// </remarks>
  Widgets = record
  public
    /// <summary>Builds an <see cref="IText"/> renderable for plain literal text. No markup parsing.</summary>
    /// <param name="value">The text to render.</param>
    class function Text(const value : string) : IText; overload; static;
    /// <summary>Builds an <see cref="IText"/> renderable for plain literal text with an explicit style.</summary>
    /// <param name="value">The text to render.</param>
    /// <param name="style">Foreground / background / decorations applied to the text.</param>
    class function Text(const value : string; const style : TAnsiStyle) : IText; overload; static;
    /// <summary>
    /// Builds an <see cref="IMarkup"/> renderable from a markup-formatted
    /// string (e.g. <c>'[red bold]hi[/]'</c>). Use this widget form when you
    /// need to embed markup-styled text inside another widget like
    /// <see cref="Panel"/> or <see cref="Table"/>; for direct writing use
    /// <see cref="AnsiConsole.Markup"/>.
    /// </summary>
    /// <param name="value">Markup-formatted string.</param>
    class function Markup(const value : string) : IMarkup; overload; static;
    /// <summary>Builds an <see cref="IMarkup"/> renderable with a base style applied to all unstyled regions.</summary>
    /// <param name="value">Markup-formatted string.</param>
    /// <param name="baseStyle">Base style; markup tags layer on top.</param>
    class function Markup(const value : string; const baseStyle : TAnsiStyle) : IMarkup; overload; static;
    /// <summary>Builds an empty horizontal rule (a divider line spanning the full width).</summary>
    class function Rule : IRule; overload; static;
    /// <summary>Builds a horizontal rule with a centered title - <c>───── Section ─────</c>.</summary>
    /// <param name="title">Title text rendered inline with the rule. Markup is supported.</param>
    class function Rule(const title : string) : IRule; overload; static;
    /// <summary>Builds an empty paragraph - a wrapping text container with configurable alignment / overflow.</summary>
    class function Paragraph : IParagraph; overload; static;
    /// <summary>Builds a paragraph initialised with the supplied text.</summary>
    /// <param name="text">The paragraph text. Markup is supported.</param>
    class function Paragraph(const text : string) : IParagraph; overload; static;
    /// <summary>Builds a paragraph initialised with the supplied text and an explicit base style.</summary>
    class function Paragraph(const text : string; const style : TAnsiStyle) : IParagraph; overload; static;
    /// <summary>
    /// Wraps a child renderable in a padder, adding configurable left / right /
    /// top / bottom whitespace around it. Use <c>WithPadding</c> on the result
    /// to set the padding values.
    /// </summary>
    /// <param name="child">The widget to pad.</param>
    class function Padder(const child : IRenderable) : IPadder; static;
    /// <summary>Wraps a child renderable in an aligner that positions it horizontally within the available width.</summary>
    /// <param name="child">The widget to align.</param>
    /// <param name="alignment">Left, Center, or Right.</param>
    class function Align(const child : IRenderable; alignment : TAlignment) : IAlign; static;
    /// <summary>Builds an empty <see cref="IRows"/> stack - children are laid out top-to-bottom.</summary>
    class function Rows : IRows; static;
    /// <summary>Builds an empty <see cref="IColumns"/> container - children are laid out left-to-right with equal-or-content sizing.</summary>
    class function Columns : IColumns; static;
    /// <summary>
    /// Builds an empty <see cref="IGrid"/> - a lightweight table without
    /// borders or headers. Add columns with <c>AddColumn</c> /
    /// <c>AddAutoColumn</c> / <c>AddFixedColumn</c> / <c>AddStarColumn</c>,
    /// then rows with <c>AddRow</c>.
    /// </summary>
    class function Grid : IGrid; static;
    /// <summary>Builds a panel - a bordered box containing one renderable child, optionally with a header / footer.</summary>
    /// <param name="child">The widget to wrap.</param>
    class function Panel(const child : IRenderable) : IPanel; overload; static;
    /// <summary>Builds a panel whose body is markup-styled text.</summary>
    /// <param name="markup">Markup string for the body.</param>
    class function Panel(const markup : string) : IPanel; overload; static;

    /// <summary>
    /// Builds an empty table. Add columns with <c>AddColumn</c> and rows with
    /// <c>AddRow</c>; configure border / title / footer / expansion via the
    /// <c>WithXxx</c> fluent setters.
    /// </summary>
    class function Table : ITable; static;
    /// <summary>Builds a table title (the line rendered above the table). Markup is supported.</summary>
    /// <param name="text">Title text.</param>
    class function TableTitle(const text : string) : ITableTitle; static;
    /// <summary>Builds a table cell wrapping a markup string. Use this when you need per-cell style overrides.</summary>
    /// <param name="text">Markup-formatted cell content.</param>
    class function TableCell(const text : string) : ITableCell; overload; static;
    /// <summary>Builds a table cell wrapping an arbitrary renderable - useful for embedding panels / tables / etc. inside cells.</summary>
    /// <param name="content">Renderable cell content.</param>
    class function TableCell(const content : IRenderable) : ITableCell; overload; static;
    /// <summary>Builds a tree whose root is an arbitrary renderable.</summary>
    /// <param name="root">The renderable to render at the tree's root.</param>
    class function Tree(const root : IRenderable) : ITree; overload; static;
    /// <summary>Builds a tree whose root is markup text.</summary>
    /// <param name="rootMarkup">Markup string for the root label.</param>
    class function Tree(const rootMarkup : string) : ITree; overload; static;

    /// <summary>Returns the <see cref="IBoxBorder"/> corresponding to the supplied kind. Used by <see cref="Panel"/> and other box-bordered widgets.</summary>
    /// <param name="kind">Square / Rounded / Heavy / Double / Ascii / None.</param>
    class function BoxBorder(kind : TBoxBorderKind) : IBoxBorder; static;
    /// <summary>Returns the <see cref="ITableBorder"/> corresponding to the supplied kind. Used by <see cref="Table"/>.</summary>
    /// <param name="kind">One of the 19 table-border kinds (Ascii, Square, Rounded, Heavy, Markdown, Simple, etc.).</param>
    class function TableBorder(kind : TTableBorderKind) : ITableBorder; static;
    /// <summary>Returns the <see cref="ITreeGuide"/> corresponding to the supplied kind. Used by <see cref="Tree"/>.</summary>
    /// <param name="kind">Ascii / Line / Heavy / Double / Bold.</param>
    class function TreeGuide(kind : TTreeGuideKind) : ITreeGuide; static;

    /// <summary>Builds a fixed-size canvas of cells you can paint by RGB. Useful for image-like rendering using half-block characters.</summary>
    /// <param name="width">Canvas width in cells.</param>
    /// <param name="height">Canvas height in cells.</param>
    class function Canvas(width, height : Integer) : ICanvas; static;
    /// <summary>Builds an empty bar chart. Add data with <c>AddItem(label, value, color)</c>; configure with <c>WithLabel</c> / <c>WithWidth</c>.</summary>
    class function BarChart : IBarChart; static;
    /// <summary>Builds an empty breakdown chart - a single horizontal bar that splits a total into proportional coloured segments with a legend.</summary>
    class function BreakdownChart : IBreakdownChart; static;
    /// <summary>Builds a calendar showing the supplied month with the first day highlighted.</summary>
    /// <param name="year">Four-digit year.</param>
    /// <param name="month">Month (1-12).</param>
    class function Calendar(year, month : Integer) : ICalendar; overload; static;
    /// <summary>Builds a calendar with a specific day highlighted.</summary>
    /// <param name="year">Four-digit year.</param>
    /// <param name="month">Month (1-12).</param>
    /// <param name="day">Day to highlight (1-31).</param>
    class function Calendar(year, month, day : Integer) : ICalendar; overload; static;
    /// <summary>Builds a calendar with the supplied <see cref="TDateTime"/> highlighted.</summary>
    /// <param name="date">The date to render and highlight.</param>
    class function Calendar(const date : TDateTime) : ICalendar; overload; static;
    /// <summary>Builds a TextPath widget that renders a file system path with each segment styled separately and an optional ellipsis when over-long.</summary>
    /// <param name="path">The path string.</param>
    class function TextPath(const path : string) : ITextPath; static;
    /// <summary>
    /// Builds an unnamed root layout. Use <c>SplitRows</c> / <c>SplitColumns</c>
    /// to recursively split into named regions, then place renderables with
    /// <c>Update</c> on each leaf.
    /// </summary>
    class function Layout : ILayout; overload; static;
    /// <summary>Builds a named layout node - the name is used by <c>FindByName</c> to locate the node later.</summary>
    /// <param name="name">Identifier for the layout node.</param>
    class function Layout(const name : string) : ILayout; overload; static;
    /// <summary>Builds a FIGlet-text widget rendering the supplied string in large ASCII-art letters using the default Standard font.</summary>
    /// <param name="text">Text to render.</param>
    class function FigletText(const text : string) : IFigletText; static;
    /// <summary>Builds a JSON renderable that pretty-prints and syntax-highlights the supplied JSON source.</summary>
    /// <param name="source">JSON text.</param>
    class function Json(const source : string) : IJsonText; static;
    /// <summary>Builds an ExceptionWidget rendering the supplied exception's class name, message, and stack trace (when available).</summary>
    /// <param name="e">The exception to render.</param>
    class function ExceptionWidget(const e : Exception) : IExceptionWidget; overload; static;
    /// <summary>Builds an ExceptionWidget from raw class name + message strings - useful for tests or post-mortem dumps where no live <see cref="Exception"/> instance exists.</summary>
    /// <param name="className">Exception class name (e.g. <c>"EInOutError"</c>).</param>
    /// <param name="message">Exception message.</param>
    class function ExceptionWidget(const className, message : string) : IExceptionWidget; overload; static;
    /// <summary>Builds a default <see cref="IExceptionStyle"/> - a Spectre-compatible style sheet you can pass to <c>WithStyle</c> on an exception widget.</summary>
    class function ExceptionStyle : IExceptionStyle; static;

    /// <summary>
    /// Builds an <see cref="ISpinner"/> for the named built-in kind. Defaults
    /// to the unicode glyph set; use the overload taking <c>unicode</c> to
    /// auto-detect or force ASCII fallback.
    /// </summary>
    /// <param name="kind">One of the built-in spinner kinds (Dots, Arc, Runner, Earth, etc.).</param>
    class function Spinner(kind : TSpinnerKind) : ISpinner; overload; static;
    /// <summary>Builds an <see cref="ISpinner"/> for the named kind, with explicit unicode handling.</summary>
    /// <param name="kind">Built-in spinner kind.</param>
    /// <param name="unicode">When <c>False</c> any kind that requires unicode falls back to a simple line-style ASCII set.</param>
    class function Spinner(kind : TSpinnerKind; unicode : Boolean) : ISpinner; overload; static;
    /// <summary>Builds a custom <see cref="ISpinner"/> from a user-supplied frame list and per-frame interval.</summary>
    /// <param name="frames">Animation frames; cycled in order with wrap-around.</param>
    /// <param name="intervalMs">Milliseconds between frames.</param>
    class function Spinner(const frames : TArray<string>; intervalMs : Integer) : ISpinner; overload; static;

    /// <summary>Progress column rendering the task description (the label passed to <c>AddTask</c>).</summary>
    class function DescriptionColumn : IDescriptionColumn; static;
    /// <summary>Progress column rendering a filled / unfilled bar at the column's allocated width.</summary>
    class function ProgressBarColumn : IProgressBarColumn; overload; static;
    /// <summary>Progress column rendering a filled / unfilled bar capped at <paramref name="width"/> cells.</summary>
    /// <param name="width">Maximum bar width in cells. Pass <c>-1</c> for no cap (the bar fills the column).</param>
    class function ProgressBarColumn(width : Integer) : IProgressBarColumn; overload; static;
    /// <summary>Progress column rendering the task percentage as <c>"42%"</c>.</summary>
    class function PercentageColumn : IPercentageColumn; static;
    /// <summary>Progress column rendering the time elapsed since <c>StartTask</c> as <c>hh:mm:ss</c>.</summary>
    class function ElapsedColumn : IElapsedColumn; static;
    /// <summary>Progress column rendering the estimated time remaining as <c>hh:mm:ss</c> (or <c>**:**:**</c> while indeterminate).</summary>
    class function RemainingTimeColumn : IRemainingTimeColumn; static;
    /// <summary>Progress column rendering an animated spinner using the default Dots kind.</summary>
    class function SpinnerColumn : ISpinnerColumn; overload; static;
    /// <summary>Progress column rendering an animated spinner with a specific kind.</summary>
    /// <param name="kind">Spinner kind to display.</param>
    class function SpinnerColumn(kind : TSpinnerKind) : ISpinnerColumn; overload; static;
    /// <summary>Progress column rendering downloaded / total bytes (e.g. <c>"512 KB / 1 MB"</c>).</summary>
    class function DownloadedColumn : IDownloadedColumn; static;
    /// <summary>Progress column rendering transfer rate (e.g. <c>"256 KB/s"</c>) computed from the task's recent sample history.</summary>
    class function TransferSpeedColumn : ITransferSpeedColumn; static;
  end;

implementation

{ AnsiConsole }

class constructor AnsiConsole.Create;
begin
  FLock := TCriticalSection.Create;
  FCurrentStyle := TAnsiStyle.Plain;
end;

class destructor AnsiConsole.Destroy;
begin
  FRecorder := nil;
  FRecordingPrevious := nil;
  FConsole := nil;
  FLock.Free;
end;

class function AnsiConsole.GetConsole : IAnsiConsole;
begin
  if FConsole <> nil then
  begin
    result := FConsole;
    Exit;
  end;
  FLock.Enter;
  try
    if FConsole = nil then
      FConsole := CreateDefaultAnsiConsole;
    result := FConsole;
  finally
    FLock.Leave;
  end;
end;

class function AnsiConsole.CreateFromSettings(const settings : TAnsiConsoleSettings) : IAnsiConsole;
begin
  result := VSoft.AnsiConsole.Settings.CreateAnsiConsoleFromSettings(settings);
end;

class procedure AnsiConsole.SetConsole(const value : IAnsiConsole);
begin
  FLock.Enter;
  try
    FConsole := value;
  finally
    FLock.Leave;
  end;
end;

{ State accessors. The setters mutate FCurrentStyle so the next Write/Markup
  emits the new colour or decoration as the base style. They do NOT emit
  any control sequence themselves - the next write does that via the
  segment style. }

class function AnsiConsole.GetForeground : TAnsiColor;
begin
  result := FCurrentStyle.Foreground;
end;

class procedure AnsiConsole.SetForeground(const value : TAnsiColor);
begin
  FCurrentStyle := FCurrentStyle.WithForeground(value);
end;

class function AnsiConsole.GetBackground : TAnsiColor;
begin
  result := FCurrentStyle.Background;
end;

class procedure AnsiConsole.SetBackground(const value : TAnsiColor);
begin
  FCurrentStyle := FCurrentStyle.WithBackground(value);
end;

class function AnsiConsole.GetDecoration : TAnsiDecorations;
begin
  result := FCurrentStyle.Decorations;
end;

class procedure AnsiConsole.SetDecoration(const value : TAnsiDecorations);
begin
  FCurrentStyle := FCurrentStyle.WithDecorations(value);
end;

class procedure AnsiConsole.Write(const renderable : IRenderable);
begin
  GetConsole.Write(renderable);
end;

class procedure AnsiConsole.Write(const value : string);
begin
  // Literal text - no markup parsing. Bracket characters are emitted
  // verbatim. Matches Spectre's AnsiConsole.Write(string). The current
  // style (Foreground/Background/Decoration set on the facade) is applied
  // as the segment style. Routed through the Text widget (rather than a
  // raw segment Write) so the Recorder captures it.
  if value = '' then Exit;
  GetConsole.Write(VSoft.AnsiConsole.Widgets.Text.Text(value, FCurrentStyle));
end;

class procedure AnsiConsole.Write(value : Integer);
begin
  Write(IntToStr(value));
end;

class procedure AnsiConsole.Write(value : Int64);
begin
  Write(IntToStr(value));
end;

class procedure AnsiConsole.Write(value : Double);
begin
  Write(FloatToStr(value));
end;

class procedure AnsiConsole.Write(value : Boolean);
begin
  Write(BoolToStr(value, True));
end;

class procedure AnsiConsole.Write(value : Char);
begin
  Write(string(value));
end;

class procedure AnsiConsole.Write(const fmt : string; const args : array of const);
begin
  Write(Format(fmt, args));
end;

class procedure AnsiConsole.WriteLine;
begin
  GetConsole.WriteLine;
end;

class procedure AnsiConsole.WriteLine(const value : string);
begin
  // Literal text + newline. Honours FCurrentStyle. Routes through the Text
  // widget so the Recorder captures it.
  if value = '' then
  begin
    GetConsole.WriteLine;
    Exit;
  end;
  GetConsole.WriteLine(VSoft.AnsiConsole.Widgets.Text.Text(value, FCurrentStyle));
end;

class procedure AnsiConsole.WriteLine(const renderable : IRenderable);
begin
  GetConsole.WriteLine(renderable);
end;

class procedure AnsiConsole.WriteLine(value : Integer);
begin
  WriteLine(IntToStr(value));
end;

class procedure AnsiConsole.WriteLine(value : Int64);
begin
  WriteLine(IntToStr(value));
end;

class procedure AnsiConsole.WriteLine(value : Double);
begin
  WriteLine(FloatToStr(value));
end;

class procedure AnsiConsole.WriteLine(value : Boolean);
begin
  WriteLine(BoolToStr(value, True));
end;

class procedure AnsiConsole.WriteLine(value : Char);
begin
  WriteLine(string(value));
end;

class procedure AnsiConsole.WriteLine(const fmt : string; const args : array of const);
begin
  WriteLine(Format(fmt, args));
end;

class procedure AnsiConsole.Markup(const value : string);
begin
  // Pass FCurrentStyle as the base style so explicit [tag]...[/] regions
  // override it but unstyled prose inherits the current colour/decoration.
  GetConsole.Write(VSoft.AnsiConsole.Widgets.Markup.Markup(value, FCurrentStyle));
end;

class procedure AnsiConsole.Markup(const fmt : string; const args : array of const);
begin
  GetConsole.Write(VSoft.AnsiConsole.Widgets.Markup.Markup(Format(fmt, args), FCurrentStyle));
end;

class procedure AnsiConsole.MarkupLine(const value : string);
var
  m : IMarkup;
begin
  m := VSoft.AnsiConsole.Widgets.Markup.Markup(value, FCurrentStyle);
  GetConsole.WriteLine(m);
end;

class procedure AnsiConsole.MarkupLine(const fmt : string; const args : array of const);
var
  m : IMarkup;
begin
  m := VSoft.AnsiConsole.Widgets.Markup.Markup(Format(fmt, args), FCurrentStyle);
  GetConsole.WriteLine(m);
end;

class procedure AnsiConsole.Clear;
begin
  GetConsole.Clear(True);
end;

class procedure AnsiConsole.Clear(home : Boolean);
begin
  GetConsole.Clear(home);
end;

class procedure AnsiConsole.HideCursor;
var segs : TAnsiSegments;
begin
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.ControlCode(#27'[?25l');
  GetConsole.Write(segs);
end;

class procedure AnsiConsole.ShowCursor;
var segs : TAnsiSegments;
begin
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.ControlCode(#27'[?25h');
  GetConsole.Write(segs);
end;

class procedure AnsiConsole.ResetColors;
var segs : TAnsiSegments;
begin
  // SGR 39 (default fg) + SGR 49 (default bg). Also clears the cached
  // foreground/background on the facade.
  FCurrentStyle := FCurrentStyle.WithForeground(TAnsiColor.Default)
                                .WithBackground(TAnsiColor.Default);
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.ControlCode(#27'[39;49m');
  GetConsole.Write(segs);
end;

class procedure AnsiConsole.ResetDecoration;
var segs : TAnsiSegments;
begin
  // SGR 22 (normal intensity) + 23 (not italic) + 24 (not underlined) +
  //     25 (not blinking) + 27 (not inverted) + 28 (not concealed) + 29
  //     (not strikethrough). Leaves foreground/background colors alone.
  FCurrentStyle := FCurrentStyle.WithDecorations([]);
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.ControlCode(#27'[22;23;24;25;27;28;29m');
  GetConsole.Write(segs);
end;

class procedure AnsiConsole.Reset;
var segs : TAnsiSegments;
begin
  // SGR 0 = reset everything. Also clears the cached current style.
  FCurrentStyle := TAnsiStyle.Plain;
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.ControlCode(#27'[0m');
  GetConsole.Write(segs);
end;

class procedure AnsiConsole.AlternateScreen(const action : TProc);
var
  enter, leave : TAnsiSegments;
begin
  SetLength(enter, 1);
  enter[0] := TAnsiSegment.ControlCode(#27'[?1049h');
  SetLength(leave, 1);
  leave[0] := TAnsiSegment.ControlCode(#27'[?1049l');
  GetConsole.Write(enter);
  try
    if Assigned(action) then action;
  finally
    GetConsole.Write(leave);
  end;
end;

class procedure AnsiConsole.SetWindowTitle(const title : string);
var
  segs : TAnsiSegments;
begin
  // OSC 0 sets icon name + window title. Terminator BEL (#7) is more
  // widely supported than ST in practice.
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.ControlCode(#27']0;' + title + #7);
  GetConsole.Write(segs);
end;

class procedure AnsiConsole.WriteAnsi(const sequence : string);
var
  segs : TAnsiSegments;
begin
  if sequence = '' then Exit;
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.ControlCode(sequence);
  GetConsole.Write(segs);
end;

class function AnsiConsole.RandomSpinner : ISpinner;
begin
  result := VSoft.AnsiConsole.Live.Spinners.RandomSpinner.Make(
              GetConsole.Profile.Capabilities.Unicode);
end;

class function AnsiConsole.EscapeMarkup(const value : string) : string;
begin
  result := VSoft.AnsiConsole.Widgets.Markup.EscapeMarkup(value);
end;

class function AnsiConsole.Emoji(const shortcode : string) : string;
begin
  result := TEmoji.Get(shortcode);
end;

class function AnsiConsole.Cursor : IAnsiConsoleCursor;
begin
  result := VSoft.AnsiConsole.Cursor.Cursor(GetConsole);
end;

class function AnsiConsole.Profile : IProfile;
begin
  result := GetConsole.Profile;
end;

class procedure AnsiConsole.WriteException(const e : Exception);
begin
  GetConsole.Write(ExceptionWidget(e));
end;

class function AnsiConsole.TextPrompt : ITextPrompt;
begin
  result := VSoft.AnsiConsole.Prompts.Text.TextPrompt;
end;

class function AnsiConsole.ConfirmationPrompt : IConfirmationPrompt;
begin
  result := VSoft.AnsiConsole.Prompts.Confirm.ConfirmationPrompt;
end;

class function AnsiConsole.Ask(const prompt : string) : string;
begin
  result := VSoft.AnsiConsole.Prompts.Text.TextPrompt
              .WithPrompt(prompt)
              .Show(GetConsole);
end;

class function AnsiConsole.Ask(const prompt, default_ : string) : string;
begin
  result := VSoft.AnsiConsole.Prompts.Text.TextPrompt
              .WithPrompt(prompt)
              .WithDefault(default_)
              .Show(GetConsole);
end;

class function AnsiConsole.Confirm(const prompt : string) : Boolean;
begin
  result := Confirm(prompt, True);
end;

class function AnsiConsole.Confirm(const prompt : string; default_ : Boolean) : Boolean;
begin
  result := VSoft.AnsiConsole.Prompts.Confirm.ConfirmationPrompt
              .WithPrompt(prompt)
              .WithDefault(default_)
              .Show(GetConsole);
end;

class function AnsiConsole.SelectionPrompt<T> : ISelectionPrompt<T>;
begin
  result := VSoft.AnsiConsole.Prompts.Select.SelectionPrompt<T>.Create;
end;

class function AnsiConsole.MultiSelectionPrompt<T> : IMultiSelectionPrompt<T>;
begin
  result := VSoft.AnsiConsole.Prompts.MultiSelect.MultiSelectionPrompt<T>.Create;
end;

class function AnsiConsole.Ask<T>(const prompt : string) : T;
begin
  result := VSoft.AnsiConsole.Prompts.Text.Generic.TextPrompt<T>.Create
              .WithPrompt(prompt)
              .Show(GetConsole);
end;

class function AnsiConsole.Ask<T>(const prompt : string; const default_ : T) : T;
begin
  result := VSoft.AnsiConsole.Prompts.Text.Generic.TextPrompt<T>.Create
              .WithPrompt(prompt)
              .WithDefault(default_)
              .Show(GetConsole);
end;

class function AnsiConsole.Prompt(const prompt : ITextPrompt) : string;
begin
  if prompt = nil then
    raise Exception.Create('AnsiConsole.Prompt: prompt argument must not be nil');
  result := prompt.Show(GetConsole);
end;

class function AnsiConsole.Prompt(const prompt : IConfirmationPrompt) : Boolean;
begin
  if prompt = nil then
    raise Exception.Create('AnsiConsole.Prompt: prompt argument must not be nil');
  result := prompt.Show(GetConsole);
end;

class function AnsiConsole.Prompt<T>(const prompt : ITextPrompt<T>) : T;
begin
  if prompt = nil then
    raise Exception.Create('AnsiConsole.Prompt: prompt argument must not be nil');
  result := prompt.Show(GetConsole);
end;

class function AnsiConsole.Prompt<T>(const prompt : ISelectionPrompt<T>) : T;
begin
  if prompt = nil then
    raise Exception.Create('AnsiConsole.Prompt: prompt argument must not be nil');
  result := prompt.Show(GetConsole);
end;

class function AnsiConsole.Prompt<T>(const prompt : IMultiSelectionPrompt<T>) : TArray<T>;
begin
  if prompt = nil then
    raise Exception.Create('AnsiConsole.Prompt: prompt argument must not be nil');
  result := prompt.Show(GetConsole);
end;

class function AnsiConsole.Live(const initial : IRenderable) : ILiveDisplayConfig;
begin
  result := VSoft.AnsiConsole.Live.Display.LiveDisplay(GetConsole, initial);
end;

class function AnsiConsole.Status : IStatusConfig;
begin
  result := VSoft.AnsiConsole.Live.Status.Status(GetConsole);
end;

class function AnsiConsole.Status(const console : IAnsiConsole) : IStatusConfig;
begin
  if console = nil then
    raise Exception.Create('AnsiConsole.Status: console must not be nil');
  result := VSoft.AnsiConsole.Live.Status.Status(console);
end;

class function AnsiConsole.LiveDisplay(const initial : IRenderable) : ILiveDisplayConfig;
begin
  result := VSoft.AnsiConsole.Live.Display.LiveDisplay(GetConsole, initial);
end;

class function AnsiConsole.LiveDisplay(const console : IAnsiConsole; const initial : IRenderable) : ILiveDisplayConfig;
begin
  if console = nil then
    raise Exception.Create('AnsiConsole.LiveDisplay: console must not be nil');
  result := VSoft.AnsiConsole.Live.Display.LiveDisplay(console, initial);
end;

class function AnsiConsole.Progress : IProgressConfig;
begin
  result := VSoft.AnsiConsole.Live.Progress.Progress(GetConsole);
end;

class function AnsiConsole.Progress(const console : IAnsiConsole) : IProgressConfig;
begin
  if console = nil then
    raise Exception.Create('AnsiConsole.Progress: console must not be nil');
  result := VSoft.AnsiConsole.Live.Progress.Progress(console);
end;

class function AnsiConsole.Recorder(const inner : IAnsiConsole) : IRecorder;
begin
  if inner <> nil then
    result := VSoft.AnsiConsole.Recorder.Recorder(inner)
  else
    result := VSoft.AnsiConsole.Recorder.Recorder(GetConsole);
end;

class procedure AnsiConsole.StartRecording;
begin
  FLock.Enter;
  try
    if FRecorder <> nil then Exit;   // already recording
    FRecordingPrevious := FConsole;
    FRecorder := VSoft.AnsiConsole.Recorder.Recorder(GetConsole);
    FConsole  := FRecorder;
  finally
    FLock.Leave;
  end;
end;

class procedure AnsiConsole.StopRecording;
begin
  FLock.Enter;
  try
    if FRecorder = nil then Exit;
    FConsole := FRecordingPrevious;
    FRecordingPrevious := nil;
    FRecorder := nil;
  finally
    FLock.Leave;
  end;
end;

class function AnsiConsole.ExportText : string;
begin
  if FRecorder = nil then
    raise Exception.Create('AnsiConsole.ExportText: no active recording. ' +
      'Call StartRecording first.');
  result := FRecorder.ExportText;
end;

class function AnsiConsole.ExportHtml : string;
begin
  if FRecorder = nil then
    raise Exception.Create('AnsiConsole.ExportHtml: no active recording. ' +
      'Call StartRecording first.');
  result := FRecorder.ExportHtml;
end;

class function AnsiConsole.ExportCustom(const encoder : IAnsiConsoleEncoder) : string;
begin
  if FRecorder = nil then
    raise Exception.Create('AnsiConsole.ExportCustom: no active recording. ' +
      'Call StartRecording first.');
  result := FRecorder.Export(encoder);
end;

{ Widgets - one-line delegates to the matching free factory in each
  widget/border/live unit. Free function names are fully-qualified to
  avoid the class-method-shadows-free-function recursion. }

class function Widgets.Text(const value : string) : IText;
begin
  result := VSoft.AnsiConsole.Widgets.Text.Text(value);
end;

class function Widgets.Text(const value : string; const style : TAnsiStyle) : IText;
begin
  result := VSoft.AnsiConsole.Widgets.Text.Text(value, style);
end;

class function Widgets.Markup(const value : string) : IMarkup;
begin
  result := VSoft.AnsiConsole.Widgets.Markup.Markup(value);
end;

class function Widgets.Markup(const value : string; const baseStyle : TAnsiStyle) : IMarkup;
begin
  result := VSoft.AnsiConsole.Widgets.Markup.Markup(value, baseStyle);
end;

class function Widgets.Rule : IRule;
begin
  result := VSoft.AnsiConsole.Widgets.Rule.Rule;
end;

class function Widgets.Rule(const title : string) : IRule;
begin
  result := VSoft.AnsiConsole.Widgets.Rule.Rule(title);
end;

class function Widgets.Paragraph : IParagraph;
begin
  result := VSoft.AnsiConsole.Widgets.Paragraph.Paragraph;
end;

class function Widgets.Paragraph(const text : string) : IParagraph;
begin
  result := VSoft.AnsiConsole.Widgets.Paragraph.Paragraph(text);
end;

class function Widgets.Paragraph(const text : string; const style : TAnsiStyle) : IParagraph;
begin
  result := VSoft.AnsiConsole.Widgets.Paragraph.Paragraph(text, style);
end;

class function Widgets.Padder(const child : IRenderable) : IPadder;
begin
  result := VSoft.AnsiConsole.Widgets.Padder.Padder(child);
end;

class function Widgets.Align(const child : IRenderable; alignment : TAlignment) : IAlign;
begin
  result := VSoft.AnsiConsole.Widgets.Align.Align(child, alignment);
end;

class function Widgets.Rows : IRows;
begin
  result := VSoft.AnsiConsole.Widgets.Rows.Rows;
end;

class function Widgets.Columns : IColumns;
begin
  result := VSoft.AnsiConsole.Widgets.Columns.Columns;
end;

class function Widgets.Grid : IGrid;
begin
  result := VSoft.AnsiConsole.Widgets.Grid.Grid;
end;

class function Widgets.Panel(const child : IRenderable) : IPanel;
begin
  result := VSoft.AnsiConsole.Widgets.Panel.Panel(child);
end;

class function Widgets.Panel(const markup : string) : IPanel;
begin
  result := VSoft.AnsiConsole.Widgets.Panel.Panel(
              VSoft.AnsiConsole.Widgets.Markup.Markup(markup));
end;

class function Widgets.Table : ITable;
begin
  result := VSoft.AnsiConsole.Widgets.Table.Table;
end;

class function Widgets.TableTitle(const text : string) : ITableTitle;
begin
  result := VSoft.AnsiConsole.Widgets.Table.TableTitle(text);
end;

class function Widgets.TableCell(const text : string) : ITableCell;
begin
  result := VSoft.AnsiConsole.Widgets.Table.TableCell(text);
end;

class function Widgets.TableCell(const content : IRenderable) : ITableCell;
begin
  result := VSoft.AnsiConsole.Widgets.Table.TableCell(content);
end;

class function Widgets.Tree(const root : IRenderable) : ITree;
begin
  result := VSoft.AnsiConsole.Widgets.Tree.Tree(root);
end;

class function Widgets.Tree(const rootMarkup : string) : ITree;
begin
  result := VSoft.AnsiConsole.Widgets.Tree.Tree(rootMarkup);
end;

class function Widgets.BoxBorder(kind : TBoxBorderKind) : IBoxBorder;
begin
  result := VSoft.AnsiConsole.Borders.Box.BoxBorder(kind);
end;

class function Widgets.TableBorder(kind : TTableBorderKind) : ITableBorder;
begin
  result := VSoft.AnsiConsole.Borders.Table.TableBorder(kind);
end;

class function Widgets.TreeGuide(kind : TTreeGuideKind) : ITreeGuide;
begin
  result := VSoft.AnsiConsole.Borders.Tree.TreeGuide(kind);
end;

class function Widgets.Canvas(width, height : Integer) : ICanvas;
begin
  result := VSoft.AnsiConsole.Widgets.Canvas.Canvas(width, height);
end;

class function Widgets.BarChart : IBarChart;
begin
  result := VSoft.AnsiConsole.Widgets.BarChart.BarChart;
end;

class function Widgets.BreakdownChart : IBreakdownChart;
begin
  result := VSoft.AnsiConsole.Widgets.BreakdownChart.BreakdownChart;
end;

class function Widgets.Calendar(year, month : Integer) : ICalendar;
begin
  result := VSoft.AnsiConsole.Widgets.Calendar.Calendar(year, month);
end;

class function Widgets.Calendar(year, month, day : Integer) : ICalendar;
begin
  result := VSoft.AnsiConsole.Widgets.Calendar.Calendar(year, month, day);
end;

class function Widgets.Calendar(const date : TDateTime) : ICalendar;
begin
  result := VSoft.AnsiConsole.Widgets.Calendar.Calendar(date);
end;

class function Widgets.TextPath(const path : string) : ITextPath;
begin
  result := VSoft.AnsiConsole.Widgets.TextPath.TextPath(path);
end;

class function Widgets.Layout : ILayout;
begin
  result := VSoft.AnsiConsole.Widgets.Layout.Layout;
end;

class function Widgets.Layout(const name : string) : ILayout;
begin
  result := VSoft.AnsiConsole.Widgets.Layout.Layout(name);
end;

class function Widgets.FigletText(const text : string) : IFigletText;
begin
  result := VSoft.AnsiConsole.Widgets.Figlet.FigletText(text);
end;

class function Widgets.Json(const source : string) : IJsonText;
begin
  result := VSoft.AnsiConsole.Widgets.Json.Json(source);
end;

class function Widgets.ExceptionWidget(const e : Exception) : IExceptionWidget;
begin
  result := VSoft.AnsiConsole.Widgets.Exception.ExceptionWidget(e);
end;

class function Widgets.ExceptionWidget(const className, message : string) : IExceptionWidget;
begin
  result := VSoft.AnsiConsole.Widgets.Exception.ExceptionWidget(className, message);
end;

class function Widgets.ExceptionStyle : IExceptionStyle;
begin
  result := VSoft.AnsiConsole.Widgets.Exception.ExceptionStyle;
end;

class function Widgets.Spinner(kind : TSpinnerKind) : ISpinner;
begin
  result := VSoft.AnsiConsole.Live.Spinners.Spinner(kind, True);
end;

class function Widgets.Spinner(kind : TSpinnerKind; unicode : Boolean) : ISpinner;
begin
  result := VSoft.AnsiConsole.Live.Spinners.Spinner(kind, unicode);
end;

class function Widgets.Spinner(const frames : TArray<string>; intervalMs : Integer) : ISpinner;
begin
  result := VSoft.AnsiConsole.Live.Spinners.Spinner(frames, intervalMs);
end;

class function Widgets.DescriptionColumn : IDescriptionColumn;
begin
  result := VSoft.AnsiConsole.Live.Progress.DescriptionColumn;
end;

class function Widgets.ProgressBarColumn : IProgressBarColumn;
begin
  result := VSoft.AnsiConsole.Live.Progress.ProgressBarColumn;
end;

class function Widgets.ProgressBarColumn(width : Integer) : IProgressBarColumn;
begin
  result := VSoft.AnsiConsole.Live.Progress.ProgressBarColumn(width);
end;

class function Widgets.PercentageColumn : IPercentageColumn;
begin
  result := VSoft.AnsiConsole.Live.Progress.PercentageColumn;
end;

class function Widgets.ElapsedColumn : IElapsedColumn;
begin
  result := VSoft.AnsiConsole.Live.Progress.ElapsedColumn;
end;

class function Widgets.RemainingTimeColumn : IRemainingTimeColumn;
begin
  result := VSoft.AnsiConsole.Live.Progress.RemainingTimeColumn;
end;

class function Widgets.SpinnerColumn : ISpinnerColumn;
begin
  result := VSoft.AnsiConsole.Live.Progress.SpinnerColumn;
end;

class function Widgets.SpinnerColumn(kind : TSpinnerKind) : ISpinnerColumn;
begin
  result := VSoft.AnsiConsole.Live.Progress.SpinnerColumn(kind);
end;

class function Widgets.DownloadedColumn : IDownloadedColumn;
begin
  result := VSoft.AnsiConsole.Live.Progress.DownloadedColumn;
end;

class function Widgets.TransferSpeedColumn : ITransferSpeedColumn;
begin
  result := VSoft.AnsiConsole.Live.Progress.TransferSpeedColumn;
end;

end.
