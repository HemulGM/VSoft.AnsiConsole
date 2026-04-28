unit VSoft.AnsiConsole.Live.Spinners;

{
  Spinner frame sets, ported from Spectre.Console. Each spinner is a
  (frame list, interval in ms) pair plus an IsUnicode flag.

  Source:   https://github.com/spectreconsole/spectre.console
            Spinner.Generated.g.cs
  Imported: 2026-04-25
  Upstream: https://github.com/sindresorhus/cli-spinners

  When `unicode=False` is passed to `Spinner()`, any kind whose frames
  require unicode falls back to the simple 4-frame skLine set so the
  animation still works in legacy terminals.

  The MINENUMSIZE 4 directive below keeps TSpinnerKind as a 4-byte enum
  regardless of the consumer's directive stack, so adding more kinds
  later can't push past the 256-value byte-enum limit.
}

{$MINENUMSIZE 4}

interface

{$SCOPEDENUMS ON}
type
  TSpinnerKind = (
    Dots, Dots2, Line, Arc, Star,
    Aesthetic, Arrow, Arrow2, Arrow3, Ascii,
    Balloon, Balloon2, BetaWave, Binary, BluePulse,
    Bounce, BouncingBall, BouncingBar, BoxBounce, BoxBounce2,
    Christmas, Circle, CircleHalves, CircleQuarters, Clock,
    Default, Dots10, Dots11, Dots12, Dots13,
    Dots14, Dots3, Dots4, Dots5, Dots6,
    Dots7, Dots8, Dots8Bit, Dots9, DotsCircle,
    Dqpb, DwarfFortress, Earth, FingerDance, FistBump,
    Flip, Grenade, GrowHorizontal, GrowVertical, Hamburger,
    Hearts, Layer, Line2, Material, Mindblown,
    Monkey, Moon, Noise, OrangeBluePulse, OrangePulse,
    Pipe, Point, Pong, Runner, Sand,
    Shark, SimpleDots, SimpleDotsScrolling, Smiley, SoccerHeader,
    Speaker, SquareCorners, Squish, Star2, TimeTravel,
    Toggle, Toggle10, Toggle11, Toggle12, Toggle13,
    Toggle2, Toggle3, Toggle4, Toggle5, Toggle6,
    Toggle7, Toggle8, Toggle9, Triangle, Weather
  );

  ISpinner = interface
    ['{4C3D7B5A-0E2F-4F16-9B82-7C5D1E8F2A30}']
    function Frames : Integer;
    function Frame(index : Integer) : string;
    function IntervalMs : Integer;
  end;

{ Named built-in spinner. }
function Spinner(kind : TSpinnerKind; unicode : Boolean = True) : ISpinner; overload;

{ User-defined spinner: supply a frame list + interval and get an ISpinner
  you can pass to Status.WithSpinner (ISpinner overload). Frames shorter
  than two still animate - Frame(i) wraps with `i mod Length(frames)`. }
function Spinner(const frames : TArray<string>; intervalMs : Integer) : ISpinner; overload;

type
  { Helper record - random-spinner factory.

    Picks a TSpinnerKind from the well-behaved subset (avoiding the
    wide-emoji spinners in legacy mode). Using a record rather than a
    free function keeps the namespace tidy: `RandomSpinner.Pick` reads
    intentionally on the call site. }
  RandomSpinner = record
    class function Pick : TSpinnerKind; static;
    class function Make(unicode : Boolean = True) : ISpinner; static;
  end;

implementation

type
  TSpinnerImpl = class(TInterfacedObject, ISpinner)
  strict private
    FFrames     : TArray<string>;
    FIntervalMs : Integer;
  public
    constructor Create(const frames : TArray<string>; interval : Integer);
    function Frames : Integer;
    function Frame(index : Integer) : string;
    function IntervalMs : Integer;
  end;

constructor TSpinnerImpl.Create(const frames : TArray<string>; interval : Integer);
begin
  inherited Create;
  FFrames := frames;
  FIntervalMs := interval;
end;

function TSpinnerImpl.Frames : Integer;
begin
  result := Length(FFrames);
end;

function TSpinnerImpl.Frame(index : Integer) : string;
var
  n : Integer;
begin
  n := Length(FFrames);
  if n = 0 then begin result := ''; Exit; end;
  if index < 0 then index := 0;
  result := FFrames[index mod n];
end;

function TSpinnerImpl.IntervalMs : Integer;
begin
  result := FIntervalMs;
end;

function Frames_Dots : TArray<string>;
begin
  SetLength(result, 10);
  result[0] := #$280B;
  result[1] := #$2819;
  result[2] := #$2839;
  result[3] := #$2838;
  result[4] := #$283C;
  result[5] := #$2834;
  result[6] := #$2826;
  result[7] := #$2827;
  result[8] := #$2807;
  result[9] := #$280F;
end;

function Frames_Dots2 : TArray<string>;
begin
  SetLength(result, 8);
  result[0] := #$28FE;
  result[1] := #$28FD;
  result[2] := #$28FB;
  result[3] := #$28BF;
  result[4] := #$287F;
  result[5] := #$28DF;
  result[6] := #$28EF;
  result[7] := #$28F7;
end;

function Frames_Line : TArray<string>;
begin
  SetLength(result, 4);
  result[0] := '-';
  result[1] := '\';
  result[2] := '|';
  result[3] := '/';
end;

function Frames_Arc : TArray<string>;
begin
  SetLength(result, 6);
  result[0] := #$25DC;
  result[1] := #$25E0;
  result[2] := #$25DD;
  result[3] := #$25DE;
  result[4] := #$25E1;
  result[5] := #$25DF;
end;

function Frames_Star : TArray<string>;
begin
  SetLength(result, 6);
  result[0] := #$2736;
  result[1] := #$2738;
  result[2] := #$2739;
  result[3] := #$273A;
  result[4] := #$2739;
  result[5] := #$2737;
end;

function Frames_Aesthetic : TArray<string>;
begin
  SetLength(result, 8);
  result[0] := #$25B0 + #$25B1 + #$25B1 + #$25B1 + #$25B1 + #$25B1 + #$25B1;
  result[1] := #$25B0 + #$25B0 + #$25B1 + #$25B1 + #$25B1 + #$25B1 + #$25B1;
  result[2] := #$25B0 + #$25B0 + #$25B0 + #$25B1 + #$25B1 + #$25B1 + #$25B1;
  result[3] := #$25B0 + #$25B0 + #$25B0 + #$25B0 + #$25B1 + #$25B1 + #$25B1;
  result[4] := #$25B0 + #$25B0 + #$25B0 + #$25B0 + #$25B0 + #$25B1 + #$25B1;
  result[5] := #$25B0 + #$25B0 + #$25B0 + #$25B0 + #$25B0 + #$25B0 + #$25B1;
  result[6] := #$25B0 + #$25B0 + #$25B0 + #$25B0 + #$25B0 + #$25B0 + #$25B0;
  result[7] := #$25B0 + #$25B1 + #$25B1 + #$25B1 + #$25B1 + #$25B1 + #$25B1;
end;

function Frames_Arrow : TArray<string>;
begin
  SetLength(result, 8);
  result[0] := #$2190;
  result[1] := #$2196;
  result[2] := #$2191;
  result[3] := #$2197;
  result[4] := #$2192;
  result[5] := #$2198;
  result[6] := #$2193;
  result[7] := #$2199;
end;

function Frames_Arrow2 : TArray<string>;
begin
  SetLength(result, 8);
  result[0] := #$2B06 + #$FE0F + ' ';
  result[1] := #$2197 + #$FE0F + ' ';
  result[2] := #$27A1 + #$FE0F + ' ';
  result[3] := #$2198 + #$FE0F + ' ';
  result[4] := #$2B07 + #$FE0F + ' ';
  result[5] := #$2199 + #$FE0F + ' ';
  result[6] := #$2B05 + #$FE0F + ' ';
  result[7] := #$2196 + #$FE0F + ' ';
end;

function Frames_Arrow3 : TArray<string>;
begin
  SetLength(result, 6);
  result[0] := #$25B9 + #$25B9 + #$25B9 + #$25B9 + #$25B9;
  result[1] := #$25B8 + #$25B9 + #$25B9 + #$25B9 + #$25B9;
  result[2] := #$25B9 + #$25B8 + #$25B9 + #$25B9 + #$25B9;
  result[3] := #$25B9 + #$25B9 + #$25B8 + #$25B9 + #$25B9;
  result[4] := #$25B9 + #$25B9 + #$25B9 + #$25B8 + #$25B9;
  result[5] := #$25B9 + #$25B9 + #$25B9 + #$25B9 + #$25B8;
end;

function Frames_Ascii : TArray<string>;
begin
  SetLength(result, 8);
  result[0] := '-';
  result[1] := '\';
  result[2] := '|';
  result[3] := '/';
  result[4] := '-';
  result[5] := '\';
  result[6] := '|';
  result[7] := '/';
end;

function Frames_Balloon : TArray<string>;
begin
  SetLength(result, 7);
  result[0] := ' ';
  result[1] := '.';
  result[2] := 'o';
  result[3] := 'O';
  result[4] := '@';
  result[5] := '*';
  result[6] := ' ';
