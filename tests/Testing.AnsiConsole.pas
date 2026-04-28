unit Testing.AnsiConsole;

{
  Test support: a string-backed IAnsiOutput and a helper to build a captured
  IAnsiConsole for assertion-friendly testing.
}

interface

uses
  System.Classes,
  System.SysUtils,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Capabilities,
  VSoft.AnsiConsole.Rendering.AnsiWriter,
  VSoft.AnsiConsole.Console;

type
  { Extension of IAnsiOutput that lets tests inspect captured bytes. }
  ICapturedAnsiOutput = interface(IAnsiOutput)
    ['{8F1D5D4E-9A0C-4C45-8DDE-6E5B6B8E8D1A}']
    function  Text : string;
    procedure Clear;
  end;

  TStringAnsiOutput = class(TInterfacedObject, IAnsiOutput, ICapturedAnsiOutput)
  strict private
    FBuffer : TStringBuilder;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Write(const s : string);
    procedure Flush;
    function  Text : string;
    procedure Clear;
  end;

{ Builds a console whose output is captured in memory. `output` receives the
  same interface so tests can assert on `output.Text`. }
procedure BuildCapturedConsole(colorSystem : TColorSystem; width : Integer;
                                unicode : Boolean; out console : IAnsiConsole;
                                out output : ICapturedAnsiOutput); overload;
procedure BuildCapturedConsole(const caps : TCapabilities; width : Integer;
                                out console : IAnsiConsole;
                                out output : ICapturedAnsiOutput); overload;

implementation

{ TStringAnsiOutput }

constructor TStringAnsiOutput.Create;
begin
  inherited Create;
  FBuffer := TStringBuilder.Create;
end;

destructor TStringAnsiOutput.Destroy;
begin
  FBuffer.Free;
  inherited;
end;

procedure TStringAnsiOutput.Write(const s : string);
begin
  FBuffer.Append(s);
end;

procedure TStringAnsiOutput.Flush;
begin
  // no-op
end;

function TStringAnsiOutput.Text : string;
begin
  result := FBuffer.ToString;
end;

procedure TStringAnsiOutput.Clear;
begin
  FBuffer.Clear;
end;

procedure BuildCapturedConsole(colorSystem : TColorSystem; width : Integer;
                                unicode : Boolean; out console : IAnsiConsole;
                                out output : ICapturedAnsiOutput);
var
  caps : TCapabilities;
begin
  caps := TCapabilities.Create(colorSystem, True, unicode, True);
  BuildCapturedConsole(caps, width, console, output);
end;

procedure BuildCapturedConsole(const caps : TCapabilities; width : Integer;
                                out console : IAnsiConsole;
                                out output : ICapturedAnsiOutput);
var
  sink : TStringAnsiOutput;
begin
  sink := TStringAnsiOutput.Create;
  output := sink;
  console := CreateAnsiConsole(sink, caps, width, 24);
end;

end.
