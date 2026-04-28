unit VSoft.AnsiConsole.Live.Progress;

{
  Multi-task progress tracker.

  Usage:
    AnsiConsole.Progress.Start(
      procedure(const ctx : IProgress)
      var
        t : IProgressTask;
      begin
        t := ctx.AddTask('Downloading', 100);
        while not t.IsFinished do
        begin
          Sleep(100);
          t.Increment(5);
        end;
      end);

  Internally each redraw builds a row per task, one column per IProgressColumn.
  A TProgressTickerThread ticks every FRefreshMs ms and triggers a refresh.

  Each task keeps a 32-entry ring buffer of (timestamp, delta) samples used
  to derive Speed (steps/sec) and RemainingMs (ETA). Samples older than
  30 seconds are ignored; the newest sample's age gates whether the speed
  estimate is still considered fresh (MaxTimeForSpeedCacheMs).

  Built-in columns:
    TDescriptionColumn     - task label (flexible/star, right-aligned)
    TProgressBarColumn     - filled/empty bar; cosine-fade pulse when indeterminate
    TPercentageColumn      - '42%'
    TElapsedColumn         - hh:mm:ss since StartTask
    TRemainingTimeColumn   - hh:mm:ss remaining (estimate)
    TSpinnerColumn         - animated spinner + pending/completed text (auto-width)
    TDownloadedColumn      - '512 KB / 1 MB' human bytes
    TransferSpeedColumn    - '256 KB/s' human rate
}

{$SCOPEDENUMS ON}

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Live.Spinners;

