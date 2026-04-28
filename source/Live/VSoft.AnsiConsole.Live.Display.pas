unit VSoft.AnsiConsole.Live.Display;

{
  TLiveDisplay - renders a single IRenderable in place, letting the user's
  action callback swap the content via ctx.Update(new).

  Flow:
    1. Take the exclusivity lock; fail fast if another live display is active.
    2. Hide the cursor.
    3. Render the initial renderable; record the emitted line count.
    4. Invoke the user's action callback with a context that exposes Update/Refresh.
    5. On each Update: clear the previous lines, render the new content, record count.
    6. On exit: optionally auto-clear the final frame, show cursor, release lock.

  Thread-safety: all rendering goes through the IAnsiConsole's own lock, so
  Status and Progress can safely call Update from a background thread while
  the user's action runs on the main thread.
}

{$SCOPEDENUMS ON}

interface

uses
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Rendering;

type
  { Strategy for content taller than the terminal:
      Visible  - emit everything, let the terminal scroll (default,
                 matches the original behaviour and what every test
                 depends on);
      Crop     - drop the excess lines silently;
      Ellipsis - drop the excess lines and replace the cropped region
                 with a single ellipsis line. }
  TLiveOverflow = (Visible, Crop, Ellipsis);

  { Which end to drop when cropping:
      Top    - drop the top lines (keep the most recent content
               visible at the bottom; matches Spectre's default);
      Bottom - drop the bottom lines. }
  TLiveCropping = (Top, Bottom);

  ILiveDisplay = interface
    ['{A8C3E2B1-4D5F-4F1A-B2C9-4D6E8F0A2B10}']
    procedure Update(const renderable : IRenderable);
    procedure Refresh;
  end;

  TLiveDisplayAction = reference to procedure(const ctx : ILiveDisplay);

  ILiveDisplayConfig = interface
    ['{B6D4F1A2-9E8C-4A5B-8F7E-1C3D2B6A5E20}']
    function WithAutoClear(value : Boolean) : ILiveDisplayConfig;
    function WithOverflow(value : TLiveOverflow) : ILiveDisplayConfig;
    function WithCropping(value : TLiveCropping) : ILiveDisplayConfig;
    procedure Start(const action : TLiveDisplayAction);
  end;

function LiveDisplay(const console : IAnsiConsole;
                      const initial : IRenderable) : ILiveDisplayConfig;

implementation

uses
  System.SysUtils,
  System.SyncObjs,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Prompts.Common,   // HideCursor / ShowCursor / ClearPreviousLines
  VSoft.AnsiConsole.Internal.SegmentOps,  // SplitLines, SegmentCellCount
  VSoft.AnsiConsole.Live.Exclusivity;

const
  ESC = #27;

type
  TLiveDisplayImpl = class(TInterfacedObject, ILiveDisplay, ILiveDisplayConfig)
  strict private
    FConsole     : IAnsiConsole;
    FCurrent     : IRenderable;
    FAutoClear   : Boolean;
    FOverflow    : TLiveOverflow;
    FCropping    : TLiveCropping;
    FLineCount   : Integer;
    FShapeWidth  : Integer;  // inflated max width
    FShapeHeight : Integer;  // inflated max height
    FLock        : TCriticalSection;
    FStarted     : Boolean;

    { Render the current renderable, split into lines, pad each line out
      to the inflated shape width (with whitespace), and pad the bottom
      with blank lines up to the inflated shape height. The result is a
      single segment stream where every line is exactly FShapeWidth cells
      and there are exactly FShapeHeight lines, separated by LineBreaks
      (no trailing LineBreak). The shape only grows - never shrinks - so
      the redraw never needs to clear stale lines below. Mirrors
      Spectre.Console's LiveRenderable + SegmentShape behaviour. }
    function  BuildPaddedFrame : TAnsiSegments;

    procedure DrawInitial;
    procedure Redraw;
  public
    constructor Create(const console : IAnsiConsole; const initial : IRenderable);
    destructor  Destroy; override;

    { ILiveDisplay }
    procedure Update(const renderable : IRenderable);
    procedure Refresh;

    { ILiveDisplayConfig }
    function WithAutoClear(value : Boolean) : ILiveDisplayConfig;
    function WithOverflow(value : TLiveOverflow) : ILiveDisplayConfig;
    function WithCropping(value : TLiveCropping) : ILiveDisplayConfig;
    procedure Start(const action : TLiveDisplayAction);
  end;

function LiveDisplay(const console : IAnsiConsole;
                      const initial : IRenderable) : ILiveDisplayConfig;
begin
  result := TLiveDisplayImpl.Create(console, initial);
end;

{ TLiveDisplayImpl }

constructor TLiveDisplayImpl.Create(const console : IAnsiConsole;
                                     const initial : IRenderable);
begin
  inherited Create;
  FConsole := console;
  FCurrent := initial;
  FAutoClear := True;
  FOverflow := TLiveOverflow.Visible;   // default: don't crop, let the terminal scroll
  FCropping := TLiveCropping.Top;       // matches Spectre's VerticalOverflowCropping.Top
  FLock := TCriticalSection.Create;
end;

destructor TLiveDisplayImpl.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TLiveDisplayImpl.WithAutoClear(value : Boolean) : ILiveDisplayConfig;
begin
  FAutoClear := value;
  result := Self;
end;

function TLiveDisplayImpl.WithOverflow(value : TLiveOverflow) : ILiveDisplayConfig;
begin
  FOverflow := value;
  result := Self;
end;

function TLiveDisplayImpl.WithCropping(value : TLiveCropping) : ILiveDisplayConfig;
begin
  FCropping := value;
  result := Self;
end;

{ Render the current renderable into a uniformly-padded segment stream
  matching the inflated shape (max width/height ever seen). Each line is
  padded out to FShapeWidth cells with trailing whitespace, and missing
  lines (if the current frame is shorter than the inflated height) are
  emitted as full-width whitespace lines. LineBreaks separate lines but
  there is no trailing LineBreak, so the cursor ends at the right edge
  of the last line. }
function TLiveDisplayImpl.BuildPaddedFrame : TAnsiSegments;
const
  ELLIPSIS_UNICODE = #$2026;        // U+2026 HORIZONTAL ELLIPSIS
  ELLIPSIS_ASCII   = '...';
var
  opts        : TRenderOptions;
  rawSegs     : TAnsiSegments;
  lines       : TArray<TAnsiSegments>;
  lineWidths  : TArray<Integer>;
  i, j        : Integer;
  count       : Integer;
  lineW, padW : Integer;
  blankLine   : TAnsiSegment;
  maxHeight   : Integer;
  excess      : Integer;
  trimmed     : TArray<TAnsiSegments>;
  ellipsisLine : TAnsiSegments;
  ellipsisStr  : string;
  ellipsisStyle: TAnsiStyle;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;

  if FCurrent = nil then Exit;

  opts := TRenderOptions.Create(FConsole.Profile.Width, FConsole.Profile.Height,
                                  FConsole.Profile.Capabilities.ColorSystem);
  opts := opts.WithUnicode(FConsole.Profile.Capabilities.Unicode);
  rawSegs := FCurrent.Render(opts, FConsole.Profile.Width);
  lines := SplitLines(rawSegs, FConsole.Profile.Width);

  // Vertical overflow handling - trim the line list when the content is
  // taller than the terminal can show. Mirrors Spectre's LiveRenderable
  // Overflow + OverflowCropping behaviour.
  if (FOverflow <> TLiveOverflow.Visible) and (Length(lines) > 0) then
  begin
    maxHeight := FConsole.Profile.Height;
    if maxHeight < 1 then maxHeight := 1;
    if Length(lines) > maxHeight then
    begin
      // Build the ellipsis indicator line once; reused for both crop+ellipsis
      // and prepend/append. Spectre uses '…' on unicode, '...' otherwise.
      if opts.Unicode then
        ellipsisStr := ELLIPSIS_UNICODE
      else
        ellipsisStr := ELLIPSIS_ASCII;
      ellipsisStyle := TAnsiStyle.Plain.WithForeground(TAnsiColor.Yellow);
      SetLength(ellipsisLine, 1);
      ellipsisLine[0] := TAnsiSegment.Text(ellipsisStr, ellipsisStyle);

      excess := Length(lines) - maxHeight;
      case FOverflow of
        TLiveOverflow.Crop:
        begin
          if FCropping = TLiveCropping.Top then
          begin
            // Drop the first `excess` lines, keep the bottom maxHeight.
            SetLength(trimmed, maxHeight);
            for i := 0 to maxHeight - 1 do
              trimmed[i] := lines[i + excess];
            lines := trimmed;
          end
          else
          begin
            SetLength(lines, maxHeight);
          end;
        end;
        TLiveOverflow.Ellipsis:
        begin
          // Same as TLiveOverflow.Crop but reserve one row for the ellipsis line.
          if FCropping = TLiveCropping.Top then
          begin
            SetLength(trimmed, maxHeight);
            trimmed[0] := ellipsisLine;
            for i := 1 to maxHeight - 1 do
              trimmed[i] := lines[i + excess];
            lines := trimmed;
          end
          else
          begin
            SetLength(trimmed, maxHeight);
            for i := 0 to maxHeight - 2 do
              trimmed[i] := lines[i];
            trimmed[maxHeight - 1] := ellipsisLine;
            lines := trimmed;
          end;
        end;
      end;
    end;
    // Cap the inflated height at the terminal height while overflow is
    // active, otherwise prior taller frames would still try to repaint
    // their full inflated height now that the content is being trimmed.
    if FShapeHeight > maxHeight then
      FShapeHeight := maxHeight;
  end;

  // Per-line cell widths + shape inflation. The shape only grows, so a
  // frame that is narrower / shorter than a previous one still emits
  // full-shape-sized output via the padding below - the redraw geometry
  // therefore stays constant and never has to clear stale lines.
  SetLength(lineWidths, Length(lines));
  for i := 0 to High(lines) do
  begin
    lineW := 0;
    for j := 0 to High(lines[i]) do
      Inc(lineW, SegmentCellCount(lines[i][j]));
    lineWidths[i] := lineW;
    if lineW > FShapeWidth then
      FShapeWidth := lineW;
  end;
  if Length(lines) > FShapeHeight then
    FShapeHeight := Length(lines);

  if (FShapeWidth = 0) or (FShapeHeight = 0) then Exit;

  for i := 0 to FShapeHeight - 1 do
  begin
    if i < Length(lines) then
    begin
      for j := 0 to High(lines[i]) do
        Push(lines[i][j]);
      padW := FShapeWidth - lineWidths[i];
      if padW > 0 then
        Push(TAnsiSegment.Whitespace(StringOfChar(' ', padW)));
    end
    else
    begin
      // Blank padding line - full-width whitespace.
      blankLine := TAnsiSegment.Whitespace(StringOfChar(' ', FShapeWidth));
      Push(blankLine);
    end;
    if i < FShapeHeight - 1 then
      Push(TAnsiSegment.LineBreak);
  end;
end;

{ Initial draw - cursor is wherever the user left it. Emit the padded
  frame in one Write and record the line count for subsequent redraws. }
procedure TLiveDisplayImpl.DrawInitial;
var
  segs : TAnsiSegments;
begin
  segs := BuildPaddedFrame;
  if Length(segs) = 0 then
  begin
    FLineCount := 0;
    Exit;
  end;
  FConsole.Write(segs);
  FLineCount := FShapeHeight;
end;

{ Redraw - overwrite previous frame in a SINGLE Write to avoid flicker:
    1. CR + cursor-up to the start of the previous first line.
    2. Emit the padded frame. Because every line is padded to FShapeWidth
       with real whitespace, the new line content fully overwrites the
       previous frame's same line cell-for-cell - no ESC[K clears needed.
    3. Because the shape is inflated (never shrinks), the new frame has
       the same height as the previous one, so there is never any stale
       content below the cursor's final position to clear.
  Everything is one combined segment array -> one console.Write -> one
  flush, matching Spectre.Console's LiveRenderable redraw path. }
procedure TLiveDisplayImpl.Redraw;
var
  segs, combined : TAnsiSegments;
  i, count       : Integer;
  resetSeq       : string;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(combined, count + 1);
    combined[count] := seg;
    Inc(count);
  end;

begin
  if FCurrent = nil then Exit;

  segs := BuildPaddedFrame;
  if Length(segs) = 0 then Exit;

  SetLength(combined, 0);
  count := 0;

  // Cursor back to start of previous first line. FLineCount equals
  // FShapeHeight whenever there has been any prior draw.
  if FLineCount > 0 then
  begin
    resetSeq := #13;  // CR
    if FLineCount > 1 then
      resetSeq := resetSeq + ESC + '[' + IntToStr(FLineCount - 1) + 'A';
    Push(TAnsiSegment.ControlCode(resetSeq));
  end;

  for i := 0 to High(segs) do
    Push(segs[i]);

  FConsole.Write(combined);
  FLineCount := FShapeHeight;
end;

procedure TLiveDisplayImpl.Update(const renderable : IRenderable);
begin
  FLock.Enter;
  try
    FCurrent := renderable;
    if FStarted then
      Redraw;
  finally
    FLock.Leave;
  end;
end;

procedure TLiveDisplayImpl.Refresh;
begin
  FLock.Enter;
  try
    if FStarted then
      Redraw;
  finally
    FLock.Leave;
  end;
end;

procedure TLiveDisplayImpl.Start(const action : TLiveDisplayAction);
begin
  TLiveExclusivityLock.EnsureNotHeld;
  try
    HideCursor(FConsole);
    try
      FLock.Enter;
      try
        FStarted := True;
        DrawInitial;
      finally
        FLock.Leave;
      end;

      if Assigned(action) then
        action(Self);

      FLock.Enter;
      try
        if FAutoClear then
        begin
          ClearPreviousLines(FConsole, FLineCount);
          FLineCount := 0;
        end
        else if FLineCount > 0 then
        begin
          // After redraw the cursor sits at the right edge of the last
          // padded line. Emit a final newline so subsequent console output
          // starts at column 0 of a fresh line. Matches Spectre's
          // ProgressRenderer.Completed(false) -> _console.WriteLine().
          FConsole.WriteLine;
        end;
      finally
        FLock.Leave;
      end;
    finally
      ShowCursor(FConsole);
      FStarted := False;
    end;
  finally
    TLiveExclusivityLock.Leave;
  end;
end;

end.
