unit Tests.Widgets.TextPath;

{
  TextPath widget tests - fits-as-is, ellipsis-collapsing, and Windows-rooted
  path parsing.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Widgets.TextPath;

type
  [TestFixture]
  TTextPathTests = class
  public
    [Test] procedure Fits_Unchanged;
    [Test] procedure EllipsisDropsMiddle;
    [Test] procedure WindowsRooted_Parses;
    [Test] procedure EmptyPath_RendersWithoutError;
    [Test] procedure SingleSegment_RenderedVerbatim;
    [Test] procedure UnixRooted_PreservesLeadingSlash;
    [Test] procedure VeryNarrow_PreservesLeafEvenWithEllipsis;
  end;

implementation

uses
  Testing.AnsiConsole;

function BuildPlain(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.NoColors, width, True, result, sink);
end;

procedure TTextPathTests.Fits_Unchanged;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  p       : ITextPath;
begin
  console := BuildPlain(40, sink);
  p := TextPath('/usr/local/bin/tool');
  console.Write(p);
  Assert.IsTrue(Pos('/usr/local/bin/tool', sink.Text) > 0);
end;

procedure TTextPathTests.EllipsisDropsMiddle;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  p       : ITextPath;
  captured : string;
begin
  console := BuildPlain(16, sink);
  p := TextPath('/usr/local/share/very/deep/folder/file.txt');
  console.Write(p);
  captured := sink.Text;
  // Must contain the ellipsis character and the leaf file name.
  Assert.IsTrue(Pos(#$2026, captured) > 0, 'Should contain U+2026 ellipsis');
  Assert.IsTrue(Pos('file.txt', captured) > 0, 'Leaf should be preserved when possible');
end;

procedure TTextPathTests.WindowsRooted_Parses;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  p       : ITextPath;
begin
  console := BuildPlain(60, sink);
  p := TextPath('C:\Users\vincent\file.txt');
  console.Write(p);
  Assert.IsTrue(Pos('C:', sink.Text) > 0);
  Assert.IsTrue(Pos('file.txt', sink.Text) > 0);
end;

procedure TTextPathTests.EmptyPath_RendersWithoutError;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildPlain(40, sink);
  console.Write(TextPath(''));
  // No assertion on text - just confirming the renderer doesn't raise.
  Assert.IsNotNull(sink, 'Empty path should render without error');
end;

procedure TTextPathTests.SingleSegment_RenderedVerbatim;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildPlain(40, sink);
  console.Write(TextPath('readme.md'));
  Assert.IsTrue(Pos('readme.md', sink.Text) > 0,
    'Single-segment path should render verbatim');
end;

procedure TTextPathTests.UnixRooted_PreservesLeadingSlash;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildPlain(60, sink);
  console.Write(TextPath('/etc/hosts'));
  Assert.IsTrue(Pos('/etc/hosts', sink.Text) > 0,
    'Unix-rooted short path should render verbatim including the leading "/"');
end;

procedure TTextPathTests.VeryNarrow_PreservesLeafEvenWithEllipsis;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  // At a narrow width the path widget collapses middle segments but still
  // tries to keep the leaf. 'file.txt' (8 chars) + ellipsis (1) = 9, which
  // fits in 12 cells with room for at least the root marker.
  console := BuildPlain(12, sink);
  console.Write(TextPath('/usr/local/share/very/deep/nested/file.txt'));
  output := sink.Text;
  Assert.IsTrue(Pos('file.txt', output) > 0,
    'Leaf "file.txt" must survive at maxWidth=12');
  Assert.IsTrue(Pos(#$2026, output) > 0,
    'Ellipsis (U+2026) should mark the elision');
end;

initialization
  TDUnitX.RegisterTestFixture(TTextPathTests);

end.
