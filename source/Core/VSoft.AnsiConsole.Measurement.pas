unit VSoft.AnsiConsole.Measurement;

{
  TMeasurement - a pair (min, max) of cell widths describing how much
  horizontal space a renderable wants. Used by layout containers to decide
  how much width to grant to each child.
}

interface

type
  TMeasurement = record
  strict private
    FMin : Integer;
    FMax : Integer;
  public
    class function Create(min, max : Integer) : TMeasurement; static;
    class function Zero : TMeasurement; static;

    function WithMin(value : Integer) : TMeasurement;
    function WithMax(value : Integer) : TMeasurement;

    property Min : Integer read FMin;
    property Max : Integer read FMax;
  end;

implementation

{ TMeasurement }

class function TMeasurement.Create(min, max : Integer) : TMeasurement;
begin
  result.FMin := min;
  result.FMax := max;
end;

class function TMeasurement.Zero : TMeasurement;
begin
  result.FMin := 0;
  result.FMax := 0;
end;

function TMeasurement.WithMin(value : Integer) : TMeasurement;
begin
  result := Self;
  result.FMin := value;
end;

function TMeasurement.WithMax(value : Integer) : TMeasurement;
begin
  result := Self;
  result.FMax := value;
end;

end.
