unit VSoft.AnsiConsole.Internal.Cell;

{
  Console cell-width computation.

  A "cell" is one terminal column. Most characters take 1 cell; wide
  characters (CJK, full-width, emoji) take 2; control characters and zero-
  width combining marks take 0.

  Data tables live in VSoft.AnsiConsole.Internal.Cell.Tables and are a
  direct port of spectreconsole/wcwidth at Unicode 15.1. This is NOT a full
  grapheme-cluster implementation (UAX #29): ZWJ-joined emoji sequences,
  flag pairs, and skin-tone modifiers still measure as the sum of their
  code-point widths. It is, however, the accepted industry baseline and
  matches what modern terminals report for isolated code points.
}

interface

function CellLengthChar(c : Char) : Integer;
function CellLength(const s : string) : Integer;

implementation

uses
  VSoft.AnsiConsole.Internal.Cell.Tables;

function InRange(cp : Cardinal; const ranges : array of TRange) : Boolean;
var
  lo, hi, mid : Integer;
begin
  lo := 0;
  hi := High(ranges);
  while lo <= hi do
  begin
    mid := (lo + hi) shr 1;
    if cp < ranges[mid].Lo then
      hi := mid - 1
    else if cp > ranges[mid].Hi then
      lo := mid + 1
    else
    begin
      result := True;
      Exit;
    end;
  end;
  result := False;
end;

function IsWideCodePoint(cp : Cardinal) : Boolean;
begin
  result := InRange(cp, WIDE_RANGES);
end;

function IsZeroCodePoint(cp : Cardinal) : Boolean;
begin
  result := InRange(cp, ZERO_RANGES);
end;

function CellLengthChar(c : Char) : Integer;
var
  cp : Cardinal;
begin
  cp := Ord(c);
  // ASCII printable fast path - skips both binary searches.
  if (cp >= $20) and (cp <= $7E) then
  begin
    result := 1;
    Exit;
  end;
  if cp < $20 then
  begin
    result := 0;
    Exit;
  end;
  if cp = $7F then
  begin
    result := 0;
    Exit;
  end;
  if IsZeroCodePoint(cp) then
  begin
    result := 0;
    Exit;
  end;
  if IsWideCodePoint(cp) then
    result := 2
  else
    result := 1;
end;

function CellLength(const s : string) : Integer;
var
  i  : Integer;
  cp : Cardinal;
begin
  result := 0;
  i := 1;
  while i <= Length(s) do
  begin
    cp := Ord(s[i]);
    // Surrogate pair - combine to astral plane code point and consult the
    // full Wide/Zero tables. Consumes both code units.
    if (cp >= $D800) and (cp <= $DBFF) and (i < Length(s)) then
    begin
      cp := Cardinal((Integer(cp) - $D800) shl 10)
          + Cardinal(Integer(Ord(s[i + 1])) - $DC00) + $10000;
      if IsWideCodePoint(cp) then
        Inc(result, 2)
      else if not IsZeroCodePoint(cp) then
        Inc(result, 1);
      // zero-width astral code points (rare) add nothing
      Inc(i, 2);
      Continue;
    end;
    Inc(result, CellLengthChar(s[i]));
    Inc(i);
  end;
end;

end.
