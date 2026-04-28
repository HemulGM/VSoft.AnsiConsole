unit VSoft.AnsiConsole.Borders.Tree;

{
  Tree guide glyph set. A tree prefix at depth N is constructed from:

    [continuation or space] [continuation or space] ... [fork or last]--

  where each depth slot is either a "vertical continues" char (an ancestor
  is not the last child at its level) or a blank (an ancestor IS the last
  child). The terminating slot picks fork/last depending on whether the
  current node is the last sibling, followed by two horizontals and a space.
}

{$SCOPEDENUMS ON}

interface

type
  TTreeGuidePart = (
    Space,       // ' '
    Continue,    // vertical line
    Fork,        // branch with more siblings below
    Last,        // last branch
    Horizontal   // horizontal filler for the branch arm
  );

  TTreeGuideKind = (
    Ascii,     // '|', '+', '`', '-'
    Line,      // ─ │ ├ └ (default)
    Heavy,     // ━ ┃ ┣ ┗
    Double,    // ═ ║ ╠ ╚
    Bold       // alias for heavy
  );

  ITreeGuide = interface
    ['{B5C6A13D-1A1B-4F2C-B78B-6B7E7A3FBC71}']
    function GetPart(part : TTreeGuidePart; unicode : Boolean) : Char;
    function Kind : TTreeGuideKind;
  end;

function TreeGuide(kind : TTreeGuideKind) : ITreeGuide;

implementation

type
  TTreeGlyphs = array[TTreeGuidePart] of Char;

  TTreeGuideImpl = class(TInterfacedObject, ITreeGuide)
  strict private
    FKind    : TTreeGuideKind;
    FUnicode : TTreeGlyphs;
    FAscii   : TTreeGlyphs;
  public
    constructor Create(kind : TTreeGuideKind;
                        const unicodeGlyphs : TTreeGlyphs;
                        const asciiGlyphs   : TTreeGlyphs);
    function GetPart(part : TTreeGuidePart; unicode : Boolean) : Char;
    function Kind : TTreeGuideKind;
  end;

constructor TTreeGuideImpl.Create(kind : TTreeGuideKind;
                                    const unicodeGlyphs : TTreeGlyphs;
                                    const asciiGlyphs   : TTreeGlyphs);
begin
  inherited Create;
  FKind := kind;
  FUnicode := unicodeGlyphs;
  FAscii := asciiGlyphs;
end;

function TTreeGuideImpl.GetPart(part : TTreeGuidePart; unicode : Boolean) : Char;
begin
  if unicode and (FKind <> TTreeGuideKind.Ascii) then
    result := FUnicode[part]
  else
    result := FAscii[part];
end;

function TTreeGuideImpl.Kind : TTreeGuideKind;
begin
  result := FKind;
end;

function Make(const space, continue_, fork_, last, horiz : Char) : TTreeGlyphs;
begin
  result[TTreeGuidePart.Space]      := space;
  result[TTreeGuidePart.Continue]   := continue_;
  result[TTreeGuidePart.Fork]       := fork_;
  result[TTreeGuidePart.Last]       := last;
  result[TTreeGuidePart.Horizontal] := horiz;
end;

function AsciiGlyphs : TTreeGlyphs;
begin
  result := Make(' ', '|', '+', '`', '-');
end;

function LineGlyphs : TTreeGlyphs;
begin
  result := Make(' ', #$2502, #$251C, #$2514, #$2500);   //  │ ├ └ ─
end;

function HeavyGlyphs : TTreeGlyphs;
begin
  result := Make(' ', #$2503, #$2523, #$2517, #$2501);   //  ┃ ┣ ┗ ━
end;

function DoubleGlyphs : TTreeGlyphs;
begin
  result := Make(' ', #$2551, #$2560, #$255A, #$2550);   //  ║ ╠ ╚ ═
end;

function TreeGuide(kind : TTreeGuideKind) : ITreeGuide;
var
  ascii : TTreeGlyphs;
begin
  ascii := AsciiGlyphs;
  case kind of
    TTreeGuideKind.Ascii  : result := TTreeGuideImpl.Create(kind, ascii,        ascii);
    TTreeGuideKind.Heavy,
    TTreeGuideKind.Bold   : result := TTreeGuideImpl.Create(kind, HeavyGlyphs,  ascii);
    TTreeGuideKind.Double : result := TTreeGuideImpl.Create(kind, DoubleGlyphs, ascii);
  else
    result := TTreeGuideImpl.Create(TTreeGuideKind.Line, LineGlyphs, ascii);
  end;
end;

end.
