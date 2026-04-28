unit Tests.Markup;

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Markup.Tokenizer,
  VSoft.AnsiConsole.Markup.Parser;

type
  [TestFixture]
  TMarkupTests = class
  public
    [Test] procedure Tokenize_PlainText;
    [Test] procedure Tokenize_EscapedBrackets;
    [Test] procedure Tokenize_SimpleOpenClose;
    [Test] procedure Tokenize_UnterminatedRaises;

    [Test] procedure ParseStyle_RedBold;
    [Test] procedure ParseStyle_OnBlueForBackground;
    [Test] procedure ParseStyle_HexColor;
    [Test] procedure ParseStyle_LinkWithUrl;
    [Test] procedure ParseStyle_LinkAlone_AutoUnderlines;
    [Test] procedure ParseStyle_LinkWithExplicitDeco_DoesNotAddUnderline;
    [Test] procedure ParseStyle_LinkWithBoldOnly_KeepsBoldNoAutoUnderline;
    [Test] procedure ParseStyle_LinkWithColorOnly_AutoUnderlinesAndKeepsColor;

    [Test] procedure Parse_PlainText_OneSegment;
    [Test] procedure Parse_RedText_StyledSegment;
    [Test] procedure Parse_NestedTags_Combine;
    [Test] procedure Parse_EscapedBrackets_LiteralChars;
    [Test] procedure Parse_UnbalancedClose_DoesNotRaise;

    [Test] procedure Tokenize_EmptyString_NoTokens;
    [Test] procedure Tokenize_TagWithSpaces_KeepsBody;
    [Test] procedure Tokenize_TextSurroundingTags_ThreeTokens;

    [Test] procedure ParseStyle_ShortHexColor_ExpandsToFull;
    [Test] procedure ParseStyle_MultipleDecorations_AllSet;
    [Test] procedure ParseStyle_UnknownToken_IgnoredButSucceeds;
    [Test] procedure ParseStyle_BackgroundOnly_HasDefaultForeground;
    [Test] procedure ParseStyle_StrikeAlias_MapsToStrikethrough;
    [Test] procedure ParseStyle_ReverseAlias_MapsToInvert;
    [Test] procedure ParseStyle_GreyAlias_MapsToGrey;

    [Test] procedure Parse_EmptyString_NoSegments;
    [Test] procedure Parse_LineBreakInText_StartsNewSegment;
    [Test] procedure Parse_OpenWithoutClose_AppliesToTrailingText;
    [Test] procedure Parse_CrLf_OnlyOneLineBreakSegment;
    [Test] procedure Parse_BaseStyleApplied_WhenNoTags;
    [Test] procedure Parse_TagsLayerOverBaseStyle;
  end;

implementation

procedure TMarkupTests.Tokenize_PlainText;
var
  toks : TMarkupTokens;
begin
  toks := TokenizeMarkup('hello');
  Assert.AreEqual<integer>(1, Length(toks));
  Assert.AreEqual<Integer>(Ord(TMarkupTokenKind.Text), Ord(toks[0].Kind));
  Assert.AreEqual('hello', toks[0].Value);
end;

procedure TMarkupTests.Tokenize_EscapedBrackets;
var
  toks : TMarkupTokens;
begin
  toks := TokenizeMarkup('[[hi]]');
  Assert.AreEqual<integer>(1, Length(toks));
  Assert.AreEqual<Integer>(Ord(TMarkupTokenKind.Text), Ord(toks[0].Kind));
  Assert.AreEqual('[hi]', toks[0].Value);
end;

procedure TMarkupTests.Tokenize_SimpleOpenClose;
var
  toks : TMarkupTokens;
begin
  toks := TokenizeMarkup('[red]hi[/]');
  Assert.AreEqual<integer>(3, Length(toks));
  Assert.AreEqual<Integer>(Ord(TMarkupTokenKind.Open), Ord(toks[0].Kind));
  Assert.AreEqual('red', toks[0].Value);
  Assert.AreEqual<Integer>(Ord(TMarkupTokenKind.Text), Ord(toks[1].Kind));
  Assert.AreEqual('hi', toks[1].Value);
  Assert.AreEqual<Integer>(Ord(TMarkupTokenKind.Close), Ord(toks[2].Kind));
  Assert.AreEqual('', toks[2].Value);
end;

procedure TMarkupTests.Tokenize_UnterminatedRaises;
begin
  Assert.WillRaise(procedure begin TokenizeMarkup('[red'); end, EMarkupParseError);
end;

