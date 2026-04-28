unit VSoft.AnsiConsole.Detection;

{
  Terminal capability detection. Phase 1: Windows-only implementation.
  POSIX detection ships in Phase 7.

  Rules mirror Spectre.Console's behaviour:
    - NO_COLOR env var (any value) disables all colors.
    - CLICOLOR_FORCE=1 forces color on even when output is redirected.
    - COLORTERM=truecolor|24bit -> truecolor.
    - TERM matching *-256color -> 8-bit.
    - On Windows, VT support is probed directly via SetConsoleMode. GetVersionEx
      is deliberately NOT used - unmanifested Delphi exes receive a compat-shim
      that reports Windows 8 on Win10/11, which would misclassify modern hosts
      as legacy. SetConsoleMode tells us the truth.
}

interface

uses
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Capabilities;

function DetectAnsiSupport   : Boolean;
function DetectColorSystem   : TColorSystem;
function DetectInteractive   : Boolean;
function DetectUnicode       : Boolean;
function DetectLegacyConsole : Boolean;
function DetectLinks(ansiSupported : Boolean) : Boolean;
function DetectCapabilities  : TCapabilities;

implementation

uses
  {$IFDEF MSWINDOWS} Winapi.Windows, {$ENDIF}
  System.SysUtils;

{$IFDEF MSWINDOWS}
const
  ENABLE_VIRTUAL_TERMINAL_PROCESSING = $0004;
{$ENDIF}

function EnvEquals(const name, value : string) : Boolean;
var
  v : string;
begin
  v := GetEnvironmentVariable(name);
  result := SameText(v, value);
end;

function EnvDefined(const name : string) : Boolean;
begin
  result := GetEnvironmentVariable(name) <> '';
end;

function EnvContains(const name, needle : string) : Boolean;
var
  v : string;
begin
  v := LowerCase(GetEnvironmentVariable(name));
  result := (v <> '') and (Pos(LowerCase(needle), v) > 0);
end;

{$IFDEF MSWINDOWS}
function StdOutIsConsole : Boolean;
var
  h    : THandle;
  mode : DWORD;
begin
  h := GetStdHandle(STD_OUTPUT_HANDLE);
  if h = INVALID_HANDLE_VALUE then
  begin
    result := False;
    Exit;
  end;
  result := GetConsoleMode(h, mode);
end;

function StdOutCodePage : DWORD;
begin
  result := GetConsoleOutputCP;
end;

{ Probe VT support by attempting to enable it. On Win10 build 10586+, modern
  Windows Terminal, ConEmu, etc. SetConsoleMode succeeds. On legacy pre-VT
  conhost the flag is silently ignored or rejected - we read back the mode to
  confirm the bit is actually set. A successful probe leaves VT enabled, so
  subsequent writes just work. }
function ProbeVirtualTerminal : Boolean;
var
  h        : THandle;
  mode     : DWORD;
  readback : DWORD;
begin
  h := GetStdHandle(STD_OUTPUT_HANDLE);
  if h = INVALID_HANDLE_VALUE then
  begin
    result := False;
    Exit;
  end;
  if not GetConsoleMode(h, mode) then
  begin
    result := False;
    Exit;
  end;
  if (mode and ENABLE_VIRTUAL_TERMINAL_PROCESSING) <> 0 then
  begin
    result := True;
    Exit;
  end;
  if not SetConsoleMode(h, mode or ENABLE_VIRTUAL_TERMINAL_PROCESSING) then
  begin
    result := False;
    Exit;
  end;
  // Some older hosts silently accept the call but drop the bit; verify.
  if not GetConsoleMode(h, readback) then
  begin
    result := False;
    Exit;
  end;
  result := (readback and ENABLE_VIRTUAL_TERMINAL_PROCESSING) <> 0;
end;
{$ENDIF}

function DetectInteractive : Boolean;
begin
  {$IFDEF MSWINDOWS}
  result := StdOutIsConsole;
  {$ELSE}
  result := False;
  {$ENDIF}
end;

function DetectLegacyConsole : Boolean;
begin
  {$IFDEF MSWINDOWS}
  // Not attached to a console - treat as non-legacy (color decision falls to
  // redirection / env var rules).
  if not StdOutIsConsole then
  begin
    result := False;
    Exit;
  end;
  result := not ProbeVirtualTerminal;
  {$ELSE}
  result := False;
  {$ENDIF}
