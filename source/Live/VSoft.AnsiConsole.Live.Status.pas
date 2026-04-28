unit VSoft.AnsiConsole.Live.Status;

{
  Status - animated spinner + message, displayed while the user's action
  callback runs. The action runs on the calling thread; a background
  TStatusTickerThread loops sleeping, advancing the frame index, and asking
  the underlying ILiveDisplay to refresh.

  Mirrors Spectre.Console's Status / StatusContext - the initial status
  message is supplied to Start, and the IStatus context exposes fluent
  setters for message, spinner, and spinner style plus an explicit Refresh.

  Example:

    AnsiConsole.Status
      .WithSpinner(skDots)
      .Start('[grey]Detecting...[/]',
        procedure(const ctx : IStatus)
        begin
          Sleep(1500);
          ctx.SetSpinner(skArc).SetStatus('[yellow]Initializing...[/]');
          Sleep(1500);
          ctx.SetSpinner(skRunner).SetStatus('[cyan]Calibrating...[/]');
          Sleep(1500);
        end);
}

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Live.Spinners;

type
  IStatus = interface;

  TStatusAction = reference to procedure(const ctx : IStatus);

  { Context handed to the user's Start callback. Mirrors Spectre's
    StatusContext - the user can change message, spinner, and spinner style
    on the fly, and force an immediate redraw via Refresh. The fluent
    setters return Self so multiple calls can be chained. }
  IStatus = interface
    ['{6E4F3A21-8D9C-4B0F-A7E1-5C2D1B3A4F60}']
    function GetStatus : string;
    function GetSpinner : ISpinner;
    function GetSpinnerStyle : TAnsiStyle;

    function SetStatus(const value : string) : IStatus;
    function SetSpinner(kind : TSpinnerKind) : IStatus; overload;
    function SetSpinner(const spinner : ISpinner) : IStatus; overload;
    function SetSpinnerStyle(const style : TAnsiStyle) : IStatus;

    procedure Refresh;
  end;

  IStatusConfig = interface
    ['{3F2E1D0C-9A8B-4756-8E6D-1C2B3A4D5E70}']
    function WithSpinner(kind : TSpinnerKind) : IStatusConfig; overload;
    function WithSpinner(const spinner : ISpinner) : IStatusConfig; overload;
    function WithSpinnerStyle(const style : TAnsiStyle) : IStatusConfig;
    function WithMessageStyle(const style : TAnsiStyle) : IStatusConfig;
    { When False the spinner ticker thread is suppressed - the caller
      drives redraw manually via ctx.Refresh. Default True. }
    function WithAutoRefresh(value : Boolean) : IStatusConfig;
    procedure Start(const status : string; const action : TStatusAction);
  end;

function Status(const console : IAnsiConsole) : IStatusConfig;

implementation

uses
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Markup.Parser,
  VSoft.AnsiConsole.Live.Display;

type
  { Shared mutable state. The user's action thread mutates these via the
    IStatus context; the ticker thread reads them every frame. All access
    is guarded by FLock. }
  TStatusState = class
  strict private
    FLock         : TCriticalSection;
    FStatus       : string;
    FSpinner      : ISpinner;
    FSpinnerStyle : TAnsiStyle;
  public
    constructor Create(const initialStatus : string; const initialSpinner : ISpinner;
                        const initialSpinnerStyle : TAnsiStyle);
    destructor  Destroy; override;
    function  GetStatus : string;
    procedure SetStatus(const value : string);
    function  GetSpinner : ISpinner;
    procedure SetSpinner(const value : ISpinner);
    function  GetSpinnerStyle : TAnsiStyle;
    procedure SetSpinnerStyle(const value : TAnsiStyle);
  end;

  { Renders "[spinner] message". Pulls spinner / spinner style / message
    from the shared state on each render so changes from the user's
    thread show up on the next ticker frame (or Refresh). }
  TStatusFrameRenderable = class(TInterfacedObject, IRenderable)
  strict private
    FFrameIdx     : Integer;
    FState        : TStatusState;
    FMessageStyle : TAnsiStyle;
  public
    constructor Create(frameIdx : Integer; const state : TStatusState;
                        const messageStyle : TAnsiStyle);
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
  end;

  TStatusTickerThread = class(TThread)
  strict private
    FDisplay      : ILiveDisplay;
    FState        : TStatusState;
    FMessageStyle : TAnsiStyle;
    FFrameIdx     : Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const display : ILiveDisplay; const state : TStatusState;
                        const messageStyle : TAnsiStyle);
  end;

  TStatusImpl = class(TInterfacedObject, IStatus, IStatusConfig)
  strict private
    FConsole      : IAnsiConsole;
    FState        : TStatusState;
    FSpinner      : ISpinner;
    FSpinnerStyle : TAnsiStyle;
    FMessageStyle : TAnsiStyle;
    FAutoRefresh  : Boolean;
    FDisplay      : ILiveDisplay;
  public
    constructor Create(const console : IAnsiConsole);
    destructor  Destroy; override;

    { IStatus }
    function GetStatus : string;
    function GetSpinner : ISpinner;
    function GetSpinnerStyle : TAnsiStyle;
    function SetStatus(const value : string) : IStatus;
    function SetSpinner(kind : TSpinnerKind) : IStatus; overload;
    function SetSpinner(const spinner : ISpinner) : IStatus; overload;
    function SetSpinnerStyle(const style : TAnsiStyle) : IStatus;
    procedure Refresh;

    { IStatusConfig }
    function WithSpinner(kind : TSpinnerKind) : IStatusConfig; overload;
    function WithSpinner(const spinner : ISpinner) : IStatusConfig; overload;
    function WithSpinnerStyle(const style : TAnsiStyle) : IStatusConfig;
    function WithMessageStyle(const style : TAnsiStyle) : IStatusConfig;
    function WithAutoRefresh(value : Boolean) : IStatusConfig;
    procedure Start(const status : string; const action : TStatusAction);
  end;