end;

function Frames_Balloon2 : TArray<string>;
begin
  SetLength(result, 7);
  result[0] := '.';
  result[1] := 'o';
  result[2] := 'O';
  result[3] := #$00B0;
  result[4] := 'O';
  result[5] := 'o';
  result[6] := '.';
end;

function Frames_BetaWave : TArray<string>;
begin
  SetLength(result, 7);
  result[0] := #$03C1 + #$03B2 + #$03B2 + #$03B2 + #$03B2 + #$03B2 + #$03B2;
  result[1] := #$03B2 + #$03C1 + #$03B2 + #$03B2 + #$03B2 + #$03B2 + #$03B2;
  result[2] := #$03B2 + #$03B2 + #$03C1 + #$03B2 + #$03B2 + #$03B2 + #$03B2;
  result[3] := #$03B2 + #$03B2 + #$03B2 + #$03C1 + #$03B2 + #$03B2 + #$03B2;
  result[4] := #$03B2 + #$03B2 + #$03B2 + #$03B2 + #$03C1 + #$03B2 + #$03B2;
  result[5] := #$03B2 + #$03B2 + #$03B2 + #$03B2 + #$03B2 + #$03C1 + #$03B2;
  result[6] := #$03B2 + #$03B2 + #$03B2 + #$03B2 + #$03B2 + #$03B2 + #$03C1;
end;

function Frames_Binary : TArray<string>;
begin
  SetLength(result, 10);
  result[0] := '010010';
  result[1] := '001100';
  result[2] := '100101';
  result[3] := '111010';
  result[4] := '111101';
  result[5] := '010111';
  result[6] := '101011';
  result[7] := '111000';
  result[8] := '110011';
  result[9] := '110101';
end;

function Frames_BluePulse : TArray<string>;
begin
  SetLength(result, 5);
  result[0] := #$D83D#$DD39 + ' ';
  result[1] := #$D83D#$DD37 + ' ';
  result[2] := #$D83D#$DD35 + ' ';
  result[3] := #$D83D#$DD35 + ' ';
  result[4] := #$D83D#$DD37 + ' ';
end;

function Frames_Bounce : TArray<string>;
begin
  SetLength(result, 4);
  result[0] := #$2801;
  result[1] := #$2802;
  result[2] := #$2804;
  result[3] := #$2802;
end;

function Frames_BouncingBall : TArray<string>;
begin
  SetLength(result, 10);
  result[0] := '( ' + #$25CF + '    )';
  result[1] := '(  ' + #$25CF + '   )';
  result[2] := '(   ' + #$25CF + '  )';
  result[3] := '(    ' + #$25CF + ' )';
  result[4] := '(     ' + #$25CF + ')';
  result[5] := '(    ' + #$25CF + ' )';
  result[6] := '(   ' + #$25CF + '  )';
  result[7] := '(  ' + #$25CF + '   )';
  result[8] := '( ' + #$25CF + '    )';
  result[9] := '(' + #$25CF + '     )';
end;

function Frames_BouncingBar : TArray<string>;
begin
  SetLength(result, 16);
  result[0] := '[    ]';
  result[1] := '[=   ]';
  result[2] := '[==  ]';
  result[3] := '[=== ]';
  result[4] := '[====]';
  result[5] := '[ ===]';
  result[6] := '[  ==]';
  result[7] := '[   =]';
  result[8] := '[    ]';
  result[9] := '[   =]';
  result[10] := '[  ==]';
  result[11] := '[ ===]';
  result[12] := '[====]';
  result[13] := '[=== ]';
  result[14] := '[==  ]';
  result[15] := '[=   ]';
end;

function Frames_BoxBounce : TArray<string>;
begin
  SetLength(result, 4);
  result[0] := #$2596;
  result[1] := #$2598;
  result[2] := #$259D;
  result[3] := #$2597;
end;

function Frames_BoxBounce2 : TArray<string>;
begin
  SetLength(result, 4);
  result[0] := #$258C;
  result[1] := #$2580;
  result[2] := #$2590;
  result[3] := #$2584;
end;

function Frames_Christmas : TArray<string>;
begin
  SetLength(result, 2);
  result[0] := #$D83C#$DF32;
  result[1] := #$D83C#$DF84;
end;

function Frames_Circle : TArray<string>;
begin
  SetLength(result, 3);
  result[0] := #$25E1;
  result[1] := #$2299;
  result[2] := #$25E0;
end;

function Frames_CircleHalves : TArray<string>;
begin
  SetLength(result, 4);
  result[0] := #$25D0;
  result[1] := #$25D3;
  result[2] := #$25D1;
  result[3] := #$25D2;
end;

function Frames_CircleQuarters : TArray<string>;
begin
  SetLength(result, 4);
  result[0] := #$25F4;
  result[1] := #$25F7;
  result[2] := #$25F6;
  result[3] := #$25F5;
end;

function Frames_Clock : TArray<string>;
begin
  SetLength(result, 12);
  result[0] := #$D83D#$DD5B + ' ';
  result[1] := #$D83D#$DD50 + ' ';
  result[2] := #$D83D#$DD51 + ' ';
  result[3] := #$D83D#$DD52 + ' ';
  result[4] := #$D83D#$DD53 + ' ';
  result[5] := #$D83D#$DD54 + ' ';
  result[6] := #$D83D#$DD55 + ' ';
  result[7] := #$D83D#$DD56 + ' ';
  result[8] := #$D83D#$DD57 + ' ';
  result[9] := #$D83D#$DD58 + ' ';
  result[10] := #$D83D#$DD59 + ' ';
  result[11] := #$D83D#$DD5A + ' ';
end;

function Frames_Default : TArray<string>;
begin
  SetLength(result, 8);
  result[0] := #$28F7;
  result[1] := #$28EF;
  result[2] := #$28DF;
  result[3] := #$287F;
  result[4] := #$28BF;
  result[5] := #$28FB;
  result[6] := #$28FD;
  result[7] := #$28FE;
end;

function Frames_Dots10 : TArray<string>;
begin
  SetLength(result, 7);
  result[0] := #$2884;
  result[1] := #$2882;
  result[2] := #$2881;
  result[3] := #$2841;
  result[4] := #$2848;
  result[5] := #$2850;
  result[6] := #$2860;
end;

function Frames_Dots11 : TArray<string>;
begin
  SetLength(result, 8);
  result[0] := #$2801;
  result[1] := #$2802;
  result[2] := #$2804;
  result[3] := #$2840;
  result[4] := #$2880;
  result[5] := #$2820;
  result[6] := #$2810;
  result[7] := #$2808;
end;

function Frames_Dots12 : TArray<string>;
begin
  SetLength(result, 56);
  result[0] := #$2880 + #$2800;
  result[1] := #$2840 + #$2800;
  result[2] := #$2804 + #$2800;
  result[3] := #$2882 + #$2800;
  result[4] := #$2842 + #$2800;
  result[5] := #$2805 + #$2800;
  result[6] := #$2883 + #$2800;
  result[7] := #$2843 + #$2800;
  result[8] := #$280D + #$2800;
  result[9] := #$288B + #$2800;
  result[10] := #$284B + #$2800;
  result[11] := #$280D + #$2801;
  result[12] := #$288B + #$2801;
  result[13] := #$284B + #$2801;
  result[14] := #$280D + #$2809;
  result[15] := #$280B + #$2809;
  result[16] := #$280B + #$2809;
  result[17] := #$2809 + #$2819;
  result[18] := #$2809 + #$2819;
  result[19] := #$2809 + #$2829;
  result[20] := #$2808 + #$2899;
  result[21] := #$2808 + #$2859;
  result[22] := #$2888 + #$2829;
  result[23] := #$2840 + #$2899;
  result[24] := #$2804 + #$2859;
  result[25] := #$2882 + #$2829;
  result[26] := #$2842 + #$2898;
  result[27] := #$2805 + #$2858;
  result[28] := #$2883 + #$2828;
  result[29] := #$2843 + #$2890;
  result[30] := #$280D + #$2850;
  result[31] := #$288B + #$2820;
  result[32] := #$284B + #$2880;
  result[33] := #$280D + #$2841;
  result[34] := #$288B + #$2801;
  result[35] := #$284B + #$2801;
  result[36] := #$280D + #$2809;
  result[37] := #$280B + #$2809;
  result[38] := #$280B + #$2809;
  result[39] := #$2809 + #$2819;
  result[40] := #$2809 + #$2819;
  result[41] := #$2809 + #$2829;
  result[42] := #$2808 + #$2899;
  result[43] := #$2808 + #$2859;
  result[44] := #$2808 + #$2829;
  result[45] := #$2800 + #$2899;
  result[46] := #$2800 + #$2859;
  result[47] := #$2800 + #$2829;
  result[48] := #$2800 + #$2898;
  result[49] := #$2800 + #$2858;
  result[50] := #$2800 + #$2828;
  result[51] := #$2800 + #$2890;
  result[52] := #$2800 + #$2850;
  result[53] := #$2800 + #$2820;
  result[54] := #$2800 + #$2880;
  result[55] := #$2800 + #$2840;
end;

