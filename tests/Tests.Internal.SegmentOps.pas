unit Tests.Internal.SegmentOps;

{
  Direct tests for the segment-array primitives every widget composes:
  measurement (TotalCellCount / SegmentCellCount), single-segment slicing
  (SplitSegmentAt), style-aware coalescing (MergeSegments), hard-wrap
  splitting (SplitLines) and crop-to-width with optional '...' ellipsis
  (CropLineToWidth). Most regressions in the rendering layer surface here
  first - pinning down their exact behaviour gives every widget a stable
  foundation.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Internal.SegmentOps;

type
  [TestFixture]
  TSegmentOpsTests = class
  public
    [Test] procedure SegmentCellCount_Plain_ReturnsCharLength;
    [Test] procedure SegmentCellCount_Wide_ReturnsTwo;
    [Test] procedure SegmentCellCount_LineBreak_IsZero;
    [Test] procedure SegmentCellCount_ControlCode_IsZero;

    [Test] procedure TotalCellCount_Empty_IsZero;
    [Test] procedure TotalCellCount_SingleLine_SumsSegments;
    [Test] procedure TotalCellCount_MultipleLines_ReturnsLongest;
    [Test] procedure TotalCellCount_TrailingLineBreak_HandledOk;

    [Test] procedure SplitSegmentAt_Zero_LeftEmpty_RightFull;
    [Test] procedure SplitSegmentAt_Middle_SplitsByCellOffset;
    [Test] procedure SplitSegmentAt_OffsetBeyondLength_LeftFull_RightEmpty;
    [Test] procedure SplitSegmentAt_LineBreak_PassedThroughAsLeft;
    [Test] procedure SplitSegmentAt_PreservesStyle;

    [Test] procedure MergeSegments_AdjacentSameStyle_Coalesces;
    [Test] procedure MergeSegments_DifferentStyles_KeepsSeparate;
    [Test] procedure MergeSegments_KeepsLineBreakBoundary;

    [Test] procedure SplitLines_Empty_ReturnsEmptyArray;
    [Test] procedure SplitLines_NoLineBreaks_FitsInMaxWidth_OneLine;
    [Test] procedure SplitLines_HardWrapAtMaxWidth;
    [Test] procedure SplitLines_ExplicitLineBreak_StartsNewLine;
    [Test] procedure SplitLines_BothExplicitAndWrap_BothHonored;

    [Test] procedure CropLineToWidth_ZeroMaxWidth_ReturnsEmpty;
    [Test] procedure CropLineToWidth_Fits_ReturnsUnchanged;
    [Test] procedure CropLineToWidth_TooLong_TruncatesNoEllipsis;
    [Test] procedure CropLineToWidth_TooLong_WithEllipsis_AppendsDots;
    [Test] procedure CropLineToWidth_PreservesControlCodes;
  end;

implementation

uses
  System.SysUtils;

function MakeText(const s : string) : TAnsiSegment;
begin
  result := TAnsiSegment.Text(s);
end;

function MakeStyledText(const s : string; const style : TAnsiStyle) : TAnsiSegment;
begin
  result := TAnsiSegment.Text(s, style);
end;

function Segs(const items : array of TAnsiSegment) : TAnsiSegments;
var
  i : Integer;
begin
  SetLength(result, Length(items));
  for i := 0 to High(items) do
    result[i] := items[i];
end;

{ ---- SegmentCellCount ---- }

procedure TSegmentOpsTests.SegmentCellCount_Plain_ReturnsCharLength;
begin
  Assert.AreEqual(5, SegmentCellCount(MakeText('hello')));
end;

procedure TSegmentOpsTests.SegmentCellCount_Wide_ReturnsTwo;
begin
  // U+AC00 is a wide Hangul syllable.
  Assert.AreEqual(2, SegmentCellCount(MakeText(#$AC00)));
end;

procedure TSegmentOpsTests.SegmentCellCount_LineBreak_IsZero;
begin
  Assert.AreEqual(0, SegmentCellCount(TAnsiSegment.LineBreak));
end;

procedure TSegmentOpsTests.SegmentCellCount_ControlCode_IsZero;
begin
  Assert.AreEqual(0, SegmentCellCount(TAnsiSegment.ControlCode(#27 + '[H')));
end;

{ ---- TotalCellCount ---- }

procedure TSegmentOpsTests.TotalCellCount_Empty_IsZero;
var
  empty : TAnsiSegments;
begin
  SetLength(empty, 0);
  Assert.AreEqual(0, TotalCellCount(empty));
end;

procedure TSegmentOpsTests.TotalCellCount_SingleLine_SumsSegments;
begin
  Assert.AreEqual(8, TotalCellCount(Segs([MakeText('foo'), MakeText(' '), MakeText('quux')])));
end;

procedure TSegmentOpsTests.TotalCellCount_MultipleLines_ReturnsLongest;
begin
  // 3 / 5 / 2: longest line is 5 cells.
  Assert.AreEqual(5, TotalCellCount(Segs([
    MakeText('abc'),
    TAnsiSegment.LineBreak,
    MakeText('hello'),
    TAnsiSegment.LineBreak,
    MakeText('xy')
  ])));
end;

procedure TSegmentOpsTests.TotalCellCount_TrailingLineBreak_HandledOk;
begin
  // Trailing break shouldn't crash or count an extra "phantom" line.
  Assert.AreEqual(3, TotalCellCount(Segs([
    MakeText('abc'),
    TAnsiSegment.LineBreak
  ])));
end;

{ ---- SplitSegmentAt ---- }

procedure TSegmentOpsTests.SplitSegmentAt_Zero_LeftEmpty_RightFull;
var
  l, r : TAnsiSegment;
begin
  SplitSegmentAt(MakeText('hello'), 0, l, r);
  Assert.AreEqual('',      l.Value);
  Assert.AreEqual('hello', r.Value);
end;

procedure TSegmentOpsTests.SplitSegmentAt_Middle_SplitsByCellOffset;
var
  l, r : TAnsiSegment;
begin
  SplitSegmentAt(MakeText('hello'), 2, l, r);
  Assert.AreEqual('he',  l.Value);
  Assert.AreEqual('llo', r.Value);
end;

procedure TSegmentOpsTests.SplitSegmentAt_OffsetBeyondLength_LeftFull_RightEmpty;
var
  l, r : TAnsiSegment;
begin
  SplitSegmentAt(MakeText('hi'), 99, l, r);
  Assert.AreEqual('hi', l.Value);
  Assert.AreEqual('',   r.Value);
end;

procedure TSegmentOpsTests.SplitSegmentAt_LineBreak_PassedThroughAsLeft;
var
  l, r : TAnsiSegment;
begin
  SplitSegmentAt(TAnsiSegment.LineBreak, 5, l, r);
  Assert.IsTrue(l.IsLineBreak, 'Left side should be the original line break');
  Assert.AreEqual('', r.Value, 'Right side should be empty');
end;

procedure TSegmentOpsTests.SplitSegmentAt_PreservesStyle;
var
  l, r : TAnsiSegment;
  style : TAnsiStyle;
begin
  style := TAnsiStyle.Plain.WithForeground(TAnsiColor.Red);
  SplitSegmentAt(MakeStyledText('abcdef', style), 3, l, r);
  Assert.AreEqual('abc', l.Value);
  Assert.AreEqual('def', r.Value);
  Assert.IsTrue(l.Style.Foreground.Equals(TAnsiColor.Red));
  Assert.IsTrue(r.Style.Foreground.Equals(TAnsiColor.Red));
end;

{ ---- MergeSegments ---- }

procedure TSegmentOpsTests.MergeSegments_AdjacentSameStyle_Coalesces;
var
  merged : TAnsiSegments;
begin
  merged := MergeSegments(Segs([
    MakeText('foo'),
    MakeText('bar')
  ]));
  Assert.AreEqual<Integer>(1, Length(merged));
  Assert.AreEqual('foobar', merged[0].Value);
end;

procedure TSegmentOpsTests.MergeSegments_DifferentStyles_KeepsSeparate;
var
  merged : TAnsiSegments;
  red    : TAnsiStyle;
begin
  red := TAnsiStyle.Plain.WithForeground(TAnsiColor.Red);
  merged := MergeSegments(Segs([
    MakeText('plain'),
    MakeStyledText('red', red)
  ]));
  Assert.AreEqual<Integer>(2, Length(merged),
    'Style boundary must remain a segment boundary');
end;

procedure TSegmentOpsTests.MergeSegments_KeepsLineBreakBoundary;
var
  merged : TAnsiSegments;
begin
  merged := MergeSegments(Segs([
    MakeText('a'),
    TAnsiSegment.LineBreak,
    MakeText('b')
  ]));
  // Line break must NOT be merged away.
  Assert.AreEqual<Integer>(3, Length(merged));
  Assert.IsTrue(merged[1].IsLineBreak);
end;

{ ---- SplitLines ---- }

procedure TSegmentOpsTests.SplitLines_Empty_ReturnsEmptyArray;
var
  empty : TAnsiSegments;
  lines : TArray<TAnsiSegments>;
begin
  SetLength(empty, 0);
  lines := SplitLines(empty, 80);
  Assert.AreEqual<Integer>(0, Length(lines));
end;

procedure TSegmentOpsTests.SplitLines_NoLineBreaks_FitsInMaxWidth_OneLine;
var
  lines : TArray<TAnsiSegments>;
begin
  lines := SplitLines(Segs([MakeText('hello')]), 80);
  Assert.AreEqual<Integer>(1, Length(lines));
end;

procedure TSegmentOpsTests.SplitLines_HardWrapAtMaxWidth;
var
  lines : TArray<TAnsiSegments>;
begin
  // 12 chars in a 5-wide budget = 3 lines of 5/5/2.
  lines := SplitLines(Segs([MakeText('abcdefghijkl')]), 5);
  Assert.AreEqual<Integer>(3, Length(lines),
    '12 chars in a 5-wide budget should hard-wrap to 3 lines');
end;

procedure TSegmentOpsTests.SplitLines_ExplicitLineBreak_StartsNewLine;
var
  lines : TArray<TAnsiSegments>;
begin
  lines := SplitLines(Segs([
    MakeText('aa'),
    TAnsiSegment.LineBreak,
    MakeText('bb')
  ]), 80);
  Assert.AreEqual<Integer>(2, Length(lines),
    'Explicit line-break must split into two lines');
end;

procedure TSegmentOpsTests.SplitLines_BothExplicitAndWrap_BothHonored;
var
  lines : TArray<TAnsiSegments>;
begin
  // 'abcdef' (6) wrapped at 4 = 2 sublines, then explicit break,
  // then 'gh' (2) = 1 line. Total 3.
  lines := SplitLines(Segs([
    MakeText('abcdef'),
    TAnsiSegment.LineBreak,
    MakeText('gh')
  ]), 4);
  Assert.AreEqual<Integer>(3, Length(lines));
end;

{ ---- CropLineToWidth ---- }

procedure TSegmentOpsTests.CropLineToWidth_ZeroMaxWidth_ReturnsEmpty;
var
  cropped : TAnsiSegments;
begin
  cropped := CropLineToWidth(Segs([MakeText('hello')]), 0, False);
  Assert.AreEqual<Integer>(0, Length(cropped));
end;

procedure TSegmentOpsTests.CropLineToWidth_Fits_ReturnsUnchanged;
var
  src, cropped : TAnsiSegments;
begin
  src := Segs([MakeText('abc')]);
  cropped := CropLineToWidth(src, 10, True);
  Assert.AreEqual<Integer>(1, Length(cropped));
  Assert.AreEqual('abc', cropped[0].Value);
end;

procedure TSegmentOpsTests.CropLineToWidth_TooLong_TruncatesNoEllipsis;
var
  cropped : TAnsiSegments;
  total   : Integer;
begin
  cropped := CropLineToWidth(Segs([MakeText('abcdefghij')]), 5, False);
  total := TotalCellCount(cropped);
  Assert.AreEqual(5, total, 'Crop should truncate to exactly maxWidth cells');
  Assert.AreEqual('abcde', cropped[0].Value);
end;

procedure TSegmentOpsTests.CropLineToWidth_TooLong_WithEllipsis_AppendsDots;
var
  cropped : TAnsiSegments;
  joined  : string;
  i       : Integer;
begin
  // maxWidth=5 with addEllipsis: budget for content = 5-3 = 2 chars + '...'
  // = 5 cells total.
  cropped := CropLineToWidth(Segs([MakeText('abcdefghij')]), 5, True);
  joined := '';
  for i := 0 to High(cropped) do
    joined := joined + cropped[i].Value;
  Assert.AreEqual(5, TotalCellCount(cropped),
    'With ellipsis the result must still be exactly maxWidth cells wide');
  Assert.IsTrue(joined.EndsWith('...'),
    'Truncated line should end with the ASCII "..." ellipsis');
end;

procedure TSegmentOpsTests.CropLineToWidth_PreservesControlCodes;
var
  cropped : TAnsiSegments;
  ctrlSeen : Boolean;
  i : Integer;
begin
  // Control-code segments don't consume cells but should pass through the
  // crop unchanged when the surrounding text fits.
  cropped := CropLineToWidth(Segs([
    TAnsiSegment.ControlCode(#27 + '[H'),
    MakeText('hi')
  ]), 80, False);
  ctrlSeen := False;
  for i := 0 to High(cropped) do
    if cropped[i].IsControlCode then ctrlSeen := True;
  Assert.IsTrue(ctrlSeen, 'Crop must preserve control-code segments');
end;

initialization
  TDUnitX.RegisterTestFixture(TSegmentOpsTests);

end.
