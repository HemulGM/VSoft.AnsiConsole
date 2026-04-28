unit Testing.ConsoleInput;

{
  Test support for prompts: a scripted IConsoleInput that dequeues a
  pre-built list of TConsoleKeyInfo values, plus a small helper to build
  each TConsoleKeyInfo without touching its record constructor directly.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Console.Types,
  VSoft.AnsiConsole.Input;

type
  TScriptedConsoleInput = class(TInterfacedObject, IConsoleInput)
  strict private
    FQueue : TQueue<TConsoleKeyInfo>;
  public
    constructor Create;
    destructor  Destroy; override;

    procedure Enqueue(const info : TConsoleKeyInfo); overload;
    procedure Enqueue(key : TConsoleKey); overload;
    procedure Enqueue(const s : string); overload;
    procedure EnqueueChar(ch : Char);

    function ReadKey(intercept : Boolean) : TConsoleKeyInfo;
    function KeyAvailable : Boolean;
  end;

  EScriptedInputExhausted = class(Exception);

{ Factory helpers. }
function KI(ch : Char; key : TConsoleKey) : TConsoleKeyInfo; overload;
function KI(key : TConsoleKey) : TConsoleKeyInfo; overload;
function KIChar(ch : Char) : TConsoleKeyInfo;

implementation

function KI(ch : Char; key : TConsoleKey) : TConsoleKeyInfo;
begin
  result := TConsoleKeyInfo.Create(ch, key, False, False, False);
end;

function KI(key : TConsoleKey) : TConsoleKeyInfo;
begin
  result := TConsoleKeyInfo.Create(#0, key, False, False, False);
end;

function KIChar(ch : Char) : TConsoleKeyInfo;
var
  key : TConsoleKey;
  code : Word;
begin
  // Pick a reasonable TConsoleKey enum value based on the character; for
  // printable ASCII we just pass the ord so downstream code can still read
  // info.KeyChar, which is what prompts actually rely on.
  code := Ord(UpCase(ch));
  if (code >= Ord(TConsoleKey.A)) and (code <= Ord(TConsoleKey.Z)) then
    key := TConsoleKey(code)
  else if (code >= Ord(TConsoleKey.D0)) and (code <= Ord(TConsoleKey.D9)) then
    key := TConsoleKey(code)
  else if ch = ' ' then
    key := TConsoleKey.Spacebar
  else
    key := TConsoleKey.None;
  result := TConsoleKeyInfo.Create(ch, key, False, False, False);
end;

{ TScriptedConsoleInput }

constructor TScriptedConsoleInput.Create;
begin
  inherited Create;
  FQueue := TQueue<TConsoleKeyInfo>.Create;
end;

destructor TScriptedConsoleInput.Destroy;
begin
  FQueue.Free;
  inherited;
end;

procedure TScriptedConsoleInput.Enqueue(const info : TConsoleKeyInfo);
begin
  FQueue.Enqueue(info);
end;

procedure TScriptedConsoleInput.Enqueue(key : TConsoleKey);
begin
  FQueue.Enqueue(KI(key));
end;

procedure TScriptedConsoleInput.Enqueue(const s : string);
var
  i : Integer;
begin
  for i := 1 to Length(s) do
    EnqueueChar(s[i]);
end;

procedure TScriptedConsoleInput.EnqueueChar(ch : Char);
begin
  FQueue.Enqueue(KIChar(ch));
end;

function TScriptedConsoleInput.ReadKey(intercept : Boolean) : TConsoleKeyInfo;
begin
  if FQueue.Count = 0 then
    raise EScriptedInputExhausted.Create('Scripted input exhausted');
  result := FQueue.Dequeue;
end;

function TScriptedConsoleInput.KeyAvailable : Boolean;
begin
  result := FQueue.Count > 0;
end;

end.
