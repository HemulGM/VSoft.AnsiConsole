unit VSoft.AnsiConsole.Widgets.Tree;

{
  TTree / TTreeNode - hierarchical display:

    root
    ├── child1
    │   ├── grand1a
    │   └── grand1b
    ├── child2
    └── child3

  Rendering algorithm (DFS with an ancestor-last-flag stack):
    1. Emit root label as-is (no prefix).
    2. For each child c at depth 1..N:
         prefix = ''
         for each ancestor a at depths 1..current-1:
           if ancestor was its parent's last child: prefix += '    '
           else: prefix += '│   '    (vertical continues)
         if c is last-of-siblings: prefix += '└── '
         else:                     prefix += '├── '
         emit prefix + c.label, then recurse.

    Multi-line labels: continuation lines use the same ancestor prefix
    plus either '│   ' or '    ' at the current depth (never the fork).
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Borders.Tree;

type
  { Raised when Render detects the same ITreeNode reference appearing
    twice in the walk - typically caused by sharing a child node between
    two parents. Mirrors Spectre's CircularTreeException. }
  ECircularTree = class(Exception);

  ITreeNode = interface
    ['{9D6B3B2A-6E51-4F27-9E52-6A4C3D0FB220}']
    function GetLabel : IRenderable;
    function GetChild(index : Integer) : ITreeNode;
    function ChildCount : Integer;
    function AddNode(const childLabel : IRenderable) : ITreeNode; overload;
    function AddNode(const childMarkup : string) : ITreeNode; overload;
    { Adds an existing ITreeNode as a child (sharing the reference, not
      cloning). Mirrors Spectre's `Nodes.Add(treeNode)`. Sharing a node
      between two parents creates a tree the renderer can detect via
      ECircularTree, so prefer the IRenderable overload above unless you
      genuinely want shared subtrees. }
    function AddNodeRef(const node : ITreeNode) : ITreeNode;
    function WithExpanded(value : Boolean) : ITreeNode;
    function GetExpanded : Boolean;

    property Labels : IRenderable read GetLabel;
    property Children[index : Integer] : ITreeNode read GetChild;
    property Expanded : Boolean read GetExpanded;
  end;

  ITree = interface(IRenderable)
    ['{6C3B3D4A-8F62-4E1D-A7C5-9E2F5B8A0C1C}']
    function GetRoot : ITreeNode;
    function AddNode(const childLabel : IRenderable) : ITreeNode; overload;
    function AddNode(const childMarkup : string) : ITreeNode; overload;
    function WithGuide(kind : TTreeGuideKind) : ITree;
    function WithGuideStyle(const value : TAnsiStyle) : ITree;
    function WithExpanded(value : Boolean) : ITree;
    property Root : ITreeNode read GetRoot;
  end;

  TTreeNode = class(TInterfacedObject, ITreeNode)
  strict private
    FLabel    : IRenderable;
    FChildren : TArray<ITreeNode>;
    FExpanded : Boolean;
    function  GetLabel : IRenderable;
    function  GetChild(index : Integer) : ITreeNode;
    function  GetExpanded : Boolean;
  public
    constructor Create(const lbl : IRenderable);
    function ChildCount : Integer;
    function AddNode(const childLabel : IRenderable) : ITreeNode; overload;
    function AddNode(const childMarkup : string) : ITreeNode; overload;
    function AddNodeRef(const node : ITreeNode) : ITreeNode;
    function WithExpanded(value : Boolean) : ITreeNode;
  end;

  TTree = class(TInterfacedObject, IRenderable, ITree)
  strict private
    FRoot       : ITreeNode;
    FGuide      : ITreeGuide;
    FGuideStyle : TAnsiStyle;
    FExpanded   : Boolean;
    function  GetRoot : ITreeNode;

    procedure EmitNode(const node : ITreeNode;
                        const ancestorsAreLast : TArray<Boolean>;
                        isLastSibling : Boolean;
                        const options : TRenderOptions;
                        maxWidth : Integer;
                        var segs : TAnsiSegments;
                        var count : Integer;
                        const visited : TList<ITreeNode>);
    function  BuildPrefix(const ancestors : TArray<Boolean>;
                           isLastSibling : Boolean;
                           isLabelLine : Boolean;
                           options : TRenderOptions) : string;
  public
    constructor Create(const root : IRenderable);
    function AddNode(const childLabel : IRenderable) : ITreeNode; overload;
    function AddNode(const childMarkup : string) : ITreeNode; overload;
    function WithGuide(kind : TTreeGuideKind) : ITree;
    function WithGuideStyle(const value : TAnsiStyle) : ITree;
    function WithExpanded(value : Boolean) : ITree;
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
  end;

function Tree(const root : IRenderable) : ITree; overload;
function Tree(const rootMarkup : string) : ITree; overload;

implementation

uses
  VSoft.AnsiConsole.Widgets.Text,
  VSoft.AnsiConsole.Widgets.Markup,
  VSoft.AnsiConsole.Internal.Cell,
  VSoft.AnsiConsole.Internal.SegmentOps;

{ TTreeNode }

constructor TTreeNode.Create(const lbl : IRenderable);
begin
  inherited Create;
  FLabel := lbl;
  FExpanded := True;
end;

function TTreeNode.GetExpanded : Boolean;
begin
  result := FExpanded;
end;

function TTreeNode.WithExpanded(value : Boolean) : ITreeNode;
begin
  FExpanded := value;
  result := Self;
end;

function TTreeNode.GetLabel : IRenderable;
begin
  result := FLabel;
end;

function TTreeNode.GetChild(index : Integer) : ITreeNode;
begin
  result := FChildren[index];
end;

function TTreeNode.ChildCount : Integer;
begin
  result := Length(FChildren);
end;

function TTreeNode.AddNode(const childLabel : IRenderable) : ITreeNode;
var
  node : TTreeNode;
begin
  node := TTreeNode.Create(childLabel);
  SetLength(FChildren, Length(FChildren) + 1);
  FChildren[High(FChildren)] := node;
  result := node;
end;

function TTreeNode.AddNode(const childMarkup : string) : ITreeNode;
begin
  result := AddNode(Markup(childMarkup));
end;

function TTreeNode.AddNodeRef(const node : ITreeNode) : ITreeNode;
begin
  if node = nil then
  begin
    result := Self;
    Exit;
  end;
  SetLength(FChildren, Length(FChildren) + 1);
  FChildren[High(FChildren)] := node;
  result := node;
end;

{ TTree }

constructor TTree.Create(const root : IRenderable);
begin
  inherited Create;
  FRoot := TTreeNode.Create(root);
  FGuide := TreeGuide(TTreeGuideKind.Line);
  FGuideStyle := TAnsiStyle.Plain;
  FExpanded := True;
end;

function TTree.WithExpanded(value : Boolean) : ITree;
begin
  FExpanded := value;
  result := Self;
end;

function TTree.GetRoot : ITreeNode;
begin
  result := FRoot;
end;

function TTree.AddNode(const childLabel : IRenderable) : ITreeNode;
begin
  result := FRoot.AddNode(childLabel);
end;

function TTree.AddNode(const childMarkup : string) : ITreeNode;
begin
  result := FRoot.AddNode(childMarkup);
end;

function TTree.WithGuide(kind : TTreeGuideKind) : ITree;
begin
  FGuide := TreeGuide(kind);
  result := Self;
end;

function TTree.WithGuideStyle(const value : TAnsiStyle) : ITree;
begin
  FGuideStyle := value;
  result := Self;
end;

function TTree.BuildPrefix(const ancestors : TArray<Boolean>;
                             isLastSibling : Boolean;
                             isLabelLine : Boolean;
                             options : TRenderOptions) : string;
var
  i            : Integer;
  contCh       : Char;
  spaceCh      : Char;
  forkCh       : Char;
  lastCh       : Char;
  horizCh      : Char;
begin
  contCh  := FGuide.GetPart(TTreeGuidePart.Continue,   options.Unicode);
  spaceCh := FGuide.GetPart(TTreeGuidePart.Space,      options.Unicode);
  forkCh  := FGuide.GetPart(TTreeGuidePart.Fork,       options.Unicode);
  lastCh  := FGuide.GetPart(TTreeGuidePart.Last,       options.Unicode);
  horizCh := FGuide.GetPart(TTreeGuidePart.Horizontal, options.Unicode);

  result := '';
  for i := 0 to High(ancestors) do
  begin
    if ancestors[i] then
      result := result + spaceCh + spaceCh + spaceCh + spaceCh
    else
      result := result + contCh + spaceCh + spaceCh + spaceCh;
  end;

  if isLabelLine then
  begin
    if isLastSibling then
      result := result + lastCh + horizCh + horizCh + spaceCh
    else
      result := result + forkCh + horizCh + horizCh + spaceCh;
  end
  else
  begin
    // Continuation line: still need to indent past the branch arm - use
    // 4 spaces for the terminating slot so it lines up with '├── ' width.
    if isLastSibling then
      result := result + spaceCh + spaceCh + spaceCh + spaceCh
    else
      result := result + contCh + spaceCh + spaceCh + spaceCh;
  end;
end;

procedure TTree.EmitNode(const node : ITreeNode;
                          const ancestorsAreLast : TArray<Boolean>;
                          isLastSibling : Boolean;
                          const options : TRenderOptions;
                          maxWidth : Integer;
                          var segs : TAnsiSegments;
                          var count : Integer;
                          const visited : TList<ITreeNode>);
var
  prefix       : string;
  contPrefix   : string;
  labelSegs    : TAnsiSegments;
  lines        : TArray<TAnsiSegments>;
  i, j, k      : Integer;
  innerWidth   : Integer;
  childAncestors : TArray<Boolean>;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(segs, count + 1);
    segs[count] := seg;
    Inc(count);
  end;

begin
  if node = nil then Exit;

  // Cycle detection - matches Spectre's CircularTreeException. If the
  // same node reference appears twice in the walk we'd loop forever.
  if visited.IndexOf(node) >= 0 then
    raise ECircularTree.Create('Cycle detected in tree - unable to render.');
  visited.Add(node);

  // Every non-root node has a fork/last prefix at its own depth.
  prefix := BuildPrefix(ancestorsAreLast, isLastSibling, True,  options);
  contPrefix := BuildPrefix(ancestorsAreLast, isLastSibling, False, options);
  innerWidth := maxWidth - CellLength(prefix);
  if innerWidth < 1 then innerWidth := 1;

  if node.Labels <> nil then
    labelSegs := node.Labels.Render(options, innerWidth)
  else
    SetLength(labelSegs, 0);
  lines := SplitLines(labelSegs, innerWidth);

  if Length(lines) = 0 then
  begin
    Push(TAnsiSegment.Text(prefix, FGuideStyle));
    Push(TAnsiSegment.LineBreak);
  end
  else
  begin
    for i := 0 to High(lines) do
    begin
      if i = 0 then
        Push(TAnsiSegment.Text(prefix, FGuideStyle))
      else
        Push(TAnsiSegment.Text(contPrefix, FGuideStyle));
      for j := 0 to High(lines[i]) do
        Push(lines[i][j]);
      Push(TAnsiSegment.LineBreak);
    end;
  end;

  // Recurse into children with the ancestors list extended by this node's
  // own isLastSibling (tells grandchildren whether our prefix column is a
  // vertical continuation or blank). When the node is collapsed (or the
  // whole tree is collapsed), skip children entirely.
  if (node.ChildCount = 0) or (not FExpanded) or (not node.Expanded) then Exit;

  SetLength(childAncestors, Length(ancestorsAreLast) + 1);
  for k := 0 to High(ancestorsAreLast) do
    childAncestors[k] := ancestorsAreLast[k];
  childAncestors[High(childAncestors)] := isLastSibling;

  for i := 0 to node.ChildCount - 1 do
    EmitNode(node.Children[i], childAncestors, i = node.ChildCount - 1,
              options, maxWidth, segs, count, visited);
end;

function TTree.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
begin
  // Not meaningful until we have a way to walk the full tree for measurement;
  // return a conservative (small, full-width) pair.
  result := TMeasurement.Create(1, maxWidth);
end;

function TTree.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  count     : Integer;
  ancestors : TArray<Boolean>;
  rootSegs  : TAnsiSegments;
  rootLines : TArray<TAnsiSegments>;
  i, j      : Integer;
  visited   : TList<ITreeNode>;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;
  if FRoot = nil then Exit;

  // 1. Emit the root label verbatim - no prefix, no ancestors.
  if FRoot.Labels <> nil then
    rootSegs := FRoot.Labels.Render(options, maxWidth)
  else
    SetLength(rootSegs, 0);
  rootLines := SplitLines(rootSegs, maxWidth);
  for i := 0 to High(rootLines) do
  begin
    for j := 0 to High(rootLines[i]) do
      Push(rootLines[i][j]);
    Push(TAnsiSegment.LineBreak);
  end;

  // 2. Emit each child with an empty ancestor list. EmitNode then does the
  // full DFS, appending isLastSibling to ancestors on each recursion.
  // If the tree is collapsed at the top level, the root label is shown by
  // itself and no children are emitted.
  if FExpanded and FRoot.Expanded then
  begin
    SetLength(ancestors, 0);
    visited := TList<ITreeNode>.Create;
    try
      visited.Add(FRoot);
      for i := 0 to FRoot.ChildCount - 1 do
        EmitNode(FRoot.Children[i], ancestors,
                  i = FRoot.ChildCount - 1,
                  options, maxWidth, result, count, visited);
    finally
      visited.Free;
    end;
  end;

  // Trim trailing line break so AnsiConsole.Write + WriteLine behaves like
  // other widgets (the caller emits its own terminator if desired).
  if (count > 0) and result[count - 1].IsLineBreak then
  begin
    SetLength(result, count - 1);
    Dec(count);
  end;
end;

function Tree(const root : IRenderable) : ITree;
begin
  result := TTree.Create(root);
end;

function Tree(const rootMarkup : string) : ITree;
begin
  result := TTree.Create(Markup(rootMarkup));
end;

end.