end;

function DetectAnsiSupport : Boolean;
begin
  if EnvDefined('NO_COLOR') then
  begin
    result := False;
    Exit;
  end;

  if EnvEquals('CLICOLOR_FORCE', '1') then
  begin
    result := True;
    Exit;
  end;

  if not DetectInteractive then
  begin
    result := False;
    Exit;
  end;

  result := not DetectLegacyConsole;
end;

function DetectColorSystem : TColorSystem;
begin
  if EnvDefined('NO_COLOR') then
  begin
    result := TColorSystem.NoColors;
    Exit;
  end;

  if EnvContains('COLORTERM', 'truecolor') or EnvContains('COLORTERM', '24bit') then
  begin
    result := TColorSystem.TrueColor;
    Exit;
  end;

  if EnvContains('TERM', '256color') then
  begin
    result := TColorSystem.EightBit;
    Exit;
  end;

  {$IFDEF MSWINDOWS}
  // If VT probing succeeded, the host is Win10+ conhost / Windows Terminal /
  // ConEmu / etc. All of these handle truecolor, so default to the highest
  // fidelity. Consumers can still override via AnsiConsoleSettings later.
  if ProbeVirtualTerminal then
    result := TColorSystem.TrueColor
  else
    result := TColorSystem.Legacy;
  {$ELSE}
  result := TColorSystem.Standard;
  {$ENDIF}
end;

function DetectUnicode : Boolean;
begin
  {$IFDEF MSWINDOWS}
  if not StdOutIsConsole then
  begin
    result := StdOutCodePage = 65001;  // UTF-8
    Exit;
  end;
  result := True;
  {$ELSE}
  result := True;
  {$ENDIF}
end;

{ Heuristic for OSC 8 hyperlink support. Modern terminals advertise
  themselves via well-known environment variables; legacy conhost and
  most CI runners do not. Returns False when ANSI is unavailable. }
function DetectLinks(ansiSupported : Boolean) : Boolean;
var
  termProgram, term : string;
begin
  if not ansiSupported then
  begin
    result := False;
    Exit;
  end;

  // Windows Terminal sets WT_SESSION to a session GUID. Anything from
  // Windows Terminal supports OSC 8.
  if EnvDefined('WT_SESSION') then
  begin
    result := True;
    Exit;
  end;

  // Common modern terminal emulators broadcast their identity in
  // TERM_PROGRAM. The list mirrors Spectre's link-capable allowlist.
  termProgram := LowerCase(GetEnvironmentVariable('TERM_PROGRAM'));
  if (termProgram = 'iterm.app')
     or (termProgram = 'wezterm')
     or (termProgram = 'vscode')
     or (termProgram = 'hyper')
     or (termProgram = 'tabby')
     or (termProgram = 'apple_terminal') then
  begin
    result := True;
    Exit;
  end;

  // TERM identifies the terminfo capability. Direct-color and kitty
  // entries imply OSC 8 support.
  term := LowerCase(GetEnvironmentVariable('TERM'));
  if (Pos('xterm-direct', term) > 0)
     or (Pos('xterm-kitty', term) > 0)
     or (Pos('truecolor',   term) > 0) then
  begin
    result := True;
    Exit;
  end;

  // Spectre also treats anything with KITTY_WINDOW_ID set as OSC 8 capable.
  if EnvDefined('KITTY_WINDOW_ID') then
  begin
    result := True;
    Exit;
  end;

  result := False;
end;

function DetectCapabilities : TCapabilities;
var
  ansi      : Boolean;
  color     : TColorSystem;
  unicode   : Boolean;
  interact  : Boolean;
  legacy    : Boolean;
begin
  ansi     := DetectAnsiSupport;
  interact := DetectInteractive;
  legacy   := DetectLegacyConsole;
  unicode  := DetectUnicode;

  if ansi then
    color := DetectColorSystem
  else
    color := TColorSystem.NoColors;

  result := TCapabilities.Create(color, ansi, unicode, interact);
  result := result.WithIsLegacyConsole(legacy);
  result := result.WithLinks(DetectLinks(ansi));
end;

end.