procedure TMarkupTests.ParseStyle_RedBold;
var
  style : TAnsiStyle;
begin
  Assert.IsTrue(ParseStyleExpr('red bold', style));
  Assert.IsTrue(style.Foreground.Equals(TAnsiColor.Red));
  Assert.IsTrue(TAnsiDecoration.Bold in style.Decorations);
end;

procedure TMarkupTests.ParseStyle_OnBlueForBackground;
var
  style : TAnsiStyle;
begin
  Assert.IsTrue(ParseStyleExpr('red on blue', style));
  Assert.IsTrue(style.Foreground.Equals(TAnsiColor.Red));
  Assert.IsTrue(style.Background.Equals(TAnsiColor.Blue));
end;

procedure TMarkupTests.ParseStyle_HexColor;
var
  style : TAnsiStyle;
begin
  Assert.IsTrue(ParseStyleExpr('#ff8800', style));
  Assert.AreEqual<Byte>($FF, style.Foreground.R);
  Assert.AreEqual<Byte>($88, style.Foreground.G);
  Assert.AreEqual<Byte>($00, style.Foreground.B);
end;

procedure TMarkupTests.ParseStyle_LinkWithUrl;
var
  style : TAnsiStyle;
begin
  Assert.IsTrue(ParseStyleExpr('link=https://example.com', style));
  Assert.AreEqual('https://example.com', style.Link);
end;

procedure TMarkupTests.ParseStyle_LinkAlone_AutoUnderlines;
var
  style : TAnsiStyle;
begin
  // A bare [link=...] tag is invisible without a visual cue, so the parser
  // adds underline automatically when the tag specifies no decoration.
  Assert.IsTrue(ParseStyleExpr('link=https://example.com', style));
  Assert.IsTrue(TAnsiDecoration.Underline in style.Decorations,
    'A link tag with no other decoration should auto-add underline');
end;

procedure TMarkupTests.ParseStyle_LinkWithExplicitDeco_DoesNotAddUnderline;
var
  style : TAnsiStyle;
begin
  // User asked for italic only - we must respect that and NOT add underline.
  Assert.IsTrue(ParseStyleExpr('italic link=https://example.com', style));
  Assert.IsTrue(TAnsiDecoration.Italic in style.Decorations);
  Assert.IsFalse(TAnsiDecoration.Underline in style.Decorations,
    'Explicit decoration must suppress the auto-underline');
end;

procedure TMarkupTests.ParseStyle_LinkWithBoldOnly_KeepsBoldNoAutoUnderline;
var
  style : TAnsiStyle;
begin
  Assert.IsTrue(ParseStyleExpr('bold link=https://example.com', style));
  Assert.IsTrue(TAnsiDecoration.Bold in style.Decorations);
  Assert.IsFalse(TAnsiDecoration.Underline in style.Decorations);
end;

procedure TMarkupTests.ParseStyle_LinkWithColorOnly_AutoUnderlinesAndKeepsColor;
var
  style : TAnsiStyle;
begin
  // A foreground colour is not a decoration, so the auto-underline still
  // fires and the user's colour is preserved on top.
  Assert.IsTrue(ParseStyleExpr('red link=https://example.com', style));
  Assert.IsTrue(style.Foreground.Equals(TAnsiColor.Red));
  Assert.IsTrue(TAnsiDecoration.Underline in style.Decorations,
    'Colour without an explicit decoration should still trigger auto-underline');
end;

procedure TMarkupTests.Parse_PlainText_OneSegment;
var
  segs : TAnsiSegments;
begin
  segs := ParseMarkup('hello');
  Assert.AreEqual<integer>(1, Length(segs));
  Assert.AreEqual('hello', segs[0].Value);
  Assert.IsTrue(segs[0].Style.IsPlain);
end;

procedure TMarkupTests.Parse_RedText_StyledSegment;
var
  segs : TAnsiSegments;
begin
  segs := ParseMarkup('[red]hi[/]');
  Assert.AreEqual<integer>(1, Length(segs));
  Assert.AreEqual('hi', segs[0].Value);
  Assert.IsTrue(segs[0].Style.Foreground.Equals(TAnsiColor.Red));
end;

procedure TMarkupTests.Parse_NestedTags_Combine;
var
  segs : TAnsiSegments;
begin
  segs := ParseMarkup('[red][bold]X[/][/]');
  Assert.AreEqual<integer>(1, Length(segs));
  Assert.IsTrue(segs[0].Style.Foreground.Equals(TAnsiColor.Red));
  Assert.IsTrue(TAnsiDecoration.Bold in segs[0].Style.Decorations);
