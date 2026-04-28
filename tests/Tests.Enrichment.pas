unit Tests.Enrichment;

{
  Profile enrichment + AnsiConsoleSettings fixtures.

  These tests mutate process-level environment variables to drive the CI
  enrichers. Setup snapshots the current values so TearDown can restore
  them - skipping that cycle would leak state between tests when the
  runner reuses the process.
}

interface

uses
  DUnitX.TestFramework,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Capabilities,
  VSoft.AnsiConsole.Enrichment,
  VSoft.AnsiConsole.Settings,
  VSoft.AnsiConsole.Console;

type
  [TestFixture]
  TEnrichmentTests = class
  strict private
    FSavedGithub      : string;
    FSavedAppveyor    : string;
    FSavedTravis      : string;
    FSavedGitlab      : string;
    FSavedJenkins     : string;
    FSavedTeamcity    : string;
    FSavedBitbucket   : string;
    FSavedContinua    : string;
    procedure SaveEnv;
    procedure RestoreEnv;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure GitHubActions_Enricher_DisablesInteractive;
    [Test] procedure NoCiEnv_DefaultEnrichers_DoNotChangeCapabilities;
    [Test] procedure ApplyEnrichers_NilArray_IsNoOp;

    [Test] procedure Settings_AnsiOn_OverridesDetection;
    [Test] procedure Settings_ColorSystemTrueColor_Honoured;
    [Test] procedure Settings_InteractiveOff_OverridesDetection;
    [Test] procedure Settings_EnrichmentEnabled_AppliesEnrichers;
    [Test] procedure Settings_EnrichmentDisabled_SkipsEnrichers;
  end;

implementation

uses
  System.SysUtils
  {$IFDEF MSWINDOWS}, Winapi.Windows{$ENDIF};

procedure SetEnv(const name, value : string);
begin
  {$IFDEF MSWINDOWS}
  Winapi.Windows.SetEnvironmentVariable(PChar(name), PChar(value));
  {$ELSE}
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

procedure TEnrichmentTests.SaveEnv;
begin
  FSavedGithub    := GetEnvironmentVariable('GITHUB_ACTIONS');
  FSavedAppveyor  := GetEnvironmentVariable('APPVEYOR');
  FSavedTravis    := GetEnvironmentVariable('TRAVIS');
  FSavedGitlab    := GetEnvironmentVariable('GITLAB_CI');
  FSavedJenkins   := GetEnvironmentVariable('JENKINS_URL');
  FSavedTeamcity  := GetEnvironmentVariable('TEAMCITY_VERSION');
  FSavedBitbucket := GetEnvironmentVariable('BITBUCKET_BUILD_NUMBER');
  FSavedContinua  := GetEnvironmentVariable('ContinuaCI.Version');
end;

procedure TEnrichmentTests.RestoreEnv;
  procedure Restore(const name, prev : string);
  begin
    if prev = '' then
      ClearEnv(name)
    else
      SetEnv(name, prev);
  end;
begin
  Restore('GITHUB_ACTIONS',         FSavedGithub);
  Restore('APPVEYOR',               FSavedAppveyor);
  Restore('TRAVIS',                 FSavedTravis);
  Restore('GITLAB_CI',              FSavedGitlab);
  Restore('JENKINS_URL',            FSavedJenkins);
  Restore('TEAMCITY_VERSION',       FSavedTeamcity);
  Restore('BITBUCKET_BUILD_NUMBER', FSavedBitbucket);
  Restore('ContinuaCI.Version',     FSavedContinua);
end;

procedure TEnrichmentTests.Setup;
begin
  SaveEnv;
  ClearEnv('GITHUB_ACTIONS');
  ClearEnv('APPVEYOR');
  ClearEnv('TRAVIS');
  ClearEnv('GITLAB_CI');
  ClearEnv('JENKINS_URL');
  ClearEnv('TEAMCITY_VERSION');
  ClearEnv('BITBUCKET_BUILD_NUMBER');
  ClearEnv('ContinuaCI.Version');
end;

procedure TEnrichmentTests.TearDown;
begin
  RestoreEnv;
end;

procedure TEnrichmentTests.GitHubActions_Enricher_DisablesInteractive;
var
  caps    : TCapabilities;
  enriched : TCapabilities;
