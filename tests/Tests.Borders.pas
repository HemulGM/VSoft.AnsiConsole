unit Tests.Borders;

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Borders.Box;

type
  [TestFixture]
  TBorderTests = class
  public
    [Test] procedure Square_UnicodeGlyphs;
    [Test] procedure Square_AsciiFallback;
    [Test] procedure Rounded_DifferentCorners;
    [Test] procedure Heavy_DifferentCorners;
    [Test] procedure Double_DifferentCorners;
    [Test] procedure Ascii_AlwaysAscii;
    [Test] procedure Kind_RoundTrip;
  end;

implementation

procedure TBorderTests.Square_UnicodeGlyphs;
var
  b : IBoxBorder;
begin
  b := BoxBorder(TBoxBorderKind.Square);
  Assert.AreEqual(#$250C, b.GetPart(TBoxBorderPart.TopLeft, True));
  Assert.AreEqual(#$2500, b.GetPart(TBoxBorderPart.Top, True));
  Assert.AreEqual(#$2510, b.GetPart(TBoxBorderPart.TopRight, True));
  Assert.AreEqual(#$2502, b.GetPart(TBoxBorderPart.Left, True));
  Assert.AreEqual(#$2502, b.GetPart(TBoxBorderPart.Right, True));
  Assert.AreEqual(#$2514, b.GetPart(TBoxBorderPart.BottomLeft, True));
  Assert.AreEqual(#$2518, b.GetPart(TBoxBorderPart.BottomRight, True));
end;

procedure TBorderTests.Square_AsciiFallback;
var
  b : IBoxBorder;
begin
  b := BoxBorder(TBoxBorderKind.Square);
  Assert.AreEqual('+', b.GetPart(TBoxBorderPart.TopLeft, False));
  Assert.AreEqual('-', b.GetPart(TBoxBorderPart.Top, False));
  Assert.AreEqual('+', b.GetPart(TBoxBorderPart.TopRight, False));
  Assert.AreEqual('|', b.GetPart(TBoxBorderPart.Left, False));
end;

procedure TBorderTests.Rounded_DifferentCorners;
var
  b : IBoxBorder;
begin
  b := BoxBorder(TBoxBorderKind.Rounded);
  Assert.AreEqual(#$256D, b.GetPart(TBoxBorderPart.TopLeft, True));
  Assert.AreEqual(#$256E, b.GetPart(TBoxBorderPart.TopRight, True));
  Assert.AreEqual(#$2570, b.GetPart(TBoxBorderPart.BottomLeft, True));
  Assert.AreEqual(#$256F, b.GetPart(TBoxBorderPart.BottomRight, True));
end;

procedure TBorderTests.Heavy_DifferentCorners;
var
  b : IBoxBorder;
begin
  b := BoxBorder(TBoxBorderKind.Heavy);
  Assert.AreEqual(#$250F, b.GetPart(TBoxBorderPart.TopLeft, True));
  Assert.AreEqual(#$2501, b.GetPart(TBoxBorderPart.Top, True));
  Assert.AreEqual(#$2503, b.GetPart(TBoxBorderPart.Left, True));
end;

procedure TBorderTests.Double_DifferentCorners;
var
  b : IBoxBorder;
begin
  b := BoxBorder(TBoxBorderKind.Double);
  Assert.AreEqual(#$2554, b.GetPart(TBoxBorderPart.TopLeft, True));
  Assert.AreEqual(#$2550, b.GetPart(TBoxBorderPart.Top, True));
  Assert.AreEqual(#$2551, b.GetPart(TBoxBorderPart.Left, True));
  Assert.AreEqual(#$255D, b.GetPart(TBoxBorderPart.BottomRight, True));
end;

procedure TBorderTests.Ascii_AlwaysAscii;
var
  b : IBoxBorder;
begin
  b := BoxBorder(TBoxBorderKind.Ascii);
  // Even when unicode=True we should get the ASCII glyphs.
  Assert.AreEqual('+', b.GetPart(TBoxBorderPart.TopLeft, True));
  Assert.AreEqual('-', b.GetPart(TBoxBorderPart.Top, True));
  Assert.AreEqual('|', b.GetPart(TBoxBorderPart.Left, True));
end;

procedure TBorderTests.Kind_RoundTrip;
begin
  Assert.AreEqual<Integer>(Ord(TBoxBorderKind.Heavy),   Ord(BoxBorder(TBoxBorderKind.Heavy).Kind));
  Assert.AreEqual<Integer>(Ord(TBoxBorderKind.Double),  Ord(BoxBorder(TBoxBorderKind.Double).Kind));
  Assert.AreEqual<Integer>(Ord(TBoxBorderKind.Rounded), Ord(BoxBorder(TBoxBorderKind.Rounded).Kind));
end;

initialization
  TDUnitX.RegisterTestFixture(TBorderTests);

end.
