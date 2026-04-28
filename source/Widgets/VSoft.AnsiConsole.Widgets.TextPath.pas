unit VSoft.AnsiConsole.Widgets.TextPath;

{
  TTextPath - renders a file-system path with per-part styling:
    C:/Users/vincent/Documents/report.txt
    ^^ root      ^^ stems           ^^ leaf
       ^  /  separators

  Fits the path to maxWidth:
    - if it already fits, render verbatim
    - otherwise drop middle parts one at a time, inserting '...' (or '…' in
      unicode mode), preserving root + last part
    - if even that doesn't fit, trim the leaf to fit.
}

interface

uses
  System.SysUtils,
  VSoft.AnsiConsole.Types,
  VSoft.AnsiConsole.Style,
  VSoft.AnsiConsole.Segment,
  VSoft.AnsiConsole.Measurement,
  VSoft.AnsiConsole.Rendering;

type
  ITextPath = interface(IRenderable)
    ['{4A3F1C2D-8B5E-4C7F-B1D9-6A5E4C3D2B10}']
    function WithAlignment(value : TAlignment) : ITextPath;
    function WithRootStyle(const value : TAnsiStyle) : ITextPath;
    function WithSeparatorStyle(const value : TAnsiStyle) : ITextPath;
    function WithStemStyle(const value : TAnsiStyle) : ITextPath;
    function WithLeafStyle(const value : TAnsiStyle) : ITextPath;
  end;

  TTextPath = class(TInterfacedObject, IRenderable, ITextPath)
  strict private
    FParts           : TArray<string>;
    FRooted          : Boolean;
    FWindows         : Boolean;
    FAlignment       : TAlignment;
    FRootStyle       : TAnsiStyle;
    FSeparatorStyle  : TAnsiStyle;
    FStemStyle       : TAnsiStyle;
    FLeafStyle       : TAnsiStyle;
    procedure ParsePath(const path : string);
    function Fit(const options : TRenderOptions; maxWidth : Integer) : TArray<string>;
  public
    constructor Create(const path : string);

    function Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
    function Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;

    function WithAlignment(value : TAlignment) : ITextPath;
    function WithRootStyle(const value : TAnsiStyle) : ITextPath;
    function WithSeparatorStyle(const value : TAnsiStyle) : ITextPath;
    function WithStemStyle(const value : TAnsiStyle) : ITextPath;
    function WithLeafStyle(const value : TAnsiStyle) : ITextPath;
  end;

function TextPath(const path : string) : ITextPath;

implementation

uses
  VSoft.AnsiConsole.Internal.Cell;

function TextPath(const path : string) : ITextPath;
begin
  result := TTextPath.Create(path);
end;

function SplitAndKeep(const s : string; sep : Char) : TArray<string>;
var
  i, start : Integer;
  count    : Integer;
begin
  SetLength(result, 0);
  count := 0;
  start := 1;
  for i := 1 to Length(s) do
  begin
    if s[i] = sep then
    begin
      if i > start then
      begin
        SetLength(result, count + 1);
        result[count] := Copy(s, start, i - start);
        Inc(count);
      end;
      start := i + 1;
    end;
  end;
  if Length(s) >= start then
  begin
    SetLength(result, count + 1);
    result[count] := Copy(s, start, Length(s) - start + 1);
    Inc(count);
  end;
  SetLength(result, count);
end;

{ TTextPath }

constructor TTextPath.Create(const path : string);
begin
  inherited Create;
  FAlignment := TAlignment.Left;
  FRootStyle := TAnsiStyle.Plain;
  FSeparatorStyle := TAnsiStyle.Plain;
  FStemStyle := TAnsiStyle.Plain;
  FLeafStyle := TAnsiStyle.Plain;
  ParsePath(path);
end;

procedure TTextPath.ParsePath(const path : string);
var
  s : string;
  i : Integer;
  parts : TArray<string>;
  prepended : TArray<string>;
  partsLen  : Integer;
