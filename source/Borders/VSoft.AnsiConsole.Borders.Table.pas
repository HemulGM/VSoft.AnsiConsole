unit VSoft.AnsiConsole.Borders.Table;

{
  Table border glyph set.

  Parts (left-to-right, top-to-bottom):

    TTableBorderPart.TopLeft   TTableBorderPart.Top   TTableBorderPart.TopMid    TTableBorderPart.Top   TTableBorderPart.TopRight
    TTableBorderPart.CellLeft          TTableBorderPart.CellMid           TTableBorderPart.CellRight         <- header row
    TTableBorderPart.HeadLeft  TTableBorderPart.Head  TTableBorderPart.HeadMid   TTableBorderPart.Head  TTableBorderPart.HeadRight          <- header separator
    TTableBorderPart.CellLeft          TTableBorderPart.CellMid           TTableBorderPart.CellRight         <- data rows (vertical separators only)
    TTableBorderPart.BottomLeft TTableBorderPart.Bottom TTableBorderPart.BottomMid TTableBorderPart.Bottom TTableBorderPart.BottomRight    <- bottom edge

  Phase 3 doesn't emit inter-row horizontal separators, so we don't need a
  middle-separator set; if we add it in a later phase the enum can grow
  without breaking the existing borders.
}

{$SCOPEDENUMS ON}

interface

type
  TTableBorderPart = (
    TopLeft,    Top,    TopMid,    TopRight,
    CellLeft,           CellMid,   CellRight,
    HeadLeft,   Head,   HeadMid,   HeadRight,
    BottomLeft, Bottom, BottomMid, BottomRight
  );

  TTableBorderKind = (
    None,             // whitespace - columns sit in plain text
    Ascii,            // +, -, |
    Ascii2,           // ascii with cell verticals on header sides
    AsciiDoubleHead,  // ascii with `=` in the header separator
    Square,           // ─ │ ┌ etc (default)
    Rounded,          // like square but rounded corners
    Heavy,            // ━ ┃ ┏ ...
    HeavyEdge,        // heavy outer edges + light inner separators
    HeavyHead,        // heavy top + heavy header separator, light elsewhere
    Double,           // ═ ║ ╔ ...
    DoubleEdge,       // double outer edges + light inner separators
    Minimal,          // only the cell vertical and the header separator
    MinimalHeavyHead, // minimal with a heavy header separator
    MinimalDoubleHead,// minimal with a double header separator
    Simple,           // only the header separator dashes; no verticals
    SimpleHeavy,      // simple but with heavy header separator
    Horizontal,       // dashes for every horizontal line, no verticals
    Minimalist,       // header underline + space cell separator only
    Markdown          // pipes + dashes, GitHub-compatible
  );

  ITableBorder = interface
    ['{A91B5A3F-7F39-4F29-9FBE-5C5D6A7C6C31}']
    function GetPart(part : TTableBorderPart; unicode : Boolean) : Char;
    function Kind : TTableBorderKind;
  end;

function TableBorder(kind : TTableBorderKind) : ITableBorder;

implementation

type
  TTableGlyphs = array[TTableBorderPart] of Char;

  TTableBorderImpl = class(TInterfacedObject, ITableBorder)
  strict private
    FKind    : TTableBorderKind;
    FUnicode : TTableGlyphs;
    FAscii   : TTableGlyphs;
  public
    constructor Create(kind : TTableBorderKind;
                        const unicodeGlyphs : TTableGlyphs;
                        const asciiGlyphs   : TTableGlyphs);
    function GetPart(part : TTableBorderPart; unicode : Boolean) : Char;
    function Kind : TTableBorderKind;
  end;

constructor TTableBorderImpl.Create(kind : TTableBorderKind;
                                      const unicodeGlyphs : TTableGlyphs;
                                      const asciiGlyphs   : TTableGlyphs);
begin
  inherited Create;
  FKind := kind;
  FUnicode := unicodeGlyphs;
  FAscii := asciiGlyphs;
end;

function TTableBorderImpl.GetPart(part : TTableBorderPart; unicode : Boolean) : Char;
begin
  if unicode and (FKind <> TTableBorderKind.Ascii) and (FKind <> TTableBorderKind.Markdown) then
    result := FUnicode[part]
  else
    result := FAscii[part];
end;

function TTableBorderImpl.Kind : TTableBorderKind;
begin
  result := FKind;
end;

function Make(topL, top, topM, topR,
              cellL, cellM, cellR,
              headL, head, headM, headR,
              botL, bot, botM, botR : Char) : TTableGlyphs;
begin
  result[TTableBorderPart.TopLeft]     := topL;
  result[TTableBorderPart.Top]         := top;
  result[TTableBorderPart.TopMid]      := topM;
  result[TTableBorderPart.TopRight]    := topR;
  result[TTableBorderPart.CellLeft]    := cellL;
  result[TTableBorderPart.CellMid]     := cellM;
  result[TTableBorderPart.CellRight]   := cellR;
  result[TTableBorderPart.HeadLeft]    := headL;
  result[TTableBorderPart.Head]        := head;
  result[TTableBorderPart.HeadMid]     := headM;
  result[TTableBorderPart.HeadRight]   := headR;
  result[TTableBorderPart.BottomLeft]  := botL;
  result[TTableBorderPart.Bottom]      := bot;
  result[TTableBorderPart.BottomMid]   := botM;
  result[TTableBorderPart.BottomRight] := botR;
