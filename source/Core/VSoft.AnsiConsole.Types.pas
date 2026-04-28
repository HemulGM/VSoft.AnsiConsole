unit VSoft.AnsiConsole.Types;

{
  Common enumerations and sets used across VSoft.AnsiConsole.
  This unit has no dependencies on other VSoft.AnsiConsole units.
}

{$SCOPEDENUMS ON}

interface

type
  { Text decorations, mapped to SGR codes 1-9. }
  TAnsiDecoration = (
    Bold,          // SGR 1
    Dim,           // SGR 2
    Italic,        // SGR 3
    Underline,     // SGR 4
    SlowBlink,     // SGR 5
    RapidBlink,    // SGR 6
    Invert,        // SGR 7 (swap FG/BG)
    Conceal,       // SGR 8
    Strikethrough  // SGR 9
  );
  TAnsiDecorations = set of TAnsiDecoration;

  { Color depth supported by the terminal. Ordered from least to most capable. }
  TColorSystem = (
    NoColors,   // monochrome
    Legacy,     // 8 colors  (SGR 30-37 / 40-47)
    Standard,   // 16 colors (adds SGR 90-97 / 100-107)
    EightBit,   // 256 colors (SGR 38;5;n / 48;5;n)
    TrueColor   // 16M colors (SGR 38;2;r;g;b / 48;2;r;g;b)
  );

  { Whether ANSI escape emission is enabled. }
  TAnsiSupport = (Detect, On, Off);

  { Color system preference/override. }
  TColorSystemSupport = (
    Detect,
    NoColors,
    Legacy,
    Standard,
    EightBit,
    TrueColor
  );

  { Whether stdin is treated as interactive (supports prompts, live redraw). }
  TInteractionSupport = (Detect, On, Off);

  { Horizontal alignment inside a fixed-width box. }
  TAlignment = (Left, Center, Right);

  { Vertical alignment inside a fixed-height box. }
  TVerticalAlignment = (Top, Middle, Bottom);

  { Justification mode for wrapped paragraphs. }
  TJustify = (Left, Center, Right, Full);

  { How to handle content that exceeds available width. }
  TOverflow = (Fold, Crop, Ellipsis);

  { Segment metadata flags. }
  TAnsiSegmentFlag = (
    LineBreak,    // segment is an explicit newline
    Whitespace,   // segment holds inter-word whitespace (preserved but trimmable)
    ControlCode   // segment text is raw ANSI and must not be wrapped in SGR
  );
  TAnsiSegmentFlags = set of TAnsiSegmentFlag;

implementation

end.
