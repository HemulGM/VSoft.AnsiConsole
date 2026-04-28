unit VSoft.AnsiConsole.Widgets.BarChart;

{
  TBarChart - horizontal bar chart. Each row = label, bar, optional value.
  Columns auto-size: label takes the widest label's cell-width, value takes
  the widest formatted value's cell-width, and the bar fills the rest.

  Unicode bar character: '█' (U+2588). ASCII fallback: '#'.
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
  TBarValueFormatter = reference to function(value : Double) : string;

  IBarChartItem = interface
    ['{1C5E4F2B-8A3D-4B7E-9F10-2D6C4E3B5A80}']
    function GetLabel_ : string;
    function GetValue : Double;
    function GetColor : TAnsiColor;
    function GetHasColor : Boolean;
    property Label_  : string     read GetLabel_;
    property Value   : Double     read GetValue;
    property Color   : TAnsiColor read GetColor;
    property HasColor: Boolean    read GetHasColor;
  end;

  IBarChart = interface(IRenderable)
    ['{B7C3D2E5-1F8A-4D6B-A9C0-5E3F4B2D1A90}']
    function AddItem(const label_ : string; value : Double) : IBarChart; overload;
    function AddItem(const label_ : string; value : Double; const color : TAnsiColor) : IBarChart; overload;
    function WithWidth(value : Integer) : IBarChart;
    function WithLabel(const value : string) : IBarChart;
    function WithLabelAlignment(value : TAlignment) : IBarChart;
    function WithShowValues(value : Boolean) : IBarChart;
    function WithMaxValue(value : Double) : IBarChart;
    function WithValueFormatter(const formatter : TBarValueFormatter) : IBarChart;
  end;

  TBarChart = class(TInterfacedObject, IRenderable, IBarChart)
  strict private
    type
      TItemRec = record
        Label_   : string;
        Value    : Double;
        Color    : TAnsiColor;
        HasColor : Boolean;
      end;
    var
      FItems     : TArray<TItemRec>;
      FWidth     : Integer;     // 0 = use all available
      FLabel     : string;
      FLabelAlign: TAlignment;
      FShowValues: Boolean;
      FMaxValue  : Double;      // 0 = derive from items
      FFormatter : TBarValueFormatter;
  public
    constructor Create;
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
    function AddItem(const label_ : string; value : Double) : IBarChart; overload;
    function AddItem(const label_ : string; value : Double; const color : TAnsiColor) : IBarChart; overload;
    function WithWidth(value : Integer) : IBarChart;
    function WithLabel(const value : string) : IBarChart;
    function WithLabelAlignment(value : TAlignment) : IBarChart;
    function WithShowValues(value : Boolean) : IBarChart;
    function WithMaxValue(value : Double) : IBarChart;
    function WithValueFormatter(const formatter : TBarValueFormatter) : IBarChart;
  end;

function BarChart : IBarChart;

implementation

uses
  VSoft.AnsiConsole.Internal.Cell,
  VSoft.AnsiConsole.Internal.SegmentOps,
  VSoft.AnsiConsole.Markup.Parser;

const
  UNICODE_BAR = #$2588;  // '█'
  ASCII_BAR   = '#';

function BarChart : IBarChart;
begin
  result := TBarChart.Create;
end;

function DefaultFormat(value : Double) : string;
begin
  if Abs(value - Round(value)) < 1E-9 then
    result := IntToStr(Round(value))
  else
    result := FloatToStrF(value, ffFixed, 10, 2);
end;

{ TBarChart }

constructor TBarChart.Create;
begin
  inherited Create;
  FWidth      := 0;
  FLabelAlign := TAlignment.Center;
  FShowValues := True;
  FMaxValue   := 0;
  SetLength(FItems, 0);
end;

function TBarChart.AddItem(const label_ : string; value : Double) : IBarChart;
var
  rec : TItemRec;
begin
  rec.Label_   := label_;
  rec.Value    := value;
  rec.Color    := TAnsiColor.Default;
  rec.HasColor := False;
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := rec;
  result := Self;
end;

function TBarChart.AddItem(const label_ : string; value : Double; const color : TAnsiColor) : IBarChart;
var
  rec : TItemRec;
begin
  rec.Label_   := label_;
  rec.Value    := value;
  rec.Color    := color;
  rec.HasColor := not color.IsDefault;
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := rec;
  result := Self;
end;

function TBarChart.WithWidth(value : Integer) : IBarChart;
begin
  FWidth := value;
  result := Self;
end;

function TBarChart.WithLabel(const value : string) : IBarChart;
begin
  FLabel := value;
  result := Self;
end;

function TBarChart.WithLabelAlignment(value : TAlignment) : IBarChart;
begin
  FLabelAlign := value;
  result := Self;
end;

function TBarChart.WithShowValues(value : Boolean) : IBarChart;
begin
  FShowValues := value;
  result := Self;
end;

function TBarChart.WithMaxValue(value : Double) : IBarChart;
begin
  FMaxValue := value;
  result := Self;
end;

function TBarChart.WithValueFormatter(const formatter : TBarValueFormatter) : IBarChart;
begin
  FFormatter := formatter;
  result := Self;
end;

function TBarChart.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
var
  w : Integer;
begin
  if FWidth > 0 then w := FWidth else w := maxWidth;
  if w > maxWidth then w := maxWidth;
  result := TMeasurement.Create(w, w);
end;

function FormatItemValue(const formatter : TBarValueFormatter; value : Double) : string;
begin
  if Assigned(formatter) then
    result := formatter(value)
  else
    result := DefaultFormat(value);
end;

function TBarChart.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  totalWidth : Integer;
  labelColW  : Integer;
  valueColW  : Integer;
  barColW    : Integer;
  maxV       : Double;
  i, count   : Integer;
  cellCount  : Integer;
  fmt        : string;
  bar        : string;
  pad        : Integer;
  barChar    : string;
  filledCells: Integer;
  style      : TAnsiStyle;
  labelCellLen : Integer;
  labelPad   : Integer;
  valuePad   : Integer;
  valueCells : Integer;
  lblWidth   : Integer;
  lblPadL, lblPadR : Integer;
  labelSegs  : TAnsiSegments;
  itemLabelSegs : TAnsiSegments;
  li         : Integer;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;

  if FWidth > 0 then totalWidth := FWidth else totalWidth := maxWidth;
  if totalWidth > maxWidth then totalWidth := maxWidth;
  if totalWidth < 4 then totalWidth := 4;

  // Compute column widths
  labelColW := 0;
  valueColW := 0;
  maxV := 0;
  for i := 0 to High(FItems) do
  begin
    // Use the cell-width of the rendered (markup-parsed) label so style
    // tags don't inflate the reserved column.
    cellCount := TotalCellCount(ParseMarkup(FItems[i].Label_));
    if cellCount > labelColW then labelColW := cellCount;
    if FItems[i].Value > maxV then maxV := FItems[i].Value;
    if FShowValues then
    begin
      fmt := FormatItemValue(FFormatter, FItems[i].Value);
      cellCount := CellLength(fmt);
      if cellCount > valueColW then valueColW := cellCount;
    end;
  end;
  if FMaxValue > maxV then maxV := FMaxValue;
  if maxV <= 0 then maxV := 1;

  // Layout: label, 2-space gap, bar, 1-space gap, value
  // If no values column, bar takes the remainder.
  barColW := totalWidth - labelColW - 2;
  if FShowValues and (valueColW > 0) then
    barColW := barColW - (valueColW + 1);
  if barColW < 1 then
  begin
    // if the label crowds out the bar, give the label less room
    labelColW := totalWidth - 2;
    if FShowValues and (valueColW > 0) then
      labelColW := labelColW - (valueColW + 1) - 1;
    if labelColW < 0 then labelColW := 0;
    barColW := totalWidth - labelColW - 2;
    if FShowValues and (valueColW > 0) then
      barColW := barColW - (valueColW + 1);
    if barColW < 1 then barColW := 1;
  end;

  if options.Unicode then barChar := UNICODE_BAR else barChar := ASCII_BAR;

  // Optional label row: centred across totalWidth. Routed through the
  // markup parser so callers can write '[bold]Languages[/]' etc.
  if FLabel <> '' then
  begin
    labelSegs := ParseMarkup(FLabel);
    lblWidth := TotalCellCount(labelSegs);
    if lblWidth > totalWidth then lblWidth := totalWidth;
    case FLabelAlign of
      TAlignment.Center:
      begin
        lblPadL := (totalWidth - lblWidth) div 2;
        lblPadR := totalWidth - lblWidth - lblPadL;
      end;
      TAlignment.Right:
      begin
        lblPadL := totalWidth - lblWidth;
        lblPadR := 0;
      end;
    else
      lblPadL := 0;
      lblPadR := totalWidth - lblWidth;
    end;
    if lblPadL > 0 then
      Push(TAnsiSegment.Whitespace(StringOfChar(' ', lblPadL)));
    for li := 0 to High(labelSegs) do
      Push(labelSegs[li]);
    if lblPadR > 0 then
      Push(TAnsiSegment.Whitespace(StringOfChar(' ', lblPadR)));
    Push(TAnsiSegment.LineBreak);
  end;

  for i := 0 to High(FItems) do
  begin
    // Per-bar label, right-padded. Routed through the markup parser so
    // callers can write e.g. '[bold]Pascal[/]' as the item label.
    itemLabelSegs := ParseMarkup(FItems[i].Label_);
    labelCellLen := TotalCellCount(itemLabelSegs);
    if labelCellLen > labelColW then
    begin
      // We don't have a nice truncation helper for parsed segments; fall
      // back to a cell-naive copy of the raw text.
      Push(TAnsiSegment.Text(Copy(FItems[i].Label_, 1, labelColW)));
      labelPad := 0;
    end
    else
    begin
      for li := 0 to High(itemLabelSegs) do
        Push(itemLabelSegs[li]);
      labelPad := labelColW - labelCellLen;
    end;
    if labelPad > 0 then
      Push(TAnsiSegment.Whitespace(StringOfChar(' ', labelPad)));
    Push(TAnsiSegment.Whitespace('  '));

    // Bar
    filledCells := 0;
    if maxV > 0 then
      filledCells := Round((FItems[i].Value / maxV) * barColW);
    if filledCells < 0 then filledCells := 0;
    if filledCells > barColW then filledCells := barColW;
    if filledCells > 0 then
    begin
      bar := StringOfChar(barChar[1], filledCells);
      if FItems[i].HasColor then
        style := TAnsiStyle.Plain.WithForeground(FItems[i].Color)
      else
        style := TAnsiStyle.Plain;
      Push(TAnsiSegment.Text(bar, style));
    end;
    pad := barColW - filledCells;
    if pad > 0 then
      Push(TAnsiSegment.Whitespace(StringOfChar(' ', pad)));

    // Value (right-aligned in valueColW)
    if FShowValues and (valueColW > 0) then
    begin
      Push(TAnsiSegment.Whitespace(' '));
      fmt := FormatItemValue(FFormatter, FItems[i].Value);
      valueCells := CellLength(fmt);
      valuePad := valueColW - valueCells;
      if valuePad < 0 then valuePad := 0;
      if valuePad > 0 then
        Push(TAnsiSegment.Whitespace(StringOfChar(' ', valuePad)));
      Push(TAnsiSegment.Text(fmt));
    end;

    if i < High(FItems) then
      Push(TAnsiSegment.LineBreak);
  end;
end;

end.
