unit Tests.Color;

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color;

type
  [TestFixture]
  TColorTests = class
  public
    [Test] procedure Default_IsDefault_ReturnsTrue;
    [Test] procedure FromRGB_NotDefault;
    [Test] procedure FromIndex_Black_HasCorrectRGB;
    [Test] procedure FromIndex_Red_IsBrightRed;
    [Test] procedure FromHex_FullForm;
    [Test] procedure FromHex_ShortForm;
    [Test] procedure FromHex_InvalidRaises;
    [Test] procedure Named_Red_MatchesPaletteIndex9;
    [Test] procedure Named_Cyan_SameAsAqua;
    [Test] procedure ToNearest_TrueColor_ReturnsSelf;
    [Test] procedure ToNearest_NoColors_ReturnsDefault;
    [Test] procedure ToNearest_Legacy_MapsToIndexBelow8;
    [Test] procedure Blend_HalfWay_GivesAverage;
    [Test] procedure Equals_SameValues_True;
    [Test] procedure Equals_DifferentValues_False;

    [Test] procedure Named_DodgerBlue1_RGB;
    [Test] procedure Named_Grey23_RGB;
    [Test] procedure Named_Aquamarine1_RGB;
    [Test] procedure Named_HotPink_RGB;
    [Test] procedure Named_Orange1_RGB;
    [Test] procedure Named_Cyan1_RGB;
    [Test] procedure Named_SkyBlue1_RGB;

    [Test] procedure TryFromHex_Valid_ReturnsTrue;
    [Test] procedure TryFromHex_Invalid_ReturnsFalse;
    [Test] procedure FromName_Red_ReturnsIndex9;
    [Test] procedure FromName_Unknown_Raises;
    [Test] procedure TryFromName_GrayAlias_MapsToGrey;
    [Test] procedure TryFromName_MagentaAlias_MapsToFuchsia;
    [Test] procedure TryFromName_ExtendedPalette_MediumPurple;
    [Test] procedure ToMarkup_NamedColor_ReturnsName;
    [Test] procedure ToMarkup_TrueColor_ReturnsHex;
    [Test] procedure ToMarkup_Default_ReturnsDefault;

    [Test] procedure FromConsoleColor_Cyan_ReturnsAqua;
    [Test] procedure FromConsoleColor_OutOfRange_Raises;
    [Test] procedure ToConsoleColor_Aqua_ReturnsCyan;
    [Test] procedure ToConsoleColor_TrueColor_ReturnsMinusOne;
    [Test] procedure ConsoleColor_RoundTrip_AllSixteen;
  end;

implementation

uses
  System.SysUtils;

procedure TColorTests.Default_IsDefault_ReturnsTrue;
var
  c : TAnsiColor;
begin
  c := TAnsiColor.Default;
  Assert.IsTrue(c.IsDefault);
end;

procedure TColorTests.FromRGB_NotDefault;
var
  c : TAnsiColor;
begin
  c := TAnsiColor.FromRGB(10, 20, 30);
  Assert.IsFalse(c.IsDefault);
  Assert.AreEqual<Byte>(10, c.R);
  Assert.AreEqual<Byte>(20, c.G);
  Assert.AreEqual<Byte>(30, c.B);
  Assert.IsFalse(c.HasPaletteIndex);
end;

procedure TColorTests.FromIndex_Black_HasCorrectRGB;
var
  c : TAnsiColor;
begin
  c := TAnsiColor.FromIndex(0);
  Assert.AreEqual<Byte>(0, c.R);
  Assert.AreEqual<Byte>(0, c.G);
  Assert.AreEqual<Byte>(0, c.B);
  Assert.AreEqual<SmallInt>(0, c.Number);
end;

procedure TColorTests.FromIndex_Red_IsBrightRed;
var
  c : TAnsiColor;
begin
  c := TAnsiColor.FromIndex(9);
  Assert.AreEqual<Byte>(255, c.R);
  Assert.AreEqual<Byte>(0,   c.G);
  Assert.AreEqual<Byte>(0,   c.B);
  Assert.AreEqual<SmallInt>(9, c.Number);
end;

procedure TColorTests.FromHex_FullForm;
var
  c : TAnsiColor;
begin
  c := TAnsiColor.FromHex('#ff8800');
  Assert.AreEqual<Byte>($FF, c.R);
  Assert.AreEqual<Byte>($88, c.G);
  Assert.AreEqual<Byte>($00, c.B);
  Assert.IsFalse(c.HasPaletteIndex);
end;

procedure TColorTests.FromHex_ShortForm;
var
  c : TAnsiColor;
begin
  c := TAnsiColor.FromHex('#f80');
  Assert.AreEqual<Byte>($FF, c.R);
  Assert.AreEqual<Byte>($88, c.G);
  Assert.AreEqual<Byte>($00, c.B);
end;

procedure TColorTests.FromHex_InvalidRaises;
begin
  Assert.WillRaise(procedure begin TAnsiColor.FromHex('#zz0000'); end);
  Assert.WillRaise(procedure begin TAnsiColor.FromHex('#12345');  end);
