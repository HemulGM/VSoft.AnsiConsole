unit VSoft.AnsiConsole.Profile;

{
  IProfile - the per-console bundle of capabilities, dimensions, and output
  sink. It is mutable (capabilities and dimensions can be overridden) so that
  tests can construct a deterministic profile, and so that the Console can
  refresh Width/Height from the live terminal before each write.
}

interface

uses
  System.SysUtils,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Capabilities,
  VSoft.AnsiConsole.Rendering.AnsiWriter;

type
  IProfile = interface
    ['{D1E3E2C5-6E9F-4E1D-8D2F-8C4B1F0E4B2D}']
    function  GetCapabilities : TCapabilities;
    procedure SetCapabilities(const value : TCapabilities);
    function  GetWidth : Integer;
    procedure SetWidth(value : Integer);
    function  GetHeight : Integer;
    procedure SetHeight(value : Integer);
    function  GetEncoding : TEncoding;
    procedure SetEncoding(const value : TEncoding);
    function  GetOutput : IAnsiOutput;

    property Capabilities : TCapabilities read GetCapabilities write SetCapabilities;
    property Width        : Integer       read GetWidth        write SetWidth;
    property Height       : Integer       read GetHeight       write SetHeight;
    property Encoding     : TEncoding     read GetEncoding     write SetEncoding;
    property Output       : IAnsiOutput   read GetOutput;
  end;

  TProfile = class(TInterfacedObject, IProfile)
  strict private
    FCapabilities : TCapabilities;
    FWidth        : Integer;
    FHeight       : Integer;
    FEncoding     : TEncoding;
    FOutput       : IAnsiOutput;
    function  GetCapabilities : TCapabilities;
    procedure SetCapabilities(const value : TCapabilities);
    function  GetWidth : Integer;
    procedure SetWidth(value : Integer);
    function  GetHeight : Integer;
    procedure SetHeight(value : Integer);
    function  GetEncoding : TEncoding;
    procedure SetEncoding(const value : TEncoding);
    function  GetOutput : IAnsiOutput;
  public
    constructor Create(const output : IAnsiOutput; const caps : TCapabilities;
                        width, height : Integer); overload;
    constructor Create(const output : IAnsiOutput; const caps : TCapabilities); overload;
  end;

implementation

const
  DEFAULT_WIDTH  = 80;
  DEFAULT_HEIGHT = 24;

{ TProfile }

constructor TProfile.Create(const output : IAnsiOutput; const caps : TCapabilities;
                              width, height : Integer);
begin
  inherited Create;
  FOutput       := output;
  FCapabilities := caps;
  FWidth        := width;
  FHeight       := height;
  FEncoding     := TEncoding.UTF8;
end;

constructor TProfile.Create(const output : IAnsiOutput; const caps : TCapabilities);
begin
  Create(output, caps, DEFAULT_WIDTH, DEFAULT_HEIGHT);
end;

function TProfile.GetCapabilities : TCapabilities;
begin
  result := FCapabilities;
end;

procedure TProfile.SetCapabilities(const value : TCapabilities);
begin
  FCapabilities := value;
end;

function TProfile.GetWidth : Integer;
begin
  result := FWidth;
end;

procedure TProfile.SetWidth(value : Integer);
begin
  FWidth := value;
end;

function TProfile.GetHeight : Integer;
begin
  result := FHeight;
end;

procedure TProfile.SetHeight(value : Integer);
begin
  FHeight := value;
end;

function TProfile.GetEncoding : TEncoding;
begin
  result := FEncoding;
end;

procedure TProfile.SetEncoding(const value : TEncoding);
begin
  FEncoding := value;
end;

function TProfile.GetOutput : IAnsiOutput;
begin
  result := FOutput;
end;

end.