function Status(const console : IAnsiConsole) : IStatusConfig;
begin
  result := TStatusImpl.Create(console);
end;

{ TStatusState }

constructor TStatusState.Create(const initialStatus : string; const initialSpinner : ISpinner;
                                  const initialSpinnerStyle : TAnsiStyle);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FStatus := initialStatus;
  FSpinner := initialSpinner;
  FSpinnerStyle := initialSpinnerStyle;
end;

destructor TStatusState.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TStatusState.GetStatus : string;
begin
  FLock.Enter;
  try
    result := FStatus;
  finally
    FLock.Leave;
  end;
end;

procedure TStatusState.SetStatus(const value : string);
begin
  FLock.Enter;
  try
    FStatus := value;
  finally
    FLock.Leave;
  end;
end;

function TStatusState.GetSpinner : ISpinner;
begin
  FLock.Enter;
  try
    result := FSpinner;
  finally
    FLock.Leave;
  end;
end;

procedure TStatusState.SetSpinner(const value : ISpinner);
begin
  FLock.Enter;
  try
    if value <> nil then
      FSpinner := value;
  finally
    FLock.Leave;
  end;
end;

function TStatusState.GetSpinnerStyle : TAnsiStyle;
begin
  FLock.Enter;
  try
    result := FSpinnerStyle;
  finally
    FLock.Leave;
  end;
end;

procedure TStatusState.SetSpinnerStyle(const value : TAnsiStyle);
begin
  FLock.Enter;
  try
    FSpinnerStyle := value;
  finally
    FLock.Leave;
  end;
end;

{ TStatusFrameRenderable }

constructor TStatusFrameRenderable.Create(frameIdx : Integer; const state : TStatusState;
                                            const messageStyle : TAnsiStyle);
begin
  inherited Create;
  FFrameIdx := frameIdx;
  FState := state;
  FMessageStyle := messageStyle;
end;

function TStatusFrameRenderable.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
begin
  result := TMeasurement.Create(1, maxWidth);
end;

function TStatusFrameRenderable.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  msg          : string;
  msgSegs      : TAnsiSegments;
  spinner      : ISpinner;
  spinnerStyle : TAnsiStyle;
  count        : Integer;
  i            : Integer;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;

  spinner := FState.GetSpinner;
  spinnerStyle := FState.GetSpinnerStyle;

  Push(TAnsiSegment.Text(spinner.Frame(FFrameIdx), spinnerStyle));
  Push(TAnsiSegment.Text(' '));

  // Message goes through the markup parser so users can write things like
  // '[yellow]Processing...[/]'. FMessageStyle is the base style the parsed
  // segments combine on top of.
  msg := FState.GetStatus;
  msgSegs := ParseMarkup(msg, FMessageStyle);
  for i := 0 to High(msgSegs) do
    Push(msgSegs[i]);
end;

{ TStatusTickerThread }

constructor TStatusTickerThread.Create(const display : ILiveDisplay; const state : TStatusState;
                                        const messageStyle : TAnsiStyle);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FDisplay      := display;
  FState        := state;
  FMessageStyle := messageStyle;
  FFrameIdx     := 0;
end;

procedure TStatusTickerThread.Execute;
var
  frame    : IRenderable;
  interval : Integer;
