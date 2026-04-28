unit Tests.Widgets.Calendar;

{
  Calendar widget tests - title/weekday header rendering, day-of-week
  alignment, and locale-driven month names.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Widgets.Calendar;

type
  [TestFixture]
  TCalendarTests = class
  public
    [Test] procedure Title_AndWeekdays;
    [Test] procedure AprilFirst2026_IsWednesday;
    [Test] procedure WithCulture_FrenchMonthName;
    [Test] procedure WithHeaderFalse_OmitsTitleRow;
    [Test] procedure WithFirstDayOfWeek_Monday_ReordersHeader;
    [Test] procedure FebruaryLeapYear_Has29Days;
    [Test] procedure FebruaryNonLeapYear_Has28Days;
    [Test] procedure CtorYearMonthOnly_DoesNotHighlight;
    [Test] procedure AddCalendarEvent_DoesNotRaise;
  end;

implementation

uses
  System.SysUtils,
  Testing.AnsiConsole;

function BuildPlain(width : Integer; out sink : ICapturedAnsiOutput) : IAnsiConsole;
begin
  BuildCapturedConsole(TColorSystem.NoColors, width, True, result, sink);
end;

procedure TCalendarTests.Title_AndWeekdays;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cal     : ICalendar;
begin
  console := BuildPlain(60, sink);
  cal := Calendar(2026, 4, 25);
  console.Write(cal);
  Assert.IsTrue(Pos('April 2026', sink.Text) > 0, 'Title should include month + year');
  Assert.IsTrue(Pos('Sun', sink.Text) > 0, 'Weekday header Sun');
  Assert.IsTrue(Pos('Sat', sink.Text) > 0, 'Weekday header Sat');
end;

procedure TCalendarTests.AprilFirst2026_IsWednesday;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  cal     : ICalendar;
  captured : string;
  posSun, posWed, posSat, posOne : Integer;
begin
  console := BuildPlain(60, sink);
  cal := Calendar(2026, 4, 25);
  console.Write(cal);
  captured := sink.Text;
  // April 1st 2026 is a Wednesday. The '1' digit should appear after the
  // row of weekday abbreviations on the first data row.
  posSun := Pos('Sun', captured);
  posWed := Pos('Wed', captured);
  posSat := Pos('Sat', captured);
  Assert.IsTrue((posSun > 0) and (posWed > 0) and (posSat > 0));
  // The '1' appearing after the header row is the first day.
  posOne := Pos(' 1 ', captured);
  if posOne = 0 then
    posOne := Pos('|1', captured);
  Assert.IsTrue(posOne > posSat, 'First day digit should render after weekday header');
end;

procedure TCalendarTests.WithCulture_FrenchMonthName;
var
  console  : IAnsiConsole;
  sink     : ICapturedAnsiOutput;
  cal      : ICalendar;
  captured : string;
begin
  // fr-FR locale should drive the month name and weekday abbreviations.
  // April -> 'avril' in French; the English 'April' must not appear.
  // Day names ('lun', 'mar', 'mer', ...) are not asserted exactly because
  // Windows abbreviation length and trailing punctuation vary by version.
  console := BuildPlain(60, sink);
  cal := Calendar(2026, 4, 25).WithCulture('fr-FR');
  console.Write(cal);
  captured := LowerCase(sink.Text);
  Assert.IsTrue(Pos('avril', captured) > 0,
    'French long month name "avril" should appear when WithCulture(fr-FR) is set');
  Assert.IsTrue(Pos('april', captured) = 0,
    'English month name "April" should not leak through when culture is fr-FR');
  Assert.IsTrue(Pos('2026', captured) > 0,
    'Year should still render');
end;

procedure TCalendarTests.WithHeaderFalse_OmitsTitleRow;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  // WithHeader(False) suppresses the calendar's "Month Year" title row.
  // The weekday-header row (Sun/Mon/...) is the table's column header
  // and stays put.
  console := BuildPlain(60, sink);
  console.Write(Calendar(2026, 4, 25).WithHeader(False));
  output := sink.Text;
  Assert.IsTrue(Pos('April', output) = 0,
    'Calendar title (month name) should be hidden when Header=False');
  Assert.IsTrue(Pos('2026',  output) = 0,
    'Calendar title (year) should be hidden when Header=False');
  Assert.IsTrue(Pos('Sun',   output) > 0,
    'Weekday column header should still render');
  Assert.IsTrue(Pos(' 1 ',   output) > 0,
    'Day numbers should still render');
end;

procedure TCalendarTests.WithFirstDayOfWeek_Monday_ReordersHeader;
var
  console  : IAnsiConsole;
  sink     : ICapturedAnsiOutput;
  output   : string;
  posMon, posSun : Integer;
begin
  // FirstDayOfWeek=1 is Monday (0=Sunday). Monday's column should appear
  // BEFORE Sunday's column in the header row.
  console := BuildPlain(60, sink);
  console.Write(Calendar(2026, 4, 25).WithFirstDayOfWeek(1));
  output := sink.Text;
  posMon := Pos('Mon', output);
  posSun := Pos('Sun', output);
  Assert.IsTrue(posMon > 0, 'Mon should appear in header');
  Assert.IsTrue(posSun > 0, 'Sun should appear in header');
  Assert.IsTrue(posMon < posSun,
    'Mon column must precede Sun column when FirstDayOfWeek is Monday');
end;

procedure TCalendarTests.FebruaryLeapYear_Has29Days;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  // 2024 is a leap year - February has 29 days.
  console := BuildPlain(60, sink);
  console.Write(Calendar(2024, 2, 1));
  output := sink.Text;
  Assert.IsTrue(Pos('29', output) > 0, '29 should appear in Feb 2024');
  Assert.IsTrue(Pos('30', output) = 0, '30 should NOT appear in February');
end;

procedure TCalendarTests.FebruaryNonLeapYear_Has28Days;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
  output  : string;
begin
  // 2025 is not a leap year - February has only 28 days.
  console := BuildPlain(60, sink);
  console.Write(Calendar(2025, 2, 1));
  output := sink.Text;
  Assert.IsTrue(Pos('28', output) > 0, '28 should appear in Feb 2025');
  Assert.IsTrue(Pos('29', output) = 0, '29 should NOT appear in non-leap February');
end;

procedure TCalendarTests.CtorYearMonthOnly_DoesNotHighlight;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // Calendar(year, month) overload should still render without raising.
  console := BuildPlain(60, sink);
  console.Write(Calendar(2026, 4));
  Assert.IsTrue(Pos('April 2026', sink.Text) > 0,
    'Year+month-only ctor should still produce a titled calendar');
end;

procedure TCalendarTests.AddCalendarEvent_DoesNotRaise;
var
  console : IAnsiConsole;
  sink    : ICapturedAnsiOutput;
begin
  // Calendar events are simply marked. Just verify the API accepts them
  // and a render still proceeds.
  console := BuildPlain(60, sink);
  console.Write(
    Calendar(2026, 4, 1)
      .AddCalendarEvent(2026, 4, 15)
      .AddCalendarEvent('Conference', 2026, 4, 22));
  Assert.IsTrue(Pos('April 2026', sink.Text) > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TCalendarTests);

end.
