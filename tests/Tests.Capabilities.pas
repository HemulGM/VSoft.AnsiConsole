unit Tests.Capabilities;

{
  Capability detection fixtures - probes the env-var heuristics in
  Detection.DetectLinks. Each test sets/clears env vars before calling
  the probe to assert the expected outcome.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Capabilities,
  VSoft.AnsiConsole.Detection;

type
  [TestFixture]
  TCapabilitiesTests = class
  strict private
    FSavedWtSession    : string;
    FSavedTermProgram  : string;
    FSavedTerm         : string;
    FSavedKittyId      : string;
    procedure SaveEnv;
    procedure RestoreEnv;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure DetectLinks_AnsiOff_ReturnsFalse;
    [Test] procedure DetectLinks_WtSession_ReturnsTrue;
    [Test] procedure DetectLinks_TermProgramITerm_ReturnsTrue;
    [Test] procedure DetectLinks_TermProgramVscode_ReturnsTrue;
    [Test] procedure DetectLinks_TermXtermKitty_ReturnsTrue;
    [Test] procedure DetectLinks_DumbTerminal_ReturnsFalse;
    [Test] procedure DetectLinks_KittyWindowId_ReturnsTrue;
    [Test] procedure DetectLinks_TermProgramWezTerm_ReturnsTrue;
    [Test] procedure DetectLinks_XtermDirect_ReturnsTrue;

    [Test] procedure Default_HasStandardColorAndAnsi;
    [Test] procedure NoColors_HasCsNoColorsAndNoAnsi;
    [Test] procedure WithColorSystem_OverridesField;
    [Test] procedure WithLinks_OverridesField;
    [Test] procedure WithUnicode_OverridesField;
    [Test] procedure WithInteractive_OverridesField;
    [Test] procedure WithAlternateBuffer_OverridesField;
    [Test] procedure WithIsLegacyConsole_OverridesField;
    [Test] procedure With_ChainedReturnsCorrectFinalState;
    [Test] procedure Create_AnsiFalse_DefaultsLegacyConsoleTrue;
  end;

implementation

uses
  System.SysUtils
  {$IFDEF MSWINDOWS}, Winapi.Windows{$ENDIF};

procedure SetEnv(const name, value : string);
begin
  {$IFDEF MSWINDOWS}
  // SetEnvironmentVariable mutates the current-process env block; the
  // RTL's GetEnvironmentVariable reads from there.
  Winapi.Windows.SetEnvironmentVariable(PChar(name), PChar(value));
  {$ELSE}
  if value = '' then
    System.SysUtils.SetEnvironmentVariable(name, '')
  else
    System.SysUtils.SetEnvironmentVariable(name, value);
  {$ENDIF}
end;

procedure ClearEnv(const name : string);
begin
  {$IFDEF MSWINDOWS}
  Winapi.Windows.SetEnvironmentVariable(PChar(name), nil);
  {$ELSE}
  System.SysUtils.SetEnvironmentVariable(name, '');
  {$ENDIF}
end;

procedure TCapabilitiesTests.SaveEnv;
begin
  FSavedWtSession   := GetEnvironmentVariable('WT_SESSION');
  FSavedTermProgram := GetEnvironmentVariable('TERM_PROGRAM');
  FSavedTerm        := GetEnvironmentVariable('TERM');
  FSavedKittyId     := GetEnvironmentVariable('KITTY_WINDOW_ID');
end;

procedure TCapabilitiesTests.RestoreEnv;
  procedure Restore(const name, prev : string);
  begin
    if prev = '' then
      ClearEnv(name)
    else
      SetEnv(name, prev);
  end;
begin
  Restore('WT_SESSION',      FSavedWtSession);
  Restore('TERM_PROGRAM',    FSavedTermProgram);
  Restore('TERM',            FSavedTerm);
  Restore('KITTY_WINDOW_ID', FSavedKittyId);
end;

procedure TCapabilitiesTests.Setup;
begin
  SaveEnv;
  // Clear all known link signals so each test starts from a known state.
  ClearEnv('WT_SESSION');
  ClearEnv('TERM_PROGRAM');
  ClearEnv('TERM');
  ClearEnv('KITTY_WINDOW_ID');
end;

procedure TCapabilitiesTests.TearDown;
begin
  RestoreEnv;
end;

procedure TCapabilitiesTests.DetectLinks_AnsiOff_ReturnsFalse;
begin
  // ANSI off short-circuits regardless of any env var.
  SetEnv('WT_SESSION', '{abc}');
  Assert.IsFalse(DetectLinks(False));
end;

procedure TCapabilitiesTests.DetectLinks_WtSession_ReturnsTrue;
begin
  SetEnv('WT_SESSION', '{abc-session-guid}');
  Assert.IsTrue(DetectLinks(True));
end;

procedure TCapabilitiesTests.DetectLinks_TermProgramITerm_ReturnsTrue;
begin
  SetEnv('TERM_PROGRAM', 'iTerm.app');
  Assert.IsTrue(DetectLinks(True));
end;

procedure TCapabilitiesTests.DetectLinks_TermProgramVscode_ReturnsTrue;
begin
  SetEnv('TERM_PROGRAM', 'vscode');
  Assert.IsTrue(DetectLinks(True));
end;

procedure TCapabilitiesTests.DetectLinks_TermXtermKitty_ReturnsTrue;
begin
  SetEnv('TERM', 'xterm-kitty');
  Assert.IsTrue(DetectLinks(True));
end;

procedure TCapabilitiesTests.DetectLinks_DumbTerminal_ReturnsFalse;
begin
  SetEnv('TERM', 'dumb');
  Assert.IsFalse(DetectLinks(True));
end;

procedure TCapabilitiesTests.DetectLinks_KittyWindowId_ReturnsTrue;
begin
  // KITTY_WINDOW_ID being set is enough on its own; no other signal needed.
  SetEnv('KITTY_WINDOW_ID', '1');
  Assert.IsTrue(DetectLinks(True));
end;

procedure TCapabilitiesTests.DetectLinks_TermProgramWezTerm_ReturnsTrue;
begin
  SetEnv('TERM_PROGRAM', 'WezTerm');
  Assert.IsTrue(DetectLinks(True),
    'WezTerm signals OSC 8 support via TERM_PROGRAM');
end;

procedure TCapabilitiesTests.DetectLinks_XtermDirect_ReturnsTrue;
begin
  SetEnv('TERM', 'xterm-direct');
  Assert.IsTrue(DetectLinks(True));
end;

procedure TCapabilitiesTests.Default_HasStandardColorAndAnsi;
var
  c : TCapabilities;
begin
  c := TCapabilities.Default;
  Assert.AreEqual<TColorSystem>(TColorSystem.Standard, c.ColorSystem);
  Assert.IsTrue(c.Ansi,        'Default profile must have ANSI on');
  Assert.IsTrue(c.Unicode,     'Default profile must have Unicode on');
  Assert.IsTrue(c.Interactive, 'Default profile must be Interactive');
end;

procedure TCapabilitiesTests.NoColors_HasCsNoColorsAndNoAnsi;
var
  c : TCapabilities;
begin
  c := TCapabilities.NoColors;
  Assert.AreEqual<TColorSystem>(TColorSystem.NoColors, c.ColorSystem);
  Assert.IsFalse(c.Ansi);
  Assert.IsFalse(c.Unicode);
  Assert.IsFalse(c.Interactive);
end;

procedure TCapabilitiesTests.WithColorSystem_OverridesField;
var
  c : TCapabilities;
begin
  c := TCapabilities.Default.WithColorSystem(TColorSystem.TrueColor);
  Assert.AreEqual<TColorSystem>(TColorSystem.TrueColor, c.ColorSystem);
  // Other fields untouched.
  Assert.IsTrue(c.Ansi);
  Assert.IsTrue(c.Unicode);
end;

procedure TCapabilitiesTests.WithLinks_OverridesField;
var
  c : TCapabilities;
begin
  c := TCapabilities.Default;
  Assert.IsFalse(c.Links, 'Default starts with Links=False');
  c := c.WithLinks(True);
  Assert.IsTrue(c.Links);
end;

procedure TCapabilitiesTests.WithUnicode_OverridesField;
var
  c : TCapabilities;
begin
  c := TCapabilities.Default.WithUnicode(False);
  Assert.IsFalse(c.Unicode);
end;

procedure TCapabilitiesTests.WithInteractive_OverridesField;
var
  c : TCapabilities;
begin
  c := TCapabilities.Default.WithInteractive(False);
  Assert.IsFalse(c.Interactive);
end;

procedure TCapabilitiesTests.WithAlternateBuffer_OverridesField;
var
  c : TCapabilities;
begin
  c := TCapabilities.Default;
  Assert.IsFalse(c.AlternateBuffer, 'AlternateBuffer defaults False');
  c := c.WithAlternateBuffer(True);
  Assert.IsTrue(c.AlternateBuffer);
end;

procedure TCapabilitiesTests.WithIsLegacyConsole_OverridesField;
var
  c : TCapabilities;
begin
  c := TCapabilities.Default.WithIsLegacyConsole(True);
  Assert.IsTrue(c.IsLegacyConsole);
end;

procedure TCapabilitiesTests.With_ChainedReturnsCorrectFinalState;
var
  c : TCapabilities;
begin
  // Chained With* mutations should compose without losing earlier
  // overrides (records are value-typed; each With returns a new value).
  c := TCapabilities.NoColors
        .WithColorSystem(TColorSystem.TrueColor)
        .WithAnsi(True)
        .WithUnicode(True)
        .WithInteractive(True)
        .WithLinks(True)
        .WithAlternateBuffer(True);
  Assert.AreEqual<TColorSystem>(TColorSystem.TrueColor, c.ColorSystem);
  Assert.IsTrue(c.Ansi);
  Assert.IsTrue(c.Unicode);
  Assert.IsTrue(c.Interactive);
  Assert.IsTrue(c.Links);
  Assert.IsTrue(c.AlternateBuffer);
end;

procedure TCapabilitiesTests.Create_AnsiFalse_DefaultsLegacyConsoleTrue;
var
  c : TCapabilities;
begin
  // Documented behaviour: Create(..., ansi=False, ...) initialises
  // FIsLegacyConsole := not ansi, i.e. True.
  c := TCapabilities.Create(TColorSystem.Standard, False, True, True);
  Assert.IsTrue(c.IsLegacyConsole,
    'Constructing with Ansi=False should mark IsLegacyConsole=True by default');
end;

initialization
  TDUnitX.RegisterTestFixture(TCapabilitiesTests);

end.
