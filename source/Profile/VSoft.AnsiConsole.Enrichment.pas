unit VSoft.AnsiConsole.Enrichment;

{
  IProfileEnricher - Spectre-style hook that lets a CI provider tweak
  detected capabilities before they reach the console.

  Each enricher probes a single environment signal (one env var, possibly
  with a required value) and returns adjusted capabilities. The conventional
  effect is "this is a non-interactive CI runner, disable interactive
  prompts and live-redraw" - implemented by clearing TCapabilities.Interactive.

  ApplyEnrichers walks a list, applying each enricher whose Enabled() probe
  succeeds. Order matters only when multiple enrichers disagree on the same
  field; the last one wins.

  Built-in enrichers cover GitHub Actions, AppVeyor, Travis, GitLab CI,
  Jenkins, TeamCity, Bitbucket Pipelines, and ContinuaCI - the same set
  Spectre.Console ships with.
}

interface

uses
  VSoft.AnsiConsole.Capabilities;

type
  IProfileEnricher = interface
    ['{1B3D5F2A-7E4C-4A1B-9C0D-2F3E4A5B6C70}']
    function Name : string;
    function Enabled : Boolean;
    function Enrich(const caps : TCapabilities) : TCapabilities;
  end;

  { Convenience base: Enabled() checks an env var; Enrich() clears
    Interactive. Most CI providers want exactly that, so we share the base. }
  TEnvEnricher = class(TInterfacedObject, IProfileEnricher)
  strict private
    FName   : string;
    FEnvVar : string;
    FEnvVal : string;   // empty => any non-empty value qualifies
  public
    constructor Create(const aName, envVar : string); overload;
    constructor Create(const aName, envVar, envVal : string); overload;
    function Name : string;
    function Enabled : Boolean; virtual;
    function Enrich(const caps : TCapabilities) : TCapabilities; virtual;
  end;

{ The shipped enrichers. }
function GitHubActionsEnricher : IProfileEnricher;
function AppVeyorEnricher      : IProfileEnricher;
function TravisEnricher        : IProfileEnricher;
function GitLabCIEnricher      : IProfileEnricher;
function JenkinsEnricher       : IProfileEnricher;
function TeamCityEnricher      : IProfileEnricher;
function BitbucketEnricher     : IProfileEnricher;
function ContinuaCIEnricher    : IProfileEnricher;

{ Returns a fresh array of all the enrichers above (one entry per
  service). Callers can subset / extend / reorder freely. }
function DefaultEnrichers : TArray<IProfileEnricher>;

{ Applies every enabled enricher in `enrichers`, threading the result so
  later enrichers see earlier overrides. A nil-or-empty array is a no-op. }
function ApplyEnrichers(const caps : TCapabilities;
                          const enrichers : TArray<IProfileEnricher>) : TCapabilities;

implementation

uses
  System.SysUtils;

{ TEnvEnricher }

constructor TEnvEnricher.Create(const aName, envVar : string);
begin
  inherited Create;
  FName   := aName;
  FEnvVar := envVar;
  FEnvVal := '';
end;

constructor TEnvEnricher.Create(const aName, envVar, envVal : string);
begin
  inherited Create;
  FName   := aName;
  FEnvVar := envVar;
  FEnvVal := envVal;
end;

function TEnvEnricher.Name : string;
begin
  result := FName;
end;

function TEnvEnricher.Enabled : Boolean;
var
  v : string;
begin
  v := GetEnvironmentVariable(FEnvVar);
  if v = '' then
  begin
    result := False;
    Exit;
  end;
  if FEnvVal = '' then
    result := True
  else
    result := SameText(v, FEnvVal);
end;

function TEnvEnricher.Enrich(const caps : TCapabilities) : TCapabilities;
begin
  // CI default: not a tty, user prompts and live redraws would block forever.
  result := caps.WithInteractive(False);
end;

{ Factories }

function GitHubActionsEnricher : IProfileEnricher;
begin
  result := TEnvEnricher.Create('GitHubActions', 'GITHUB_ACTIONS', 'true');
end;

function AppVeyorEnricher : IProfileEnricher;
begin
  result := TEnvEnricher.Create('AppVeyor', 'APPVEYOR');
end;

function TravisEnricher : IProfileEnricher;
begin
  result := TEnvEnricher.Create('Travis', 'TRAVIS', 'true');
end;

function GitLabCIEnricher : IProfileEnricher;
begin
  result := TEnvEnricher.Create('GitLabCI', 'GITLAB_CI', 'true');
end;

function JenkinsEnricher : IProfileEnricher;
begin
  result := TEnvEnricher.Create('Jenkins', 'JENKINS_URL');
end;

function TeamCityEnricher : IProfileEnricher;
begin
  result := TEnvEnricher.Create('TeamCity', 'TEAMCITY_VERSION');
end;

function BitbucketEnricher : IProfileEnricher;
begin
  result := TEnvEnricher.Create('Bitbucket', 'BITBUCKET_BUILD_NUMBER');
end;

function ContinuaCIEnricher : IProfileEnricher;
begin
  result := TEnvEnricher.Create('ContinuaCI', 'ContinuaCI.Version');
end;

function DefaultEnrichers : TArray<IProfileEnricher>;
begin
  SetLength(result, 8);
  result[0] := GitHubActionsEnricher;
  result[1] := AppVeyorEnricher;
  result[2] := TravisEnricher;
  result[3] := GitLabCIEnricher;
  result[4] := JenkinsEnricher;
  result[5] := TeamCityEnricher;
  result[6] := BitbucketEnricher;
  result[7] := ContinuaCIEnricher;
end;

function ApplyEnrichers(const caps : TCapabilities;
                          const enrichers : TArray<IProfileEnricher>) : TCapabilities;
var
  i : Integer;
begin
  result := caps;
  for i := 0 to High(enrichers) do
  begin
    if (enrichers[i] <> nil) and enrichers[i].Enabled then
      result := enrichers[i].Enrich(result);
  end;
end;

end.
