unit VSoft.AnsiConsole.Prompts.Text.Generic;

{
  TTextPrompt<T> - typed line-of-input prompt. Mirrors the string
  ITextPrompt's UI but parses the user's input into a T using either a
  user-supplied parser (WithParser) or one of the built-in defaults
  (string, Integer, Int64, Double, TDateTime, Boolean, enums) dispatched
  by RTTI.

  Usage:

    age := TextPrompt<Integer>.Create
             .WithPrompt('[bold]Age[/]?')
             .WithDefault(30)
             .WithValidator(
               function(const v : Integer) : TPromptValidationResult
               begin
                 if v < 0 then
                   result := TPromptValidationResult.Fail('Negative age?')
                 else
                   result := TPromptValidationResult.Ok;
               end)
             .Show(AnsiConsole.Console);

  Choices are compared after the parser succeeds, using the configured
  IEqualityComparer<T>.Default. So `AddChoice(1).AddChoice(2)` rejects
  any other integer the user types.

  Generic free functions are forbidden in Delphi XE3 (E2530), so the
  factory is a record with a class function (same pattern as
  SelectionPrompt<T>).
}

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Rtti,
  System.Generics.Defaults,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Rendering,
  VSoft.AnsiConsole.Console,
  VSoft.AnsiConsole.Prompts.Common;

type
  TTextPromptConverter<T>  = reference to function(const value : T) : string;
  TTextPromptParser<T>     = reference to function(const text : string; out value : T) : Boolean;
  TTextPromptValidatorT<T> = reference to function(const value : T) : TPromptValidationResult;

  ITextPrompt<T> = interface
    function WithPrompt(const markup : string) : ITextPrompt<T>;
    function WithDefault(const value : T) : ITextPrompt<T>;
    function WithParser(const parser : TTextPromptParser<T>) : ITextPrompt<T>;
    function WithConverter(const converter : TTextPromptConverter<T>) : ITextPrompt<T>;
    function WithValidator(const validator : TTextPromptValidatorT<T>) : ITextPrompt<T>;
    function AddChoice(const value : T) : ITextPrompt<T>;
    function WithShowChoices(value : Boolean) : ITextPrompt<T>;
    function WithShowDefaultValue(value : Boolean) : ITextPrompt<T>;
    function WithChoicesStyle(const value : TAnsiStyle) : ITextPrompt<T>;
    function WithDefaultValueStyle(const value : TAnsiStyle) : ITextPrompt<T>;
    function WithInvalidChoiceMessage(const markup : string) : ITextPrompt<T>;
    function WithSecret : ITextPrompt<T>; overload;
    function WithSecret(mask : Char) : ITextPrompt<T>; overload;
    function WithAllowEmpty(value : Boolean) : ITextPrompt<T>;
    function Show(const console : IAnsiConsole) : T;
  end;

  TTextPromptT<T> = class(TInterfacedObject, ITextPrompt<T>)
  strict private
    FPrompt              : string;
    FDefault             : T;
    FHasDefault          : Boolean;
    FSecret              : Boolean;
    FMask                : Char;
    FAllowEmpty          : Boolean;
    FParser              : TTextPromptParser<T>;
    FConverter           : TTextPromptConverter<T>;
    FValidator           : TTextPromptValidatorT<T>;
    FChoices             : TArray<T>;
    FShowChoices         : Boolean;
    FShowDefaultValue    : Boolean;
    FChoicesStyle        : TAnsiStyle;
    FDefaultValueStyle   : TAnsiStyle;
    FInvalidChoiceMessage: string;
    procedure DrawPromptLine(const console : IAnsiConsole);
    function  Convert(const value : T) : string;
    function  Parse(const text : string; out value : T) : Boolean;
    function  IsValidChoice(const value : T) : Boolean;
  public
    { Built-in RTTI-based parser. Returns False if the text doesn't
      parse to T (e.g. 'forty-two' for Integer). Exposed as a class
      method so callers can chain it from a custom WithParser
      (`if MyTrim(text, t) and TTextPromptT<Integer>.DefaultParse(t,v)`). }
    class function DefaultParse(const text : string; out value : T) : Boolean; static;
    { Built-in RTTI-based converter for the display side (default value
      rendering, choice list rendering). }
    class function DefaultConvert(const value : T) : string; static;
    constructor Create;
    function WithPrompt(const markup : string) : ITextPrompt<T>;
    function WithDefault(const value : T) : ITextPrompt<T>;
    function WithParser(const parser : TTextPromptParser<T>) : ITextPrompt<T>;
    function WithConverter(const converter : TTextPromptConverter<T>) : ITextPrompt<T>;
    function WithValidator(const validator : TTextPromptValidatorT<T>) : ITextPrompt<T>;
    function AddChoice(const value : T) : ITextPrompt<T>;
    function WithShowChoices(value : Boolean) : ITextPrompt<T>;
    function WithShowDefaultValue(value : Boolean) : ITextPrompt<T>;
    function WithChoicesStyle(const value : TAnsiStyle) : ITextPrompt<T>;
    function WithDefaultValueStyle(const value : TAnsiStyle) : ITextPrompt<T>;
    function WithInvalidChoiceMessage(const markup : string) : ITextPrompt<T>;
    function WithSecret : ITextPrompt<T>; overload;
    function WithSecret(mask : Char) : ITextPrompt<T>; overload;
    function WithAllowEmpty(value : Boolean) : ITextPrompt<T>;
    function Show(const console : IAnsiConsole) : T;
  end;

  { Factory record - generic free functions are forbidden in Delphi XE3,
    so the public surface is `TextPrompt<T>.Create...`. }
  TextPrompt<T> = record
    class function Create : ITextPrompt<T>; static; inline;
  end;

