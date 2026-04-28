unit VSoft.AnsiConsole.Widgets.Panel;

{
  TPanel - wraps a single child renderable with a box border, optional
  header (inset into the top border) and optional footer (inset into the
  bottom border).

    +---- header ----+
    |                |
    |   child lines  |
    |                |
    +---- footer ----+

  Layout:
    outer width = maxWidth
    inner width = outer - 2 (one cell each side for the border)
                        - horizontal padding (defaults to 1 left and right)

  Phase 2 ships single-line header/footer text with centred alignment.
  Multi-line titles, custom alignment, and vertical alignment for the
  child block arrive with Phase 6 layout features.
}

interface

uses
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Borders.Box;

type
  IPanel = interface(IRenderable)
    ['{4AAF1B05-88D1-4F6D-8C46-1E8F7C6D70F0}']
    function GetChild : IRenderable;
    function GetHeader : string;
    function GetFooter : string;
    function GetBorder : IBoxBorder;
    function GetBorderStyle : TAnsiStyle;
    function GetPadding : Integer;

    function WithHeader(const value : string) : IPanel;
    function WithFooter(const value : string) : IPanel;
    function WithBorder(const value : IBoxBorder) : IPanel; overload;
    function WithBorder(kind : TBoxBorderKind) : IPanel; overload;
    function WithBorderStyle(const value : TAnsiStyle) : IPanel;
    function WithPadding(cells : Integer) : IPanel;
    function WithWidth(value : Integer) : IPanel;
    function WithHeight(value : Integer) : IPanel;
    function WithExpand(value : Boolean) : IPanel;
    function WithUseSafeBorder(value : Boolean) : IPanel;

    property Child       : IRenderable read GetChild;
    property Header      : string      read GetHeader;
    property Footer      : string      read GetFooter;
    property Border      : IBoxBorder  read GetBorder;
    property BorderStyle : TAnsiStyle  read GetBorderStyle;
    property Padding     : Integer     read GetPadding;
  end;

  TPanel = class(TInterfacedObject, IRenderable, IPanel)
  strict private
    FChild          : IRenderable;
    FHeader         : string;
    FFooter         : string;
    FBorder         : IBoxBorder;
    FBorderStyle    : TAnsiStyle;
    FPadding        : Integer;
    FWidth          : Integer;   // -1 = auto, otherwise fixed
    FHeight         : Integer;   // -1 = auto, otherwise fixed
    FExpand         : Boolean;
    FUseSafeBorder  : Boolean;   // True = unicode borders downgrade to ASCII when not unicode-capable
    function  GetChild : IRenderable;
    function  GetHeader : string;
    function  GetFooter : string;
    function  GetBorder : IBoxBorder;
    function  GetBorderStyle : TAnsiStyle;
    function  GetPadding : Integer;
    function  Clone : TPanel;
  public
    constructor Create(const child : IRenderable);
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
    function WithHeader(const value : string) : IPanel;
    function WithFooter(const value : string) : IPanel;
    function WithBorder(const value : IBoxBorder) : IPanel; overload;
    function WithBorder(kind : TBoxBorderKind) : IPanel; overload;
    function WithBorderStyle(const value : TAnsiStyle) : IPanel;
    function WithPadding(cells : Integer) : IPanel;
    function WithWidth(value : Integer) : IPanel;
    function WithHeight(value : Integer) : IPanel;
    function WithExpand(value : Boolean) : IPanel;
    function WithUseSafeBorder(value : Boolean) : IPanel;
  end;

function Panel(const child : IRenderable) : IPanel;

implementation

uses
  System.SysUtils,
  VSoft.AnsiConsole.Internal.Cell,
  VSoft.AnsiConsole.Internal.SegmentOps,
  VSoft.AnsiConsole.Markup.Parser;

function Panel(const child : IRenderable) : IPanel;
begin
  result := TPanel.Create(child);
end;

{ TPanel }

constructor TPanel.Create(const child : IRenderable);
begin
  inherited Create;
  FChild         := child;
  FBorder        := BoxBorder(TBoxBorderKind.Square);
  FBorderStyle   := TAnsiStyle.Plain;
  FPadding       := 1;
  FWidth         := -1;
  FHeight        := -1;
  // Expand-to-maxWidth is the historical behaviour every existing
  // layout test relies on; WithExpand(False) opts out (Spectre default)
  // and shrinks the panel to its child's natural width.
  FExpand        := True;
  FUseSafeBorder := True;
end;

function TPanel.GetChild : IRenderable;    begin result := FChild; end;
function TPanel.GetHeader : string;        begin result := FHeader; end;
function TPanel.GetFooter : string;        begin result := FFooter; end;
function TPanel.GetBorder : IBoxBorder;    begin result := FBorder; end;
function TPanel.GetBorderStyle : TAnsiStyle; begin result := FBorderStyle; end;
function TPanel.GetPadding : Integer;      begin result := FPadding; end;