begin
  s := path;
  // Normalise backslashes
  for i := 1 to Length(s) do
    if s[i] = '\' then s[i] := '/';
  // Trim trailing separators + surrounding whitespace
  s := Trim(s);
  while (Length(s) > 0) and (s[Length(s)] = '/') do
    Delete(s, Length(s), 1);

  parts := SplitAndKeep(s, '/');
  partsLen := Length(parts);

  if (Length(s) > 0) and (s[1] = '/') then
  begin
    FRooted := True;
    SetLength(prepended, partsLen + 1);
    prepended[0] := '/';
    for i := 0 to partsLen - 1 do
      prepended[i + 1] := parts[i];
    FParts := prepended;
  end
  else if (partsLen > 0) and (Length(parts[0]) > 0)
          and (parts[0][Length(parts[0])] = ':') then
  begin
    FRooted := True;
    FWindows := True;
    FParts := parts;
  end
  else
    FParts := parts;
end;

function TTextPath.WithAlignment(value : TAlignment) : ITextPath;
begin
  FAlignment := value;
  result := Self;
end;

function TTextPath.WithRootStyle(const value : TAnsiStyle) : ITextPath;
begin
  FRootStyle := value;
  result := Self;
end;

function TTextPath.WithSeparatorStyle(const value : TAnsiStyle) : ITextPath;
begin
  FSeparatorStyle := value;
  result := Self;
end;

function TTextPath.WithStemStyle(const value : TAnsiStyle) : ITextPath;
begin
  FStemStyle := value;
  result := Self;
end;

function TTextPath.WithLeafStyle(const value : TAnsiStyle) : ITextPath;
begin
  FLeafStyle := value;
  result := Self;
end;

function SumCellLengths(const parts : TArray<string>) : Integer;
var
  i : Integer;
begin
  result := 0;
  for i := 0 to High(parts) do
    Inc(result, CellLength(parts[i]));
end;

function TTextPath.Fit(const options : TRenderOptions; maxWidth : Integer) : TArray<string>;
var
  ellipsis      : string;
  ellipsisLen   : Integer;
  partsLen      : Integer;
  total         : Integer;
  skip          : Integer;
  separatorCount: Integer;
  rootLen       : Integer;
  queueStart    : Integer;
  queueLen      : Integer;
  queueWidth    : Integer;
  lastLen       : Integer;
  i             : Integer;
  built         : TArray<string>;
  lastStr       : string;
  take          : Integer;
  startIdx      : Integer;
  countBuilt    : Integer;
begin
  partsLen := Length(FParts);
  if partsLen = 0 then
  begin
    result := FParts;
    Exit;
  end;

  total := SumCellLengths(FParts) + (partsLen - 1);
  if total <= maxWidth then
  begin
    result := FParts;
    Exit;
  end;

  if options.Unicode then ellipsis := #$2026 else ellipsis := '...';
  ellipsisLen := CellLength(ellipsis);

  if partsLen >= 2 then
  begin
    if FRooted then
    begin
      skip := 1;
      separatorCount := 2;
      rootLen := CellLength(FParts[0]);
    end
    else
    begin
      skip := 0;
      separatorCount := 1;
      rootLen := 0;
    end;

    lastLen := CellLength(FParts[partsLen - 1]);

    queueStart := skip;
    queueLen   := partsLen - separatorCount;
    if queueLen < 0 then queueLen := 0;

    while queueLen > 0 do
    begin
      // Dequeue one from the front of the "middle" queue
      Inc(queueStart);
      Dec(queueLen);

      queueWidth := rootLen + ellipsisLen + lastLen + queueLen + separatorCount;
      for i := 0 to queueLen - 1 do
        Inc(queueWidth, CellLength(FParts[queueStart + i]));

      if maxWidth >= queueWidth then
      begin
        countBuilt := 0;
        SetLength(built, 0);
        if FRooted then
        begin
          SetLength(built, countBuilt + 1);
          built[countBuilt] := FParts[0];
          Inc(countBuilt);
        end;
        SetLength(built, countBuilt + 1);
        built[countBuilt] := ellipsis;
        Inc(countBuilt);
        for i := 0 to queueLen - 1 do
        begin
          SetLength(built, countBuilt + 1);
          built[countBuilt] := FParts[queueStart + i];
          Inc(countBuilt);
        end;
        SetLength(built, countBuilt + 1);
        built[countBuilt] := FParts[partsLen - 1];
        result := built;
        Exit;
      end;
    end;

  end;

  // Trim just the last part so it fits
  lastStr := FParts[partsLen - 1];
  take := maxWidth - ellipsisLen;
  if take < 0 then take := 0;
  if take > Length(lastStr) then take := Length(lastStr);
  startIdx := Length(lastStr) - take + 1;
  if startIdx < 1 then startIdx := 1;
  SetLength(result, 1);
  result[0] := ellipsis + Copy(lastStr, startIdx, take);
