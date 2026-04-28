unit VSoft.AnsiConsole.Prompts.Confirm;

{
  TConfirmationPrompt - a yes/no question with a boolean default.

  Display:  <prompt> [y/n] (Y):
                              ^-- uppercased letter = default
  Accepts the configured Yes / No char (case-insensitive), or Enter for
  the default. Any other character prints the InvalidChoiceMessage and
  reprompts. Both the choice hint and the default-value indicator can
  be hidden or styled via the With* fluent setters.
}

interface

uses
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Console;

type
  IConfirmationPrompt = interface
    ['{A8C6E2B1-7E3F-4F5B-9C1D-3B6D8E9F0A12}']
    function WithPrompt(const markup : string) : IConfirmationPrompt;
    function WithDefault(value : Boolean) : IConfirmationPrompt;
    { Configurable accept characters - default 'y' / 'n' (case insensitive). }
    function WithYes(value : Char) : IConfirmationPrompt;
    function WithNo(value : Char) : IConfirmationPrompt;
    { Markup printed when the user types something other than yes/no/enter. }
    function WithInvalidChoiceMessage(const markup : string) : IConfirmationPrompt;
    { Toggle the '[Y/n]' choice indicator and the '(Y)' default indicator. }
    function WithShowChoices(value : Boolean) : IConfirmationPrompt;
    function WithShowDefaultValue(value : Boolean) : IConfirmationPrompt;
    function WithChoicesStyle(const value : TAnsiStyle) : IConfirmationPrompt;
    function WithDefaultValueStyle(const value : TAnsiStyle) : IConfirmationPrompt;
    function Show(const console : IAnsiConsole) : Boolean;
  end;

  TConfirmationPrompt = class(TInterfacedObject, IConfirmationPrompt)
  strict private
    FPrompt              : string;
    FDefault             : Boolean;
    FYes                 : Char;
    FNo                  : Char;
    FInvalidChoiceMessage : string;
    FShowChoices         : Boolean;
    FShowDefaultValue    : Boolean;
    FChoicesStyle        : TAnsiStyle;
    FDefaultValueStyle   : TAnsiStyle;
  public
    constructor Create;
    function WithPrompt(const markup : string) : IConfirmationPrompt;
    function WithDefault(value : Boolean) : IConfirmationPrompt;
    function WithYes(value : Char) : IConfirmationPrompt;
    function WithNo(value : Char) : IConfirmationPrompt;
    function WithInvalidChoiceMessage(const markup : string) : IConfirmationPrompt;
    function WithShowChoices(value : Boolean) : IConfirmationPrompt;
    function WithShowDefaultValue(value : Boolean) : IConfirmationPrompt;
    function WithChoicesStyle(const value : TAnsiStyle) : IConfirmationPrompt;
    function WithDefaultValueStyle(const value : TAnsiStyle) : IConfirmationPrompt;
    function Show(const console : IAnsiConsole) : Boolean;
  end;

function ConfirmationPrompt : IConfirmationPrompt;

implementation

uses
  System.SysUtils,
  System.Console.Types,
  VSoft.AnsiConsole.Prompts.Text;  // for EmitPlain / EmitMarkup / EmitStyled

{ Char-case helpers - XE3 lacks the System.Character intrinsic record
  helpers (CharUpper / CharLower), so we wrap the string-form RTL
  functions and pick the first char. }
function CharUpper(ch : Char) : Char;
var
  s : string;
begin
  s := UpperCase(ch);
  if s = '' then result := ch else result := s[1];
end;

function CharLower(ch : Char) : Char;
var
  s : string;
begin
  s := LowerCase(ch);
  if s = '' then result := ch else result := s[1];
end;

function ConfirmationPrompt : IConfirmationPrompt;
begin
  result := TConfirmationPrompt.Create;
end;

{ TConfirmationPrompt }

constructor TConfirmationPrompt.Create;
begin
  inherited Create;
  FDefault := True;
  FYes := 'y';
  FNo  := 'n';
  FInvalidChoiceMessage := '[red]Please select one of the available options[/]';
  FShowChoices       := True;
  FShowDefaultValue  := True;
  FChoicesStyle      := TAnsiStyle.Plain;
  FDefaultValueStyle := TAnsiStyle.Plain;