function Frames_Dots13 : TArray<string>;
begin
  SetLength(result, 8);
  result[0] := #$28FC;
  result[1] := #$28F9;
  result[2] := #$28BB;
  result[3] := #$283F;
  result[4] := #$285F;
  result[5] := #$28CF;
  result[6] := #$28E7;
  result[7] := #$28F6;
end;

function Frames_Dots14 : TArray<string>;
begin
  SetLength(result, 12);
  result[0] := #$2809 + #$2809;
  result[1] := #$2808 + #$2819;
  result[2] := #$2800 + #$2839;
  result[3] := #$2800 + #$28B8;
  result[4] := #$2800 + #$28F0;
  result[5] := #$2880 + #$28E0;
  result[6] := #$28C0 + #$28C0;
  result[7] := #$28C4 + #$2840;
  result[8] := #$28C6 + #$2800;
  result[9] := #$2847 + #$2800;
  result[10] := #$280F + #$2800;
  result[11] := #$280B + #$2801;
end;

function Frames_Dots3 : TArray<string>;
begin
  SetLength(result, 10);
  result[0] := #$280B;
  result[1] := #$2819;
  result[2] := #$281A;
  result[3] := #$281E;
  result[4] := #$2816;
  result[5] := #$2826;
  result[6] := #$2834;
  result[7] := #$2832;
  result[8] := #$2833;
  result[9] := #$2813;
end;

function Frames_Dots4 : TArray<string>;
begin
  SetLength(result, 14);
  result[0] := #$2804;
  result[1] := #$2806;
  result[2] := #$2807;
  result[3] := #$280B;
  result[4] := #$2819;
  result[5] := #$2838;
  result[6] := #$2830;
  result[7] := #$2820;
  result[8] := #$2830;
  result[9] := #$2838;
  result[10] := #$2819;
  result[11] := #$280B;
  result[12] := #$2807;
  result[13] := #$2806;
end;

function Frames_Dots5 : TArray<string>;
begin
  SetLength(result, 17);
  result[0] := #$280B;
  result[1] := #$2819;
  result[2] := #$281A;
  result[3] := #$2812;
  result[4] := #$2802;
  result[5] := #$2802;
  result[6] := #$2812;
  result[7] := #$2832;
  result[8] := #$2834;
  result[9] := #$2826;
  result[10] := #$2816;
  result[11] := #$2812;
  result[12] := #$2810;
  result[13] := #$2810;
  result[14] := #$2812;
  result[15] := #$2813;
  result[16] := #$280B;
end;

function Frames_Dots6 : TArray<string>;
begin
  SetLength(result, 24);
  result[0] := #$2801;
  result[1] := #$2809;
  result[2] := #$2819;
  result[3] := #$281A;
  result[4] := #$2812;
  result[5] := #$2802;
  result[6] := #$2802;
  result[7] := #$2812;
  result[8] := #$2832;
  result[9] := #$2834;
  result[10] := #$2824;
  result[11] := #$2804;
  result[12] := #$2804;
  result[13] := #$2824;
  result[14] := #$2834;
  result[15] := #$2832;
  result[16] := #$2812;
  result[17] := #$2802;
  result[18] := #$2802;
  result[19] := #$2812;
  result[20] := #$281A;
  result[21] := #$2819;
  result[22] := #$2809;
  result[23] := #$2801;
end;

function Frames_Dots7 : TArray<string>;
begin
  SetLength(result, 24);
  result[0] := #$2808;
  result[1] := #$2809;
  result[2] := #$280B;
  result[3] := #$2813;
  result[4] := #$2812;
  result[5] := #$2810;
  result[6] := #$2810;
  result[7] := #$2812;
  result[8] := #$2816;
  result[9] := #$2826;
  result[10] := #$2824;
  result[11] := #$2820;
  result[12] := #$2820;
  result[13] := #$2824;
  result[14] := #$2826;
  result[15] := #$2816;
  result[16] := #$2812;
  result[17] := #$2810;
  result[18] := #$2810;
  result[19] := #$2812;
  result[20] := #$2813;
  result[21] := #$280B;
  result[22] := #$2809;
  result[23] := #$2808;
end;

function Frames_Dots8 : TArray<string>;
begin
  SetLength(result, 29);
  result[0] := #$2801;
  result[1] := #$2801;
  result[2] := #$2809;
  result[3] := #$2819;
  result[4] := #$281A;
  result[5] := #$2812;
  result[6] := #$2802;
  result[7] := #$2802;
  result[8] := #$2812;
  result[9] := #$2832;
  result[10] := #$2834;
  result[11] := #$2824;
  result[12] := #$2804;
  result[13] := #$2804;
  result[14] := #$2824;
  result[15] := #$2820;
  result[16] := #$2820;
  result[17] := #$2824;
  result[18] := #$2826;
  result[19] := #$2816;
  result[20] := #$2812;
  result[21] := #$2810;
  result[22] := #$2810;
  result[23] := #$2812;
  result[24] := #$2813;
  result[25] := #$280B;
  result[26] := #$2809;
  result[27] := #$2808;
  result[28] := #$2808;
end;

function Frames_Dots8Bit : TArray<string>;
begin
  SetLength(result, 256);
  result[0] := #$2800;
  result[1] := #$2801;
  result[2] := #$2802;
  result[3] := #$2803;
  result[4] := #$2804;
  result[5] := #$2805;
  result[6] := #$2806;
  result[7] := #$2807;
  result[8] := #$2840;
  result[9] := #$2841;
  result[10] := #$2842;
  result[11] := #$2843;
  result[12] := #$2844;
  result[13] := #$2845;
  result[14] := #$2846;
  result[15] := #$2847;
  result[16] := #$2808;
  result[17] := #$2809;
  result[18] := #$280A;
  result[19] := #$280B;
  result[20] := #$280C;
  result[21] := #$280D;
  result[22] := #$280E;
  result[23] := #$280F;
  result[24] := #$2848;
  result[25] := #$2849;
  result[26] := #$284A;
  result[27] := #$284B;
  result[28] := #$284C;
  result[29] := #$284D;
  result[30] := #$284E;
  result[31] := #$284F;
  result[32] := #$2810;
  result[33] := #$2811;
  result[34] := #$2812;
  result[35] := #$2813;
  result[36] := #$2814;
  result[37] := #$2815;
  result[38] := #$2816;
  result[39] := #$2817;
  result[40] := #$2850;
  result[41] := #$2851;
  result[42] := #$2852;
  result[43] := #$2853;
  result[44] := #$2854;
  result[45] := #$2855;
  result[46] := #$2856;
  result[47] := #$2857;
  result[48] := #$2818;
  result[49] := #$2819;
  result[50] := #$281A;
  result[51] := #$281B;
  result[52] := #$281C;
  result[53] := #$281D;
  result[54] := #$281E;
  result[55] := #$281F;
  result[56] := #$2858;
  result[57] := #$2859;
  result[58] := #$285A;
  result[59] := #$285B;
  result[60] := #$285C;
  result[61] := #$285D;
  result[62] := #$285E;
  result[63] := #$285F;
  result[64] := #$2820;
  result[65] := #$2821;
  result[66] := #$2822;
  result[67] := #$2823;
  result[68] := #$2824;
  result[69] := #$2825;
  result[70] := #$2826;
  result[71] := #$2827;
  result[72] := #$2860;
  result[73] := #$2861;
  result[74] := #$2862;
  result[75] := #$2863;
  result[76] := #$2864;
  result[77] := #$2865;
  result[78] := #$2866;
  result[79] := #$2867;
  result[80] := #$2828;
  result[81] := #$2829;
  result[82] := #$282A;
  result[83] := #$282B;
  result[84] := #$282C;
  result[85] := #$282D;
  result[86] := #$282E;
  result[87] := #$282F;
  result[88] := #$2868;
  result[89] := #$2869;
  result[90] := #$286A;
  result[91] := #$286B;
  result[92] := #$286C;
  result[93] := #$286D;
  result[94] := #$286E;
  result[95] := #$286F;
  result[96] := #$2830;
  result[97] := #$2831;
  result[98] := #$2832;
  result[99] := #$2833;
  result[100] := #$2834;
  result[101] := #$2835;
  result[102] := #$2836;
  result[103] := #$2837;
  result[104] := #$2870;
  result[105] := #$2871;
  result[106] := #$2872;
  result[107] := #$2873;
  result[108] := #$2874;
  result[109] := #$2875;
  result[110] := #$2876;
  result[111] := #$2877;
  result[112] := #$2838;
  result[113] := #$2839;
  result[114] := #$283A;
  result[115] := #$283B;
  result[116] := #$283C;
  result[117] := #$283D;
  result[118] := #$283E;
  result[119] := #$283F;
  result[120] := #$2878;
  result[121] := #$2879;
  result[122] := #$287A;
  result[123] := #$287B;
  result[124] := #$287C;
  result[125] := #$287D;
  result[126] := #$287E;
  result[127] := #$287F;
  result[128] := #$2880;
  result[129] := #$2881;
  result[130] := #$2882;
  result[131] := #$2883;
  result[132] := #$2884;
  result[133] := #$2885;
  result[134] := #$2886;
  result[135] := #$2887;
  result[136] := #$28C0;
  result[137] := #$28C1;
  result[138] := #$28C2;
  result[139] := #$28C3;
  result[140] := #$28C4;
  result[141] := #$28C5;
  result[142] := #$28C6;
  result[143] := #$28C7;
  result[144] := #$2888;
  result[145] := #$2889;
  result[146] := #$288A;
  result[147] := #$288B;
  result[148] := #$288C;
  result[149] := #$288D;
  result[150] := #$288E;
  result[151] := #$288F;
  result[152] := #$28C8;
  result[153] := #$28C9;
  result[154] := #$28CA;
  result[155] := #$28CB;
  result[156] := #$28CC;
  result[157] := #$28CD;
  result[158] := #$28CE;
  result[159] := #$28CF;
  result[160] := #$2890;
  result[161] := #$2891;
  result[162] := #$2892;
  result[163] := #$2893;
  result[164] := #$2894;
  result[165] := #$2895;
  result[166] := #$2896;
  result[167] := #$2897;
  result[168] := #$28D0;
  result[169] := #$28D1;
  result[170] := #$28D2;
  result[171] := #$28D3;
  result[172] := #$28D4;
  result[173] := #$28D5;
  result[174] := #$28D6;
  result[175] := #$28D7;
  result[176] := #$2898;
  result[177] := #$2899;
  result[178] := #$289A;
  result[179] := #$289B;
  result[180] := #$289C;
  result[181] := #$289D;
  result[182] := #$289E;
  result[183] := #$289F;
  result[184] := #$28D8;
  result[185] := #$28D9;
  result[186] := #$28DA;
  result[187] := #$28DB;
  result[188] := #$28DC;
  result[189] := #$28DD;
  result[190] := #$28DE;
  result[191] := #$28DF;
  result[192] := #$28A0;
  result[193] := #$28A1;
  result[194] := #$28A2;
  result[195] := #$28A3;
  result[196] := #$28A4;
  result[197] := #$28A5;
  result[198] := #$28A6;
  result[199] := #$28A7;
  result[200] := #$28E0;
  result[201] := #$28E1;
  result[202] := #$28E2;
  result[203] := #$28E3;
  result[204] := #$28E4;
  result[205] := #$28E5;
  result[206] := #$28E6;
  result[207] := #$28E7;
  result[208] := #$28A8;
  result[209] := #$28A9;
  result[210] := #$28AA;
  result[211] := #$28AB;
  result[212] := #$28AC;
  result[213] := #$28AD;
  result[214] := #$28AE;
  result[215] := #$28AF;
  result[216] := #$28E8;
  result[217] := #$28E9;
  result[218] := #$28EA;
  result[219] := #$28EB;
  result[220] := #$28EC;
  result[221] := #$28ED;
  result[222] := #$28EE;
  result[223] := #$28EF;
  result[224] := #$28B0;
  result[225] := #$28B1;
  result[226] := #$28B2;
  result[227] := #$28B3;
  result[228] := #$28B4;
  result[229] := #$28B5;
  result[230] := #$28B6;
  result[231] := #$28B7;
  result[232] := #$28F0;
  result[233] := #$28F1;
  result[234] := #$28F2;
  result[235] := #$28F3;
  result[236] := #$28F4;
  result[237] := #$28F5;
  result[238] := #$28F6;
  result[239] := #$28F7;
  result[240] := #$28B8;
  result[241] := #$28B9;
  result[242] := #$28BA;
  result[243] := #$28BB;
  result[244] := #$28BC;
  result[245] := #$28BD;
  result[246] := #$28BE;
  result[247] := #$28BF;
  result[248] := #$28F8;
  result[249] := #$28F9;
  result[250] := #$28FA;
  result[251] := #$28FB;
  result[252] := #$28FC;
  result[253] := #$28FD;
  result[254] := #$28FE;
  result[255] := #$28FF;
