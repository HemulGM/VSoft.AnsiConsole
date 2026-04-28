unit VSoft.AnsiConsole.Color;

{
  TAnsiColor - value-type color record.

  A zero-initialised TAnsiColor (e.g. `var c: TAnsiColor;`) represents the
  "default / use terminal default" color. Use the factory class functions
  (FromRGB, FromHex, FromIndex, or the named colors like Red, Green, ...)
  to create a concrete color.

  Internal state:
    FHasValue  : False => default color, True => explicit color
    FR, FG, FB : 24-bit RGB (always populated for explicit colors)
    FNumber    : palette index 0..255, or -1 if the color has no palette entry
}

interface

uses
  VSoft.AnsiConsole.Types;

type
  TAnsiColor = record
  strict private
    FHasValue : Boolean;
    FR        : Byte;
    FG        : Byte;
    FB        : Byte;
    FNumber   : SmallInt;  // -1 = no palette entry
    class function Make(r, g, b : Byte; number : SmallInt) : TAnsiColor; static;
  public
    { Factories }
    class function Default : TAnsiColor; static;
    class function FromRGB(r, g, b : Byte) : TAnsiColor; static;
    class function FromHex(const hex : string) : TAnsiColor; static;
    class function TryFromHex(const hex : string; out color : TAnsiColor) : Boolean; static;
    class function FromIndex(index : Byte) : TAnsiColor; static;
    { Look up a palette color by name (case-insensitive). FromName raises
      EConvertError on unknown names; TryFromName returns False instead.
      Aliases like gray/grey, magenta/fuchsia, cyan/aqua all resolve. }
    class function FromName(const name : string) : TAnsiColor; static;
    class function TryFromName(const name : string; out color : TAnsiColor) : Boolean; static;
    { Conversion to/from a Windows ConsoleColor value (0..15). The mapping
      reorders RGB bits to match the legacy WinAPI palette - blue and red
      are swapped relative to the standard ANSI 16. Values outside 0..15
      raise on FromConsoleColor; ToConsoleColor returns -1 when the color
      has no palette entry in the standard 16. }
    class function FromConsoleColor(value : Integer) : TAnsiColor; static;
    function ToConsoleColor : Integer;

    { Named colors. The standard 16 (indices 0-15) are listed first;
      everything below is mechanically ported from Spectre.Console's
      Color.Generated.g.cs (xterm-256 palette). Each entry returns the
      matching TAnsiColor via FromIndex. The last batch is an
      auto-generated import from the source file specified in the
      implementation section header - re-port from there for newer
      Spectre versions. }
    class function Black       : TAnsiColor; static;  // 0
    class function Maroon      : TAnsiColor; static;  // 1
    class function Green       : TAnsiColor; static;  // 2
    class function Olive       : TAnsiColor; static;  // 3
    class function Navy        : TAnsiColor; static;  // 4
    class function Purple      : TAnsiColor; static;  // 5
    class function Teal        : TAnsiColor; static;  // 6
    class function Silver      : TAnsiColor; static;  // 7
    class function Grey        : TAnsiColor; static;  // 8
    class function Red         : TAnsiColor; static;  // 9
    class function Lime        : TAnsiColor; static;  // 10
    class function Yellow      : TAnsiColor; static;  // 11
    class function Blue        : TAnsiColor; static;  // 12
    class function Fuchsia     : TAnsiColor; static;  // 13
    class function Aqua        : TAnsiColor; static;  // 14
    class function White       : TAnsiColor; static;  // 15

    { Extended xterm-256 named palette (indices 16-255). One-shot port
      from Spectre.Console's Color.Generated.g.cs - see the matching
      block in the implementation for source / import date. }
    class function Grey0 : TAnsiColor; static;
    class function Gray0 : TAnsiColor; static;
    class function NavyBlue : TAnsiColor; static;
    class function DarkBlue : TAnsiColor; static;
    class function Blue3 : TAnsiColor; static;
    class function Blue3_1 : TAnsiColor; static;
    class function Blue1 : TAnsiColor; static;
    class function DarkGreen : TAnsiColor; static;
    class function DeepSkyBlue4 : TAnsiColor; static;
    class function DeepSkyBlue4_1 : TAnsiColor; static;
    class function DeepSkyBlue4_2 : TAnsiColor; static;
    class function DodgerBlue3 : TAnsiColor; static;
    class function DodgerBlue2 : TAnsiColor; static;
    class function Green4 : TAnsiColor; static;
    class function SpringGreen4 : TAnsiColor; static;
    class function Turquoise4 : TAnsiColor; static;
    class function DeepSkyBlue3 : TAnsiColor; static;
    class function DeepSkyBlue3_1 : TAnsiColor; static;
    class function DodgerBlue1 : TAnsiColor; static;
    class function Green3 : TAnsiColor; static;
    class function SpringGreen3 : TAnsiColor; static;
    class function DarkCyan : TAnsiColor; static;
    class function LightSeaGreen : TAnsiColor; static;
    class function DeepSkyBlue2 : TAnsiColor; static;
    class function DeepSkyBlue1 : TAnsiColor; static;
    class function Green3_1 : TAnsiColor; static;
    class function SpringGreen3_1 : TAnsiColor; static;
    class function SpringGreen2 : TAnsiColor; static;
    class function Cyan3 : TAnsiColor; static;
    class function DarkTurquoise : TAnsiColor; static;
    class function Turquoise2 : TAnsiColor; static;
    class function Green1 : TAnsiColor; static;
    class function SpringGreen2_1 : TAnsiColor; static;
    class function SpringGreen1 : TAnsiColor; static;
    class function MediumSpringGreen : TAnsiColor; static;
    class function Cyan2 : TAnsiColor; static;
    class function Cyan1 : TAnsiColor; static;
    class function DarkRed : TAnsiColor; static;
    class function DeepPink4 : TAnsiColor; static;
    class function Purple4 : TAnsiColor; static;
    class function Purple4_1 : TAnsiColor; static;
    class function Purple3 : TAnsiColor; static;
    class function BlueViolet : TAnsiColor; static;
    class function Orange4 : TAnsiColor; static;
    class function Grey37 : TAnsiColor; static;
    class function Gray37 : TAnsiColor; static;
    class function MediumPurple4 : TAnsiColor; static;
    class function SlateBlue3 : TAnsiColor; static;
    class function SlateBlue3_1 : TAnsiColor; static;
    class function RoyalBlue1 : TAnsiColor; static;
    class function Chartreuse4 : TAnsiColor; static;
    class function DarkSeaGreen4 : TAnsiColor; static;
    class function PaleTurquoise4 : TAnsiColor; static;
    class function SteelBlue : TAnsiColor; static;
    class function SteelBlue3 : TAnsiColor; static;
    class function CornflowerBlue : TAnsiColor; static;
    class function Chartreuse3 : TAnsiColor; static;
    class function DarkSeaGreen4_1 : TAnsiColor; static;
    class function CadetBlue : TAnsiColor; static;
    class function CadetBlue_1 : TAnsiColor; static;
    class function SkyBlue3 : TAnsiColor; static;
    class function SteelBlue1 : TAnsiColor; static;
    class function Chartreuse3_1 : TAnsiColor; static;
    class function PaleGreen3 : TAnsiColor; static;
    class function SeaGreen3 : TAnsiColor; static;
    class function Aquamarine3 : TAnsiColor; static;
    class function MediumTurquoise : TAnsiColor; static;
    class function SteelBlue1_1 : TAnsiColor; static;
    class function Chartreuse2 : TAnsiColor; static;
    class function SeaGreen2 : TAnsiColor; static;
    class function SeaGreen1 : TAnsiColor; static;
    class function SeaGreen1_1 : TAnsiColor; static;
    class function Aquamarine1 : TAnsiColor; static;
    class function DarkSlateGray2 : TAnsiColor; static;
    class function DarkRed_1 : TAnsiColor; static;
    class function DeepPink4_1 : TAnsiColor; static;
    class function DarkMagenta : TAnsiColor; static;
    class function DarkMagenta_1 : TAnsiColor; static;
    class function DarkViolet : TAnsiColor; static;
    class function Purple_1 : TAnsiColor; static;
    class function Orange4_1 : TAnsiColor; static;
    class function LightPink4 : TAnsiColor; static;
    class function Plum4 : TAnsiColor; static;
    class function MediumPurple3 : TAnsiColor; static;
    class function MediumPurple3_1 : TAnsiColor; static;
    class function SlateBlue1 : TAnsiColor; static;
    class function Yellow4 : TAnsiColor; static;
    class function Wheat4 : TAnsiColor; static;
    class function Grey53 : TAnsiColor; static;
    class function Gray53 : TAnsiColor; static;
    class function LightSlateGrey : TAnsiColor; static;
    class function MediumPurple : TAnsiColor; static;
    class function LightSlateBlue : TAnsiColor; static;
    class function Yellow4_1 : TAnsiColor; static;
    class function DarkOliveGreen3 : TAnsiColor; static;
    class function DarkSeaGreen : TAnsiColor; static;
    class function LightSkyBlue3 : TAnsiColor; static;
    class function LightSkyBlue3_1 : TAnsiColor; static;
    class function SkyBlue2 : TAnsiColor; static;
    class function Chartreuse2_1 : TAnsiColor; static;
    class function DarkOliveGreen3_1 : TAnsiColor; static;
    class function PaleGreen3_1 : TAnsiColor; static;
    class function DarkSeaGreen3 : TAnsiColor; static;
    class function DarkSlateGray3 : TAnsiColor; static;
    class function SkyBlue1 : TAnsiColor; static;
    class function Chartreuse1 : TAnsiColor; static;
    class function LightGreen : TAnsiColor; static;
    class function LightGreen_1 : TAnsiColor; static;
    class function PaleGreen1 : TAnsiColor; static;
    class function Aquamarine1_1 : TAnsiColor; static;
    class function DarkSlateGray1 : TAnsiColor; static;
    class function Red3 : TAnsiColor; static;
    class function DeepPink4_2 : TAnsiColor; static;
    class function MediumVioletRed : TAnsiColor; static;
    class function Magenta3 : TAnsiColor; static;
    class function DarkViolet_1 : TAnsiColor; static;
    class function Purple_2 : TAnsiColor; static;
    class function DarkOrange3 : TAnsiColor; static;
    class function IndianRed : TAnsiColor; static;
    class function HotPink3 : TAnsiColor; static;
    class function MediumOrchid3 : TAnsiColor; static;
    class function MediumOrchid : TAnsiColor; static;
    class function MediumPurple2 : TAnsiColor; static;
    class function DarkGoldenrod : TAnsiColor; static;
    class function LightSalmon3 : TAnsiColor; static;
    class function RosyBrown : TAnsiColor; static;
    class function Grey63 : TAnsiColor; static;
    class function Gray63 : TAnsiColor; static;
    class function MediumPurple2_1 : TAnsiColor; static;
    class function MediumPurple1 : TAnsiColor; static;
    class function Gold3 : TAnsiColor; static;
    class function DarkKhaki : TAnsiColor; static;
    class function NavajoWhite3 : TAnsiColor; static;
    class function Grey69 : TAnsiColor; static;
    class function Gray69 : TAnsiColor; static;
    class function LightSteelBlue3 : TAnsiColor; static;
    class function LightSteelBlue : TAnsiColor; static;
    class function Yellow3 : TAnsiColor; static;
    class function DarkOliveGreen3_2 : TAnsiColor; static;
    class function DarkSeaGreen3_1 : TAnsiColor; static;
    class function DarkSeaGreen2 : TAnsiColor; static;
    class function LightCyan3 : TAnsiColor; static;
    class function LightSkyBlue1 : TAnsiColor; static;
    class function GreenYellow : TAnsiColor; static;
    class function DarkOliveGreen2 : TAnsiColor; static;
    class function PaleGreen1_1 : TAnsiColor; static;
    class function DarkSeaGreen2_1 : TAnsiColor; static;
    class function DarkSeaGreen1 : TAnsiColor; static;
    class function PaleTurquoise1 : TAnsiColor; static;
    class function Red3_1 : TAnsiColor; static;
    class function DeepPink3 : TAnsiColor; static;
    class function DeepPink3_1 : TAnsiColor; static;
    class function Magenta3_1 : TAnsiColor; static;
    class function Magenta3_2 : TAnsiColor; static;
    class function Magenta2 : TAnsiColor; static;
    class function DarkOrange3_1 : TAnsiColor; static;
    class function IndianRed_1 : TAnsiColor; static;
    class function HotPink3_1 : TAnsiColor; static;
    class function HotPink2 : TAnsiColor; static;
    class function Orchid : TAnsiColor; static;
    class function MediumOrchid1 : TAnsiColor; static;
    class function Orange3 : TAnsiColor; static;
    class function LightSalmon3_1 : TAnsiColor; static;
    class function LightPink3 : TAnsiColor; static;
    class function Pink3 : TAnsiColor; static;
    class function Plum3 : TAnsiColor; static;
    class function Violet : TAnsiColor; static;
    class function Gold3_1 : TAnsiColor; static;
    class function LightGoldenrod3 : TAnsiColor; static;
    class function Tan : TAnsiColor; static;
    class function MistyRose3 : TAnsiColor; static;
    class function Thistle3 : TAnsiColor; static;
    class function Plum2 : TAnsiColor; static;
    class function Yellow3_1 : TAnsiColor; static;
    class function Khaki3 : TAnsiColor; static;
    class function LightGoldenrod2 : TAnsiColor; static;
    class function LightYellow3 : TAnsiColor; static;
    class function Grey84 : TAnsiColor; static;
    class function Gray84 : TAnsiColor; static;
    class function LightSteelBlue1 : TAnsiColor; static;
    class function Yellow2 : TAnsiColor; static;
    class function DarkOliveGreen1 : TAnsiColor; static;
    class function DarkOliveGreen1_1 : TAnsiColor; static;
    class function DarkSeaGreen1_1 : TAnsiColor; static;
    class function Honeydew2 : TAnsiColor; static;
    class function LightCyan1 : TAnsiColor; static;
    class function Red1 : TAnsiColor; static;
    class function DeepPink2 : TAnsiColor; static;
    class function DeepPink1 : TAnsiColor; static;
    class function DeepPink1_1 : TAnsiColor; static;
    class function Magenta2_1 : TAnsiColor; static;
    class function Magenta1 : TAnsiColor; static;
    class function OrangeRed1 : TAnsiColor; static;
    class function IndianRed1 : TAnsiColor; static;
    class function IndianRed1_1 : TAnsiColor; static;
    class function HotPink : TAnsiColor; static;
    class function HotPink_1 : TAnsiColor; static;
    class function MediumOrchid1_1 : TAnsiColor; static;
    class function DarkOrange : TAnsiColor; static;
    class function Salmon1 : TAnsiColor; static;
    class function LightCoral : TAnsiColor; static;
    class function PaleVioletRed1 : TAnsiColor; static;
    class function Orchid2 : TAnsiColor; static;
    class function Orchid1 : TAnsiColor; static;
    class function Orange1 : TAnsiColor; static;
    class function SandyBrown : TAnsiColor; static;
    class function LightSalmon1 : TAnsiColor; static;
    class function LightPink1 : TAnsiColor; static;
    class function Pink1 : TAnsiColor; static;
    class function Plum1 : TAnsiColor; static;
    class function Gold1 : TAnsiColor; static;
    class function LightGoldenrod2_1 : TAnsiColor; static;
    class function LightGoldenrod2_2 : TAnsiColor; static;
    class function NavajoWhite1 : TAnsiColor; static;
    class function MistyRose1 : TAnsiColor; static;
    class function Thistle1 : TAnsiColor; static;
    class function Yellow1 : TAnsiColor; static;
    class function LightGoldenrod1 : TAnsiColor; static;
    class function Khaki1 : TAnsiColor; static;
    class function Wheat1 : TAnsiColor; static;
    class function Cornsilk1 : TAnsiColor; static;
    class function Grey100 : TAnsiColor; static;
    class function Gray100 : TAnsiColor; static;
    class function Grey3 : TAnsiColor; static;
    class function Gray3 : TAnsiColor; static;
    class function Grey7 : TAnsiColor; static;
    class function Gray7 : TAnsiColor; static;
    class function Grey11 : TAnsiColor; static;
    class function Gray11 : TAnsiColor; static;
    class function Grey15 : TAnsiColor; static;
    class function Gray15 : TAnsiColor; static;
    class function Grey19 : TAnsiColor; static;
    class function Gray19 : TAnsiColor; static;
    class function Grey23 : TAnsiColor; static;
    class function Gray23 : TAnsiColor; static;
    class function Grey27 : TAnsiColor; static;
    class function Gray27 : TAnsiColor; static;
    class function Grey30 : TAnsiColor; static;
    class function Gray30 : TAnsiColor; static;
    class function Grey35 : TAnsiColor; static;
    class function Gray35 : TAnsiColor; static;
    class function Grey39 : TAnsiColor; static;
    class function Gray39 : TAnsiColor; static;
    class function Grey42 : TAnsiColor; static;
    class function Gray42 : TAnsiColor; static;
    class function Grey46 : TAnsiColor; static;
    class function Gray46 : TAnsiColor; static;
    class function Grey50 : TAnsiColor; static;
    class function Gray50 : TAnsiColor; static;
    class function Grey54 : TAnsiColor; static;
    class function Gray54 : TAnsiColor; static;
    class function Grey58 : TAnsiColor; static;
    class function Gray58 : TAnsiColor; static;
    class function Grey62 : TAnsiColor; static;
    class function Gray62 : TAnsiColor; static;
    class function Grey66 : TAnsiColor; static;
    class function Gray66 : TAnsiColor; static;
    class function Grey70 : TAnsiColor; static;
    class function Gray70 : TAnsiColor; static;
    class function Grey74 : TAnsiColor; static;
    class function Gray74 : TAnsiColor; static;
    class function Grey78 : TAnsiColor; static;
    class function Gray78 : TAnsiColor; static;
    class function Grey82 : TAnsiColor; static;
    class function Gray82 : TAnsiColor; static;
    class function Grey85 : TAnsiColor; static;
    class function Gray85 : TAnsiColor; static;
    class function Grey89 : TAnsiColor; static;
    class function Gray89 : TAnsiColor; static;
    class function Grey93 : TAnsiColor; static;
    class function Gray93 : TAnsiColor; static;

    { Queries }
    function IsDefault : Boolean;
    function HasPaletteIndex : Boolean;
    function ToHex : string;
    function Equals(const other : TAnsiColor) : Boolean;
    { Returns the canonical palette name (e.g. 'red', 'mediumpurple') when the
      color has a palette index, '#rrggbb' when it's a true-color RGB, or ''
      when the color is default. Suitable for use inside markup style tags. }
    function ToMarkup : string;

    { Operations }
    function Blend(const other : TAnsiColor; factor : Single) : TAnsiColor;
    function ToNearest(system : TColorSystem) : TAnsiColor;

    property R : Byte read FR;
    property G : Byte read FG;
    property B : Byte read FB;
    property Number : SmallInt read FNumber;
  end;

