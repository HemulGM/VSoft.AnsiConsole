unit VSoft.AnsiConsole.Widgets.BreakdownChart;

{
  TBreakdownChart - single horizontal bar split by proportional segments,
  followed by a tag row listing each item's colour swatch, label and value.

    ████████████▓▓▓▓▓░░░░░
    ■ Elixir 35  ■ C# 27  ■ Ruby 15

  Unicode segment char: '█'. ASCII fallback: '#'.
  Tag swatch: '■' (unicode) or '#' (ASCII).
}

interface

uses
  System.SysUtils,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering;

type
  TBreakdownValueFormatter = reference to function(value : Double) : string;

  IBreakdownChart = interface(IRenderable)
    ['{E9F4C3D2-7B1A-4E6F-8A20-5C3D4E5F6A00}']
    function AddItem(const label_ : string; value : Double; const color : TAnsiColor) : IBreakdownChart;
    function WithWidth(value : Integer) : IBreakdownChart;
    function WithShowTags(value : Boolean) : IBreakdownChart;
    function WithShowTagValues(value : Boolean) : IBreakdownChart;
    function WithCompact(value : Boolean) : IBreakdownChart;
    function WithValueFormatter(const formatter : TBreakdownValueFormatter) : IBreakdownChart;
    function WithValueColor(const value : TAnsiColor) : IBreakdownChart;
    function WithExpand(value : Boolean) : IBreakdownChart;
  end;

  TBreakdownChart = class(TInterfacedObject, IRenderable, IBreakdownChart)
  strict private
    type
      TItemRec = record
        Label_ : string;
        Value  : Double;
        Color  : TAnsiColor;
      end;
    var
      FItems        : TArray<TItemRec>;
      FWidth        : Integer;
      FShowTags     : Boolean;
      FShowTagValue : Boolean;
      FCompact      : Boolean;
      FExpand       : Boolean;
      FFormatter    : TBreakdownValueFormatter;
      FValueColor   : TAnsiColor;
  public
    constructor Create;
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
    function AddItem(const label_ : string; value : Double; const color : TAnsiColor) : IBreakdownChart;
    function WithWidth(value : Integer) : IBreakdownChart;
    function WithShowTags(value : Boolean) : IBreakdownChart;
    function WithShowTagValues(value : Boolean) : IBreakdownChart;
    function WithCompact(value : Boolean) : IBreakdownChart;
    function WithValueFormatter(const formatter : TBreakdownValueFormatter) : IBreakdownChart;
    function WithValueColor(const value : TAnsiColor) : IBreakdownChart;
    function WithExpand(value : Boolean) : IBreakdownChart;
  end;

function BreakdownChart : IBreakdownChart;

implementation

uses
  VSoft.AnsiConsole.Internal.Cell,
  VSoft.AnsiConsole.Internal.SegmentOps,
  VSoft.AnsiConsole.Markup.Parser;

const
  UNICODE_BLOCK = #$2588;  // '█'
  UNICODE_SWATCH= #$25A0;  // '■'
  ASCII_BLOCK   = '#';
  ASCII_SWATCH  = '#';

function BreakdownChart : IBreakdownChart;
begin
  result := TBreakdownChart.Create;
end;

function DefaultFormat(value : Double) : string;
begin
  if Abs(value - Round(value)) < 1E-9 then
    result := IntToStr(Round(value))
  else
    result := FloatToStrF(value, ffFixed, 10, 2);
end;

{ TBreakdownChart }

constructor TBreakdownChart.Create;
begin
  inherited Create;
  FWidth        := 0;
  FShowTags     := True;
  FShowTagValue := True;
  FCompact      := True;
  FExpand       := True;  // Spectre default
  FValueColor   := TAnsiColor.Grey;
end;

function TBreakdownChart.AddItem(const label_ : string; value : Double; const color : TAnsiColor) : IBreakdownChart;
var
  rec : TItemRec;
begin
  rec.Label_ := label_;
  rec.Value  := value;
  rec.Color  := color;
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := rec;
  result := Self;
end;

function TBreakdownChart.WithWidth(value : Integer) : IBreakdownChart;
begin
  FWidth := value;
  result := Self;
end;

function TBreakdownChart.WithShowTags(value : Boolean) : IBreakdownChart;
begin
  FShowTags := value;
  result := Self;
end;

function TBreakdownChart.WithShowTagValues(value : Boolean) : IBreakdownChart;
begin
  FShowTagValue := value;
  result := Self;
end;

function TBreakdownChart.WithCompact(value : Boolean) : IBreakdownChart;
begin
  FCompact := value;
  result := Self;
end;

function TBreakdownChart.WithValueFormatter(const formatter : TBreakdownValueFormatter) : IBreakdownChart;
begin
  FFormatter := formatter;
  result := Self;
end;

function TBreakdownChart.WithValueColor(const value : TAnsiColor) : IBreakdownChart;
begin
  FValueColor := value;
  result := Self;
end;

function TBreakdownChart.WithExpand(value : Boolean) : IBreakdownChart;
begin
  FExpand := value;
  result := Self;
end;

function TBreakdownChart.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
var
  w : Integer;
begin
  if FWidth > 0 then w := FWidth else w := maxWidth;
  if w > maxWidth then w := maxWidth;
  result := TMeasurement.Create(w, w);