implementation

uses
  System.Console.Types,
  VSoft.AnsiConsole.Color,
  VSoft.AnsiConsole.Prompts.Text;  // EmitPlain / EmitMarkup / EmitStyled

class function TTextPromptT<T>.DefaultParse(const text : string; out value : T) : Boolean;
var
  ti   : PTypeInfo;
  iv   : Integer;
  i64v : Int64;
  fv   : Double;
  dt   : TDateTime;
  bv   : Boolean;
  ev   : Integer;
  v    : TValue;
begin
  ti := TypeInfo(T);
  result := False;

  // Default to a zero-initialised T so the out param is never garbage
  // when we return False.
  v := TValue.Empty;
  v := v.Cast(ti);
  value := v.AsType<T>;

  case ti^.Kind of
    tkUString, tkLString, tkWString, tkString:
    begin
      v := TValue.From<string>(text);
      value := v.AsType<T>;
      result := True;
    end;

    tkInteger:
    begin
      if TryStrToInt(text, iv) then
      begin
        v := TValue.From<Integer>(iv);
        value := v.AsType<T>;
        result := True;
      end;
    end;

    tkInt64:
    begin
      if TryStrToInt64(text, i64v) then
      begin
        v := TValue.From<Int64>(i64v);
        value := v.AsType<T>;
        result := True;
      end;
    end;

    tkFloat:
    begin
      // TDateTime is a tkFloat with a distinct PTypeInfo, so identity-
      // compare to dispatch into the date parser when appropriate.
      if ti = TypeInfo(TDateTime) then
      begin
        if TryStrToDateTime(text, dt) then
        begin
          v := TValue.From<TDateTime>(dt);
          value := v.AsType<T>;
          result := True;
        end;
      end
      else
      begin
        if TryStrToFloat(text, fv) then
        begin
          v := TValue.From<Double>(fv);
          value := v.AsType<T>;
          result := True;
        end;
      end;
    end;

    tkEnumeration:
    begin
      if ti = TypeInfo(Boolean) then
      begin
        if SameText(text, 'y') or SameText(text, 'yes') or SameText(text, 'true') or
           SameText(text, '1') then
          bv := True
        else if SameText(text, 'n') or SameText(text, 'no') or SameText(text, 'false') or
                SameText(text, '0') then
          bv := False
        else
          Exit;
        v := TValue.From<Boolean>(bv);
        value := v.AsType<T>;
        result := True;
      end
      else
      begin
        ev := GetEnumValue(ti, text);
        if ev >= 0 then
        begin
          v := TValue.FromOrdinal(ti, ev);
          value := v.AsType<T>;
          result := True;
        end;
      end;
    end;
  end;