implementation

uses
  System.SysUtils;

{ Lookup table for the standard 16 ANSI colors, indexed by palette number.
  Used for "nearest" calculations in lower color systems. }
const
  ANSI16 : array[0..15] of record
    R, G, B : Byte;
  end = (
    (R:   0; G:   0; B:   0),   // 0  black
    (R: 128; G:   0; B:   0),   // 1  maroon
    (R:   0; G: 128; B:   0),   // 2  green
    (R: 128; G: 128; B:   0),   // 3  olive
    (R:   0; G:   0; B: 128),   // 4  navy
    (R: 128; G:   0; B: 128),   // 5  purple
    (R:   0; G: 128; B: 128),   // 6  teal
    (R: 192; G: 192; B: 192),   // 7  silver
    (R: 128; G: 128; B: 128),   // 8  grey
    (R: 255; G:   0; B:   0),   // 9  red
    (R:   0; G: 255; B:   0),   // 10 lime
    (R: 255; G: 255; B:   0),   // 11 yellow
    (R:   0; G:   0; B: 255),   // 12 blue
    (R: 255; G:   0; B: 255),   // 13 fuchsia
    (R:   0; G: 255; B: 255),   // 14 aqua
    (R: 255; G: 255; B: 255)    // 15 white
  );

{ TAnsiColor }

