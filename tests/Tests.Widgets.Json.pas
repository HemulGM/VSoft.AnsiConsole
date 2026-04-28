unit Tests.Widgets.Json;

{
  JsonText widget tests - object/array pretty-printing, empty-object
  inlining, and primitive token rendering.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Widgets.Json;

type
  [TestFixture]
  TJsonTextTests = class
  public
    [Test] procedure Object_IsPrettyPrinted;
    [Test] procedure EmptyObject_StaysOnSameLine;
    [Test] procedure Array_WithNumbers;
    [Test] procedure BooleanAndNull;
    [Test] procedure NestedObject_Indents;
    [Test] procedure NegativeAndDecimalNumbers;
    [Test] procedure StringValue_AppearsQuoted;
    [Test] procedure WithIndent_ChangesIndentationWidth;
    [Test] procedure WithStringStyle_AppliesColorToStrings;
    [Test] procedure EmptyArray_StaysOnSameLine;
  end;

implementation

uses
  Testing.AnsiConsole;

function BuildPlain(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.NoColors, width, True, result, sink);
end;

procedure TJsonTextTests.Object_IsPrettyPrinted;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(Json('{"name":"vincent","age":42}'));
  output := sink.Text;
  Assert.IsTrue(Pos('name', output) > 0);
  Assert.IsTrue(Pos('vincent', output) > 0);
  Assert.IsTrue(Pos('42', output) > 0);
  // Pretty-printed, so there should be at least one newline inside
  Assert.IsTrue(Pos(#10, output) > 0, 'Object should be spread across lines');
end;

procedure TJsonTextTests.EmptyObject_StaysOnSameLine;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(Json('{}'));
  output := sink.Text;
  // Empty object: "{}" on a single line, no interior newline.
  Assert.IsTrue(Pos('{}', output) > 0, 'Empty object should print as "{}"');
end;

procedure TJsonTextTests.Array_WithNumbers;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(Json('[1, 2, 3]'));
  output := sink.Text;
  Assert.IsTrue(Pos('1', output) > 0);
  Assert.IsTrue(Pos('2', output) > 0);
  Assert.IsTrue(Pos('3', output) > 0);
end;

procedure TJsonTextTests.BooleanAndNull;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(Json('{"flag":true,"empty":null,"on":false}'));
  output := sink.Text;
  Assert.IsTrue(Pos('true',  output) > 0);
  Assert.IsTrue(Pos('false', output) > 0);
  Assert.IsTrue(Pos('null',  output) > 0);
end;

procedure TJsonTextTests.NestedObject_Indents;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(Json('{"outer":{"inner":1}}'));
  output := sink.Text;
  // Inner key should appear indented past the outer key.
  Assert.IsTrue(Pos('outer', output) > 0);
  Assert.IsTrue(Pos('inner', output) > 0);
  // Indented inner: a leading-whitespace + double-quote sequence ahead of
  // 'inner'.
  Assert.IsTrue(Pos('  "inner"', output) > 0,
    'Nested key should be indented at least 2 spaces');
end;

procedure TJsonTextTests.NegativeAndDecimalNumbers;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(Json('[-3, 1.5, 0]'));
  output := sink.Text;
  Assert.IsTrue(Pos('-3',  output) > 0, 'Negative number should appear');
  Assert.IsTrue(Pos('1.5', output) > 0, 'Decimal number should appear');
  Assert.IsTrue(Pos('0',   output) > 0, 'Zero should appear');
end;

procedure TJsonTextTests.StringValue_AppearsQuoted;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  console := BuildPlain(80, sink);
  console.Write(Json('{"name":"vincent"}'));
  output := sink.Text;
  Assert.IsTrue(Pos('"vincent"', output) > 0,
    'String value should render with surrounding quotes');
end;

procedure TJsonTextTests.WithIndent_ChangesIndentationWidth;
var
  console      : IAnsiConsole;
  sink         : ICapturedAnsiOutput;
  defaultIndented, wideIndented : string;
begin
  // Default indent (2): nested key prefixed by 2 spaces.
  console := BuildPlain(80, sink);
  console.Write(Json('{"a":{"b":1}}'));
  defaultIndented := sink.Text;

  // Custom indent of 4: nested key prefixed by 4 spaces.
  console := BuildPlain(80, sink);
  console.Write(Json('{"a":{"b":1}}').WithIndent(4));
  wideIndented := sink.Text;

  Assert.IsTrue(Pos('  "b"',   defaultIndented) > 0, 'Default indent should be 2');
  Assert.IsTrue(Pos('    "b"', wideIndented)    > 0,
    'WithIndent(4) should produce 4-space indentation for nested keys');
end;

procedure TJsonTextTests.WithStringStyle_AppliesColorToStrings;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // True-color console + a Lime string style => RGB(0,255,0) SGR around
  // any quoted string in the rendered output.
  BuildCapturedConsole(TColorSystem.TrueColor, 80, True, console, sink);
  console.Write(
    Json('{"x":"hi"}')
      .WithStringStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Lime)));
  Assert.IsTrue(Pos('38;2;0;255;0', sink.Text) > 0,
    'Custom string style should emit a Lime foreground SGR');
end;

procedure TJsonTextTests.EmptyArray_StaysOnSameLine;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildPlain(80, sink);
  console.Write(Json('[]'));
  Assert.IsTrue(Pos('[]', sink.Text) > 0,
    'Empty array should render compactly as "[]"');
end;

initialization
  TDUnitX.RegisterTestFixture(TJsonTextTests);

end.
