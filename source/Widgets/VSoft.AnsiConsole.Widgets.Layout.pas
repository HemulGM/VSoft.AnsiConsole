unit VSoft.AnsiConsole.Widgets.Layout;

{
  TLayout - recursive row/column splitter. Each node is either a leaf (wraps
  an IRenderable) or an internal node split by rows or columns.

  Usage:

    var
      root, hdr, body, side, main, foot : ILayout;
    begin
      root := Layout('root');
      hdr  := Layout('header').WithSize(3);
      side := Layout('side').WithRatio(1);
      main := Layout('main').WithRatio(2);
      body := Layout('body');
      body.SplitColumns([side, main]);
      foot := Layout('footer').WithSize(1);
      root.SplitRows([hdr, body, foot]);
      root.Update(SomeRenderable);
      root.WithHeight(24);

  Use `root.FindByName('side')` to retrieve a child by name so the consumer
  can swap its content with `Update()`.

  Height: Layout needs a target height. If not set, Render uses options.Height
  (or a sensible fallback).
}

{$SCOPEDENUMS ON}

interface

uses
  System.SysUtils,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering;

type
  TLayoutSplitKind = (None, Rows, Columns);

  TAnsiSegmentLines = TArray<TArray<TAnsiSegment>>;

  ILayout = interface(IRenderable)
    ['{C2F4A5B6-8D1E-4F7C-9B30-6A5E4D3B2C10}']
    function GetName : string;
    function GetRatio : Integer;
    function GetMinimumSize : Integer;
    function GetFixedSize : Integer;
    function GetVisible : Boolean;
    function Update(const renderable : IRenderable) : ILayout;
    function SplitRows(const children : array of ILayout) : ILayout;
    function SplitColumns(const children : array of ILayout) : ILayout;
    function WithRatio(value : Integer) : ILayout;
    function WithSize(value : Integer) : ILayout;
    function WithMinimumSize(value : Integer) : ILayout;
    function WithVisible(value : Boolean) : ILayout;
    function WithHeight(value : Integer) : ILayout;
    function FindByName(const name : string) : ILayout;
    procedure RenderInto(const options : TRenderOptions;
                          width, height : Integer;
                          var outLines : TAnsiSegmentLines);
    property Name : string read GetName;
  end;

  TLayout = class(TInterfacedObject, IRenderable, ILayout)
  strict private
    FName        : string;
    FContent     : IRenderable;
    FSplit       : TLayoutSplitKind;
    FChildren    : TArray<ILayout>;
    FRatio       : Integer;
    FMinSize     : Integer;
    FFixedSize   : Integer;  // 0 = none
    FVisible     : Boolean;
    FHeight      : Integer;  // 0 = use options.Height

    procedure DivideSpace(total : Integer; out sizes : TArray<Integer>);
    procedure RenderChildren(const options : TRenderOptions; width, height : Integer;
                             var outLines : TAnsiSegmentLines);
    procedure RenderLeaf(const options : TRenderOptions; width, height : Integer;
                          var outLines : TAnsiSegmentLines);
  public
    constructor Create(const name : string = '');

    function GetName : string;
    function GetRatio : Integer;
    function GetMinimumSize : Integer;
    function GetFixedSize : Integer;
    function GetVisible : Boolean;

    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;

    function Update(const renderable : IRenderable) : ILayout;
    function SplitRows(const children : array of ILayout) : ILayout;
    function SplitColumns(const children : array of ILayout) : ILayout;
    function WithRatio(value : Integer) : ILayout;
    function WithSize(value : Integer) : ILayout;
    function WithMinimumSize(value : Integer) : ILayout;
    function WithVisible(value : Boolean) : ILayout;
    function WithHeight(value : Integer) : ILayout;
    function FindByName(const name : string) : ILayout;

    procedure RenderInto(const options : TRenderOptions;
                          width, height : Integer;
                          var outLines : TAnsiSegmentLines);
  end;

function Layout : ILayout; overload;
function Layout(const name : string) : ILayout; overload;
function Layout(const name : string; const content : IRenderable) : ILayout; overload;

implementation

uses
  VSoft.AnsiConsole.Internal.SegmentOps;

function Layout : ILayout;
begin
  result := TLayout.Create('');
end;

function Layout(const name : string) : ILayout;
begin
  result := TLayout.Create(name);
end;