class function TAnsiColor.Make(r, g, b : Byte; number : SmallInt) : TAnsiColor;
begin
  result.FHasValue := True;
  result.FR := r;
  result.FG := g;
  result.FB := b;
  result.FNumber := number;
end;

class function TAnsiColor.Default : TAnsiColor;
begin
  FillChar(result, SizeOf(result), 0);
  // FHasValue stays False => "no color"
end;

class function TAnsiColor.FromRGB(r, g, b : Byte) : TAnsiColor;
begin
  result := Make(r, g, b, -1);
end;

class function TAnsiColor.FromIndex(index : Byte) : TAnsiColor;
var
  r, g, b : Byte;
  i       : Integer;
  cube    : Integer;
  level   : array[0..5] of Byte;
  shade   : Integer;
begin
  if index < 16 then
  begin
    result := Make(ANSI16[index].R, ANSI16[index].G, ANSI16[index].B, index);
    Exit;
  end;

  if index < 232 then
  begin
    // 6x6x6 color cube
    level[0] := 0;
    level[1] := 95;
    level[2] := 135;
    level[3] := 175;
    level[4] := 215;
    level[5] := 255;
    cube := index - 16;
    r := level[(cube div 36) mod 6];
    g := level[(cube div  6) mod 6];
    b := level[ cube         mod 6];
    result := Make(r, g, b, index);
    Exit;
  end;

  // grayscale ramp 232..255
  i := index - 232;
  shade := 8 + i * 10;
  result := Make(Byte(shade), Byte(shade), Byte(shade), index);
end;

class function TAnsiColor.FromHex(const hex : string) : TAnsiColor;
var
  s       : string;
  r, g, b : Byte;
begin
  s := hex;
  if (Length(s) > 0) and (s[1] = '#') then
    Delete(s, 1, 1);

  if Length(s) = 3 then
  begin
    // Short form: #rgb  =>  #rrggbb
    s := s[1] + s[1] + s[2] + s[2] + s[3] + s[3];
  end;

  if Length(s) <> 6 then
    raise EConvertError.CreateFmt('Invalid hex color "%s"', [hex]);

  r := Byte(StrToInt('$' + Copy(s, 1, 2)));
  g := Byte(StrToInt('$' + Copy(s, 3, 2)));
  b := Byte(StrToInt('$' + Copy(s, 5, 2)));
  result := Make(r, g, b, -1);
end;

class function TAnsiColor.TryFromHex(const hex : string; out color : TAnsiColor) : Boolean;
begin
  try
    color := FromHex(hex);
    result := True;
  except
    color := TAnsiColor.Default;
    result := False;
  end;
end;

// Named colors ---------------------------------------------------------------

class function TAnsiColor.Black   : TAnsiColor; begin result := FromIndex(0);  end;
class function TAnsiColor.Maroon  : TAnsiColor; begin result := FromIndex(1);  end;
class function TAnsiColor.Green   : TAnsiColor; begin result := FromIndex(2);  end;
class function TAnsiColor.Olive   : TAnsiColor; begin result := FromIndex(3);  end;
class function TAnsiColor.Navy    : TAnsiColor; begin result := FromIndex(4);  end;
class function TAnsiColor.Purple  : TAnsiColor; begin result := FromIndex(5);  end;
class function TAnsiColor.Teal    : TAnsiColor; begin result := FromIndex(6);  end;
class function TAnsiColor.Silver  : TAnsiColor; begin result := FromIndex(7);  end;
class function TAnsiColor.Grey    : TAnsiColor; begin result := FromIndex(8);  end;
class function TAnsiColor.Red     : TAnsiColor; begin result := FromIndex(9);  end;
class function TAnsiColor.Lime    : TAnsiColor; begin result := FromIndex(10); end;
class function TAnsiColor.Yellow  : TAnsiColor; begin result := FromIndex(11); end;
class function TAnsiColor.Blue    : TAnsiColor; begin result := FromIndex(12); end;
class function TAnsiColor.Fuchsia : TAnsiColor; begin result := FromIndex(13); end;
class function TAnsiColor.Aqua    : TAnsiColor; begin result := FromIndex(14); end;
class function TAnsiColor.White   : TAnsiColor; begin result := FromIndex(15); end;

