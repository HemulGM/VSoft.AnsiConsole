unit VSoft.AnsiConsole.Capabilities;

{
  TCapabilities - snapshot of what the terminal supports. Built once by
  detection, overrideable via TAnsiConsoleSettings (future phase).
}

interface

uses
  VSoft.AnsiConsole.Types;

type
  TCapabilities = record
  strict private
    FColorSystem     : TColorSystem;
    FAnsi            : Boolean;
    FLinks           : Boolean;
    FUnicode         : Boolean;
    FInteractive     : Boolean;
    FAlternateBuffer : Boolean;
    FIsLegacyConsole : Boolean;
  public
    class function Create(colorSystem : TColorSystem; ansi, unicode, interactive : Boolean) : TCapabilities; static;
    class function NoColors : TCapabilities; static;
    class function Default : TCapabilities; static;

    function WithColorSystem(value : TColorSystem) : TCapabilities;
    function WithAnsi(value : Boolean) : TCapabilities;
    function WithLinks(value : Boolean) : TCapabilities;
    function WithUnicode(value : Boolean) : TCapabilities;
    function WithInteractive(value : Boolean) : TCapabilities;
    function WithAlternateBuffer(value : Boolean) : TCapabilities;
    function WithIsLegacyConsole(value : Boolean) : TCapabilities;

    property ColorSystem     : TColorSystem read FColorSystem;
    property Ansi            : Boolean      read FAnsi;
    property Links           : Boolean      read FLinks;
    property Unicode         : Boolean      read FUnicode;
    property Interactive     : Boolean      read FInteractive;
    property AlternateBuffer : Boolean      read FAlternateBuffer;
    property IsLegacyConsole : Boolean      read FIsLegacyConsole;
  end;

implementation

{ TCapabilities }

class function TCapabilities.Create(colorSystem : TColorSystem; ansi, unicode, interactive : Boolean) : TCapabilities;
begin
  result.FColorSystem     := colorSystem;
  result.FAnsi            := ansi;
  result.FLinks           := False;
  result.FUnicode         := unicode;
  result.FInteractive     := interactive;
  result.FAlternateBuffer := False;
  result.FIsLegacyConsole := not ansi;
end;

class function TCapabilities.NoColors : TCapabilities;
begin
  result := TCapabilities.Create(TColorSystem.NoColors, False, False, False);
end;

class function TCapabilities.Default : TCapabilities;
begin
  result := TCapabilities.Create(TColorSystem.Standard, True, True, True);
end;

function TCapabilities.WithColorSystem(value : TColorSystem) : TCapabilities;
begin
  result := Self;
  result.FColorSystem := value;
end;

function TCapabilities.WithAnsi(value : Boolean) : TCapabilities;
begin
  result := Self;
  result.FAnsi := value;
end;

function TCapabilities.WithLinks(value : Boolean) : TCapabilities;
begin
  result := Self;
  result.FLinks := value;
end;

function TCapabilities.WithUnicode(value : Boolean) : TCapabilities;
begin
  result := Self;
  result.FUnicode := value;
end;

function TCapabilities.WithInteractive(value : Boolean) : TCapabilities;
begin
  result := Self;
  result.FInteractive := value;
end;

function TCapabilities.WithAlternateBuffer(value : Boolean) : TCapabilities;
begin
  result := Self;
  result.FAlternateBuffer := value;
end;

function TCapabilities.WithIsLegacyConsole(value : Boolean) : TCapabilities;
begin
  result := Self;
  result.FIsLegacyConsole := value;
end;

end.
