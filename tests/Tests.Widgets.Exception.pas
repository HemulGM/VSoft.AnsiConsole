unit Tests.Widgets.Exception;

{
  ExceptionWidget tests - basic header rendering, stack-trace splitting,
  rich tokenization formats (ShortenPaths/Methods/Types, NoStackTrace,
  ShowLinks), and per-token style overrides.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Capabilities,
  VSoft.AnsiConsole.Profile,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Widgets.Exception;

type
  [TestFixture]
  TExceptionWidgetTests = class
  public
    [Test] procedure ClassNameAndMessage;
    [Test] procedure StackTrace_SplitsLines;

    [Test] procedure ShortenPaths_DropsDriveAndDirs;
    [Test] procedure ShortenMethods_KeepsLastSegment;
    [Test] procedure ShortenTypes_KeepsTypeAndMethod;
    [Test] procedure NoStackTrace_OmitsTraceBlock;
    [Test] procedure ShowLinks_WrapsPathWithOSC8;
    [Test] procedure CustomStyle_OverridesEachToken;

    [Test] procedure NoMessage_OmitsColonAndMessage;
    [Test] procedure EmptyTrace_OmitsTraceBlock;
    [Test] procedure ConstructFromException_UsesClassNameAndMessage;
    [Test] procedure WithStyleNil_LeavesExistingStyle;
    [Test] procedure WithClassNameStyle_StillFunctional;
    [Test] procedure CombinedShortenFlags_MethodsTakesPrecedence;
    [Test] procedure ExceptionStyle_DefaultsAreNotPlain;
    [Test] procedure UnparseableTraceLine_StillRenders;
  end;

implementation

uses
  System.SysUtils,
  Testing.AnsiConsole;

function BuildPlain(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.NoColors, width, True, result, sink);
end;

function BuildTrueColor(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.TrueColor, width, True, result, sink);
end;

procedure TExceptionWidgetTests.ClassNameAndMessage;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(ExceptionWidget('EIOError', 'Access denied'));
  output := sink.Text;
  Assert.IsTrue(Pos('EIOError', output) > 0);
  Assert.IsTrue(Pos('Access denied', output) > 0);
end;

procedure TExceptionWidgetTests.StackTrace_SplitsLines;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(
    ExceptionWidget('EFoo', 'bar')
      .WithStackTrace('MyUnit.DoWork'#10'Main.Run'#10'System.Start'));
  output := sink.Text;
  Assert.IsTrue(Pos('MyUnit.DoWork', output) > 0);
  Assert.IsTrue(Pos('Main.Run',      output) > 0);
  Assert.IsTrue(Pos('System.Start',  output) > 0);
  Assert.IsTrue(Pos('at ', output) > 0,
    'Stack frames should be prefixed with "at "');
end;

procedure TExceptionWidgetTests.ShortenPaths_DropsDriveAndDirs;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(
    ExceptionWidget('EIO', 'oops')
      .WithStackTrace('TFoo.Bar in C:\Long\Dir\File.pas:42')
      .WithFormats([TExceptionFormat.ShortenPaths]));
  output := sink.Text;
  Assert.IsTrue(Pos('File.pas', output) > 0,
    'Shortened path should still appear');
  Assert.IsTrue(Pos('C:\Long', output) = 0,
    'Drive/directories should be stripped from the path');
  Assert.IsTrue(Pos('42', output) > 0,
    'Line number should still appear');
end;

procedure TExceptionWidgetTests.ShortenMethods_KeepsLastSegment;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(
    ExceptionWidget('EFoo', '')
      .WithStackTrace('My.Long.Namespace.TheType.DoTheThing')
      .WithFormats([TExceptionFormat.ShortenMethods]));
  output := sink.Text;
  Assert.IsTrue(Pos('DoTheThing', output) > 0,
    'Method name should appear');
  Assert.IsTrue(Pos('Namespace', output) = 0,
    'Namespace prefix should be stripped');
  Assert.IsTrue(Pos('TheType', output) = 0,
    'Type prefix should be stripped under ShortenMethods');
end;

procedure TExceptionWidgetTests.ShortenTypes_KeepsTypeAndMethod;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(
    ExceptionWidget('EFoo', '')
      .WithStackTrace('My.Long.Namespace.TheType.DoTheThing')
      .WithFormats([TExceptionFormat.ShortenTypes]));
  output := sink.Text;
  Assert.IsTrue(Pos('TheType.DoTheThing', output) > 0,
    'Type+method should be kept');
  Assert.IsTrue(Pos('Namespace', output) = 0,
    'Namespace prefix should be stripped');
end;

procedure TExceptionWidgetTests.NoStackTrace_OmitsTraceBlock;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(
    ExceptionWidget('EFoo', 'gone')
      .WithStackTrace('TFoo.Bar in C:\X.pas:1')
      .WithFormats([TExceptionFormat.NoStackTrace]));
  output := sink.Text;
  Assert.IsTrue(Pos('EFoo', output) > 0, 'Header should still render');
  Assert.IsTrue(Pos('gone', output) > 0, 'Message should still render');
  Assert.IsTrue(Pos('at ',     output) = 0, 'No frame prefix should appear');
  Assert.IsTrue(Pos('TFoo.Bar',output) = 0, 'No frame text should appear');
end;

procedure TExceptionWidgetTests.ShowLinks_WrapsPathWithOSC8;
var
  caps    : TCapabilities;
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  // Capabilities with Links=True so the writer emits OSC 8 sequences.
  caps := TCapabilities.Create(TColorSystem.TrueColor, True, True, True).WithLinks(True);
  BuildCapturedConsole(caps, 80, console, sink);
  console.Write(
    ExceptionWidget('EFoo', '')
      .WithStackTrace('TFoo.Bar in C:\Some\File.pas:1')
      .WithFormats([TExceptionFormat.ShowLinks]));
  output := sink.Text;
  // OSC 8 hyperlink intro: ESC ] 8 ; id=N ; <url> ST. The id parameter is
  // required for Windows Terminal to register the link as clickable.
  Assert.IsTrue(Pos(#27']8;id=', output) > 0,
    'Path token should be wrapped with an OSC 8 link with id parameter');
  Assert.IsTrue(Pos(';file:///', output) > 0,
    'The OSC 8 sequence should carry the file:// URL');
  Assert.IsTrue(Pos('C:\Some\File.pas', output) > 0,
    'The URL should target the original full path');
end;

procedure TExceptionWidgetTests.CustomStyle_OverridesEachToken;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
  custom  : IExceptionStyle;
begin
  // TColorSystem.TrueColor lets the writer emit SGR escapes so we can substring-search
  // the output for the colors we set on each token category.
  console := BuildTrueColor(80, sink);
  custom := ExceptionStyle
    .WithMethod    (TAnsiStyle.Plain.WithForeground(TAnsiColor.Lime))
    .WithPath      (TAnsiStyle.Plain.WithForeground(TAnsiColor.FromRGB(1, 2, 3)))
    .WithLineNumber(TAnsiStyle.Plain.WithForeground(TAnsiColor.FromRGB(7, 8, 9)));
  console.Write(
    ExceptionWidget('EFoo', '')
      .WithStackTrace('TFoo.Bar in C:\X.pas:42')
      .WithStyle(custom));
  output := sink.Text;
  // Method = Lime = RGB(0,255,0)
  Assert.IsTrue(Pos('38;2;0;255;0', output) > 0,
    'Method style should emit its true-color SGR sequence');
  // Path
  Assert.IsTrue(Pos('38;2;1;2;3', output) > 0,
    'Path style should emit its true-color SGR sequence');
  // LineNumber
  Assert.IsTrue(Pos('38;2;7;8;9', output) > 0,
    'LineNumber style should emit its true-color SGR sequence');
end;

procedure TExceptionWidgetTests.NoMessage_OmitsColonAndMessage;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  // Empty message should suppress the ': ' separator after the type.
  console := BuildPlain(80, sink);
  console.Write(ExceptionWidget('EFoo', ''));
  output := sink.Text;
  Assert.IsTrue(Pos('EFoo', output) > 0, 'Type name should appear');
  Assert.IsFalse(Pos(': ', output) > 0,
    'No colon-space separator when message is empty');
end;

procedure TExceptionWidgetTests.EmptyTrace_OmitsTraceBlock;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(ExceptionWidget('EFoo', 'msg'));   // no WithStackTrace call
  output := sink.Text;
  Assert.IsTrue(Pos('EFoo', output) > 0);
  Assert.IsFalse(Pos('at ', output) > 0,
    'Empty stack trace should not emit any "at " frames');
end;

procedure TExceptionWidgetTests.ConstructFromException_UsesClassNameAndMessage;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  e       : Exception;
  output  : string;
begin
  // Constructing from a real Exception instance should pick up its
  // ClassName ('Exception') and Message.
  console := BuildPlain(80, sink);
  e := Exception.Create('boom');
  try
    console.Write(ExceptionWidget(e));
  finally
    e.Free;
  end;
  output := sink.Text;
  Assert.IsTrue(Pos('Exception', output) > 0,
    'ClassName from Exception instance should render');
  Assert.IsTrue(Pos('boom', output) > 0,
    'Message from Exception instance should render');
end;

procedure TExceptionWidgetTests.WithStyleNil_LeavesExistingStyle;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // WithStyle(nil) is a no-op - the default style sheet stays in place
  // and the widget still renders.
  console := BuildPlain(80, sink);
  console.Write(ExceptionWidget('EFoo', 'msg').WithStyle(nil));
  Assert.IsTrue(Pos('EFoo', sink.Text) > 0,
    'WithStyle(nil) should not break rendering');
end;

procedure TExceptionWidgetTests.WithClassNameStyle_StillFunctional;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // Backward-compat: the legacy WithClassNameStyle setter must still
  // affect the rendered output.
  BuildCapturedConsole(TColorSystem.TrueColor, 80, True, console, sink);
  console.Write(
    ExceptionWidget('EFoo', 'oops')
      .WithClassNameStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Lime)));
  Assert.IsTrue(Pos('38;2;0;255;0', sink.Text) > 0,
    'WithClassNameStyle (legacy) should still drive the type-name color');
end;

procedure TExceptionWidgetTests.CombinedShortenFlags_MethodsTakesPrecedence;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  // ShortenMethods should win over ShortenTypes when both are set: only
  // the bare method name is kept.
  console := BuildPlain(80, sink);
  console.Write(
    ExceptionWidget('EFoo', '')
      .WithStackTrace('My.Long.Namespace.TheType.DoTheThing')
      .WithFormats([TExceptionFormat.ShortenTypes, TExceptionFormat.ShortenMethods]));
  output := sink.Text;
  Assert.IsTrue(Pos('DoTheThing', output) > 0);
  Assert.IsTrue(Pos('TheType',    output) = 0,
    'ShortenMethods wins: type prefix must be stripped even with ShortenTypes set');
end;

procedure TExceptionWidgetTests.ExceptionStyle_DefaultsAreNotPlain;
var
  s : IExceptionStyle;
begin
  // The factory style sheet should ship with non-plain defaults so calls
  // to ExceptionWidget render colored output without further config.
  s := ExceptionStyle;
  Assert.IsFalse(s.GetExceptionType.IsPlain,
    'ExceptionType default should be styled');
  Assert.IsFalse(s.GetMethod.IsPlain,
    'Method default should be styled');
  Assert.IsFalse(s.GetPath.IsPlain,
    'Path default should be styled');
  Assert.IsFalse(s.GetLineNumber.IsPlain,
    'LineNumber default should be styled');
end;

procedure TExceptionWidgetTests.UnparseableTraceLine_StillRenders;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  // A trace line that doesn't match the 'method in path:line' pattern
  // is treated as a bare method - still rendered, no path/line tokens.
  console := BuildPlain(80, sink);
  console.Write(
    ExceptionWidget('EFoo', '')
      .WithStackTrace('garbledframe123 +0x42'));
  output := sink.Text;
  Assert.IsTrue(Pos('garbledframe123', output) > 0,
    'Unparseable line should still render verbatim as the method token');
  Assert.IsTrue(Pos('at ', output) > 0,
    'Frame prefix "at " should still appear');
end;

initialization
  TDUnitX.RegisterTestFixture(TExceptionWidgetTests);

end.
