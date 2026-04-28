unit Tests.Widgets.LayoutAreas;

{
  ILayout area-tree tests - row/column splitting, fixed-size honouring,
  and FindByName lookup. Distinct from Tests.Widgets.Layout (which covers
  the layout primitives Padder/Align/Rows/Columns/Grid/Panel).
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Widgets.Text,
  VSoft.AnsiConsole.Widgets.Layout;

type
  [TestFixture]
  TLayoutAreasTests = class
  public
    [Test] procedure SplitRows_AllocatesByRatio;
    [Test] procedure FixedSize_HonoursSize;
    [Test] procedure FindByName_Works;
    [Test] procedure SplitColumns_RendersSideBySide;
    [Test] procedure WithRatio_ProportionalAllocation;
    [Test] procedure WithVisibleFalse_HidesPane;
    [Test] procedure FindByName_Missing_ReturnsNil;
    [Test] procedure NestedSplit_BothChildrenVisible;
    [Test] procedure Update_ReplacesContent;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Types,
  Testing.AnsiConsole;

function BuildPlain(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.NoColors, width, True, result, sink);
end;

procedure TLayoutAreasTests.SplitRows_AllocatesByRatio;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  root, a, b : ILayout;
begin
  console := BuildPlain(20, sink);
  a := Layout('a').Update(Text('AAA'));
  b := Layout('b').Update(Text('BBB'));
  root := Layout('root');
  root.SplitRows([a, b]);
  root.WithHeight(6);
  console.Write(root);
  Assert.IsTrue(Pos('AAA', sink.Text) > 0);
  Assert.IsTrue(Pos('BBB', sink.Text) > 0);
end;

procedure TLayoutAreasTests.FixedSize_HonoursSize;
var
  root, hdr, body : ILayout;
  lines           : TStringDynArray;
  sink            : ICapturedAnsiOutput;
  console         : IAnsiConsole;
  i, hRow, bRow   : Integer;
begin
  console := BuildPlain(20, sink);
  hdr  := Layout('h').Update(Text('H')).WithSize(2);
  body := Layout('b').Update(Text('B'));
  root := Layout('r');
  root.SplitRows([hdr, body]);
  root.WithHeight(10);
  console.Write(root);

  lines := SplitString(sink.Text, #10);
  // Header occupies the top two rows (its content on one row, blank pad on
  // the other). Body starts on row 2 since the header claimed rows 0-1.
  hRow := -1;
  bRow := -1;
  for i := 0 to High(lines) do
  begin
    if (hRow = -1) and (Pos('H', lines[i]) > 0) then hRow := i;
    if (bRow = -1) and (Pos('B', lines[i]) > 0) then bRow := i;
  end;
  Assert.IsTrue(hRow >= 0, 'Header content should render somewhere');
  Assert.IsTrue((hRow = 0) or (hRow = 1), 'Header must be within its 2-row slot');
  Assert.AreEqual(2, bRow, 'Body must start on row 2 (after the 2-row header)');
end;

procedure TLayoutAreasTests.FindByName_Works;
var
  root, a, b : ILayout;
  found      : ILayout;
begin
  a := Layout('alpha').Update(Text('A'));
  b := Layout('beta').Update(Text('B'));
  root := Layout('root');
  root.SplitColumns([a, b]);

  found := root.FindByName('alpha');
  Assert.IsNotNull(found);
  Assert.AreEqual('alpha', found.Name);
end;

procedure TLayoutAreasTests.SplitColumns_RendersSideBySide;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  root, a, b : ILayout;
  lines   : TStringDynArray;
  i, hits : Integer;
begin
  console := BuildPlain(20, sink);
  a := Layout('a').Update(Text('A'));
  b := Layout('b').Update(Text('B'));
  root := Layout('root');
  root.SplitColumns([a, b]);
  console.Write(root);
  // Both 'A' and 'B' should appear on the same output line at least once.
  lines := SplitString(sink.Text, #10);
  hits := 0;
  for i := 0 to High(lines) do
    if (Pos('A', lines[i]) > 0) and (Pos('B', lines[i]) > 0) then
      Inc(hits);
  Assert.IsTrue(hits >= 1,
    'SplitColumns must place both children on a shared row');
end;

procedure TLayoutAreasTests.WithRatio_ProportionalAllocation;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  root, big, small : ILayout;
  lines : TStringDynArray;
  bigCol, smallCol, i : Integer;
begin
  // 3:1 horizontal split. The big child gets ~75% of the 20-wide row.
  console := BuildPlain(20, sink);
  big   := Layout('big').Update(Text('X')).WithRatio(3);
  small := Layout('small').Update(Text('Y')).WithRatio(1);
  root  := Layout('root');
  root.SplitColumns([big, small]);
  console.Write(root);

  lines := SplitString(sink.Text, #10);
  bigCol := -1;
  smallCol := -1;
  for i := 0 to High(lines) do
  begin
    if (bigCol = -1)   and (Pos('X', lines[i]) > 0) then bigCol   := Pos('X', lines[i]);
    if (smallCol = -1) and (Pos('Y', lines[i]) > 0) then smallCol := Pos('Y', lines[i]);
  end;
  Assert.IsTrue(bigCol > 0, 'X should appear');
  Assert.IsTrue(smallCol > 0, 'Y should appear');
  Assert.IsTrue(smallCol > bigCol,
    'Y should sit to the right of X (small ratio child after big ratio child)');
  // The Y column should land roughly in the rightmost quarter of the row.
  Assert.IsTrue(smallCol >= 13,
    Format('Y should fall in the rightmost ratio slot (col=%d)', [smallCol]));
end;

procedure TLayoutAreasTests.WithVisibleFalse_HidesPane;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  root, hidden, shown : ILayout;
begin
  console := BuildPlain(20, sink);
  hidden := Layout('hidden').Update(Text('SECRET')).WithVisible(False);
  shown  := Layout('shown').Update(Text('PUBLIC'));
  root := Layout('root');
  root.SplitRows([hidden, shown]);
  root.WithHeight(6);
  console.Write(root);
  Assert.IsTrue(Pos('SECRET', sink.Text) = 0,
    'Hidden pane content must not appear in output');
  Assert.IsTrue(Pos('PUBLIC', sink.Text) > 0,
    'Shown pane content should still render');
end;

procedure TLayoutAreasTests.FindByName_Missing_ReturnsNil;
var
  root, a : ILayout;
begin
  a := Layout('alpha').Update(Text('A'));
  root := Layout('root');
  root.SplitColumns([a]);
  Assert.IsNull(root.FindByName('nonexistent'),
    'FindByName must return nil for an unknown name');
end;

procedure TLayoutAreasTests.NestedSplit_BothChildrenVisible;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  root, top, bottom, left, right : ILayout;
begin
  // root SplitRows [top, bottom]; bottom SplitColumns [left, right].
  console := BuildPlain(20, sink);
  top    := Layout('top').Update(Text('TOP'));
  left   := Layout('left').Update(Text('LL'));
  right  := Layout('right').Update(Text('RR'));
  bottom := Layout('bottom');
  bottom.SplitColumns([left, right]);
  root   := Layout('root');
  root.SplitRows([top, bottom]);
  root.WithHeight(6);
  console.Write(root);
  Assert.IsTrue(Pos('TOP', sink.Text) > 0, 'top pane should render');
  Assert.IsTrue(Pos('LL',  sink.Text) > 0, 'nested left should render');
  Assert.IsTrue(Pos('RR',  sink.Text) > 0, 'nested right should render');
end;

procedure TLayoutAreasTests.Update_ReplacesContent;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  pane    : ILayout;
begin
  pane := Layout('pane').Update(Text('first'));
  pane.Update(Text('second'));   // replace with new content
  console := BuildPlain(20, sink);
  console.Write(pane);
  Assert.IsTrue(Pos('first',  sink.Text) = 0, 'first content should be replaced');
  Assert.IsTrue(Pos('second', sink.Text) > 0, 'updated content should render');
end;

initialization
  TDUnitX.RegisterTestFixture(TLayoutAreasTests);

end.