end;

procedure TColorTests.Named_Red_MatchesPaletteIndex9;
begin
  Assert.AreEqual<SmallInt>(9, TAnsiColor.Red.Number);
end;

procedure TColorTests.Named_Cyan_SameAsAqua;
var
  c : TAnsiColor;
begin
  c := TAnsiColor.Aqua;
  Assert.AreEqual<SmallInt>(14, c.Number);
end;

procedure TColorTests.ToNearest_TrueColor_ReturnsSelf;
var
  c, n : TAnsiColor;
begin
  c := TAnsiColor.FromRGB(123, 45, 67);
  n := c.ToNearest(TColorSystem.TrueColor);
  Assert.IsTrue(n.Equals(c));
end;

procedure TColorTests.ToNearest_NoColors_ReturnsDefault;
var
  c, n : TAnsiColor;
begin
  c := TAnsiColor.Red;
  n := c.ToNearest(TColorSystem.NoColors);
  Assert.IsTrue(n.IsDefault);
end;

procedure TColorTests.ToNearest_Legacy_MapsToIndexBelow8;
var
  c : TAnsiColor;
begin
  c := TAnsiColor.Red.ToNearest(TColorSystem.Legacy);  // bright red -> darker red or nearest
  Assert.IsTrue(c.HasPaletteIndex);
  Assert.IsTrue(c.Number < 8, 'Expected a legacy palette index (0..7), got ' + IntToStr(c.Number));
end;

procedure TColorTests.Blend_HalfWay_GivesAverage;
var
  a, b, m : TAnsiColor;
begin
  a := TAnsiColor.FromRGB(0, 0, 0);
  b := TAnsiColor.FromRGB(200, 100, 50);
  m := a.Blend(b, 0.5);
  Assert.AreEqual<Byte>(100, m.R);
  Assert.AreEqual<Byte>(50,  m.G);
  Assert.AreEqual<Byte>(25,  m.B);
end;

procedure TColorTests.Equals_SameValues_True;
begin
  Assert.IsTrue(TAnsiColor.Red.Equals(TAnsiColor.Red));
  Assert.IsTrue(TAnsiColor.Default.Equals(TAnsiColor.Default));
end;

procedure TColorTests.Equals_DifferentValues_False;
begin
  Assert.IsFalse(TAnsiColor.Red.Equals(TAnsiColor.Blue));
  Assert.IsFalse(TAnsiColor.Red.Equals(TAnsiColor.Default));
end;

// Spot-checks for the extended xterm-256 palette generated from
// Spectre's Color.Generated.g.cs. Sample values straight from the
// upstream file to catch drift if we re-import.

procedure TColorTests.Named_DodgerBlue1_RGB;
var c : TAnsiColor;
begin
  c := TAnsiColor.DodgerBlue1;
  Assert.AreEqual(33, Integer(c.Number));
  Assert.AreEqual(0,   Integer(c.R));
  Assert.AreEqual(135, Integer(c.G));
  Assert.AreEqual(255, Integer(c.B));
end;

procedure TColorTests.Named_Grey23_RGB;
var c : TAnsiColor;
begin
  c := TAnsiColor.Grey23;
  Assert.AreEqual(237, Integer(c.Number));
  Assert.AreEqual(58, Integer(c.R));
  Assert.AreEqual(58, Integer(c.G));
  Assert.AreEqual(58, Integer(c.B));
end;

procedure TColorTests.Named_Aquamarine1_RGB;
var c : TAnsiColor;
begin
  c := TAnsiColor.Aquamarine1;
  Assert.AreEqual(86, Integer(c.Number));
  Assert.AreEqual(95,  Integer(c.R));
  Assert.AreEqual(255, Integer(c.G));
  Assert.AreEqual(215, Integer(c.B));
end;

procedure TColorTests.Named_HotPink_RGB;
var c : TAnsiColor;
begin
  c := TAnsiColor.HotPink;
  Assert.AreEqual(205, Integer(c.Number));
  Assert.AreEqual(255, Integer(c.R));
  Assert.AreEqual(95,  Integer(c.G));
  Assert.AreEqual(175, Integer(c.B));
end;

procedure TColorTests.Named_Orange1_RGB;
var c : TAnsiColor;
begin
  c := TAnsiColor.Orange1;
  Assert.AreEqual(214, Integer(c.Number));
  Assert.AreEqual(255, Integer(c.R));
  Assert.AreEqual(175, Integer(c.G));
  Assert.AreEqual(0,   Integer(c.B));
end;

procedure TColorTests.Named_Cyan1_RGB;
var c : TAnsiColor;
begin
  c := TAnsiColor.Cyan1;
  Assert.AreEqual(51, Integer(c.Number));
  Assert.AreEqual(0,   Integer(c.R));
  Assert.AreEqual(255, Integer(c.G));
  Assert.AreEqual(255, Integer(c.B));
end;