end;

function TTextPath.Measure(const options : TRenderOptions; maxWidth : Integer) : TMeasurement;
var
  fitted : TArray<string>;
  len    : Integer;
begin
  fitted := Fit(options, maxWidth);
  if Length(fitted) = 0 then
  begin
    result := TMeasurement.Create(0, 0);
    Exit;
  end;
  len := SumCellLengths(fitted) + (Length(fitted) - 1);
  if len > maxWidth then len := maxWidth;
  result := TMeasurement.Create(len, len);
end;

function TTextPath.Render(const options : TRenderOptions; maxWidth : Integer) : TAnsiSegments;
var
  fitted     : TArray<string>;
  i          : Integer;
  count      : Integer;
  len        : Integer;
  pad        : Integer;
  leftPad    : Integer;
  rightPad   : Integer;
  totalCells : Integer;

  procedure Push(const seg : TAnsiSegment);
  begin
    SetLength(result, count + 1);
    result[count] := seg;
    Inc(count);
  end;

begin
  SetLength(result, 0);
  count := 0;
  fitted := Fit(options, maxWidth);
  if Length(fitted) = 0 then Exit;

  // Pre-compute totalCells for alignment padding
  totalCells := SumCellLengths(fitted) + (Length(fitted) - 1);
  if totalCells > maxWidth then totalCells := maxWidth;

  pad := maxWidth - totalCells;
  leftPad := 0;
  rightPad := 0;
  if pad > 0 then
  begin
    case FAlignment of
      TAlignment.Center:
      begin
        leftPad := pad div 2;
        rightPad := pad - leftPad;
      end;
      TAlignment.Right:
      begin
        leftPad := pad;
      end;
    else
      rightPad := pad;
    end;
  end;

  if leftPad > 0 then
    Push(TAnsiSegment.Whitespace(StringOfChar(' ', leftPad)));

  len := Length(fitted);
  for i := 0 to len - 1 do
  begin
    if i = len - 1 then
    begin
      // Leaf
      Push(TAnsiSegment.Text(fitted[i], FLeafStyle));
    end
    else
    begin
      if (i = 0) and FRooted then
      begin
        Push(TAnsiSegment.Text(fitted[i], FRootStyle));
        if FWindows then
          Push(TAnsiSegment.Text('/', FSeparatorStyle));
      end
      else
      begin
        Push(TAnsiSegment.Text(fitted[i], FStemStyle));
        Push(TAnsiSegment.Text('/', FSeparatorStyle));
      end;
    end;
  end;

  if rightPad > 0 then
    Push(TAnsiSegment.Whitespace(StringOfChar(' ', rightPad)));

  // Alignment note: for TAlignment.Left we emit no left pad; fitted path ends flush,
  // trailing pad (if any) is appended so caller sees exactly maxWidth cells
  // of content. This matches BarChart/Calendar etc. behaviour.
end;

end.
