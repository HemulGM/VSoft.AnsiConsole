unit Tests.Live.Spinners;

{
  Spinner factory tests - exercise the named-kind lookup, custom
  frame factory, frame-index wrap-around, ASCII fallback, and
  RandomSpinner helper.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Live.Spinners;

type
  [TestFixture]
  TSpinnerTests = class
  public
    [Test] procedure NamedSpinner_LineKind_HasFourAsciiFrames;
    [Test] procedure NamedSpinner_DotsKind_HasUnicodeFrames;
    [Test] procedure Frame_Index_WrapsAroundModFrameCount;
    [Test] procedure Frame_NegativeIndex_ReturnsFirstFrame;
    [Test] procedure Frame_EmptyCustomSpinner_ReturnsEmptyString;
    [Test] procedure CustomSpinner_HonoursFramesAndInterval;
    [Test] procedure CustomSpinner_ZeroInterval_ClampsToOne;
    [Test] procedure UnicodeFalse_FallsBackToLineFrames;
    [Test] procedure RandomSpinner_PickReturnsKnownKind;
    [Test] procedure RandomSpinner_MakeReturnsValidSpinner;
  end;

implementation

uses
  System.SysUtils;

procedure TSpinnerTests.NamedSpinner_LineKind_HasFourAsciiFrames;
var
  s : ISpinner;
begin
  s := Spinner(TSpinnerKind.Line);
  Assert.AreEqual(4, s.Frames, 'skLine ships with 4 frames');
  Assert.AreEqual('-',  s.Frame(0));
  Assert.AreEqual('\',  s.Frame(1));
  Assert.AreEqual('|',  s.Frame(2));
  Assert.AreEqual('/',  s.Frame(3));
  Assert.IsTrue(s.IntervalMs > 0, 'Interval must be positive');
end;

procedure TSpinnerTests.NamedSpinner_DotsKind_HasUnicodeFrames;
var
  s : ISpinner;
  i : Integer;
  frame : string;
begin
  s := Spinner(TSpinnerKind.Dots, True);
  Assert.IsTrue(s.Frames > 0, 'Dots should ship at least one frame');
  // Every Dots frame is a single Braille code point (U+2800..U+28FF).
  for i := 0 to s.Frames - 1 do
  begin
    frame := s.Frame(i);
    Assert.AreEqual(1, Length(frame),
      Format('Dots frame %d should be a single char, got "%s"', [i, frame]));
    Assert.IsTrue((Ord(frame[1]) >= $2800) and (Ord(frame[1]) <= $28FF),
      Format('Dots frame %d should be a Braille code point', [i]));
  end;
end;

procedure TSpinnerTests.Frame_Index_WrapsAroundModFrameCount;
var
  s : ISpinner;
begin
  s := Spinner(TSpinnerKind.Line);
  // skLine has 4 frames; index n+4 should equal index n.
  Assert.AreEqual(s.Frame(0), s.Frame(4));
  Assert.AreEqual(s.Frame(1), s.Frame(5));
  Assert.AreEqual(s.Frame(2), s.Frame(1234567 * 4 + 2));
end;

procedure TSpinnerTests.Frame_NegativeIndex_ReturnsFirstFrame;
var
  s : ISpinner;
begin
  s := Spinner(TSpinnerKind.Line);
  Assert.AreEqual(s.Frame(0), s.Frame(-1),
    'Negative indices should clamp to the first frame');
  Assert.AreEqual(s.Frame(0), s.Frame(-9999));
end;

procedure TSpinnerTests.Frame_EmptyCustomSpinner_ReturnsEmptyString;
var
  s : ISpinner;
  empty : TArray<string>;
begin
  SetLength(empty, 0);
  s := Spinner(empty, 100);
  Assert.AreEqual(0, s.Frames);
  Assert.AreEqual('', s.Frame(0),
    'Frame on a zero-frame spinner must not raise; returns ""');
end;

procedure TSpinnerTests.CustomSpinner_HonoursFramesAndInterval;
var
  s : ISpinner;
  frames : TArray<string>;
begin
  SetLength(frames, 3);
  frames[0] := 'a';
  frames[1] := 'b';
  frames[2] := 'c';
  s := Spinner(frames, 250);
  Assert.AreEqual(3, s.Frames);
  Assert.AreEqual('a', s.Frame(0));
  Assert.AreEqual('b', s.Frame(1));
  Assert.AreEqual('c', s.Frame(2));
  Assert.AreEqual(250, s.IntervalMs);
end;

procedure TSpinnerTests.CustomSpinner_ZeroInterval_ClampsToOne;
var
  s : ISpinner;
  frames : TArray<string>;
begin
  SetLength(frames, 1);
  frames[0] := '*';
  s := Spinner(frames, 0);
  Assert.IsTrue(s.IntervalMs >= 1,
    'Zero interval must be clamped to a positive value');
end;

procedure TSpinnerTests.UnicodeFalse_FallsBackToLineFrames;
var
  s : ISpinner;
  i : Integer;
  frame : string;
  ok : Boolean;
begin
  // skDots is unicode-only. With unicode=False the factory should fall
  // back to the simple skLine frame set so the spinner still animates.
  s := Spinner(TSpinnerKind.Dots, False);
  Assert.IsTrue(s.Frames > 0, 'Fallback spinner must have frames');
  // Every fallback frame should be a single ASCII char.
  for i := 0 to s.Frames - 1 do
  begin
    frame := s.Frame(i);
    Assert.AreEqual(1, Length(frame));
    ok := (frame[1] = '-') or (frame[1] = '\') or
          (frame[1] = '|') or (frame[1] = '/');
    Assert.IsTrue(ok,
      Format('Fallback frame %d should be ASCII line char, got "%s"', [i, frame]));
  end;
end;

procedure TSpinnerTests.RandomSpinner_PickReturnsKnownKind;
var
  k : TSpinnerKind;
  i : Integer;
begin
  // Sample several picks; each must be a valid TSpinnerKind ordinal in
  // range. We don't assert distribution.
  for i := 1 to 20 do
  begin
    k := RandomSpinner.Pick;
    Assert.IsTrue((Ord(k) >= Ord(Low(TSpinnerKind))) and
                  (Ord(k) <= Ord(High(TSpinnerKind))),
      'Pick must return a valid TSpinnerKind value');
  end;
end;

procedure TSpinnerTests.RandomSpinner_MakeReturnsValidSpinner;
var
  s : ISpinner;
begin
  s := RandomSpinner.Make;
  Assert.IsNotNull(s);
  Assert.IsTrue(s.Frames > 0,
    'Random spinner should have at least one frame');
  Assert.IsTrue(s.IntervalMs > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TSpinnerTests);

end.
