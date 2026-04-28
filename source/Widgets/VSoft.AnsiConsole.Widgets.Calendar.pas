unit VSoft.AnsiConsole.Widgets.Calendar;

{
  TCalendar - month-view calendar. Internally builds a TTable with seven
  columns (Sun-Sat by default) + title header. Current day and registered
  events are rendered with a highlight style (a trailing '*' marks event
  days).

  Week layout matches Sunday=0 (US) by default; use WithFirstDayOfWeek to
  start the week on Monday.
}

interface

uses
  System.SysUtils,
  System.DateUtils,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Borders.Table;

type
  TCalendarEvent = record
    Description : string;
    Year        : Integer;
    Month       : Integer;
    Day         : Integer;
  end;

  ICalendar = interface(IRenderable)
    ['{D2C1F3A5-4E5B-4C0A-8B76-3E2D1A5F7B90}']
    function WithHeader(value : Boolean) : ICalendar;
    function WithHighlightStyle(const value : TAnsiStyle) : ICalendar;
    function WithHeaderStyle(const value : TAnsiStyle) : ICalendar;
    function WithFirstDayOfWeek(value : Integer) : ICalendar;
    function WithBorder(kind : TTableBorderKind) : ICalendar;
    function WithBorderStyle(const value : TAnsiStyle) : ICalendar;
    function WithCulture(const value : string) : ICalendar;
    function AddCalendarEvent(year, month, day : Integer) : ICalendar; overload;
    function AddCalendarEvent(const description : string; year, month, day : Integer) : ICalendar; overload;
  end;

  TCalendar = class(TInterfacedObject, IRenderable, ICalendar)
  strict private
    FYear            : Integer;
    FMonth           : Integer;
    FDay             : Integer;
    FShowHeader      : Boolean;
    FHighlightStyle  : TAnsiStyle;
    FHeaderStyle     : TAnsiStyle;
    FFirstDayOfWeek  : Integer;  // 0 = Sunday, 1 = Monday
    FBorderKind      : TTableBorderKind;
    FBorderStyle     : TAnsiStyle;
    FCulture         : string;   // empty = process default; otherwise BCP-47 / locale name (e.g. 'fr-FR')
    FEvents          : TArray<TCalendarEvent>;
    function HasEvent(day : Integer) : Boolean;
    function GetFormatSettings : TFormatSettings;
    function BuildTable(const options : TRenderOptions) : IRenderable;
  public
    constructor Create(year, month : Integer); overload;
    constructor Create(year, month, day : Integer); overload;

    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;

    function WithHeader(value : Boolean) : ICalendar;
    function WithHighlightStyle(const value : TAnsiStyle) : ICalendar;
    function WithHeaderStyle(const value : TAnsiStyle) : ICalendar;
    function WithFirstDayOfWeek(value : Integer) : ICalendar;
    function WithBorder(kind : TTableBorderKind) : ICalendar;
    function WithBorderStyle(const value : TAnsiStyle) : ICalendar;
    function WithCulture(const value : string) : ICalendar;
    function AddCalendarEvent(year, month, day : Integer) : ICalendar; overload;
    function AddCalendarEvent(const description : string; year, month, day : Integer) : ICalendar; overload;
  end;

function Calendar(year, month : Integer) : ICalendar; overload;
function Calendar(year, month, day : Integer) : ICalendar; overload;
function Calendar(const date : TDateTime) : ICalendar; overload;

implementation

uses
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Widgets.Text,
  VSoft.AnsiConsole.Widgets.Markup,
  VSoft.AnsiConsole.Widgets.Table;

