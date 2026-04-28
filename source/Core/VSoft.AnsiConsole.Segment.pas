unit VSoft.AnsiConsole.Segment;

{
  TAnsiSegment - the atomic unit of rendering. A renderable produces an array
  of segments; the AnsiWriter then emits the appropriate escape sequences.

  A segment is conceptually: (text, style, flags).
    - TAnsiSegmentFlag.LineBreak : text is ignored; writer emits a newline.
    - TAnsiSegmentFlag.Whitespace: text is interword whitespace (may be trimmed at line edges).
    - TAnsiSegmentFlag.ControlCode: text is raw ANSI; writer emits it verbatim (no SGR wrap).

  Zero-initialised record is a valid empty text segment.
}

interface

uses
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Style;

type
  TAnsiSegment = record
  strict private
    FText  : string;
    FStyle : TAnsiStyle;
    FFlags : TAnsiSegmentFlags;
  public
    class function Text(const s : string) : TAnsiSegment; overload; static;
    class function Text(const s : string; const style : TAnsiStyle) : TAnsiSegment; overload; static;
    class function Whitespace(const s : string) : TAnsiSegment; overload; static;
    class function Whitespace(const s : string; const style : TAnsiStyle) : TAnsiSegment; overload; static;
    class function LineBreak : TAnsiSegment; static;
    class function ControlCode(const raw : string) : TAnsiSegment; static;

    function IsLineBreak : Boolean;
    function IsWhitespace : Boolean;
    function IsControlCode : Boolean;

    property Value  : string             read FText;   // segment text (property name "Text" clashes with factory)
    property Style  : TAnsiStyle         read FStyle;
    property Flags  : TAnsiSegmentFlags  read FFlags;
  end;

  TAnsiSegments = TArray<TAnsiSegment>;

implementation

{ TAnsiSegment }

class function TAnsiSegment.Text(const s : string) : TAnsiSegment;
begin
  result.FText  := s;
  result.FStyle := TAnsiStyle.Plain;
  result.FFlags := [];
end;

class function TAnsiSegment.Text(const s : string; const style : TAnsiStyle) : TAnsiSegment;
begin
  result.FText  := s;
  result.FStyle := style;
  result.FFlags := [];
end;

class function TAnsiSegment.Whitespace(const s : string) : TAnsiSegment;
begin
  result.FText  := s;
  result.FStyle := TAnsiStyle.Plain;
  result.FFlags := [TAnsiSegmentFlag.Whitespace];
end;

class function TAnsiSegment.Whitespace(const s : string; const style : TAnsiStyle) : TAnsiSegment;
begin
  result.FText  := s;
  result.FStyle := style;
  result.FFlags := [TAnsiSegmentFlag.Whitespace];
end;

class function TAnsiSegment.LineBreak : TAnsiSegment;
begin
  result.FText  := '';
  result.FStyle := TAnsiStyle.Plain;
  result.FFlags := [TAnsiSegmentFlag.LineBreak];
end;

class function TAnsiSegment.ControlCode(const raw : string) : TAnsiSegment;
begin
  result.FText  := raw;
  result.FStyle := TAnsiStyle.Plain;
  result.FFlags := [TAnsiSegmentFlag.ControlCode];
end;

function TAnsiSegment.IsLineBreak : Boolean;
begin
  result := TAnsiSegmentFlag.LineBreak in FFlags;
end;

function TAnsiSegment.IsWhitespace : Boolean;
begin
  result := TAnsiSegmentFlag.Whitespace in FFlags;
end;

function TAnsiSegment.IsControlCode : Boolean;
begin
  result := TAnsiSegmentFlag.ControlCode in FFlags;
end;

end.