function TPanel.Clone : TPanel;
begin
  result := TPanel.Create(FChild);
  result.FHeader        := FHeader;
  result.FFooter        := FFooter;
  result.FBorder        := FBorder;
  result.FBorderStyle   := FBorderStyle;
  result.FPadding       := FPadding;
  result.FWidth         := FWidth;
  result.FHeight        := FHeight;
  result.FExpand        := FExpand;
  result.FUseSafeBorder := FUseSafeBorder;
end;

function TPanel.WithHeader(const value : string) : IPanel;
var p : TPanel; begin p := Clone; p.FHeader := value; result := p; end;

function TPanel.WithFooter(const value : string) : IPanel;
var p : TPanel; begin p := Clone; p.FFooter := value; result := p; end;

function TPanel.WithBorder(const value : IBoxBorder) : IPanel;
var p : TPanel; begin p := Clone; p.FBorder := value; result := p; end;

function TPanel.WithBorder(kind : TBoxBorderKind) : IPanel;
var p : TPanel; begin p := Clone; p.FBorder := BoxBorder(kind); result := p; end;

function TPanel.WithBorderStyle(const value : TAnsiStyle) : IPanel;
var p : TPanel; begin p := Clone; p.FBorderStyle := value; result := p; end;

function TPanel.WithPadding(cells : Integer) : IPanel;
var p : TPanel;
begin
  if cells < 0 then cells := 0;
  p := Clone;
  p.FPadding := cells;
  result := p;
end;

function TPanel.WithWidth(value : Integer) : IPanel;
var p : TPanel;
begin
  p := Clone;
  if value < 1 then
    p.FWidth := -1
  else
    p.FWidth := value;
  result := p;
end;

function TPanel.WithHeight(value : Integer) : IPanel;
var p : TPanel;
begin
  p := Clone;
  if value < 1 then
    p.FHeight := -1
  else
    p.FHeight := value;
  result := p;
end;

function TPanel.WithExpand(value : Boolean) : IPanel;
var p : TPanel;
begin p := Clone; p.FExpand := value; result := p; end;

function TPanel.WithUseSafeBorder(value : Boolean) : IPanel;
var p : TPanel;
begin p := Clone; p.FUseSafeBorder := value; result := p; end;

function TPanel.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
var
  overhead : Integer;
  inner    : Integer;
  m        : TMeasurement;
begin
  overhead := 2 + FPadding * 2;  // two border cells + horizontal padding
  inner := maxWidth - overhead;
  if inner < 0 then inner := 0;
  if FChild = nil then
    m := TMeasurement.Create(0, 0)
  else
    m := FChild.Measure(options, inner);
  result := TMeasurement.Create(m.Min + overhead, m.Max + overhead);
end;

function BuildBorderRow(const border : IBoxBorder; unicode : Boolean;
                         leftPart, fillPart, rightPart : TBoxBorderPart;
                         fillCount : Integer;
                         const title : string;
                         const style : TAnsiStyle;
                         headerLeft, headerRight : TBoxBorderPart) : TAnsiSegments;
var
  count    : Integer;
  titleLen : Integer;
  rawTitle : string;
  leftPad  : Integer;
  rightPad : Integer;
  titleSegs : TAnsiSegments;
  ti       : Integer;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;

  Push(TAnsiSegment.Text(border.GetPart(leftPart, unicode), style));

  if title = '' then
  begin
    if fillCount > 0 then
      Push(TAnsiSegment.Text(StringOfChar(border.GetPart(fillPart, unicode), fillCount), style));
  end
  else
  begin
    // Parse the title as markup so callers can include style tags
    // (e.g. '[bold]Section[/]'). Width comes from the parsed segments.
    titleSegs := ParseMarkup(' ' + title + ' ');
    titleLen := TotalCellCount(titleSegs);
    if titleLen > fillCount then
    begin
      // Doesn't fit - fall back to a cell-naive clip of the raw text so
      // we still produce a visually reasonable header.
      rawTitle := Copy(' ' + title + ' ', 1, fillCount);
      Push(TAnsiSegment.Text(rawTitle, style));
    end
    else
    begin
      leftPad  := (fillCount - titleLen) div 2;
      rightPad := fillCount - titleLen - leftPad;
      if leftPad > 0 then
        Push(TAnsiSegment.Text(StringOfChar(border.GetPart(fillPart, unicode), leftPad), style));
      // we don't emit the headerLeft/headerRight joins in Phase 2 - the title
      // simply sits inline with the surrounding border characters. These enum
      // members are kept for future (Phase 3 table headers) symmetry.
      for ti := 0 to High(titleSegs) do
        Push(titleSegs[ti]);
      if rightPad > 0 then
        Push(TAnsiSegment.Text(StringOfChar(border.GetPart(fillPart, unicode), rightPad), style));
    end;
  end;

  // headerLeft/headerRight deliberately unused in Phase 2 - referenced to
  // silence the unused-param hint only.
  if (headerLeft = TBoxBorderPart.HeaderLeft) and (headerRight = TBoxBorderPart.HeaderRight) then ;

  Push(TAnsiSegment.Text(border.GetPart(rightPart, unicode), style));
end;