// Extended xterm-256 named palette ------------------------------------------
//
// Mechanically ported from Spectre.Console's
//   src/Spectre.Console/Generated/Spectre.Console.SourceGenerator/
//   Spectre.Console.SourceGenerator.Colors.ColorGenerator/
//   Color.Generated.g.cs
// Imported: 2026-04-25 (290 source entries, 274 listed below; the 16 standard
// ANSI colors above cover indices 0..15). Re-port from the same path for a
// future Spectre version - the upstream sed/awk pipeline transforms each
//   public static Color Foo { get; } = new Color(idx, r, g, b);
// into
//   class function TAnsiColor.Foo : TAnsiColor; begin result := FromIndex(idx); end;
// and is regenerated on demand. The Spectre source-gen names occasionally
// include `_1`, `_2` etc. suffixes for repeated palette positions; those are
// kept verbatim so the call sites match Spectre's `Color.Blue3_1` exactly.

class function TAnsiColor.Grey0 : TAnsiColor; begin result := FromIndex(16); end;
class function TAnsiColor.Gray0 : TAnsiColor; begin result := FromIndex(16); end;
class function TAnsiColor.NavyBlue : TAnsiColor; begin result := FromIndex(17); end;
class function TAnsiColor.DarkBlue : TAnsiColor; begin result := FromIndex(18); end;
class function TAnsiColor.Blue3 : TAnsiColor; begin result := FromIndex(19); end;
class function TAnsiColor.Blue3_1 : TAnsiColor; begin result := FromIndex(20); end;
class function TAnsiColor.Blue1 : TAnsiColor; begin result := FromIndex(21); end;
class function TAnsiColor.DarkGreen : TAnsiColor; begin result := FromIndex(22); end;
class function TAnsiColor.DeepSkyBlue4 : TAnsiColor; begin result := FromIndex(23); end;
class function TAnsiColor.DeepSkyBlue4_1 : TAnsiColor; begin result := FromIndex(24); end;
class function TAnsiColor.DeepSkyBlue4_2 : TAnsiColor; begin result := FromIndex(25); end;
class function TAnsiColor.DodgerBlue3 : TAnsiColor; begin result := FromIndex(26); end;
class function TAnsiColor.DodgerBlue2 : TAnsiColor; begin result := FromIndex(27); end;
class function TAnsiColor.Green4 : TAnsiColor; begin result := FromIndex(28); end;
class function TAnsiColor.SpringGreen4 : TAnsiColor; begin result := FromIndex(29); end;
class function TAnsiColor.Turquoise4 : TAnsiColor; begin result := FromIndex(30); end;
class function TAnsiColor.DeepSkyBlue3 : TAnsiColor; begin result := FromIndex(31); end;
class function TAnsiColor.DeepSkyBlue3_1 : TAnsiColor; begin result := FromIndex(32); end;
class function TAnsiColor.DodgerBlue1 : TAnsiColor; begin result := FromIndex(33); end;
class function TAnsiColor.Green3 : TAnsiColor; begin result := FromIndex(34); end;
class function TAnsiColor.SpringGreen3 : TAnsiColor; begin result := FromIndex(35); end;
class function TAnsiColor.DarkCyan : TAnsiColor; begin result := FromIndex(36); end;
class function TAnsiColor.LightSeaGreen : TAnsiColor; begin result := FromIndex(37); end;
class function TAnsiColor.DeepSkyBlue2 : TAnsiColor; begin result := FromIndex(38); end;
class function TAnsiColor.DeepSkyBlue1 : TAnsiColor; begin result := FromIndex(39); end;
class function TAnsiColor.Green3_1 : TAnsiColor; begin result := FromIndex(40); end;
class function TAnsiColor.SpringGreen3_1 : TAnsiColor; begin result := FromIndex(41); end;
class function TAnsiColor.SpringGreen2 : TAnsiColor; begin result := FromIndex(42); end;
class function TAnsiColor.Cyan3 : TAnsiColor; begin result := FromIndex(43); end;
class function TAnsiColor.DarkTurquoise : TAnsiColor; begin result := FromIndex(44); end;
class function TAnsiColor.Turquoise2 : TAnsiColor; begin result := FromIndex(45); end;
class function TAnsiColor.Green1 : TAnsiColor; begin result := FromIndex(46); end;
class function TAnsiColor.SpringGreen2_1 : TAnsiColor; begin result := FromIndex(47); end;
class function TAnsiColor.SpringGreen1 : TAnsiColor; begin result := FromIndex(48); end;
class function TAnsiColor.MediumSpringGreen : TAnsiColor; begin result := FromIndex(49); end;
class function TAnsiColor.Cyan2 : TAnsiColor; begin result := FromIndex(50); end;
class function TAnsiColor.Cyan1 : TAnsiColor; begin result := FromIndex(51); end;
class function TAnsiColor.DarkRed : TAnsiColor; begin result := FromIndex(52); end;
class function TAnsiColor.DeepPink4 : TAnsiColor; begin result := FromIndex(53); end;
class function TAnsiColor.Purple4 : TAnsiColor; begin result := FromIndex(54); end;
class function TAnsiColor.Purple4_1 : TAnsiColor; begin result := FromIndex(55); end;
class function TAnsiColor.Purple3 : TAnsiColor; begin result := FromIndex(56); end;
class function TAnsiColor.BlueViolet : TAnsiColor; begin result := FromIndex(57); end;
class function TAnsiColor.Orange4 : TAnsiColor; begin result := FromIndex(58); end;
class function TAnsiColor.Grey37 : TAnsiColor; begin result := FromIndex(59); end;
class function TAnsiColor.Gray37 : TAnsiColor; begin result := FromIndex(59); end;
class function TAnsiColor.MediumPurple4 : TAnsiColor; begin result := FromIndex(60); end;
class function TAnsiColor.SlateBlue3 : TAnsiColor; begin result := FromIndex(61); end;
class function TAnsiColor.SlateBlue3_1 : TAnsiColor; begin result := FromIndex(62); end;
class function TAnsiColor.RoyalBlue1 : TAnsiColor; begin result := FromIndex(63); end;
class function TAnsiColor.Chartreuse4 : TAnsiColor; begin result := FromIndex(64); end;
class function TAnsiColor.DarkSeaGreen4 : TAnsiColor; begin result := FromIndex(65); end;
class function TAnsiColor.PaleTurquoise4 : TAnsiColor; begin result := FromIndex(66); end;
class function TAnsiColor.SteelBlue : TAnsiColor; begin result := FromIndex(67); end;
class function TAnsiColor.SteelBlue3 : TAnsiColor; begin result := FromIndex(68); end;
class function TAnsiColor.CornflowerBlue : TAnsiColor; begin result := FromIndex(69); end;
class function TAnsiColor.Chartreuse3 : TAnsiColor; begin result := FromIndex(70); end;
class function TAnsiColor.DarkSeaGreen4_1 : TAnsiColor; begin result := FromIndex(71); end;
class function TAnsiColor.CadetBlue : TAnsiColor; begin result := FromIndex(72); end;
class function TAnsiColor.CadetBlue_1 : TAnsiColor; begin result := FromIndex(73); end;
class function TAnsiColor.SkyBlue3 : TAnsiColor; begin result := FromIndex(74); end;
class function TAnsiColor.SteelBlue1 : TAnsiColor; begin result := FromIndex(75); end;
class function TAnsiColor.Chartreuse3_1 : TAnsiColor; begin result := FromIndex(76); end;
class function TAnsiColor.PaleGreen3 : TAnsiColor; begin result := FromIndex(77); end;
class function TAnsiColor.SeaGreen3 : TAnsiColor; begin result := FromIndex(78); end;
class function TAnsiColor.Aquamarine3 : TAnsiColor; begin result := FromIndex(79); end;
class function TAnsiColor.MediumTurquoise : TAnsiColor; begin result := FromIndex(80); end;
class function TAnsiColor.SteelBlue1_1 : TAnsiColor; begin result := FromIndex(81); end;
class function TAnsiColor.Chartreuse2 : TAnsiColor; begin result := FromIndex(82); end;
class function TAnsiColor.SeaGreen2 : TAnsiColor; begin result := FromIndex(83); end;
class function TAnsiColor.SeaGreen1 : TAnsiColor; begin result := FromIndex(84); end;
class function TAnsiColor.SeaGreen1_1 : TAnsiColor; begin result := FromIndex(85); end;
class function TAnsiColor.Aquamarine1 : TAnsiColor; begin result := FromIndex(86); end;
class function TAnsiColor.DarkSlateGray2 : TAnsiColor; begin result := FromIndex(87); end;
class function TAnsiColor.DarkRed_1 : TAnsiColor; begin result := FromIndex(88); end;
class function TAnsiColor.DeepPink4_1 : TAnsiColor; begin result := FromIndex(89); end;
class function TAnsiColor.DarkMagenta : TAnsiColor; begin result := FromIndex(90); end;
class function TAnsiColor.DarkMagenta_1 : TAnsiColor; begin result := FromIndex(91); end;
class function TAnsiColor.DarkViolet : TAnsiColor; begin result := FromIndex(92); end;
class function TAnsiColor.Purple_1 : TAnsiColor; begin result := FromIndex(93); end;
class function TAnsiColor.Orange4_1 : TAnsiColor; begin result := FromIndex(94); end;
class function TAnsiColor.LightPink4 : TAnsiColor; begin result := FromIndex(95); end;
class function TAnsiColor.Plum4 : TAnsiColor; begin result := FromIndex(96); end;
class function TAnsiColor.MediumPurple3 : TAnsiColor; begin result := FromIndex(97); end;
class function TAnsiColor.MediumPurple3_1 : TAnsiColor; begin result := FromIndex(98); end;
class function TAnsiColor.SlateBlue1 : TAnsiColor; begin result := FromIndex(99); end;
class function TAnsiColor.Yellow4 : TAnsiColor; begin result := FromIndex(100); end;
class function TAnsiColor.Wheat4 : TAnsiColor; begin result := FromIndex(101); end;
class function TAnsiColor.Grey53 : TAnsiColor; begin result := FromIndex(102); end;
class function TAnsiColor.Gray53 : TAnsiColor; begin result := FromIndex(102); end;
class function TAnsiColor.LightSlateGrey : TAnsiColor; begin result := FromIndex(103); end;
class function TAnsiColor.MediumPurple : TAnsiColor; begin result := FromIndex(104); end;
class function TAnsiColor.LightSlateBlue : TAnsiColor; begin result := FromIndex(105); end;
class function TAnsiColor.Yellow4_1 : TAnsiColor; begin result := FromIndex(106); end;
class function TAnsiColor.DarkOliveGreen3 : TAnsiColor; begin result := FromIndex(107); end;
class function TAnsiColor.DarkSeaGreen : TAnsiColor; begin result := FromIndex(108); end;
class function TAnsiColor.LightSkyBlue3 : TAnsiColor; begin result := FromIndex(109); end;
class function TAnsiColor.LightSkyBlue3_1 : TAnsiColor; begin result := FromIndex(110); end;
class function TAnsiColor.SkyBlue2 : TAnsiColor; begin result := FromIndex(111); end;
class function TAnsiColor.Chartreuse2_1 : TAnsiColor; begin result := FromIndex(112); end;
class function TAnsiColor.DarkOliveGreen3_1 : TAnsiColor; begin result := FromIndex(113); end;
class function TAnsiColor.PaleGreen3_1 : TAnsiColor; begin result := FromIndex(114); end;
class function TAnsiColor.DarkSeaGreen3 : TAnsiColor; begin result := FromIndex(115); end;
class function TAnsiColor.DarkSlateGray3 : TAnsiColor; begin result := FromIndex(116); end;
class function TAnsiColor.SkyBlue1 : TAnsiColor; begin result := FromIndex(117); end;
class function TAnsiColor.Chartreuse1 : TAnsiColor; begin result := FromIndex(118); end;
class function TAnsiColor.LightGreen : TAnsiColor; begin result := FromIndex(119); end;
class function TAnsiColor.LightGreen_1 : TAnsiColor; begin result := FromIndex(120); end;
class function TAnsiColor.PaleGreen1 : TAnsiColor; begin result := FromIndex(121); end;
class function TAnsiColor.Aquamarine1_1 : TAnsiColor; begin result := FromIndex(122); end;
class function TAnsiColor.DarkSlateGray1 : TAnsiColor; begin result := FromIndex(123); end;
class function TAnsiColor.Red3 : TAnsiColor; begin result := FromIndex(124); end;
class function TAnsiColor.DeepPink4_2 : TAnsiColor; begin result := FromIndex(125); end;
class function TAnsiColor.MediumVioletRed : TAnsiColor; begin result := FromIndex(126); end;
class function TAnsiColor.Magenta3 : TAnsiColor; begin result := FromIndex(127); end;
class function TAnsiColor.DarkViolet_1 : TAnsiColor; begin result := FromIndex(128); end;
class function TAnsiColor.Purple_2 : TAnsiColor; begin result := FromIndex(129); end;
class function TAnsiColor.DarkOrange3 : TAnsiColor; begin result := FromIndex(130); end;
class function TAnsiColor.IndianRed : TAnsiColor; begin result := FromIndex(131); end;
class function TAnsiColor.HotPink3 : TAnsiColor; begin result := FromIndex(132); end;
class function TAnsiColor.MediumOrchid3 : TAnsiColor; begin result := FromIndex(133); end;
class function TAnsiColor.MediumOrchid : TAnsiColor; begin result := FromIndex(134); end;
class function TAnsiColor.MediumPurple2 : TAnsiColor; begin result := FromIndex(135); end;
class function TAnsiColor.DarkGoldenrod : TAnsiColor; begin result := FromIndex(136); end;
class function TAnsiColor.LightSalmon3 : TAnsiColor; begin result := FromIndex(137); end;
class function TAnsiColor.RosyBrown : TAnsiColor; begin result := FromIndex(138); end;
class function TAnsiColor.Grey63 : TAnsiColor; begin result := FromIndex(139); end;
class function TAnsiColor.Gray63 : TAnsiColor; begin result := FromIndex(139); end;
class function TAnsiColor.MediumPurple2_1 : TAnsiColor; begin result := FromIndex(140); end;
class function TAnsiColor.MediumPurple1 : TAnsiColor; begin result := FromIndex(141); end;
class function TAnsiColor.Gold3 : TAnsiColor; begin result := FromIndex(142); end;
class function TAnsiColor.DarkKhaki : TAnsiColor; begin result := FromIndex(143); end;
class function TAnsiColor.NavajoWhite3 : TAnsiColor; begin result := FromIndex(144); end;
class function TAnsiColor.Grey69 : TAnsiColor; begin result := FromIndex(145); end;
class function TAnsiColor.Gray69 : TAnsiColor; begin result := FromIndex(145); end;
class function TAnsiColor.LightSteelBlue3 : TAnsiColor; begin result := FromIndex(146); end;
class function TAnsiColor.LightSteelBlue : TAnsiColor; begin result := FromIndex(147); end;
class function TAnsiColor.Yellow3 : TAnsiColor; begin result := FromIndex(148); end;
class function TAnsiColor.DarkOliveGreen3_2 : TAnsiColor; begin result := FromIndex(149); end;
class function TAnsiColor.DarkSeaGreen3_1 : TAnsiColor; begin result := FromIndex(150); end;
class function TAnsiColor.DarkSeaGreen2 : TAnsiColor; begin result := FromIndex(151); end;
class function TAnsiColor.LightCyan3 : TAnsiColor; begin result := FromIndex(152); end;
class function TAnsiColor.LightSkyBlue1 : TAnsiColor; begin result := FromIndex(153); end;
class function TAnsiColor.GreenYellow : TAnsiColor; begin result := FromIndex(154); end;
class function TAnsiColor.DarkOliveGreen2 : TAnsiColor; begin result := FromIndex(155); end;
class function TAnsiColor.PaleGreen1_1 : TAnsiColor; begin result := FromIndex(156); end;
class function TAnsiColor.DarkSeaGreen2_1 : TAnsiColor; begin result := FromIndex(157); end;
class function TAnsiColor.DarkSeaGreen1 : TAnsiColor; begin result := FromIndex(158); end;
class function TAnsiColor.PaleTurquoise1 : TAnsiColor; begin result := FromIndex(159); end;
class function TAnsiColor.Red3_1 : TAnsiColor; begin result := FromIndex(160); end;
class function TAnsiColor.DeepPink3 : TAnsiColor; begin result := FromIndex(161); end;
class function TAnsiColor.DeepPink3_1 : TAnsiColor; begin result := FromIndex(162); end;
class function TAnsiColor.Magenta3_1 : TAnsiColor; begin result := FromIndex(163); end;
class function TAnsiColor.Magenta3_2 : TAnsiColor; begin result := FromIndex(164); end;
class function TAnsiColor.Magenta2 : TAnsiColor; begin result := FromIndex(165); end;
class function TAnsiColor.DarkOrange3_1 : TAnsiColor; begin result := FromIndex(166); end;
class function TAnsiColor.IndianRed_1 : TAnsiColor; begin result := FromIndex(167); end;
class function TAnsiColor.HotPink3_1 : TAnsiColor; begin result := FromIndex(168); end;
class function TAnsiColor.HotPink2 : TAnsiColor; begin result := FromIndex(169); end;
class function TAnsiColor.Orchid : TAnsiColor; begin result := FromIndex(170); end;
class function TAnsiColor.MediumOrchid1 : TAnsiColor; begin result := FromIndex(171); end;
class function TAnsiColor.Orange3 : TAnsiColor; begin result := FromIndex(172); end;
class function TAnsiColor.LightSalmon3_1 : TAnsiColor; begin result := FromIndex(173); end;
class function TAnsiColor.LightPink3 : TAnsiColor; begin result := FromIndex(174); end;
class function TAnsiColor.Pink3 : TAnsiColor; begin result := FromIndex(175); end;
class function TAnsiColor.Plum3 : TAnsiColor; begin result := FromIndex(176); end;
class function TAnsiColor.Violet : TAnsiColor; begin result := FromIndex(177); end;
class function TAnsiColor.Gold3_1 : TAnsiColor; begin result := FromIndex(178); end;
class function TAnsiColor.LightGoldenrod3 : TAnsiColor; begin result := FromIndex(179); end;
class function TAnsiColor.Tan : TAnsiColor; begin result := FromIndex(180); end;
class function TAnsiColor.MistyRose3 : TAnsiColor; begin result := FromIndex(181); end;
class function TAnsiColor.Thistle3 : TAnsiColor; begin result := FromIndex(182); end;
class function TAnsiColor.Plum2 : TAnsiColor; begin result := FromIndex(183); end;
class function TAnsiColor.Yellow3_1 : TAnsiColor; begin result := FromIndex(184); end;
class function TAnsiColor.Khaki3 : TAnsiColor; begin result := FromIndex(185); end;
class function TAnsiColor.LightGoldenrod2 : TAnsiColor; begin result := FromIndex(186); end;
class function TAnsiColor.LightYellow3 : TAnsiColor; begin result := FromIndex(187); end;
class function TAnsiColor.Grey84 : TAnsiColor; begin result := FromIndex(188); end;
class function TAnsiColor.Gray84 : TAnsiColor; begin result := FromIndex(188); end;
class function TAnsiColor.LightSteelBlue1 : TAnsiColor; begin result := FromIndex(189); end;
class function TAnsiColor.Yellow2 : TAnsiColor; begin result := FromIndex(190); end;
class function TAnsiColor.DarkOliveGreen1 : TAnsiColor; begin result := FromIndex(191); end;
class function TAnsiColor.DarkOliveGreen1_1 : TAnsiColor; begin result := FromIndex(192); end;
class function TAnsiColor.DarkSeaGreen1_1 : TAnsiColor; begin result := FromIndex(193); end;
class function TAnsiColor.Honeydew2 : TAnsiColor; begin result := FromIndex(194); end;
class function TAnsiColor.LightCyan1 : TAnsiColor; begin result := FromIndex(195); end;
class function TAnsiColor.Red1 : TAnsiColor; begin result := FromIndex(196); end;
class function TAnsiColor.DeepPink2 : TAnsiColor; begin result := FromIndex(197); end;
class function TAnsiColor.DeepPink1 : TAnsiColor; begin result := FromIndex(198); end;
class function TAnsiColor.DeepPink1_1 : TAnsiColor; begin result := FromIndex(199); end;
class function TAnsiColor.Magenta2_1 : TAnsiColor; begin result := FromIndex(200); end;
class function TAnsiColor.Magenta1 : TAnsiColor; begin result := FromIndex(201); end;
class function TAnsiColor.OrangeRed1 : TAnsiColor; begin result := FromIndex(202); end;
class function TAnsiColor.IndianRed1 : TAnsiColor; begin result := FromIndex(203); end;
class function TAnsiColor.IndianRed1_1 : TAnsiColor; begin result := FromIndex(204); end;
class function TAnsiColor.HotPink : TAnsiColor; begin result := FromIndex(205); end;
class function TAnsiColor.HotPink_1 : TAnsiColor; begin result := FromIndex(206); end;
class function TAnsiColor.MediumOrchid1_1 : TAnsiColor; begin result := FromIndex(207); end;
class function TAnsiColor.DarkOrange : TAnsiColor; begin result := FromIndex(208); end;
class function TAnsiColor.Salmon1 : TAnsiColor; begin result := FromIndex(209); end;
class function TAnsiColor.LightCoral : TAnsiColor; begin result := FromIndex(210); end;
class function TAnsiColor.PaleVioletRed1 : TAnsiColor; begin result := FromIndex(211); end;
class function TAnsiColor.Orchid2 : TAnsiColor; begin result := FromIndex(212); end;
class function TAnsiColor.Orchid1 : TAnsiColor; begin result := FromIndex(213); end;
class function TAnsiColor.Orange1 : TAnsiColor; begin result := FromIndex(214); end;
class function TAnsiColor.SandyBrown : TAnsiColor; begin result := FromIndex(215); end;
class function TAnsiColor.LightSalmon1 : TAnsiColor; begin result := FromIndex(216); end;
class function TAnsiColor.LightPink1 : TAnsiColor; begin result := FromIndex(217); end;
class function TAnsiColor.Pink1 : TAnsiColor; begin result := FromIndex(218); end;
class function TAnsiColor.Plum1 : TAnsiColor; begin result := FromIndex(219); end;
class function TAnsiColor.Gold1 : TAnsiColor; begin result := FromIndex(220); end;
class function TAnsiColor.LightGoldenrod2_1 : TAnsiColor; begin result := FromIndex(221); end;
class function TAnsiColor.LightGoldenrod2_2 : TAnsiColor; begin result := FromIndex(222); end;
class function TAnsiColor.NavajoWhite1 : TAnsiColor; begin result := FromIndex(223); end;
class function TAnsiColor.MistyRose1 : TAnsiColor; begin result := FromIndex(224); end;
class function TAnsiColor.Thistle1 : TAnsiColor; begin result := FromIndex(225); end;
class function TAnsiColor.Yellow1 : TAnsiColor; begin result := FromIndex(226); end;
class function TAnsiColor.LightGoldenrod1 : TAnsiColor; begin result := FromIndex(227); end;
class function TAnsiColor.Khaki1 : TAnsiColor; begin result := FromIndex(228); end;
class function TAnsiColor.Wheat1 : TAnsiColor; begin result := FromIndex(229); end;
class function TAnsiColor.Cornsilk1 : TAnsiColor; begin result := FromIndex(230); end;
class function TAnsiColor.Grey100 : TAnsiColor; begin result := FromIndex(231); end;
class function TAnsiColor.Gray100 : TAnsiColor; begin result := FromIndex(231); end;
class function TAnsiColor.Grey3 : TAnsiColor; begin result := FromIndex(232); end;
class function TAnsiColor.Gray3 : TAnsiColor; begin result := FromIndex(232); end;
class function TAnsiColor.Grey7 : TAnsiColor; begin result := FromIndex(233); end;
class function TAnsiColor.Gray7 : TAnsiColor; begin result := FromIndex(233); end;
class function TAnsiColor.Grey11 : TAnsiColor; begin result := FromIndex(234); end;
class function TAnsiColor.Gray11 : TAnsiColor; begin result := FromIndex(234); end;
class function TAnsiColor.Grey15 : TAnsiColor; begin result := FromIndex(235); end;
class function TAnsiColor.Gray15 : TAnsiColor; begin result := FromIndex(235); end;
class function TAnsiColor.Grey19 : TAnsiColor; begin result := FromIndex(236); end;
class function TAnsiColor.Gray19 : TAnsiColor; begin result := FromIndex(236); end;
class function TAnsiColor.Grey23 : TAnsiColor; begin result := FromIndex(237); end;
class function TAnsiColor.Gray23 : TAnsiColor; begin result := FromIndex(237); end;
class function TAnsiColor.Grey27 : TAnsiColor; begin result := FromIndex(238); end;
class function TAnsiColor.Gray27 : TAnsiColor; begin result := FromIndex(238); end;
class function TAnsiColor.Grey30 : TAnsiColor; begin result := FromIndex(239); end;
class function TAnsiColor.Gray30 : TAnsiColor; begin result := FromIndex(239); end;
class function TAnsiColor.Grey35 : TAnsiColor; begin result := FromIndex(240); end;
class function TAnsiColor.Gray35 : TAnsiColor; begin result := FromIndex(240); end;
class function TAnsiColor.Grey39 : TAnsiColor; begin result := FromIndex(241); end;
class function TAnsiColor.Gray39 : TAnsiColor; begin result := FromIndex(241); end;
class function TAnsiColor.Grey42 : TAnsiColor; begin result := FromIndex(242); end;
class function TAnsiColor.Gray42 : TAnsiColor; begin result := FromIndex(242); end;
class function TAnsiColor.Grey46 : TAnsiColor; begin result := FromIndex(243); end;
class function TAnsiColor.Gray46 : TAnsiColor; begin result := FromIndex(243); end;
class function TAnsiColor.Grey50 : TAnsiColor; begin result := FromIndex(244); end;
class function TAnsiColor.Gray50 : TAnsiColor; begin result := FromIndex(244); end;
class function TAnsiColor.Grey54 : TAnsiColor; begin result := FromIndex(245); end;
class function TAnsiColor.Gray54 : TAnsiColor; begin result := FromIndex(245); end;
class function TAnsiColor.Grey58 : TAnsiColor; begin result := FromIndex(246); end;
class function TAnsiColor.Gray58 : TAnsiColor; begin result := FromIndex(246); end;
class function TAnsiColor.Grey62 : TAnsiColor; begin result := FromIndex(247); end;
class function TAnsiColor.Gray62 : TAnsiColor; begin result := FromIndex(247); end;
class function TAnsiColor.Grey66 : TAnsiColor; begin result := FromIndex(248); end;
class function TAnsiColor.Gray66 : TAnsiColor; begin result := FromIndex(248); end;
class function TAnsiColor.Grey70 : TAnsiColor; begin result := FromIndex(249); end;
class function TAnsiColor.Gray70 : TAnsiColor; begin result := FromIndex(249); end;
class function TAnsiColor.Grey74 : TAnsiColor; begin result := FromIndex(250); end;
class function TAnsiColor.Gray74 : TAnsiColor; begin result := FromIndex(250); end;
class function TAnsiColor.Grey78 : TAnsiColor; begin result := FromIndex(251); end;
class function TAnsiColor.Gray78 : TAnsiColor; begin result := FromIndex(251); end;
class function TAnsiColor.Grey82 : TAnsiColor; begin result := FromIndex(252); end;
class function TAnsiColor.Gray82 : TAnsiColor; begin result := FromIndex(252); end;
class function TAnsiColor.Grey85 : TAnsiColor; begin result := FromIndex(253); end;
class function TAnsiColor.Gray85 : TAnsiColor; begin result := FromIndex(253); end;
class function TAnsiColor.Grey89 : TAnsiColor; begin result := FromIndex(254); end;
class function TAnsiColor.Gray89 : TAnsiColor; begin result := FromIndex(254); end;
class function TAnsiColor.Grey93 : TAnsiColor; begin result := FromIndex(255); end;
class function TAnsiColor.Gray93 : TAnsiColor; begin result := FromIndex(255); end;

