unit VSoft.AnsiConsole.Prompts.Common;

{
  Shared helpers for all prompts: cursor show/hide, line-level redraw,
  validation result record, and the EPromptCancelled exception raised when
  the user presses Escape on a selection or multi-selection prompt.

  All cursor and erase operations go out as control-code segments so they
  flow through the normal IAnsiConsole write path (which handles buffering
  and thread-safety consistently with the rest of the library).
}

interface

uses
  System.SysUtils,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Console;

type
  TPromptValidationResult = record
    Valid : Boolean;
    Error : string;
    class function Ok : TPromptValidationResult; static;
    class function Fail(const error : string) : TPromptValidationResult; static;
  end;

  EPromptCancelled = class(Exception);

  { Generic prompt contract - matches Spectre's IPrompt<T>. Each concrete
    prompt provides Show(console) returning T:
        ITextPrompt<T>          : IPrompt<T>
        ISelectionPrompt<T>     : IPrompt<T>
        IMultiSelectionPrompt<T>: IPrompt<TArray<T>>
        IConfirmationPrompt     : IPrompt<Boolean>
    The interfaces don't formally inherit from this in our port (Delphi
    generic-interface inheritance has GUID quirks); the contract is
    duck-typed: any prompt type with a Show(console) : T method is
    usable via the AnsiConsole.Prompt<T> facade method. }
  IPrompt<T> = interface
    function Show(const console : IAnsiConsole) : T;
  end;

procedure HideCursor(const console : IAnsiConsole);
procedure ShowCursor(const console : IAnsiConsole);

{ Move cursor up `count` lines AND clear each of them as we go - this returns
  the terminal to the position that was active just before we emitted those
  lines, ready for a fresh redraw at the same starting column. }
procedure ClearPreviousLines(const console : IAnsiConsole; count : Integer);

const
  ESC = #27;

implementation

{ TPromptValidationResult }

class function TPromptValidationResult.Ok : TPromptValidationResult;
begin
  result.Valid := True;
  result.Error := '';
end;

class function TPromptValidationResult.Fail(const error : string) : TPromptValidationResult;
begin
  result.Valid := False;
  result.Error := error;
end;

procedure EmitRaw(const console : IAnsiConsole; const s : string);
var
  segs : TAnsiSegments;
begin
  if s = '' then Exit;
  SetLength(segs, 1);
  segs[0] := TAnsiSegment.ControlCode(s);
  console.Write(segs);
end;

procedure HideCursor(const console : IAnsiConsole);
begin
  EmitRaw(console, ESC + '[?25l');
end;

procedure ShowCursor(const console : IAnsiConsole);
begin
  EmitRaw(console, ESC + '[?25h');
end;

procedure ClearPreviousLines(const console : IAnsiConsole; count : Integer);
var
  i : Integer;
  seq : string;
begin
  if count <= 0 then Exit;
  seq := '';
  // After rendering N lines, the cursor sits at the end of the last line
  // (no trailing linebreak emitted). To return to the start of the FIRST
  // rendered line we need count-1 up-moves, clearing each of the N lines
  // in the process.
  seq := seq + #13;              // CR - column 0
  seq := seq + ESC + '[2K';      // clear current (last-rendered) line
  for i := 1 to count - 1 do
  begin
    seq := seq + ESC + '[1A';    // up one line
    seq := seq + ESC + '[2K';    // clear it
  end;
  EmitRaw(console, seq);
end;

end.