const
  MONTH_NAMES : array[1..12] of string = (
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December');

  { Abbreviated weekday names - three letters starting Sunday. }
  WEEKDAY_ABBR : array[0..6] of string = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');

function Calendar(year, month : Integer) : ICalendar;
begin
  result := TCalendar.Create(year, month, 1);
end;

function Calendar(year, month, day : Integer) : ICalendar;
begin
  result := TCalendar.Create(year, month, day);
end;

function Calendar(const date : TDateTime) : ICalendar;
var
  y, m, d : Word;
begin
  DecodeDate(date, y, m, d);
  result := TCalendar.Create(y, m, d);
end;

{ TCalendar }

constructor TCalendar.Create(year, month : Integer);
begin
  Create(year, month, 1);
end;

constructor TCalendar.Create(year, month, day : Integer);
begin
  inherited Create;
  FYear            := year;
  FMonth           := month;
  FDay             := day;
  FShowHeader      := True;
  FHighlightStyle  := TAnsiStyle.Plain.WithForeground(TAnsiColor.SkyBlue3);
  FHeaderStyle     := TAnsiStyle.Plain;
  FFirstDayOfWeek  := 0;  // Sunday
  FBorderKind      := TTableBorderKind.Square;
  FBorderStyle     := TAnsiStyle.Plain;
  FCulture         := '';
end;

function TCalendar.WithHeader(value : Boolean) : ICalendar;
begin
  FShowHeader := value;
  result := Self;
end;

function TCalendar.WithHighlightStyle(const value : TAnsiStyle) : ICalendar;
begin
  FHighlightStyle := value;
  result := Self;
end;

function TCalendar.WithHeaderStyle(const value : TAnsiStyle) : ICalendar;
begin
  FHeaderStyle := value;
  result := Self;
end;

function TCalendar.WithFirstDayOfWeek(value : Integer) : ICalendar;
begin
  FFirstDayOfWeek := value and 7;
  result := Self;
end;

function TCalendar.WithBorder(kind : TTableBorderKind) : ICalendar;
begin
  FBorderKind := kind;
  result := Self;
end;

function TCalendar.WithBorderStyle(const value : TAnsiStyle) : ICalendar;
begin
  FBorderStyle := value;
  result := Self;
end;

function TCalendar.WithCulture(const value : string) : ICalendar;
begin
  // BCP-47 / Windows locale name (e.g. 'fr-FR'). Drives the long month
  // name in the title and the short weekday names in the column headers.
  // Empty means "use process default".
  FCulture := value;
  result := Self;
end;

function TCalendar.GetFormatSettings : TFormatSettings;
begin
  if FCulture = '' then
    result := System.SysUtils.FormatSettings
  else
  try
    result := TFormatSettings.Create(FCulture);
  except
    // Unknown culture name - fall back to process default rather than
    // letting an invalid WithCulture(...) crash the render path.
    result := System.SysUtils.FormatSettings;
  end;
end;

function TCalendar.AddCalendarEvent(year, month, day : Integer) : ICalendar;
begin
  result := AddCalendarEvent('', year, month, day);
end;

function TCalendar.AddCalendarEvent(const description : string;
                                      year, month, day : Integer) : ICalendar;
var
  ev : TCalendarEvent;
begin
  ev.Description := description;
  ev.Year        := year;
  ev.Month       := month;
  ev.Day         := day;
  SetLength(FEvents, Length(FEvents) + 1);
  FEvents[High(FEvents)] := ev;
  result := Self;
end;

function TCalendar.HasEvent(day : Integer) : Boolean;
var
  i : Integer;
begin
  for i := 0 to High(FEvents) do
    if (FEvents[i].Year = FYear) and (FEvents[i].Month = FMonth)
       and (FEvents[i].Day = day) then
    begin
      result := True;
      Exit;
    end;
  result := False;
end;

function DaysInMonthFn(year, month : Integer) : Integer;
begin
  result := DaysInAMonth(year, month);
end;

{ Returns the weekday (0=Sunday..6=Saturday) of the 1st of year/month. }
function FirstWeekdayOfMonth(year, month : Integer) : Integer;
var
  dt : TDateTime;
  dow : Integer;
begin
  dt := EncodeDate(year, month, 1);
  // TDateTime's DayOfWeek: 1=Sunday..7=Saturday (Delphi convention)
  dow := System.SysUtils.DayOfWeek(dt);
  result := dow - 1;
end;

function TCalendar.BuildTable(const options : TRenderOptions) : IRenderable;
var
  tbl    : ITable;
  i        : Integer;
  col      : Integer;
  days     : Integer;
  firstDow : Integer;
  leading  : Integer;
  currentDay : Integer;
  dayCol   : Integer;
  row      : TArray<IRenderable>;
  cellStr  : string;
  isToday  : Boolean;
  isEvent  : Boolean;
  style    : TAnsiStyle;
  weekdayOrder : array[0..6] of Integer;
  fs       : TFormatSettings;
  monthName : string;
  dayName   : string;
begin
  tbl := Table;
  tbl.WithBorder(FBorderKind).WithBorderStyle(FBorderStyle).WithShowHeader(True);

  fs := GetFormatSettings;

  if FShowHeader then
  begin
    monthName := fs.LongMonthNames[FMonth];
    if monthName = '' then
      monthName := MONTH_NAMES[FMonth];   // RTL fallback if locale lacks data
    tbl.WithTitle(monthName + ' ' + IntToStr(FYear));
  end;

  // Column order based on first day of week. TFormatSettings.ShortDayNames
  // is 1-based with 1=Sunday..7=Saturday, matching our 0-based 0=Sunday
  // convention with a +1 offset.
  for i := 0 to 6 do
    weekdayOrder[i] := (FFirstDayOfWeek + i) mod 7;
  for i := 0 to 6 do
  begin
    dayName := fs.ShortDayNames[weekdayOrder[i] + 1];
    if dayName = '' then
      dayName := WEEKDAY_ABBR[weekdayOrder[i]];
    tbl.AddColumn(dayName, TAlignment.Center);
  end;

  days := DaysInMonthFn(FYear, FMonth);
  firstDow := FirstWeekdayOfMonth(FYear, FMonth);

  leading := (firstDow - FFirstDayOfWeek + 7) mod 7;

  currentDay := 1;
  SetLength(row, 7);
  for i := 0 to 6 do
    row[i] := Text(' ');

  // Fill leading empty cells
  dayCol := leading;
  col := 0;
  while col < dayCol do
  begin
    row[col] := Text(' ');
    Inc(col);
  end;

  while currentDay <= days do
  begin
    cellStr := IntToStr(currentDay);
    isToday := (currentDay = FDay);
    isEvent := HasEvent(currentDay);
    if isEvent then cellStr := cellStr + '*';

    if isToday or isEvent then
    begin
      style := FHighlightStyle;
      row[col] := Text(cellStr, style);
    end
    else
      row[col] := Text(cellStr);

    Inc(currentDay);
    Inc(col);

    if col = 7 then
    begin
      tbl.AddRow(row);
      col := 0;
      for i := 0 to 6 do
        row[i] := Text(' ');
    end;
  end;

  if col > 0 then
  begin
    // fill trailing empties
    while col < 7 do
    begin
      row[col] := Text(' ');
      Inc(col);
    end;
    tbl.AddRow(row);
  end;

  // Silence unused-param warning for options
  if options.Width < 0 then ;
  result := tbl;
end;

function TCalendar.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
var
  t : IRenderable;
begin
  t := BuildTable(options);
  result := t.Measure(options, maxWidth);
end;

function TCalendar.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  t : IRenderable;
begin
  t := BuildTable(options);
  result := t.Render(options, maxWidth);
end;

end.