// Queries --------------------------------------------------------------------

function TAnsiColor.IsDefault : Boolean;
begin
  result := not FHasValue;
end;

function TAnsiColor.HasPaletteIndex : Boolean;
begin
  result := FHasValue and (FNumber >= 0);
end;

function TAnsiColor.ToHex : string;
begin
  if IsDefault then
    result := ''
  else
    result := Format('%.2x%.2x%.2x', [FR, FG, FB]);
end;

function TAnsiColor.Equals(const other : TAnsiColor) : Boolean;
begin
  if FHasValue <> other.FHasValue then
  begin
    result := False;
    Exit;
  end;
  if not FHasValue then
  begin
    result := True;
    Exit;
  end;
  result := (FR = other.FR) and (FG = other.FG) and (FB = other.FB) and (FNumber = other.FNumber);
end;

// Operations -----------------------------------------------------------------

function TAnsiColor.Blend(const other : TAnsiColor; factor : Single) : TAnsiColor;
var
  f    : Single;
  r, g, b : Byte;
begin
  if IsDefault or other.IsDefault then
  begin
    result := Self;
    Exit;
  end;
  f := factor;
  if f < 0 then f := 0;
  if f > 1 then f := 1;
  r := Byte(Round(FR + (other.FR - Integer(FR)) * f));
  g := Byte(Round(FG + (other.FG - Integer(FG)) * f));
  b := Byte(Round(FB + (other.FB - Integer(FB)) * f));
  result := TAnsiColor.FromRGB(r, g, b);
