unit VSoft.AnsiConsole.Prompts.MultiSelect;

{
  TMultiSelectionPrompt<T> - select zero or more items from a list.

  Usage (interface-based fluent API):

    chosen := MultiSelectionPrompt<string>
                .WithTitle('Select tags')
                .AddChoice('rust')
                .AddChoice('go')
                .AddChoice('delphi', 'Delphi')
                .Required(1)
                .Show(AnsiConsole.Console);

  Display:
    <title>
    > [x] one        <- current (highlighted) and selected
      [ ] two
      [x] three
    (press <space> to toggle, <enter> to commit)

  Keys:
    Up / Down       navigate
    Space           toggle current item's selected state
    Enter           commit; if Required(n) and count < n, re-prompt
    Escape          raise EPromptCancelled

  Returns TArray<T> of just the values that were selected.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Prompts.Common,
  VSoft.AnsiConsole.Prompts.Hierarchy,
  VSoft.AnsiConsole.Prompts.Select;  // TSelectionConverter<T>

type
  IMultiSelectionPrompt<T> = interface
    function WithTitle(const markup : string) : IMultiSelectionPrompt<T>;
    function WithInstructions(const markup : string) : IMultiSelectionPrompt<T>;
    function WithPageSize(size : Integer) : IMultiSelectionPrompt<T>;
    function WithWrap(value : Boolean) : IMultiSelectionPrompt<T>;
    function WithHighlightStyle(const value : TAnsiStyle) : IMultiSelectionPrompt<T>;
    function WithConverter(const converter : TSelectionConverter<T>) : IMultiSelectionPrompt<T>;
    function Required(min : Integer = 1) : IMultiSelectionPrompt<T>;

    { Hint shown below the visible window when items overflow the page.
      Defaults to '(Move up and down to reveal more choices)'. }
    function WithMoreChoicesText(const markup : string) : IMultiSelectionPrompt<T>;
    { Cursor positioning - sets the initial highlight to the choice
      matching `value` (uses TEqualityComparer<T>.Default). }
    function WithDefault(const value : T) : IMultiSelectionPrompt<T>;
    { When set, Esc returns this array instead of raising EPromptCancelled. }
    function WithCancelResult(const value : TArray<T>) : IMultiSelectionPrompt<T>;

    function AddChoice(const value : T) : IMultiSelectionPrompt<T>; overload;
    function AddChoice(const value : T; const display : string) : IMultiSelectionPrompt<T>; overload;
    function AddChoice(const value : T; const display : string;
                         preselected : Boolean) : IMultiSelectionPrompt<T>; overload;

    { Hierarchical choices. AddChoiceHierarchy returns an
      IMultiSelectionItem<T>. WithMode controls whether parents are
      themselves selectable (TSelectionMode.Independent) or merely expansion toggles
      (TSelectionMode.Leaf, the default). }
    function AddChoiceHierarchy(const value : T) : IMultiSelectionItem<T>; overload;
    function AddChoiceHierarchy(const value : T;
                                  const display : string) : IMultiSelectionItem<T>; overload;
    function WithMode(const value : TSelectionMode) : IMultiSelectionPrompt<T>;

    function Show(const console : IAnsiConsole) : TArray<T>;
  end;

  TMultiSelectionPrompt<T> = class(TInterfacedObject, IMultiSelectionPrompt<T>)
  strict private
    type
      TChoice = record
        Value      : T;
        Display    : string;
        Selected   : Boolean;
        Depth      : Integer;
        IsParent   : Boolean;
        IsExpanded : Boolean;
        ParentIdx  : Integer;
      end;
  private
    // Same pattern as TSelectionPrompt<T>: TMultiSelectionItem<T>
    // (declared in this same unit) reads/mutates choices via these
    // accessors so it never has to see the strict-private TChoice type.
    FConverter         : TSelectionConverter<T>;
    FChoices           : TList<TChoice>;
    function  GetChoiceValue(idx : Integer) : T;
    function  GetChoiceIsExpanded(idx : Integer) : Boolean;
    procedure SetChoiceIsExpanded(idx : Integer; value : Boolean);
    function  GetChoiceIsSelected(idx : Integer) : Boolean;
    procedure SetChoiceIsSelected(idx : Integer; value : Boolean);
    procedure SetChoiceIsParent(idx : Integer; value : Boolean);
    function  GetChoiceDepth(idx : Integer) : Integer;
    function  AddChoiceInternal(const value : T; const display : string;
                                  preselected : Boolean; depth : Integer;
                                  parentIdx : Integer) : Integer;
  strict private
    FTitle             : string;
    FInstructions      : string;
    FPageSize          : Integer;
    FWrap              : Boolean;
    FMinRequired       : Integer;
    FIndex             : Integer;
    FHighlightStyle    : TAnsiStyle;
    FMoreChoicesText   : string;
    FHasCancelResult   : Boolean;
    FCancelResult      : TArray<T>;
    FMode              : TSelectionMode;
    FHasHierarchy      : Boolean;

    function  VisibleStart : Integer;
    function  VisibleCount : Integer;
    function  SelectedCount : Integer;
    function  IsAncestorCollapsed(choiceIdx : Integer) : Boolean;
    function  IsActive(choiceIdx : Integer) : Boolean;
    function  NextActive(idx : Integer; forward : Boolean) : Integer;
    function  BuildRenderable(const errorMessage : string) : IRenderable;
    procedure ToggleCurrent;
  public
    constructor Create;
    destructor  Destroy; override;

    function WithTitle(const markup : string) : IMultiSelectionPrompt<T>;
    function WithInstructions(const markup : string) : IMultiSelectionPrompt<T>;
    function WithPageSize(size : Integer) : IMultiSelectionPrompt<T>;
    function WithWrap(value : Boolean) : IMultiSelectionPrompt<T>;
    function WithHighlightStyle(const value : TAnsiStyle) : IMultiSelectionPrompt<T>;
    function WithConverter(const converter : TSelectionConverter<T>) : IMultiSelectionPrompt<T>;
    function Required(min : Integer = 1) : IMultiSelectionPrompt<T>;
    function WithMoreChoicesText(const markup : string) : IMultiSelectionPrompt<T>;
    function WithDefault(const value : T) : IMultiSelectionPrompt<T>;
    function WithCancelResult(const value : TArray<T>) : IMultiSelectionPrompt<T>;
    function AddChoice(const value : T) : IMultiSelectionPrompt<T>; overload;
    function AddChoice(const value : T; const display : string) : IMultiSelectionPrompt<T>; overload;
    function AddChoice(const value : T; const display : string;
                         preselected : Boolean) : IMultiSelectionPrompt<T>; overload;
    function AddChoiceHierarchy(const value : T) : IMultiSelectionItem<T>; overload;
    function AddChoiceHierarchy(const value : T; const display : string) : IMultiSelectionItem<T>; overload;
    function WithMode(const value : TSelectionMode) : IMultiSelectionPrompt<T>;

    function Show(const console : IAnsiConsole) : TArray<T>;
  end;

  { Wrapper used by TMultiSelectionPrompt<T>.AddChoiceHierarchy. Same
    pattern as TSelectionItem<T> in the Select unit. }
  TMultiSelectionItem<T> = class(TInterfacedObject, IMultiSelectionItem<T>)
  strict private
    FOwner : TMultiSelectionPrompt<T>;
    FIndex : Integer;
  public
    constructor Create(const owner : TMultiSelectionPrompt<T>; index : Integer);
    function GetValue : T;
    function GetIsExpanded : Boolean;
    procedure SetIsExpanded(value : Boolean);
    function GetIsSelected : Boolean;
    procedure SetIsSelected(value : Boolean);
    function AddChild(const value : T) : IMultiSelectionItem<T>; overload;
    function AddChild(const value : T; const display : string) : IMultiSelectionItem<T>; overload;
  end;

  { Factory record - generic free functions are forbidden in Delphi XE3
    (E2530), so the public factory lives on a generic record. Usage:
    MultiSelectionPrompt<string>.Create.AddChoice(...).Show(console). }
  MultiSelectionPrompt<T> = record
    class function Create : IMultiSelectionPrompt<T>; static; inline;
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

{ MultiSelectionPrompt<T> factory record }

class function MultiSelectionPrompt<T>.Create : IMultiSelectionPrompt<T>;
begin
  result := TMultiSelectionPrompt<T>.Create;
end;

{ TMultiSelectionPrompt<T> }

constructor TMultiSelectionPrompt<T>.Create;
begin
  inherited Create;
  FChoices       := TList<TChoice>.Create;
  FPageSize      := 10;
  FWrap          := True;
  FMinRequired   := 0;
  FInstructions  := 'press <space> to toggle, <enter> to commit';
  FHighlightStyle := TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua);
  FMode           := TSelectionMode.Leaf;
  FHasHierarchy   := False;
