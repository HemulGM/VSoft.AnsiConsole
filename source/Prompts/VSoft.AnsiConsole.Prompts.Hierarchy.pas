unit VSoft.AnsiConsole.Prompts.Hierarchy;

{
  Public surface for hierarchical Selection / MultiSelection prompts.

  ISelectionItem<T>      - returned by SelectionPrompt<T>.AddChoiceHierarchy;
                            consumers call AddChild to nest items.
  IMultiSelectionItem<T> - same shape, also exposes Select / IsSelected
                            for multi-selection prompts.
  TSelectionMode         - controls whether parents are themselves
                            selectable (TSelectionMode.Independent) or only leaves
                            (TSelectionMode.Leaf, the Spectre default).

  The interfaces are intentionally minimal - the prompt's internal flat
  representation does the heavy lifting. Wrapper records on the prompt
  hold a back-reference and the choice's flat-list index, so AddChild
  inserts a new entry at the right depth and updates the parent's
  IsParent/IsExpanded flags.
}

{$SCOPEDENUMS ON}

interface

type
  TSelectionMode = (
    Leaf,         // Spectre default: only leaf items selectable;
                  // parents toggle expansion on Enter.
    Independent   // every node selectable in its own right.
    );

  ISelectionItem<T> = interface
    ['{2C7F4B11-9D3E-4A8F-8B1C-7E3D5F2B9C40}']
    function GetValue : T;
    function GetIsExpanded : Boolean;
    procedure SetIsExpanded(value : Boolean);
    function AddChild(const value : T) : ISelectionItem<T>; overload;
    function AddChild(const value : T; const display : string) : ISelectionItem<T>; overload;
    property Value      : T       read GetValue;
    property IsExpanded : Boolean read GetIsExpanded write SetIsExpanded;
  end;

  IMultiSelectionItem<T> = interface
    ['{3D8F5C22-AE4F-5B9F-9C2D-8F4E6B3C0D51}']
    function GetValue : T;
    function GetIsExpanded : Boolean;
    procedure SetIsExpanded(value : Boolean);
    function GetIsSelected : Boolean;
    procedure SetIsSelected(value : Boolean);
    function AddChild(const value : T) : IMultiSelectionItem<T>; overload;
    function AddChild(const value : T; const display : string) : IMultiSelectionItem<T>; overload;
    property Value      : T       read GetValue;
    property IsExpanded : Boolean read GetIsExpanded write SetIsExpanded;
    property IsSelected : Boolean read GetIsSelected write SetIsSelected;
  end;

implementation

end.
