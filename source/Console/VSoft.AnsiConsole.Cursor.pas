unit VSoft.AnsiConsole.Cursor;

{
  IAnsiConsoleCursor - Spectre's facade-level cursor primitive. Wraps the
  CSI control sequences for show/hide/position/move and routes them through
  a target IAnsiConsole's write path so output stays serialised with the
  rest of the library.

  Sequences:
    ESC[?25h / ESC[?25l    show / hide cursor (DECTCEM)
    ESC[<L>;<C>H           SetPosition (1-based row;col, ANSI CUP)
    ESC[<n>A/B/C/D         move up/down/right/left

  Note: SetPosition is 1-based to match Spectre and the underlying ANSI
  semantics. (column=1, line=1) is the upper-left corner.
}

{$SCOPEDENUMS ON}

interface

uses
  VSoft.AnsiConsole.Console;

type
  TCursorDirection = (Up, Down, Left, Right);

  IAnsiConsoleCursor = interface
    ['{B7C9D2A1-3F4B-4E8C-9A1D-5E7F2B3D4C50}']
    procedure Show(value : Boolean);
    procedure Hide;
    procedure SetPosition(column, line : Integer);
    procedure Move(direction : TCursorDirection; steps : Integer);
    procedure MoveUp(steps : Integer = 1);
    procedure MoveDown(steps : Integer = 1);
    procedure MoveLeft(steps : Integer = 1);
    procedure MoveRight(steps : Integer = 1);
  end;

function Cursor(const console : IAnsiConsole) : IAnsiConsoleCursor;

implementation

uses
  System.SysUtils,
  VSoft.AnsiConsole.Segment;

const
  ESC = #27;

type
  TAnsiConsoleCursor = class(TInterfacedObject, IAnsiConsoleCursor)
  strict private
    FConsole : IAnsiConsole;
    procedure EmitRaw(const s : string);
  public
    constructor Create(const console : IAnsiConsole);
    procedure Show(value : Boolean);
    procedure Hide;
    procedure SetPosition(column, line : Integer);
    procedure Move(direction : TCursorDirection; steps : Integer);
    procedure MoveUp(steps : Integer = 1);
    procedure MoveDown(steps : Integer = 1);
    procedure MoveLeft(steps : Integer = 1);
    procedure MoveRight(steps : Integer = 1);
  end;

function Cursor(const console : IAnsiConsole) : IAnsiConsoleCursor;
begin
  result := TAnsiConsoleCursor.Create(console);
end;

{ TAnsiConsoleCursor }

constructor TAnsiConsoleCursor.Create(const console : IAnsiConsole);
begin
  inherited Create;
  FConsole := console;
end;

procedure TAnsiConsoleCursor.EmitRaw(const s : string);
var
  segs : TAnsiSegments;
begin
  if (s = '') or (FConsole = nil) then Exit;
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.ControlCode(s);
  FConsole.Write(segs);
end;

procedure TAnsiConsoleCursor.Show(value : Boolean);
begin
  if value then
    EmitRaw(ESC + '[?25h')
  else
    EmitRaw(ESC + '[?25l');
end;

procedure TAnsiConsoleCursor.Hide;
begin
  Show(False);
end;

procedure TAnsiConsoleCursor.SetPosition(column, line : Integer);
begin
  if column < 1 then column := 1;
  if line   < 1 then line   := 1;
  EmitRaw(ESC + '[' + IntToStr(line) + ';' + IntToStr(column) + 'H');
end;

procedure TAnsiConsoleCursor.Move(direction : TCursorDirection; steps : Integer);
const
  CMD : array[TCursorDirection] of Char = ('A', 'B', 'D', 'C');
begin
  if steps < 1 then Exit;
  EmitRaw(ESC + '[' + IntToStr(steps) + CMD[direction]);
end;

procedure TAnsiConsoleCursor.MoveUp(steps : Integer);
begin
  Move(TCursorDirection.Up, steps);
end;

procedure TAnsiConsoleCursor.MoveDown(steps : Integer);
begin
  Move(TCursorDirection.Down, steps);
end;

procedure TAnsiConsoleCursor.MoveLeft(steps : Integer);
begin
  Move(TCursorDirection.Left, steps);
end;

procedure TAnsiConsoleCursor.MoveRight(steps : Integer);
begin
  Move(TCursorDirection.Right, steps);
end;

end.