end;

class function TTextPromptT<T>.DefaultConvert(const value : T) : string;
var
  ti : PTypeInfo;
  v  : TValue;
begin
  ti := TypeInfo(T);
  v := TValue.From<T>(value);

  case ti^.Kind of
    tkUString, tkLString, tkWString, tkString:
      result := v.AsString;
    tkInteger:
      result := IntToStr(v.AsInteger);
    tkInt64:
      result := IntToStr(v.AsInt64);
    tkFloat:
    begin
      if ti = TypeInfo(TDateTime) then
        result := DateTimeToStr(v.AsType<TDateTime>)
      else
        result := FloatToStr(v.AsExtended);
    end;
    tkEnumeration:
    begin
      if ti = TypeInfo(Boolean) then
      begin
        if v.AsBoolean then result := 'true' else result := 'false';
      end
      else
        result := GetEnumName(ti, v.AsOrdinal);
    end;
  else
    result := v.ToString;
  end;
end;

{ TextPrompt<T> factory record }

class function TextPrompt<T>.Create : ITextPrompt<T>;
begin
  result := TTextPromptT<T>.Create;
end;

{ TTextPromptT<T> }

constructor TTextPromptT<T>.Create;
begin
  inherited Create;
  FMask                 := '*';
  FAllowEmpty           := True;
  FShowChoices          := True;
  FShowDefaultValue     := True;
  FChoicesStyle         := TAnsiStyle.Plain.WithForeground(TAnsiColor.Aqua);
  FDefaultValueStyle    := TAnsiStyle.Plain.WithForeground(TAnsiColor.Green);
  FInvalidChoiceMessage := '[red]Please select one of the available options.[/]';
end;

function TTextPromptT<T>.WithPrompt(const markup : string) : ITextPrompt<T>;
begin FPrompt := markup; result := Self; end;

function TTextPromptT<T>.WithDefault(const value : T) : ITextPrompt<T>;
begin FDefault := value; FHasDefault := True; result := Self; end;

function TTextPromptT<T>.WithParser(const parser : TTextPromptParser<T>) : ITextPrompt<T>;
begin FParser := parser; result := Self; end;

function TTextPromptT<T>.WithConverter(const converter : TTextPromptConverter<T>) : ITextPrompt<T>;
begin FConverter := converter; result := Self; end;

function TTextPromptT<T>.WithValidator(const validator : TTextPromptValidatorT<T>) : ITextPrompt<T>;
begin FValidator := validator; result := Self; end;

function TTextPromptT<T>.AddChoice(const value : T) : ITextPrompt<T>;
var
  n : Integer;
begin
  n := Length(FChoices);
  SetLength(FChoices, n + 1);
  FChoices[n] := value;
  result := Self;
end;

function TTextPromptT<T>.WithShowChoices(value : Boolean) : ITextPrompt<T>;
begin FShowChoices := value; result := Self; end;

function TTextPromptT<T>.WithShowDefaultValue(value : Boolean) : ITextPrompt<T>;
begin FShowDefaultValue := value; result := Self; end;

function TTextPromptT<T>.WithChoicesStyle(const value : TAnsiStyle) : ITextPrompt<T>;
begin FChoicesStyle := value; result := Self; end;

function TTextPromptT<T>.WithDefaultValueStyle(const value : TAnsiStyle) : ITextPrompt<T>;
begin FDefaultValueStyle := value; result := Self; end;

function TTextPromptT<T>.WithInvalidChoiceMessage(const markup : string) : ITextPrompt<T>;
begin FInvalidChoiceMessage := markup; result := Self; end;

function TTextPromptT<T>.WithSecret : ITextPrompt<T>;
begin FSecret := True; result := Self; end;

function TTextPromptT<T>.WithSecret(mask : Char) : ITextPrompt<T>;
begin FSecret := True; FMask := mask; result := Self; end;

function TTextPromptT<T>.WithAllowEmpty(value : Boolean) : ITextPrompt<T>;
begin FAllowEmpty := value; result := Self; end;

function TTextPromptT<T>.Convert(const value : T) : string;
begin
  if Assigned(FConverter) then
    result := FConverter(value)
  else
    result := TTextPromptT<T>.DefaultConvert(value);