end;

destructor TMultiSelectionPrompt<T>.Destroy;
begin
  FChoices.Free;
  inherited;
end;

function TMultiSelectionPrompt<T>.WithTitle(const markup : string) : IMultiSelectionPrompt<T>;
begin FTitle := markup; result := Self; end;

function TMultiSelectionPrompt<T>.WithInstructions(const markup : string) : IMultiSelectionPrompt<T>;
begin FInstructions := markup; result := Self; end;

function TMultiSelectionPrompt<T>.WithPageSize(size : Integer) : IMultiSelectionPrompt<T>;
begin
  if size < 1 then size := 1;
  FPageSize := size;
  result := Self;
end;

function TMultiSelectionPrompt<T>.WithWrap(value : Boolean) : IMultiSelectionPrompt<T>;
begin FWrap := value; result := Self; end;

function TMultiSelectionPrompt<T>.WithHighlightStyle(const value : TAnsiStyle) : IMultiSelectionPrompt<T>;
begin FHighlightStyle := value; result := Self; end;

function TMultiSelectionPrompt<T>.WithConverter(const converter : TSelectionConverter<T>) : IMultiSelectionPrompt<T>;
begin FConverter := converter; result := Self; end;

function TMultiSelectionPrompt<T>.Required(min : Integer) : IMultiSelectionPrompt<T>;
begin
  if min < 0 then min := 0;
  FMinRequired := min;
  result := Self;