procedure TColorTests.Named_SkyBlue1_RGB;
var c : TAnsiColor;
begin
  c := TAnsiColor.SkyBlue1;
  Assert.AreEqual(117, Integer(c.Number));
  Assert.AreEqual(135, Integer(c.R));
  Assert.AreEqual(215, Integer(c.G));
  Assert.AreEqual(255, Integer(c.B));
end;

procedure TColorTests.TryFromHex_Valid_ReturnsTrue;
var
  c : TAnsiColor;
begin
  Assert.IsTrue(TAnsiColor.TryFromHex('#ff8800', c));
  Assert.AreEqual<Byte>($FF, c.R);
  Assert.AreEqual<Byte>($88, c.G);
  Assert.AreEqual<Byte>($00, c.B);
end;

procedure TColorTests.TryFromHex_Invalid_ReturnsFalse;
var
  c : TAnsiColor;
begin
  Assert.IsFalse(TAnsiColor.TryFromHex('#zzz', c));
  Assert.IsTrue(c.IsDefault);
end;

procedure TColorTests.FromName_Red_ReturnsIndex9;
begin
  Assert.AreEqual<SmallInt>(9, TAnsiColor.FromName('red').Number);
  Assert.AreEqual<SmallInt>(9, TAnsiColor.FromName('RED').Number);
end;

procedure TColorTests.FromName_Unknown_Raises;
begin
  Assert.WillRaise(procedure begin TAnsiColor.FromName('notacolor'); end);
end;

procedure TColorTests.TryFromName_GrayAlias_MapsToGrey;
var
  a, b : TAnsiColor;
begin
  Assert.IsTrue(TAnsiColor.TryFromName('gray', a));
  Assert.IsTrue(TAnsiColor.TryFromName('grey', b));
  Assert.IsTrue(a.Equals(b));
  Assert.IsTrue(TAnsiColor.TryFromName('gray23', a));
  Assert.AreEqual<SmallInt>(237, a.Number);
end;

procedure TColorTests.TryFromName_MagentaAlias_MapsToFuchsia;
var
  c : TAnsiColor;
begin
  Assert.IsTrue(TAnsiColor.TryFromName('magenta', c));
  Assert.AreEqual<SmallInt>(13, c.Number);
end;

procedure TColorTests.TryFromName_ExtendedPalette_MediumPurple;
var
  c : TAnsiColor;
begin
  Assert.IsTrue(TAnsiColor.TryFromName('mediumpurple', c));
  Assert.AreEqual<SmallInt>(104, c.Number);
end;

procedure TColorTests.ToMarkup_NamedColor_ReturnsName;
begin
  Assert.AreEqual('red',          TAnsiColor.Red.ToMarkup);
  Assert.AreEqual('mediumpurple', TAnsiColor.MediumPurple.ToMarkup);
  Assert.AreEqual('grey',         TAnsiColor.Grey.ToMarkup);
end;

procedure TColorTests.ToMarkup_TrueColor_ReturnsHex;
begin
  Assert.AreEqual('#ff8800', TAnsiColor.FromRGB($FF, $88, $00).ToMarkup);
end;

procedure TColorTests.ToMarkup_Default_ReturnsDefault;
begin
  Assert.AreEqual('default', TAnsiColor.Default.ToMarkup);
end;

procedure TColorTests.FromConsoleColor_Cyan_ReturnsAqua;
var
  c : TAnsiColor;
begin
  // Windows ConsoleColor.Cyan = 11 -> ANSI palette aqua = 14
  c := TAnsiColor.FromConsoleColor(11);
  Assert.AreEqual<SmallInt>(14, c.Number);
  Assert.IsTrue(c.Equals(TAnsiColor.Aqua));
end;

procedure TColorTests.FromConsoleColor_OutOfRange_Raises;
begin
  Assert.WillRaise(procedure begin TAnsiColor.FromConsoleColor(-1); end);
  Assert.WillRaise(procedure begin TAnsiColor.FromConsoleColor(16); end);
end;

procedure TColorTests.ToConsoleColor_Aqua_ReturnsCyan;
begin
  Assert.AreEqual(11, TAnsiColor.Aqua.ToConsoleColor);
end;

procedure TColorTests.ToConsoleColor_TrueColor_ReturnsMinusOne;
begin
  Assert.AreEqual(-1, TAnsiColor.FromRGB(123, 45, 67).ToConsoleColor);
  Assert.AreEqual(-1, TAnsiColor.Default.ToConsoleColor);
  // An extended palette index outside the 0..15 range also returns -1.
  Assert.AreEqual(-1, TAnsiColor.MediumPurple.ToConsoleColor);
end;

procedure TColorTests.ConsoleColor_RoundTrip_AllSixteen;
var
  i : Integer;
  c : TAnsiColor;
begin
  for i := 0 to 15 do
  begin
    c := TAnsiColor.FromConsoleColor(i);
    Assert.AreEqual(i, c.ToConsoleColor,
      'Round trip failed for ConsoleColor index ' + IntToStr(i));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TColorTests);

end.