end;

procedure TMarkupTests.Parse_EscapedBrackets_LiteralChars;
var
  segs : TAnsiSegments;
begin
  segs := ParseMarkup('a[[b]]c');
  Assert.AreEqual<integer>(1, Length(segs));
  Assert.AreEqual('a[b]c', segs[0].Value);
end;

procedure TMarkupTests.Parse_UnbalancedClose_DoesNotRaise;
var
  segs : TAnsiSegments;
begin
  // Extra [/] without a matching open should be silently tolerated.
  Assert.WillNotRaise(
    procedure
    begin
      segs := ParseMarkup('[/]hello[/][/]');
    end);
end;

procedure TMarkupTests.Tokenize_EmptyString_NoTokens;
var
  toks : TMarkupTokens;
begin
  toks := TokenizeMarkup('');
  Assert.AreEqual<Integer>(0, Length(toks),
    'Empty input should produce no tokens');
end;

procedure TMarkupTests.Tokenize_TagWithSpaces_KeepsBody;
var
  toks : TMarkupTokens;
begin
  toks := TokenizeMarkup('[red bold on blue]X[/]');
  Assert.AreEqual<Integer>(3, Length(toks));
  Assert.AreEqual<Integer>(Ord(TMarkupTokenKind.Open), Ord(toks[0].Kind));
  Assert.AreEqual('red bold on blue', toks[0].Value,
    'Open tag body should be kept verbatim including spaces');
end;

procedure TMarkupTests.Tokenize_TextSurroundingTags_ThreeTokens;
var
  toks : TMarkupTokens;
begin
  toks := TokenizeMarkup('hi [red]there[/] world');
  // Expected: text, open, text, close, text
  Assert.AreEqual<Integer>(5, Length(toks));
  Assert.AreEqual<Integer>(Ord(TMarkupTokenKind.Text),  Ord(toks[0].Kind));
  Assert.AreEqual('hi ',                 toks[0].Value);
  Assert.AreEqual<Integer>(Ord(TMarkupTokenKind.Open),  Ord(toks[1].Kind));
  Assert.AreEqual<Integer>(Ord(TMarkupTokenKind.Text),  Ord(toks[2].Kind));
  Assert.AreEqual('there',               toks[2].Value);
  Assert.AreEqual<Integer>(Ord(TMarkupTokenKind.Close), Ord(toks[3].Kind));
  Assert.AreEqual<Integer>(Ord(TMarkupTokenKind.Text),  Ord(toks[4].Kind));
  Assert.AreEqual(' world',              toks[4].Value);
end;

procedure TMarkupTests.ParseStyle_ShortHexColor_ExpandsToFull;
var
  style : TAnsiStyle;
begin
  // #f80 should expand to #ff8800.
  Assert.IsTrue(ParseStyleExpr('#f80', style));
  Assert.AreEqual<Byte>($FF, style.Foreground.R);
  Assert.AreEqual<Byte>($88, style.Foreground.G);
  Assert.AreEqual<Byte>($00, style.Foreground.B);
end;

procedure TMarkupTests.ParseStyle_MultipleDecorations_AllSet;
var
  style : TAnsiStyle;
begin
  Assert.IsTrue(ParseStyleExpr('bold italic underline strikethrough', style));
  Assert.IsTrue(TAnsiDecoration.Bold          in style.Decorations);
  Assert.IsTrue(TAnsiDecoration.Italic        in style.Decorations);
  Assert.IsTrue(TAnsiDecoration.Underline     in style.Decorations);
  Assert.IsTrue(TAnsiDecoration.Strikethrough in style.Decorations);
end;

procedure TMarkupTests.ParseStyle_UnknownToken_IgnoredButSucceeds;
var
  style : TAnsiStyle;
begin
  // Unknown words must be ignored - the parser stays resilient.
  Assert.IsTrue(ParseStyleExpr('red zomgwhat bold', style));
  Assert.IsTrue(style.Foreground.Equals(TAnsiColor.Red));
  Assert.IsTrue(TAnsiDecoration.Bold in style.Decorations);
end;

procedure TMarkupTests.ParseStyle_BackgroundOnly_HasDefaultForeground;
var
  style : TAnsiStyle;
begin
  Assert.IsTrue(ParseStyleExpr('on blue', style));
  Assert.IsTrue(style.Foreground.IsDefault, 'No FG specified -> Default');
  Assert.IsTrue(style.Background.Equals(TAnsiColor.Blue));
