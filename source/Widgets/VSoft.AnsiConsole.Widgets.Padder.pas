unit VSoft.AnsiConsole.Widgets.Padder;

{
  TPadder - wraps a single IRenderable child and adds fixed cell padding
  on each side. Padding is applied after the child is rendered: the child
  sees a reduced maxWidth and its output is surrounded with whitespace.
}

interface

uses
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering;

type
  TPadding = record
    Top, Right, Bottom, Left : Integer;
    { Construct uniform padding for all four sides. }
    class function All(size : Integer) : TPadding; static;
    { Separate horizontal (Left = Right) and vertical (Top = Bottom) sizes. }
    class function HorizontalVertical(horizontal, vertical : Integer) : TPadding; static;
    { Construct an explicit four-sided padding record (verbose alternative
      to brace-init for callers who prefer a factory). }
    class function Make(top, right, bottom, left : Integer) : TPadding; static;
    { Sum of horizontal padding (Left + Right). }
    function GetWidth : Integer;
    { Sum of vertical padding (Top + Bottom). }
    function GetHeight : Integer;
    function Equals(const other : TPadding) : Boolean;
  end;

  IPadder = interface(IRenderable)
    ['{9E4A5D0C-D8F2-4F37-9B97-2B7B4E8A4D63}']
    function GetChild : IRenderable;
    function GetPadding : TPadding;
    function WithPadding(top, right, bottom, left : Integer) : IPadder; overload;
    function WithPadding(horizontal, vertical : Integer) : IPadder; overload;
    function WithPadding(all : Integer) : IPadder; overload;
    function WithExpand(value : Boolean) : IPadder;
    property Child   : IRenderable read GetChild;
    property Padding : TPadding    read GetPadding;
  end;

  TPadder = class(TInterfacedObject, IRenderable, IPadder)
  strict private
    FChild   : IRenderable;
    FPadding : TPadding;
    FExpand  : Boolean;
    function  GetChild : IRenderable;
    function  GetPadding : TPadding;
    function  Clone : TPadder;
  public
    constructor Create(const child : IRenderable);
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
    function WithPadding(top, right, bottom, left : Integer) : IPadder; overload;
    function WithPadding(horizontal, vertical : Integer) : IPadder; overload;
    function WithPadding(all : Integer) : IPadder; overload;
    function WithExpand(value : Boolean) : IPadder;
  end;

function Padder(const child : IRenderable) : IPadder;

implementation

uses
  System.SysUtils,
  VSoft.AnsiConsole.Internal.SegmentOps;

function Padder(const child : IRenderable) : IPadder;
begin
  result := TPadder.Create(child);
end;

{ TPadding }

class function TPadding.All(size : Integer) : TPadding;
begin
  result.Top    := size;
  result.Right  := size;
  result.Bottom := size;
  result.Left   := size;
end;

class function TPadding.HorizontalVertical(horizontal, vertical : Integer) : TPadding;
begin
  result.Top    := vertical;
  result.Right  := horizontal;
  result.Bottom := vertical;
  result.Left   := horizontal;
end;

class function TPadding.Make(top, right, bottom, left : Integer) : TPadding;
begin
  result.Top    := top;
  result.Right  := right;
  result.Bottom := bottom;
  result.Left   := left;
end;

function TPadding.GetWidth : Integer;
begin
  result := Left + Right;
end;

function TPadding.GetHeight : Integer;
begin
  result := Top + Bottom;
end;

function TPadding.Equals(const other : TPadding) : Boolean;
begin
  result := (Top    = other.Top)
        and (Right  = other.Right)
        and (Bottom = other.Bottom)
        and (Left   = other.Left);
end;

{ TPadder }

constructor TPadder.Create(const child : IRenderable);
begin
  inherited Create;
  FChild := child;
  FPadding.Top    := 0;
  FPadding.Right  := 1;
  FPadding.Bottom := 0;
  FPadding.Left   := 1;
  // Expand-to-maxWidth is the historical behaviour and matches what
  // every existing layout test expects; WithExpand(False) opts out and
  // shrinks to the child's natural width.
  FExpand := True;
