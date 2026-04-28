unit VSoft.AnsiConsole.Widgets.Canvas;

{
  TCanvas - a fixed-size pixel grid. Unicode mode packs two vertical pixels
  per terminal cell using the upper-half block ('▀') with:
    foreground = top pixel, background = bottom pixel.
  Transparent pixels emit a plain space.

  ASCII fallback: one pixel per two-space cell, background-coloured.

  Pixels are stored as FPixels[x, y] where (0,0) is the top-left.
}

interface

uses
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering;

type
  TCanvasPixel = record
    FHasColor : Boolean;
    FColor    : TAnsiColor;
  end;

  ICanvas = interface(IRenderable)
    ['{A8E2F1C0-9B5D-4F3A-8E71-2C4D5B6A7E80}']
    function GetWidth : Integer;
    function GetHeight : Integer;
    function SetPixel(x, y : Integer; const color : TAnsiColor) : ICanvas;
    function ClearPixel(x, y : Integer) : ICanvas;
    function WithMaxWidth(value : Integer) : ICanvas;
    function WithScale(value : Boolean) : ICanvas;
    property Width  : Integer read GetWidth;
    property Height : Integer read GetHeight;
  end;

  TCanvasPixelGrid = array of array of TCanvasPixel;

  TCanvas = class(TInterfacedObject, IRenderable, ICanvas)
  strict private
    FWidth     : Integer;
    FHeight    : Integer;
    FMaxWidth  : Integer;   // -1 = no cap
    FScale     : Boolean;   // True = scale down to MaxWidth, False = clip
    FPixels    : TCanvasPixelGrid;
    function GetWidth  : Integer;
    function GetHeight : Integer;
    { Returns the pixel grid to render. When FMaxWidth caps the visible width
      and FScale=True, the grid is resampled with nearest-neighbour to the
      target dimensions; when FScale=False, the original grid is returned and
      the caller crops. effW / effH are the pixel dimensions of the returned
      grid. }
    procedure GetEffectivePixels(targetPixelWidth : Integer;
                                  out grid : TCanvasPixelGrid;
                                  out effW, effH : Integer);
  public
    constructor Create(width, height : Integer);
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
    function SetPixel(x, y : Integer; const color : TAnsiColor) : ICanvas;
    function ClearPixel(x, y : Integer) : ICanvas;
    function WithMaxWidth(value : Integer) : ICanvas;
    function WithScale(value : Boolean) : ICanvas;
  end;

function Canvas(width, height : Integer) : ICanvas;

implementation

uses
  System.SysUtils;

const
  UPPER_HALF = #$2580;  // '▀'

function Canvas(width, height : Integer) : ICanvas;
begin
  result := TCanvas.Create(width, height);
end;

{ TCanvas }

constructor TCanvas.Create(width, height : Integer);
var
  x, y : Integer;
begin
  inherited Create;
  if width  < 1 then width  := 1;
  if height < 1 then height := 1;
  FWidth  := width;
  FHeight := height;
  FMaxWidth := -1;
  FScale    := True;
  SetLength(FPixels, width, height);
  for x := 0 to width - 1 do
    for y := 0 to height - 1 do
    begin
      FPixels[x, y].FHasColor := False;
      FPixels[x, y].FColor    := TAnsiColor.Default;
    end;
end;

procedure TCanvas.GetEffectivePixels(targetPixelWidth : Integer;
                                       out grid : TCanvasPixelGrid;
                                       out effW, effH : Integer);
var
  x, y   : Integer;
  sx, sy : Integer;
begin
  // No scaling needed: caller fits within the source pixels.
  if (targetPixelWidth <= 0) or (targetPixelWidth >= FWidth) or (not FScale) then
  begin
    grid := FPixels;
    effW := FWidth;
    effH := FHeight;
    Exit;
  end;

  // Nearest-neighbour resample. Maintain aspect ratio so a 16x16 canvas
  // capped at MaxWidth=8 collapses to 8x8 (in unicode mode that becomes 8
  // cells wide x 4 cells tall after the half-block packing).
  effW := targetPixelWidth;
  effH := Round(FHeight * (targetPixelWidth / FWidth));
  if effH < 1 then effH := 1;
  SetLength(grid, effW, effH);

  for x := 0 to effW - 1 do
  begin
    sx := Round((x + 0.5) * FWidth / effW);
    if sx < 0 then sx := 0;
    if sx >= FWidth then sx := FWidth - 1;
    for y := 0 to effH - 1 do
    begin
      sy := Round((y + 0.5) * FHeight / effH);
      if sy < 0 then sy := 0;
      if sy >= FHeight then sy := FHeight - 1;
      grid[x, y] := FPixels[sx, sy];
    end;
  end;