end;

function Frames_Dots9 : TArray<string>;
begin
  SetLength(result, 8);
  result[0] := #$28B9;
  result[1] := #$28BA;
  result[2] := #$28BC;
  result[3] := #$28F8;
  result[4] := #$28C7;
  result[5] := #$2867;
  result[6] := #$2857;
  result[7] := #$284F;
end;

function Frames_DotsCircle : TArray<string>;
begin
  SetLength(result, 8);
  result[0] := #$288E + ' ';
  result[1] := #$280E + #$2801;
  result[2] := #$280A + #$2811;
  result[3] := #$2808 + #$2831;
  result[4] := ' ' + #$2871;
  result[5] := #$2880 + #$2870;
  result[6] := #$2884 + #$2860;
  result[7] := #$2886 + #$2840;
end;

function Frames_Dqpb : TArray<string>;
begin
  SetLength(result, 4);
  result[0] := 'd';
  result[1] := 'q';
  result[2] := 'p';
  result[3] := 'b';
end;

function Frames_DwarfFortress : TArray<string>;
begin
  SetLength(result, 133);
  result[0] := ' ' + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[1] := #$263A + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[2] := #$263A + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[3] := #$263A + #$2593 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[4] := #$263A + #$2593 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[5] := #$263A + #$2592 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[6] := #$263A + #$2592 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[7] := #$263A + #$2591 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[8] := #$263A + #$2591 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[9] := #$263A + ' ' + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[10] := ' ' + #$263A + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[11] := ' ' + #$263A + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[12] := ' ' + #$263A + #$2593 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[13] := ' ' + #$263A + #$2593 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[14] := ' ' + #$263A + #$2592 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[15] := ' ' + #$263A + #$2592 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[16] := ' ' + #$263A + #$2591 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[17] := ' ' + #$263A + #$2591 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[18] := ' ' + #$263A + ' ' + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[19] := '  ' + #$263A + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[20] := '  ' + #$263A + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[21] := '  ' + #$263A + #$2593 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[22] := '  ' + #$263A + #$2593 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[23] := '  ' + #$263A + #$2592 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[24] := '  ' + #$263A + #$2592 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[25] := '  ' + #$263A + #$2591 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[26] := '  ' + #$263A + #$2591 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[27] := '  ' + #$263A + ' ' + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[28] := '   ' + #$263A + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[29] := '   ' + #$263A + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[30] := '   ' + #$263A + #$2593 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[31] := '   ' + #$263A + #$2593 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[32] := '   ' + #$263A + #$2592 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[33] := '   ' + #$263A + #$2592 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[34] := '   ' + #$263A + #$2591 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[35] := '   ' + #$263A + #$2591 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[36] := '   ' + #$263A + ' ' + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[37] := '    ' + #$263A + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[38] := '    ' + #$263A + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[39] := '    ' + #$263A + #$2593 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[40] := '    ' + #$263A + #$2593 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[41] := '    ' + #$263A + #$2592 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[42] := '    ' + #$263A + #$2592 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[43] := '    ' + #$263A + #$2591 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[44] := '    ' + #$263A + #$2591 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[45] := '    ' + #$263A + ' ' + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[46] := '     ' + #$263A + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[47] := '     ' + #$263A + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[48] := '     ' + #$263A + #$2593 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[49] := '     ' + #$263A + #$2593 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[50] := '     ' + #$263A + #$2592 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[51] := '     ' + #$263A + #$2592 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[52] := '     ' + #$263A + #$2591 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[53] := '     ' + #$263A + #$2591 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[54] := '     ' + #$263A + ' ' + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[55] := '      ' + #$263A + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[56] := '      ' + #$263A + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[57] := '      ' + #$263A + #$2593 + #$00A3 + #$00A3 + '  ';
  result[58] := '      ' + #$263A + #$2593 + #$00A3 + #$00A3 + '  ';
  result[59] := '      ' + #$263A + #$2592 + #$00A3 + #$00A3 + '  ';
  result[60] := '      ' + #$263A + #$2592 + #$00A3 + #$00A3 + '  ';
  result[61] := '      ' + #$263A + #$2591 + #$00A3 + #$00A3 + '  ';
  result[62] := '      ' + #$263A + #$2591 + #$00A3 + #$00A3 + '  ';
  result[63] := '      ' + #$263A + ' ' + #$00A3 + #$00A3 + '  ';
  result[64] := '       ' + #$263A + #$00A3 + #$00A3 + '  ';
  result[65] := '       ' + #$263A + #$00A3 + #$00A3 + '  ';
  result[66] := '       ' + #$263A + #$2593 + #$00A3 + '  ';
  result[67] := '       ' + #$263A + #$2593 + #$00A3 + '  ';
  result[68] := '       ' + #$263A + #$2592 + #$00A3 + '  ';
  result[69] := '       ' + #$263A + #$2592 + #$00A3 + '  ';
  result[70] := '       ' + #$263A + #$2591 + #$00A3 + '  ';
  result[71] := '       ' + #$263A + #$2591 + #$00A3 + '  ';
  result[72] := '       ' + #$263A + ' ' + #$00A3 + '  ';
  result[73] := '        ' + #$263A + #$00A3 + '  ';
  result[74] := '        ' + #$263A + #$00A3 + '  ';
  result[75] := '        ' + #$263A + #$2593 + '  ';
  result[76] := '        ' + #$263A + #$2593 + '  ';
  result[77] := '        ' + #$263A + #$2592 + '  ';
  result[78] := '        ' + #$263A + #$2592 + '  ';
  result[79] := '        ' + #$263A + #$2591 + '  ';
  result[80] := '        ' + #$263A + #$2591 + '  ';
  result[81] := '        ' + #$263A + '   ';
  result[82] := '        ' + #$263A + '  &';
  result[83] := '        ' + #$263A + ' ' + #$263C + '&';
  result[84] := '       ' + #$263A + ' ' + #$263C + ' &';
  result[85] := '       ' + #$263A + #$263C + '  &';
  result[86] := '      ' + #$263A + #$263C + '  & ';
  result[87] := '      ' + #$203C + '   & ';
  result[88] := '     ' + #$263A + '   &  ';
  result[89] := '    ' + #$203C + '    &  ';
  result[90] := '   ' + #$263A + '    &   ';
  result[91] := '  ' + #$203C + '     &   ';
  result[92] := ' ' + #$263A + '     &    ';
  result[93] := #$203C + '      &    ';
  result[94] := '      &     ';
  result[95] := '      &     ';
  result[96] := '     &   ' + #$2591 + '  ';
  result[97] := '     &   ' + #$2592 + '  ';
  result[98] := '    &    ' + #$2593 + '  ';
  result[99] := '    &    ' + #$00A3 + '  ';
  result[100] := '   &    ' + #$2591 + #$00A3 + '  ';
  result[101] := '   &    ' + #$2592 + #$00A3 + '  ';
  result[102] := '  &     ' + #$2593 + #$00A3 + '  ';
  result[103] := '  &     ' + #$00A3 + #$00A3 + '  ';
  result[104] := ' &     ' + #$2591 + #$00A3 + #$00A3 + '  ';
  result[105] := ' &     ' + #$2592 + #$00A3 + #$00A3 + '  ';
  result[106] := '&      ' + #$2593 + #$00A3 + #$00A3 + '  ';
  result[107] := '&      ' + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[108] := '      ' + #$2591 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[109] := '      ' + #$2592 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[110] := '      ' + #$2593 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[111] := '      ' + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[112] := '     ' + #$2591 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[113] := '     ' + #$2592 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[114] := '     ' + #$2593 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[115] := '     ' + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[116] := '    ' + #$2591 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[117] := '    ' + #$2592 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[118] := '    ' + #$2593 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[119] := '    ' + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[120] := '   ' + #$2591 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[121] := '   ' + #$2592 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[122] := '   ' + #$2593 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[123] := '   ' + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[124] := '  ' + #$2591 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[125] := '  ' + #$2592 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[126] := '  ' + #$2593 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[127] := '  ' + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[128] := ' ' + #$2591 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[129] := ' ' + #$2592 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[130] := ' ' + #$2593 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[131] := ' ' + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
  result[132] := ' ' + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$00A3 + #$00A3 + #$00A3 + '  ';
