unit VSoft.AnsiConsole.Widgets.Align;

{
  TAlign - horizontally aligns a single child renderable within the full
  available width. The child measures naturally; the aligner pads each
  rendered line with leading / trailing whitespace so that its content sits
  at the left, centre, or right of the target width.
}

interface

uses
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering;

type
  IAlign = interface(IRenderable)
    ['{1C2D1B08-4A6A-4B7F-8D70-2F0C2C2D7A55}']
    function GetChild : IRenderable;
    function GetAlignment : TAlignment;
    function GetVerticalAlignment : TVerticalAlignment;
    function WithAlignment(value : TAlignment) : IAlign;
    function WithVertical(value : TVerticalAlignment) : IAlign;
    function WithWidth(value : Integer) : IAlign;
    function WithHeight(value : Integer) : IAlign;
    property Child              : IRenderable        read GetChild;
    property Alignment          : TAlignment         read GetAlignment;
    property VerticalAlignment  : TVerticalAlignment read GetVerticalAlignment;
  end;

  TAlign = class(TInterfacedObject, IRenderable, IAlign)
  strict private
    FChild     : IRenderable;
    FAlignment : TAlignment;
    FVertical  : TVerticalAlignment;
    FWidth     : Integer;   // -1 = use full maxWidth
    FHeight    : Integer;   // -1 = no padding
    function  GetChild : IRenderable;
    function  GetAlignment : TAlignment;
    function  GetVerticalAlignment : TVerticalAlignment;
  public
    constructor Create(const child : IRenderable; alignment : TAlignment);
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
    function WithAlignment(value : TAlignment) : IAlign;
    function WithVertical(value : TVerticalAlignment) : IAlign;
    function WithWidth(value : Integer) : IAlign;
    function WithHeight(value : Integer) : IAlign;
  end;

function Align(const child : IRenderable; alignment : TAlignment) : IAlign;

implementation

uses
  System.SysUtils,
  VSoft.AnsiConsole.Internal.SegmentOps;

function Align(const child : IRenderable; alignment : TAlignment) : IAlign;
begin
  result := TAlign.Create(child, alignment);
end;

{ TAlign }

constructor TAlign.Create(const child : IRenderable; alignment : TAlignment);
begin
  inherited Create;
  FChild     := child;
  FAlignment := alignment;
  FVertical  := TVerticalAlignment.Top;
  FWidth     := -1;
  FHeight    := -1;
end;

function TAlign.GetChild : IRenderable;                       begin result := FChild; end;
function TAlign.GetAlignment : TAlignment;                    begin result := FAlignment; end;
function TAlign.GetVerticalAlignment : TVerticalAlignment;    begin result := FVertical; end;

function TAlign.WithAlignment(value : TAlignment) : IAlign;
var a : TAlign;
begin
  a := TAlign.Create(FChild, value);
  a.FVertical := FVertical;
  a.FWidth    := FWidth;
  a.FHeight   := FHeight;
  result := a;
end;

function TAlign.WithVertical(value : TVerticalAlignment) : IAlign;
var a : TAlign;
begin
  a := TAlign.Create(FChild, FAlignment);
  a.FVertical := value;
  a.FWidth    := FWidth;
  a.FHeight   := FHeight;
  result := a;
end;

function TAlign.WithWidth(value : Integer) : IAlign;
var a : TAlign;
begin
  a := TAlign.Create(FChild, FAlignment);
  a.FVertical := FVertical;
  if value < 1 then a.FWidth := -1 else a.FWidth := value;
  a.FHeight   := FHeight;
  result := a;
end;

function TAlign.WithHeight(value : Integer) : IAlign;
var a : TAlign;
begin
  a := TAlign.Create(FChild, FAlignment);
  a.FVertical := FVertical;
  a.FWidth    := FWidth;
  if value < 1 then a.FHeight := -1 else a.FHeight := value;
  result := a;
end;

function TAlign.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
begin
  if FChild = nil then
    result := TMeasurement.Create(0, 0)
  else
    result := FChild.Measure(options, maxWidth);
end;

function TAlign.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  segs       : TAnsiSegments;
  lines      : TArray<TAnsiSegments>;
  i, j       : Integer;
  count      : Integer;
  width      : Integer;
  pad        : Integer;
  leftPad    : Integer;
  rightPad   : Integer;
  cellWidth  : Integer;
  topPad, bottomPad : Integer;
  vpad       : Integer;
  blankLine  : string;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

  procedure EmitBlankLine;
  begin
    if cellWidth > 0 then
      Push(TAnsiSegment.Whitespace(blankLine));
  end;

begin
  SetLength(result, 0);
  count := 0;
  if FChild = nil then
    Exit;

  // FWidth caps the alignment box; otherwise use the full maxWidth.
  if (FWidth > 0) and (FWidth < maxWidth) then
    cellWidth := FWidth
  else
    cellWidth := maxWidth;
  if cellWidth < 1 then cellWidth := 1;
  blankLine := StringOfChar(' ', cellWidth);

  segs := FChild.Render(options, cellWidth);
  lines := SplitLines(segs, cellWidth);

  // Vertical padding for FHeight: top/middle/bottom alignment of the
  // content block within FHeight rows.
  topPad := 0;
  bottomPad := 0;
  if FHeight > 0 then
  begin
    if Length(lines) > FHeight then
      SetLength(lines, FHeight);
    vpad := FHeight - Length(lines);
    if vpad > 0 then
    begin
      case FVertical of
        TVerticalAlignment.Middle:
        begin
          topPad := vpad div 2;
          bottomPad := vpad - topPad;
        end;
        TVerticalAlignment.Bottom:
        begin
          topPad := vpad;
          bottomPad := 0;
        end;
      else
        topPad := 0;
        bottomPad := vpad;
      end;
    end;
  end;

  for i := 1 to topPad do
  begin
    EmitBlankLine;
    Push(TAnsiSegment.LineBreak);
  end;

  for i := 0 to High(lines) do
  begin
    width := TotalCellCount(lines[i]);
    if width >= cellWidth then
    begin
      for j := 0 to High(lines[i]) do
        Push(lines[i][j]);
    end
    else
    begin
      pad := cellWidth - width;
      case FAlignment of
        TAlignment.Center:
          begin
            leftPad  := pad div 2;
            rightPad := pad - leftPad;
          end;
        TAlignment.Right:
          begin
            leftPad  := pad;
            rightPad := 0;
          end;
      else
        leftPad  := 0;
        rightPad := pad;
      end;

      if leftPad > 0 then
        Push(TAnsiSegment.Whitespace(StringOfChar(' ', leftPad)));
      for j := 0 to High(lines[i]) do
        Push(lines[i][j]);
      if rightPad > 0 then
        Push(TAnsiSegment.Whitespace(StringOfChar(' ', rightPad)));
    end;

    if (i < High(lines)) or (bottomPad > 0) then
      Push(TAnsiSegment.LineBreak);
  end;

  for i := 1 to bottomPad do
  begin
    EmitBlankLine;
    if i < bottomPad then
      Push(TAnsiSegment.LineBreak);
  end;
end;

end.
