unit Tests.Style;

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style;

type
  [TestFixture]
  TStyleTests = class
  public
    [Test] procedure Plain_IsPlain;
    [Test] procedure WithForeground_SetsFG_KeepsOthersPlain;
    [Test] procedure Combine_NewFGWins;
    [Test] procedure Combine_DefaultFGDoesNotOverride;
    [Test] procedure Combine_DecorationsAreUnioned;
    [Test] procedure Combine_LinkOverrides_WhenNonEmpty;
    [Test] procedure Equals_SameContent_True;
    [Test] procedure Equals_DifferentDecorations_False;

    [Test] procedure Parse_RedBold_ReturnsCorrectStyle;
    [Test] procedure Parse_RedOnBlue_SetsBackground;
    [Test] procedure Parse_Brackets_AreTolerated;
    [Test] procedure TryParse_Empty_ReturnsFalse;
    [Test] procedure Parse_Empty_Raises;
    [Test] procedure ToMarkup_Plain_ReturnsEmpty;
    [Test] procedure ToMarkup_RedBoldOnBlue_RoundTrips;
    [Test] procedure ToMarkup_WithLink_IncludesLinkToken;
  end;

implementation

procedure TStyleTests.Plain_IsPlain;
var
  s : TAnsiStyle;
begin
  s := TAnsiStyle.Plain;
  Assert.IsTrue(s.IsPlain);
  Assert.IsTrue(s.Foreground.IsDefault);
  Assert.IsTrue(s.Background.IsDefault);
  Assert.IsTrue(s.Decorations = []);
  Assert.AreEqual('', s.Link);
end;

procedure TStyleTests.WithForeground_SetsFG_KeepsOthersPlain;
var
  s : TAnsiStyle;
begin
  s := TAnsiStyle.Plain.WithForeground(TAnsiColor.Red);
  Assert.IsFalse(s.Foreground.IsDefault);
  Assert.IsTrue(s.Background.IsDefault);
  Assert.AreEqual('', s.Link);
end;

procedure TStyleTests.Combine_NewFGWins;
var
  a, b, c : TAnsiStyle;
begin
  a := TAnsiStyle.Plain.WithForeground(TAnsiColor.Red);
  b := TAnsiStyle.Plain.WithForeground(TAnsiColor.Blue);
  c := a.Combine(b);
  Assert.IsTrue(c.Foreground.Equals(TAnsiColor.Blue));
end;

procedure TStyleTests.Combine_DefaultFGDoesNotOverride;
var
  a, b, c : TAnsiStyle;
begin
  a := TAnsiStyle.Plain.WithForeground(TAnsiColor.Red);
  b := TAnsiStyle.Plain.WithDecorations([TAnsiDecoration.Bold]);
  c := a.Combine(b);
  Assert.IsTrue(c.Foreground.Equals(TAnsiColor.Red));
  Assert.IsTrue(TAnsiDecoration.Bold in c.Decorations);
end;

procedure TStyleTests.Combine_DecorationsAreUnioned;
var
  a, b, c : TAnsiStyle;
begin
  a := TAnsiStyle.Plain.WithDecorations([TAnsiDecoration.Bold]);
  b := TAnsiStyle.Plain.WithDecorations([TAnsiDecoration.Italic]);
  c := a.Combine(b);
  Assert.IsTrue(TAnsiDecoration.Bold   in c.Decorations);
  Assert.IsTrue(TAnsiDecoration.Italic in c.Decorations);
end;

procedure TStyleTests.Combine_LinkOverrides_WhenNonEmpty;
var
  a, b, c : TAnsiStyle;
begin
  a := TAnsiStyle.Plain.WithLink('https://old');
  b := TAnsiStyle.Plain.WithLink('https://new');
  c := a.Combine(b);
  Assert.AreEqual('https://new', c.Link);

  b := TAnsiStyle.Plain;  // empty link
  c := a.Combine(b);
  Assert.AreEqual('https://old', c.Link);
end;

procedure TStyleTests.Equals_SameContent_True;
var
  a, b : TAnsiStyle;
begin
  a := TAnsiStyle.Create(TAnsiColor.Red, TAnsiColor.Blue, [TAnsiDecoration.Bold, TAnsiDecoration.Italic]);
  b := TAnsiStyle.Create(TAnsiColor.Red, TAnsiColor.Blue, [TAnsiDecoration.Bold, TAnsiDecoration.Italic]);
  Assert.IsTrue(a.Equals(b));
end;

procedure TStyleTests.Equals_DifferentDecorations_False;
var
  a, b : TAnsiStyle;
begin
  a := TAnsiStyle.Create(TAnsiColor.Red, TAnsiColor.Blue, [TAnsiDecoration.Bold]);
  b := TAnsiStyle.Create(TAnsiColor.Red, TAnsiColor.Blue, [TAnsiDecoration.Italic]);
  Assert.IsFalse(a.Equals(b));
end;

procedure TStyleTests.Parse_RedBold_ReturnsCorrectStyle;
var
  s : TAnsiStyle;
begin
  s := TAnsiStyle.Parse('red bold');
  Assert.IsTrue(s.Foreground.Equals(TAnsiColor.Red));
  Assert.IsTrue(s.Background.IsDefault);
  Assert.IsTrue(TAnsiDecoration.Bold in s.Decorations);
end;

procedure TStyleTests.Parse_RedOnBlue_SetsBackground;
var
  s : TAnsiStyle;
begin
  s := TAnsiStyle.Parse('red on blue');
  Assert.IsTrue(s.Foreground.Equals(TAnsiColor.Red));
  Assert.IsTrue(s.Background.Equals(TAnsiColor.Blue));
end;

procedure TStyleTests.Parse_Brackets_AreTolerated;
var
  a, b : TAnsiStyle;
begin
  a := TAnsiStyle.Parse('red bold');
  b := TAnsiStyle.Parse('[red bold]');
  Assert.IsTrue(a.Equals(b));
end;

procedure TStyleTests.TryParse_Empty_ReturnsFalse;
var
  s : TAnsiStyle;
begin
  Assert.IsFalse(TAnsiStyle.TryParse('', s));
end;

procedure TStyleTests.Parse_Empty_Raises;
begin
  Assert.WillRaise(procedure begin TAnsiStyle.Parse(''); end);
end;

procedure TStyleTests.ToMarkup_Plain_ReturnsEmpty;
begin
  Assert.AreEqual('', TAnsiStyle.Plain.ToMarkup);
end;

procedure TStyleTests.ToMarkup_RedBoldOnBlue_RoundTrips;
var
  src, parsed : TAnsiStyle;
  text : string;
begin
  src := TAnsiStyle.Create(TAnsiColor.Red, TAnsiColor.Blue, [TAnsiDecoration.Bold]);
  text := src.ToMarkup;
  Assert.AreEqual('bold red on blue', text);
  parsed := TAnsiStyle.Parse(text);
  Assert.IsTrue(parsed.Equals(src));
end;

procedure TStyleTests.ToMarkup_WithLink_IncludesLinkToken;
var
  s : TAnsiStyle;
begin
  s := TAnsiStyle.Plain.WithForeground(TAnsiColor.Red).WithLink('https://example.com');
  Assert.AreEqual('red link=https://example.com', s.ToMarkup);
end;

initialization
  TDUnitX.RegisterTestFixture(TStyleTests);

end.