end;

function TCanvas.WithMaxWidth(value : Integer) : ICanvas;
begin
  if value < 1 then FMaxWidth := -1 else FMaxWidth := value;
  result := Self;
end;

function TCanvas.WithScale(value : Boolean) : ICanvas;
begin
  FScale := value;
  result := Self;
end;

function TCanvas.GetWidth : Integer;
begin
  result := FWidth;
end;

function TCanvas.GetHeight : Integer;
begin
  result := FHeight;
end;

function TCanvas.SetPixel(x, y : Integer; const color : TAnsiColor) : ICanvas;
begin
  if (x >= 0) and (x < FWidth) and (y >= 0) and (y < FHeight) then
  begin
    FPixels[x, y].FHasColor := True;
    FPixels[x, y].FColor    := color;
  end;
  result := Self;
end;

function TCanvas.ClearPixel(x, y : Integer) : ICanvas;
begin
  if (x >= 0) and (x < FWidth) and (y >= 0) and (y < FHeight) then
  begin
    FPixels[x, y].FHasColor := False;
    FPixels[x, y].FColor    := TAnsiColor.Default;
  end;
  result := Self;
end;

function TCanvas.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
var
  pixelCells : Integer;
  need       : Integer;
begin
  if options.Unicode then pixelCells := 1 else pixelCells := 2;
  need := FWidth * pixelCells;
  if need > maxWidth then need := maxWidth;
  result := TMeasurement.Create(need, need);
end;

function TCanvas.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  x, y, count : Integer;
  upper, lower : TCanvasPixel;
  style  : TAnsiStyle;
  widthLimit : Integer;
  grid       : TCanvasPixelGrid;
  effW, effH : Integer;
  targetW    : Integer;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;

  if options.Unicode then
  begin
    // Compute the target pixel-width budget (1 pixel per cell horizontally
    // in unicode mode). Both maxWidth and FMaxWidth shrink it.
    targetW := FWidth;
    if targetW > maxWidth then targetW := maxWidth;
    if (FMaxWidth > 0) and (targetW > FMaxWidth) then
      targetW := FMaxWidth;

    GetEffectivePixels(targetW, grid, effW, effH);
    widthLimit := effW;
    if widthLimit > targetW then widthLimit := targetW;

    y := 0;
    while y < effH do
    begin
      for x := 0 to widthLimit - 1 do
      begin
        upper := grid[x, y];
        if y + 1 < effH then
          lower := grid[x, y + 1]
        else
        begin
          lower.FHasColor := False;
          lower.FColor    := TAnsiColor.Default;
        end;

        if (not upper.FHasColor) and (not lower.FHasColor) then
        begin
          Push(TAnsiSegment.Text(' '));
        end
        else if upper.FHasColor and lower.FHasColor then
        begin
          style := TAnsiStyle.Plain.WithForeground(upper.FColor).WithBackground(lower.FColor);
          Push(TAnsiSegment.Text(UPPER_HALF, style));
        end
        else if upper.FHasColor then
        begin
          style := TAnsiStyle.Plain.WithForeground(upper.FColor);
          Push(TAnsiSegment.Text(UPPER_HALF, style));
        end
        else
        begin
          style := TAnsiStyle.Plain.WithForeground(lower.FColor);
          Push(TAnsiSegment.Text(#$2584, style));  // '▄' lower half
        end;
      end;
      Push(TAnsiSegment.LineBreak);
      Inc(y, 2);
    end;
  end
  else
  begin
    // ASCII mode: 1 pixel = 2 cells horizontally. Convert FMaxWidth and
    // maxWidth (cell budgets) into a pixel-width budget before resampling.
    targetW := FWidth;
    if targetW * 2 > maxWidth then targetW := maxWidth div 2;
    if (FMaxWidth > 0) and (targetW * 2 > FMaxWidth) then
      targetW := FMaxWidth div 2;

    GetEffectivePixels(targetW, grid, effW, effH);
    widthLimit := effW;
    if widthLimit > targetW then widthLimit := targetW;

    for y := 0 to effH - 1 do
    begin
      for x := 0 to widthLimit - 1 do
      begin
        if grid[x, y].FHasColor then
        begin
          style := TAnsiStyle.Plain.WithBackground(grid[x, y].FColor);
          Push(TAnsiSegment.Text('  ', style));
        end
        else
          Push(TAnsiSegment.Text('  '));
      end;
      Push(TAnsiSegment.LineBreak);
    end;
  end;
end;

end.
