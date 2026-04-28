unit VSoft.AnsiConsole.Widgets.Columns;

{
  TColumns - arranges children left-to-right at equal widths, with an
  optional inter-column gutter. Each child is rendered into its own column
  width, then the outputs are stitched together line-by-line.

  Phase 2 ships equal-width columns. Proportional and fixed widths ship
  with Grid.
}

interface

uses
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering;

type
  IColumns = interface(IRenderable)
    ['{7D7F2E3A-3CF5-4913-9BFB-0A23F0E4C3D1}']
    function Add(const child : IRenderable) : IColumns;
    function WithGutter(cells : Integer) : IColumns;
    function WithExpand(value : Boolean) : IColumns;
    function Count : Integer;
  end;

  TColumns = class(TInterfacedObject, IRenderable, IColumns)
  strict private
    FChildren : TArray<IRenderable>;
    FGutter   : Integer;
    FExpand   : Boolean;
  public
    constructor Create;
    function Add(const child : IRenderable) : IColumns;
    function WithGutter(cells : Integer) : IColumns;
    function WithExpand(value : Boolean) : IColumns;
    function Count : Integer;
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
  end;

function Columns : IColumns;

implementation

uses
  System.SysUtils,
  VSoft.AnsiConsole.Internal.SegmentOps;

function Columns : IColumns;
begin
  result := TColumns.Create;
end;

{ TColumns }

constructor TColumns.Create;
begin
  inherited Create;
  FGutter := 1;
  FExpand := True;     // Spectre default: columns fill the available width.
end;

function TColumns.Add(const child : IRenderable) : IColumns;
begin
  if child <> nil then
  begin
    SetLength(FChildren, Length(FChildren) + 1);
    FChildren[High(FChildren)] := child;
  end;
  result := Self;
end;

function TColumns.WithGutter(cells : Integer) : IColumns;
begin
  if cells < 0 then cells := 0;
  FGutter := cells;
  result := Self;
end;

function TColumns.WithExpand(value : Boolean) : IColumns;
begin
  FExpand := value;
  result := Self;
end;

function TColumns.Count : Integer;
begin
  result := Length(FChildren);
end;

function TColumns.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
var
  i : Integer;
  m : TMeasurement;
  totalMin, totalMax : Integer;
  gutters            : Integer;
begin
  totalMin := 0;
  totalMax := 0;
  for i := 0 to High(FChildren) do
  begin
    m := FChildren[i].Measure(options, maxWidth);
    Inc(totalMin, m.Min);
    Inc(totalMax, m.Max);
  end;
  if Length(FChildren) > 1 then
    gutters := (Length(FChildren) - 1) * FGutter
  else
    gutters := 0;
  result := TMeasurement.Create(totalMin + gutters, totalMax + gutters);
end;

function TColumns.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  n          : Integer;
  i, j, k    : Integer;
  count      : Integer;
  available  : Integer;
  colWidth   : Integer;
  remainder  : Integer;
  widths     : TArray<Integer>;
  rendered   : TArray<TArray<TAnsiSegments>>;
  rowCount   : Integer;
  line       : TAnsiSegments;
  lineWidth  : Integer;
  gutter     : string;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;
  n := Length(FChildren);
  if n = 0 then Exit;

  if FExpand then
  begin
    // Allocate widths: equal split of (maxWidth - gutters), distributing any
    // remainder cells to the leftmost columns.
    available := maxWidth - FGutter * (n - 1);
    if available < n then available := n;
    colWidth  := available div n;
    remainder := available - colWidth * n;

    SetLength(widths, n);
    for i := 0 to n - 1 do
    begin
      widths[i] := colWidth;
      if i < remainder then
        Inc(widths[i]);
    end;
  end
  else
  begin
    // Spectre Expand=False: each column sized to its child's natural max.
    // If the resulting total still exceeds maxWidth, squeeze proportionally.
    available := maxWidth - FGutter * (n - 1);
    if available < n then available := n;

    SetLength(widths, n);
    colWidth := 0;
    for i := 0 to n - 1 do
    begin
      widths[i] := FChildren[i].Measure(options, available).Max;
      if widths[i] < 1 then widths[i] := 1;
      Inc(colWidth, widths[i]);
    end;
    if colWidth > available then
    begin
      // Shave one cell at a time from the widest column until we fit.
      while colWidth > available do
      begin
        remainder := -1;
        for i := 0 to n - 1 do
          if (remainder < 0) or (widths[i] > widths[remainder]) then
            remainder := i;
        if (remainder < 0) or (widths[remainder] <= 1) then Break;
        Dec(widths[remainder]);
        Dec(colWidth);
      end;
    end;
  end;

  // Render each child into its own line array.
  SetLength(rendered, n);
  rowCount := 0;
  for i := 0 to n - 1 do
  begin
    rendered[i] := SplitLines(FChildren[i].Render(options, widths[i]), widths[i]);
    if Length(rendered[i]) > rowCount then
      rowCount := Length(rendered[i]);
  end;

  gutter := StringOfChar(' ', FGutter);

  // Stitch row by row.
  for j := 0 to rowCount - 1 do
  begin
    for i := 0 to n - 1 do
    begin
      if j <= High(rendered[i]) then
      begin
        line := rendered[i][j];
        lineWidth := TotalCellCount(line);
        for k := 0 to High(line) do
          Push(line[k]);
        if lineWidth < widths[i] then
          Push(TAnsiSegment.Whitespace(StringOfChar(' ', widths[i] - lineWidth)));
      end
      else
      begin
        // this column has no content for this row - fill with spaces
        Push(TAnsiSegment.Whitespace(StringOfChar(' ', widths[i])));
      end;

      if (i < n - 1) and (FGutter > 0) then
        Push(TAnsiSegment.Whitespace(gutter));
    end;

    if j < rowCount - 1 then
      Push(TAnsiSegment.LineBreak);
  end;
end;

end.