end;

function TTextPromptT<T>.Parse(const text : string; out value : T) : Boolean;
begin
  if Assigned(FParser) then
    result := FParser(text, value)
  else
    result := TTextPromptT<T>.DefaultParse(text, value);
end;

function TTextPromptT<T>.IsValidChoice(const value : T) : Boolean;
var
  cmp : IEqualityComparer<T>;
  i   : Integer;
begin
  if Length(FChoices) = 0 then
  begin
    result := True;
    Exit;
  end;
  cmp := TEqualityComparer<T>.Default;
  for i := 0 to High(FChoices) do
    if cmp.Equals(FChoices[i], value) then
    begin
      result := True;
      Exit;
    end;
  result := False;
end;

procedure TTextPromptT<T>.DrawPromptLine(const console : IAnsiConsole);
var
  i        : Integer;
  joined   : string;
begin
  if FPrompt <> '' then
    EmitMarkup(console, FPrompt);

  if FShowChoices and (Length(FChoices) > 0) then
  begin
    joined := '';
    for i := 0 to High(FChoices) do
    begin
      if i > 0 then joined := joined + '/';
      joined := joined + Convert(FChoices[i]);
    end;
    EmitPlain(console, ' [');
    EmitStyled(console, joined, FChoicesStyle);
    EmitPlain(console, ']');
  end;

  if FHasDefault and not FSecret and FShowDefaultValue then
  begin
    EmitPlain(console, ' (');
    EmitStyled(console, Convert(FDefault), FDefaultValueStyle);
    EmitPlain(console, ')');
  end;
  EmitPlain(console, ': ');
end;

function TTextPromptT<T>.Show(const console : IAnsiConsole) : T;
var
  buffer    : string;
  key       : TConsoleKeyInfo;
  ch        : Char;
  parsed    : T;
  vr        : TPromptValidationResult;
  committed : Boolean;
begin
  // Initial result value - ensures `result` is well-defined if the
  // caller re-uses Show() output before commit.
  result := Default(T);
  committed := False;

  while not committed do
  begin
    buffer := '';
    DrawPromptLine(console);

    while True do
    begin
      key := console.Input.ReadKey(True);
      case key.Key of
        TConsoleKey.Enter:
        begin
          EmitPlain(console, sLineBreak);

          // Empty + default => commit the default unconditionally.
          if (buffer = '') and FHasDefault then
          begin
            result := FDefault;
            committed := True;
            Break;
          end;

          if (buffer = '') and not FAllowEmpty then
          begin
            EmitMarkup(console, '[red]Value is required.[/]');
            EmitPlain(console, sLineBreak);
            Break;
          end;

          // Parse the input into a T.
          if not Parse(buffer, parsed) then
          begin
            EmitMarkup(console, '[red]Could not parse input.[/]');
            EmitPlain(console, sLineBreak);
            Break;
          end;

          // Choice membership check.
          if (Length(FChoices) > 0) and not IsValidChoice(parsed) then
          begin
            EmitMarkup(console, FInvalidChoiceMessage);
            EmitPlain(console, sLineBreak);
            Break;
          end;

          // Validator.
          if Assigned(FValidator) then
          begin
            vr := FValidator(parsed);
            if not vr.Valid then
            begin
              EmitMarkup(console, '[red]' + vr.Error + '[/]');
              EmitPlain(console, sLineBreak);
              Break;
            end;
          end;

          result := parsed;
          committed := True;
          Break;
        end;

        TConsoleKey.Escape:
        begin
          if FHasDefault then
          begin
            EmitPlain(console, sLineBreak);
            result := FDefault;
            committed := True;
            Break;
          end;
        end;

        TConsoleKey.Backspace:
        begin
          if Length(buffer) > 0 then
          begin
            SetLength(buffer, Length(buffer) - 1);
            EmitPlain(console, #8 + ' ' + #8);
          end;
        end;

      else
        ch := key.KeyChar;
        if (ch >= #32) and (ch <> #127) then
        begin
          buffer := buffer + ch;
          if FSecret then
            EmitPlain(console, FMask)
          else
            EmitPlain(console, ch);
        end;
      end;
    end;
  end;
end;

end.
