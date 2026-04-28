unit VSoft.AnsiConsole.Borders.Box;

{
  Box-drawing border set. A box border supplies the characters for:

    TL -- T -- TR
    |           |
    L          R
    |           |
    BL -- B -- BR

  plus HeaderLeft / HeaderRight - the characters that sit to the immediate
  left and right of a panel's inset header text (or '|' / '|' by default so
  the header text sits inline on the top border).

  Every border has a unicode form and an ASCII fallback (used when the
  terminal is not capable of wide drawing characters).
}

{$SCOPEDENUMS ON}

interface

type
  TBoxBorderPart = (
    TopLeft, Top, TopRight,
    Left, Right,
    BottomLeft, Bottom, BottomRight,
    HeaderLeft, HeaderRight
  );

  TBoxBorderKind = (Square, Rounded, Heavy, Double, Ascii, None);

  IBoxBorder = interface
    ['{6B09B0D9-2C84-4C8A-9123-69B2A86E5E21}']
    function GetPart(part : TBoxBorderPart; unicode : Boolean) : Char;
    function Kind : TBoxBorderKind;
  end;

function BoxBorder(kind : TBoxBorderKind) : IBoxBorder;

implementation

type
  TBorderGlyphs = array[TBoxBorderPart] of Char;

  TBoxBorderImpl = class(TInterfacedObject, IBoxBorder)
  strict private
    FKind    : TBoxBorderKind;
    FUnicode : TBorderGlyphs;
    FAscii   : TBorderGlyphs;
  public
    constructor Create(kind : TBoxBorderKind;
                       const unicodeGlyphs : TBorderGlyphs;
                       const asciiGlyphs   : TBorderGlyphs);
    function GetPart(part : TBoxBorderPart; unicode : Boolean) : Char;
    function Kind : TBoxBorderKind;
  end;

constructor TBoxBorderImpl.Create(kind : TBoxBorderKind;
                                   const unicodeGlyphs : TBorderGlyphs;
                                   const asciiGlyphs   : TBorderGlyphs);
begin
  inherited Create;
  FKind    := kind;
  FUnicode := unicodeGlyphs;
  FAscii   := asciiGlyphs;
end;

function TBoxBorderImpl.GetPart(part : TBoxBorderPart; unicode : Boolean) : Char;
begin
  if unicode and (FKind <> TBoxBorderKind.Ascii) then
    result := FUnicode[part]
  else
    result := FAscii[part];
end;

function TBoxBorderImpl.Kind : TBoxBorderKind;
begin
  result := FKind;
end;

function MakeGlyphs(tl, t, tr, l, r, bl, b, br, hl, hr : Char) : TBorderGlyphs;
begin
  result[TBoxBorderPart.TopLeft]      := tl;
  result[TBoxBorderPart.Top]          := t;
  result[TBoxBorderPart.TopRight]     := tr;
  result[TBoxBorderPart.Left]         := l;
  result[TBoxBorderPart.Right]        := r;
  result[TBoxBorderPart.BottomLeft]   := bl;
  result[TBoxBorderPart.Bottom]       := b;
  result[TBoxBorderPart.BottomRight]  := br;
  result[TBoxBorderPart.HeaderLeft]   := hl;
  result[TBoxBorderPart.HeaderRight]  := hr;
end;

function AsciiGlyphs : TBorderGlyphs;
begin
  result := MakeGlyphs('+', '-', '+',
                       '|',      '|',
                       '+', '-', '+',
                       '|', '|');
end;

function NoneGlyphs : TBorderGlyphs;
begin
  result := MakeGlyphs(' ', ' ', ' ',
                       ' ',      ' ',
                       ' ', ' ', ' ',
                       ' ', ' ');
end;

function SquareGlyphs : TBorderGlyphs;
begin
  result := MakeGlyphs(#$250C, #$2500, #$2510,
                       #$2502,         #$2502,
                       #$2514, #$2500, #$2518,
                       #$2524, #$251C);
end;

function RoundedGlyphs : TBorderGlyphs;
begin
  result := MakeGlyphs(#$256D, #$2500, #$256E,
                       #$2502,         #$2502,
                       #$2570, #$2500, #$256F,
                       #$2524, #$251C);
end;

function HeavyGlyphs : TBorderGlyphs;
begin
  result := MakeGlyphs(#$250F, #$2501, #$2513,
                       #$2503,         #$2503,
                       #$2517, #$2501, #$251B,
                       #$252B, #$2523);
end;

function DoubleGlyphs : TBorderGlyphs;
begin
  result := MakeGlyphs(#$2554, #$2550, #$2557,
                       #$2551,         #$2551,
                       #$255A, #$2550, #$255D,
                       #$2563, #$2560);
end;

function BoxBorder(kind : TBoxBorderKind) : IBoxBorder;
var
  ascii : TBorderGlyphs;
begin
  ascii := AsciiGlyphs;
  case kind of
    TBoxBorderKind.Ascii   : result := TBoxBorderImpl.Create(kind, ascii,          ascii);
    TBoxBorderKind.Rounded : result := TBoxBorderImpl.Create(kind, RoundedGlyphs,  ascii);
    TBoxBorderKind.Heavy   : result := TBoxBorderImpl.Create(kind, HeavyGlyphs,    ascii);
    TBoxBorderKind.Double  : result := TBoxBorderImpl.Create(kind, DoubleGlyphs,   ascii);
    TBoxBorderKind.None    : result := TBoxBorderImpl.Create(kind, NoneGlyphs,     NoneGlyphs);
  else
    result := TBoxBorderImpl.Create(TBoxBorderKind.Square, SquareGlyphs, ascii);
  end;
end;

end.