end;

function TConfirmationPrompt.WithPrompt(const markup : string) : IConfirmationPrompt;
begin
  FPrompt := markup;
  result := Self;
end;

function TConfirmationPrompt.WithDefault(value : Boolean) : IConfirmationPrompt;
begin
  FDefault := value;
  result := Self;
end;

function TConfirmationPrompt.WithYes(value : Char) : IConfirmationPrompt;
begin
  FYes := value;
  result := Self;
end;

function TConfirmationPrompt.WithNo(value : Char) : IConfirmationPrompt;
begin
  FNo := value;
  result := Self;
end;

function TConfirmationPrompt.WithInvalidChoiceMessage(const markup : string) : IConfirmationPrompt;
begin
  FInvalidChoiceMessage := markup;
  result := Self;
end;

function TConfirmationPrompt.WithShowChoices(value : Boolean) : IConfirmationPrompt;
begin
  FShowChoices := value;
  result := Self;
end;

function TConfirmationPrompt.WithShowDefaultValue(value : Boolean) : IConfirmationPrompt;
begin
  FShowDefaultValue := value;
  result := Self;
end;

function TConfirmationPrompt.WithChoicesStyle(const value : TAnsiStyle) : IConfirmationPrompt;
begin
  FChoicesStyle := value;
  result := Self;
end;

function TConfirmationPrompt.WithDefaultValueStyle(const value : TAnsiStyle) : IConfirmationPrompt;
begin
  FDefaultValueStyle := value;
  result := Self;
end;

function TConfirmationPrompt.Show(const console : IAnsiConsole) : Boolean;
var
  key  : TConsoleKeyInfo;
  ch   : Char;
  yesU, noU, chU : Char;
  hint : string;
begin
  yesU := CharUpper(FYes);
  noU  := CharUpper(FNo);

  if FShowChoices then
  begin
    if FDefault then
      hint := ' [' + UpperCase(FYes) + '/' + LowerCase(FNo) + ']'
    else
      hint := ' [' + LowerCase(FYes) + '/' + UpperCase(FNo) + ']';
  end
  else
    hint := '';

  if FPrompt <> '' then
    EmitMarkup(console, FPrompt);
  if hint <> '' then
    EmitStyled(console, hint, FChoicesStyle);
  if FShowDefaultValue then
  begin
    if FDefault then
      EmitStyled(console, ' (' + UpperCase(FYes) + ')', FDefaultValueStyle)
    else
      EmitStyled(console, ' (' + UpperCase(FNo)  + ')', FDefaultValueStyle);
  end;
  EmitPlain(console, ' ');

  result := FDefault;
  while True do
  begin
    key := console.Input.ReadKey(True);
    case key.Key of
      TConsoleKey.Enter:
      begin
        EmitPlain(console, sLineBreak);
        Exit;
      end;
    else
      ch := key.KeyChar;
      chU := CharUpper(ch);
      if chU = yesU then
      begin
        EmitPlain(console, FYes + sLineBreak);
        result := True;
        Exit;
      end
      else if chU = noU then
      begin
        EmitPlain(console, FNo + sLineBreak);
        result := False;
        Exit;
      end
      else if (ch >= ' ') and (FInvalidChoiceMessage <> '') then
      begin
        // Echo the typed char + newline, then print error and reprompt.
        EmitPlain(console, ch + sLineBreak);
        EmitMarkup(console, FInvalidChoiceMessage);
        EmitPlain(console, sLineBreak);
        if FPrompt <> '' then
          EmitMarkup(console, FPrompt);
        if hint <> '' then
          EmitStyled(console, hint, FChoicesStyle);
        if FShowDefaultValue then
        begin
          if FDefault then
            EmitStyled(console, ' (' + UpperCase(FYes) + ')', FDefaultValueStyle)
          else
            EmitStyled(console, ' (' + UpperCase(FNo)  + ')', FDefaultValueStyle);
        end;
        EmitPlain(console, ' ');
      end;
    end;
  end;
end;

end.
