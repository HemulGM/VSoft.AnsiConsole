unit Tests.Internal.Cell;

{
  Fixture for the Unicode 15.1 cell-width table port. Samples each of the
  major categories the expanded table covers (combining marks,
  east-asian-width, emoji, variation selectors) to catch regressions if the
  table is ever regenerated from a different Unicode version.
}

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TCellWidthTests = class
  public
    { Narrow (width 1) }
    [Test] procedure Ascii_Letter_IsOne;
    [Test] procedure LatinSupplement_IsOne;
    [Test] procedure RegionalIndicator_IsWide;      // 2 cells - see comment in impl
    { Zero-width }
    [Test] procedure ControlChar_IsZero;
    [Test] procedure CombiningAcute_IsZero;
    [Test] procedure DevanagariAnusvara_IsZero;
    [Test] procedure ArabicDamma_IsZero;
    [Test] procedure ThaiMaiHanAkat_IsZero;
    [Test] procedure ZeroWidthJoiner_IsZero;
    [Test] procedure VariationSelector16_IsZero;
    { Wide (width 2) }
    [Test] procedure HangulSyllable_IsWide;
    [Test] procedure HiraganaA_IsWide;
    [Test] procedure SoccerBallEmoji_IsWide;
    [Test] procedure Unicode15Emoji_IsWide;
    { String-level combinations }
    [Test] procedure CombinedString_AccumulatesCorrectly;
    [Test] procedure SurrogatePair_CountsOnceAsWide;
  end;

implementation

uses
  VSoft.AnsiConsole.Internal.Cell;

procedure TCellWidthTests.Ascii_Letter_IsOne;
begin
  Assert.AreEqual(1, CellLengthChar('A'));
  Assert.AreEqual(1, CellLengthChar('z'));
  Assert.AreEqual(1, CellLengthChar('0'));
  Assert.AreEqual(1, CellLengthChar(' '));
  Assert.AreEqual(1, CellLengthChar('~'));
end;

procedure TCellWidthTests.LatinSupplement_IsOne;
begin
  // 'é' (U+00E9) is narrow
  Assert.AreEqual(1, CellLengthChar(#$00E9));
end;

procedure TCellWidthTests.RegionalIndicator_IsWide;
begin
  // Regional indicators (U+1F1E6..U+1F1FF) are classified as wide (2
  // cells each). Rationale: terminals that compose a regional-indicator
  // pair into a single flag emoji glyph render the pair at 2 cells
  // total, so reserving 4 cells for the pair leaves at most 2 cells of
  // trailing whitespace - cosmetic, recoverable. Terminals that don't
  // compose the pair (no flag-glyph entry in the fallback emoji font)
  // render each indicator as its own letter glyph, also 2 cells each;
  // reserving 4 cells matches what the terminal actually paints. The
  // alternative (1 cell each = 2 reserved for the pair) would let the
  // second indicator overwrite the visual cell of the first on those
  // terminals.
  Assert.AreEqual(2, CellLength(#$D83C#$DDE6));  // surrogate pair for U+1F1E6
end;

procedure TCellWidthTests.ControlChar_IsZero;
begin
  Assert.AreEqual(0, CellLengthChar(#$00));
  Assert.AreEqual(0, CellLengthChar(#$09));  // TAB
  Assert.AreEqual(0, CellLengthChar(#$1B));  // ESC
  Assert.AreEqual(0, CellLengthChar(#$7F));  // DEL
end;

procedure TCellWidthTests.CombiningAcute_IsZero;
begin
  Assert.AreEqual(0, CellLengthChar(#$0301));
end;

procedure TCellWidthTests.DevanagariAnusvara_IsZero;
begin
  Assert.AreEqual(0, CellLengthChar(#$0902));
end;

procedure TCellWidthTests.ArabicDamma_IsZero;
begin
  Assert.AreEqual(0, CellLengthChar(#$064F));
end;

procedure TCellWidthTests.ThaiMaiHanAkat_IsZero;
begin
  Assert.AreEqual(0, CellLengthChar(#$0E31));
end;

procedure TCellWidthTests.ZeroWidthJoiner_IsZero;
begin
  Assert.AreEqual(0, CellLengthChar(#$200D));
end;

procedure TCellWidthTests.VariationSelector16_IsZero;
begin
  Assert.AreEqual(0, CellLengthChar(#$FE0F));
end;

procedure TCellWidthTests.HangulSyllable_IsWide;
begin
  Assert.AreEqual(2, CellLengthChar(#$AC00));
end;

procedure TCellWidthTests.HiraganaA_IsWide;
begin
  Assert.AreEqual(2, CellLengthChar(#$3042));
end;

procedure TCellWidthTests.SoccerBallEmoji_IsWide;
begin
  Assert.AreEqual(2, CellLengthChar(#$26BD));
end;

procedure TCellWidthTests.Unicode15Emoji_IsWide;
begin
  // U+1FAE8 "Shaking Face" - added in Unicode 15.0
  // Surrogate pair: high $D83E low $DEE8
  Assert.AreEqual(2, CellLength(#$D83E#$DEE8));
end;

procedure TCellWidthTests.CombinedString_AccumulatesCorrectly;
begin
  // "abc" = 3 cells
  Assert.AreEqual(3, CellLength('abc'));
  // "a" + combining acute + "b" = 1 + 0 + 1 = 2
  Assert.AreEqual(2, CellLength('a' + #$0301 + 'b'));
  // Hangul syllable + ASCII = 2 + 1 = 3
  Assert.AreEqual(3, CellLength(#$AC00 + 'x'));
end;

procedure TCellWidthTests.SurrogatePair_CountsOnceAsWide;
begin
  // U+1F600 GRINNING FACE - high $D83D low $DE00 - must render as width 2,
  // not 2x1 from two surrogate code units counted independently.
  Assert.AreEqual(2, CellLength(#$D83D#$DE00));
end;

initialization
  TDUnitX.RegisterTestFixture(TCellWidthTests);

end.