end;

function TMultiSelectionPrompt<T>.WithMoreChoicesText(const markup : string) : IMultiSelectionPrompt<T>;
begin
  FMoreChoicesText := markup;
  result := Self;
end;

function TMultiSelectionPrompt<T>.WithDefault(const value : T) : IMultiSelectionPrompt<T>;
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

function TMultiSelectionPrompt<T>.WithCancelResult(const value : TArray<T>) : IMultiSelectionPrompt<T>;
begin
  FCancelResult    := value;
  FHasCancelResult := True;
  result := Self;
end;

function TMultiSelectionPrompt<T>.AddChoice(const value : T) : IMultiSelectionPrompt<T>;
var
  display : string;
begin
  if Assigned(FConverter) then
    display := FConverter(value)
  else
    raise Exception.Create('MultiSelectionPrompt: WithConverter is required, or use AddChoice(value, display).');
  result := AddChoice(value, display, False);
end;

function TMultiSelectionPrompt<T>.AddChoice(const value : T; const display : string) : IMultiSelectionPrompt<T>;
begin
  result := AddChoice(value, display, False);
end;

function TMultiSelectionPrompt<T>.AddChoice(const value : T; const display : string;
                                              preselected : Boolean) : IMultiSelectionPrompt<T>;
begin
  AddChoiceInternal(value, display, preselected, 0, -1);
  result := Self;
end;

function TMultiSelectionPrompt<T>.AddChoiceInternal(const value : T; const display : string;
                                                      preselected : Boolean; depth : Integer;
                                                      parentIdx : Integer) : Integer;
var
  c : TChoice;
begin
  c.Value      := value;
  c.Display    := display;
  c.Selected   := preselected;
  c.Depth      := depth;
  c.IsParent   := False;
  c.IsExpanded := True;
  c.ParentIdx  := parentIdx;
  FChoices.Add(c);
  result := FChoices.Count - 1;
end;

function TMultiSelectionPrompt<T>.GetChoiceValue(idx : Integer) : T;
begin
  result := FChoices[idx].Value;
end;

function TMultiSelectionPrompt<T>.GetChoiceIsExpanded(idx : Integer) : Boolean;
begin
  result := FChoices[idx].IsExpanded;
end;

procedure TMultiSelectionPrompt<T>.SetChoiceIsExpanded(idx : Integer; value : Boolean);
var
  c : TChoice;
begin
  c := FChoices[idx];
  c.IsExpanded := value;
  FChoices[idx] := c;
