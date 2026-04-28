unit Tests.Borders.Table;

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Borders.Table;

type
  [TestFixture]
  TTableBorderTests = class
  public
    [Test] procedure Square_UnicodeCorners;
    [Test] procedure Ascii_UsesPlusAndDash;
    [Test] procedure None_AllSpaces;
    [Test] procedure Markdown_VerticalsArePipes;
    [Test] procedure Heavy_UsesHeavyGlyphs;
    [Test] procedure Double_UsesDoubleGlyphs;
    [Test] procedure Ascii2_HeaderSidesArePipes;
    [Test] procedure AsciiDoubleHead_HeaderUsesEquals;
    [Test] procedure Minimal_OnlyVerticalAndHeaderSep;
    [Test] procedure Simple_OnlyHeaderSeparator;
    [Test] procedure Horizontal_DashesEverywhere;
    [Test] procedure HeavyEdge_HeavyOuterLightInner;
    [Test] procedure HeavyHead_HeavyTopAndHeaderSep;
    [Test] procedure DoubleEdge_DoubleOuterLightInner;
  end;

implementation

uses
  System.SysUtils;

procedure TTableBorderTests.Square_UnicodeCorners;
var
  b : ITableBorder;
begin
  b := TableBorder(TTableBorderKind.Square);
  Assert.AreEqual(#$250C, b.GetPart(TTableBorderPart.TopLeft,     True));
  Assert.AreEqual(#$252C, b.GetPart(TTableBorderPart.TopMid,      True));
  Assert.AreEqual(#$2510, b.GetPart(TTableBorderPart.TopRight,    True));
  Assert.AreEqual(#$2502, b.GetPart(TTableBorderPart.CellLeft,    True));
  Assert.AreEqual(#$253C, b.GetPart(TTableBorderPart.HeadMid,     True));
  Assert.AreEqual(#$2514, b.GetPart(TTableBorderPart.BottomLeft,  True));
end;

procedure TTableBorderTests.Ascii_UsesPlusAndDash;
var
  b : ITableBorder;
begin
  b := TableBorder(TTableBorderKind.Ascii);
  Assert.AreEqual('+', b.GetPart(TTableBorderPart.TopLeft, True));
  Assert.AreEqual('-', b.GetPart(TTableBorderPart.Top,     True));
  Assert.AreEqual('+', b.GetPart(TTableBorderPart.TopMid,  True));
  Assert.AreEqual('|', b.GetPart(TTableBorderPart.CellLeft, True));
end;

procedure TTableBorderTests.None_AllSpaces;
var
  b : ITableBorder;
  part : TTableBorderPart;
begin
  b := TableBorder(TTableBorderKind.None);
  for part := Low(TTableBorderPart) to High(TTableBorderPart) do
    Assert.AreEqual(' ', b.GetPart(part, True),
      'Expected space for part ' + IntToStr(Ord(part)));
end;

procedure TTableBorderTests.Markdown_VerticalsArePipes;
var
  b : ITableBorder;
begin
  b := TableBorder(TTableBorderKind.Markdown);
  Assert.AreEqual('|', b.GetPart(TTableBorderPart.CellLeft,  True));
  Assert.AreEqual('|', b.GetPart(TTableBorderPart.CellMid,   True));
  Assert.AreEqual('|', b.GetPart(TTableBorderPart.CellRight, True));
  Assert.AreEqual('-', b.GetPart(TTableBorderPart.Head,      True));
  // Top + bottom edges are blank so the markdown output doesn't have a top rule.
  Assert.AreEqual(' ', b.GetPart(TTableBorderPart.Top,       True));
  Assert.AreEqual(' ', b.GetPart(TTableBorderPart.Bottom,    True));
end;

procedure TTableBorderTests.Heavy_UsesHeavyGlyphs;
var
  b : ITableBorder;
begin
  b := TableBorder(TTableBorderKind.Heavy);
  Assert.AreEqual(#$250F, b.GetPart(TTableBorderPart.TopLeft,  True));
  Assert.AreEqual(#$2501, b.GetPart(TTableBorderPart.Top,      True));
  Assert.AreEqual(#$2503, b.GetPart(TTableBorderPart.CellLeft, True));
end;

procedure TTableBorderTests.Double_UsesDoubleGlyphs;
var
  b : ITableBorder;
begin
  b := TableBorder(TTableBorderKind.Double);
  Assert.AreEqual(#$2554, b.GetPart(TTableBorderPart.TopLeft,     True));
  Assert.AreEqual(#$2550, b.GetPart(TTableBorderPart.Top,         True));
  Assert.AreEqual(#$2551, b.GetPart(TTableBorderPart.CellLeft,    True));
  Assert.AreEqual(#$255D, b.GetPart(TTableBorderPart.BottomRight, True));
end;

procedure TTableBorderTests.Ascii2_HeaderSidesArePipes;
var
  b : ITableBorder;
begin
  b := TableBorder(TTableBorderKind.Ascii2);
  Assert.AreEqual('+', b.GetPart(TTableBorderPart.TopLeft,    True));
  Assert.AreEqual('|', b.GetPart(TTableBorderPart.HeadLeft,   True));   // Ascii2 quirk: '|' here, not '+'
  Assert.AreEqual('|', b.GetPart(TTableBorderPart.HeadRight,  True));
  Assert.AreEqual('-', b.GetPart(TTableBorderPart.Head,       True));
end;

procedure TTableBorderTests.AsciiDoubleHead_HeaderUsesEquals;
var
  b : ITableBorder;
begin
  b := TableBorder(TTableBorderKind.AsciiDoubleHead);
  Assert.AreEqual('=', b.GetPart(TTableBorderPart.Head, True));
  Assert.AreEqual('-', b.GetPart(TTableBorderPart.Top,  True));
end;

procedure TTableBorderTests.Minimal_OnlyVerticalAndHeaderSep;
var
  b : ITableBorder;
begin
  b := TableBorder(TTableBorderKind.Minimal);
  Assert.AreEqual(' ',    b.GetPart(TTableBorderPart.TopLeft,     True));
  Assert.AreEqual(' ',    b.GetPart(TTableBorderPart.Top,         True));
  Assert.AreEqual(#$2502, b.GetPart(TTableBorderPart.CellMid,     True));   // │
  Assert.AreEqual(' ',    b.GetPart(TTableBorderPart.CellLeft,    True));
  Assert.AreEqual(#$2500, b.GetPart(TTableBorderPart.Head,        True));   // ─
  Assert.AreEqual(#$253C, b.GetPart(TTableBorderPart.HeadMid,     True));   // ┼
  Assert.AreEqual(' ',    b.GetPart(TTableBorderPart.BottomLeft,  True));
end;

procedure TTableBorderTests.Simple_OnlyHeaderSeparator;
var
  b : ITableBorder;
begin
  b := TableBorder(TTableBorderKind.Simple);
  Assert.AreEqual(' ',    b.GetPart(TTableBorderPart.CellMid,    True));   // no vertical
  Assert.AreEqual(' ',    b.GetPart(TTableBorderPart.CellLeft,   True));
  Assert.AreEqual(#$2500, b.GetPart(TTableBorderPart.Head,       True));   // ─
  Assert.AreEqual(#$2500, b.GetPart(TTableBorderPart.HeadLeft,   True));
  Assert.AreEqual(#$2500, b.GetPart(TTableBorderPart.HeadMid,    True));
  Assert.AreEqual(' ',    b.GetPart(TTableBorderPart.Top,        True));
  Assert.AreEqual(' ',    b.GetPart(TTableBorderPart.Bottom,     True));
end;

procedure TTableBorderTests.Horizontal_DashesEverywhere;
var
  b : ITableBorder;
begin
  b := TableBorder(TTableBorderKind.Horizontal);
  Assert.AreEqual(#$2500, b.GetPart(TTableBorderPart.Top,        True));
  Assert.AreEqual(#$2500, b.GetPart(TTableBorderPart.Head,       True));
  Assert.AreEqual(#$2500, b.GetPart(TTableBorderPart.Bottom,     True));
  Assert.AreEqual(' ',    b.GetPart(TTableBorderPart.CellMid,    True));   // no vertical
end;

procedure TTableBorderTests.HeavyEdge_HeavyOuterLightInner;
var
  b : ITableBorder;
begin
  b := TableBorder(TTableBorderKind.HeavyEdge);
  Assert.AreEqual(#$250F, b.GetPart(TTableBorderPart.TopLeft,     True));   // ┏
  Assert.AreEqual(#$2501, b.GetPart(TTableBorderPart.Top,         True));   // ━
  Assert.AreEqual(#$2503, b.GetPart(TTableBorderPart.CellLeft,    True));   // ┃ (heavy edge)
  Assert.AreEqual(#$2502, b.GetPart(TTableBorderPart.CellMid,     True));   // │ (light inner)
  Assert.AreEqual(#$251B, b.GetPart(TTableBorderPart.BottomRight, True));   // ┛
end;

procedure TTableBorderTests.HeavyHead_HeavyTopAndHeaderSep;
var
  b : ITableBorder;
begin
  b := TableBorder(TTableBorderKind.HeavyHead);
  Assert.AreEqual(#$250F, b.GetPart(TTableBorderPart.TopLeft,    True));    // ┏
  Assert.AreEqual(#$2501, b.GetPart(TTableBorderPart.Top,        True));    // ━
  Assert.AreEqual(#$2502, b.GetPart(TTableBorderPart.CellLeft,   True));    // │ (light below header)
  Assert.AreEqual(#$2501, b.GetPart(TTableBorderPart.Head,       True));    // ━ (heavy header sep)
  Assert.AreEqual(#$2500, b.GetPart(TTableBorderPart.Bottom,     True));    // ─ (light bottom)
end;

procedure TTableBorderTests.DoubleEdge_DoubleOuterLightInner;
var
  b : ITableBorder;
begin
  b := TableBorder(TTableBorderKind.DoubleEdge);
  Assert.AreEqual(#$2554, b.GetPart(TTableBorderPart.TopLeft,     True));   // ╔
  Assert.AreEqual(#$2550, b.GetPart(TTableBorderPart.Top,         True));   // ═
  Assert.AreEqual(#$2551, b.GetPart(TTableBorderPart.CellLeft,    True));   // ║ (double edge)
  Assert.AreEqual(#$2502, b.GetPart(TTableBorderPart.CellMid,     True));   // │ (light inner)
  Assert.AreEqual(#$255D, b.GetPart(TTableBorderPart.BottomRight, True));   // ╝
end;

initialization
  TDUnitX.RegisterTestFixture(TTableBorderTests);

end.