type
  IProgressTask = interface
    ['{9E7F2A51-0D1C-4F22-B3B6-5A4E7C8F1D80}']
    function  GetDescription : string;
    procedure SetDescription(const value : string);
    function  GetValue : Double;
    procedure SetValue(value : Double);
    function  GetMaxValue : Double;
    procedure SetMaxValue(value : Double);
    function  GetPercentage : Double;
    function  GetSpeed : Double;
    function  GetRemainingMs : Int64;
    function  GetIsStarted : Boolean;
    function  GetIsFinished : Boolean;
    function  GetIsIndeterminate : Boolean;
    procedure SetIsIndeterminate(value : Boolean);
    function  GetHideWhenCompleted : Boolean;
    procedure SetHideWhenCompleted(value : Boolean);
    function  GetElapsedMs : Int64;
    function  GetTag : TObject;
    procedure SetTag(const value : TObject);
    function  GetId : Integer;
    function  GetStartTime : TDateTime;
    function  GetStopTime : TDateTime;
    function  GetMaxTimeForSpeedCacheMs : Integer;
    procedure SetMaxTimeForSpeedCacheMs(value : Integer);
    function  GetMaxSamplingAgeMs : Integer;
    procedure SetMaxSamplingAgeMs(value : Integer);
    function  GetMaxSamplesKept : Integer;
    procedure SetMaxSamplesKept(value : Integer);
    procedure Increment(by : Double = 1);
    procedure StartTask;
    procedure StopTask;

    property Description       : string  read GetDescription       write SetDescription;
    property Value             : Double  read GetValue             write SetValue;
    property MaxValue          : Double  read GetMaxValue          write SetMaxValue;
    property Percentage        : Double  read GetPercentage;
    { Steps/second over a sliding window (default 30 s, configurable via
      MaxSamplingAgeMs). 0 if not enough samples. }
    property Speed             : Double  read GetSpeed;
    { Milliseconds remaining estimate. 0 when finished, -1 when unknown. }
    property RemainingMs       : Int64   read GetRemainingMs;
    property IsStarted         : Boolean read GetIsStarted;
    property IsFinished        : Boolean read GetIsFinished;
    property IsIndeterminate   : Boolean read GetIsIndeterminate   write SetIsIndeterminate;
    property HideWhenCompleted : Boolean read GetHideWhenCompleted write SetHideWhenCompleted;
    property ElapsedMs         : Int64   read GetElapsedMs;
    { User-attached object slot (not freed by the task). Mirrors
      Spectre's ProgressTask.Tag for attaching domain data to a task. }
    property Tag               : TObject read GetTag               write SetTag;
    { Sequential ID assigned at creation. Read-only. }
    property Id                : Integer read GetId;
    { Wall-clock time when the task first started (StartTask called or
      first Increment received). 0 if never started. }
    property StartTime         : TDateTime read GetStartTime;
    { Wall-clock time when the task finished (StopTask or reaching
      MaxValue). 0 if still running. }
    property StopTime          : TDateTime read GetStopTime;
    { Caps the rolling window for speed averaging. Default 1000 ms.
      Mirrors Spectre's MaxTimeForSpeedCache. }
    property MaxTimeForSpeedCacheMs : Integer read GetMaxTimeForSpeedCacheMs write SetMaxTimeForSpeedCacheMs;
    { Caps how old a sample can be before being discarded. Default 30 s. }
    property MaxSamplingAgeMs       : Integer read GetMaxSamplingAgeMs       write SetMaxSamplingAgeMs;
    { Caps the absolute number of samples retained. Default 1000. }
    property MaxSamplesKept         : Integer read GetMaxSamplesKept         write SetMaxSamplesKept;
  end;

  IProgressColumn = interface
    ['{1A2B3C4D-5E6F-4170-8E9D-0A1B2C3D4E90}']
    function Render(const task : IProgressTask; const options : TRenderOptions;
                     maxWidth : Integer) : TAnsiSegments;
    function PreferredWidth : Integer;  // -1 for flexible
    { Maximum natural width this column wants to use for the given task.
      For fixed columns this matches PreferredWidth. For flex columns
      (e.g. description) it's the rendered content's cell width. The
      board-level renderer takes the max across all tasks, so columns
      align across rows. Mirrors Spectre's TableMeasurer.MeasureColumn. }
    function MeasureMaxWidth(const task : IProgressTask;
                              const options : TRenderOptions) : Integer;
  end;

  IProgress = interface
    ['{5B6C7D8E-9F10-4A23-B4C5-6D7E8F9A0B12}']
    function AddTask(const description : string; maxValue : Double = 100) : IProgressTask; overload;
    function AddTask(const description : string; maxValue : Double; autoStart : Boolean) : IProgressTask; overload;
    { Insert a task at a specific list index. `index` is clamped to the
      current task count. Mirrors Spectre's ProgressContext.AddTaskAt. }
    function AddTaskAt(const description : string; index : Integer;
                        maxValue : Double = 100; autoStart : Boolean = True) : IProgressTask;
    { Insert immediately before / after another task. `refTask` must be
      one of this context's tasks; otherwise the new task is appended. }
    function AddTaskBefore(const description : string; const refTask : IProgressTask;
                            maxValue : Double = 100; autoStart : Boolean = True) : IProgressTask;
    function AddTaskAfter(const description : string; const refTask : IProgressTask;
                           maxValue : Double = 100; autoStart : Boolean = True) : IProgressTask;
    { True when every task has reached its MaxValue. Mirrors Spectre's
      ProgressContext.IsFinished - useful for `while not ctx.IsFinished do`
      drive loops. }
    function IsFinished : Boolean;
  end;

  TProgressAction = reference to procedure(const ctx : IProgress);

  { Wraps the rendered board renderable per-frame, e.g. to add a banner
    or border. Mirrors Spectre's Progress.UseRenderHook. }
  TProgressRenderHook = reference to function(const board : IRenderable;
    const tasks : TArray<IProgressTask>) : IRenderable;

  IProgressConfig = interface
    ['{2C3D4E5F-6071-4823-9A4B-5C6D7E8F9012}']
    function WithAutoClear(value : Boolean) : IProgressConfig;
    function WithHideCompleted(value : Boolean) : IProgressConfig;
    function WithRefreshMs(value : Integer) : IProgressConfig;
    function WithColumns(const columns : array of IProgressColumn) : IProgressConfig;
    { When False the auto-refresh ticker is suppressed - the caller drives
      redraw via task value/description updates only. Default True. }
    function WithAutoRefresh(value : Boolean) : IProgressConfig;
    function WithRenderHook(const hook : TProgressRenderHook) : IProgressConfig;
    procedure Start(const action : TProgressAction);
  end;

  { Styled-column interfaces. Each factory function returns one of these so
    users can fluently configure styles before handing the column to
    WithColumns() - the specific interface descends from IProgressColumn so
    the open-array binding stays transparent. }

  IDescriptionColumn = interface(IProgressColumn)
    ['{6E1F5A34-8D2B-4C07-9F12-3A5E6B7C8D10}']
    function WithStyle(const value : TAnsiStyle) : IDescriptionColumn;
    function WithAlignment(value : TAlignment) : IDescriptionColumn;
  end;

  IProgressBarColumn = interface(IProgressColumn)
    ['{7F2A6B45-9E3C-4D18-A023-4B6F7C8D9E20}']
    function WithWidth(value : Integer) : IProgressBarColumn;
    function WithCompletedStyle(const value : TAnsiStyle) : IProgressBarColumn;
    function WithFinishedStyle(const value : TAnsiStyle) : IProgressBarColumn;
    function WithRemainingStyle(const value : TAnsiStyle) : IProgressBarColumn;
    function WithIndeterminateStyle(const value : TAnsiStyle) : IProgressBarColumn;
  end;

  IPercentageColumn = interface(IProgressColumn)
    ['{8A3B7C56-AF4D-4E29-B134-5C7A8B9C0D30}']
    function WithStyle(const value : TAnsiStyle) : IPercentageColumn;
    function WithCompletedStyle(const value : TAnsiStyle) : IPercentageColumn;
  end;

  IElapsedColumn = interface(IProgressColumn)
    ['{9B4C8D67-B05E-4F30-C245-6D8B9C0D1E40}']
    function WithStyle(const value : TAnsiStyle) : IElapsedColumn;
  end;

  IRemainingTimeColumn = interface(IProgressColumn)
    ['{AC5D9E78-C16F-4041-D356-7E9C0D1E2F50}']
    function WithStyle(const value : TAnsiStyle) : IRemainingTimeColumn;
  end;

  ISpinnerColumn = interface(IProgressColumn)
    ['{BD6E0F89-D270-4152-E467-8F0D1E2F3060}']
    function WithStyle(const value : TAnsiStyle) : ISpinnerColumn;
    function WithCompletedStyle(const value : TAnsiStyle) : ISpinnerColumn;
    function WithPendingStyle(const value : TAnsiStyle) : ISpinnerColumn;
    function WithCompletedText(const value : string) : ISpinnerColumn;
    function WithPendingText(const value : string) : ISpinnerColumn;
  end;

  { File-size unit base for the Downloaded / TransferSpeed columns.
    TFileSizeBase.Binary uses 1024-multiples ('KB' = 1024 B, default and the
    canonical convention in Spectre); TFileSizeBase.Decimal uses 1000-multiples
    ('kB' = 1000 B, IEC SI). }
  TFileSizeBase = (Binary, Decimal);

  IDownloadedColumn = interface(IProgressColumn)
    ['{CE7F108A-E381-4263-F578-A01E2F304170}']
    function WithStyle(const value : TAnsiStyle) : IDownloadedColumn;
    function WithCompletedStyle(const value : TAnsiStyle) : IDownloadedColumn;
    function WithSeparatorStyle(const value : TAnsiStyle) : IDownloadedColumn;
    function WithBase(const value : TFileSizeBase) : IDownloadedColumn;
    { When True, the size is reported as bits/Mbits ('512 Mb' instead
      of '64 MB'). Defaults to False. }
    function WithShowBits(value : Boolean) : IDownloadedColumn;
  end;

  ITransferSpeedColumn = interface(IProgressColumn)
    ['{DF80219B-F492-4374-0689-B12F30415280}']
    function WithStyle(const value : TAnsiStyle) : ITransferSpeedColumn;
    function WithIdleStyle(const value : TAnsiStyle) : ITransferSpeedColumn;
    function WithBase(const value : TFileSizeBase) : ITransferSpeedColumn;
    function WithShowBits(value : Boolean) : ITransferSpeedColumn;
  end;

{ Built-in columns - each returns the matching styled interface. }
function DescriptionColumn : IDescriptionColumn;
{ ProgressBarColumn `width` is the column's fixed width in cells. Pass
  -1 to make the column flex - it then absorbs any leftover row width
  not claimed by the other columns. Default 40 matches Spectre's
  `new ProgressBarColumn().Width = 40`. }
function ProgressBarColumn(width : Integer = 40) : IProgressBarColumn;
function PercentageColumn : IPercentageColumn;
function ElapsedColumn : IElapsedColumn;
function RemainingTimeColumn : IRemainingTimeColumn;
function SpinnerColumn : ISpinnerColumn; overload;
function SpinnerColumn(kind : TSpinnerKind) : ISpinnerColumn; overload;
function DownloadedColumn : IDownloadedColumn;
function TransferSpeedColumn : ITransferSpeedColumn;

function Progress(const console : IAnsiConsole) : IProgressConfig;

implementation

uses
  System.Math,
  System.Diagnostics,
  System.DateUtils,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Widgets.Text,
  VSoft.AnsiConsole.Widgets.Grid,
  VSoft.AnsiConsole.Markup.Parser,
  VSoft.AnsiConsole.Live.Display,
  VSoft.AnsiConsole.Internal.Cell,
  VSoft.AnsiConsole.Internal.SegmentOps;

const
  SAMPLE_CAPACITY          = 32;
  MAX_SAMPLE_AGE_MS        = 30 * 1000;
  MAX_TIME_FOR_SPEED_CACHE = 1000;

type
  TProgressSample = record
    TimestampMs : Int64;  // monotonic (stopwatch) ms at sample time
    Delta       : Double; // value change since prior sample
  end;

  TProgressTaskImpl = class(TInterfacedObject, IProgressTask)
  strict private
    FLock              : TCriticalSection;
    FDescription       : string;
    FValue             : Double;
    FMaxValue          : Double;
    FIsStarted         : Boolean;
    FIsIndeterminate   : Boolean;
    FHideWhenCompleted : Boolean;
    FWatch             : TStopwatch;
    FSamples           : array[0..SAMPLE_CAPACITY - 1] of TProgressSample;
    FSamplesHead       : Integer;  // next write slot
    FSamplesCount      : Integer;
    FTag               : TObject;  // user payload; not owned
    FId                : Integer;
    FStartTime         : TDateTime;
    FStopTime          : TDateTime;
    FMaxTimeForSpeedCacheMs : Integer;
    FMaxSamplingAgeMs       : Integer;
    FMaxSamplesKept         : Integer;
    procedure AddSample(delta : Double);
  public
    constructor Create(const description : string; maxValue : Double;
                        autoStart : Boolean; id : Integer);
    destructor  Destroy; override;

    function  GetDescription : string;
    procedure SetDescription(const value : string);
    function  GetValue : Double;
    procedure SetValue(value : Double);
    function  GetMaxValue : Double;
    procedure SetMaxValue(value : Double);
    function  GetPercentage : Double;
    function  GetSpeed : Double;
    function  GetRemainingMs : Int64;
    function  GetIsStarted : Boolean;
    function  GetIsFinished : Boolean;
    function  GetIsIndeterminate : Boolean;
    procedure SetIsIndeterminate(value : Boolean);
    function  GetHideWhenCompleted : Boolean;
    procedure SetHideWhenCompleted(value : Boolean);
    function  GetElapsedMs : Int64;
    function  GetTag : TObject;
    procedure SetTag(const value : TObject);
    function  GetId : Integer;
    function  GetStartTime : TDateTime;
    function  GetStopTime : TDateTime;
    function  GetMaxTimeForSpeedCacheMs : Integer;
    procedure SetMaxTimeForSpeedCacheMs(value : Integer);
    function  GetMaxSamplingAgeMs : Integer;
    procedure SetMaxSamplingAgeMs(value : Integer);
    function  GetMaxSamplesKept : Integer;
    procedure SetMaxSamplesKept(value : Integer);
    procedure Increment(by : Double = 1);
    procedure StartTask;
    procedure StopTask;
  end;

{ TProgressTaskImpl }

constructor TProgressTaskImpl.Create(const description : string; maxValue : Double;
                                       autoStart : Boolean; id : Integer);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FDescription := description;
  FMaxValue := maxValue;
  if FMaxValue <= 0 then FMaxValue := 100;
  FValue := 0;
  FId   := id;
  FStartTime := 0;
  FStopTime  := 0;
  FMaxTimeForSpeedCacheMs := 1000;
  FMaxSamplingAgeMs       := 30000;
  FMaxSamplesKept         := 1000;
  if autoStart then
  begin
    FIsStarted := True;
    FStartTime := Now;
    FWatch := TStopwatch.StartNew;
  end;
end;

destructor TProgressTaskImpl.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure TProgressTaskImpl.AddSample(delta : Double);
begin
  FSamples[FSamplesHead].TimestampMs := FWatch.ElapsedMilliseconds;
  FSamples[FSamplesHead].Delta := delta;
  FSamplesHead := (FSamplesHead + 1) mod SAMPLE_CAPACITY;
  if FSamplesCount < SAMPLE_CAPACITY then
    Inc(FSamplesCount);
end;

function TProgressTaskImpl.GetDescription : string;
begin
  FLock.Enter;
  try result := FDescription; finally FLock.Leave; end;
end;

procedure TProgressTaskImpl.SetDescription(const value : string);
begin
  FLock.Enter;
  try FDescription := value; finally FLock.Leave; end;
end;

function TProgressTaskImpl.GetValue : Double;
begin
  FLock.Enter;
  try result := FValue; finally FLock.Leave; end;
end;

procedure TProgressTaskImpl.SetValue(value : Double);
var
  prev : Double;
begin
  FLock.Enter;
  try
    if value < 0 then value := 0;
    if value > FMaxValue then value := FMaxValue;
    prev := FValue;
    FValue := value;
    if not FIsStarted then
    begin
      FIsStarted := True;
      FStartTime := Now;
      FWatch := TStopwatch.StartNew;
    end;
    if FValue <> prev then
      AddSample(FValue - prev);
    if (FValue >= FMaxValue) and FWatch.IsRunning then
    begin
      FWatch.Stop;
      if FStopTime = 0 then FStopTime := Now;
    end;
  finally FLock.Leave; end;
end;

function TProgressTaskImpl.GetMaxValue : Double;
begin
  FLock.Enter;
  try result := FMaxValue; finally FLock.Leave; end;
end;

procedure TProgressTaskImpl.SetMaxValue(value : Double);
begin
  FLock.Enter;
  try
    if value < 1 then value := 1;
    FMaxValue := value;
  finally FLock.Leave; end;
end;

function TProgressTaskImpl.GetPercentage : Double;
begin
  FLock.Enter;
  try
    if FMaxValue <= 0 then
      result := 0
    else
    begin
      result := (FValue / FMaxValue) * 100.0;
      if result < 0 then result := 0;
      if result > 100 then result := 100;
    end;
  finally FLock.Leave; end;
end;

{ Steps/second over the most-recent MAX_SAMPLE_AGE_MS window.
  Algorithm (simplified from Spectre.Console/ProgressTask.GetSpeed):
    - gather samples with timestamp >= (now - MAX_SAMPLE_AGE_MS)
    - effective end-time = newest sample timestamp; if that sample is
      older than MAX_TIME_FOR_SPEED_CACHE, use `now` so speed decays to
      zero when nothing is happening
    - speed = sum(delta) / (end - start) seconds }
function TProgressTaskImpl.GetSpeed : Double;
var
  nowMs     : Int64;
  threshold : Int64;
  i, idx    : Integer;
  firstTs   : Int64;
  lastTs    : Int64;
  total     : Double;
  spanMs    : Int64;
  validCount: Integer;
begin
  FLock.Enter;
  try
    if (not FIsStarted) or (FSamplesCount = 0) then
    begin
      result := 0;
      Exit;
    end;
    nowMs := FWatch.ElapsedMilliseconds;
    threshold := nowMs - MAX_SAMPLE_AGE_MS;
    if threshold < 0 then threshold := 0;
    firstTs := -1;
    lastTs := 0;
    total := 0;
    validCount := 0;
    for i := 0 to FSamplesCount - 1 do
    begin
      // Oldest sample is at (head - count + i) mod capacity
      idx := (FSamplesHead - FSamplesCount + i + SAMPLE_CAPACITY) mod SAMPLE_CAPACITY;
      if FSamples[idx].TimestampMs < threshold then Continue;
      if firstTs < 0 then firstTs := FSamples[idx].TimestampMs;
      lastTs := FSamples[idx].TimestampMs;
      total := total + FSamples[idx].Delta;
      Inc(validCount);
    end;
    if validCount = 0 then
    begin
      result := 0;
      Exit;
    end;
    // If the newest sample is stale, stretch the window to `now` so the
    // estimated speed decays naturally.
    if (nowMs - lastTs) > MAX_TIME_FOR_SPEED_CACHE then
      lastTs := nowMs;
    spanMs := lastTs - firstTs;
    if spanMs <= 0 then
    begin
      result := 0;
      Exit;
    end;
    result := total / (spanMs / 1000.0);
    if result < 0 then result := 0;
  finally FLock.Leave; end;
end;

function TProgressTaskImpl.GetRemainingMs : Int64;
var
  speed, remaining : Double;
begin
  FLock.Enter;
  try
    if FValue >= FMaxValue then
    begin
      result := 0;
      Exit;
    end;
  finally FLock.Leave; end;

  speed := GetSpeed;  // own locking
  if speed <= 0 then
  begin
    result := -1;
    Exit;
  end;

  FLock.Enter;
  try
    remaining := (FMaxValue - FValue) / speed;  // seconds
  finally FLock.Leave; end;

  if remaining > High(Int64) / 1000 then
    result := High(Int64)
  else
    result := Round(remaining * 1000);
end;

function TProgressTaskImpl.GetIsStarted : Boolean;
begin
  FLock.Enter;
  try result := FIsStarted; finally FLock.Leave; end;
end;

function TProgressTaskImpl.GetIsFinished : Boolean;
begin
  FLock.Enter;
  try result := FValue >= FMaxValue; finally FLock.Leave; end;
end;

function TProgressTaskImpl.GetIsIndeterminate : Boolean;
begin
  FLock.Enter;
  try result := FIsIndeterminate; finally FLock.Leave; end;
end;

procedure TProgressTaskImpl.SetIsIndeterminate(value : Boolean);
begin
  FLock.Enter;
  try FIsIndeterminate := value; finally FLock.Leave; end;
end;

function TProgressTaskImpl.GetHideWhenCompleted : Boolean;
begin
  FLock.Enter;
  try result := FHideWhenCompleted; finally FLock.Leave; end;
end;

procedure TProgressTaskImpl.SetHideWhenCompleted(value : Boolean);
begin
  FLock.Enter;
  try FHideWhenCompleted := value; finally FLock.Leave; end;
end;

function TProgressTaskImpl.GetElapsedMs : Int64;
begin
  FLock.Enter;
  try
    if not FIsStarted then
      result := 0
    else
      result := FWatch.ElapsedMilliseconds;
  finally FLock.Leave; end;
end;

procedure TProgressTaskImpl.Increment(by : Double);
begin
  SetValue(GetValue + by);
end;

procedure TProgressTaskImpl.StartTask;
begin
  FLock.Enter;
  try
    if not FIsStarted then
    begin
      FIsStarted := True;
      FStartTime := Now;
      FWatch := TStopwatch.StartNew;
    end;
  finally FLock.Leave; end;
end;

procedure TProgressTaskImpl.StopTask;
begin
  FLock.Enter;
  try
    if FWatch.IsRunning then FWatch.Stop;
    if FStopTime = 0 then FStopTime := Now;
  finally FLock.Leave; end;
end;

function TProgressTaskImpl.GetTag : TObject;
begin
  FLock.Enter;
  try result := FTag; finally FLock.Leave; end;
end;

procedure TProgressTaskImpl.SetTag(const value : TObject);
begin
  FLock.Enter;
  try FTag := value; finally FLock.Leave; end;
end;

function TProgressTaskImpl.GetId : Integer;
begin
  result := FId;
end;

function TProgressTaskImpl.GetStartTime : TDateTime;
begin
  FLock.Enter;
  try result := FStartTime; finally FLock.Leave; end;
end;

function TProgressTaskImpl.GetStopTime : TDateTime;
begin
  FLock.Enter;
  try result := FStopTime; finally FLock.Leave; end;
end;

function TProgressTaskImpl.GetMaxTimeForSpeedCacheMs : Integer;
begin
  FLock.Enter;
  try result := FMaxTimeForSpeedCacheMs; finally FLock.Leave; end;
end;

procedure TProgressTaskImpl.SetMaxTimeForSpeedCacheMs(value : Integer);
begin
  FLock.Enter;
  try FMaxTimeForSpeedCacheMs := value; finally FLock.Leave; end;
end;

function TProgressTaskImpl.GetMaxSamplingAgeMs : Integer;
begin
  FLock.Enter;
  try result := FMaxSamplingAgeMs; finally FLock.Leave; end;
end;

procedure TProgressTaskImpl.SetMaxSamplingAgeMs(value : Integer);
begin
  FLock.Enter;
  try FMaxSamplingAgeMs := value; finally FLock.Leave; end;
end;

function TProgressTaskImpl.GetMaxSamplesKept : Integer;
begin
  FLock.Enter;
  try result := FMaxSamplesKept; finally FLock.Leave; end;
end;

procedure TProgressTaskImpl.SetMaxSamplesKept(value : Integer);
begin
  FLock.Enter;
  try FMaxSamplesKept := value; finally FLock.Leave; end;
end;

{ Helpers ------------------------------------------------------------------- }

{ hh:mm:ss formatter, matching Spectre's Elapsed/Remaining columns. }
function FormatHhMmSs(ms : Int64; indeterminate : Boolean = False) : string;
var
  totalSecs : Int64;
  hours     : Int64;
  mins      : Integer;
  secs      : Integer;
begin
  if indeterminate then
  begin
    result := '**:**:**';
    Exit;
  end;
  if ms < 0 then
  begin
    result := '--:--:--';
    Exit;
  end;
  totalSecs := ms div 1000;
  hours := totalSecs div 3600;
  mins  := Integer((totalSecs div 60) mod 60);
  secs  := Integer(totalSecs mod 60);
  if hours > 99 then
  begin
    result := '**:**:**';
    Exit;
  end;
  result := Format('%.2d:%.2d:%.2d', [Integer(hours), mins, secs]);
end;

{ Format a byte (or bit) count as a human-readable size string. The
  Downloaded and TransferSpeed columns delegate here; their
  WithBase/WithShowBits setters select the unit base and bits-vs-bytes
  rendering. Bits multiply the input by 8 and use lower-case 'b' /
  'kb' / 'Mb' suffixes. }
function FormatFileSize(n : Double; base : TFileSizeBase; bits : Boolean) : string;
var
  k    : Double;
  v    : Double;
  unit_ : string;
  level : Integer;
const
  BYTE_UNITS : array[0..4] of string = ('B', 'KB', 'MB', 'GB', 'TB');
  BIT_UNITS  : array[0..4] of string = ('b', 'kb', 'Mb', 'Gb', 'Tb');
begin
  v := n;
  if bits then v := v * 8;

  if base = TFileSizeBase.Decimal then k := 1000.0 else k := 1024.0;

  level := 0;
  while (v >= k) and (level < 4) do
  begin
    v := v / k;
    Inc(level);
  end;

  if bits then unit_ := BIT_UNITS[level] else unit_ := BYTE_UNITS[level];

  if level = 0 then
    result := Format('%.0f %s', [v, unit_])
  else
    result := Format('%.1f %s', [v, unit_]);
end;

{ Backwards-compatible default: binary base, byte units. }
function FormatBytes(n : Double) : string;
begin
  result := FormatFileSize(n, TFileSizeBase.Binary, False);
end;

{ Built-in columns ---------------------------------------------------------- }

type
  TDescriptionColumnImpl = class(TInterfacedObject, IProgressColumn,
                                  IDescriptionColumn)
  strict private
    FStyle     : TAnsiStyle;
    FAlignment : TAlignment;
  public
    constructor Create;
    function Render(const task : IProgressTask; const options : TRenderOptions;
                     maxWidth : Integer) : TAnsiSegments;
    function PreferredWidth : Integer;
    function MeasureMaxWidth(const task : IProgressTask;
                              const options : TRenderOptions) : Integer;
    function WithStyle(const value : TAnsiStyle) : IDescriptionColumn;
    function WithAlignment(value : TAlignment) : IDescriptionColumn;
  end;

  TProgressBarColumnImpl = class(TInterfacedObject, IProgressColumn, IProgressBarColumn)
  strict private
    FWidth              : Integer;  // -1 = flex
    FCompletedStyle     : TAnsiStyle;
    FFinishedStyle      : TAnsiStyle;
    FRemainingStyle     : TAnsiStyle;
    FIndeterminateStyle : TAnsiStyle;
  public
    constructor Create(width : Integer);
    function Render(const task : IProgressTask; const options : TRenderOptions;
                     maxWidth : Integer) : TAnsiSegments;
    function PreferredWidth : Integer;
    function MeasureMaxWidth(const task : IProgressTask;
                              const options : TRenderOptions) : Integer;
    function WithWidth(value : Integer) : IProgressBarColumn;
    function WithCompletedStyle(const value : TAnsiStyle) : IProgressBarColumn;
    function WithFinishedStyle(const value : TAnsiStyle) : IProgressBarColumn;
    function WithRemainingStyle(const value : TAnsiStyle) : IProgressBarColumn;
    function WithIndeterminateStyle(const value : TAnsiStyle) : IProgressBarColumn;
  end;

  TPercentageColumnImpl = class(TInterfacedObject, IProgressColumn, IPercentageColumn)
  strict private
    FStyle          : TAnsiStyle;
    FCompletedStyle : TAnsiStyle;
  public
    constructor Create;
    function Render(const task : IProgressTask; const options : TRenderOptions;
                     maxWidth : Integer) : TAnsiSegments;
    function PreferredWidth : Integer;
    function MeasureMaxWidth(const task : IProgressTask;
                              const options : TRenderOptions) : Integer;
    function WithStyle(const value : TAnsiStyle) : IPercentageColumn;
    function WithCompletedStyle(const value : TAnsiStyle) : IPercentageColumn;
  end;

  TElapsedColumnImpl = class(TInterfacedObject, IProgressColumn, IElapsedColumn)
  strict private
    FStyle : TAnsiStyle;
  public
    constructor Create;
    function Render(const task : IProgressTask; const options : TRenderOptions;
                     maxWidth : Integer) : TAnsiSegments;
    function PreferredWidth : Integer;
    function MeasureMaxWidth(const task : IProgressTask;
                              const options : TRenderOptions) : Integer;
    function WithStyle(const value : TAnsiStyle) : IElapsedColumn;
  end;

  TRemainingTimeColumnImpl = class(TInterfacedObject, IProgressColumn, IRemainingTimeColumn)
  strict private
    FStyle : TAnsiStyle;
  public
    constructor Create;
    function Render(const task : IProgressTask; const options : TRenderOptions;
                     maxWidth : Integer) : TAnsiSegments;
    function PreferredWidth : Integer;
    function MeasureMaxWidth(const task : IProgressTask;
                              const options : TRenderOptions) : Integer;
    function WithStyle(const value : TAnsiStyle) : IRemainingTimeColumn;
  end;

  TSpinnerColumnImpl = class(TInterfacedObject, IProgressColumn, ISpinnerColumn)
  strict private
    FSpinner        : ISpinner;
    FStyle          : TAnsiStyle;
    FCompletedStyle : TAnsiStyle;
    FPendingStyle   : TAnsiStyle;
    FWatch          : TStopwatch;
    FPendingText    : string;
    FCompletedText  : string;
    FMaxWidth       : Integer;  // -1 = not yet computed
    procedure InvalidateWidth;
  public
    constructor Create(const spinner : ISpinner);
    function Render(const task : IProgressTask; const options : TRenderOptions;
                     maxWidth : Integer) : TAnsiSegments;
    function PreferredWidth : Integer;
    function MeasureMaxWidth(const task : IProgressTask;
                              const options : TRenderOptions) : Integer;
    function WithStyle(const value : TAnsiStyle) : ISpinnerColumn;
    function WithCompletedStyle(const value : TAnsiStyle) : ISpinnerColumn;
    function WithPendingStyle(const value : TAnsiStyle) : ISpinnerColumn;
    function WithCompletedText(const value : string) : ISpinnerColumn;
    function WithPendingText(const value : string) : ISpinnerColumn;
  end;

  TDownloadedColumnImpl = class(TInterfacedObject, IProgressColumn, IDownloadedColumn)
  strict private
    FStyle          : TAnsiStyle;
    FCompletedStyle : TAnsiStyle;
    FSeparatorStyle : TAnsiStyle;
    FBase           : TFileSizeBase;
    FShowBits       : Boolean;
  public
    constructor Create;
    function Render(const task : IProgressTask; const options : TRenderOptions;
                     maxWidth : Integer) : TAnsiSegments;
    function PreferredWidth : Integer;
    function MeasureMaxWidth(const task : IProgressTask;
                              const options : TRenderOptions) : Integer;
    function WithStyle(const value : TAnsiStyle) : IDownloadedColumn;
    function WithCompletedStyle(const value : TAnsiStyle) : IDownloadedColumn;
    function WithSeparatorStyle(const value : TAnsiStyle) : IDownloadedColumn;
    function WithBase(const value : TFileSizeBase) : IDownloadedColumn;
    function WithShowBits(value : Boolean) : IDownloadedColumn;
  end;

  TTransferSpeedColumnImpl = class(TInterfacedObject, IProgressColumn, ITransferSpeedColumn)
  strict private
    FStyle     : TAnsiStyle;
    FIdleStyle : TAnsiStyle;
    FBase      : TFileSizeBase;
    FShowBits  : Boolean;
  public
    constructor Create;
    function Render(const task : IProgressTask; const options : TRenderOptions;
                     maxWidth : Integer) : TAnsiSegments;
    function PreferredWidth : Integer;
    function MeasureMaxWidth(const task : IProgressTask;
                              const options : TRenderOptions) : Integer;
    function WithStyle(const value : TAnsiStyle) : ITransferSpeedColumn;
    function WithIdleStyle(const value : TAnsiStyle) : ITransferSpeedColumn;
    function WithBase(const value : TFileSizeBase) : ITransferSpeedColumn;
    function WithShowBits(value : Boolean) : ITransferSpeedColumn;
  end;

{ TDescriptionColumnImpl ---------------------------------------------------- }

constructor TDescriptionColumnImpl.Create;
begin
  inherited Create;
  FStyle     := TAnsiStyle.Plain;
  FAlignment := TAlignment.Right;  // matches Spectre's TaskDescriptionColumn default
end;

function TDescriptionColumnImpl.Render(const task : IProgressTask;
  const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  desc        : string;
  parsed      : TAnsiSegments;
  descCells   : Integer;
  width       : Integer;
  pad         : Integer;
  leftPad     : Integer;
  rightPad    : Integer;
  count       : Integer;
  i           : Integer;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;

  desc := task.Description;
  // Run through the markup parser so users can write '[red]error[/]' in
  // task descriptions, matching Spectre's TaskDescriptionColumn behaviour.
  parsed := ParseMarkup(desc, FStyle);

  descCells := 0;
  for i := 0 to High(parsed) do
    descCells := descCells + CellLength(parsed[i].Value);

  width := maxWidth;
  if width < 1 then width := 1;

  // If description overflows, clip from the right (cell-naive — adequate
  // for the common ASCII case; falls back to char count). Reserve one cell
  // for an ellipsis so the visual width still matches.
  if descCells > width then
  begin
    if Length(desc) > 0 then
      desc := Copy(desc, 1, width - 1) + #$2026  // … U+2026
    else
      desc := '';
    parsed := ParseMarkup(desc, FStyle);
    descCells := 0;
    for i := 0 to High(parsed) do
      descCells := descCells + CellLength(parsed[i].Value);
  end;

  pad := width - descCells;
  if pad < 0 then pad := 0;
  case FAlignment of
    TAlignment.Center:
    begin
      leftPad  := pad div 2;
      rightPad := pad - leftPad;
    end;
    TAlignment.Right:
    begin
      leftPad  := pad;
      rightPad := 0;
    end;
  else
    leftPad  := 0;
    rightPad := pad;
  end;

  if leftPad > 0 then
    Push(TAnsiSegment.Whitespace(StringOfChar(' ', leftPad)));
  for i := 0 to High(parsed) do
    Push(parsed[i]);
  if rightPad > 0 then
    Push(TAnsiSegment.Whitespace(StringOfChar(' ', rightPad)));
end;

function TDescriptionColumnImpl.PreferredWidth : Integer;
begin
  result := -1;  // always flexible — Spectre's TaskDescriptionColumn has no fixed width
end;

function TDescriptionColumnImpl.MeasureMaxWidth(const task : IProgressTask;
  const options : TRenderOptions) : Integer;
var
  parsed : TAnsiSegments;
  i      : Integer;
begin
  parsed := ParseMarkup(task.Description, FStyle);
  result := 0;
  for i := 0 to High(parsed) do
    Inc(result, CellLength(parsed[i].Value));
end;

function TDescriptionColumnImpl.WithStyle(const value : TAnsiStyle) : IDescriptionColumn;
begin
  FStyle := value;
  result := Self;
end;

function TDescriptionColumnImpl.WithAlignment(value : TAlignment) : IDescriptionColumn;
begin
  FAlignment := value;
  result := Self;
end;

{ TProgressBarColumnImpl ---------------------------------------------------- }

constructor TProgressBarColumnImpl.Create(width : Integer);
begin
  inherited Create;
  if width = 0 then width := 40;
  if (width > 0) and (width < 5) then width := 5;
  FWidth := width;  // -1 (or any negative) = flex
  // Spectre defaults: Yellow (active), Green (finished), Grey (remaining),
  // DodgerBlue1/Grey23 pulse for indeterminate.
  FCompletedStyle     := TAnsiStyle.Plain.WithForeground(TAnsiColor.Yellow);
  FFinishedStyle      := TAnsiStyle.Plain.WithForeground(TAnsiColor.Green);
  FRemainingStyle     := TAnsiStyle.Plain.WithForeground(TAnsiColor.Grey);
  FIndeterminateStyle := TAnsiStyle.Plain
                          .WithForeground(TAnsiColor.FromRGB(0, 135, 255))   // DodgerBlue1
                          .WithBackground(TAnsiColor.FromRGB(58, 58, 58));   // Grey23
end;

const
  PULSESIZE  = 20;
  PULSESPEED = 15;  // chars/second of scroll

function TProgressBarColumnImpl.Render(const task : IProgressTask;
  const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  filled        : Integer;
  pct           : Double;
  barCh         : Char;
  fillCh        : Char;
  remCh         : Char;          // remaining glyph (bar char or space in legacy)
  fillStyle     : TAnsiStyle;
  barWidth      : Integer;
  isLegacy      : Boolean;
  i, j          : Integer;
  count         : Integer;
  pulse         : array[0..PULSESIZE - 1] of TAnsiStyle;
  fadeFg, fadeBg: TAnsiColor;
  fade          : Single;
  position      : Single;
  offsetMs      : Int64;
  scroll        : Integer;
  segCount      : Integer;
begin
  SetLength(result, 0);

  // Render fills the cellWidth allocated to this column by the board's
  // width computation. When FWidth >= 0 the column was fixed at FWidth;
  // when FWidth < 0 the board gave us a share of the leftover space.
  // Either way, maxWidth is our final width.
  barWidth := maxWidth;
  if barWidth < 1 then barWidth := 1;

  if options.Unicode then
  begin
    // Spectre uses U+2501 (BOX DRAWINGS HEAVY HORIZONTAL) for both filled
    // and unfilled portions; only the colour distinguishes them.
    fillCh := #$2501;  // ━
    barCh  := #$2501;  // ━
  end
  else
  begin
    fillCh := '#';
    barCh  := '-';
  end;

  isLegacy := (options.ColorSystem = TColorSystem.NoColors) or (options.ColorSystem = TColorSystem.Legacy);

  // Indeterminate: 20-cell cosine-fade pulse repeated to fill the bar
  // and scrolled by wall-clock time. Falls back to a 2-tone block in
  // legacy / no-color terminals.
  if task.IsIndeterminate and (not task.IsFinished) then
  begin
    fadeFg := FIndeterminateStyle.Foreground;
    fadeBg := FIndeterminateStyle.Background;
    if isLegacy then
    begin
      // First half of pulse = fg, second half = bg (or space in NoColors)
      for i := 0 to (PULSESIZE div 2) - 1 do
        pulse[i] := TAnsiStyle.Plain.WithForeground(fadeFg);
      for i := (PULSESIZE div 2) to PULSESIZE - 1 do
        pulse[i] := TAnsiStyle.Plain.WithForeground(fadeBg);
    end
    else
    begin
      // 24-bit cosine fade between fg and bg, per cell
      for i := 0 to PULSESIZE - 1 do
      begin
        position := i / PULSESIZE;
        fade := 0.5 + Cos(position * 2 * Pi) / 2.0;
        pulse[i] := TAnsiStyle.Plain.WithForeground(fadeFg.Blend(fadeBg, fade));
      end;
    end;

    // Scroll offset based on wall-clock seconds since midnight.
    offsetMs := MillisecondsBetween(Now, Today);
    scroll := Integer((offsetMs * PULSESPEED div 1000) mod PULSESIZE);

    SetLength(result, barWidth);
    segCount := 0;
    for i := 0 to barWidth - 1 do
    begin
      j := (i + scroll) mod PULSESIZE;
      // In legacy / no-color terminals the gradient collapses to two
      // discrete styles, so Spectre renders the second half as a space
      // (otherwise the bar would look fully solid).
      if isLegacy and (j >= PULSESIZE div 2) then
        result[segCount] := TAnsiSegment.Text(' ', pulse[j])
      else
        result[segCount] := TAnsiSegment.Text(barCh, pulse[j]);
      Inc(segCount);
    end;
    Exit;
  end;

  pct := task.Percentage / 100.0;
  filled := Trunc(pct * barWidth);  // Spectre uses truncation, not rounding
  if filled < 0 then filled := 0;
  if filled > barWidth then filled := barWidth;

  if task.IsFinished then
    fillStyle := FFinishedStyle
  else
    fillStyle := FCompletedStyle;

  // In NoColors / Legacy, remaining portion uses ' ' instead of bar char so
  // it doesn't visually look full.
  if isLegacy then
    remCh := ' '
  else
    remCh := barCh;

  SetLength(result, 2);
  count := 0;
  if filled > 0 then
  begin
    result[count] := TAnsiSegment.Text(StringOfChar(fillCh, filled), fillStyle);
    Inc(count);
  end;
  if (barWidth - filled) > 0 then
  begin
    result[count] := TAnsiSegment.Text(StringOfChar(remCh, barWidth - filled), FRemainingStyle);
    Inc(count);
  end;
  SetLength(result, count);
end;

function TProgressBarColumnImpl.PreferredWidth : Integer;
begin
  result := FWidth;  // -1 = flex (board distributes leftover space)
end;

function TProgressBarColumnImpl.MeasureMaxWidth(const task : IProgressTask;
  const options : TRenderOptions) : Integer;
begin
  // Flex columns return -1 to signal "fill leftover"; fixed columns
  // report their configured width.
  result := FWidth;
end;

function TProgressBarColumnImpl.WithWidth(value : Integer) : IProgressBarColumn;
begin
  if value < 0 then
    FWidth := -1
  else
  begin
    if value < 5 then value := 5;
    FWidth := value;
  end;
  result := Self;
end;

function TProgressBarColumnImpl.WithCompletedStyle(const value : TAnsiStyle) : IProgressBarColumn;
begin FCompletedStyle := value; result := Self; end;

function TProgressBarColumnImpl.WithFinishedStyle(const value : TAnsiStyle) : IProgressBarColumn;
begin FFinishedStyle := value; result := Self; end;

function TProgressBarColumnImpl.WithRemainingStyle(const value : TAnsiStyle) : IProgressBarColumn;
begin FRemainingStyle := value; result := Self; end;

function TProgressBarColumnImpl.WithIndeterminateStyle(const value : TAnsiStyle) : IProgressBarColumn;
begin FIndeterminateStyle := value; result := Self; end;

{ TPercentageColumnImpl ----------------------------------------------------- }

constructor TPercentageColumnImpl.Create;
begin
  inherited Create;
  FStyle          := TAnsiStyle.Plain;
  FCompletedStyle := TAnsiStyle.Plain.WithForeground(TAnsiColor.Green);
end;

function TPercentageColumnImpl.Render(const task : IProgressTask;
  const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  s     : string;
  style : TAnsiStyle;
begin
  s := Format('%3.0f%%', [task.Percentage]);
  if task.IsFinished then
    style := FCompletedStyle
  else
    style := FStyle;
  SetLength(result, 1);
  result[0] := TAnsiSegment.Text(s, style);
end;

function TPercentageColumnImpl.PreferredWidth : Integer;
begin
  result := 4;
end;

function TPercentageColumnImpl.MeasureMaxWidth(const task : IProgressTask;
  const options : TRenderOptions) : Integer;
begin
  result := 4;
end;

function TPercentageColumnImpl.WithStyle(const value : TAnsiStyle) : IPercentageColumn;
begin FStyle := value; result := Self; end;

function TPercentageColumnImpl.WithCompletedStyle(const value : TAnsiStyle) : IPercentageColumn;
begin FCompletedStyle := value; result := Self; end;

{ TElapsedColumnImpl -------------------------------------------------------- }

constructor TElapsedColumnImpl.Create;
begin
  inherited Create;
  FStyle := TAnsiStyle.Plain.WithForeground(TAnsiColor.Blue);
end;

function TElapsedColumnImpl.Render(const task : IProgressTask;
  const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
begin
  SetLength(result, 1);
  result[0] := TAnsiSegment.Text(FormatHhMmSs(task.ElapsedMs), FStyle);
end;

function TElapsedColumnImpl.PreferredWidth : Integer;
begin
  result := 8;  // hh:mm:ss
end;

function TElapsedColumnImpl.MeasureMaxWidth(const task : IProgressTask;
  const options : TRenderOptions) : Integer;
begin
  result := 8;
end;

function TElapsedColumnImpl.WithStyle(const value : TAnsiStyle) : IElapsedColumn;
begin FStyle := value; result := Self; end;

{ TRemainingTimeColumnImpl -------------------------------------------------- }

constructor TRemainingTimeColumnImpl.Create;
begin
  inherited Create;
  FStyle := TAnsiStyle.Plain.WithForeground(TAnsiColor.Blue);
end;

function TRemainingTimeColumnImpl.Render(const task : IProgressTask;
  const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
begin
  SetLength(result, 1);
  // Spectre renders **:**:** for indeterminate tasks (the remaining time
  // estimate is meaningless until a max value is known).
  result[0] := TAnsiSegment.Text(FormatHhMmSs(task.RemainingMs, task.IsIndeterminate), FStyle);
end;

function TRemainingTimeColumnImpl.PreferredWidth : Integer;
begin
  result := 8;  // hh:mm:ss
end;

function TRemainingTimeColumnImpl.MeasureMaxWidth(const task : IProgressTask;
  const options : TRenderOptions) : Integer;
begin
  result := 8;
end;

function TRemainingTimeColumnImpl.WithStyle(const value : TAnsiStyle) : IRemainingTimeColumn;
begin FStyle := value; result := Self; end;

{ TSpinnerColumnImpl -------------------------------------------------------- }

constructor TSpinnerColumnImpl.Create(const spinner : ISpinner);
begin
  inherited Create;
  FSpinner := spinner;
  FStyle          := TAnsiStyle.Plain.WithForeground(TAnsiColor.Yellow);
  FCompletedStyle := TAnsiStyle.Plain.WithForeground(TAnsiColor.Lime);
  FPendingStyle   := TAnsiStyle.Plain;
  FPendingText    := ' ';
  FCompletedText  := #$2714;  // heavy check mark; downgraded in non-unicode
  FWatch          := TStopwatch.StartNew;
  FMaxWidth       := -1;
end;

procedure TSpinnerColumnImpl.InvalidateWidth;
begin
  FMaxWidth := -1;
end;

function TSpinnerColumnImpl.Render(const task : IProgressTask;
  const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  frameIdx : Integer;
  glyph    : string;
begin
  SetLength(result, 1);
  if not task.IsStarted then
  begin
    result[0] := TAnsiSegment.Text(FPendingText, FPendingStyle);
    Exit;
  end;
  if task.IsFinished then
  begin
    glyph := FCompletedText;
    if not options.Unicode then glyph := 'v';
    result[0] := TAnsiSegment.Text(glyph, FCompletedStyle);
    Exit;
  end;
  frameIdx := Integer(FWatch.ElapsedMilliseconds div FSpinner.IntervalMs);
  result[0] := TAnsiSegment.Text(FSpinner.Frame(frameIdx), FStyle);
end;

{ Auto-size to the widest of pending text, completed text, and the widest
  spinner frame. Cached after first call - InvalidateWidth resets it after
  any field that affects width changes. }
function TSpinnerColumnImpl.PreferredWidth : Integer;
var
  i  : Integer;
  w  : Integer;
  fw : Integer;
begin
  if FMaxWidth >= 0 then
  begin
    result := FMaxWidth;
    Exit;
  end;
  w := CellLength(FPendingText);
  if CellLength(FCompletedText) > w then w := CellLength(FCompletedText);
  if FSpinner <> nil then
  begin
    for i := 0 to FSpinner.Frames - 1 do
    begin
      fw := CellLength(FSpinner.Frame(i));
      if fw > w then w := fw;
    end;
  end;
  if w < 1 then w := 1;
  FMaxWidth := w;
  result := w;
end;

function TSpinnerColumnImpl.MeasureMaxWidth(const task : IProgressTask;
  const options : TRenderOptions) : Integer;
begin
  result := PreferredWidth;
end;

function TSpinnerColumnImpl.WithStyle(const value : TAnsiStyle) : ISpinnerColumn;
begin FStyle := value; result := Self; end;

function TSpinnerColumnImpl.WithCompletedStyle(const value : TAnsiStyle) : ISpinnerColumn;
begin FCompletedStyle := value; result := Self; end;

function TSpinnerColumnImpl.WithPendingStyle(const value : TAnsiStyle) : ISpinnerColumn;
begin FPendingStyle := value; result := Self; end;

function TSpinnerColumnImpl.WithCompletedText(const value : string) : ISpinnerColumn;
begin FCompletedText := value; InvalidateWidth; result := Self; end;

function TSpinnerColumnImpl.WithPendingText(const value : string) : ISpinnerColumn;
begin FPendingText := value; InvalidateWidth; result := Self; end;

{ TDownloadedColumnImpl ----------------------------------------------------- }

constructor TDownloadedColumnImpl.Create;
begin
  inherited Create;
  FStyle          := TAnsiStyle.Plain;
  FCompletedStyle := TAnsiStyle.Plain.WithForeground(TAnsiColor.Green);
  FSeparatorStyle := TAnsiStyle.Plain.WithForeground(TAnsiColor.Grey);
  FBase           := TFileSizeBase.Binary;
  FShowBits       := False;
end;

function TDownloadedColumnImpl.Render(const task : IProgressTask;
  const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
begin
  if task.IsFinished then
  begin
    SetLength(result, 1);
    result[0] := TAnsiSegment.Text(FormatFileSize(task.MaxValue, FBase, FShowBits), FCompletedStyle);
    Exit;
  end;
  SetLength(result, 3);
  result[0] := TAnsiSegment.Text(FormatFileSize(task.Value,    FBase, FShowBits), FStyle);
  result[1] := TAnsiSegment.Text(' / ', FSeparatorStyle);
  result[2] := TAnsiSegment.Text(FormatFileSize(task.MaxValue, FBase, FShowBits), FStyle);
end;

function TDownloadedColumnImpl.PreferredWidth : Integer;
begin
  result := 20;
end;

function TDownloadedColumnImpl.MeasureMaxWidth(const task : IProgressTask;
  const options : TRenderOptions) : Integer;
begin
  result := 20;
end;

function TDownloadedColumnImpl.WithStyle(const value : TAnsiStyle) : IDownloadedColumn;
begin FStyle := value; result := Self; end;

function TDownloadedColumnImpl.WithCompletedStyle(const value : TAnsiStyle) : IDownloadedColumn;
begin FCompletedStyle := value; result := Self; end;

function TDownloadedColumnImpl.WithSeparatorStyle(const value : TAnsiStyle) : IDownloadedColumn;
begin FSeparatorStyle := value; result := Self; end;

function TDownloadedColumnImpl.WithBase(const value : TFileSizeBase) : IDownloadedColumn;
begin FBase := value; result := Self; end;

function TDownloadedColumnImpl.WithShowBits(value : Boolean) : IDownloadedColumn;
begin FShowBits := value; result := Self; end;

{ TTransferSpeedColumnImpl -------------------------------------------------- }

constructor TTransferSpeedColumnImpl.Create;
begin
  inherited Create;
  FStyle     := TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua);
  FIdleStyle := TAnsiStyle.Plain.WithForeground(TAnsiColor.Grey);
  FBase      := TFileSizeBase.Binary;
  FShowBits  := False;
end;

function TTransferSpeedColumnImpl.Render(const task : IProgressTask;
  const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  sp : Double;
begin
  sp := task.Speed;
  SetLength(result, 1);
  if sp <= 0 then
    result[0] := TAnsiSegment.Text('--', FIdleStyle)
  else
    result[0] := TAnsiSegment.Text(FormatFileSize(sp, FBase, FShowBits) + '/s', FStyle);
end;

function TTransferSpeedColumnImpl.PreferredWidth : Integer;
begin
  result := 12;
end;

function TTransferSpeedColumnImpl.MeasureMaxWidth(const task : IProgressTask;
  const options : TRenderOptions) : Integer;
begin
  result := 12;
end;

function TTransferSpeedColumnImpl.WithStyle(const value : TAnsiStyle) : ITransferSpeedColumn;
begin FStyle := value; result := Self; end;

function TTransferSpeedColumnImpl.WithIdleStyle(const value : TAnsiStyle) : ITransferSpeedColumn;
begin FIdleStyle := value; result := Self; end;

function TTransferSpeedColumnImpl.WithBase(const value : TFileSizeBase) : ITransferSpeedColumn;
begin FBase := value; result := Self; end;

function TTransferSpeedColumnImpl.WithShowBits(value : Boolean) : ITransferSpeedColumn;
begin FShowBits := value; result := Self; end;

function DescriptionColumn : IDescriptionColumn;
begin result := TDescriptionColumnImpl.Create; end;

function ProgressBarColumn(width : Integer) : IProgressBarColumn;
begin result := TProgressBarColumnImpl.Create(width); end;

function PercentageColumn : IPercentageColumn;
begin result := TPercentageColumnImpl.Create; end;

function ElapsedColumn : IElapsedColumn;
begin result := TElapsedColumnImpl.Create; end;

function RemainingTimeColumn : IRemainingTimeColumn;
begin result := TRemainingTimeColumnImpl.Create; end;

function SpinnerColumn : ISpinnerColumn;
begin
  result := TSpinnerColumnImpl.Create(Spinner(TSpinnerKind.Dots, True));
end;

function SpinnerColumn(kind : TSpinnerKind) : ISpinnerColumn;
begin
  result := TSpinnerColumnImpl.Create(Spinner(kind, True));
end;

function DownloadedColumn : IDownloadedColumn;
begin result := TDownloadedColumnImpl.Create; end;

function TransferSpeedColumn : ITransferSpeedColumn;
begin result := TTransferSpeedColumnImpl.Create; end;

{ TProgressRow / TProgressBoard -------------------------------------------- }

type
  { Renders one task's row given pre-computed per-column widths. The
    board owns the width computation so all rows share the same column
    boundaries (matches Spectre's table layout). }
  TProgressRowRenderable = class(TInterfacedObject, IRenderable)
  strict private
    FTask       : IProgressTask;
    FColumns    : TArray<IProgressColumn>;
    FCellWidths : TArray<Integer>;
    FGutter     : Integer;
  public
    constructor Create(const task : IProgressTask;
                        const columns : TArray<IProgressColumn>;
                        const cellWidths : TArray<Integer>;
                        gutter : Integer);
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
  end;

  TProgressBoardRenderable = class(TInterfacedObject, IRenderable)
  strict private
    FTasks         : TArray<IProgressTask>;
    FColumns       : TArray<IProgressColumn>;
    FGutter        : Integer;
    FHideCompleted : Boolean;
    { Compute final per-column widths across the visible tasks, then
      distribute leftover row width to any fill columns (PreferredWidth<0
      with MeasureMaxWidth=-1) and shrink content-flex columns when the
      sum overflows maxWidth. Mirrors Spectre.TableMeasurer. }
    function ComputeCellWidths(const visible : TArray<IProgressTask>;
                                 const options : TRenderOptions;
                                 maxWidth : Integer) : TArray<Integer>;
  public
    constructor Create(const tasks : TArray<IProgressTask>;
                        const columns : TArray<IProgressColumn>;
                        gutter : Integer;
                        hideCompleted : Boolean);
    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
  end;

constructor TProgressRowRenderable.Create(const task : IProgressTask;
                                           const columns : TArray<IProgressColumn>;
                                           const cellWidths : TArray<Integer>;
                                           gutter : Integer);
begin
  inherited Create;
  FTask := task;
  FColumns := columns;
  FCellWidths := cellWidths;
  FGutter := gutter;
end;

function TProgressRowRenderable.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
begin
  result := TMeasurement.Create(1, maxWidth);
end;

function TProgressRowRenderable.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  i, j, count  : Integer;
  colSegs      : TAnsiSegments;
  gutterStr    : string;
  emittedAny   : Boolean;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;
  if Length(FColumns) = 0 then Exit;

  gutterStr := StringOfChar(' ', FGutter);
  emittedAny := False;
  for i := 0 to High(FColumns) do
  begin
    if (i >= Length(FCellWidths)) or (FCellWidths[i] <= 0) then
      Continue;
    if emittedAny and (FGutter > 0) then
      Push(TAnsiSegment.Whitespace(gutterStr));
    colSegs := FColumns[i].Render(FTask, options, FCellWidths[i]);
    for j := 0 to High(colSegs) do
      Push(colSegs[j]);
    emittedAny := True;
  end;
end;

function TProgressBoardRenderable.ComputeCellWidths(const visible : TArray<IProgressTask>;
                                                     const options : TRenderOptions;
                                                     maxWidth : Integer) : TArray<Integer>;
var
  i, j, colCount, visibleCnt : Integer;
  fillFlags                  : TArray<Boolean>;
  pref, measMax, taskMaxW    : Integer;
  fixedTotal, leftover       : Integer;
  fillCount, perFill, extra  : Integer;
  used, contentFlexTotal     : Integer;
  excess                     : Integer;
  reduce                     : Integer;
begin
  colCount := Length(FColumns);
  visibleCnt := Length(visible);
  SetLength(result, colCount);
  SetLength(fillFlags, colCount);
  fixedTotal := 0;
  fillCount := 0;

  for i := 0 to colCount - 1 do
  begin
    pref := FColumns[i].PreferredWidth;
    if pref >= 0 then
    begin
      result[i] := pref;
      fixedTotal := fixedTotal + pref;
      fillFlags[i] := False;
    end
    else
    begin
      // Flex column - measure each visible task; -1 from any task means
      // "fill leftover" so the column joins the leftover-distribution pass.
      taskMaxW := 0;
      for j := 0 to visibleCnt - 1 do
      begin
        measMax := FColumns[i].MeasureMaxWidth(visible[j], options);
        if measMax < 0 then
        begin
          taskMaxW := -1;
          Break;
        end;
        if measMax > taskMaxW then taskMaxW := measMax;
      end;
      if taskMaxW < 0 then
      begin
        result[i] := 0;
        fillFlags[i] := True;
        Inc(fillCount);
      end
      else
      begin
        result[i] := taskMaxW;
        fixedTotal := fixedTotal + taskMaxW;
        fillFlags[i] := False;
      end;
    end;
  end;

  // Add gutter cells (one between each pair of columns).
  if colCount > 1 then
    Inc(fixedTotal, FGutter * (colCount - 1));

  leftover := maxWidth - fixedTotal;

  if leftover > 0 then
  begin
    if fillCount > 0 then
    begin
      perFill := leftover div fillCount;
      extra := leftover - perFill * fillCount;
      used := 0;
      for i := 0 to colCount - 1 do
      begin
        if fillFlags[i] then
        begin
          result[i] := perFill;
          if used < extra then Inc(result[i]);
          Inc(used);
        end;
      end;
    end;
    // Without fill columns the row stays shorter than maxWidth - the
    // live display pads to the right naturally.
  end
  else if leftover < 0 then
  begin
    excess := -leftover;
    // Fill columns already at 0; shrink content-flex columns proportionally.
    contentFlexTotal := 0;
    for i := 0 to colCount - 1 do
      if (FColumns[i].PreferredWidth < 0) and not fillFlags[i] then
        Inc(contentFlexTotal, result[i]);
    if contentFlexTotal > 0 then
    begin
      for i := 0 to colCount - 1 do
      begin
        if (FColumns[i].PreferredWidth < 0) and not fillFlags[i] then
        begin
          reduce := (excess * result[i]) div contentFlexTotal;
          result[i] := result[i] - reduce;
          if result[i] < 1 then result[i] := 1;
        end;
      end;
    end;
    // If still over, the row simply overruns - fixed columns are honoured.
  end;
end;

constructor TProgressBoardRenderable.Create(const tasks : TArray<IProgressTask>;
                                              const columns : TArray<IProgressColumn>;
                                              gutter : Integer;
                                              hideCompleted : Boolean);
begin
  inherited Create;
  FTasks := tasks;
  FColumns := columns;
  FGutter := gutter;
  FHideCompleted := hideCompleted;
end;

function TProgressBoardRenderable.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
begin
  result := TMeasurement.Create(1, maxWidth);
end;

function TProgressBoardRenderable.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  i, j, count : Integer;
  row         : IRenderable;
  rowSegs     : TAnsiSegments;
  visible     : TArray<IProgressTask>;
  visibleCnt  : Integer;
  cellWidths  : TArray<Integer>;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;

  // Filter out hidden tasks (per-task HideWhenCompleted + global HideCompleted)
  SetLength(visible, Length(FTasks));
  visibleCnt := 0;
  for i := 0 to High(FTasks) do
  begin
    if FTasks[i].IsFinished and
       (FHideCompleted or FTasks[i].HideWhenCompleted) then
      Continue;
    visible[visibleCnt] := FTasks[i];
    Inc(visibleCnt);
  end;
  SetLength(visible, visibleCnt);
  if visibleCnt = 0 then Exit;

  // Compute column widths once across all visible tasks so columns line
  // up between rows. Each row then renders at exactly these widths.
  cellWidths := ComputeCellWidths(visible, options, maxWidth);

  // No leading/trailing padding inside the live region: extra LineBreaks
  // here would be re-drawn every refresh tick and flicker visibly. The
  // surrounding blank lines are emitted once by TProgressImpl.Start
  // outside the live block.
  for i := 0 to High(visible) do
  begin
    row := TProgressRowRenderable.Create(visible[i], FColumns, cellWidths, FGutter);
    rowSegs := row.Render(options, maxWidth);
    for j := 0 to High(rowSegs) do
      Push(rowSegs[j]);
    if i < High(visible) then
      Push(TAnsiSegment.LineBreak);
  end;
end;

{ Ticker thread + config impl ---------------------------------------------- }

type
  TProgressBoardBuilder = reference to function : IRenderable;

  TProgressTickerThread = class(TThread)
  strict private
    FDisplay   : ILiveDisplay;
    FBuilder   : TProgressBoardBuilder;
    FRefreshMs : Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const display : ILiveDisplay;
                        const builder : TProgressBoardBuilder;
                        refreshMs : Integer);
  end;

constructor TProgressTickerThread.Create(const display : ILiveDisplay;
                                          const builder : TProgressBoardBuilder;
                                          refreshMs : Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FDisplay := display;
  FBuilder := builder;
  FRefreshMs := refreshMs;
end;

procedure TProgressTickerThread.Execute;
begin
  while not Terminated do
  begin
    Sleep(FRefreshMs);
    if Terminated then Break;
    FDisplay.Update(FBuilder());
  end;
end;

type
  TProgressImpl = class(TInterfacedObject, IProgress, IProgressConfig)
  strict private
    FConsole       : IAnsiConsole;
    FTasks         : TList<IProgressTask>;
    FTasksLock     : TCriticalSection;
    FColumns       : TArray<IProgressColumn>;
    FRefreshMs     : Integer;
    FAutoClear     : Boolean;
    FHideCompleted : Boolean;
    FAutoRefresh   : Boolean;
    FGutter        : Integer;
    FNextId        : Integer;
    FRenderHook    : TProgressRenderHook;
    procedure EnsureDefaultColumns;
    function  SnapshotTasks : TArray<IProgressTask>;
    function  BuildBoard : IRenderable;
    function  AllocId : Integer;
  public
    constructor Create(const console : IAnsiConsole);
    destructor  Destroy; override;

    { IProgress }
    function AddTask(const description : string; maxValue : Double = 100) : IProgressTask; overload;
    function AddTask(const description : string; maxValue : Double; autoStart : Boolean) : IProgressTask; overload;
    function AddTaskAt(const description : string; index : Integer;
                        maxValue : Double = 100; autoStart : Boolean = True) : IProgressTask;
    function AddTaskBefore(const description : string; const refTask : IProgressTask;
                            maxValue : Double = 100; autoStart : Boolean = True) : IProgressTask;
    function AddTaskAfter(const description : string; const refTask : IProgressTask;
                           maxValue : Double = 100; autoStart : Boolean = True) : IProgressTask;
    function IsFinished : Boolean;

    { IProgressConfig }
    function WithAutoClear(value : Boolean) : IProgressConfig;
    function WithHideCompleted(value : Boolean) : IProgressConfig;
    function WithRefreshMs(value : Integer) : IProgressConfig;
    function WithColumns(const columns : array of IProgressColumn) : IProgressConfig;
    function WithAutoRefresh(value : Boolean) : IProgressConfig;
    function WithRenderHook(const hook : TProgressRenderHook) : IProgressConfig;
    procedure Start(const action : TProgressAction);
  end;

function Progress(const console : IAnsiConsole) : IProgressConfig;
begin
  result := TProgressImpl.Create(console);
end;

{ TProgressImpl }

constructor TProgressImpl.Create(const console : IAnsiConsole);
begin
  inherited Create;
  FConsole := console;
  FTasks := TList<IProgressTask>.Create;
  FTasksLock := TCriticalSection.Create;
  FRefreshMs := 100;
  FAutoClear := False;
  FHideCompleted := False;
  FAutoRefresh := True;
  FNextId := 0;
  FGutter := 1;  // matches Spectre's PadRight(1) per grid column
end;

function TProgressImpl.AllocId : Integer;
begin
  // Sequential ids starting at 0. Not locked - all task creation paths
  // hold FTasksLock when calling this.
  result := FNextId;
  Inc(FNextId);
end;

destructor TProgressImpl.Destroy;
begin
  FTasks.Free;
  FTasksLock.Free;
  inherited;
end;

procedure TProgressImpl.EnsureDefaultColumns;
begin
  if Length(FColumns) > 0 then Exit;
  // Matches Spectre's default Progress columns
  SetLength(FColumns, 3);
  FColumns[0] := DescriptionColumn;
  FColumns[1] := ProgressBarColumn(40);
  FColumns[2] := PercentageColumn;
end;

function TProgressImpl.SnapshotTasks : TArray<IProgressTask>;
var
  i : Integer;
begin
  FTasksLock.Enter;
  try
    SetLength(result, FTasks.Count);
    for i := 0 to FTasks.Count - 1 do
      result[i] := FTasks[i];
  finally
    FTasksLock.Leave;
  end;
end;

function TProgressImpl.BuildBoard : IRenderable;
begin
  result := TProgressBoardRenderable.Create(SnapshotTasks, FColumns,
                                             FGutter, FHideCompleted);
end;

function TProgressImpl.AddTask(const description : string; maxValue : Double) : IProgressTask;
begin
  result := AddTask(description, maxValue, True);
end;

function TProgressImpl.AddTask(const description : string; maxValue : Double;
                                 autoStart : Boolean) : IProgressTask;
begin
  FTasksLock.Enter;
  try
    result := TProgressTaskImpl.Create(description, maxValue, autoStart, AllocId);
    FTasks.Add(result);
  finally
    FTasksLock.Leave;
  end;
end;

function TProgressImpl.AddTaskAt(const description : string; index : Integer;
                                  maxValue : Double; autoStart : Boolean) : IProgressTask;
var
  clamped : Integer;
begin
  FTasksLock.Enter;
  try
    result := TProgressTaskImpl.Create(description, maxValue, autoStart, AllocId);
    clamped := index;
    if clamped < 0 then clamped := 0;
    if clamped > FTasks.Count then clamped := FTasks.Count;
    FTasks.Insert(clamped, result);
  finally
    FTasksLock.Leave;
  end;
end;

function TProgressImpl.AddTaskBefore(const description : string; const refTask : IProgressTask;
                                      maxValue : Double; autoStart : Boolean) : IProgressTask;
var
  refIdx : Integer;
begin
  FTasksLock.Enter;
  try
    result := TProgressTaskImpl.Create(description, maxValue, autoStart, AllocId);
    refIdx := FTasks.IndexOf(refTask);
    if refIdx < 0 then
      FTasks.Add(result)            // refTask not found - fall back to append
    else
      FTasks.Insert(refIdx, result);
  finally
    FTasksLock.Leave;
  end;
end;

function TProgressImpl.AddTaskAfter(const description : string; const refTask : IProgressTask;
                                     maxValue : Double; autoStart : Boolean) : IProgressTask;
var
  refIdx : Integer;
begin
  FTasksLock.Enter;
  try
    result := TProgressTaskImpl.Create(description, maxValue, autoStart, AllocId);
    refIdx := FTasks.IndexOf(refTask);
    if refIdx < 0 then
      FTasks.Add(result)
    else
      FTasks.Insert(refIdx + 1, result);
  finally
    FTasksLock.Leave;
  end;
end;

function TProgressImpl.IsFinished : Boolean;
var
  i : Integer;
begin
  FTasksLock.Enter;
  try
    if FTasks.Count = 0 then
    begin
      result := False;
      Exit;
    end;
    for i := 0 to FTasks.Count - 1 do
    begin
      if not FTasks[i].IsFinished then
      begin
        result := False;
        Exit;
      end;
    end;
    result := True;
  finally
    FTasksLock.Leave;
  end;
end;

function TProgressImpl.WithAutoClear(value : Boolean) : IProgressConfig;
begin FAutoClear := value; result := Self; end;

function TProgressImpl.WithHideCompleted(value : Boolean) : IProgressConfig;
begin FHideCompleted := value; result := Self; end;

function TProgressImpl.WithRefreshMs(value : Integer) : IProgressConfig;
begin
  if value < 20 then value := 20;
  FRefreshMs := value;
  result := Self;
end;

function TProgressImpl.WithColumns(const columns : array of IProgressColumn) : IProgressConfig;
var
  i : Integer;
begin
  SetLength(FColumns, Length(columns));
  for i := 0 to High(columns) do
    FColumns[i] := columns[i];
  result := Self;
end;

function TProgressImpl.WithAutoRefresh(value : Boolean) : IProgressConfig;
begin
  FAutoRefresh := value;
  result := Self;
end;

function TProgressImpl.WithRenderHook(const hook : TProgressRenderHook) : IProgressConfig;
begin
  FRenderHook := hook;
  result := Self;
end;

procedure TProgressImpl.Start(const action : TProgressAction);
var
  display : ILiveDisplayConfig;
  ticker  : TProgressTickerThread;
  builder : TProgressBoardBuilder;
begin
  EnsureDefaultColumns;

  builder :=
    function : IRenderable
    begin
      result := BuildBoard;
      if Assigned(FRenderHook) then
        result := FRenderHook(result, SnapshotTasks);
    end;

  display := LiveDisplay(FConsole, builder()).WithAutoClear(FAutoClear);

  // Spectre's `Padder(0, 1)` equivalent: one blank line above and below
  // the progress block. Emitted outside the live region so the redraw
  // never has to repaint them - that was the source of the earlier
  // flicker.
  if not FAutoClear then
    FConsole.WriteLine;

  display.Start(
    procedure(const ctx : ILiveDisplay)
    begin
      if FAutoRefresh then
      begin
        ticker := TProgressTickerThread.Create(ctx, builder, FRefreshMs);
        try
          ticker.Start;
          try
            if Assigned(action) then
              action(Self);

            ctx.Update(builder());
          finally
            ticker.Terminate;
            ticker.WaitFor;
          end;
        finally
          ticker.Free;
        end;
      end
      else
      begin
        // Caller drives redraw - no animation ticker. Each task value/
        // description change still causes a repaint via its own update
        // path (the action callback invokes builder() at appropriate
        // points if it wants to push new state).
        if Assigned(action) then
          action(Self);
        ctx.Update(builder());
      end;
    end);

  // LiveDisplay already emits one closing newline when FAutoClear=False;
  // a second one here gives the bottom padding line.
  if not FAutoClear then
    FConsole.WriteLine;
end;

end.