begin
  SetEnv('GITHUB_ACTIONS', 'true');
  caps := TCapabilities.Default.WithInteractive(True);
  Assert.IsTrue(GitHubActionsEnricher.Enabled, 'Enricher should be enabled');
  enriched := GitHubActionsEnricher.Enrich(caps);
  Assert.IsFalse(enriched.Interactive,
    'GitHubActions enrichment should clear Interactive');
end;

procedure TEnrichmentTests.NoCiEnv_DefaultEnrichers_DoNotChangeCapabilities;
var
  caps     : TCapabilities;
  enriched : TCapabilities;
begin
  // No CI env vars set in Setup. ApplyEnrichers should be a no-op
  // because every Enabled() probe returns False.
  caps := TCapabilities.Default.WithInteractive(True);
  enriched := ApplyEnrichers(caps, DefaultEnrichers);
  Assert.IsTrue(enriched.Interactive,
    'No CI env => Interactive must remain True');
end;

procedure TEnrichmentTests.ApplyEnrichers_NilArray_IsNoOp;
var
  caps     : TCapabilities;
  enriched : TCapabilities;
  empty    : TArray<IProfileEnricher>;
begin
  caps := TCapabilities.Default.WithInteractive(True);
  SetLength(empty, 0);
  enriched := ApplyEnrichers(caps, empty);
  Assert.IsTrue(enriched.Interactive);
  Assert.AreEqual<TColorSystem>(caps.ColorSystem, enriched.ColorSystem);
end;

procedure TEnrichmentTests.Settings_AnsiOn_OverridesDetection;
var
  s    : TAnsiConsoleSettings;
  caps : TCapabilities;
begin
  s := TAnsiConsoleSettings.Default;
  s.Ansi := TAnsiSupport.On;
  s.Enrichment := False;
  caps := BuildCapabilities(s);
  Assert.IsTrue(caps.Ansi, 'Ansi=TAnsiSupport.On must produce Ansi=True');
end;

procedure TEnrichmentTests.Settings_ColorSystemTrueColor_Honoured;
var
  s    : TAnsiConsoleSettings;
  caps : TCapabilities;
begin
  s := TAnsiConsoleSettings.Default;
  s.ColorSystem := TColorSystemSupport.TrueColor;
  s.Enrichment  := False;
  caps := BuildCapabilities(s);
  Assert.AreEqual<TColorSystem>(TColorSystem.TrueColor, caps.ColorSystem);
end;

procedure TEnrichmentTests.Settings_InteractiveOff_OverridesDetection;
var
  s    : TAnsiConsoleSettings;
  caps : TCapabilities;
begin
  s := TAnsiConsoleSettings.Default;
  s.Interactive := TInteractionSupport.Off;
  s.Enrichment  := False;
  caps := BuildCapabilities(s);
  Assert.IsFalse(caps.Interactive, 'Interactive=TInteractionSupport.Off must yield Interactive=False');
end;

procedure TEnrichmentTests.Settings_EnrichmentEnabled_AppliesEnrichers;
var
  s    : TAnsiConsoleSettings;
  caps : TCapabilities;
begin
  SetEnv('GITHUB_ACTIONS', 'true');
  s := TAnsiConsoleSettings.Default;
  s.Interactive := TInteractionSupport.On;        // Force Interactive=True before enrichment
  s.Enrichment  := True;
  caps := BuildCapabilities(s);
  Assert.IsFalse(caps.Interactive,
    'GITHUB_ACTIONS env should let the enricher clear Interactive');
end;

procedure TEnrichmentTests.Settings_EnrichmentDisabled_SkipsEnrichers;
var
  s    : TAnsiConsoleSettings;
  caps : TCapabilities;
begin
  SetEnv('GITHUB_ACTIONS', 'true');
  s := TAnsiConsoleSettings.Default;
  s.Interactive := TInteractionSupport.On;
  s.Enrichment  := False;
  caps := BuildCapabilities(s);
  Assert.IsTrue(caps.Interactive,
    'Enrichment=False should bypass the CI enricher entirely');
end;

initialization
  TDUnitX.RegisterTestFixture(TEnrichmentTests);

end.
