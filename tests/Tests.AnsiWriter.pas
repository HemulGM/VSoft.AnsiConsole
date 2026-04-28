unit Tests.AnsiWriter;

{
  Byte-level tests for ANSI escape emission. These are the most load-bearing
  tests in Phase 1 - they pin down exactly what we send over the wire.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Rendering.AnsiWriter;

type
  [TestFixture]
  TAnsiWriterTests = class
  public
    [Test] procedure BuildDecorationCodes_Empty;
    [Test] procedure BuildDecorationCodes_Bold;
    [Test] procedure BuildDecorationCodes_BoldItalicUnderline;

    [Test] procedure BuildForegroundCode_Default_IsEmpty;
    [Test] procedure BuildForegroundCode_NoColors_IsEmpty;
    [Test] procedure BuildForegroundCode_LegacyRed_Is31;
    [Test] procedure BuildForegroundCode_StandardRed_Is91;
    [Test] procedure BuildForegroundCode_TrueColor_Is38_2_R_G_B;
    [Test] procedure BuildForegroundCode_8Bit_FromRGB_QuantizesToPalette;

    [Test] procedure BuildBackgroundCode_StandardBlue_Is104;
    [Test] procedure BuildBackgroundCode_TrueColor_Is48_2_R_G_B;

    [Test] procedure Writer_PlainText_NoEscapes;
    [Test] procedure Writer_StyledText_EmitsSGR_AndResets;
    [Test] procedure Writer_LineBreak_EmitsCRLF;
    [Test] procedure Writer_ControlCode_WrittenVerbatim;
    [Test] procedure Writer_NoColors_SkipsSGR;

    [Test] procedure BuildDecorationCodes_DimItalicStrikethrough;
    [Test] procedure BuildDecorationCodes_AllNine_InOrder;
    [Test] procedure BuildForegroundCode_LegacyBlack_Is30;
    [Test] procedure BuildForegroundCode_8Bit_NamedPalette_UsesIndex;
    [Test] procedure BuildBackgroundCode_Default_IsEmpty;
    [Test] procedure BuildBackgroundCode_Legacy_Is40Plus;

    [Test] procedure Writer_StyleTransition_EmitsNewSGR;
    [Test] procedure Writer_BackgroundOnly_EmitsBackgroundSGR;
    [Test] procedure Writer_LinkWithSupport_EmitsOSC8;
    [Test] procedure Writer_LinkWithoutSupport_DropsLink_KeepsStyle;
    [Test] procedure Writer_Whitespace_PassesThroughText;
  end;

implementation

uses
  System.SysUtils,
  Testing.AnsiConsole;

const
  ESC = #27;

function OptTrueColor : TRenderOptions;
begin
  result := TRenderOptions.Create(80, 24, TColorSystem.TrueColor);
end;

function OptStandard : TRenderOptions;
begin
  result := TRenderOptions.Create(80, 24, TColorSystem.Standard);
end;

function OptLegacy : TRenderOptions;
begin
  result := TRenderOptions.Create(80, 24, TColorSystem.Legacy);
end;

function Opt8Bit : TRenderOptions;
begin
  result := TRenderOptions.Create(80, 24, TColorSystem.EightBit);
end;

function OptNone : TRenderOptions;
begin
  result := TRenderOptions.Create(80, 24, TColorSystem.NoColors);
end;

procedure TAnsiWriterTests.BuildDecorationCodes_Empty;
begin
  Assert.AreEqual('', BuildDecorationCodes([]));
end;

procedure TAnsiWriterTests.BuildDecorationCodes_Bold;
begin
  Assert.AreEqual('1', BuildDecorationCodes([TAnsiDecoration.Bold]));
end;

procedure TAnsiWriterTests.BuildDecorationCodes_BoldItalicUnderline;
begin
  Assert.AreEqual('1;3;4', BuildDecorationCodes([TAnsiDecoration.Bold, TAnsiDecoration.Italic, TAnsiDecoration.Underline]));
end;

procedure TAnsiWriterTests.BuildForegroundCode_Default_IsEmpty;
begin
  Assert.AreEqual('', BuildForegroundCode(TAnsiColor.Default, OptTrueColor));
end;

procedure TAnsiWriterTests.BuildForegroundCode_NoColors_IsEmpty;
begin
  Assert.AreEqual('', BuildForegroundCode(TAnsiColor.Red, OptNone));
end;

procedure TAnsiWriterTests.BuildForegroundCode_LegacyRed_Is31;
begin
  // Red (palette 9) downgrades to index < 8 in legacy; nearest is 1 (maroon) -> 31
  Assert.AreEqual('31', BuildForegroundCode(TAnsiColor.Red, OptLegacy));
end;

procedure TAnsiWriterTests.BuildForegroundCode_StandardRed_Is91;
begin
  // Standard keeps bright palette -> index 9 = SGR 91
  Assert.AreEqual('91', BuildForegroundCode(TAnsiColor.Red, OptStandard));
end;

procedure TAnsiWriterTests.BuildForegroundCode_TrueColor_Is38_2_R_G_B;
begin
  Assert.AreEqual('38;2;255;136;0',
    BuildForegroundCode(TAnsiColor.FromRGB(255, 136, 0), OptTrueColor));
end;

procedure TAnsiWriterTests.BuildForegroundCode_8Bit_FromRGB_QuantizesToPalette;
var
  code : string;
begin
  // RGB with no palette index under TColorSystem.EightBit should produce "38;5;N"
  code := BuildForegroundCode(TAnsiColor.FromRGB(255, 136, 0), Opt8Bit);
  Assert.StartsWith('38;5;', code);
end;

procedure TAnsiWriterTests.BuildBackgroundCode_StandardBlue_Is104;
begin
  // Blue (palette 12) under standard -> 100 + (12 - 8) = 104
  Assert.AreEqual('104', BuildBackgroundCode(TAnsiColor.Blue, OptStandard));
end;

procedure TAnsiWriterTests.BuildBackgroundCode_TrueColor_Is48_2_R_G_B;
begin
  Assert.AreEqual('48;2;0;0;255',
    BuildBackgroundCode(TAnsiColor.FromRGB(0, 0, 255), OptTrueColor));
end;

function WriteAndCapture(const segs : TAnsiSegments; const opts : TRenderOptions) : string;
var
  sink    : ICapturedAnsiOutput;
  strSink : TStringAnsiOutput;
  writer  : IAnsiWriter;
begin
  strSink := TStringAnsiOutput.Create;
  sink := strSink;
  writer := TAnsiWriter.Create(sink);
  writer.WriteSegments(segs, opts);
  writer.Reset;
  result := sink.Text;
end;

procedure TAnsiWriterTests.Writer_PlainText_NoEscapes;
var
  segs   : TAnsiSegments;
  output : string;
begin
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.Text('hello');
  output := WriteAndCapture(segs, OptTrueColor);
  Assert.AreEqual('hello', output);
end;

procedure TAnsiWriterTests.Writer_StyledText_EmitsSGR_AndResets;
var
  segs   : TAnsiSegments;
  output : string;
  expected : string;
begin
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.Text('X',
    TAnsiStyle.Create(TAnsiColor.Red, TAnsiColor.Default, [TAnsiDecoration.Bold]));
  output := WriteAndCapture(segs, OptStandard);
  // SGR "1;91" (bold + bright-red FG), text, then reset on flush. No leading
  // reset because nothing has been styled yet on the wire.
  expected := ESC + '[1;91mX' + ESC + '[0m';
  Assert.AreEqual(expected, output);
end;

procedure TAnsiWriterTests.Writer_LineBreak_EmitsCRLF;
var
  segs   : TAnsiSegments;
  output : string;
begin
  SetLength(segs, 2);
  segs[0] := TAnsiSegment.Text('a');
  segs[1] := TAnsiSegment.LineBreak;
  output := WriteAndCapture(segs, OptTrueColor);
  Assert.AreEqual('a' + sLineBreak, output);
end;

procedure TAnsiWriterTests.Writer_ControlCode_WrittenVerbatim;
var
  segs   : TAnsiSegments;
  output : string;
begin
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.ControlCode(ESC + '[H');
  output := WriteAndCapture(segs, OptTrueColor);
  Assert.AreEqual(ESC + '[H', output);
end;

procedure TAnsiWriterTests.Writer_NoColors_SkipsSGR;
var
  segs   : TAnsiSegments;
  output : string;
begin
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.Text('plain',
    TAnsiStyle.Create(TAnsiColor.Red, TAnsiColor.Blue, [TAnsiDecoration.Bold]));
  output := WriteAndCapture(segs, OptNone);
  Assert.AreEqual('plain', output);
end;

procedure TAnsiWriterTests.BuildDecorationCodes_DimItalicStrikethrough;
begin
  // SGR codes: dim=2, italic=3, strikethrough=9. Output is in enum order.
  Assert.AreEqual('2;3;9',
    BuildDecorationCodes([TAnsiDecoration.Dim, TAnsiDecoration.Italic, TAnsiDecoration.Strikethrough]));
end;

procedure TAnsiWriterTests.BuildDecorationCodes_AllNine_InOrder;
begin
  Assert.AreEqual('1;2;3;4;5;6;7;8;9',
    BuildDecorationCodes([
      TAnsiDecoration.Bold, TAnsiDecoration.Dim, TAnsiDecoration.Italic, TAnsiDecoration.Underline, TAnsiDecoration.SlowBlink,
      TAnsiDecoration.RapidBlink, TAnsiDecoration.Invert, TAnsiDecoration.Conceal, TAnsiDecoration.Strikethrough
    ]));
end;

procedure TAnsiWriterTests.BuildForegroundCode_LegacyBlack_Is30;
begin
  // Black is palette index 0; legacy 8-color fg base = 30 + index = 30.
  Assert.AreEqual('30', BuildForegroundCode(TAnsiColor.Black, OptLegacy));
end;

procedure TAnsiWriterTests.BuildForegroundCode_8Bit_NamedPalette_UsesIndex;
begin
  // A named palette color in TColorSystem.EightBit emits its 256-color index directly,
  // so no quantization round-trip is needed.
  Assert.AreEqual('38;5;9', BuildForegroundCode(TAnsiColor.Red, Opt8Bit),
    'Red has palette index 9; TColorSystem.EightBit should emit "38;5;9"');
end;

procedure TAnsiWriterTests.BuildBackgroundCode_Default_IsEmpty;
begin
  Assert.AreEqual('', BuildBackgroundCode(TAnsiColor.Default, OptStandard),
    'Default background must produce no SGR code');
end;

procedure TAnsiWriterTests.BuildBackgroundCode_Legacy_Is40Plus;
begin
  // Legacy 8-color bg base = 40 + index. Maroon (index 1) -> 41.
  Assert.AreEqual('41', BuildBackgroundCode(TAnsiColor.Maroon, OptLegacy));
end;

procedure TAnsiWriterTests.Writer_StyleTransition_EmitsNewSGR;
var
  segs   : TAnsiSegments;
  output : string;
begin
  // Two text segments with different colors: writer should emit a new
  // SGR sequence between them, not just one resetting wrap.
  SetLength(segs, 2);
  segs[0] := TAnsiSegment.Text('a',
    TAnsiStyle.Create(TAnsiColor.Red, TAnsiColor.Default));
  segs[1] := TAnsiSegment.Text('b',
    TAnsiStyle.Create(TAnsiColor.Blue, TAnsiColor.Default));
  output := WriteAndCapture(segs, OptStandard);
  // Bright red FG = SGR 91, bright blue = 94.
  Assert.IsTrue(Pos('91', output) > 0, 'Red SGR (91) should appear');
  Assert.IsTrue(Pos('94', output) > 0, 'Blue SGR (94) should appear');
end;

procedure TAnsiWriterTests.Writer_BackgroundOnly_EmitsBackgroundSGR;
var
  segs   : TAnsiSegments;
  output : string;
begin
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.Text('X',
    TAnsiStyle.Create(TAnsiColor.Default, TAnsiColor.FromRGB(0, 0, 255)));
  output := WriteAndCapture(segs, OptTrueColor);
  Assert.IsTrue(Pos('48;2;0;0;255', output) > 0,
    'Background-only style should emit a true-color BG SGR');
  Assert.IsTrue(Pos('38;', output) = 0,
    'No foreground SGR should appear when FG is Default');
end;

procedure TAnsiWriterTests.Writer_LinkWithSupport_EmitsOSC8;
var
  segs   : TAnsiSegments;
  output : string;
  opts   : TRenderOptions;
begin
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.Text('click',
    TAnsiStyle.Plain.WithLink('https://example.com'));
  opts := TRenderOptions.Create(80, 24, TColorSystem.TrueColor).WithSupportsLinks(True);
  output := WriteAndCapture(segs, opts);
  // Format: OSC 8 ; id=N ; <url> ST. The id is required for Windows Terminal
  // to recognise the link, so we always emit it.
  Assert.IsTrue(Pos(ESC + ']8;id=', output) > 0,
    'OSC 8 introducer with id parameter should appear');
  Assert.IsTrue(Pos(';https://example.com', output) > 0,
    'OSC 8 should carry the link target');
  Assert.IsTrue(Pos('click', output) > 0,
    'Body text should still render');
end;

procedure TAnsiWriterTests.Writer_LinkWithoutSupport_DropsLink_KeepsStyle;
var
  segs   : TAnsiSegments;
  output : string;
  opts   : TRenderOptions;
begin
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.Text('hi',
    TAnsiStyle.Plain.WithForeground(TAnsiColor.Red).WithLink('https://example.com'));
  opts := TRenderOptions.Create(80, 24, TColorSystem.Standard).WithSupportsLinks(False);
  output := WriteAndCapture(segs, opts);
  Assert.IsTrue(Pos('https://example.com', output) = 0,
    'When SupportsLinks is False the URL must not appear in output');
  Assert.IsTrue(Pos('91', output) > 0,
    'Surrounding style (red FG = 91) should still be applied');
end;

procedure TAnsiWriterTests.Writer_Whitespace_PassesThroughText;
var
  segs   : TAnsiSegments;
  output : string;
begin
  // Whitespace segments carry their textual content even though they're
  // marked TAnsiSegmentFlag.Whitespace. The writer should not strip them.
  SetLength(segs, 3);
  segs[0] := TAnsiSegment.Text('a');
  segs[1] := TAnsiSegment.Whitespace('   ');
  segs[2] := TAnsiSegment.Text('b');
  output := WriteAndCapture(segs, OptNone);
  Assert.AreEqual('a   b', output);
end;

initialization
  TDUnitX.RegisterTestFixture(TAnsiWriterTests);

end.