end;

function NearestIndex(const R, G, B : Byte; maxIndex : Integer) : Integer;
var
  i         : Integer;
  dr, dg, db: Integer;
  d, best   : Integer;
begin
  result := 0;
  best := MaxInt;
  for i := 0 to maxIndex - 1 do
  begin
    dr := Integer(ANSI16[i].R) - R;
    dg := Integer(ANSI16[i].G) - G;
    db := Integer(ANSI16[i].B) - B;
    d := dr*dr + dg*dg + db*db;
    if d < best then
    begin
      best := d;
      result := i;
    end;
  end;
end;

function TAnsiColor.ToNearest(system : TColorSystem) : TAnsiColor;
var
  idx : Integer;
begin
  if IsDefault then
  begin
    result := Self;
    Exit;
  end;

  case system of
    TColorSystem.NoColors:
      result := TAnsiColor.Default;

    TColorSystem.Legacy:
      begin
        if HasPaletteIndex and (FNumber < 8) then
          result := Self
        else
        begin
          idx := NearestIndex(FR, FG, FB, 8);
          result := TAnsiColor.FromIndex(Byte(idx));
        end;
      end;

    TColorSystem.Standard:
      begin
        if HasPaletteIndex and (FNumber < 16) then
          result := Self
        else
        begin
          idx := NearestIndex(FR, FG, FB, 16);
          result := TAnsiColor.FromIndex(Byte(idx));
        end;
      end;

    TColorSystem.EightBit:
      begin
        // If we already have a palette index, keep it; otherwise keep RGB and
        // let 256-color quantisation happen at emit time.
        result := Self;
      end;

    TColorSystem.TrueColor:
      result := Self;
  else
    result := Self;
  end;
