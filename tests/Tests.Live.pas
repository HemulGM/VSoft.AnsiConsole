unit Tests.Live;

{
  Live-display fixtures. The refresh interval is pushed high (10 seconds) so
  the ticker thread never fires during a test; the test synchronously drives
  the action and inspects the captured output at the end.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Widgets.Text,
  VSoft.AnsiConsole.Widgets.Rows,
  VSoft.AnsiConsole.Live.Display,
  VSoft.AnsiConsole.Live.Spinners,
  VSoft.AnsiConsole.Live.Status,
  VSoft.AnsiConsole.Live.Progress,
  VSoft.AnsiConsole.Live.Exclusivity;

type
  [TestFixture]
  TLiveTests = class
  public
    [Test] procedure Spinner_DotsHasTenFrames;
    [Test] procedure Spinner_LegacyFallbackForAll;
    [Test] procedure Spinner_FrameWrapsModCount;
    [Test] procedure Spinner_ClockHasTwelveFrames;
    [Test] procedure Spinner_NonUnicodeSpinner_KeepsOwnFrames;
    [Test] procedure Spinner_EarthHasThreeFrames;

    [Test] procedure LiveDisplay_Update_RendersNewContent;
    [Test] procedure LiveDisplay_AutoClearTrue_OutputEndsEmpty;

    [Test] procedure LiveDisplay_OverflowVisible_EmitsAllLines;
    [Test] procedure LiveDisplay_OverflowCropTop_DropsTopLines;
    [Test] procedure LiveDisplay_OverflowCropBottom_DropsBottomLines;
    [Test] procedure LiveDisplay_OverflowEllipsisTop_AddsEllipsis;
    [Test] procedure LiveDisplay_OverflowEllipsisBottom_AddsEllipsis;

    [Test] procedure Exclusivity_NestedStart_RaisesBusy;

    [Test] procedure Progress_Task_PercentageAndFinished;
    [Test] procedure Progress_RendersAllTasks;

    [Test] procedure Status_AutoRefreshFalse_NoTickerFires;
    [Test] procedure Progress_Task_IdsAreSequential;
    [Test] procedure Progress_Task_StartTime_SetOnIncrement;
    [Test] procedure Progress_Task_StopTime_SetWhenFinished;
    [Test] procedure Progress_RenderHook_WrapsBoard;
  end;

implementation

uses
  System.SysUtils,
  Testing.AnsiConsole;

function BuildPlain(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.NoColors, width, False, result, sink);
end;

// -- Spinner ----------------------------------------------------------------

procedure TLiveTests.Spinner_DotsHasTenFrames;
var
  s : ISpinner;
begin
  s := Spinner(TSpinnerKind.Dots, True);
  Assert.AreEqual(10, s.Frames);
end;

procedure TLiveTests.Spinner_LegacyFallbackForAll;
var
  s : ISpinner;
begin
  // Non-unicode mode -> all spinners use the line-style fallback.
  s := Spinner(TSpinnerKind.Dots, False);
  Assert.AreEqual(4, s.Frames);
  Assert.AreEqual('-', s.Frame(0));
  Assert.AreEqual('\', s.Frame(1));
  Assert.AreEqual('|', s.Frame(2));
  Assert.AreEqual('/', s.Frame(3));
end;

procedure TLiveTests.Spinner_FrameWrapsModCount;
var
  s : ISpinner;
begin
  s := Spinner(TSpinnerKind.Line, True);
  Assert.AreEqual(s.Frame(0), s.Frame(4));   // 4 mod 4 = 0
  Assert.AreEqual(s.Frame(1), s.Frame(13));  // 13 mod 4 = 1
end;

procedure TLiveTests.Spinner_ClockHasTwelveFrames;
var
  s : ISpinner;
begin
  s := Spinner(TSpinnerKind.Clock, True);
  Assert.AreEqual(12, s.Frames, 'Clock spinner has twelve positions');
end;

{ Non-unicode spinners (Line, Line2, Pipe, ...) already draw with ASCII-safe
  glyphs; they should keep their own frames regardless of the unicode flag,
  not get forced through the Line fallback. }
procedure TLiveTests.Spinner_NonUnicodeSpinner_KeepsOwnFrames;
var
  s : ISpinner;
begin
  s := Spinner(TSpinnerKind.Pipe, False);
  Assert.AreEqual(8, s.Frames, 'Pipe spinner has eight frames');
end;

procedure TLiveTests.Spinner_EarthHasThreeFrames;
var
  s : ISpinner;
begin
  s := Spinner(TSpinnerKind.Earth, True);
  Assert.AreEqual(3, s.Frames, 'Earth spinner has three rotation positions');
end;

// -- LiveDisplay ------------------------------------------------------------

procedure TLiveTests.LiveDisplay_Update_RendersNewContent;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cfg     : ILiveDisplayConfig;
begin
  console := BuildPlain(40, sink);
  cfg := LiveDisplay(console, Text('first')).WithAutoClear(False);
  cfg.Start(
    procedure(const ctx : ILiveDisplay)
    begin
      ctx.Update(Text('second'));
    end);
  // The final rendered state should contain 'second'. 'first' may or may not
  // be present depending on terminal clearing sequences, but 'second' must be.
  Assert.Contains(sink.Text, 'second');
end;

procedure TLiveTests.LiveDisplay_AutoClearTrue_OutputEndsEmpty;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cfg     : ILiveDisplayConfig;
  last    : Integer;
  tail    : string;
begin
  console := BuildPlain(40, sink);
  cfg := LiveDisplay(console, Text('hello')).WithAutoClear(True);
  cfg.Start(
    procedure(const ctx : ILiveDisplay)
    begin
      // no updates, just let it draw and clear
    end);
  // The tail of the captured output should be a clear sequence (ESC[2K) after
  // any content. A loose check: 'hello' is followed by clear escapes.
  last := Pos('hello', sink.Text);
  Assert.IsTrue(last > 0, 'initial content should have been emitted');
  tail := Copy(sink.Text, last + Length('hello'), MaxInt);
  Assert.IsTrue(Pos(#27 + '[2K', tail) > 0, 'auto-clear should emit erase-line sequences after the content');
end;

{ Helper - builds a Rows widget with `count` distinct lines named line01,
  line02, ... so a test can pinpoint which lines survived overflow trimming.
  Delphi is case-insensitive, so a local var named `rows` would shadow the
  free function `Rows()` and resolve to the (still-nil) local instead. The
  local is named `stack` to avoid that trap. }
function BuildNumberedRows(count : Integer) : IRenderable;
var
  stack : IRows;
  i     : Integer;
begin
  stack := Rows;
  for i := 1 to count do
    stack.Add(Text(Format('line%.2d', [i])));
  result := stack;
end;

procedure TLiveTests.LiveDisplay_OverflowVisible_EmitsAllLines;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cfg     : ILiveDisplayConfig;
begin
  // Default profile height is 24. Build 30 lines and confirm every one is
  // emitted under TLiveOverflow.Visible (terminal-scroll, the legacy default).
  console := BuildPlain(40, sink);
  cfg := LiveDisplay(console, BuildNumberedRows(30)).WithAutoClear(False);
  cfg.Start(
    procedure(const ctx : ILiveDisplay)
    begin
      // no updates - just draw the initial content
    end);
  Assert.Contains(sink.Text, 'line01', 'first line should be visible');
  Assert.Contains(sink.Text, 'line24', 'middle line should be visible');
  Assert.Contains(sink.Text, 'line30', 'last line should be visible');
end;

procedure TLiveTests.LiveDisplay_OverflowCropTop_DropsTopLines;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cfg     : ILiveDisplayConfig;
begin
  // Profile height is 24, content is 30 -> 6 lines must be dropped from
  // the top, leaving line07..line30 visible.
  console := BuildPlain(40, sink);
  cfg := LiveDisplay(console, BuildNumberedRows(30))
           .WithAutoClear(False)
           .WithOverflow(TLiveOverflow.Crop)
           .WithCropping(TLiveCropping.Top);
  cfg.Start(
    procedure(const ctx : ILiveDisplay)
    begin
    end);
  Assert.IsFalse(Pos('line01', sink.Text) > 0, 'top-cropped line01 should be gone');
  Assert.IsFalse(Pos('line06', sink.Text) > 0, 'top-cropped line06 should be gone');
  Assert.Contains(sink.Text, 'line07', 'first surviving line is line07');
  Assert.Contains(sink.Text, 'line30', 'bottom should be intact');
end;

procedure TLiveTests.LiveDisplay_OverflowCropBottom_DropsBottomLines;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cfg     : ILiveDisplayConfig;
begin
  console := BuildPlain(40, sink);
  cfg := LiveDisplay(console, BuildNumberedRows(30))
           .WithAutoClear(False)
           .WithOverflow(TLiveOverflow.Crop)
           .WithCropping(TLiveCropping.Bottom);
  cfg.Start(
    procedure(const ctx : ILiveDisplay)
    begin
    end);
  Assert.Contains(sink.Text, 'line01', 'top should be intact');
  Assert.Contains(sink.Text, 'line24', 'last surviving line is line24');
  Assert.IsFalse(Pos('line25', sink.Text) > 0, 'bottom-cropped line25 should be gone');
  Assert.IsFalse(Pos('line30', sink.Text) > 0, 'bottom-cropped line30 should be gone');
end;

procedure TLiveTests.LiveDisplay_OverflowEllipsisTop_AddsEllipsis;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cfg     : ILiveDisplayConfig;
begin
  // Unicode mode -> '...' fallback because BuildPlain passes False for unicode.
  console := BuildPlain(40, sink);
  cfg := LiveDisplay(console, BuildNumberedRows(30))
           .WithAutoClear(False)
           .WithOverflow(TLiveOverflow.Ellipsis)
           .WithCropping(TLiveCropping.Top);
  cfg.Start(
    procedure(const ctx : ILiveDisplay)
    begin
    end);
  // Reserved one row for the ellipsis line, so 7 source lines drop from the
  // top -> first surviving content line is line08.
  Assert.IsFalse(Pos('line01', sink.Text) > 0, 'cropped line01 should be gone');
  Assert.IsFalse(Pos('line07', sink.Text) > 0, 'cropped line07 should be gone');
  Assert.Contains(sink.Text, 'line08', 'first surviving content line is line08');
  Assert.Contains(sink.Text, 'line30', 'bottom should be intact');
  Assert.Contains(sink.Text, '...', 'ASCII ellipsis marker should appear');
end;

procedure TLiveTests.LiveDisplay_OverflowEllipsisBottom_AddsEllipsis;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cfg     : ILiveDisplayConfig;
begin
  console := BuildPlain(40, sink);
  cfg := LiveDisplay(console, BuildNumberedRows(30))
           .WithAutoClear(False)
           .WithOverflow(TLiveOverflow.Ellipsis)
           .WithCropping(TLiveCropping.Bottom);
  cfg.Start(
    procedure(const ctx : ILiveDisplay)
    begin
    end);
  Assert.Contains(sink.Text, 'line01', 'top should be intact');
  Assert.Contains(sink.Text, 'line23', 'last surviving content line is line23');
  Assert.IsFalse(Pos('line24', sink.Text) > 0, 'cropped line24 should be gone');
  Assert.IsFalse(Pos('line30', sink.Text) > 0, 'cropped line30 should be gone');
  Assert.Contains(sink.Text, '...', 'ASCII ellipsis marker should appear');
end;

// -- Exclusivity ------------------------------------------------------------

procedure TLiveTests.Exclusivity_NestedStart_RaisesBusy;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  outer   : ILiveDisplayConfig;
  caught  : Boolean;
begin
  console := BuildPlain(40, sink);
  caught := False;
  outer := LiveDisplay(console, Text('outer')).WithAutoClear(True);
  outer.Start(
    procedure(const ctx : ILiveDisplay)
    var
      inner : ILiveDisplayConfig;
    begin
      inner := LiveDisplay(console, Text('inner')).WithAutoClear(True);
      try
        inner.Start(
          procedure(const innerCtx : ILiveDisplay)
          begin
            // should never get here
          end);
      except
        on E: ELiveDisplayBusy do
          caught := True;
      end;
    end);
  Assert.IsTrue(caught, 'Nested Start should raise ELiveDisplayBusy');
end;

// -- Progress ---------------------------------------------------------------

procedure TLiveTests.Progress_Task_PercentageAndFinished;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cfg     : IProgressConfig;
begin
  console := BuildPlain(60, sink);
  cfg := Progress(console).WithRefreshMs(10000);  // ticker won't fire
  cfg.Start(
    procedure(const ctx : IProgress)
    var
      t : IProgressTask;
    begin
      t := ctx.AddTask('work', 200);
      t.SetValue(100);
      Assert.AreEqual(50, t.Percentage, 0.001);
      Assert.IsFalse(t.IsFinished);
      t.SetValue(200);
      Assert.IsTrue(t.IsFinished);
      Assert.AreEqual(100, t.Percentage, 0.001);
    end);
end;

procedure TLiveTests.Progress_RendersAllTasks;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cfg     : IProgressConfig;
begin
  console := BuildPlain(80, sink);
  cfg := Progress(console).WithRefreshMs(10000);
  cfg.Start(
    procedure(const ctx : IProgress)
    var
      a, b : IProgressTask;
    begin
      a := ctx.AddTask('alpha', 100);
      b := ctx.AddTask('bravo', 100);
      a.SetValue(42);
      b.SetValue(100);
    end);
  Assert.Contains(sink.Text, 'alpha');
  Assert.Contains(sink.Text, 'bravo');
  Assert.Contains(sink.Text, '100%');
end;

// -- Status / Progress polish (Landing 21) ----------------------------------

procedure TLiveTests.Status_AutoRefreshFalse_NoTickerFires;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  before, after : Integer;
begin
  // With AutoRefresh=False the spinner ticker thread never starts.
  // We verify by sleeping a couple of spinner intervals and confirming
  // the captured output didn't grow further.
  console := BuildPlain(40, sink);
  VSoft.AnsiConsole.Live.Status.Status(console).WithAutoRefresh(False).Start('idle',
    procedure(const ctx : IStatus)
    begin
      before := Length(sink.Text);
      Sleep(150);   // longer than any spinner frame interval
      after := Length(sink.Text);
    end);
  Assert.AreEqual(before, after,
    'No frames should have been written by a ticker that never started');
end;

procedure TLiveTests.Progress_Task_IdsAreSequential;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cfg     : IProgressConfig;
  ids     : TArray<Integer>;
begin
  console := BuildPlain(80, sink);
  cfg := Progress(console).WithRefreshMs(10000);
  SetLength(ids, 3);
  cfg.Start(
    procedure(const ctx : IProgress)
    var
      a, b, c : IProgressTask;
    begin
      a := ctx.AddTask('a');
      b := ctx.AddTask('b');
      c := ctx.AddTask('c');
      ids[0] := a.Id;
      ids[1] := b.Id;
      ids[2] := c.Id;
    end);
  Assert.AreEqual(0, ids[0]);
  Assert.AreEqual(1, ids[1]);
  Assert.AreEqual(2, ids[2]);
end;

procedure TLiveTests.Progress_Task_StartTime_SetOnIncrement;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cfg     : IProgressConfig;
  startTime : TDateTime;
begin
  console := BuildPlain(80, sink);
  cfg := Progress(console).WithRefreshMs(10000);
  startTime := 0;
  cfg.Start(
    procedure(const ctx : IProgress)
    var
      t : IProgressTask;
    begin
      // Task created with autoStart=True (default) - StartTime should be
      // set immediately.
      t := ctx.AddTask('work');
      startTime := t.StartTime;
    end);
  Assert.IsTrue(startTime > 0,
    'StartTime should be non-zero once the task auto-started');
end;

procedure TLiveTests.Progress_Task_StopTime_SetWhenFinished;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cfg     : IProgressConfig;
  stopTime : TDateTime;
begin
  console := BuildPlain(80, sink);
  cfg := Progress(console).WithRefreshMs(10000);
  stopTime := 0;
  cfg.Start(
    procedure(const ctx : IProgress)
    var
      t : IProgressTask;
    begin
      t := ctx.AddTask('work', 100);
      t.SetValue(100);   // reaches MaxValue -> StopTime captured
      stopTime := t.StopTime;
    end);
  Assert.IsTrue(stopTime > 0,
    'StopTime should be non-zero once the task reaches MaxValue');
end;

procedure TLiveTests.Progress_RenderHook_WrapsBoard;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cfg     : IProgressConfig;
  hookCalls : Integer;
begin
  console := BuildPlain(80, sink);
  hookCalls := 0;
  cfg := Progress(console)
           .WithRefreshMs(10000)
           .WithRenderHook(
             function(const board : IRenderable;
                       const tasks : TArray<IProgressTask>) : IRenderable
             begin
               Inc(hookCalls);
               result := board;   // pass-through; just count invocations
             end);
  cfg.Start(
    procedure(const ctx : IProgress)
    var
      t : IProgressTask;
    begin
      t := ctx.AddTask('work', 100);
      t.SetValue(50);
    end);
  Assert.IsTrue(hookCalls > 0,
    'Render hook should have been invoked at least once');
end;

initialization
  TDUnitX.RegisterTestFixture(TLiveTests);

end.