end;

procedure TMarkupTests.ParseStyle_StrikeAlias_MapsToStrikethrough;
var
  style : TAnsiStyle;
begin
  Assert.IsTrue(ParseStyleExpr('strike', style));
  Assert.IsTrue(TAnsiDecoration.Strikethrough in style.Decorations,
    'Short alias "strike" should set TAnsiDecoration.Strikethrough');
end;

procedure TMarkupTests.ParseStyle_ReverseAlias_MapsToInvert;
var
  style : TAnsiStyle;
begin
  Assert.IsTrue(ParseStyleExpr('reverse', style));
  Assert.IsTrue(TAnsiDecoration.Invert in style.Decorations,
    'Alias "reverse" should set TAnsiDecoration.Invert');
end;

procedure TMarkupTests.ParseStyle_GreyAlias_MapsToGrey;
var
  s1, s2 : TAnsiStyle;
begin
  Assert.IsTrue(ParseStyleExpr('grey', s1));
  Assert.IsTrue(ParseStyleExpr('gray', s2));
  Assert.IsTrue(s1.Foreground.Equals(s2.Foreground),
    'grey and gray should resolve to the same color');
end;

procedure TMarkupTests.Parse_EmptyString_NoSegments;
var
  segs : TAnsiSegments;
begin
  segs := ParseMarkup('');
  Assert.AreEqual<Integer>(0, Length(segs));
end;

procedure TMarkupTests.Parse_LineBreakInText_StartsNewSegment;
var
  segs : TAnsiSegments;
  lbCount, i : Integer;
begin
  segs := ParseMarkup('aa'#10'bb');
  // Expected: text 'aa', LineBreak, text 'bb' (= 3 segments).
  Assert.AreEqual<Integer>(3, Length(segs));
  lbCount := 0;
  for i := 0 to High(segs) do
    if segs[i].IsLineBreak then Inc(lbCount);
  Assert.AreEqual(1, lbCount, 'Single LF should produce exactly one LineBreak segment');
end;

procedure TMarkupTests.Parse_OpenWithoutClose_AppliesToTrailingText;
var
  segs : TAnsiSegments;
begin
  // No matching [/] - the style still wraps the trailing text rather
  // than raising.
  segs := ParseMarkup('[red]tail');
  Assert.AreEqual<Integer>(1, Length(segs));
  Assert.AreEqual('tail', segs[0].Value);
  Assert.IsTrue(segs[0].Style.Foreground.Equals(TAnsiColor.Red),
    'Unclosed open tag should still style the trailing text');
end;

procedure TMarkupTests.Parse_CrLf_OnlyOneLineBreakSegment;
var
  segs : TAnsiSegments;
  lbCount, i : Integer;
begin
  // CR is swallowed; only the LF drives the line break, so CRLF should
  // produce exactly one LineBreak segment, not two.
  segs := ParseMarkup('aa'#13#10'bb');
  lbCount := 0;
  for i := 0 to High(segs) do
    if segs[i].IsLineBreak then Inc(lbCount);
  Assert.AreEqual(1, lbCount,
    'CRLF should collapse to a single LineBreak segment');
end;

procedure TMarkupTests.Parse_BaseStyleApplied_WhenNoTags;
var
  segs : TAnsiSegments;
  base : TAnsiStyle;
begin
  base := TAnsiStyle.Plain.WithForeground(TAnsiColor.Yellow);
  segs := ParseMarkup('plain', base);
  Assert.AreEqual<Integer>(1, Length(segs));
  Assert.IsTrue(segs[0].Style.Foreground.Equals(TAnsiColor.Yellow),
    'Base style should apply when no tags wrap the text');
end;

procedure TMarkupTests.Parse_TagsLayerOverBaseStyle;
var
  segs : TAnsiSegments;
  base : TAnsiStyle;
begin
  // Base = yellow FG. Tag adds bold. Both should be visible on the
  // combined style.
  base := TAnsiStyle.Plain.WithForeground(TAnsiColor.Yellow);
  segs := ParseMarkup('[bold]X[/]', base);
  Assert.AreEqual<Integer>(1, Length(segs));
  Assert.IsTrue(segs[0].Style.Foreground.Equals(TAnsiColor.Yellow),
    'Base FG should still apply through the tag');
  Assert.IsTrue(TAnsiDecoration.Bold in segs[0].Style.Decorations,
    'Tag-supplied decoration should layer on top of the base');
end;

initialization
  TDUnitX.RegisterTestFixture(TMarkupTests);

end.
