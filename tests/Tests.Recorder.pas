unit Tests.Recorder;

{
  Recorder tests - text/HTML export, reset semantics, inner-console
  forwarding, and pluggable encoders.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Profile,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Widgets.Text,
  VSoft.AnsiConsole.Recorder;

type
  [TestFixture]
  TRecorderTests = class
  public
    [Test] procedure ExportText_ContainsWritten;
    [Test] procedure ExportHtml_WrapsInPreTag;
    [Test] procedure Reset_ClearsRecording;
    [Test] procedure ForwardsToInner;
    [Test] procedure Export_CustomEncoder_ReceivesRenderables;
    [Test] procedure Export_TextEncoder_MatchesExportText;
    [Test] procedure Export_HtmlEncoder_MatchesExportHtml;
    [Test] procedure MultipleWrites_AccumulateInOrder;
    [Test] procedure ExportText_FreshRecorder_IsEmpty;
    [Test] procedure ExportHtml_EscapesAngleBrackets;
    [Test] procedure CustomEncoder_AfterReset_SeesNothing;
    [Test] procedure WriteLine_NoArg_RecordsLineBreak;
    [Test] procedure WriteLine_WithRenderable_RecordsTrailingLineBreak;
    [Test] procedure ExportHtml_WriteLine_PreservesNewline;
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

procedure TRecorderTests.ExportText_ContainsWritten;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  rec     : IRecorder;
  output  : string;
begin
  console := BuildPlain(40, sink);
  rec := Recorder(console);
  rec.Write(Text('hello world'));
  output := rec.ExportText;
  Assert.IsTrue(Pos('hello world', output) > 0,
    'ExportText should contain the written content');
end;

procedure TRecorderTests.ExportHtml_WrapsInPreTag;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  rec     : IRecorder;
  html    : string;
begin
  console := BuildTrueColor(40, sink);
  rec := Recorder(console);
  rec.Write(Text('abc'));
  html := rec.ExportHtml;
  Assert.IsTrue(Pos('<pre', html) > 0, 'HTML should start with <pre>');
  Assert.IsTrue(Pos('</pre>', html) > 0, 'HTML should end with </pre>');
  Assert.IsTrue(Pos('abc', html) > 0, 'HTML should contain the rendered text');
end;

procedure TRecorderTests.Reset_ClearsRecording;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  rec     : IRecorder;
begin
  console := BuildPlain(40, sink);
  rec := Recorder(console);
  rec.Write(Text('first'));
  rec.Reset;
  rec.Write(Text('second'));
  Assert.IsFalse(Pos('first', rec.ExportText) > 0,
    'Reset should drop previously recorded items');
  Assert.IsTrue(Pos('second', rec.ExportText) > 0);
end;

procedure TRecorderTests.ForwardsToInner;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  rec     : IRecorder;
begin
  console := BuildPlain(40, sink);
  rec := Recorder(console);
  rec.Write(Text('through'));
  // The inner console's sink should also have received the text because
  // the recorder forwards every write.
  Assert.IsTrue(Pos('through', sink.Text) > 0,
    'Recorder must forward writes to the inner console');
end;

type
  { Custom encoder used by the test below. Stamps each recorded renderable
    into a `[#i]` line so we can assert the encoder received the right
    inputs. }
  TCountingEncoder = class(TInterfacedObject, IAnsiConsoleEncoder)
  strict private
    FProfile : IProfile;
    FCount   : Integer;
  public
    function Encode(const profile : IProfile;
                     const recorded : TArray<IRenderable>) : string;
    property Profile : IProfile read FProfile;
    property Count   : Integer  read FCount;
  end;

function TCountingEncoder.Encode(const profile : IProfile;
                                  const recorded : TArray<IRenderable>) : string;
var
  i : Integer;
begin
  FProfile := profile;
  FCount := Length(recorded);
  result := '';
  for i := 0 to High(recorded) do
    result := result + '[#' + IntToStr(i) + ']' + sLineBreak;
end;

procedure TRecorderTests.Export_CustomEncoder_ReceivesRenderables;
var
  console  : IAnsiConsole;
  sink     : ICapturedAnsiOutput;
  rec      : IRecorder;
  encoder  : TCountingEncoder;
  iEncoder : IAnsiConsoleEncoder;
  output   : string;
begin
  console := BuildPlain(40, sink);
  rec := Recorder(console);
  rec.Write(Text('one'));
  rec.Write(Text('two'));
  rec.Write(Text('three'));

  encoder := TCountingEncoder.Create;
  iEncoder := encoder;
  output := rec.Export(iEncoder);

  Assert.AreEqual(3, encoder.Count, 'Encoder should see all three recorded renderables');
  Assert.IsNotNull(encoder.Profile, 'Encoder must receive the recorder profile');
  Assert.Contains(output, '[#0]');
  Assert.Contains(output, '[#1]');
  Assert.Contains(output, '[#2]');
end;

procedure TRecorderTests.Export_TextEncoder_MatchesExportText;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  rec     : IRecorder;
begin
  console := BuildPlain(40, sink);
  rec := Recorder(console);
  rec.Write(Text('alpha'));
  rec.Write(Text('beta'));
  Assert.AreEqual(rec.ExportText, rec.Export(TextEncoder),
    'TextEncoder must produce the same output as ExportText');
end;

procedure TRecorderTests.Export_HtmlEncoder_MatchesExportHtml;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  rec     : IRecorder;
begin
  console := BuildPlain(40, sink);
  rec := Recorder(console);
  rec.Write(Text('alpha'));
  rec.Write(Text('beta'));
  Assert.AreEqual(rec.ExportHtml, rec.Export(HtmlEncoder),
    'HtmlEncoder must produce the same output as ExportHtml');
end;

procedure TRecorderTests.MultipleWrites_AccumulateInOrder;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  rec     : IRecorder;
  output  : string;
  posA, posB, posC : Integer;
begin
  console := BuildPlain(40, sink);
  rec := Recorder(console);
  rec.Write(Text('alpha'));
  rec.Write(Text('beta'));
  rec.Write(Text('gamma'));
  output := rec.ExportText;
  posA := Pos('alpha', output);
  posB := Pos('beta',  output);
  posC := Pos('gamma', output);
  Assert.IsTrue(posA > 0,    'alpha should be present');
  Assert.IsTrue(posB > posA, 'beta should follow alpha in export');
  Assert.IsTrue(posC > posB, 'gamma should follow beta in export');
end;

procedure TRecorderTests.ExportText_FreshRecorder_IsEmpty;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  rec     : IRecorder;
begin
  console := BuildPlain(40, sink);
  rec := Recorder(console);
  // No writes - export should produce no characters.
  Assert.AreEqual('', rec.ExportText,
    'Export of an unused recorder should be empty');
end;

procedure TRecorderTests.ExportHtml_EscapesAngleBrackets;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  rec     : IRecorder;
  html    : string;
begin
  console := BuildPlain(40, sink);
  rec := Recorder(console);
  rec.Write(Text('<script>'));
  html := rec.ExportHtml;
  // The text payload `<script>` must be HTML-escaped (eg `&lt;script&gt;`)
  // so the wrapping <pre> tag isn't broken by user content. We don't
  // require an exact entity but a literal `<script>` substring would mean
  // the encoder failed to escape.
  Assert.IsFalse(Pos('<script>', html) > 0,
    'HTML export must escape literal "<script>" so the wrapper is safe');
  // The text body should still be reachable via the escaped form.
  Assert.IsTrue(Pos('script', html) > 0, 'Body content should still be present');
end;

procedure TRecorderTests.CustomEncoder_AfterReset_SeesNothing;
var
  console  : IAnsiConsole;
  sink     : ICapturedAnsiOutput;
  rec      : IRecorder;
  encoder  : TCountingEncoder;
  iEncoder : IAnsiConsoleEncoder;
begin
  console := BuildPlain(40, sink);
  rec := Recorder(console);
  rec.Write(Text('one'));
  rec.Write(Text('two'));
  rec.Reset;

  encoder := TCountingEncoder.Create;
  iEncoder := encoder;
  rec.Export(iEncoder);

  Assert.AreEqual(0, encoder.Count,
    'After Reset the encoder should see zero recorded renderables');
end;

procedure TRecorderTests.WriteLine_NoArg_RecordsLineBreak;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  rec     : IRecorder;
  output  : string;
  posA, posB : Integer;
begin
  // Regression for "missing newline" bug: the export must preserve the
  // line break emitted by WriteLine between two Write() calls so the two
  // payloads don't collapse onto a single line.
  console := BuildPlain(40, sink);
  rec := Recorder(console);
  rec.Write(Text('aaa'));
  rec.WriteLine;
  rec.Write(Text('bbb'));

  output := rec.ExportText;
  posA := Pos('aaa', output);
  posB := Pos('bbb', output);
  Assert.IsTrue(posA > 0, 'aaa should appear');
  Assert.IsTrue(posB > posA, 'bbb should appear after aaa');
  Assert.IsTrue(Pos(#10, Copy(output, posA, posB - posA)) > 0,
    'There must be a line break between aaa and bbb in the export');
end;

procedure TRecorderTests.WriteLine_WithRenderable_RecordsTrailingLineBreak;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  rec     : IRecorder;
  output  : string;
  posA, posB : Integer;
begin
  // WriteLine(IRenderable) is "render the payload, then move to the next
  // line". The trailing line break must be present in the recorded
  // stream too.
  console := BuildPlain(40, sink);
  rec := Recorder(console);
  rec.WriteLine(Text('aaa'));
  rec.Write(Text('bbb'));

  output := rec.ExportText;
  posA := Pos('aaa', output);
  posB := Pos('bbb', output);
  Assert.IsTrue(posA > 0, 'aaa should appear');
  Assert.IsTrue(posB > posA, 'bbb should appear after aaa');
  Assert.IsTrue(Pos(#10, Copy(output, posA, posB - posA)) > 0,
    'WriteLine(renderable) must record a trailing line break');
end;

procedure TRecorderTests.ExportHtml_WriteLine_PreservesNewline;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  rec     : IRecorder;
  html    : string;
  posA, posB : Integer;
begin
  // The HTML encoder maps line-break segments to sLineBreak inside the
  // <pre>. SimpleDemo's recorder report relies on this so the wrapped
  // panel doesn't sit next to the leading line of plain text.
  console := BuildPlain(40, sink);
  rec := Recorder(console);
  rec.Write(Text('aaa'));
  rec.WriteLine;
  rec.Write(Text('bbb'));

  html := rec.ExportHtml;
  posA := Pos('aaa', html);
  posB := Pos('bbb', html);
  Assert.IsTrue(posA > 0);
  Assert.IsTrue(posB > posA);
  Assert.IsTrue(Pos(#10, Copy(html, posA, posB - posA)) > 0,
    'HTML export must contain a line break between the two writes');
end;

initialization
  TDUnitX.RegisterTestFixture(TRecorderTests);

end.