end;

function TMultiSelectionPrompt<T>.GetChoiceIsSelected(idx : Integer) : Boolean;
begin
  result := FChoices[idx].Selected;
end;

procedure TMultiSelectionPrompt<T>.SetChoiceIsSelected(idx : Integer; value : Boolean);
var
  c : TChoice;
begin
  c := FChoices[idx];
  c.Selected := value;
  FChoices[idx] := c;
end;

procedure TMultiSelectionPrompt<T>.SetChoiceIsParent(idx : Integer; value : Boolean);
var
  c : TChoice;
begin
  c := FChoices[idx];
  c.IsParent := value;
  FChoices[idx] := c;
end;

function TMultiSelectionPrompt<T>.GetChoiceDepth(idx : Integer) : Integer;
begin
  result := FChoices[idx].Depth;
end;

function TMultiSelectionPrompt<T>.AddChoiceHierarchy(const value : T) : IMultiSelectionItem<T>;
var
  display : string;
begin
  if Assigned(FConverter) then
    display := FConverter(value)
  else
    raise Exception.Create('MultiSelectionPrompt: WithConverter is required, or use AddChoiceHierarchy(value, display).');
  result := AddChoiceHierarchy(value, display);
end;

function TMultiSelectionPrompt<T>.AddChoiceHierarchy(const value : T;
                                                      const display : string) : IMultiSelectionItem<T>;
var
  idx : Integer;
begin
  FHasHierarchy := True;
  idx := AddChoiceInternal(value, display, False, 0, -1);
  result := TMultiSelectionItem<T>.Create(Self, idx);
end;

function TMultiSelectionPrompt<T>.WithMode(const value : TSelectionMode) : IMultiSelectionPrompt<T>;
begin
  FMode := value;
  result := Self;
end;

function TMultiSelectionPrompt<T>.IsAncestorCollapsed(choiceIdx : Integer) : Boolean;
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

function TMultiSelectionPrompt<T>.IsActive(choiceIdx : Integer) : Boolean;
begin
  if (choiceIdx < 0) or (choiceIdx >= FChoices.Count) then
  begin
    result := False;
    Exit;
  end;
  result := (not FHasHierarchy) or (not IsAncestorCollapsed(choiceIdx));
end;

function TMultiSelectionPrompt<T>.NextActive(idx : Integer; forward : Boolean) : Integer;
var
  step : Integer;
  i    : Integer;
begin
  if not FHasHierarchy then
  begin
    result := idx;
    Exit;
  end;
  if forward then step := 1 else step := -1;
  i := idx + step;
  while (i >= 0) and (i < FChoices.Count) do
  begin
    if IsActive(i) then
    begin
      result := i;
      Exit;
    end;
    Inc(i, step);
  end;
  result := -1;   // no active item in that direction
end;

{ TMultiSelectionItem<T> wrapper }

constructor TMultiSelectionItem<T>.Create(const owner : TMultiSelectionPrompt<T>; index : Integer);
begin
  inherited Create;
  FOwner := owner;
  FIndex := index;
end;

function TMultiSelectionItem<T>.GetValue : T;
begin
  result := FOwner.GetChoiceValue(FIndex);
end;

function TMultiSelectionItem<T>.GetIsExpanded : Boolean;
begin
  result := FOwner.GetChoiceIsExpanded(FIndex);
end;

procedure TMultiSelectionItem<T>.SetIsExpanded(value : Boolean);
begin
  FOwner.SetChoiceIsExpanded(FIndex, value);
end;

function TMultiSelectionItem<T>.GetIsSelected : Boolean;
begin
  result := FOwner.GetChoiceIsSelected(FIndex);
end;

procedure TMultiSelectionItem<T>.SetIsSelected(value : Boolean);
begin
  FOwner.SetChoiceIsSelected(FIndex, value);
end;

function TMultiSelectionItem<T>.AddChild(const value : T) : IMultiSelectionItem<T>;
var
  display : string;
begin
  if Assigned(FOwner.FConverter) then
    display := FOwner.FConverter(value)
  else
    raise Exception.Create('MultiSelectionPrompt.AddChild: WithConverter is required, or use AddChild(value, display).');
  result := AddChild(value, display);
end;

function TMultiSelectionItem<T>.AddChild(const value : T;
                                          const display : string) : IMultiSelectionItem<T>;
