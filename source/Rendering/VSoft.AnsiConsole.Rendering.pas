unit VSoft.AnsiConsole.Rendering;

{
  Core rendering abstractions.

  IRenderable  - interface implemented by every widget.
  TRenderOptions - snapshot of terminal capabilities passed to render calls.
  IRenderHook  - transform items before they are rendered.
  IRenderPipeline - collection of hooks applied in order.

  The flow for a top-level write is:
    1. Ask the console for its profile -> build TRenderOptions.
    2. Hand the [item] to the pipeline -> Process() returns transformed items.
    3. For each item, call Measure then Render.
    4. Feed the returned segments to the AnsiWriter.
}

interface

uses
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement;

type
  TRenderOptions = record
  strict private
    FWidth           : Integer;
    FHeight          : Integer;
    FColorSystem     : TColorSystem;
    FIsLegacyConsole : Boolean;
    FUnicode         : Boolean;
    FInteractive     : Boolean;
    FSupportsLinks   : Boolean;
  public
    class function Create(width, height : Integer; colorSystem : TColorSystem) : TRenderOptions; static;

    function WithWidth(value : Integer) : TRenderOptions;
    function WithHeight(value : Integer) : TRenderOptions;
    function WithLegacyConsole(value : Boolean) : TRenderOptions;
    function WithUnicode(value : Boolean) : TRenderOptions;
    function WithInteractive(value : Boolean) : TRenderOptions;
    function WithSupportsLinks(value : Boolean) : TRenderOptions;

    property Width           : Integer      read FWidth;
    property Height          : Integer      read FHeight;
    property ColorSystem     : TColorSystem read FColorSystem;
    property IsLegacyConsole : Boolean      read FIsLegacyConsole;
    property Unicode         : Boolean      read FUnicode;
    property Interactive     : Boolean      read FInteractive;
    property SupportsLinks   : Boolean      read FSupportsLinks;
  end;

  IRenderable = interface
    ['{5BA2DEE1-73B6-4E11-9B66-C0C4B4E5C2E7}']
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
  end;

  TRenderables = TArray<IRenderable>;

  IRenderHook = interface
    ['{6711EE42-2A69-4CEB-9CAA-28B2C3C6AAD3}']
    function Process(const options : TRenderOptions; const items : TRenderables) : TRenderables;
  end;

  IRenderPipeline = interface
    ['{7B3F8A95-FF2A-4F09-8CBE-48FD4ED67CDF}']
    procedure Attach(const hook : IRenderHook);
    procedure Detach(const hook : IRenderHook);
    function  Process(const options : TRenderOptions; const items : TRenderables) : TRenderables;
  end;

function CreateRenderPipeline : IRenderPipeline;

implementation

type
  TRenderPipeline = class(TInterfacedObject, IRenderPipeline)
  strict private
    FHooks : TArray<IRenderHook>;
  public
    procedure Attach(const hook : IRenderHook);
    procedure Detach(const hook : IRenderHook);
    function  Process(const options : TRenderOptions; const items : TRenderables) : TRenderables;
  end;

{ TRenderOptions }

class function TRenderOptions.Create(width, height : Integer; colorSystem : TColorSystem) : TRenderOptions;
begin
  result.FWidth           := width;
  result.FHeight          := height;
  result.FColorSystem     := colorSystem;
  result.FIsLegacyConsole := False;
  result.FUnicode         := True;
  result.FInteractive     := True;
  result.FSupportsLinks   := False;
end;

function TRenderOptions.WithWidth(value : Integer) : TRenderOptions;
begin
  result := Self;
  result.FWidth := value;
end;

function TRenderOptions.WithHeight(value : Integer) : TRenderOptions;
begin
  result := Self;
  result.FHeight := value;
end;

function TRenderOptions.WithLegacyConsole(value : Boolean) : TRenderOptions;
begin
  result := Self;
  result.FIsLegacyConsole := value;
end;

function TRenderOptions.WithUnicode(value : Boolean) : TRenderOptions;
begin
  result := Self;
  result.FUnicode := value;
end;

function TRenderOptions.WithInteractive(value : Boolean) : TRenderOptions;
begin
  result := Self;
  result.FInteractive := value;
end;

function TRenderOptions.WithSupportsLinks(value : Boolean) : TRenderOptions;
begin
  result := Self;
  result.FSupportsLinks := value;
end;

{ TRenderPipeline }

procedure TRenderPipeline.Attach(const hook : IRenderHook);
begin
  SetLength(FHooks, Length(FHooks) + 1);
  FHooks[High(FHooks)] := hook;
end;

procedure TRenderPipeline.Detach(const hook : IRenderHook);
var
  i, j : Integer;
  keep : TArray<IRenderHook>;
begin
  SetLength(keep, Length(FHooks));
  j := 0;
  for i := 0 to High(FHooks) do
  begin
    if FHooks[i] <> hook then
    begin
      keep[j] := FHooks[i];
      Inc(j);
    end;
  end;
  SetLength(keep, j);
  FHooks := keep;
end;

function TRenderPipeline.Process(const options : TRenderOptions; const items : TRenderables) : TRenderables;
var
  i : Integer;
begin
  result := items;
  for i := 0 to High(FHooks) do
    result := FHooks[i].Process(options, result);
end;

function CreateRenderPipeline : IRenderPipeline;
begin
  result := TRenderPipeline.Create;
end;

end.
