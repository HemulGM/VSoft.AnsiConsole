unit Tests.Cursor;

{
  IAnsiConsoleCursor tests - exercises the CSI / DECTCEM sequences emitted
  for show/hide/setposition/move and the 1-based clamping in SetPosition.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Cursor;

type
  [TestFixture]
  TCursorTests = class
  public
    [Test] procedure Hide_EmitsDectcemHide;
    [Test] procedure ShowTrue_EmitsDectcemShow;
    [Test] procedure ShowFalse_SameAsHide;
    [Test] procedure SetPosition_OneBased;
    [Test] procedure SetPosition_ClampsZeroAndNegativeToOne;
    [Test] procedure MoveUp_EmitsCursorUp;
    [Test] procedure MoveDown_EmitsCursorDown;
    [Test] procedure MoveLeft_EmitsCursorBack;
    [Test] procedure MoveRight_EmitsCursorForward;
    [Test] procedure Move_ZeroSteps_NoOp;
    [Test] procedure Move_DefaultStepsIsOne;
  end;

implementation

uses
  Testing.AnsiConsole;

const
  ESC = #27;

function BuildAnsi(out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  // Need an ANSI-on console so control codes pass through to the sink.
  BuildCapturedConsole(TColorSystem.TrueColor, 80, True, result, sink);
end;

procedure TCursorTests.Hide_EmitsDectcemHide;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildAnsi(sink);
  Cursor(console).Hide;
  Assert.AreEqual(ESC + '[?25l', sink.Text);
end;

procedure TCursorTests.ShowTrue_EmitsDectcemShow;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildAnsi(sink);
  Cursor(console).Show(True);
  Assert.AreEqual(ESC + '[?25h', sink.Text);
end;

procedure TCursorTests.ShowFalse_SameAsHide;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildAnsi(sink);
  Cursor(console).Show(False);
  Assert.AreEqual(ESC + '[?25l', sink.Text);
end;

procedure TCursorTests.SetPosition_OneBased;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildAnsi(sink);
  // CUP is "ESC[<line>;<column>H" - line first, column second.
  Cursor(console).SetPosition(7, 3);
  Assert.AreEqual(ESC + '[3;7H', sink.Text);
end;

procedure TCursorTests.SetPosition_ClampsZeroAndNegativeToOne;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildAnsi(sink);
  Cursor(console).SetPosition(0, -5);
  Assert.AreEqual(ESC + '[1;1H', sink.Text);
end;

procedure TCursorTests.MoveUp_EmitsCursorUp;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildAnsi(sink);
  Cursor(console).MoveUp(4);
  Assert.AreEqual(ESC + '[4A', sink.Text);
end;

procedure TCursorTests.MoveDown_EmitsCursorDown;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildAnsi(sink);
  Cursor(console).MoveDown(2);
  Assert.AreEqual(ESC + '[2B', sink.Text);
end;

procedure TCursorTests.MoveLeft_EmitsCursorBack;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildAnsi(sink);
  Cursor(console).MoveLeft(3);
  Assert.AreEqual(ESC + '[3D', sink.Text);
end;

procedure TCursorTests.MoveRight_EmitsCursorForward;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildAnsi(sink);
  Cursor(console).MoveRight(5);
  Assert.AreEqual(ESC + '[5C', sink.Text);
end;

procedure TCursorTests.Move_ZeroSteps_NoOp;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildAnsi(sink);
  Cursor(console).MoveUp(0);
  Cursor(console).MoveDown(-1);
  Assert.AreEqual('', sink.Text,
    'Zero or negative step counts must emit no escape');
end;

procedure TCursorTests.Move_DefaultStepsIsOne;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildAnsi(sink);
  Cursor(console).MoveUp;   // default steps=1
  Assert.AreEqual(ESC + '[1A', sink.Text);
end;

initialization
  TDUnitX.RegisterTestFixture(TCursorTests);

end.