function Layout(const name : string; const content : IRenderable) : ILayout;
begin
  result := TLayout.Create(name);
  result.Update(content);
end;

{ TLayout }

constructor TLayout.Create(const name : string);
begin
  inherited Create;
  FName := name;
  FRatio := 1;
  FMinSize := 1;
  FFixedSize := 0;
  FVisible := True;
  FSplit := TLayoutSplitKind.None;
end;

function TLayout.GetName : string;         begin result := FName; end;
function TLayout.GetRatio : Integer;       begin result := FRatio; end;
function TLayout.GetMinimumSize : Integer; begin result := FMinSize; end;
function TLayout.GetFixedSize : Integer;   begin result := FFixedSize; end;
function TLayout.GetVisible : Boolean;     begin result := FVisible; end;

function TLayout.Update(const renderable : IRenderable) : ILayout;
begin
  FContent := renderable;
  result := Self;
end;

function TLayout.SplitRows(const children : array of ILayout) : ILayout;
var
  i : Integer;
begin
  FSplit := TLayoutSplitKind.Rows;
  SetLength(FChildren, Length(children));
  for i := 0 to High(children) do
    FChildren[i] := children[i];
  result := Self;
end;

function TLayout.SplitColumns(const children : array of ILayout) : ILayout;
var
  i : Integer;
begin
  FSplit := TLayoutSplitKind.Columns;
  SetLength(FChildren, Length(children));
  for i := 0 to High(children) do
    FChildren[i] := children[i];
  result := Self;
end;

function TLayout.WithRatio(value : Integer) : ILayout;
begin
  if value < 1 then value := 1;
  FRatio := value;
  result := Self;
end;

function TLayout.WithSize(value : Integer) : ILayout;
begin
  if value < 1 then value := 1;
  FFixedSize := value;
  result := Self;
end;

function TLayout.WithMinimumSize(value : Integer) : ILayout;
begin
  if value < 1 then value := 1;
  FMinSize := value;
  result := Self;
end;

function TLayout.WithVisible(value : Boolean) : ILayout;
begin
  FVisible := value;
  result := Self;
end;

function TLayout.WithHeight(value : Integer) : ILayout;
begin
  if value < 1 then value := 1;
  FHeight := value;
  result := Self;
end;

function TLayout.FindByName(const name : string) : ILayout;
var
  i : Integer;
  found : ILayout;
begin
  if SameText(FName, name) then
  begin
    result := Self;
    Exit;
  end;
  for i := 0 to High(FChildren) do
  begin
    found := FChildren[i].FindByName(name);
    if found <> nil then
    begin
      result := found;
      Exit;
    end;
  end;
  result := nil;
end;

function TLayout.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
begin
  result := TMeasurement.Create(maxWidth, maxWidth);
end;

procedure TLayout.DivideSpace(total : Integer; out sizes : TArray<Integer>);
var
  i         : Integer;
  ratioSum  : Integer;
  remaining : Integer;
  given     : Integer;
  leftover  : Integer;
  idx       : Integer;
begin
  SetLength(sizes, Length(FChildren));

  remaining := total;
  ratioSum := 0;
  for i := 0 to High(FChildren) do
  begin
    if not FChildren[i].GetVisible then
    begin
      sizes[i] := 0;
      Continue;
    end;
    if FChildren[i].GetFixedSize > 0 then
    begin
      sizes[i] := FChildren[i].GetFixedSize;
      remaining := remaining - FChildren[i].GetFixedSize;
    end
    else
    begin
      sizes[i] := 0;
      Inc(ratioSum, FChildren[i].GetRatio);
    end;
  end;
  if remaining < 0 then remaining := 0;

  if ratioSum > 0 then
  begin
    leftover := remaining;
    for i := 0 to High(FChildren) do
    begin
      if (not FChildren[i].GetVisible) or (FChildren[i].GetFixedSize > 0) then Continue;
      given := (remaining * FChildren[i].GetRatio) div ratioSum;
      if given < FChildren[i].GetMinimumSize then given := FChildren[i].GetMinimumSize;
      sizes[i] := given;
      Dec(leftover, given);
    end;
    idx := -1;
    for i := 0 to High(FChildren) do
    begin
      if (FChildren[i].GetVisible) and (FChildren[i].GetFixedSize = 0) then
      begin
        idx := i;
        Break;
      end;
    end;
    if (leftover > 0) and (idx >= 0) then
      sizes[idx] := sizes[idx] + leftover;
  end;

  for i := 0 to High(sizes) do
    if sizes[i] < 0 then sizes[i] := 0;
