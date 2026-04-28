unit Tests.Widgets.Tree;

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Widgets.Text,
  VSoft.AnsiConsole.Widgets.Tree,
  VSoft.AnsiConsole.Borders.Tree;

type
  [TestFixture]
  TTreeWidgetTests = class
  public
    [Test] procedure Ascii_TwoSiblings_ForkThenLast;
    [Test] procedure Ascii_NestedTree_IndentsContinuation;
    [Test] procedure Unicode_OneChild_UsesLastGlyph;
    [Test] procedure CircularTree_RaisesECircularTree;
    [Test] procedure RootOnly_RendersJustRoot;
    [Test] procedure AddNode_StringOverload_AcceptsMarkup;
    [Test] procedure WithExpandedFalse_HidesChildren;
    [Test] procedure NodeWithExpandedFalse_HidesItsSubtree;
    [Test] procedure GuideStyle_AppliesAnsiColor;
    [Test] procedure DeeplyNested_PreservesIndentation;
    [Test] procedure RootMarkupCtor_ParsesMarkup;
    [Test] procedure GetRoot_ReturnsRootNode;
    [Test] procedure NodeChildren_IndexedAccessWorks;
  end;

implementation

uses
  System.SysUtils,
  Testing.AnsiConsole;

function BuildPlain(width : Integer; unicode : Boolean;
                     out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.NoColors, width, unicode, result, sink);
end;

procedure TTreeWidgetTests.Ascii_TwoSiblings_ForkThenLast;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  t       : ITree;
  expected : string;
begin
  console := BuildPlain(40, False, sink);
  t := Tree(Text('root')).WithGuide(TTreeGuideKind.Ascii);
  t.AddNode(Text('a'));
  t.AddNode(Text('b'));
  console.Write(t);

  expected :=
    'root' + sLineBreak +
    '+-- a' + sLineBreak +
    '`-- b';
  Assert.AreEqual(expected, sink.Text);
end;

procedure TTreeWidgetTests.Ascii_NestedTree_IndentsContinuation;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  t       : ITree;
  a       : ITreeNode;
  expected : string;
begin
  console := BuildPlain(40, False, sink);
  t := Tree(Text('root')).WithGuide(TTreeGuideKind.Ascii);
  a := t.AddNode(Text('a'));
  a.AddNode(Text('a1'));
  a.AddNode(Text('a2'));
  t.AddNode(Text('b'));
  console.Write(t);

  // 'a' is not the last sibling, so its children's continuation prefix is '|   '.
  // 'b' IS the last sibling (no children).
  expected :=
    'root' + sLineBreak +
    '+-- a' + sLineBreak +
    '|   +-- a1' + sLineBreak +
    '|   `-- a2' + sLineBreak +
    '`-- b';
  Assert.AreEqual(expected, sink.Text);
end;

procedure TTreeWidgetTests.Unicode_OneChild_UsesLastGlyph;
var
  console  : IAnsiConsole;
  sink     : ICapturedAnsiOutput;
  t        : ITree;
  captured : string;
