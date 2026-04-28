unit Tests.Widgets.Cell;

{
  Cell-width tests - exercises CellLengthChar's classification of wide,
  narrow, and zero-width characters.
}

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TCellWidthTests = class
  public
    [Test] procedure Cell_EmojiRange_IsWide;
    [Test] procedure Cell_CombiningMark_IsZero;
    [Test] procedure Cell_AsciiPrintable_AllNarrow;
    [Test] procedure Cell_CjkIdeograph_IsWide;
    [Test] procedure CellLength_EmptyString_ReturnsZero;
    [Test] procedure CellLength_AsciiOnly_MatchesLength;
    [Test] procedure CellLength_MixedNarrowWide_SumsCells;
    [Test] procedure CellLength_NarrowWithCombining_DropsCombining;
  end;

implementation

uses
  System.SysUtils,
  VSoft.AnsiConsole.Internal.Cell;

procedure TCellWidthTests.Cell_EmojiRange_IsWide;
begin
  // Hangul syllable (wide)
  Assert.AreEqual(2, CellLengthChar(#$AC00), 'Hangul should be wide');
  // Soccer ball U+26BD (wide symbol)
  Assert.AreEqual(2, CellLengthChar(#$26BD), 'Soccer ball should be wide');
  // ASCII letter (narrow)
  Assert.AreEqual(1, CellLengthChar('A'), 'ASCII letter should be narrow');
end;

procedure TCellWidthTests.Cell_CombiningMark_IsZero;
begin
  // COMBINING ACUTE ACCENT (U+0301)
  Assert.AreEqual(0, CellLengthChar(#$0301), 'Combining mark should be zero-width');
end;

procedure TCellWidthTests.Cell_AsciiPrintable_AllNarrow;
var
  ch : Char;
begin
  // Every printable ASCII glyph occupies a single cell.
  for ch := ' ' to '~' do
    Assert.AreEqual(1, CellLengthChar(ch),
      'Expected narrow for ASCII char #' + IntToStr(Ord(ch)));
end;

procedure TCellWidthTests.Cell_CjkIdeograph_IsWide;
begin
  // CJK UNIFIED IDEOGRAPH 'CHINESE NUMBER ONE' (U+4E00) is full-width.
  Assert.AreEqual(2, CellLengthChar(#$4E00), 'CJK ideograph should be wide');
  // Fullwidth Latin Capital Letter A (U+FF21) - explicitly wide variant.
  Assert.AreEqual(2, CellLengthChar(#$FF21), 'Fullwidth Latin should be wide');
end;

procedure TCellWidthTests.CellLength_EmptyString_ReturnsZero;
begin
  Assert.AreEqual(0, CellLength(''));
end;

procedure TCellWidthTests.CellLength_AsciiOnly_MatchesLength;
begin
  Assert.AreEqual(11, CellLength('hello world'));
end;

procedure TCellWidthTests.CellLength_MixedNarrowWide_SumsCells;
begin
  // 'A' (1) + Hangul (2) + 'B' (1) = 4 cells
  Assert.AreEqual(4, CellLength('A' + #$AC00 + 'B'));
end;

procedure TCellWidthTests.CellLength_NarrowWithCombining_DropsCombining;
begin
  // 'e' (1) + COMBINING ACUTE ACCENT (0) = 1 cell on screen.
  Assert.AreEqual(1, CellLength('e' + #$0301));
end;

initialization
  TDUnitX.RegisterTestFixture(TCellWidthTests);

end.