end;

function TBreakdownChart.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  totalWidth : Integer;
  total      : Double;
  i          : Integer;
  count      : Integer;
  remaining  : Integer;
  cells      : Integer;
  spent      : Integer;
  blockCh    : string;
  swatchCh   : string;
  style      : TAnsiStyle;
  tagCells   : Integer;
  labelSegs  : TAnsiSegments;
  labelCells : Integer;
  li         : Integer;
  lineUsed   : Integer;
  first      : Boolean;
  widthPx    : array of Integer;
  biggest    : Integer;
  biggestVal : Integer;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

  function FormatValue(v : Double) : string;
  begin
    if Assigned(FFormatter) then
      result := FFormatter(v)
    else
      result := DefaultFormat(v);
  end;

begin
  SetLength(result, 0);
  count := 0;

  if FWidth > 0 then totalWidth := FWidth else totalWidth := maxWidth;
  if totalWidth > maxWidth then totalWidth := maxWidth;
  if totalWidth < 1 then totalWidth := 1;

  total := 0;
  for i := 0 to High(FItems) do
    total := total + FItems[i].Value;
  if total <= 0 then
  begin
    // Empty bar
    Push(TAnsiSegment.Whitespace(StringOfChar(' ', totalWidth)));
    Exit;
  end;

  if options.Unicode then blockCh := UNICODE_BLOCK else blockCh := ASCII_BLOCK;
  if options.Unicode then swatchCh := UNICODE_SWATCH else swatchCh := ASCII_SWATCH;

  // Pre-compute cell counts so small values get at least 1 cell if possible
  // and the total equals totalWidth. Use largest-remainder-ish: round down,
  // then give any leftover cells to the item with the largest fractional part.
  SetLength(widthPx, Length(FItems));
  spent := 0;
  for i := 0 to High(FItems) do
  begin
    cells := Trunc((FItems[i].Value / total) * totalWidth);
    if (cells = 0) and (FItems[i].Value > 0) then
      cells := 1;
    widthPx[i] := cells;
    Inc(spent, cells);
  end;
  // Trim from or add to the largest-value item until spent = totalWidth.
  while spent > totalWidth do
  begin
    biggest := 0;
    biggestVal := widthPx[0];
    for i := 1 to High(FItems) do
      if widthPx[i] > biggestVal then begin biggest := i; biggestVal := widthPx[i]; end;
    if widthPx[biggest] <= 0 then Break;
    Dec(widthPx[biggest]);
    Dec(spent);
  end;
  while spent < totalWidth do
  begin
    biggest := 0;
    biggestVal := widthPx[0];
    for i := 1 to High(FItems) do
      if widthPx[i] > biggestVal then begin biggest := i; biggestVal := widthPx[i]; end;
    Inc(widthPx[biggest]);
    Inc(spent);
  end;

  // The bar row
  remaining := totalWidth;
  for i := 0 to High(FItems) do
  begin
    cells := widthPx[i];
    if cells > remaining then cells := remaining;
    if cells <= 0 then Continue;
    style := TAnsiStyle.Plain.WithForeground(FItems[i].Color);
    Push(TAnsiSegment.Text(StringOfChar(blockCh[1], cells), style));
    Dec(remaining, cells);
  end;
  if remaining > 0 then
    Push(TAnsiSegment.Whitespace(StringOfChar(' ', remaining)));

  if FShowTags and (Length(FItems) > 0) then
  begin
    Push(TAnsiSegment.LineBreak);
    if not FCompact then
      Push(TAnsiSegment.LineBreak);

    lineUsed := 0;
    first := True;
    for i := 0 to High(FItems) do
    begin
      // Parse the label as markup so users can include style tags in
      // segment names; cell width comes from the parsed segments so a
      // tag like '[bold]C#[/]' reports 2 cells, not 12.
      labelSegs := ParseMarkup(FItems[i].Label_);
      labelCells := TotalCellCount(labelSegs);
      // tagCells = swatch (1) + space (1) + label cells [+ space + value]
      tagCells := 1 + 1 + labelCells;
      if FShowTagValue then
        tagCells := tagCells + 1 + CellLength(FormatValue(FItems[i].Value));

      if (not first) and (lineUsed + tagCells + 2 > totalWidth) then
      begin
        Push(TAnsiSegment.LineBreak);
        lineUsed := 0;
        first := True;
      end;

      if not first then
      begin
        Push(TAnsiSegment.Whitespace('  '));
        Inc(lineUsed, 2);
      end;

      style := TAnsiStyle.Plain.WithForeground(FItems[i].Color);
      Push(TAnsiSegment.Text(swatchCh, style));
      Push(TAnsiSegment.Whitespace(' '));
      // Emit each parsed label segment (preserves any styled spans).
      for li := 0 to High(labelSegs) do
        Push(labelSegs[li]);
      // Optional value rendered with FValueColor (defaults to Grey).
      if FShowTagValue then
      begin
        Push(TAnsiSegment.Whitespace(' '));
        Push(TAnsiSegment.Text(FormatValue(FItems[i].Value),
                                TAnsiStyle.Plain.WithForeground(FValueColor)));
      end;
      Inc(lineUsed, tagCells);
      first := False;
    end;
  end;
end;

end.