function TPanel.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  outerWidth       : Integer;
  innerWidth       : Integer;
  overhead         : Integer;
  childSegs        : TAnsiSegments;
  lines            : TArray<TAnsiSegments>;
  i, j             : Integer;
  count            : Integer;
  leftPad          : string;
  rightPad         : string;
  topRow           : TAnsiSegments;
  bottomRow        : TAnsiSegments;
  line             : TAnsiSegments;
  lineWidth        : Integer;
  leftCh           : string;
  rightCh          : string;
  childMeasure     : TMeasurement;
  desiredBodyLines : Integer;
  borderUnicode    : Boolean;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

  procedure PushMany(const source : TAnsiSegments);
  var
    x : Integer;
  begin
    for x := 0 to High(source) do
      Push(source[x]);
  end;

begin
  SetLength(result, 0);
  count := 0;

  // Determine the outer width:
  //   FWidth > 0    -> fixed (clamped to maxWidth so we never overflow)
  //   FExpand=True  -> use the full maxWidth (existing behaviour)
  //   FExpand=False -> shrink to natural child width + overhead
  overhead := 2 + FPadding * 2;
  if FWidth > 0 then
  begin
    outerWidth := FWidth;
    if outerWidth > maxWidth then outerWidth := maxWidth;
  end
  else if FExpand then
    outerWidth := maxWidth
  else
  begin
    if FChild = nil then
      outerWidth := overhead + 1
    else
    begin
      childMeasure := FChild.Measure(options, maxWidth - overhead);
      outerWidth := childMeasure.Max + overhead;
      if outerWidth > maxWidth then outerWidth := maxWidth;
    end;
  end;
  if outerWidth < overhead + 1 then
    outerWidth := overhead + 1;
  innerWidth := outerWidth - overhead;

  // FUseSafeBorder=False forces the unicode glyphs even when the terminal
  // wasn't detected as unicode-capable. Default True: respects options.Unicode.
  borderUnicode := options.Unicode or (not FUseSafeBorder);

  leftPad  := StringOfChar(' ', FPadding);
  rightPad := StringOfChar(' ', FPadding);
  leftCh   := FBorder.GetPart(TBoxBorderPart.Left, borderUnicode);
  rightCh  := FBorder.GetPart(TBoxBorderPart.Right, borderUnicode);

  // Top border (with optional header)
  topRow := BuildBorderRow(FBorder, borderUnicode,
                            TBoxBorderPart.TopLeft, TBoxBorderPart.Top, TBoxBorderPart.TopRight,
                            outerWidth - 2,
                            FHeader, FBorderStyle,
                            TBoxBorderPart.HeaderLeft, TBoxBorderPart.HeaderRight);
  PushMany(topRow);
  Push(TAnsiSegment.LineBreak);

  // Child body
  if FChild <> nil then
  begin
    childSegs := FChild.Render(options, innerWidth);
    lines := SplitLines(childSegs, innerWidth);
  end
  else
    SetLength(lines, 0);

  // Honour FHeight: number of *body* lines = FHeight - 2 (top + bottom edge).
  // If FHeight <= 0 the body grows naturally with the child content.
  if FHeight > 0 then
  begin
    desiredBodyLines := FHeight - 2;
    if desiredBodyLines < 1 then desiredBodyLines := 1;
    if Length(lines) > desiredBodyLines then
      SetLength(lines, desiredBodyLines)
    else
      while Length(lines) < desiredBodyLines do
      begin
        SetLength(lines, Length(lines) + 1);
        SetLength(lines[High(lines)], 0);
      end;
  end;

  if Length(lines) = 0 then
  begin
    // empty panel - a single blank content row
    Push(TAnsiSegment.Text(leftCh, FBorderStyle));
    Push(TAnsiSegment.Whitespace(StringOfChar(' ', outerWidth - 2)));
    Push(TAnsiSegment.Text(rightCh, FBorderStyle));
    Push(TAnsiSegment.LineBreak);
  end
  else
  begin
    for i := 0 to High(lines) do
    begin
      Push(TAnsiSegment.Text(leftCh, FBorderStyle));
      if FPadding > 0 then
        Push(TAnsiSegment.Whitespace(leftPad));

      line := lines[i];
      lineWidth := TotalCellCount(line);
      for j := 0 to High(line) do
        Push(line[j]);
      if lineWidth < innerWidth then
        Push(TAnsiSegment.Whitespace(StringOfChar(' ', innerWidth - lineWidth)));

      if FPadding > 0 then
        Push(TAnsiSegment.Whitespace(rightPad));
      Push(TAnsiSegment.Text(rightCh, FBorderStyle));
      Push(TAnsiSegment.LineBreak);
    end;
  end;

  // Bottom border (with optional footer)
  bottomRow := BuildBorderRow(FBorder, borderUnicode,
                               TBoxBorderPart.BottomLeft, TBoxBorderPart.Bottom, TBoxBorderPart.BottomRight,
                               outerWidth - 2,
                               FFooter, FBorderStyle,
                               TBoxBorderPart.HeaderLeft, TBoxBorderPart.HeaderRight);
  PushMany(bottomRow);
end;

end.