end;

function Frames_Earth : TArray<string>;
begin
  SetLength(result, 3);
  result[0] := #$D83C#$DF0D + ' ';
  result[1] := #$D83C#$DF0E + ' ';
  result[2] := #$D83C#$DF0F + ' ';
end;

function Frames_FingerDance : TArray<string>;
begin
  SetLength(result, 6);
  result[0] := #$D83E#$DD18 + ' ';
  result[1] := #$D83E#$DD1F + ' ';
  result[2] := #$D83D#$DD96 + ' ';
  result[3] := #$270B + ' ';
  result[4] := #$D83E#$DD1A + ' ';
  result[5] := #$D83D#$DC46 + ' ';
end;

function Frames_FistBump : TArray<string>;
begin
  SetLength(result, 7);
  result[0] := #$D83E#$DD1C + #$3000 + #$3000 + #$3000 + #$3000 + #$D83E#$DD1B + ' ';
  result[1] := #$D83E#$DD1C + #$3000 + #$3000 + #$3000 + #$3000 + #$D83E#$DD1B + ' ';
  result[2] := #$D83E#$DD1C + #$3000 + #$3000 + #$3000 + #$3000 + #$D83E#$DD1B + ' ';
  result[3] := #$3000 + #$D83E#$DD1C + #$3000 + #$3000 + #$D83E#$DD1B + #$3000 + ' ';
  result[4] := #$3000 + #$3000 + #$D83E#$DD1C + #$D83E#$DD1B + #$3000 + #$3000 + ' ';
  result[5] := #$3000 + #$D83E#$DD1C + #$2728 + #$D83E#$DD1B + #$3000 + #$3000 + ' ';
  result[6] := #$D83E#$DD1C + #$3000 + #$2728 + #$3000 + #$D83E#$DD1B + #$3000 + ' ';
end;

