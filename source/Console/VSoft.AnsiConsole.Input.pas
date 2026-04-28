unit VSoft.AnsiConsole.Input;

{
  IConsoleInput - thin abstraction over VSoft.System.Console's key input so
  that prompts can be driven by scripted input in tests.

  The default implementation forwards to System.Console.TConsole.ReadKey /
  .KeyAvailable. A test implementation (TScriptedConsoleInput under tests\)
  dequeues a pre-built TConsoleKeyInfo array.

  We expose TConsoleKey / TConsoleKeyInfo from System.Console.Types directly
  rather than wrapping them - no need to duplicate a 150-key enum.
}

interface

uses
  System.Console.Types;  // TConsoleKey, TConsoleKeyInfo

type
  IConsoleInput = interface
    ['{5F3A2E71-9A6C-4F68-8A4B-2E3C1B5D7A40}']
    function ReadKey(intercept : Boolean) : TConsoleKeyInfo;
    function KeyAvailable : Boolean;
  end;

function CreateDefaultConsoleInput : IConsoleInput;

implementation

uses
  System.Console;

type
  TDefaultConsoleInput = class(TInterfacedObject, IConsoleInput)
  public
    function ReadKey(intercept : Boolean) : TConsoleKeyInfo;
    function KeyAvailable : Boolean;
  end;

function TDefaultConsoleInput.ReadKey(intercept : Boolean) : TConsoleKeyInfo;
begin
  result := Console.ReadKey(intercept);
end;

function TDefaultConsoleInput.KeyAvailable : Boolean;
begin
  result := Console.KeyAvailable;
end;

function CreateDefaultConsoleInput : IConsoleInput;
begin
  result := TDefaultConsoleInput.Create;
end;

end.
