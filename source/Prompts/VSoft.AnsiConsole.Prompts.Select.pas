unit VSoft.AnsiConsole.Prompts.Select;

{
  TSelectionPrompt<T> - a single-selection list with arrow-key navigation.

  Usage (interface-based fluent API):

    chosen := SelectionPrompt<string>
                .WithTitle('Pick an environment')
                .AddChoice('dev')
                .AddChoice('staging')
                .AddChoice('production')
                .WithDefault('staging')
                .Show(AnsiConsole.Console);

  Display:
    <title>
      one
    > two        <- highlighted
      three
      (10 more)

  Keys:
    Up / Down       navigate one item (wraps unless WithWrap(False))
    PageUp/PageDown jump by page size
    Home / End      go to first / last
    Enter           commit current item, return its value
    Escape          raise EPromptCancelled

  AddChoice(value) requires WithConverter to be set; for the common
  string case use AddChoice(value, display) to provide an explicit
  display string.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Prompts.Common,
  VSoft.AnsiConsole.Prompts.Hierarchy;

type
  TSelectionConverter<T> = reference to function(const value : T) : string;

  ISelectionPrompt<T> = interface
    function WithTitle(const markup : string) : ISelectionPrompt<T>;
    function WithPageSize(size : Integer) : ISelectionPrompt<T>;
    function WithWrap(value : Boolean) : ISelectionPrompt<T>;
    function WithHighlightStyle(const value : TAnsiStyle) : ISelectionPrompt<T>;
    function WithMoreChoicesText(const markup : string) : ISelectionPrompt<T>;
    function WithConverter(const converter : TSelectionConverter<T>) : ISelectionPrompt<T>;
    function WithDefault(const value : T) : ISelectionPrompt<T>;

    { Search-as-you-type. When enabled, letter/digit keys append to a
      buffer and the visible list filters to choices whose display text
      contains the buffer (case-insensitive). Backspace pops a char. }
    function WithSearchEnabled(value : Boolean) : ISelectionPrompt<T>;
    function WithSearchPlaceholderText(const markup : string) : ISelectionPrompt<T>;
    function WithSearchHighlightStyle(const value : TAnsiStyle) : ISelectionPrompt<T>;

    { Style applied to disabled choices. Use the third AddChoice overload
      to mark a choice disabled. Disabled items are skipped over by Enter
      (no-op) but cursor still navigates through them. }
    function WithDisabledStyle(const value : TAnsiStyle) : ISelectionPrompt<T>;
    function AddChoice(const value : T; const display : string;
                        disabled : Boolean) : ISelectionPrompt<T>; overload;

    { When set, Esc returns this value instead of raising EPromptCancelled. }
    function WithCancelResult(const value : T) : ISelectionPrompt<T>;

    function AddChoice(const value : T) : ISelectionPrompt<T>; overload;
    function AddChoice(const value : T; const display : string) : ISelectionPrompt<T>; overload;

    { Hierarchical choices. Returns an ISelectionItem<T> on which the
      caller can call AddChild to nest further. Mode controls whether
      parents are themselves selectable (TSelectionMode.Independent) or merely
      expansion toggles (TSelectionMode.Leaf, the default). }
    function AddChoiceHierarchy(const value : T) : ISelectionItem<T>; overload;
    function AddChoiceHierarchy(const value : T;
                                  const display : string) : ISelectionItem<T>; overload;
    function WithMode(value : TSelectionMode) : ISelectionPrompt<T>;

    function Show(const console : IAnsiConsole) : T;
  end;

  TSelectionPrompt<T> = class(TInterfacedObject, ISelectionPrompt<T>)
  strict private
    type
      TChoice = record
        Value      : T;
        Display    : string;
        Disabled   : Boolean;
        Depth      : Integer;
        IsParent   : Boolean;
        IsExpanded : Boolean;
        ParentIdx  : Integer;   // -1 for top-level
      end;
  private
    // FConverter and the GetChoice*/SetChoice*/AddChoiceInternal helpers
    // are private (not strict) so the TSelectionItem<T> wrapper declared
    // in this same unit can read/mutate choices without seeing the
    // strict-private TChoice type.
    FConverter             : TSelectionConverter<T>;
    FChoices               : TList<TChoice>;
    function  GetChoiceValue(idx : Integer) : T;
    function  GetChoiceIsExpanded(idx : Integer) : Boolean;
    procedure SetChoiceIsExpanded(idx : Integer; value : Boolean);
    procedure SetChoiceIsParent(idx : Integer; value : Boolean);
    function  GetChoiceDepth(idx : Integer) : Integer;
    function  AddChoiceInternal(const value : T; const display : string;
                                  disabled : Boolean; depth : Integer;
                                  parentIdx : Integer) : Integer;
  strict private
    FTitle                 : string;
    FFilteredIndices       : TArray<Integer>;
    FPageSize              : Integer;
    FWrap                  : Boolean;
    FIndex                 : Integer;
    FHighlightStyle        : TAnsiStyle;
    FDisabledStyle         : TAnsiStyle;
    FSearchHighlightStyle  : TAnsiStyle;
    FMoreChoicesText       : string;
    FSearchEnabled         : Boolean;
    FSearchBuffer          : string;
    FSearchPlaceholderText : string;
    FHasCancelResult       : Boolean;
    FCancelResult          : T;
    FMode                  : TSelectionMode;
    FHasHierarchy          : Boolean;

    function  VisibleStart : Integer;
    function  VisibleCount : Integer;
    function  ActiveCount : Integer;
    function  ActiveIndex(visibleIndex : Integer) : Integer;
    function  IsAncestorCollapsed(choiceIdx : Integer) : Boolean;
    procedure RefreshFilter;
    function  BuildRenderable : IRenderable;
  public
    constructor Create;
    destructor  Destroy; override;

    function WithTitle(const markup : string) : ISelectionPrompt<T>;
    function WithPageSize(size : Integer) : ISelectionPrompt<T>;
    function WithWrap(value : Boolean) : ISelectionPrompt<T>;
    function WithHighlightStyle(const value : TAnsiStyle) : ISelectionPrompt<T>;
    function WithMoreChoicesText(const markup : string) : ISelectionPrompt<T>;
    function WithConverter(const converter : TSelectionConverter<T>) : ISelectionPrompt<T>;
    function WithDefault(const value : T) : ISelectionPrompt<T>;
    function WithSearchEnabled(value : Boolean) : ISelectionPrompt<T>;
    function WithSearchPlaceholderText(const markup : string) : ISelectionPrompt<T>;
    function WithSearchHighlightStyle(const value : TAnsiStyle) : ISelectionPrompt<T>;
    function WithDisabledStyle(const value : TAnsiStyle) : ISelectionPrompt<T>;
    function WithCancelResult(const value : T) : ISelectionPrompt<T>;
    function AddChoice(const value : T) : ISelectionPrompt<T>; overload;
    function AddChoice(const value : T; const display : string) : ISelectionPrompt<T>; overload;
    function AddChoice(const value : T; const display : string;
                        disabled : Boolean) : ISelectionPrompt<T>; overload;
    function AddChoiceHierarchy(const value : T) : ISelectionItem<T>; overload;
    function AddChoiceHierarchy(const value : T; const display : string) : ISelectionItem<T>; overload;
    function WithMode(value : TSelectionMode) : ISelectionPrompt<T>;

    function Show(const console : IAnsiConsole) : T;
  end;

  { Private wrapper used by TSelectionPrompt<T>.AddChoiceHierarchy.
    Holds a back-reference to the prompt (raw pointer; the prompt outlives
    these wrappers because they're only used during the build phase) plus
    the flat-list index of the choice it represents. }
  TSelectionItem<T> = class(TInterfacedObject, ISelectionItem<T>)
  strict private
    FOwner : TSelectionPrompt<T>;
    FIndex : Integer;
  public
    constructor Create(const owner : TSelectionPrompt<T>; index : Integer);
    function GetValue : T;
    function GetIsExpanded : Boolean;
    procedure SetIsExpanded(value : Boolean);
    function AddChild(const value : T) : ISelectionItem<T>; overload;
    function AddChild(const value : T; const display : string) : ISelectionItem<T>; overload;
  end;

  { Factory record. Delphi XE3 forbids type parameters on free functions
    (E2530), so the public factory lives on a generic record instead.
    Usage:  SelectionPrompt<string>.Create.AddChoice('a').Show(console). }
  SelectionPrompt<T> = record
    class function Create : ISelectionPrompt<T>; static; inline;
  end;

implementation

uses
  System.Console.Types,
  System.Generics.Defaults,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Widgets.Text,
  VSoft.AnsiConsole.Widgets.Markup,
  VSoft.AnsiConsole.Widgets.Rows,
  VSoft.AnsiConsole.Live.Display;

{ SelectionPrompt<T> factory record }

class function SelectionPrompt<T>.Create : ISelectionPrompt<T>;
begin
  result := TSelectionPrompt<T>.Create;
end;

{ TSelectionPrompt<T> }

constructor TSelectionPrompt<T>.Create;
begin
  inherited Create;
  FChoices  := TList<TChoice>.Create;
  FPageSize := 10;
  FWrap     := True;
  FIndex    := 0;
  FHighlightStyle        := TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua);
  FDisabledStyle         := TAnsiStyle.Plain.WithForeground(TAnsiColor.Grey);
  FSearchHighlightStyle  := TAnsiStyle.Plain.WithForeground(TAnsiColor.Yellow);
  FMoreChoicesText       := '';
  FSearchEnabled         := False;
  FSearchBuffer          := '';
  FSearchPlaceholderText := '(Type to search)';
  FHasCancelResult       := False;
  FMode                  := TSelectionMode.Leaf;
  FHasHierarchy          := False;
end;

destructor TSelectionPrompt<T>.Destroy;
begin
  FChoices.Free;
  inherited;
end;

function TSelectionPrompt<T>.WithTitle(const markup : string) : ISelectionPrompt<T>;
begin
  FTitle := markup;
  result := Self;
end;

function TSelectionPrompt<T>.WithPageSize(size : Integer) : ISelectionPrompt<T>;
begin
  if size < 1 then size := 1;
  FPageSize := size;
  result := Self;
end;

function TSelectionPrompt<T>.WithWrap(value : Boolean) : ISelectionPrompt<T>;
begin
  FWrap := value;
  result := Self;
end;

function TSelectionPrompt<T>.WithHighlightStyle(const value : TAnsiStyle) : ISelectionPrompt<T>;
begin
  FHighlightStyle := value;
  result := Self;
end;

function TSelectionPrompt<T>.WithMoreChoicesText(const markup : string) : ISelectionPrompt<T>;
begin
  FMoreChoicesText := markup;
  result := Self;
end;

function TSelectionPrompt<T>.WithConverter(const converter : TSelectionConverter<T>) : ISelectionPrompt<T>;
begin
  FConverter := converter;
  result := Self;
end;

function TSelectionPrompt<T>.WithDefault(const value : T) : ISelectionPrompt<T>;
var
  cmp : IEqualityComparer<T>;
  i   : Integer;
begin
  cmp := TEqualityComparer<T>.Default;
  for i := 0 to FChoices.Count - 1 do
    if cmp.Equals(FChoices[i].Value, value) then
    begin
      FIndex := i;
      Break;
    end;
  result := Self;
end;

function TSelectionPrompt<T>.AddChoice(const value : T) : ISelectionPrompt<T>;
var
  display : string;
begin
  if Assigned(FConverter) then
    display := FConverter(value)
  else
    raise Exception.Create('SelectionPrompt: WithConverter is required, or use AddChoice(value, display).');
  result := AddChoice(value, display, False);
end;

function TSelectionPrompt<T>.AddChoice(const value : T; const display : string) : ISelectionPrompt<T>;
begin
  result := AddChoice(value, display, False);
end;

function TSelectionPrompt<T>.AddChoice(const value : T; const display : string;
                                         disabled : Boolean) : ISelectionPrompt<T>;
begin
  AddChoiceInternal(value, display, disabled, 0, -1);
  result := Self;
end;

function TSelectionPrompt<T>.AddChoiceInternal(const value : T; const display : string;
                                                disabled : Boolean; depth : Integer;
                                                parentIdx : Integer) : Integer;
var
  c : TChoice;
begin
  c.Value      := value;
  c.Display    := display;
  c.Disabled   := disabled;
  c.Depth      := depth;
  c.IsParent   := False;
  c.IsExpanded := True;
  c.ParentIdx  := parentIdx;
  FChoices.Add(c);
  result := FChoices.Count - 1;
end;

function TSelectionPrompt<T>.AddChoiceHierarchy(const value : T) : ISelectionItem<T>;
var
  display : string;
begin
  if Assigned(FConverter) then
    display := FConverter(value)
  else
    raise Exception.Create('SelectionPrompt: WithConverter is required, or use AddChoiceHierarchy(value, display).');
  result := AddChoiceHierarchy(value, display);
end;

function TSelectionPrompt<T>.AddChoiceHierarchy(const value : T;
                                                  const display : string) : ISelectionItem<T>;
var
  idx : Integer;
begin
  FHasHierarchy := True;
  idx := AddChoiceInternal(value, display, False, 0, -1);
  result := TSelectionItem<T>.Create(Self, idx);
end;

function TSelectionPrompt<T>.WithMode(value : TSelectionMode) : ISelectionPrompt<T>;
begin
  FMode := value;
  result := Self;
end;

function TSelectionPrompt<T>.GetChoiceValue(idx : Integer) : T;
begin
  result := FChoices[idx].Value;
end;

function TSelectionPrompt<T>.GetChoiceIsExpanded(idx : Integer) : Boolean;
begin
  result := FChoices[idx].IsExpanded;
end;

procedure TSelectionPrompt<T>.SetChoiceIsExpanded(idx : Integer; value : Boolean);
var
  c : TChoice;
begin
  c := FChoices[idx];
  c.IsExpanded := value;
  FChoices[idx] := c;
end;

procedure TSelectionPrompt<T>.SetChoiceIsParent(idx : Integer; value : Boolean);
var
  c : TChoice;
begin
  c := FChoices[idx];
  c.IsParent := value;
  FChoices[idx] := c;
end;

function TSelectionPrompt<T>.GetChoiceDepth(idx : Integer) : Integer;
begin
  result := FChoices[idx].Depth;
end;

function TSelectionPrompt<T>.IsAncestorCollapsed(choiceIdx : Integer) : Boolean;
var
  cur : Integer;
begin
  cur := FChoices[choiceIdx].ParentIdx;
  while cur >= 0 do
  begin
    if not FChoices[cur].IsExpanded then
    begin
      result := True;
      Exit;
    end;
    cur := FChoices[cur].ParentIdx;
  end;
  result := False;
end;

{ TSelectionItem<T> wrapper }

constructor TSelectionItem<T>.Create(const owner : TSelectionPrompt<T>; index : Integer);
begin
  inherited Create;
  FOwner := owner;
  FIndex := index;
end;

function TSelectionItem<T>.GetValue : T;
begin
  result := FOwner.GetChoiceValue(FIndex);
end;

function TSelectionItem<T>.GetIsExpanded : Boolean;
begin
  result := FOwner.GetChoiceIsExpanded(FIndex);
end;

procedure TSelectionItem<T>.SetIsExpanded(value : Boolean);
begin
  FOwner.SetChoiceIsExpanded(FIndex, value);
end;

function TSelectionItem<T>.AddChild(const value : T) : ISelectionItem<T>;
var
  display : string;
begin
  if Assigned(FOwner.FConverter) then
    display := FOwner.FConverter(value)
  else
    raise Exception.Create('SelectionPrompt.AddChild: WithConverter is required, or use AddChild(value, display).');
  result := AddChild(value, display);
end;

function TSelectionItem<T>.AddChild(const value : T;
                                      const display : string) : ISelectionItem<T>;
var
  childIdx : Integer;
begin
  // Mark parent as a parent (idempotent).
  FOwner.SetChoiceIsParent(FIndex, True);
  childIdx := FOwner.AddChoiceInternal(value, display, False,
                                         FOwner.GetChoiceDepth(FIndex) + 1,
                                         FIndex);
  result := TSelectionItem<T>.Create(FOwner, childIdx);
end;

function TSelectionPrompt<T>.WithSearchEnabled(value : Boolean) : ISelectionPrompt<T>;
begin
  FSearchEnabled := value;
  result := Self;
end;

function TSelectionPrompt<T>.WithSearchPlaceholderText(const markup : string) : ISelectionPrompt<T>;
begin
  FSearchPlaceholderText := markup;
  result := Self;
end;

function TSelectionPrompt<T>.WithSearchHighlightStyle(const value : TAnsiStyle) : ISelectionPrompt<T>;
begin
  FSearchHighlightStyle := value;
  result := Self;
end;

function TSelectionPrompt<T>.WithDisabledStyle(const value : TAnsiStyle) : ISelectionPrompt<T>;
begin
  FDisabledStyle := value;
  result := Self;
end;

function TSelectionPrompt<T>.WithCancelResult(const value : T) : ISelectionPrompt<T>;
begin
  FCancelResult    := value;
  FHasCancelResult := True;
  result := Self;
end;

{ Recompute FFilteredIndices based on FSearchBuffer. When the buffer is
  empty (or search is disabled) every choice is included. The filter is
  case-insensitive substring on each choice's display string. FIndex is
  clamped to the new range so navigation stays valid after a filter
  change. }
procedure TSelectionPrompt<T>.RefreshFilter;
var
  i, n : Integer;
  needle, hay : string;
  matchesSearch : Boolean;
begin
  // Two filters apply: the search buffer (case-insensitive substring)
  // AND the hierarchy collapse state (children of any collapsed parent
  // are excluded). Both are computed in one pass.
  SetLength(FFilteredIndices, FChoices.Count);
  needle := LowerCase(FSearchBuffer);
  n := 0;
  for i := 0 to FChoices.Count - 1 do
  begin
    if FHasHierarchy and IsAncestorCollapsed(i) then Continue;
    if FSearchEnabled and (FSearchBuffer <> '') then
    begin
      hay := LowerCase(FChoices[i].Display);
      matchesSearch := Pos(needle, hay) > 0;
    end
    else
      matchesSearch := True;
    if matchesSearch then
    begin
      FFilteredIndices[n] := i;
      Inc(n);
    end;
  end;
  SetLength(FFilteredIndices, n);
  if FIndex >= Length(FFilteredIndices) then
    FIndex := Length(FFilteredIndices) - 1;
  if FIndex < 0 then FIndex := 0;
end;

function TSelectionPrompt<T>.ActiveCount : Integer;
begin
  result := Length(FFilteredIndices);
end;

function TSelectionPrompt<T>.ActiveIndex(visibleIndex : Integer) : Integer;
begin
  result := FFilteredIndices[visibleIndex];
end;

function TSelectionPrompt<T>.VisibleStart : Integer;
var
  half  : Integer;
  total : Integer;
begin
  total := ActiveCount;
  if total <= FPageSize then
  begin
    result := 0;
    Exit;
  end;
  half := FPageSize div 2;
  if FIndex < half then
    result := 0
  else if FIndex >= total - half then
    result := total - FPageSize
  else
    result := FIndex - half;
end;

function TSelectionPrompt<T>.VisibleCount : Integer;
begin
  result := ActiveCount;
  if result > FPageSize then result := FPageSize;
end;

function TSelectionPrompt<T>.BuildRenderable : IRenderable;
var
  rows      : IRows;
  start     : Integer;
  vcount    : Integer;
  i, ci     : Integer;
  remaining : Integer;
  line      : IRenderable;
  prefix    : string;
  searchLine : string;
  marker     : string;
  hierPrefix : string;
begin
  rows := VSoft.AnsiConsole.Widgets.Rows.Rows;

  if FTitle <> '' then
    rows.Add(VSoft.AnsiConsole.Widgets.Markup.Markup(FTitle));

  if FSearchEnabled then
  begin
    if FSearchBuffer <> '' then
      searchLine := 'Search: ' + FSearchBuffer
    else
      searchLine := 'Search: ' + FSearchPlaceholderText;
    rows.Add(VSoft.AnsiConsole.Widgets.Text.Text(searchLine).WithStyle(FSearchHighlightStyle));
  end;

  start := VisibleStart;
  vcount := VisibleCount;
  for i := start to start + vcount - 1 do
  begin
    ci := ActiveIndex(i);
    if i = FIndex then
      prefix := '> '
    else
      prefix := '  ';

    if FHasHierarchy then
    begin
      // Indent by depth (2 cells per level) and add a parent/leaf glyph.
      hierPrefix := StringOfChar(' ', FChoices[ci].Depth * 2);
      if FChoices[ci].IsParent then
      begin
        if FChoices[ci].IsExpanded then
          marker := #$25BE + ' '   // "▾"
        else
          marker := #$25B8 + ' ';  // "▸"
      end
      else
        marker := '  ';
    end
    else
    begin
      hierPrefix := '';
      marker := '';
    end;

    // Route through Markup so consumers can include style tags in the
    // Display string ("[bold]Region[/]" etc). Prefix / hierPrefix /
    // marker are all hard-coded ASCII / Unicode arrows with no '['
    // characters, so they pass through the markup parser unchanged.
    // The (source, baseStyle) overload applies the state colour as a
    // base, with tags inside the Display layering on top.
    if FChoices[ci].Disabled then
      line := VSoft.AnsiConsole.Widgets.Markup.Markup(prefix + hierPrefix + marker + FChoices[ci].Display, FDisabledStyle)
    else if i = FIndex then
      line := VSoft.AnsiConsole.Widgets.Markup.Markup(prefix + hierPrefix + marker + FChoices[ci].Display, FHighlightStyle)
    else
      line := VSoft.AnsiConsole.Widgets.Markup.Markup(prefix + hierPrefix + marker + FChoices[ci].Display);
    rows.Add(line);
  end;

  remaining := ActiveCount - (start + vcount);
  if remaining > 0 then
  begin
    if FMoreChoicesText <> '' then
      rows.Add(VSoft.AnsiConsole.Widgets.Markup.Markup(FMoreChoicesText))
    else
      rows.Add(VSoft.AnsiConsole.Widgets.Text.Text('  (' + IntToStr(remaining) + ' more)'));
  end;

  result := rows;
end;

function TSelectionPrompt<T>.Show(const console : IAnsiConsole) : T;
var
  display      : ILiveDisplayConfig;
  finalChoice  : Integer;
  cancelled    : Boolean;
  initial      : IRenderable;
begin
  if FChoices.Count = 0 then
    raise EPromptCancelled.Create('SelectionPrompt has no choices');

  RefreshFilter;
  cancelled   := False;
  finalChoice := -1;

  { Drive redraws through LiveDisplay - it handles the inflated-shape
    padding that prevents flicker on multi-line content, auto-clears
    the region on exit, and shares one ExclusivityLock with Status and
    Progress so prompts cannot overlap a live display. }
  initial := BuildRenderable;
  display := LiveDisplay(console, initial).WithAutoClear(True);
  display.Start(
    procedure(const ctx : ILiveDisplay)
    var
      key  : TConsoleKeyInfo;
      done : Boolean;
    begin
      done := False;
      while not done do
      begin
        key := console.Input.ReadKey(True);
        case key.Key of
          TConsoleKey.UpArrow:
          begin
            if ActiveCount = 0 then Continue;
            if FIndex > 0 then
              Dec(FIndex)
            else if FWrap then
              FIndex := ActiveCount - 1
            else
              Continue;
            ctx.Update(BuildRenderable);
          end;
          TConsoleKey.DownArrow:
          begin
            if ActiveCount = 0 then Continue;
            if FIndex < ActiveCount - 1 then
              Inc(FIndex)
            else if FWrap then
              FIndex := 0
            else
              Continue;
            ctx.Update(BuildRenderable);
          end;
          TConsoleKey.PageUp:
          begin
            if ActiveCount = 0 then Continue;
            if FIndex - FPageSize < 0 then
              FIndex := 0
            else
              Dec(FIndex, FPageSize);
            ctx.Update(BuildRenderable);
          end;
          TConsoleKey.PageDown:
          begin
            if ActiveCount = 0 then Continue;
            if FIndex + FPageSize > ActiveCount - 1 then
              FIndex := ActiveCount - 1
            else
              Inc(FIndex, FPageSize);
            ctx.Update(BuildRenderable);
          end;
          TConsoleKey.Home:
          begin
            if ActiveCount = 0 then Continue;
            FIndex := 0;
            ctx.Update(BuildRenderable);
          end;
          TConsoleKey.&End:
          begin
            if ActiveCount = 0 then Continue;
            FIndex := ActiveCount - 1;
            ctx.Update(BuildRenderable);
          end;
          TConsoleKey.Enter:
          begin
            // No-op when no items match the search filter, or when the
            // currently-highlighted item is disabled.
            if ActiveCount = 0 then Continue;
            if FChoices[ActiveIndex(FIndex)].Disabled then Continue;
            // In TSelectionMode.Leaf mode (Spectre default), Enter on a parent toggles
            // its expansion rather than returning. TSelectionMode.Independent always
            // returns the value of the highlighted item.
            if FHasHierarchy and (FMode = TSelectionMode.Leaf) and FChoices[ActiveIndex(FIndex)].IsParent then
            begin
              SetChoiceIsExpanded(ActiveIndex(FIndex), not FChoices[ActiveIndex(FIndex)].IsExpanded);
              RefreshFilter;
              ctx.Update(BuildRenderable);
              Continue;
            end;
            finalChoice := ActiveIndex(FIndex);
            done := True;
          end;
          TConsoleKey.Escape:
          begin
            // Esc with a non-empty search buffer clears the search
            // first; only escape the prompt itself when the buffer is
            // already empty.
            if FSearchEnabled and (FSearchBuffer <> '') then
            begin
              FSearchBuffer := '';
              RefreshFilter;
              ctx.Update(BuildRenderable);
            end
            else
            begin
              cancelled := True;
              done := True;
            end;
          end;
          TConsoleKey.Backspace:
          begin
            if FSearchEnabled and (FSearchBuffer <> '') then
            begin
              SetLength(FSearchBuffer, Length(FSearchBuffer) - 1);
              RefreshFilter;
              ctx.Update(BuildRenderable);
            end;
          end;
        else
          // Letter / digit / symbol keys append to the search buffer
          // when search is enabled and the key produces a printable
          // character.
          if FSearchEnabled and (key.KeyChar >= ' ') and (key.KeyChar <> #127) then
          begin
            FSearchBuffer := FSearchBuffer + key.KeyChar;
            FIndex := 0;
            RefreshFilter;
            ctx.Update(BuildRenderable);
          end;
        end;
      end;
    end);

  if cancelled then
  begin
    if FHasCancelResult then
    begin
      result := FCancelResult;
      Exit;
    end;
    raise EPromptCancelled.Create('Selection cancelled');
  end;
  result := FChoices[finalChoice].Value;
end;

end.