function Frames_Flip : TArray<string>;
begin
  SetLength(result, 12);
  result[0] := '_';
  result[1] := '_';
  result[2] := '_';
  result[3] := '-';
  result[4] := '`';
  result[5] := '`';
  result[6] := '''';
  result[7] := #$00B4;
  result[8] := '-';
  result[9] := '_';
  result[10] := '_';
  result[11] := '_';
end;

function Frames_Grenade : TArray<string>;
begin
  SetLength(result, 14);
  result[0] := #$060C + '  ';
  result[1] := #$2032 + '  ';
  result[2] := ' ' + #$00B4 + ' ';
  result[3] := ' ' + #$203E + ' ';
  result[4] := '  ' + #$2E0C;
  result[5] := '  ' + #$2E0A;
  result[6] := '  |';
  result[7] := '  ' + #$204E;
  result[8] := '  ' + #$2055;
  result[9] := ' ' + #$0DF4 + ' ';
  result[10] := '  ' + #$2053;
  result[11] := '   ';
  result[12] := '   ';
  result[13] := '   ';
end;

function Frames_GrowHorizontal : TArray<string>;
begin
  SetLength(result, 12);
  result[0] := #$258F;
  result[1] := #$258E;
  result[2] := #$258D;
  result[3] := #$258C;
  result[4] := #$258B;
  result[5] := #$258A;
  result[6] := #$2589;
  result[7] := #$258A;
  result[8] := #$258B;
  result[9] := #$258C;
  result[10] := #$258D;
  result[11] := #$258E;
end;

function Frames_GrowVertical : TArray<string>;
begin
  SetLength(result, 10);
  result[0] := #$2581;
  result[1] := #$2583;
  result[2] := #$2584;
  result[3] := #$2585;
  result[4] := #$2586;
  result[5] := #$2587;
  result[6] := #$2586;
  result[7] := #$2585;
  result[8] := #$2584;
  result[9] := #$2583;
end;

function Frames_Hamburger : TArray<string>;
begin
  SetLength(result, 3);
  result[0] := #$2631;
  result[1] := #$2632;
  result[2] := #$2634;
end;

function Frames_Hearts : TArray<string>;
begin
  SetLength(result, 5);
  result[0] := #$D83D#$DC9B + ' ';
  result[1] := #$D83D#$DC99 + ' ';
  result[2] := #$D83D#$DC9C + ' ';
  result[3] := #$D83D#$DC9A + ' ';
  result[4] := #$2764 + #$FE0F + ' ';
end;

function Frames_Layer : TArray<string>;
begin
  SetLength(result, 3);
  result[0] := '-';
  result[1] := '=';
  result[2] := #$2261;
end;

function Frames_Line2 : TArray<string>;
begin
  SetLength(result, 6);
  result[0] := #$2802;
  result[1] := '-';
  result[2] := #$2013;
  result[3] := #$2014;
  result[4] := #$2013;
  result[5] := '-';
end;

function Frames_Material : TArray<string>;
begin
  SetLength(result, 92);
  result[0] := #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[1] := #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[2] := #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[3] := #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[4] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[5] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[6] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[7] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[8] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[9] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[10] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[11] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[12] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[13] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[14] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[15] := #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[16] := #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[17] := #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[18] := #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581;
  result[19] := #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581;
  result[20] := #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581;
  result[21] := #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581;
  result[22] := #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581;
  result[23] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581;
  result[24] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581;
  result[25] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581;
  result[26] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[27] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[28] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[29] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[30] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[31] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[32] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[33] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[34] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[35] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[36] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[37] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[38] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[39] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[40] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[41] := #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588;
  result[42] := #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588;
  result[43] := #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588;
  result[44] := #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588;
  result[45] := #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588;
  result[46] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588;
  result[47] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588;
  result[48] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588;
  result[49] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[50] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[51] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[52] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[53] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[54] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[55] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[56] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[57] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[58] := #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[59] := #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[60] := #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[61] := #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581 + #$2581;
  result[62] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581;
  result[63] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581;
  result[64] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581;
  result[65] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581;
  result[66] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581 + #$2581;
  result[67] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581;
  result[68] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581 + #$2581;
  result[69] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581;
  result[70] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581;
  result[71] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581;
  result[72] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581;
  result[73] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2581;
  result[74] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[75] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[76] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588 + #$2588;
  result[77] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588;
  result[78] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588;
  result[79] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588 + #$2588;
  result[80] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588;
  result[81] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588 + #$2588;
  result[82] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588;
  result[83] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588;
  result[84] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588 + #$2588;
  result[85] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588;
  result[86] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588;
  result[87] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2588;
  result[88] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[89] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[90] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
  result[91] := #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581 + #$2581;
end;

function Frames_Mindblown : TArray<string>;
begin
  SetLength(result, 14);
  result[0] := #$D83D#$DE10 + ' ';
  result[1] := #$D83D#$DE10 + ' ';
  result[2] := #$D83D#$DE2E + ' ';
  result[3] := #$D83D#$DE2E + ' ';
  result[4] := #$D83D#$DE26 + ' ';
  result[5] := #$D83D#$DE26 + ' ';
  result[6] := #$D83D#$DE27 + ' ';
  result[7] := #$D83D#$DE27 + ' ';
  result[8] := #$D83E#$DD2F + ' ';
  result[9] := #$D83D#$DCA5 + ' ';
  result[10] := #$2728 + ' ';
  result[11] := #$3000 + ' ';
  result[12] := #$3000 + ' ';
  result[13] := #$3000 + ' ';
end;

function Frames_Monkey : TArray<string>;
begin
  SetLength(result, 4);
  result[0] := #$D83D#$DE48 + ' ';
  result[1] := #$D83D#$DE48 + ' ';
  result[2] := #$D83D#$DE49 + ' ';
  result[3] := #$D83D#$DE4A + ' ';
end;

function Frames_Moon : TArray<string>;
begin
  SetLength(result, 8);
  result[0] := #$D83C#$DF11 + ' ';
  result[1] := #$D83C#$DF12 + ' ';
  result[2] := #$D83C#$DF13 + ' ';
  result[3] := #$D83C#$DF14 + ' ';
  result[4] := #$D83C#$DF15 + ' ';
  result[5] := #$D83C#$DF16 + ' ';
  result[6] := #$D83C#$DF17 + ' ';
  result[7] := #$D83C#$DF18 + ' ';
end;

function Frames_Noise : TArray<string>;
begin
  SetLength(result, 3);
  result[0] := #$2593;
  result[1] := #$2592;
  result[2] := #$2591;
end;

function Frames_OrangeBluePulse : TArray<string>;
begin
  SetLength(result, 10);
  result[0] := #$D83D#$DD38 + ' ';
  result[1] := #$D83D#$DD36 + ' ';
  result[2] := #$D83D#$DFE0 + ' ';
  result[3] := #$D83D#$DFE0 + ' ';
  result[4] := #$D83D#$DD36 + ' ';
  result[5] := #$D83D#$DD39 + ' ';
  result[6] := #$D83D#$DD37 + ' ';
  result[7] := #$D83D#$DD35 + ' ';
  result[8] := #$D83D#$DD35 + ' ';
  result[9] := #$D83D#$DD37 + ' ';
end;

function Frames_OrangePulse : TArray<string>;
begin
  SetLength(result, 5);
  result[0] := #$D83D#$DD38 + ' ';
  result[1] := #$D83D#$DD36 + ' ';
  result[2] := #$D83D#$DFE0 + ' ';
  result[3] := #$D83D#$DFE0 + ' ';
  result[4] := #$D83D#$DD36 + ' ';
end;

function Frames_Pipe : TArray<string>;
begin
  SetLength(result, 8);
  result[0] := #$2524;
  result[1] := #$2518;
  result[2] := #$2534;
  result[3] := #$2514;
  result[4] := #$251C;
  result[5] := #$250C;
  result[6] := #$252C;
  result[7] := #$2510;
end;

function Frames_Point : TArray<string>;
begin
  SetLength(result, 5);
  result[0] := #$2219 + #$2219 + #$2219;
  result[1] := #$25CF + #$2219 + #$2219;
  result[2] := #$2219 + #$25CF + #$2219;
  result[3] := #$2219 + #$2219 + #$25CF;
  result[4] := #$2219 + #$2219 + #$2219;
end;

function Frames_Pong : TArray<string>;
begin
  SetLength(result, 30);
  result[0] := #$2590 + #$2802 + '       ' + #$258C;
  result[1] := #$2590 + #$2808 + '       ' + #$258C;
  result[2] := #$2590 + ' ' + #$2802 + '      ' + #$258C;
  result[3] := #$2590 + ' ' + #$2820 + '      ' + #$258C;
  result[4] := #$2590 + '  ' + #$2840 + '     ' + #$258C;
  result[5] := #$2590 + '  ' + #$2820 + '     ' + #$258C;
  result[6] := #$2590 + '   ' + #$2802 + '    ' + #$258C;
  result[7] := #$2590 + '   ' + #$2808 + '    ' + #$258C;
  result[8] := #$2590 + '    ' + #$2802 + '   ' + #$258C;
  result[9] := #$2590 + '    ' + #$2820 + '   ' + #$258C;
  result[10] := #$2590 + '     ' + #$2840 + '  ' + #$258C;
  result[11] := #$2590 + '     ' + #$2820 + '  ' + #$258C;
  result[12] := #$2590 + '      ' + #$2802 + ' ' + #$258C;
  result[13] := #$2590 + '      ' + #$2808 + ' ' + #$258C;
  result[14] := #$2590 + '       ' + #$2802 + #$258C;
  result[15] := #$2590 + '       ' + #$2820 + #$258C;
  result[16] := #$2590 + '       ' + #$2840 + #$258C;
  result[17] := #$2590 + '      ' + #$2820 + ' ' + #$258C;
  result[18] := #$2590 + '      ' + #$2802 + ' ' + #$258C;
  result[19] := #$2590 + '     ' + #$2808 + '  ' + #$258C;
  result[20] := #$2590 + '     ' + #$2802 + '  ' + #$258C;
  result[21] := #$2590 + '    ' + #$2820 + '   ' + #$258C;
  result[22] := #$2590 + '    ' + #$2840 + '   ' + #$258C;
  result[23] := #$2590 + '   ' + #$2820 + '    ' + #$258C;
  result[24] := #$2590 + '   ' + #$2802 + '    ' + #$258C;
  result[25] := #$2590 + '  ' + #$2808 + '     ' + #$258C;
  result[26] := #$2590 + '  ' + #$2802 + '     ' + #$258C;
  result[27] := #$2590 + ' ' + #$2820 + '      ' + #$258C;
  result[28] := #$2590 + ' ' + #$2840 + '      ' + #$258C;
  result[29] := #$2590 + #$2820 + '       ' + #$258C;
end;

function Frames_Runner : TArray<string>;
begin
  SetLength(result, 2);
  result[0] := #$D83D#$DEB6 + ' ';
  result[1] := #$D83C#$DFC3 + ' ';
end;

function Frames_Sand : TArray<string>;
begin
  SetLength(result, 35);
  result[0] := #$2801;
  result[1] := #$2802;
  result[2] := #$2804;
  result[3] := #$2840;
  result[4] := #$2848;
  result[5] := #$2850;
  result[6] := #$2860;
  result[7] := #$28C0;
  result[8] := #$28C1;
  result[9] := #$28C2;
  result[10] := #$28C4;
  result[11] := #$28CC;
  result[12] := #$28D4;
  result[13] := #$28E4;
  result[14] := #$28E5;
  result[15] := #$28E6;
  result[16] := #$28EE;
  result[17] := #$28F6;
  result[18] := #$28F7;
  result[19] := #$28FF;
  result[20] := #$287F;
  result[21] := #$283F;
  result[22] := #$289F;
  result[23] := #$281F;
  result[24] := #$285B;
  result[25] := #$281B;
  result[26] := #$282B;
  result[27] := #$288B;
  result[28] := #$280B;
  result[29] := #$280D;
  result[30] := #$2849;
  result[31] := #$2809;
  result[32] := #$2811;
  result[33] := #$2821;
  result[34] := #$2881;
end;

function Frames_Shark : TArray<string>;
begin
  SetLength(result, 26);
  result[0] := #$2590 + '|\____________' + #$258C;
  result[1] := #$2590 + '_|\___________' + #$258C;
  result[2] := #$2590 + '__|\__________' + #$258C;
  result[3] := #$2590 + '___|\_________' + #$258C;
  result[4] := #$2590 + '____|\________' + #$258C;
  result[5] := #$2590 + '_____|\_______' + #$258C;
  result[6] := #$2590 + '______|\______' + #$258C;
  result[7] := #$2590 + '_______|\_____' + #$258C;
  result[8] := #$2590 + '________|\____' + #$258C;
  result[9] := #$2590 + '_________|\___' + #$258C;
  result[10] := #$2590 + '__________|\__' + #$258C;
  result[11] := #$2590 + '___________|\_' + #$258C;
  result[12] := #$2590 + '____________|\' + #$258C;
  result[13] := #$2590 + '____________/|' + #$258C;
  result[14] := #$2590 + '___________/|_' + #$258C;
  result[15] := #$2590 + '__________/|__' + #$258C;
  result[16] := #$2590 + '_________/|___' + #$258C;
  result[17] := #$2590 + '________/|____' + #$258C;
  result[18] := #$2590 + '_______/|_____' + #$258C;
  result[19] := #$2590 + '______/|______' + #$258C;
  result[20] := #$2590 + '_____/|_______' + #$258C;
  result[21] := #$2590 + '____/|________' + #$258C;
  result[22] := #$2590 + '___/|_________' + #$258C;
  result[23] := #$2590 + '__/|__________' + #$258C;
  result[24] := #$2590 + '_/|___________' + #$258C;
  result[25] := #$2590 + '/|____________' + #$258C;
end;

function Frames_SimpleDots : TArray<string>;
begin
  SetLength(result, 4);
  result[0] := '.  ';
  result[1] := '.. ';
  result[2] := '...';
  result[3] := '   ';
end;

function Frames_SimpleDotsScrolling : TArray<string>;
begin
  SetLength(result, 6);
  result[0] := '.  ';
  result[1] := '.. ';
  result[2] := '...';
  result[3] := ' ..';
  result[4] := '  .';
  result[5] := '   ';
end;

function Frames_Smiley : TArray<string>;
begin
  SetLength(result, 2);
  result[0] := #$D83D#$DE04 + ' ';
  result[1] := #$D83D#$DE1D + ' ';
end;

function Frames_SoccerHeader : TArray<string>;
begin
  SetLength(result, 12);
  result[0] := ' ' + #$D83E#$DDD1 + #$26BD + #$FE0F + '       ' + #$D83E#$DDD1 + ' ';
  result[1] := #$D83E#$DDD1 + '  ' + #$26BD + #$FE0F + '      ' + #$D83E#$DDD1 + ' ';
  result[2] := #$D83E#$DDD1 + '   ' + #$26BD + #$FE0F + '     ' + #$D83E#$DDD1 + ' ';
  result[3] := #$D83E#$DDD1 + '    ' + #$26BD + #$FE0F + '    ' + #$D83E#$DDD1 + ' ';
  result[4] := #$D83E#$DDD1 + '     ' + #$26BD + #$FE0F + '   ' + #$D83E#$DDD1 + ' ';
  result[5] := #$D83E#$DDD1 + '      ' + #$26BD + #$FE0F + '  ' + #$D83E#$DDD1 + ' ';
  result[6] := #$D83E#$DDD1 + '       ' + #$26BD + #$FE0F + #$D83E#$DDD1 + '  ';
  result[7] := #$D83E#$DDD1 + '      ' + #$26BD + #$FE0F + '  ' + #$D83E#$DDD1 + ' ';
  result[8] := #$D83E#$DDD1 + '     ' + #$26BD + #$FE0F + '   ' + #$D83E#$DDD1 + ' ';
  result[9] := #$D83E#$DDD1 + '    ' + #$26BD + #$FE0F + '    ' + #$D83E#$DDD1 + ' ';
  result[10] := #$D83E#$DDD1 + '   ' + #$26BD + #$FE0F + '     ' + #$D83E#$DDD1 + ' ';
  result[11] := #$D83E#$DDD1 + '  ' + #$26BD + #$FE0F + '      ' + #$D83E#$DDD1 + ' ';
end;

function Frames_Speaker : TArray<string>;
begin
  SetLength(result, 4);
  result[0] := #$D83D#$DD08 + ' ';
  result[1] := #$D83D#$DD09 + ' ';
  result[2] := #$D83D#$DD0A + ' ';
  result[3] := #$D83D#$DD09 + ' ';
end;

function Frames_SquareCorners : TArray<string>;
begin
  SetLength(result, 4);
  result[0] := #$25F0;
  result[1] := #$25F3;
  result[2] := #$25F2;
  result[3] := #$25F1;
end;

function Frames_Squish : TArray<string>;
begin
  SetLength(result, 2);
  result[0] := #$256B;
  result[1] := #$256A;
end;

function Frames_Star2 : TArray<string>;
begin
  SetLength(result, 3);
  result[0] := '+';
  result[1] := 'x';
  result[2] := '*';
end;

function Frames_TimeTravel : TArray<string>;
begin
  SetLength(result, 12);
  result[0] := #$D83D#$DD5B + ' ';
  result[1] := #$D83D#$DD5A + ' ';
  result[2] := #$D83D#$DD59 + ' ';
  result[3] := #$D83D#$DD58 + ' ';
  result[4] := #$D83D#$DD57 + ' ';
  result[5] := #$D83D#$DD56 + ' ';
  result[6] := #$D83D#$DD55 + ' ';
  result[7] := #$D83D#$DD54 + ' ';
  result[8] := #$D83D#$DD53 + ' ';
  result[9] := #$D83D#$DD52 + ' ';
  result[10] := #$D83D#$DD51 + ' ';
  result[11] := #$D83D#$DD50 + ' ';
end;

function Frames_Toggle : TArray<string>;
begin
  SetLength(result, 2);
  result[0] := #$22B6;
  result[1] := #$22B7;
end;

function Frames_Toggle10 : TArray<string>;
begin
  SetLength(result, 3);
  result[0] := #$3282;
  result[1] := #$3280;
  result[2] := #$3281;
end;

function Frames_Toggle11 : TArray<string>;
begin
  SetLength(result, 2);
  result[0] := #$29C7;
  result[1] := #$29C6;
end;

function Frames_Toggle12 : TArray<string>;
begin
  SetLength(result, 2);
  result[0] := #$2617;
  result[1] := #$2616;
end;

function Frames_Toggle13 : TArray<string>;
begin
  SetLength(result, 3);
  result[0] := '=';
  result[1] := '*';
  result[2] := '-';
end;

function Frames_Toggle2 : TArray<string>;
begin
  SetLength(result, 2);
  result[0] := #$25AB;
  result[1] := #$25AA;
end;

function Frames_Toggle3 : TArray<string>;
begin
  SetLength(result, 2);
  result[0] := #$25A1;
  result[1] := #$25A0;
end;

function Frames_Toggle4 : TArray<string>;
begin
  SetLength(result, 4);
  result[0] := #$25A0;
  result[1] := #$25A1;
  result[2] := #$25AA;
  result[3] := #$25AB;
end;

function Frames_Toggle5 : TArray<string>;
begin
  SetLength(result, 2);
  result[0] := #$25AE;
  result[1] := #$25AF;
end;

function Frames_Toggle6 : TArray<string>;
begin
  SetLength(result, 2);
  result[0] := #$101D;
  result[1] := #$1040;
end;

function Frames_Toggle7 : TArray<string>;
begin
  SetLength(result, 2);
  result[0] := #$29BE;
  result[1] := #$29BF;
end;

function Frames_Toggle8 : TArray<string>;
begin
  SetLength(result, 2);
  result[0] := #$25CD;
  result[1] := #$25CC;
end;

function Frames_Toggle9 : TArray<string>;
begin
  SetLength(result, 2);
  result[0] := #$25C9;
  result[1] := #$25CE;
end;

function Frames_Triangle : TArray<string>;
begin
  SetLength(result, 4);
  result[0] := #$25E2;
  result[1] := #$25E3;
  result[2] := #$25E4;
  result[3] := #$25E5;
end;

function Frames_Weather : TArray<string>;
begin
  SetLength(result, 23);
  result[0] := #$2600 + #$FE0F + ' ';
  result[1] := #$2600 + #$FE0F + ' ';
  result[2] := #$2600 + #$FE0F + ' ';
  result[3] := #$D83C#$DF24 + ' ';
  result[4] := #$26C5 + #$FE0F + ' ';
  result[5] := #$D83C#$DF25 + ' ';
  result[6] := #$2601 + #$FE0F + ' ';
  result[7] := #$D83C#$DF27 + ' ';
  result[8] := #$D83C#$DF28 + ' ';
  result[9] := #$D83C#$DF27 + ' ';
  result[10] := #$D83C#$DF28 + ' ';
  result[11] := #$D83C#$DF27 + ' ';
  result[12] := #$D83C#$DF28 + ' ';
  result[13] := #$26C8 + ' ';
  result[14] := #$D83C#$DF28 + ' ';
  result[15] := #$D83C#$DF27 + ' ';
  result[16] := #$D83C#$DF28 + ' ';
  result[17] := #$2601 + #$FE0F + ' ';
  result[18] := #$D83C#$DF25 + ' ';
  result[19] := #$26C5 + #$FE0F + ' ';
  result[20] := #$D83C#$DF24 + ' ';
  result[21] := #$2600 + #$FE0F + ' ';
  result[22] := #$2600 + #$FE0F + ' ';
end;

function Spinner(kind : TSpinnerKind; unicode : Boolean) : ISpinner;
var
  frames   : TArray<string>;
  interval : Integer;
  needsUnicode : Boolean;
begin
  case kind of
    TSpinnerKind.Dots: begin frames := Frames_Dots; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Dots2: begin frames := Frames_Dots2; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Line: begin frames := Frames_Line; interval := 130; needsUnicode := False; end;
    TSpinnerKind.Arc: begin frames := Frames_Arc; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Star: begin frames := Frames_Star; interval := 70; needsUnicode := True; end;
    TSpinnerKind.Aesthetic: begin frames := Frames_Aesthetic; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Arrow: begin frames := Frames_Arrow; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Arrow2: begin frames := Frames_Arrow2; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Arrow3: begin frames := Frames_Arrow3; interval := 120; needsUnicode := True; end;
    TSpinnerKind.Ascii: begin frames := Frames_Ascii; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Balloon: begin frames := Frames_Balloon; interval := 140; needsUnicode := False; end;
    TSpinnerKind.Balloon2: begin frames := Frames_Balloon2; interval := 120; needsUnicode := False; end;
    TSpinnerKind.BetaWave: begin frames := Frames_BetaWave; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Binary: begin frames := Frames_Binary; interval := 80; needsUnicode := False; end;
    TSpinnerKind.BluePulse: begin frames := Frames_BluePulse; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Bounce: begin frames := Frames_Bounce; interval := 120; needsUnicode := True; end;
    TSpinnerKind.BouncingBall: begin frames := Frames_BouncingBall; interval := 80; needsUnicode := True; end;
    TSpinnerKind.BouncingBar: begin frames := Frames_BouncingBar; interval := 80; needsUnicode := True; end;
    TSpinnerKind.BoxBounce: begin frames := Frames_BoxBounce; interval := 120; needsUnicode := True; end;
    TSpinnerKind.BoxBounce2: begin frames := Frames_BoxBounce2; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Christmas: begin frames := Frames_Christmas; interval := 400; needsUnicode := True; end;
    TSpinnerKind.Circle: begin frames := Frames_Circle; interval := 120; needsUnicode := True; end;
    TSpinnerKind.CircleHalves: begin frames := Frames_CircleHalves; interval := 50; needsUnicode := True; end;
    TSpinnerKind.CircleQuarters: begin frames := Frames_CircleQuarters; interval := 120; needsUnicode := True; end;
    TSpinnerKind.Clock: begin frames := Frames_Clock; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Default: begin frames := Frames_Default; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Dots10: begin frames := Frames_Dots10; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Dots11: begin frames := Frames_Dots11; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Dots12: begin frames := Frames_Dots12; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Dots13: begin frames := Frames_Dots13; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Dots14: begin frames := Frames_Dots14; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Dots3: begin frames := Frames_Dots3; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Dots4: begin frames := Frames_Dots4; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Dots5: begin frames := Frames_Dots5; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Dots6: begin frames := Frames_Dots6; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Dots7: begin frames := Frames_Dots7; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Dots8: begin frames := Frames_Dots8; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Dots8Bit: begin frames := Frames_Dots8Bit; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Dots9: begin frames := Frames_Dots9; interval := 80; needsUnicode := True; end;
    TSpinnerKind.DotsCircle: begin frames := Frames_DotsCircle; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Dqpb: begin frames := Frames_Dqpb; interval := 100; needsUnicode := False; end;
    TSpinnerKind.DwarfFortress: begin frames := Frames_DwarfFortress; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Earth: begin frames := Frames_Earth; interval := 180; needsUnicode := True; end;
    TSpinnerKind.FingerDance: begin frames := Frames_FingerDance; interval := 160; needsUnicode := True; end;
    TSpinnerKind.FistBump: begin frames := Frames_FistBump; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Flip: begin frames := Frames_Flip; interval := 70; needsUnicode := False; end;
    TSpinnerKind.Grenade: begin frames := Frames_Grenade; interval := 80; needsUnicode := True; end;
    TSpinnerKind.GrowHorizontal: begin frames := Frames_GrowHorizontal; interval := 120; needsUnicode := True; end;
    TSpinnerKind.GrowVertical: begin frames := Frames_GrowVertical; interval := 120; needsUnicode := True; end;
    TSpinnerKind.Hamburger: begin frames := Frames_Hamburger; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Hearts: begin frames := Frames_Hearts; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Layer: begin frames := Frames_Layer; interval := 150; needsUnicode := True; end;
    TSpinnerKind.Line2: begin frames := Frames_Line2; interval := 100; needsUnicode := False; end;
    TSpinnerKind.Material: begin frames := Frames_Material; interval := 17; needsUnicode := True; end;
    TSpinnerKind.Mindblown: begin frames := Frames_Mindblown; interval := 160; needsUnicode := True; end;
    TSpinnerKind.Monkey: begin frames := Frames_Monkey; interval := 300; needsUnicode := True; end;
    TSpinnerKind.Moon: begin frames := Frames_Moon; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Noise: begin frames := Frames_Noise; interval := 100; needsUnicode := True; end;
    TSpinnerKind.OrangeBluePulse: begin frames := Frames_OrangeBluePulse; interval := 100; needsUnicode := True; end;
    TSpinnerKind.OrangePulse: begin frames := Frames_OrangePulse; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Pipe: begin frames := Frames_Pipe; interval := 100; needsUnicode := False; end;
    TSpinnerKind.Point: begin frames := Frames_Point; interval := 125; needsUnicode := True; end;
    TSpinnerKind.Pong: begin frames := Frames_Pong; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Runner: begin frames := Frames_Runner; interval := 140; needsUnicode := True; end;
    TSpinnerKind.Sand: begin frames := Frames_Sand; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Shark: begin frames := Frames_Shark; interval := 120; needsUnicode := True; end;
    TSpinnerKind.SimpleDots: begin frames := Frames_SimpleDots; interval := 400; needsUnicode := False; end;
    TSpinnerKind.SimpleDotsScrolling: begin frames := Frames_SimpleDotsScrolling; interval := 200; needsUnicode := False; end;
    TSpinnerKind.Smiley: begin frames := Frames_Smiley; interval := 200; needsUnicode := True; end;
    TSpinnerKind.SoccerHeader: begin frames := Frames_SoccerHeader; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Speaker: begin frames := Frames_Speaker; interval := 160; needsUnicode := True; end;
    TSpinnerKind.SquareCorners: begin frames := Frames_SquareCorners; interval := 180; needsUnicode := True; end;
    TSpinnerKind.Squish: begin frames := Frames_Squish; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Star2: begin frames := Frames_Star2; interval := 80; needsUnicode := False; end;
    TSpinnerKind.TimeTravel: begin frames := Frames_TimeTravel; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Toggle: begin frames := Frames_Toggle; interval := 250; needsUnicode := True; end;
    TSpinnerKind.Toggle10: begin frames := Frames_Toggle10; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Toggle11: begin frames := Frames_Toggle11; interval := 50; needsUnicode := True; end;
    TSpinnerKind.Toggle12: begin frames := Frames_Toggle12; interval := 120; needsUnicode := True; end;
    TSpinnerKind.Toggle13: begin frames := Frames_Toggle13; interval := 80; needsUnicode := False; end;
    TSpinnerKind.Toggle2: begin frames := Frames_Toggle2; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Toggle3: begin frames := Frames_Toggle3; interval := 120; needsUnicode := True; end;
    TSpinnerKind.Toggle4: begin frames := Frames_Toggle4; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Toggle5: begin frames := Frames_Toggle5; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Toggle6: begin frames := Frames_Toggle6; interval := 300; needsUnicode := True; end;
    TSpinnerKind.Toggle7: begin frames := Frames_Toggle7; interval := 80; needsUnicode := True; end;
    TSpinnerKind.Toggle8: begin frames := Frames_Toggle8; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Toggle9: begin frames := Frames_Toggle9; interval := 100; needsUnicode := True; end;
    TSpinnerKind.Triangle: begin frames := Frames_Triangle; interval := 50; needsUnicode := True; end;
    TSpinnerKind.Weather: begin frames := Frames_Weather; interval := 100; needsUnicode := True; end;
  else
    frames := Frames_Dots; interval := 80; needsUnicode := True;
  end;

  if needsUnicode and not unicode then
  begin
    // Unicode-only spinner requested on a legacy terminal - fall back
    // to the plain Line frames so the animation still works.
    frames := Frames_Line;
    interval := 130;
  end;
  result := TSpinnerImpl.Create(frames, interval);
end;

function Spinner(const frames : TArray<string>; intervalMs : Integer) : ISpinner;
begin
  if intervalMs < 1 then intervalMs := 1;
  result := TSpinnerImpl.Create(frames, intervalMs);
end;

{ RandomSpinner }

class function RandomSpinner.Pick : TSpinnerKind;
const
  // The well-behaved subset that animates cleanly in any modern
  // terminal. Excludes wide-emoji spinners that mis-cell on legacy
  // hosts (Hearts, Soccerheader, FistBump, etc.) and the multi-byte
  // image-style ones.
  POOL : array[0..15] of TSpinnerKind = (
    TSpinnerKind.Dots, TSpinnerKind.Line, TSpinnerKind.Arc,
    TSpinnerKind.Star, TSpinnerKind.BouncingBall, TSpinnerKind.BouncingBar,
    TSpinnerKind.CircleHalves, TSpinnerKind.CircleQuarters, TSpinnerKind.Clock, TSpinnerKind.Dots2, TSpinnerKind.Dots3,
    TSpinnerKind.Dots4, TSpinnerKind.Moon, TSpinnerKind.Pipe, TSpinnerKind.SimpleDots, TSpinnerKind.Triangle);
begin
  result := POOL[Random(Length(POOL))];
end;

class function RandomSpinner.Make(unicode : Boolean) : ISpinner;
begin
  result := Spinner(Pick, unicode);
end;

initialization
  Randomize;

end.
