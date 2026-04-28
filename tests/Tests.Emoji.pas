unit Tests.Emoji;

{
  Emoji table + Replace algorithm fixtures.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Emoji;

type
  [TestFixture]
  TEmojiTests = class
  public
    [Test] procedure Get_KnownShortcode_ReturnsGlyph;
    [Test] procedure Get_UnknownShortcode_ReturnsEmpty;
    [Test] procedure Get_StripsBracketingColons;
    [Test] procedure Replace_PlainText_PassesThrough;
    [Test] procedure Replace_KnownShortcode_Substitutes;
    [Test] procedure Replace_UnknownShortcode_PassesThrough;
    [Test] procedure Replace_MultipleShortcodes;
    [Test] procedure Replace_AdjacentColons_NotConsumed;
    [Test] procedure Remap_OverridesShortcode;
    [Test] procedure Constants_AbacusIsExpected;
  end;

implementation

uses
  System.SysUtils;

procedure TEmojiTests.Get_KnownShortcode_ReturnsGlyph;
begin
  Assert.AreEqual(EmojiNames.Abacus, TEmoji.Get('abacus'));
end;

procedure TEmojiTests.Get_UnknownShortcode_ReturnsEmpty;
begin
  Assert.AreEqual('', TEmoji.Get('this_is_not_a_real_emoji_xyz'));
end;

procedure TEmojiTests.Get_StripsBracketingColons;
begin
  // ':abacus:' should be normalised by stripping the colons.
  Assert.AreEqual(EmojiNames.Abacus, TEmoji.Get(':abacus:'));
end;

procedure TEmojiTests.Replace_PlainText_PassesThrough;
begin
  Assert.AreEqual('hello world', TEmoji.Replace('hello world'));
end;

procedure TEmojiTests.Replace_KnownShortcode_Substitutes;
begin
  Assert.AreEqual('counted on ' + EmojiNames.Abacus + ' beads',
    TEmoji.Replace('counted on :abacus: beads'));
end;

procedure TEmojiTests.Replace_UnknownShortcode_PassesThrough;
var
  s : string;
begin
  s := TEmoji.Replace('hi :nope_unknown_xyz: there');
  Assert.IsTrue(Pos('nope_unknown_xyz', s) > 0,
    'Unknown shortcode should remain in the output verbatim');
end;

procedure TEmojiTests.Replace_MultipleShortcodes;
begin
  Assert.AreEqual(EmojiNames.Abacus + ' and ' + EmojiNames.Anchor,
    TEmoji.Replace(':abacus: and :anchor:'));
end;

procedure TEmojiTests.Replace_AdjacentColons_NotConsumed;
begin
  // Bare colons not paired with an identifier shouldn't break the scanner.
  Assert.AreEqual('time::stamp', TEmoji.Replace('time::stamp'));
end;

procedure TEmojiTests.Remap_OverridesShortcode;
var
  custom : string;
begin
  // Replace a known shortcode with something we control, verify, then
  // restore.
  custom := 'CUSTOM_GLYPH_VALUE';
  TEmoji.Remap('abacus', custom);
  try
    Assert.AreEqual(custom, TEmoji.Get('abacus'));
  finally
    TEmoji.Remap('abacus', EmojiNames.Abacus);   // restore
  end;
end;

procedure TEmojiTests.Constants_AbacusIsExpected;
begin
  // U+1F9EE encoded as UTF-16 surrogate pair D83E DDEE.
  Assert.AreEqual(2, Length(EmojiNames.Abacus),
    'Abacus glyph should be a 2-char surrogate pair');
  Assert.AreEqual(#$D83E, EmojiNames.Abacus[1]);
  Assert.AreEqual(#$DDEE, EmojiNames.Abacus[2]);
end;

initialization
  TDUnitX.RegisterTestFixture(TEmojiTests);

end.