end;

function TPadder.GetChild : IRenderable;
begin
  result := FChild;
end;

function TPadder.GetPadding : TPadding;
begin
  result := FPadding;
end;

function TPadder.Clone : TPadder;
begin
  result := TPadder.Create(FChild);
  result.FPadding := FPadding;
  result.FExpand  := FExpand;
end;

function TPadder.WithExpand(value : Boolean) : IPadder;
var p : TPadder;
begin p := Clone; p.FExpand := value; result := p; end;

function TPadder.WithPadding(top, right, bottom, left : Integer) : IPadder;
var
  p : TPadder;
begin
  p := Clone;
  p.FPadding.Top    := top;
  p.FPadding.Right  := right;
  p.FPadding.Bottom := bottom;
  p.FPadding.Left   := left;
  result := p;
end;

function TPadder.WithPadding(horizontal, vertical : Integer) : IPadder;
begin
  result := WithPadding(vertical, horizontal, vertical, horizontal);
end;

function TPadder.WithPadding(all : Integer) : IPadder;
begin
  result := WithPadding(all, all, all, all);
end;

function TPadder.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
var
  innerWidth : Integer;
  m          : TMeasurement;
begin
  innerWidth := maxWidth - FPadding.Left - FPadding.Right;
  if innerWidth < 0 then innerWidth := 0;
  m := FChild.Measure(options, innerWidth);
  result := TMeasurement.Create(m.Min + FPadding.Left + FPadding.Right,
                                 m.Max + FPadding.Left + FPadding.Right);
end;

function TPadder.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  innerWidth  : Integer;
  outerWidth  : Integer;
  childSegs   : TAnsiSegments;
  lines       : TArray<TAnsiSegments>;
  i, j        : Integer;
  count       : Integer;
  lineWidth   : Integer;
  blank       : string;
  leftPad     : string;
  rightPad    : string;
  m           : TMeasurement;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;

  // Inner width: full available width minus L+R padding when Expand=True;
  // shrink to the child's natural width otherwise (matches Spectre's
  // Padder.Expand semantics).
  if FExpand or (FChild = nil) then
    innerWidth := maxWidth - FPadding.Left - FPadding.Right
  else
  begin
    m := FChild.Measure(options, maxWidth - FPadding.Left - FPadding.Right);
    innerWidth := m.Max;
    if innerWidth > maxWidth - FPadding.Left - FPadding.Right then
      innerWidth := maxWidth - FPadding.Left - FPadding.Right;
  end;
  if innerWidth < 0 then innerWidth := 0;
  outerWidth := innerWidth + FPadding.Left + FPadding.Right;

  leftPad  := StringOfChar(' ', FPadding.Left);
  rightPad := StringOfChar(' ', FPadding.Right);
  blank    := StringOfChar(' ', outerWidth);

  // Top blank lines
  for i := 0 to FPadding.Top - 1 do
  begin
    Push(TAnsiSegment.Whitespace(blank));
    Push(TAnsiSegment.LineBreak);
  end;

  if FChild <> nil then
  begin
    childSegs := FChild.Render(options, innerWidth);
    lines := SplitLines(childSegs, innerWidth);

    for i := 0 to High(lines) do
    begin
      if FPadding.Left > 0 then
        Push(TAnsiSegment.Whitespace(leftPad));

      lineWidth := TotalCellCount(lines[i]);
      for j := 0 to High(lines[i]) do
        Push(lines[i][j]);

      // Fill remaining inner width before right padding so the right edge
      // lines up even when the child produced a short line.
      if lineWidth < innerWidth then
        Push(TAnsiSegment.Whitespace(StringOfChar(' ', innerWidth - lineWidth)));

      if FPadding.Right > 0 then
        Push(TAnsiSegment.Whitespace(rightPad));

      if i < High(lines) then
        Push(TAnsiSegment.LineBreak);
    end;
  end;

  // Bottom blank lines
  for i := 0 to FPadding.Bottom - 1 do
  begin
    Push(TAnsiSegment.LineBreak);
    Push(TAnsiSegment.Whitespace(blank));
  end;
end;

end.