end;

// Name <-> palette-index lookup ---------------------------------------------
//
// Reverse-direction table for ToMarkup and the source of TryFromName/FromName.
// Names are lowercase; "grey" is canonical (callers can also pass "gray" form
// and a few other aliases - those are normalised in TryFromName before lookup).
// Order matches the palette index 0..255 so ToMarkup can index directly.

const
  COLOR_NAMES : array[0..255] of string = (
    'black', 'maroon', 'green', 'olive', 'navy', 'purple', 'teal', 'silver',
    'grey', 'red', 'lime', 'yellow', 'blue', 'fuchsia', 'aqua', 'white',
    'grey0', 'navyblue', 'darkblue', 'blue3', 'blue3_1', 'blue1',
    'darkgreen', 'deepskyblue4', 'deepskyblue4_1', 'deepskyblue4_2',
    'dodgerblue3', 'dodgerblue2', 'green4', 'springgreen4', 'turquoise4',
    'deepskyblue3', 'deepskyblue3_1', 'dodgerblue1', 'green3', 'springgreen3',
    'darkcyan', 'lightseagreen', 'deepskyblue2', 'deepskyblue1',
    'green3_1', 'springgreen3_1', 'springgreen2', 'cyan3', 'darkturquoise',
    'turquoise2', 'green1', 'springgreen2_1', 'springgreen1',
    'mediumspringgreen', 'cyan2', 'cyan1', 'darkred', 'deeppink4',
    'purple4', 'purple4_1', 'purple3', 'blueviolet', 'orange4', 'grey37',
    'mediumpurple4', 'slateblue3', 'slateblue3_1', 'royalblue1',
    'chartreuse4', 'darkseagreen4', 'paleturquoise4', 'steelblue',
    'steelblue3', 'cornflowerblue', 'chartreuse3', 'darkseagreen4_1',
    'cadetblue', 'cadetblue_1', 'skyblue3', 'steelblue1', 'chartreuse3_1',
    'palegreen3', 'seagreen3', 'aquamarine3', 'mediumturquoise',
    'steelblue1_1', 'chartreuse2', 'seagreen2', 'seagreen1', 'seagreen1_1',
    'aquamarine1', 'darkslategray2', 'darkred_1', 'deeppink4_1',
    'darkmagenta', 'darkmagenta_1', 'darkviolet', 'purple_1', 'orange4_1',
    'lightpink4', 'plum4', 'mediumpurple3', 'mediumpurple3_1', 'slateblue1',
    'yellow4', 'wheat4', 'grey53', 'lightslategrey', 'mediumpurple',
    'lightslateblue', 'yellow4_1', 'darkolivegreen3', 'darkseagreen',
    'lightskyblue3', 'lightskyblue3_1', 'skyblue2', 'chartreuse2_1',
    'darkolivegreen3_1', 'palegreen3_1', 'darkseagreen3', 'darkslategray3',
    'skyblue1', 'chartreuse1', 'lightgreen', 'lightgreen_1', 'palegreen1',
    'aquamarine1_1', 'darkslategray1', 'red3', 'deeppink4_2',
    'mediumvioletred', 'magenta3', 'darkviolet_1', 'purple_2', 'darkorange3',
    'indianred', 'hotpink3', 'mediumorchid3', 'mediumorchid', 'mediumpurple2',
    'darkgoldenrod', 'lightsalmon3', 'rosybrown', 'grey63', 'mediumpurple2_1',
    'mediumpurple1', 'gold3', 'darkkhaki', 'navajowhite3', 'grey69',
    'lightsteelblue3', 'lightsteelblue', 'yellow3', 'darkolivegreen3_2',
    'darkseagreen3_1', 'darkseagreen2', 'lightcyan3', 'lightskyblue1',
    'greenyellow', 'darkolivegreen2', 'palegreen1_1', 'darkseagreen2_1',
    'darkseagreen1', 'paleturquoise1', 'red3_1', 'deeppink3', 'deeppink3_1',
    'magenta3_1', 'magenta3_2', 'magenta2', 'darkorange3_1', 'indianred_1',
    'hotpink3_1', 'hotpink2', 'orchid', 'mediumorchid1', 'orange3',
    'lightsalmon3_1', 'lightpink3', 'pink3', 'plum3', 'violet', 'gold3_1',
    'lightgoldenrod3', 'tan', 'mistyrose3', 'thistle3', 'plum2',
    'yellow3_1', 'khaki3', 'lightgoldenrod2', 'lightyellow3', 'grey84',
    'lightsteelblue1', 'yellow2', 'darkolivegreen1', 'darkolivegreen1_1',
    'darkseagreen1_1', 'honeydew2', 'lightcyan1', 'red1', 'deeppink2',
    'deeppink1', 'deeppink1_1', 'magenta2_1', 'magenta1', 'orangered1',
    'indianred1', 'indianred1_1', 'hotpink', 'hotpink_1', 'mediumorchid1_1',
    'darkorange', 'salmon1', 'lightcoral', 'palevioletred1', 'orchid2',
    'orchid1', 'orange1', 'sandybrown', 'lightsalmon1', 'lightpink1',
    'pink1', 'plum1', 'gold1', 'lightgoldenrod2_1', 'lightgoldenrod2_2',
    'navajowhite1', 'mistyrose1', 'thistle1', 'yellow1', 'lightgoldenrod1',
    'khaki1', 'wheat1', 'cornsilk1', 'grey100',
    'grey3', 'grey7', 'grey11', 'grey15', 'grey19', 'grey23', 'grey27',
    'grey30', 'grey35', 'grey39', 'grey42', 'grey46', 'grey50', 'grey54',
    'grey58', 'grey62', 'grey66', 'grey70', 'grey74', 'grey78', 'grey82',
    'grey85', 'grey89', 'grey93'
  );