var
  childIdx : Integer;
begin
  FOwner.SetChoiceIsParent(FIndex, True);
  childIdx := FOwner.AddChoiceInternal(value, display, False,
                                         FOwner.GetChoiceDepth(FIndex) + 1,
                                         FIndex);
  result := TMultiSelectionItem<T>.Create(FOwner, childIdx);
end;

function TMultiSelectionPrompt<T>.VisibleStart : Integer;
var
  half : Integer;
begin
  if FChoices.Count <= FPageSize then
  begin
    result := 0;
    Exit;
  end;
  half := FPageSize div 2;
  if FIndex < half then
    result := 0
  else if FIndex >= FChoices.Count - half then
    result := FChoices.Count - FPageSize
  else
    result := FIndex - half;
end;

function TMultiSelectionPrompt<T>.VisibleCount : Integer;
begin
  result := FChoices.Count;
  if result > FPageSize then result := FPageSize;
end;

function TMultiSelectionPrompt<T>.SelectedCount : Integer;
var
  i : Integer;
begin
  result := 0;
  for i := 0 to FChoices.Count - 1 do
    if FChoices[i].Selected then
      Inc(result);
end;

procedure TMultiSelectionPrompt<T>.ToggleCurrent;
var
  c : TChoice;
begin
  if (FIndex < 0) or (FIndex >= FChoices.Count) then Exit;
  c := FChoices[FIndex];
  c.Selected := not c.Selected;
  FChoices[FIndex] := c;
end;

function TMultiSelectionPrompt<T>.BuildRenderable(const errorMessage : string) : IRenderable;
var
  rows          : IRows;
  start, vcount : Integer;
  i             : Integer;
  marker, box   : string;
  line          : IRenderable;
  remaining     : Integer;
begin
  rows := VSoft.AnsiConsole.Widgets.Rows.Rows;

  if FTitle <> '' then
    rows.Add(VSoft.AnsiConsole.Widgets.Markup.Markup(FTitle));

  start := VisibleStart;
  vcount := VisibleCount;
  for i := start to start + vcount - 1 do
  begin
    // Skip choices nested under a collapsed parent.
    if FHasHierarchy and (not IsActive(i)) then Continue;

    if i = FIndex then
      marker := '> '
    else
      marker := '  ';
    if FChoices[i].Selected then
      box := '[x] '
    else
      box := '[ ] ';
    if FHasHierarchy then
    begin
      // Indent by depth + add parent expand/collapse glyph.
      if FChoices[i].IsParent then
      begin
        if FChoices[i].IsExpanded then
          box := StringOfChar(' ', FChoices[i].Depth * 2) + #$25BE + ' ' + box   // "▾"
        else
          box := StringOfChar(' ', FChoices[i].Depth * 2) + #$25B8 + ' ' + box;  // "▸"
      end
      else
        box := StringOfChar(' ', FChoices[i].Depth * 2) + '  ' + box;
    end;
    // Route through Markup so style tags inside the Display string are
    // honoured (matches Spectre.Console). The marker / box / hierarchy
    // glyphs are all hard-coded ASCII / Unicode without '[' characters,
    // so they pass through the parser unchanged.
    if i = FIndex then
      line := VSoft.AnsiConsole.Widgets.Markup.Markup(marker + box + FChoices[i].Display, FHighlightStyle)
    else
      line := VSoft.AnsiConsole.Widgets.Markup.Markup(marker + box + FChoices[i].Display);
    rows.Add(line);
  end;

  remaining := FChoices.Count - (start + vcount);
  if remaining > 0 then
  begin
    if FMoreChoicesText <> '' then
      rows.Add(VSoft.AnsiConsole.Widgets.Markup.Markup(FMoreChoicesText))
    else
      rows.Add(VSoft.AnsiConsole.Widgets.Text.Text('  (' + IntToStr(remaining) + ' more)'));
  end;

  if FInstructions <> '' then
    rows.Add(VSoft.AnsiConsole.Widgets.Markup.Markup('[grey]' + FInstructions + '[/]'));

  if errorMessage <> '' then
    rows.Add(VSoft.AnsiConsole.Widgets.Markup.Markup('[red]' + errorMessage + '[/]'));

  result := rows;
end;

