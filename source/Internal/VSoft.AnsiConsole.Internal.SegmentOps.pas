unit VSoft.AnsiConsole.Internal.SegmentOps;

{
  Segment array operations: measurement, splitting, merging, line-wrapping.
  These are pure functions - they return new arrays rather than mutating.
}

interface

uses
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment;

{ Cell width of a single non-linebreak segment. }
function SegmentCellCount(const seg : TAnsiSegment) : Integer;

{ Cell width of a segment array, treating line breaks as resetting to zero
  (i.e. returns the width of the longest line). }
function TotalCellCount(const segs : TAnsiSegments) : Integer;

{ Split a text or whitespace segment at a cell offset. ControlCode and
  LineBreak segments are returned unchanged as `left`, and `right` is empty. }
procedure SplitSegmentAt(const seg : TAnsiSegment; cellOffset : Integer;
                          out left, right : TAnsiSegment);

{ Coalesce adjacent text segments that share the same style. Whitespace,
  line-break and control-code segments are left as independent items. }
function MergeSegments(const segs : TAnsiSegments) : TAnsiSegments;

{ Break segments into an array of lines. A line ends at an TAnsiSegmentFlag.LineBreak segment
  or when the running cell-width reaches maxWidth (hard wrap). Segments wider
  than maxWidth are split at the boundary. Returns an array of per-line
  segment arrays (the trailing linebreak segment is not included in each line).

  Phase 1: hard character wrap. Word wrap is the Text widget's responsibility. }
function SplitLines(const segs : TAnsiSegments; maxWidth : Integer) : TArray<TAnsiSegments>;

{ Truncate a single line to maxWidth cells. If the line already fits the
  function returns it unchanged. If `addEllipsis` is True and the line had
  to be cropped, an ellipsis ('...') is appended (using the trailing
  segment's style); the truncation budget shrinks by the ellipsis width
  so the result fits in maxWidth. }
function CropLineToWidth(const line : TAnsiSegments; maxWidth : Integer;
                          addEllipsis : Boolean) : TAnsiSegments;

implementation

uses
  VSoft.AnsiConsole.Internal.Cell;

function SegmentCellCount(const seg : TAnsiSegment) : Integer;
begin
  if seg.IsLineBreak or seg.IsControlCode then
    result := 0
  else
    result := CellLength(seg.Value);
end;

function TotalCellCount(const segs : TAnsiSegments) : Integer;
var
  i    : Integer;
  line : Integer;
begin
  result := 0;
  line   := 0;
  for i := 0 to High(segs) do
  begin
    if segs[i].IsLineBreak then
    begin
      if line > result then
        result := line;
      line := 0;
    end
    else
      Inc(line, SegmentCellCount(segs[i]));
  end;
  if line > result then
    result := line;
end;

procedure SplitSegmentAt(const seg : TAnsiSegment; cellOffset : Integer;
                          out left, right : TAnsiSegment);
var
  i       : Integer;
  running : Integer;
  txt     : string;
  style   : TAnsiStyle;
begin
  if seg.IsLineBreak or seg.IsControlCode then
  begin
    left := seg;
    right := TAnsiSegment.Text('');
    Exit;
  end;

  txt := seg.Value;
  style := seg.Style;

  if cellOffset <= 0 then
  begin
    left := TAnsiSegment.Text('', style);
    right := seg;
    Exit;
  end;

  running := 0;
  for i := 1 to Length(txt) do
  begin
    if running >= cellOffset then
    begin
      if seg.IsWhitespace then
        left := TAnsiSegment.Whitespace(Copy(txt, 1, i - 1), style)
      else
        left := TAnsiSegment.Text(Copy(txt, 1, i - 1), style);
      if seg.IsWhitespace then
        right := TAnsiSegment.Whitespace(Copy(txt, i, MaxInt), style)
      else
        right := TAnsiSegment.Text(Copy(txt, i, MaxInt), style);
      Exit;
    end;
    Inc(running, CellLengthChar(txt[i]));
  end;

  // cellOffset >= segment width: all on the left
  left := seg;
  right := TAnsiSegment.Text('', style);
end;

function MergeSegments(const segs : TAnsiSegments) : TAnsiSegments;
var
  i     : Integer;
  count : Integer;
  buf   : string;
  style : TAnsiStyle;
  inRun : Boolean;

  procedure Flush;
  begin
    if inRun then
    begin
      if Length(result) <= count then
        SetLength(result, count + 1);
      result[count] := TAnsiSegment.Text(buf, style);
      Inc(count);
      inRun := False;
      buf := '';
    end;
  end;

begin
  SetLength(result, Length(segs));
  count := 0;
  inRun := False;
  buf := '';
  style := TAnsiStyle.Plain;

  for i := 0 to High(segs) do
  begin
    if segs[i].IsLineBreak or segs[i].IsWhitespace or segs[i].IsControlCode then
    begin
      Flush;
      result[count] := segs[i];
      Inc(count);
      Continue;
    end;

    if inRun and segs[i].Style.Equals(style) then
    begin
      buf := buf + segs[i].Value;
    end
    else
    begin
      Flush;
      buf := segs[i].Value;
      style := segs[i].Style;
      inRun := True;
    end;
  end;
  Flush;

  SetLength(result, count);
end;

function SplitLines(const segs : TAnsiSegments; maxWidth : Integer) : TArray<TAnsiSegments>;
var
  i       : Integer;
  lineIdx : Integer;
  width   : Integer;
  seg     : TAnsiSegment;
  remaining : TAnsiSegment;
  left, right : TAnsiSegment;
  segWidth : Integer;
  line    : TAnsiSegments;

  procedure PushSeg(const s : TAnsiSegment);
  begin
    SetLength(line, Length(line) + 1);
    line[High(line)] := s;
  end;

  procedure NewLine;
  begin
    if Length(result) <= lineIdx then
      SetLength(result, lineIdx + 1);
    result[lineIdx] := line;
    Inc(lineIdx);
    line := nil;
    width := 0;
  end;

begin
  SetLength(result, 0);
  lineIdx := 0;
  width   := 0;
  line    := nil;

  for i := 0 to High(segs) do
  begin
    seg := segs[i];

    if seg.IsLineBreak then
    begin
      NewLine;
      Continue;
    end;

    if seg.IsControlCode then
    begin
      PushSeg(seg);
      Continue;
    end;

    remaining := seg;
    while True do
    begin
      segWidth := SegmentCellCount(remaining);
      if (maxWidth <= 0) or (width + segWidth <= maxWidth) then
      begin
        if remaining.Value <> '' then
        begin
          PushSeg(remaining);
          Inc(width, segWidth);
        end;
        Break;
      end;

      SplitSegmentAt(remaining, maxWidth - width, left, right);
      if left.Value <> '' then
        PushSeg(left);
      NewLine;
      remaining := right;
      if SegmentCellCount(remaining) = 0 then
        Break;
    end;
  end;

  // flush any remaining partial line
  if Length(line) > 0 then
    NewLine;
end;

function CropLineToWidth(const line : TAnsiSegments; maxWidth : Integer;
                          addEllipsis : Boolean) : TAnsiSegments;
const
  ELLIPSIS = '...';
var
  budget   : Integer;
  consumed : Integer;
  i, count : Integer;
  segW     : Integer;
  left, right : TAnsiSegment;
  lastStyle : TAnsiStyle;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;

  if maxWidth <= 0 then Exit;

  // Quick path: line already fits.
  if TotalCellCount(line) <= maxWidth then
  begin
    SetLength(result, Length(line));
    for i := 0 to High(line) do
      result[i] := line[i];
    Exit;
  end;

  // Reserve room for ellipsis if requested.
  budget := maxWidth;
  if addEllipsis then
  begin
    budget := budget - Length(ELLIPSIS);
    if budget < 0 then budget := 0;
  end;

  consumed := 0;
  lastStyle := TAnsiStyle.Plain;
  for i := 0 to High(line) do
  begin
    if line[i].IsLineBreak then Continue;
    if line[i].IsControlCode then
    begin
      Push(line[i]);
      Continue;
    end;
    segW := SegmentCellCount(line[i]);
    if consumed + segW <= budget then
    begin
      Push(line[i]);
      Inc(consumed, segW);
      lastStyle := line[i].Style;
    end
    else
    begin
      if budget - consumed > 0 then
      begin
        SplitSegmentAt(line[i], budget - consumed, left, right);
        if left.Value <> '' then
        begin
          Push(left);
          lastStyle := left.Style;
        end;
      end;
      Break;
    end;
  end;

  if addEllipsis then
    Push(TAnsiSegment.Text(ELLIPSIS, lastStyle));
end;

end.
