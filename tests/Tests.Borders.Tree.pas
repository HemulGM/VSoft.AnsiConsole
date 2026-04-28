unit Tests.Borders.Tree;

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Borders.Tree;

type
  [TestFixture]
  TTreeGuideTests = class
  public
    [Test] procedure Line_UnicodeGlyphs;
    [Test] procedure Ascii_Glyphs;
    [Test] procedure Heavy_Glyphs;
    [Test] procedure Double_Glyphs;
    [Test] procedure Ascii_AlwaysAsciiEvenWhenUnicode;
  end;

implementation

procedure TTreeGuideTests.Line_UnicodeGlyphs;
var
  g : ITreeGuide;
begin
  g := TreeGuide(TTreeGuideKind.Line);
  Assert.AreEqual(' ',    g.GetPart(TTreeGuidePart.Space,      True));
  Assert.AreEqual(#$2502, g.GetPart(TTreeGuidePart.Continue,   True));
  Assert.AreEqual(#$251C, g.GetPart(TTreeGuidePart.Fork,       True));
  Assert.AreEqual(#$2514, g.GetPart(TTreeGuidePart.Last,       True));
  Assert.AreEqual(#$2500, g.GetPart(TTreeGuidePart.Horizontal, True));
end;

procedure TTreeGuideTests.Ascii_Glyphs;
var
  g : ITreeGuide;
begin
  g := TreeGuide(TTreeGuideKind.Ascii);
  Assert.AreEqual(' ', g.GetPart(TTreeGuidePart.Space,      True));
  Assert.AreEqual('|', g.GetPart(TTreeGuidePart.Continue,   True));
  Assert.AreEqual('+', g.GetPart(TTreeGuidePart.Fork,       True));
  Assert.AreEqual('`', g.GetPart(TTreeGuidePart.Last,       True));
  Assert.AreEqual('-', g.GetPart(TTreeGuidePart.Horizontal, True));
end;

procedure TTreeGuideTests.Heavy_Glyphs;
var
  g : ITreeGuide;
begin
  g := TreeGuide(TTreeGuideKind.Heavy);
  Assert.AreEqual(#$2503, g.GetPart(TTreeGuidePart.Continue,   True));
  Assert.AreEqual(#$2523, g.GetPart(TTreeGuidePart.Fork,       True));
  Assert.AreEqual(#$2517, g.GetPart(TTreeGuidePart.Last,       True));
  Assert.AreEqual(#$2501, g.GetPart(TTreeGuidePart.Horizontal, True));
end;

procedure TTreeGuideTests.Double_Glyphs;
var
  g : ITreeGuide;
begin
  g := TreeGuide(TTreeGuideKind.Double);
  Assert.AreEqual(#$2551, g.GetPart(TTreeGuidePart.Continue,   True));
  Assert.AreEqual(#$2560, g.GetPart(TTreeGuidePart.Fork,       True));
  Assert.AreEqual(#$255A, g.GetPart(TTreeGuidePart.Last,       True));
end;

procedure TTreeGuideTests.Ascii_AlwaysAsciiEvenWhenUnicode;
var
  g : ITreeGuide;
begin
  g := TreeGuide(TTreeGuideKind.Ascii);
  // explicitly request unicode - should still return ASCII characters
  Assert.AreEqual('|', g.GetPart(TTreeGuidePart.Continue, True));
  Assert.AreEqual('+', g.GetPart(TTreeGuidePart.Fork,     True));
end;

initialization
  TDUnitX.RegisterTestFixture(TTreeGuideTests);

end.