end;

procedure TLayout.RenderLeaf(const options : TRenderOptions;
                              width, height : Integer;
                              var outLines : TAnsiSegmentLines);
var
  segs     : TAnsiSegments;
  rendered : TArray<TAnsiSegments>;
  i        : Integer;
  lineW    : Integer;
  opts     : TRenderOptions;
begin
  SetLength(outLines, height);
  if FContent = nil then
  begin
    for i := 0 to height - 1 do
    begin
      SetLength(outLines[i], 1);
      outLines[i][0] := TAnsiSegment.Whitespace(StringOfChar(' ', width));
    end;
    Exit;
  end;

  opts := options.WithWidth(width).WithHeight(height);
  segs := FContent.Render(opts, width);

  rendered := SplitLines(segs, width);
  for i := 0 to height - 1 do
  begin
    if i <= High(rendered) then
    begin
      outLines[i] := rendered[i];
      lineW := TotalCellCount(rendered[i]);
      if lineW < width then
      begin
        SetLength(outLines[i], Length(outLines[i]) + 1);
        outLines[i][High(outLines[i])] :=
          TAnsiSegment.Whitespace(StringOfChar(' ', width - lineW));
      end;
    end
    else
    begin
      SetLength(outLines[i], 1);
      outLines[i][0] := TAnsiSegment.Whitespace(StringOfChar(' ', width));
    end;
  end;
end;

procedure TLayout.RenderChildren(const options : TRenderOptions;
                                  width, height : Integer;
                                  var outLines : TAnsiSegmentLines);
var
  sizes      : TArray<Integer>;
  childLines : TAnsiSegmentLines;
  i, j, k    : Integer;
  oldLen     : Integer;
  cursorY    : Integer;
begin
  SetLength(outLines, height);
  for i := 0 to height - 1 do
    SetLength(outLines[i], 0);

  if FSplit = TLayoutSplitKind.Rows then
  begin
    DivideSpace(height, sizes);
    cursorY := 0;
    for i := 0 to High(FChildren) do
    begin
      if sizes[i] <= 0 then Continue;
      FChildren[i].RenderInto(options, width, sizes[i], childLines);
      for j := 0 to High(childLines) do
      begin
        if cursorY + j < height then
          outLines[cursorY + j] := childLines[j];
      end;
      Inc(cursorY, sizes[i]);
    end;
  end
  else if FSplit = TLayoutSplitKind.Columns then
  begin
    DivideSpace(width, sizes);
    for i := 0 to High(FChildren) do
    begin
      if sizes[i] <= 0 then Continue;
      FChildren[i].RenderInto(options, sizes[i], height, childLines);
      for j := 0 to High(childLines) do
      begin
        if j < height then
        begin
          oldLen := Length(outLines[j]);
          SetLength(outLines[j], oldLen + Length(childLines[j]));
          for k := 0 to High(childLines[j]) do
            outLines[j][oldLen + k] := childLines[j][k];
        end;
      end;
    end;
  end
  else
    RenderLeaf(options, width, height, outLines);

  for i := 0 to height - 1 do
  begin
    if Length(outLines[i]) = 0 then
    begin
      SetLength(outLines[i], 1);
      outLines[i][0] := TAnsiSegment.Whitespace(StringOfChar(' ', width));
    end;
  end;
end;

procedure TLayout.RenderInto(const options : TRenderOptions;
                              width, height : Integer;
                              var outLines : TAnsiSegmentLines);
begin
  if FSplit = TLayoutSplitKind.None then
    RenderLeaf(options, width, height, outLines)
  else
    RenderChildren(options, width, height, outLines);
end;

function TLayout.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  targetHeight : Integer;
  lines        : TAnsiSegmentLines;
  i, j, count  : Integer;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;

  if FHeight > 0 then
    targetHeight := FHeight
  else
  begin
    targetHeight := options.Height;
    if targetHeight <= 0 then targetHeight := 24;
  end;

  RenderInto(options, maxWidth, targetHeight, lines);

  for i := 0 to High(lines) do
  begin
    for j := 0 to High(lines[i]) do
      Push(lines[i][j]);
    if i < High(lines) then
      Push(TAnsiSegment.LineBreak);
  end;
end;

end.