begin
  console := BuildPlain(40, True, sink);
  t := Tree(Text('r')).WithGuide(TTreeGuideKind.Line);
  t.AddNode(Text('only'));
  console.Write(t);
  captured := sink.Text;
  // Unicode 'last' glyph is U+2514 and horizontal is U+2500.
  Assert.Contains(captured, #$2514 + #$2500 + #$2500 + ' only');
end;

procedure TTreeWidgetTests.CircularTree_RaisesECircularTree;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  t       : ITree;
  parent  : ITreeNode;
  child   : ITreeNode;
begin
  // Build: root -> parent -> child, then add `parent` as a child of
  // `child` to form a cycle. Render must raise ECircularTree.
  console := BuildPlain(40, False, sink);
  t := Tree(Text('root'));
  parent := t.AddNode(Text('parent'));
  child  := parent.AddNode(Text('child'));
  child.AddNodeRef(parent);   // cycle: child -> parent (existing ref)

  Assert.WillRaise(
    procedure
    begin
      console.Write(t);
    end,
    ECircularTree,
    'Render should raise ECircularTree when a cycle is detected');
end;

procedure TTreeWidgetTests.RootOnly_RendersJustRoot;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  console := BuildPlain(40, False, sink);
  console.Write(Tree(Text('alone')));
  // No children: just the root label, no guide glyphs.
  Assert.AreEqual('alone', sink.Text);
end;

procedure TTreeWidgetTests.AddNode_StringOverload_AcceptsMarkup;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  t       : ITree;
begin
  // The string overload of AddNode must route through the markup parser
  // so [bold]Hello[/] resolves to plain "Hello" (in TColorSystem.NoColors).
  console := BuildPlain(40, False, sink);
  t := Tree(Text('r')).WithGuide(TTreeGuideKind.Ascii);
  t.AddNode('[bold]Hello[/]');
  console.Write(t);
  Assert.IsTrue(Pos('Hello',  sink.Text) > 0, 'markup payload should render');
  Assert.IsTrue(Pos('[bold]', sink.Text) = 0, 'tag must not leak through');
end;

procedure TTreeWidgetTests.WithExpandedFalse_HidesChildren;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  t       : ITree;
begin
  console := BuildPlain(40, False, sink);
  t := Tree(Text('root')).WithGuide(TTreeGuideKind.Ascii);
  t.AddNode(Text('hidden-a'));
  t.AddNode(Text('hidden-b'));
  t.WithExpanded(False);
  console.Write(t);
  Assert.IsTrue(Pos('root',     sink.Text) > 0, 'root should still render');
  Assert.IsTrue(Pos('hidden-a', sink.Text) = 0,
    'collapsed tree must not emit children');
  Assert.IsTrue(Pos('hidden-b', sink.Text) = 0);
end;

procedure TTreeWidgetTests.NodeWithExpandedFalse_HidesItsSubtree;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  t       : ITree;
  branch  : ITreeNode;
begin
  console := BuildPlain(40, False, sink);
  t := Tree(Text('root')).WithGuide(TTreeGuideKind.Ascii);
  branch := t.AddNode(Text('branch'));
  branch.AddNode(Text('leaf-a'));
  branch.AddNode(Text('leaf-b'));
  branch.WithExpanded(False);
  t.AddNode(Text('sibling'));
  console.Write(t);
  Assert.IsTrue(Pos('branch',  sink.Text) > 0, 'branch label should render');
  Assert.IsTrue(Pos('sibling', sink.Text) > 0, 'siblings still render');
  Assert.IsTrue(Pos('leaf-a',  sink.Text) = 0,
    'collapsed branch must hide its leaves');
  Assert.IsTrue(Pos('leaf-b',  sink.Text) = 0);
end;

procedure TTreeWidgetTests.GuideStyle_AppliesAnsiColor;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  t       : ITree;
begin
  // True-color console + a Lime guide style => RGB(0,255,0) on the
  // tree's branch glyphs.
  BuildCapturedConsole(TColorSystem.TrueColor, 40, True, console, sink);
  t := Tree(Text('r')).WithGuide(TTreeGuideKind.Line)
       .WithGuideStyle(TAnsiStyle.Plain.WithForeground(TAnsiColor.Lime));
  t.AddNode(Text('only'));
  console.Write(t);
  Assert.IsTrue(Pos('38;2;0;255;0', sink.Text) > 0,
    'WithGuideStyle should drive the guide-glyph SGR colour');
end;

procedure TTreeWidgetTests.DeeplyNested_PreservesIndentation;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  t       : ITree;
  a, b, c : ITreeNode;
begin
  // Three levels deep. The leaf line should have at least two indentation
  // levels of guide-prefix before the fork glyph.
  console := BuildPlain(60, False, sink);
  t := Tree(Text('root')).WithGuide(TTreeGuideKind.Ascii);
  a := t.AddNode(Text('a'));
  b := a.AddNode(Text('b'));
  c := b.AddNode(Text('c'));
  c.AddNode(Text('leaf'));
  console.Write(t);
  // Leaf line indent: 'root' last-child markers get '`-- '/'    ', so the
  // leaf row contains two '    ' continuation slots (8 spaces) followed by
  // the fork glyph and the leaf text.
  Assert.IsTrue(Pos('        `-- leaf', sink.Text) > 0,
    'Deeply nested leaf should be indented by two continuation slots');
end;

procedure TTreeWidgetTests.RootMarkupCtor_ParsesMarkup;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // Tree(string) is the markup overload. TColorSystem.NoColors strips styling but
  // the parser still consumes the [bold] tag.
  console := BuildPlain(40, False, sink);
  console.Write(Tree('[bold]Title[/]'));
  Assert.IsTrue(Pos('Title',  sink.Text) > 0);
  Assert.IsTrue(Pos('[bold]', sink.Text) = 0);
end;

procedure TTreeWidgetTests.GetRoot_ReturnsRootNode;
var
  t    : ITree;
  root : ITreeNode;
begin
  t := Tree(Text('hello'));
  root := t.Root;
  Assert.IsNotNull(root, 'Tree.Root must expose the root node');
  // Initially the root has no children.
  Assert.AreEqual<integer>(0, root.ChildCount, 'Fresh tree root has no children');
end;

procedure TTreeWidgetTests.NodeChildren_IndexedAccessWorks;
var
  t    : ITree;
  a, b : ITreeNode;
begin
  t := Tree(Text('r'));
  a := t.AddNode(Text('a'));
  b := t.AddNode(Text('b'));
  Assert.AreEqual(2, t.Root.ChildCount);
  // Children are indexed in insertion order; we check the wire identity
  // round-trips through the property.
  Assert.IsTrue(t.Root.Children[0] = a, 'First child should be "a"');
  Assert.IsTrue(t.Root.Children[1] = b, 'Second child should be "b"');
end;

initialization
  TDUnitX.RegisterTestFixture(TTreeWidgetTests);

end.