function TMultiSelectionPrompt<T>.Show(const console : IAnsiConsole) : TArray<T>;
var
  display   : ILiveDisplayConfig;
  cancelled : Boolean;
  committed : Boolean;
  initial   : IRenderable;
  i, outIdx : Integer;
begin
  SetLength(result, 0);
  if FChoices.Count = 0 then
    raise EPromptCancelled.Create('MultiSelectionPrompt has no choices');

  cancelled := False;
  committed := False;

  initial := BuildRenderable('');
  display := LiveDisplay(console, initial).WithAutoClear(True);
  display.Start(
    procedure(const ctx : ILiveDisplay)
    var
      key    : TConsoleKeyInfo;
      done   : Boolean;
      errMsg : string;
    begin
      done := False;
      errMsg := '';
      while not done do
      begin
        key := console.Input.ReadKey(True);
        errMsg := '';  // clear stale error on any movement keypress
        case key.Key of
          TConsoleKey.UpArrow:
          begin
            if FHasHierarchy then
            begin
              if NextActive(FIndex, False) >= 0 then
                FIndex := NextActive(FIndex, False)
              else if FWrap then
              begin
                // Find the LAST active item.
                FIndex := FChoices.Count - 1;
                while (FIndex >= 0) and (not IsActive(FIndex)) do Dec(FIndex);
                if FIndex < 0 then Continue;
              end
              else
                Continue;
            end
            else
            begin
              if FIndex > 0 then
                Dec(FIndex)
              else if FWrap then
                FIndex := FChoices.Count - 1
              else
                Continue;
            end;
            ctx.Update(BuildRenderable(errMsg));
          end;
          TConsoleKey.DownArrow:
          begin
            if FHasHierarchy then
            begin
              if NextActive(FIndex, True) >= 0 then
                FIndex := NextActive(FIndex, True)
              else if FWrap then
              begin
                FIndex := 0;
                while (FIndex < FChoices.Count) and (not IsActive(FIndex)) do Inc(FIndex);
                if FIndex >= FChoices.Count then Continue;
              end
              else
                Continue;
            end
            else
            begin
              if FIndex < FChoices.Count - 1 then
                Inc(FIndex)
              else if FWrap then
                FIndex := 0
              else
                Continue;
            end;
            ctx.Update(BuildRenderable(errMsg));
          end;
          TConsoleKey.PageUp:
          begin
            if FIndex - FPageSize < 0 then
              FIndex := 0
            else
              Dec(FIndex, FPageSize);
            ctx.Update(BuildRenderable(errMsg));
          end;
          TConsoleKey.PageDown:
          begin
            if FIndex + FPageSize > FChoices.Count - 1 then
              FIndex := FChoices.Count - 1
            else
              Inc(FIndex, FPageSize);
            ctx.Update(BuildRenderable(errMsg));
          end;
          TConsoleKey.Home:
          begin
            FIndex := 0;
            ctx.Update(BuildRenderable(errMsg));
          end;
          TConsoleKey.&End:
          begin
            FIndex := FChoices.Count - 1;
            ctx.Update(BuildRenderable(errMsg));
          end;
          TConsoleKey.Spacebar:
          begin
            // TSelectionMode.Leaf mode: Space on a parent toggles its expansion
            // rather than its selection state. Leaves still toggle.
            if FHasHierarchy and (FMode = TSelectionMode.Leaf) and FChoices[FIndex].IsParent then
              SetChoiceIsExpanded(FIndex, not FChoices[FIndex].IsExpanded)
            else
              ToggleCurrent;
            ctx.Update(BuildRenderable(errMsg));
          end;
          TConsoleKey.Enter:
          begin
            if SelectedCount >= FMinRequired then
            begin
              committed := True;
              done := True;
            end
            else
            begin
              errMsg := Format('At least %d item(s) must be selected.', [FMinRequired]);
              ctx.Update(BuildRenderable(errMsg));
            end;
          end;
          TConsoleKey.Escape:
          begin
            cancelled := True;
            done := True;
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
  if not committed then Exit;

  outIdx := 0;
  SetLength(result, SelectedCount);
  for i := 0 to FChoices.Count - 1 do
    if FChoices[i].Selected then
    begin
      result[outIdx] := FChoices[i].Value;
      Inc(outIdx);
    end;
end;

end.
