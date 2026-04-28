unit VSoft.AnsiConsole.Widgets.Rows;

{
  TRows - vertical stack of IRenderable children. Each child is rendered at
  the same maxWidth and its segments are emitted in order with a linebreak
  between successive children.
}

interface

uses
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering;

type
  IRows = interface(IRenderable)
    ['{4F4F3A8D-2A2D-4B4A-9C40-B1C8F2F0D201}']
    function Add(const child : IRenderable) : IRows;
    function Count : Integer;
    function WithExpand(value : Boolean) : IRows;
  end;

  TRows = class(TInterfacedObject, IRenderable, IRows)
  strict private
    FChildren : TArray<IRenderable>;
    FExpand   : Boolean;
  public
    function Add(const child : IRenderable) : IRows;
    function Count : Integer;
    function WithExpand(value : Boolean) : IRows;
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
  end;

function Rows : IRows;

implementation

function Rows : IRows;
begin
  result := TRows.Create;
end;

{ TRows }

function TRows.Add(const child : IRenderable) : IRows;
begin
  if child <> nil then
  begin
    SetLength(FChildren, Length(FChildren) + 1);
    FChildren[High(FChildren)] := child;
  end;
  result := Self;
end;

function TRows.Count : Integer;
begin
  result := Length(FChildren);
end;

function TRows.WithExpand(value : Boolean) : IRows;
begin
  FExpand := value;
  result := Self;
end;

function TRows.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
var
  i : Integer;
  m : TMeasurement;
  minW, maxW : Integer;
begin
  minW := 0;
  maxW := 0;
  for i := 0 to High(FChildren) do
  begin
    m := FChildren[i].Measure(options, maxWidth);
    if m.Min > minW then minW := m.Min;
    if m.Max > maxW then maxW := m.Max;
  end;
  result := TMeasurement.Create(minW, maxW);
end;

function TRows.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  i, j           : Integer;
  count          : Integer;
  segs           : TAnsiSegments;
  m              : TMeasurement;
  effectiveWidth : Integer;
begin
  SetLength(result, 0);
  count := 0;

  // Spectre default: Expand=False means the stack sizes to the widest child's
  // natural max (capped at maxWidth). With Expand=True, fall back to the full
  // maxWidth so children that fill (Padder, Panel, Align, ...) span the row.
  if FExpand then
    effectiveWidth := maxWidth
  else
  begin
    effectiveWidth := 0;
    for i := 0 to High(FChildren) do
    begin
      m := FChildren[i].Measure(options, maxWidth);
      if m.Max > effectiveWidth then
        effectiveWidth := m.Max;
    end;
    if effectiveWidth > maxWidth then
      effectiveWidth := maxWidth;
    if effectiveWidth < 1 then
      effectiveWidth := 1;
  end;

  for i := 0 to High(FChildren) do
  begin
    segs := FChildren[i].Render(options, effectiveWidth);
    for j := 0 to High(segs) do
    begin
      SetLength(result, count + 1);
      result[count] := segs[j];
      Inc(count);
    end;
    if i < High(FChildren) then
    begin
      SetLength(result, count + 1);
      result[count] := TAnsiSegment.LineBreak;
      Inc(count);
    end;
  end;
end;

end.