class function TAnsiColor.TryFromName(const name : string; out color : TAnsiColor) : Boolean;
var
  lname : string;
  i     : Integer;
begin
  color := TAnsiColor.Default;
  if name = '' then
  begin
    result := False;
    Exit;
  end;
  lname := LowerCase(Trim(name));
  if lname = 'default' then
  begin
    color := TAnsiColor.Default;
    result := True;
    Exit;
  end;
  // Common aliases that don't appear in the canonical name table.
  if lname = 'magenta' then lname := 'fuchsia'
  else if lname = 'cyan' then lname := 'aqua'
  else if (Length(lname) >= 4) and (Copy(lname, 1, 4) = 'gray') then
    lname := 'grey' + Copy(lname, 5, MaxInt);

  for i := 0 to High(COLOR_NAMES) do
  begin
    if COLOR_NAMES[i] = lname then
    begin
      color := TAnsiColor.FromIndex(Byte(i));
      result := True;
      Exit;
    end;
  end;
  result := False;
end;

class function TAnsiColor.FromName(const name : string) : TAnsiColor;
begin
  if not TryFromName(name, result) then
    raise EConvertError.CreateFmt('Unknown color name "%s"', [name]);
end;

function TAnsiColor.ToMarkup : string;
begin
  if IsDefault then
  begin
    result := 'default';
    Exit;
  end;
  if HasPaletteIndex then
    result := COLOR_NAMES[FNumber]
  else
    result := '#' + Format('%.2x%.2x%.2x', [FR, FG, FB]);
end;

// Windows ConsoleColor <-> ANSI palette index. The Win32 console swaps the
// blue and red bits relative to ANSI 16, so we route through a small map.
const
  CONSOLE_TO_ANSI : array[0..15] of Byte = (
    0,   // ConsoleColor.Black       -> ANSI black
    4,   // ConsoleColor.DarkBlue    -> ANSI navy
    2,   // ConsoleColor.DarkGreen   -> ANSI green
    6,   // ConsoleColor.DarkCyan    -> ANSI teal
    1,   // ConsoleColor.DarkRed     -> ANSI maroon
    5,   // ConsoleColor.DarkMagenta -> ANSI purple
    3,   // ConsoleColor.DarkYellow  -> ANSI olive
    7,   // ConsoleColor.Gray        -> ANSI silver
    8,   // ConsoleColor.DarkGray    -> ANSI grey
    12,  // ConsoleColor.Blue        -> ANSI blue
    10,  // ConsoleColor.Green       -> ANSI lime
    14,  // ConsoleColor.Cyan        -> ANSI aqua
    9,   // ConsoleColor.Red         -> ANSI red
    13,  // ConsoleColor.Magenta     -> ANSI fuchsia
    11,  // ConsoleColor.Yellow      -> ANSI yellow
    15   // ConsoleColor.White       -> ANSI white
  );

class function TAnsiColor.FromConsoleColor(value : Integer) : TAnsiColor;
begin
  if (value < 0) or (value > 15) then
    raise EConvertError.CreateFmt('ConsoleColor value %d is out of range 0..15', [value]);
  result := TAnsiColor.FromIndex(CONSOLE_TO_ANSI[value]);
end;

function TAnsiColor.ToConsoleColor : Integer;
var
  i : Integer;
begin
  result := -1;
  if (not FHasValue) or (FNumber < 0) or (FNumber > 15) then Exit;
  for i := 0 to 15 do
    if CONSOLE_TO_ANSI[i] = FNumber then
    begin
      result := i;
      Exit;
    end;
end;

end.
