unit Tests.Widgets.Canvas;

{
  Canvas widget tests - half-block rendering, ASCII fallback, MaxWidth
  scaling and cropping.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Widgets.Canvas;

type
  [TestFixture]
  TCanvasTests = class
  public
    [Test] procedure UnicodeHalfBlock_Output;
    [Test] procedure AsciiFallback_UsesDoubleSpace;
    [Test] procedure MaxWidth_Scale_DownsamplesGrid;
    [Test] procedure MaxWidth_NoScale_CropsButKeepsHeight;
    [Test] procedure Scale_PreservesDistantPixel;
    [Test] procedure EmptyCanvas_RendersWithoutError;
    [Test] procedure ClearPixel_RemovesPreviouslySetPixel;
    [Test] procedure SetPixel_OutOfBounds_IsIgnored;
    [Test] procedure DistinctColors_EmitDistinctSGR;
    [Test] procedure RowCount_MatchesHeightOverTwo;
  end;

implementation

uses
  System.SysUtils,
  Testing.AnsiConsole;

function BuildPlain(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.NoColors, width, True, result, sink);
end;

function BuildPlainAscii(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.NoColors, width, False, result, sink);
end;

function CountLineBreaks(const value : string) : Integer;
var
  i : Integer;
begin
  result := 0;
  for i := 1 to Length(value) do
    if value[i] = #10 then Inc(result);
end;

procedure TCanvasTests.UnicodeHalfBlock_Output;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  c       : ICanvas;
begin
  console := BuildPlain(40, sink);
  c := Canvas(4, 4);
  c.SetPixel(0, 0, TAnsiColor.Red);
  c.SetPixel(1, 1, TAnsiColor.Blue);
  console.Write(c);
  // In unicode mode the top-left cell uses UPPER HALF BLOCK (U+2580).
  Assert.IsTrue(Pos(#$2580, sink.Text) > 0, 'Expected upper-half-block in unicode mode');
end;

procedure TCanvasTests.AsciiFallback_UsesDoubleSpace;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  c       : ICanvas;
begin
  console := BuildPlainAscii(40, sink);
  c := Canvas(2, 2);
  c.SetPixel(0, 0, TAnsiColor.Red);
  console.Write(c);
  // ASCII fallback emits pairs of spaces; output must contain at least one.
  Assert.IsTrue(Pos('  ', sink.Text) > 0, 'ASCII canvas should emit "  " cells');
end;

procedure TCanvasTests.MaxWidth_Scale_DownsamplesGrid;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  c       : ICanvas;
  lines   : Integer;
begin
  // 16x16 canvas in unicode mode normally emits 16/2 = 8 rows. With Scale
  // resampling to MaxWidth=8, the grid collapses to 8x8 source pixels and
  // emits 8/2 = 4 rows. (Default WithScale(True).)
  console := BuildPlain(80, sink);
  c := Canvas(16, 16).WithMaxWidth(8);   // FScale=True by default
  c.SetPixel(0, 0, TAnsiColor.Red);
  c.SetPixel(15, 15, TAnsiColor.Blue);
  console.Write(c);
  lines := CountLineBreaks(sink.Text);
  Assert.AreEqual(4, lines, 'Scaled 16x16 canvas at MaxWidth=8 should emit 4 rows');
end;

procedure TCanvasTests.MaxWidth_NoScale_CropsButKeepsHeight;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  c       : ICanvas;
  lines   : Integer;
begin
  // With Scale=False the canvas is cropped horizontally but the source
  // height is preserved -> 16/2 = 8 rows still emitted.
  console := BuildPlain(80, sink);
  c := Canvas(16, 16).WithMaxWidth(8).WithScale(False);
  c.SetPixel(0, 0, TAnsiColor.Red);
  console.Write(c);
  lines := CountLineBreaks(sink.Text);
  Assert.AreEqual(8, lines, 'Cropped 16x16 canvas at MaxWidth=8 should keep all 8 rows');
end;

procedure TCanvasTests.EmptyCanvas_RendersWithoutError;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // No pixels set: every cell renders as a blank-block. The render should
  // still produce output without raising.
  console := BuildPlain(40, sink);
  console.Write(Canvas(4, 4));
  Assert.IsTrue(Length(sink.Text) > 0,
    'Empty canvas should still render some whitespace cells');
end;

procedure TCanvasTests.ClearPixel_RemovesPreviouslySetPixel;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  before, after : string;
begin
  // Render with a pixel set...
  BuildCapturedConsole(TColorSystem.TrueColor, 40, True, console, sink);
  console.Write(Canvas(2, 2).SetPixel(0, 0, TAnsiColor.Red));
  before := sink.Text;

  // ...then with the same pixel cleared.
  BuildCapturedConsole(TColorSystem.TrueColor, 40, True, console, sink);
  console.Write(Canvas(2, 2).SetPixel(0, 0, TAnsiColor.Red).ClearPixel(0, 0));
  after := sink.Text;

  // The "before" output should contain a Red foreground SGR; the "after"
  // version (cleared) should not.
  Assert.IsTrue(Pos('38;2;255;0;0', before) > 0,
    'Set+render should emit the Red SGR');
  Assert.IsTrue(Pos('38;2;255;0;0', after) = 0,
    'After ClearPixel the Red SGR should be gone');
end;

procedure TCanvasTests.SetPixel_OutOfBounds_IsIgnored;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // Out-of-range coordinates must not raise; the canvas silently drops them.
  console := BuildPlain(40, sink);
  console.Write(
    Canvas(2, 2)
      .SetPixel(-1, 0, TAnsiColor.Red)
      .SetPixel(0, -1, TAnsiColor.Red)
      .SetPixel(2,  0, TAnsiColor.Red)
      .SetPixel(0,  2, TAnsiColor.Red));
  Assert.IsTrue(Length(sink.Text) > 0, 'Render should complete successfully');
end;

procedure TCanvasTests.DistinctColors_EmitDistinctSGR;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  BuildCapturedConsole(TColorSystem.TrueColor, 40, True, console, sink);
  console.Write(Canvas(2, 2)
    .SetPixel(0, 0, TAnsiColor.Red)
    .SetPixel(1, 0, TAnsiColor.Lime)
    .SetPixel(0, 1, TAnsiColor.Blue));
  output := sink.Text;
  Assert.IsTrue(Pos('255;0;0',  output) > 0, 'Red SGR present');
  Assert.IsTrue(Pos('0;255;0',  output) > 0, 'Lime SGR present');
  Assert.IsTrue(Pos('0;0;255',  output) > 0, 'Blue SGR present');
end;

procedure TCanvasTests.RowCount_MatchesHeightOverTwo;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // Unicode mode packs two source rows into one output row via half-blocks,
  // so a 6-tall canvas should emit exactly 3 rendered rows.
  console := BuildPlain(80, sink);
  console.Write(Canvas(2, 6).SetPixel(0, 0, TAnsiColor.Red));
  Assert.AreEqual(3, CountLineBreaks(sink.Text),
    '6-row canvas should emit 3 half-block rows in unicode mode');
end;

procedure TCanvasTests.Scale_PreservesDistantPixel;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  c       : ICanvas;
  scaledOutput, croppedOutput : string;
begin
  // A pixel at (15, 15) is in the bottom-right corner. Scaling preserves it
  // (resamples to (7, 7) approximately); cropping discards it. Compare
  // outputs to confirm scaling is doing real work, not just clipping.
  console := BuildPlain(80, sink);
  c := Canvas(16, 16).WithMaxWidth(8);   // scale on
  c.SetPixel(15, 15, TAnsiColor.Red);
  console.Write(c);
  scaledOutput := sink.Text;

  console := BuildPlain(80, sink);   // fresh sink
  c := Canvas(16, 16).WithMaxWidth(8).WithScale(False);
  c.SetPixel(15, 15, TAnsiColor.Red);
  console.Write(c);
  croppedOutput := sink.Text;

  // The scaled output renders the half-block glyph (UPPER HALF or LOWER
  // HALF) somewhere because the corner pixel survives resampling. The
  // cropped output should not (corner column is past MaxWidth).
  Assert.IsTrue(
    (Pos(#$2580, scaledOutput) > 0) or (Pos(#$2584, scaledOutput) > 0),
    'Scaled output should contain a half-block glyph for the corner pixel');
  Assert.IsTrue(
    (Pos(#$2580, croppedOutput) = 0) and (Pos(#$2584, croppedOutput) = 0),
    'Cropped output should not contain a half-block (corner is clipped)');
end;

initialization
  TDUnitX.RegisterTestFixture(TCanvasTests);

end.