end;

function NoneGlyphs : TTableGlyphs;
begin
  result := Make(' ', ' ', ' ', ' ',
                 ' ', ' ', ' ',
                 ' ', ' ', ' ', ' ',
                 ' ', ' ', ' ', ' ');
end;

function AsciiGlyphs : TTableGlyphs;
begin
  result := Make('+', '-', '+', '+',
                 '|', '|', '|',
                 '+', '-', '+', '+',
                 '+', '-', '+', '+');
end;

function MarkdownGlyphs : TTableGlyphs;
begin
  // top + bottom edges use spaces so typical markdown output is just the
  // header row, the '---' separator, and the body rows.
  result := Make(' ', ' ', ' ', ' ',
                 '|', '|', '|',
                 '|', '-', '|', '|',
                 ' ', ' ', ' ', ' ');
end;

function SquareGlyphs : TTableGlyphs;
begin
  result := Make(#$250C, #$2500, #$252C, #$2510,   //  ┌ ─ ┬ ┐
                 #$2502, #$2502, #$2502,            //  │ │ │
                 #$251C, #$2500, #$253C, #$2524,    //  ├ ─ ┼ ┤
                 #$2514, #$2500, #$2534, #$2518);   //  └ ─ ┴ ┘
end;

function RoundedGlyphs : TTableGlyphs;
begin
  result := Make(#$256D, #$2500, #$252C, #$256E,   //  ╭ ─ ┬ ╮
                 #$2502, #$2502, #$2502,
                 #$251C, #$2500, #$253C, #$2524,
                 #$2570, #$2500, #$2534, #$256F);   //  ╰ ─ ┴ ╯
end;

function HeavyGlyphs : TTableGlyphs;
begin
  result := Make(#$250F, #$2501, #$2533, #$2513,   //  ┏ ━ ┳ ┓
                 #$2503, #$2503, #$2503,
                 #$2523, #$2501, #$254B, #$252B,   //  ┣ ━ ╋ ┫
                 #$2517, #$2501, #$253B, #$251B);   //  ┗ ━ ┻ ┛
end;

function DoubleGlyphs : TTableGlyphs;
begin
  result := Make(#$2554, #$2550, #$2566, #$2557,   //  ╔ ═ ╦ ╗
                 #$2551, #$2551, #$2551,
                 #$2560, #$2550, #$256C, #$2563,   //  ╠ ═ ╬ ╣
                 #$255A, #$2550, #$2569, #$255D);   //  ╚ ═ ╩ ╝
end;

function Ascii2Glyphs : TTableGlyphs;
begin
  // Like Ascii, but the header separator's outer edges are '|' instead of '+'.
  result := Make('+', '-', '+', '+',
                 '|', '|', '|',
                 '|', '-', '+', '|',
                 '+', '-', '+', '+');
end;

function AsciiDoubleHeadGlyphs : TTableGlyphs;
begin
  // Ascii with `=` in the header separator row.
  result := Make('+', '-', '+', '+',
                 '|', '|', '|',
                 '|', '=', '+', '|',
                 '+', '-', '+', '+');
end;

function HeavyEdgeGlyphs : TTableGlyphs;
begin
  // Heavy outer frame, light inner column separators.
  result := Make(#$250F, #$2501, #$252F, #$2513,   //  ┏ ━ ┯ ┓
                 #$2503, #$2502, #$2503,            //  ┃ │ ┃
                 #$2520, #$2500, #$253C, #$2528,    //  ┠ ─ ┼ ┨
                 #$2517, #$2501, #$2537, #$251B);   //  ┗ ━ ┷ ┛
end;

function HeavyHeadGlyphs : TTableGlyphs;
begin
  // Heavy top + heavy header separator, light cell verticals + bottom.
  result := Make(#$250F, #$2501, #$2533, #$2513,   //  ┏ ━ ┳ ┓
                 #$2502, #$2502, #$2502,            //  │ │ │
                 #$2521, #$2501, #$2547, #$2529,    //  ┡ ━ ╇ ┩
                 #$2514, #$2500, #$2534, #$2518);   //  └ ─ ┴ ┘
end;

function DoubleEdgeGlyphs : TTableGlyphs;
begin
  // Double outer frame, light inner column separators.
  result := Make(#$2554, #$2550, #$2564, #$2557,   //  ╔ ═ ╤ ╗
                 #$2551, #$2502, #$2551,            //  ║ │ ║
                 #$255F, #$2500, #$253C, #$2562,    //  ╟ ─ ┼ ╢
                 #$255A, #$2550, #$2567, #$255D);   //  ╚ ═ ╧ ╝
end;

function MinimalGlyphs : TTableGlyphs;
begin
  // Only the cell vertical and the header underline; no outer frame.
  result := Make(' ', ' ', ' ', ' ',
                 ' ', #$2502, ' ',                  //    │
                 ' ', #$2500, #$253C, ' ',          //    ─ ┼
                 ' ', ' ', ' ', ' ');
end;

function MinimalHeavyHeadGlyphs : TTableGlyphs;
begin
  result := Make(' ', ' ', ' ', ' ',
                 ' ', #$2502, ' ',                  //    │
                 ' ', #$2501, #$253F, ' ',          //    ━ ┿
                 ' ', ' ', ' ', ' ');
end;

function MinimalDoubleHeadGlyphs : TTableGlyphs;
begin
  result := Make(' ', ' ', ' ', ' ',
                 ' ', #$2502, ' ',                  //    │
                 ' ', #$2550, #$256A, ' ',          //    ═ ╪
                 ' ', ' ', ' ', ' ');
end;

function SimpleGlyphs : TTableGlyphs;
begin
  // Only the header underline; no verticals at all.
  result := Make(' ', ' ', ' ', ' ',
                 ' ', ' ', ' ',
                 #$2500, #$2500, #$2500, #$2500,    //  ─ ─ ─ ─
                 ' ', ' ', ' ', ' ');
end;

function SimpleHeavyGlyphs : TTableGlyphs;
begin
  result := Make(' ', ' ', ' ', ' ',
                 ' ', ' ', ' ',
                 #$2501, #$2501, #$2501, #$2501,    //  ━ ━ ━ ━
                 ' ', ' ', ' ', ' ');
end;

function HorizontalGlyphs : TTableGlyphs;
begin
  // Dashes on every horizontal line, no vertical separators.
  result := Make(#$2500, #$2500, #$2500, #$2500,    //  top edge
                 ' ', ' ', ' ',
                 #$2500, #$2500, #$2500, #$2500,    //  header sep
                 #$2500, #$2500, #$2500, #$2500);   //  bottom edge
end;

function MinimalistGlyphs : TTableGlyphs;
begin
  // Header underline + plain-space column separator, no left/right edges.
  result := Make(' ', ' ', ' ', ' ',
                 ' ', ' ', ' ',
                 ' ', #$2500, #$2500, ' ',          //  ─ ─
                 ' ', ' ', ' ', ' ');
end;

function TableBorder(kind : TTableBorderKind) : ITableBorder;
var
  ascii : TTableGlyphs;
begin
  ascii := AsciiGlyphs;
  case kind of
    TTableBorderKind.None              : result := TTableBorderImpl.Create(kind, NoneGlyphs,              NoneGlyphs);
    TTableBorderKind.Ascii             : result := TTableBorderImpl.Create(kind, ascii,                   ascii);
    TTableBorderKind.Ascii2            : result := TTableBorderImpl.Create(kind, Ascii2Glyphs,            Ascii2Glyphs);
    TTableBorderKind.AsciiDoubleHead   : result := TTableBorderImpl.Create(kind, AsciiDoubleHeadGlyphs,   AsciiDoubleHeadGlyphs);
    TTableBorderKind.Markdown          : result := TTableBorderImpl.Create(kind, MarkdownGlyphs,          MarkdownGlyphs);
    TTableBorderKind.Rounded           : result := TTableBorderImpl.Create(kind, RoundedGlyphs,           ascii);
    TTableBorderKind.Heavy             : result := TTableBorderImpl.Create(kind, HeavyGlyphs,             ascii);
    TTableBorderKind.HeavyEdge         : result := TTableBorderImpl.Create(kind, HeavyEdgeGlyphs,         ascii);
    TTableBorderKind.HeavyHead         : result := TTableBorderImpl.Create(kind, HeavyHeadGlyphs,         ascii);
    TTableBorderKind.Double            : result := TTableBorderImpl.Create(kind, DoubleGlyphs,            ascii);
    TTableBorderKind.DoubleEdge        : result := TTableBorderImpl.Create(kind, DoubleEdgeGlyphs,        ascii);
    TTableBorderKind.Minimal           : result := TTableBorderImpl.Create(kind, MinimalGlyphs,           ascii);
    TTableBorderKind.MinimalHeavyHead  : result := TTableBorderImpl.Create(kind, MinimalHeavyHeadGlyphs,  ascii);
    TTableBorderKind.MinimalDoubleHead : result := TTableBorderImpl.Create(kind, MinimalDoubleHeadGlyphs, ascii);
    TTableBorderKind.Simple            : result := TTableBorderImpl.Create(kind, SimpleGlyphs,            ascii);
    TTableBorderKind.SimpleHeavy       : result := TTableBorderImpl.Create(kind, SimpleHeavyGlyphs,       ascii);
    TTableBorderKind.Horizontal        : result := TTableBorderImpl.Create(kind, HorizontalGlyphs,        ascii);
    TTableBorderKind.Minimalist        : result := TTableBorderImpl.Create(kind, MinimalistGlyphs,        ascii);
  else
    result := TTableBorderImpl.Create(TTableBorderKind.Square, SquareGlyphs, ascii);
  end;
end;

end.