begin
  while not Terminated do
  begin
    interval := FState.GetSpinner.IntervalMs;
    Sleep(interval);
    if Terminated then Break;
    Inc(FFrameIdx);
    frame := TStatusFrameRenderable.Create(FFrameIdx, FState, FMessageStyle);
    FDisplay.Update(frame);
  end;
end;

{ TStatusImpl }

constructor TStatusImpl.Create(const console : IAnsiConsole);
begin
  inherited Create;
  FConsole := console;
  FSpinner := Spinner(TSpinnerKind.Dots, console.Profile.Capabilities.Unicode);
  FSpinnerStyle := TAnsiStyle.Plain.WithForeground(TAnsiColor.Yellow);
  FMessageStyle := TAnsiStyle.Plain;
  FAutoRefresh := True;
end;

destructor TStatusImpl.Destroy;
begin
  FState.Free;
  inherited;
end;

{ IStatus }

function TStatusImpl.GetStatus : string;
begin
  if FState <> nil then
    result := FState.GetStatus
  else
    result := '';
end;

function TStatusImpl.GetSpinner : ISpinner;
begin
  if FState <> nil then
    result := FState.GetSpinner
  else
    result := FSpinner;
end;

function TStatusImpl.GetSpinnerStyle : TAnsiStyle;
begin
  if FState <> nil then
    result := FState.GetSpinnerStyle
  else
    result := FSpinnerStyle;
end;

function TStatusImpl.SetStatus(const value : string) : IStatus;
begin
  if FState <> nil then
    FState.SetStatus(value);
  result := Self;
end;

function TStatusImpl.SetSpinner(kind : TSpinnerKind) : IStatus;
begin
  result := SetSpinner(Spinner(kind, FConsole.Profile.Capabilities.Unicode));
end;

function TStatusImpl.SetSpinner(const spinner : ISpinner) : IStatus;
begin
  if (FState <> nil) and (spinner <> nil) then
    FState.SetSpinner(spinner);
  result := Self;
end;

function TStatusImpl.SetSpinnerStyle(const style : TAnsiStyle) : IStatus;
begin
  if FState <> nil then
    FState.SetSpinnerStyle(style);
  result := Self;
end;

procedure TStatusImpl.Refresh;
begin
  if FDisplay <> nil then
    FDisplay.Refresh;
end;

{ IStatusConfig }

function TStatusImpl.WithSpinner(kind : TSpinnerKind) : IStatusConfig;
begin
  FSpinner := Spinner(kind, FConsole.Profile.Capabilities.Unicode);
  result := Self;
end;

function TStatusImpl.WithSpinner(const spinner : ISpinner) : IStatusConfig;
begin
  if spinner <> nil then
    FSpinner := spinner;
  result := Self;
end;

function TStatusImpl.WithSpinnerStyle(const style : TAnsiStyle) : IStatusConfig;
begin
  FSpinnerStyle := style;
  result := Self;
end;

function TStatusImpl.WithMessageStyle(const style : TAnsiStyle) : IStatusConfig;
begin
  FMessageStyle := style;
  result := Self;
end;

function TStatusImpl.WithAutoRefresh(value : Boolean) : IStatusConfig;
begin
  FAutoRefresh := value;
  result := Self;
end;

procedure TStatusImpl.Start(const status : string; const action : TStatusAction);
var
  display     : ILiveDisplayConfig;
  ticker      : TStatusTickerThread;
  statusFrame : IRenderable;
begin
  FState := TStatusState.Create(status, FSpinner, FSpinnerStyle);

  statusFrame := TStatusFrameRenderable.Create(0, FState, FMessageStyle);
  display := LiveDisplay(FConsole, statusFrame).WithAutoClear(True);

  if FAutoRefresh then
    display.Start(
      procedure(const ctx : ILiveDisplay)
      begin
        FDisplay := ctx;
        try
          ticker := TStatusTickerThread.Create(ctx, FState, FMessageStyle);
          try
            ticker.Start;
            try
              if Assigned(action) then
                action(Self);
            finally
              ticker.Terminate;
              ticker.WaitFor;
            end;
          finally
            ticker.Free;
          end;
        finally
          FDisplay := nil;
        end;
      end)
  else
    // Caller drives redraw manually via ctx.Refresh. The live display
    // still wraps the action so output is bracketed correctly, but no
    // animation ticker fires.
    display.Start(
      procedure(const ctx : ILiveDisplay)
      begin
        FDisplay := ctx;
        try
          if Assigned(action) then
            action(Self);
        finally
          FDisplay := nil;
        end;
      end);
end;

end.
