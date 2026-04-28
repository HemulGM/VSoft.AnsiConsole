unit Tests.Facade;

{
  Fixtures for the AnsiConsole static facade. Tests swap in a captured
  console via AnsiConsole.SetConsole, exercise the static method, then
  restore the prior console via teardown.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole;

type
  [TestFixture]
  TFacadeTests = class
  strict private
    FPrevious   : IAnsiConsole;
    FPrevFG     : TAnsiColor;
    FPrevBG     : TAnsiColor;
    FPrevDecor  : TAnsiDecorations;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Markup_StylesText_RedSGR;
    [Test] procedure Markup_PlainText_NoSGR;
    [Test] procedure MarkupLine_AppendsNewline;
    [Test] procedure Markup_FormatArgs_SplicesValues;
    [Test] procedure MarkupLine_FormatArgs_SplicesAndAppendsNewline;

    [Test] procedure Write_String_IsLiteral_NoMarkupParsing;
    [Test] procedure WriteLine_String_IsLiteral_AppendsNewline;
    [Test] procedure Write_LiteralBracketsSurviveVerbatim;

    [Test] procedure Cursor_Hide_EmitsDECTCEMOff;
    [Test] procedure Cursor_Show_EmitsDECTCEMOn;
    [Test] procedure Cursor_SetPosition_EmitsCUP_RowFirst;
    [Test] procedure Cursor_MoveUp_EmitsCSI_A;
    [Test] procedure Cursor_MoveDown_EmitsCSI_B;
    [Test] procedure Cursor_MoveLeft_EmitsCSI_D;
    [Test] procedure Cursor_MoveRight_EmitsCSI_C;

    [Test] procedure Profile_ReturnsCurrentConsoleProfile;
    [Test] procedure WriteException_EmitsExceptionType;

    [Test] procedure Foreground_Set_AffectsSubsequentWrite;
    [Test] procedure Reset_ClearsCurrentStyle;
    [Test] procedure Decoration_Set_StoredAndRetrieved;

    [Test] procedure Recording_StartExportText_RoundTrip;
    [Test] procedure Recording_StopRecording_ResumesPreviousConsole;
    [Test] procedure Recording_ExportWithoutStart_Raises;

    [Test] procedure Write_Integer_EmitsDigits;
    [Test] procedure Write_Int64_EmitsDigits;
    [Test] procedure Write_Double_UsesDefaultFormat;
    [Test] procedure Write_Boolean_EmitsTrueOrFalse;
    [Test] procedure Write_Char_EmitsSingleCharacter;
    [Test] procedure Write_FormatArgs_Splices;
    [Test] procedure WriteLine_Integer_EmitsDigitsAndNewline;
    [Test] procedure WriteLine_FormatArgs_AppendsNewline;

    [Test] procedure Live_Alias_ReturnsLiveDisplayConfig;
    [Test] procedure Status_NoArg_ReturnsStatusConfig;

    [Test] procedure SetWindowTitle_EmitsOSC0Sequence;
    [Test] procedure WriteAnsi_EmitsRawSequence;
    [Test] procedure RandomSpinner_ReturnsValidSpinner;
  end;

implementation

uses
  System.SysUtils,
  Testing.AnsiConsole;

procedure TFacadeTests.Setup;
begin
  FPrevious  := AnsiConsole.Console;
  FPrevFG    := AnsiConsole.Foreground;
  FPrevBG    := AnsiConsole.Background;
  FPrevDecor := AnsiConsole.Decoration;
end;

procedure TFacadeTests.TearDown;
begin
  AnsiConsole.StopRecording;             // safe no-op if not recording
  AnsiConsole.SetConsole(FPrevious);
  AnsiConsole.Foreground := FPrevFG;
  AnsiConsole.Background := FPrevBG;
  AnsiConsole.Decoration := FPrevDecor;
  FPrevious := nil;
end;

function CaptureNoColors(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.NoColors, width, False, result, sink);
end;

function CaptureWithColor(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.EightBit, width, False, result, sink);
end;

procedure TFacadeTests.Markup_StylesText_RedSGR;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // 8-bit color so we get an SGR code we can grep for. Red foreground in
  // the 256-palette path emits ESC[38;5;9m... or ESC[31m on the legacy path.
  console := CaptureWithColor(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Markup('[red]hi[/]');
  Assert.IsTrue(Pos('hi', sink.Text) > 0, 'Body text "hi" should appear');
  Assert.IsTrue(Pos(#27 + '[', sink.Text) > 0, 'A CSI/SGR sequence should be emitted for [red]');
  // The literal markup tags must not appear.
  Assert.IsTrue(Pos('[red]', sink.Text) = 0, 'Markup tag should be consumed by parser');
  Assert.IsTrue(Pos('[/]',   sink.Text) = 0, 'Closing markup tag should be consumed');
end;

procedure TFacadeTests.Markup_PlainText_NoSGR;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Markup('plain');
  Assert.AreEqual('plain', sink.Text);
end;

procedure TFacadeTests.MarkupLine_AppendsNewline;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.MarkupLine('hello');
  Assert.AreEqual('hello' + sLineBreak, sink.Text);
end;

procedure TFacadeTests.Markup_FormatArgs_SplicesValues;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Markup('value=%d, name=%s', [42, 'foo']);
  Assert.AreEqual('value=42, name=foo', sink.Text);
end;

procedure TFacadeTests.MarkupLine_FormatArgs_SplicesAndAppendsNewline;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.MarkupLine('item %d of %d', [1, 3]);
  Assert.AreEqual('item 1 of 3' + sLineBreak, sink.Text);
end;

procedure TFacadeTests.Write_String_IsLiteral_NoMarkupParsing;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // Literal: brackets must appear verbatim, no markup parsing.
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Write('[red]hi[/]');
  Assert.AreEqual('[red]hi[/]', sink.Text);
end;

procedure TFacadeTests.WriteLine_String_IsLiteral_AppendsNewline;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.WriteLine('[red]hi[/]');
  Assert.AreEqual('[red]hi[/]' + sLineBreak, sink.Text);
end;

procedure TFacadeTests.Write_LiteralBracketsSurviveVerbatim;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Write('a [b] c');
  Assert.AreEqual('a [b] c', sink.Text);
end;

// ---- Cursor / Profile / WriteException -----------------------------------

procedure TFacadeTests.Cursor_Hide_EmitsDECTCEMOff;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Cursor.Hide;
  Assert.AreEqual(#27 + '[?25l', sink.Text);
end;

procedure TFacadeTests.Cursor_Show_EmitsDECTCEMOn;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Cursor.Show(True);
  Assert.AreEqual(#27 + '[?25h', sink.Text);
end;

procedure TFacadeTests.Cursor_SetPosition_EmitsCUP_RowFirst;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // CUP is row;column 1-based: ESC[<line>;<col>H. SetPosition(5, 10)
  // moves to column 5, line 10.
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Cursor.SetPosition(5, 10);
  Assert.AreEqual(#27 + '[10;5H', sink.Text);
end;

procedure TFacadeTests.Cursor_MoveUp_EmitsCSI_A;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Cursor.MoveUp(3);
  Assert.AreEqual(#27 + '[3A', sink.Text);
end;

procedure TFacadeTests.Cursor_MoveDown_EmitsCSI_B;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Cursor.MoveDown(7);
  Assert.AreEqual(#27 + '[7B', sink.Text);
end;

procedure TFacadeTests.Cursor_MoveLeft_EmitsCSI_D;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Cursor.MoveLeft(2);
  Assert.AreEqual(#27 + '[2D', sink.Text);
end;

procedure TFacadeTests.Cursor_MoveRight_EmitsCSI_C;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Cursor.MoveRight(4);
  Assert.AreEqual(#27 + '[4C', sink.Text);
end;

procedure TFacadeTests.Profile_ReturnsCurrentConsoleProfile;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(72, sink);
  AnsiConsole.SetConsole(console);
  // The profile width should match what we built the captured console with.
  Assert.AreEqual(72, AnsiConsole.Profile.Width);
end;

procedure TFacadeTests.WriteException_EmitsExceptionType;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  e       : Exception;
begin
  console := CaptureNoColors(80, sink);
  AnsiConsole.SetConsole(console);
  e := EArgumentException.Create('Sample failure');
  try
    AnsiConsole.WriteException(e);
  finally
    e.Free;
  end;
  Assert.IsTrue(Pos('EArgumentException', sink.Text) > 0,
    'Output should contain the exception class name');
  Assert.IsTrue(Pos('Sample failure', sink.Text) > 0,
    'Output should contain the exception message');
end;

// ---- State setters -------------------------------------------------------

procedure TFacadeTests.Foreground_Set_AffectsSubsequentWrite;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // 8-bit colour so red foreground emits an SGR sequence (38;5;9 or 31).
  console := CaptureWithColor(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Foreground := TAnsiColor.Red;
  AnsiConsole.Write('hi');
  Assert.IsTrue(Pos('hi', sink.Text) > 0, 'Body text should appear');
  Assert.IsTrue(Pos(#27 + '[', sink.Text) > 0,
    'An SGR sequence should be emitted because Foreground is set to Red');
end;

procedure TFacadeTests.Reset_ClearsCurrentStyle;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureWithColor(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Foreground := TAnsiColor.Red;
  AnsiConsole.Reset;
  Assert.IsTrue(AnsiConsole.Foreground.IsDefault,
    'Reset should clear the foreground colour to Default');
end;

procedure TFacadeTests.Decoration_Set_StoredAndRetrieved;
begin
  AnsiConsole.Decoration := [TAnsiDecoration.Bold, TAnsiDecoration.Underline];
  Assert.IsTrue(TAnsiDecoration.Bold in AnsiConsole.Decoration);
  Assert.IsTrue(TAnsiDecoration.Underline in AnsiConsole.Decoration);
  AnsiConsole.ResetDecoration;
  Assert.IsTrue(AnsiConsole.Decoration = [],
    'ResetDecoration should clear the decoration set');
end;

// ---- Recording -----------------------------------------------------------

procedure TFacadeTests.Recording_StartExportText_RoundTrip;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  exported : string;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.StartRecording;
  AnsiConsole.Write('captured');
  exported := AnsiConsole.ExportText;
  Assert.IsTrue(Pos('captured', exported) > 0,
    'ExportText should include the recorded write');
end;

procedure TFacadeTests.Recording_StopRecording_ResumesPreviousConsole;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.StartRecording;
  AnsiConsole.StopRecording;
  // After stopping, the captured console should be back as the active one.
  Assert.AreSame(console, AnsiConsole.Console);
end;

procedure TFacadeTests.Recording_ExportWithoutStart_Raises;
begin
  AnsiConsole.StopRecording;   // ensure no recording is active
  Assert.WillRaise(
    procedure
    begin
      AnsiConsole.ExportText;
    end,
    Exception,
    'ExportText with no active recording should raise');
end;

// ---- Numeric / format Write & WriteLine ----------------------------------

procedure TFacadeTests.Write_Integer_EmitsDigits;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Write(42);
  Assert.AreEqual('42', sink.Text);
end;

procedure TFacadeTests.Write_Int64_EmitsDigits;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  big     : Int64;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  big := 9223372036854775000;
  AnsiConsole.Write(big);
  Assert.AreEqual('9223372036854775000', sink.Text);
end;

procedure TFacadeTests.Write_Double_UsesDefaultFormat;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  d       : Double;
begin
  // FloatToStr honours the current locale's decimal separator. We assert on
  // the integer-style fraction-free case to avoid locale dependency.
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  d := 123;
  AnsiConsole.Write(d);
  Assert.AreEqual('123', sink.Text);
end;

procedure TFacadeTests.Write_Boolean_EmitsTrueOrFalse;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Write(True);
  Assert.AreEqual('True', sink.Text);
end;

procedure TFacadeTests.Write_Char_EmitsSingleCharacter;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  c       : Char;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  c := 'q';
  AnsiConsole.Write(c);   // Char overload (typed local picks Write(Char))
  Assert.AreEqual('q', sink.Text);
end;

procedure TFacadeTests.Write_FormatArgs_Splices;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.Write('%d items, %s flag', [3, 'Y']);
  Assert.AreEqual('3 items, Y flag', sink.Text);
end;

procedure TFacadeTests.WriteLine_Integer_EmitsDigitsAndNewline;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.WriteLine(99);
  Assert.AreEqual('99' + sLineBreak, sink.Text);
end;

procedure TFacadeTests.WriteLine_FormatArgs_AppendsNewline;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.WriteLine('count=%d', [7]);
  Assert.AreEqual('count=7' + sLineBreak, sink.Text);
end;

// ---- Naming polish (Live / Status no-arg) --------------------------------

procedure TFacadeTests.Live_Alias_ReturnsLiveDisplayConfig;
var
  cfg : ILiveDisplayConfig;
begin
  cfg := AnsiConsole.Live(Widgets.Text('hello'));
  Assert.IsNotNull(cfg, 'Live(initial) should return a non-nil ILiveDisplayConfig');
end;

procedure TFacadeTests.Status_NoArg_ReturnsStatusConfig;
var
  cfg : IStatusConfig;
begin
  cfg := AnsiConsole.Status;
  Assert.IsNotNull(cfg, 'Status (no-arg) should return a non-nil IStatusConfig');
end;

// ---- Landing 22 facade additions ----------------------------------------

procedure TFacadeTests.SetWindowTitle_EmitsOSC0Sequence;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // OSC 0 - 'ESC ] 0 ; <title> BEL'.
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.SetWindowTitle('My App');
  Assert.AreEqual(#27']0;My App'#7, sink.Text);
end;

procedure TFacadeTests.WriteAnsi_EmitsRawSequence;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := CaptureNoColors(40, sink);
  AnsiConsole.SetConsole(console);
  AnsiConsole.WriteAnsi(#27 + '[2K');
  Assert.AreEqual(#27 + '[2K', sink.Text);
end;

procedure TFacadeTests.RandomSpinner_ReturnsValidSpinner;
var
  s : ISpinner;
begin
  s := AnsiConsole.RandomSpinner;
  Assert.IsNotNull(s, 'RandomSpinner should return a non-nil ISpinner');
  Assert.IsTrue(s.Frames > 0, 'Picked spinner should have at least one frame');
  Assert.IsTrue(s.IntervalMs > 0, 'Picked spinner should have a positive interval');
end;

initialization
  TDUnitX.RegisterTestFixture(TFacadeTests);

end.
