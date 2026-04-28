program ReadmeDemo;

{
  ReadmeDemo - a single-screen feature showcase modelled on the Rich
  (Python) "rich features" splash. Layout: a 2-column grid where the
  left column holds red-bold section labels and the right column holds
  the live demo for that section.

  This demo is the README's hero image. Keep its output width pinned
  to TOTAL_WIDTH so the gradient and sub-grids line up.
}

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Math,
  VSoft.AnsiConsole.Types in '..\..\source\Core\VSoft.AnsiConsole.Types.pas',
  VSoft.AnsiConsole.Color in '..\..\source\Core\VSoft.AnsiConsole.Color.pas',
  VSoft.AnsiConsole.Emoji in '..\..\source\Core\VSoft.AnsiConsole.Emoji.pas',
  VSoft.AnsiConsole.Style in '..\..\source\Core\VSoft.AnsiConsole.Style.pas',
  VSoft.AnsiConsole.Segment in '..\..\source\Core\VSoft.AnsiConsole.Segment.pas',
  VSoft.AnsiConsole.Measurement in '..\..\source\Core\VSoft.AnsiConsole.Measurement.pas',
  VSoft.AnsiConsole.Internal.Cell.Tables in '..\..\source\Internal\VSoft.AnsiConsole.Internal.Cell.Tables.pas',
  VSoft.AnsiConsole.Internal.Cell in '..\..\source\Internal\VSoft.AnsiConsole.Internal.Cell.pas',
  VSoft.AnsiConsole.Internal.SegmentOps in '..\..\source\Internal\VSoft.AnsiConsole.Internal.SegmentOps.pas',
  VSoft.AnsiConsole.Rendering in '..\..\source\Rendering\VSoft.AnsiConsole.Rendering.pas',
  VSoft.AnsiConsole.Rendering.AnsiWriter in '..\..\source\Rendering\VSoft.AnsiConsole.Rendering.AnsiWriter.pas',
  VSoft.AnsiConsole.Capabilities in '..\..\source\Profile\VSoft.AnsiConsole.Capabilities.pas',
  VSoft.AnsiConsole.Detection in '..\..\source\Profile\VSoft.AnsiConsole.Detection.pas',
  VSoft.AnsiConsole.Enrichment in '..\..\source\Profile\VSoft.AnsiConsole.Enrichment.pas',
  VSoft.AnsiConsole.Profile in '..\..\source\Profile\VSoft.AnsiConsole.Profile.pas',
  VSoft.AnsiConsole.Console in '..\..\source\Console\VSoft.AnsiConsole.Console.pas',
  VSoft.AnsiConsole.Settings in '..\..\source\Console\VSoft.AnsiConsole.Settings.pas',
  VSoft.AnsiConsole.Cursor in '..\..\source\Console\VSoft.AnsiConsole.Cursor.pas',
  VSoft.AnsiConsole.Markup.Tokenizer in '..\..\source\Markup\VSoft.AnsiConsole.Markup.Tokenizer.pas',
  VSoft.AnsiConsole.Markup.Parser in '..\..\source\Markup\VSoft.AnsiConsole.Markup.Parser.pas',
  VSoft.AnsiConsole.Borders.Box in '..\..\source\Borders\VSoft.AnsiConsole.Borders.Box.pas',
  VSoft.AnsiConsole.Borders.Table in '..\..\source\Borders\VSoft.AnsiConsole.Borders.Table.pas',
  VSoft.AnsiConsole.Borders.Tree in '..\..\source\Borders\VSoft.AnsiConsole.Borders.Tree.pas',
  VSoft.AnsiConsole.Widgets.Text in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Text.pas',
  VSoft.AnsiConsole.Widgets.Markup in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Markup.pas',
  VSoft.AnsiConsole.Widgets.Rule in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Rule.pas',
  VSoft.AnsiConsole.Widgets.Paragraph in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Paragraph.pas',
  VSoft.AnsiConsole.Widgets.Padder in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Padder.pas',
  VSoft.AnsiConsole.Widgets.Align in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Align.pas',
  VSoft.AnsiConsole.Widgets.Rows in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Rows.pas',
  VSoft.AnsiConsole.Widgets.Columns in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Columns.pas',
  VSoft.AnsiConsole.Widgets.Grid in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Grid.pas',
  VSoft.AnsiConsole.Widgets.Panel in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Panel.pas',
  VSoft.AnsiConsole.Widgets.Table in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Table.pas',
  VSoft.AnsiConsole.Widgets.Tree in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Tree.pas',
  VSoft.AnsiConsole.Input in '..\..\source\Console\VSoft.AnsiConsole.Input.pas',
  VSoft.AnsiConsole.Prompts.Common in '..\..\source\Prompts\VSoft.AnsiConsole.Prompts.Common.pas',
  VSoft.AnsiConsole.Prompts.Hierarchy in '..\..\source\Prompts\VSoft.AnsiConsole.Prompts.Hierarchy.pas',
  VSoft.AnsiConsole.Prompts.Text in '..\..\source\Prompts\VSoft.AnsiConsole.Prompts.Text.pas',
  VSoft.AnsiConsole.Prompts.Text.Generic in '..\..\source\Prompts\VSoft.AnsiConsole.Prompts.Text.Generic.pas',
  VSoft.AnsiConsole.Prompts.Confirm in '..\..\source\Prompts\VSoft.AnsiConsole.Prompts.Confirm.pas',
  VSoft.AnsiConsole.Prompts.Select in '..\..\source\Prompts\VSoft.AnsiConsole.Prompts.Select.pas',
  VSoft.AnsiConsole.Prompts.MultiSelect in '..\..\source\Prompts\VSoft.AnsiConsole.Prompts.MultiSelect.pas',
  VSoft.AnsiConsole.Live.Exclusivity in '..\..\source\Live\VSoft.AnsiConsole.Live.Exclusivity.pas',
  VSoft.AnsiConsole.Live.Display in '..\..\source\Live\VSoft.AnsiConsole.Live.Display.pas',
  VSoft.AnsiConsole.Live.Spinners in '..\..\source\Live\VSoft.AnsiConsole.Live.Spinners.pas',
  VSoft.AnsiConsole.Live.Status in '..\..\source\Live\VSoft.AnsiConsole.Live.Status.pas',
  VSoft.AnsiConsole.Live.Progress in '..\..\source\Live\VSoft.AnsiConsole.Live.Progress.pas',
  VSoft.AnsiConsole.Widgets.Canvas in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Canvas.pas',
  VSoft.AnsiConsole.Widgets.BarChart in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.BarChart.pas',
  VSoft.AnsiConsole.Widgets.BreakdownChart in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.BreakdownChart.pas',
  VSoft.AnsiConsole.Widgets.Calendar in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Calendar.pas',
  VSoft.AnsiConsole.Widgets.TextPath in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.TextPath.pas',
  VSoft.AnsiConsole.Widgets.Layout in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Layout.pas',
  VSoft.AnsiConsole.Widgets.Figlet in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Figlet.pas',
  VSoft.AnsiConsole.Internal.FigletFont in '..\..\source\Internal\VSoft.AnsiConsole.Internal.FigletFont.pas',
  VSoft.AnsiConsole.Internal.Fonts.Standard in '..\..\source\Internal\VSoft.AnsiConsole.Internal.Fonts.Standard.pas',
  VSoft.AnsiConsole.Widgets.Json in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Json.pas',
  VSoft.AnsiConsole.Widgets.Exception in '..\..\source\Widgets\VSoft.AnsiConsole.Widgets.Exception.pas',
  VSoft.AnsiConsole.Recorder in '..\..\source\Console\VSoft.AnsiConsole.Recorder.pas',
  VSoft.AnsiConsole in '..\..\source\VSoft.AnsiConsole.pas';

const
  // Total demo width. The terminal probably has more cells available;
  // we pin the demo so the gradient and inner sub-grids stay aligned.
  TOTAL_WIDTH    = 100;
  LABEL_WIDTH    = 14;
  GUTTER         = 2;
  CONTENT_WIDTH  = TOTAL_WIDTH - LABEL_WIDTH - GUTTER;   // = 84

  // Lorem ipsum used in three "Justify" columns.
  LOREM = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. ' +
          'Quisque in metus sed sapien ultricies pretium a at justo. ' +
          'Maecenas luctus velit et auctor maximus.';

{ ----- HSV -> RGB sweep used for the colour gradient strip ----- }

procedure HsvToRgb(h : Single; out r, g, b : Byte);
var
  hp     : Single;        // h / 60, in [0, 6)
  sector : Integer;
  frac   : Single;        // fractional position within current sector
  rp, gp, bp : Single;
begin
  // Full saturation, full value, no need for the C/X/m formula -
  // pick from a 6-entry sector table directly.
  hp := h / 60.0;
  sector := Trunc(hp) mod 6;
  if sector < 0 then sector := sector + 6;
  frac := hp - Trunc(hp);
  case sector of
    0: begin rp := 1;        gp := frac;     bp := 0; end;
    1: begin rp := 1 - frac; gp := 1;        bp := 0; end;
    2: begin rp := 0;        gp := 1;        bp := frac; end;
    3: begin rp := 0;        gp := 1 - frac; bp := 1; end;
    4: begin rp := frac;     gp := 0;        bp := 1; end;
  else
    rp := 1; gp := 0; bp := 1 - frac;
  end;
  r := Byte(Round(rp * 255));
  g := Byte(Round(gp * 255));
  b := Byte(Round(bp * 255));
end;

function MakeGradient(width, height : Integer) : ICanvas;
var
  c : ICanvas;
  x, y : Integer;
  hue : Single;
  r, g, b : Byte;
  divW : Integer;
begin
  c := Widgets.Canvas(width, height);
  divW := width;
  if divW < 2 then divW := 2;
  for y := 0 to height - 1 do
    for x := 0 to width - 1 do
    begin
      // Sweep hue across X, full saturation/value at every Y.
      hue := (x / (divW - 1)) * 360.0;
      if hue >= 360.0 then hue := 359.99;
      HsvToRgb(hue, r, g, b);
      c.SetPixel(x, y, TAnsiColor.FromRGB(r, g, b));
    end;
  result := c;
end;

{ ----- Section builders ----- }

function ColorsContent : IRenderable;
var
  inner : IGrid;
  list  : IMarkup;
  grad  : ICanvas;
begin
  // Sub-grid: 26 cells for the checklist, rest for the gradient.
  inner := Widgets.Grid.WithGutter(2);
  inner.AddColumn(TGridColumnWidth.Fixed, 30, TAlignment.Left);
  inner.AddColumn(TGridColumnWidth.Star,  1,  TAlignment.Left);

  list := Widgets.Markup(
    '[green]:check_mark_button:[/] [bold]4-bit color[/]'        + #10 +
    '[green]:check_mark_button:[/] [bold]8-bit color[/]'        + #10 +
    '[green]:check_mark_button:[/] [bold]Truecolor (16.7 million)[/]' + #10 +
    '[green]:check_mark_button:[/] [bold]Dumb terminals[/]'     + #10 +
    '[green]:check_mark_button:[/] [bold]Automatic color conversion[/]'
  );

  grad := MakeGradient(CONTENT_WIDTH - 26 - 2, 8);
  inner.AddRow([list, grad]);
  result := inner;
end;

function StylesContent : IRenderable;
begin
  result := Widgets.Markup(
    'All ansi styles: [bold]bold[/], [dim]dim[/], [italic]italic[/], ' +
    '[underline]underline[/], [strikethrough]strikethrough[/], ' +
    '[reverse]reverse[/], and even [blink]blink[/].');
end;

function TextContent : IRenderable;
var
  rs  : IRows;
  inner : IGrid;
  para1, para2, para3 : IMarkup;
begin
  // Top: intro line, bottom: 3 sub-columns of Lorem ipsum.
  rs := Widgets.Rows;

  rs.Add(Widgets.Markup(
    'Word wrap text. Justify [green]left[/], [yellow]center[/] or [blue]right[/].'));
  // WithExpand(True) is required to make star columns actually divide
  // the available width instead of sizing each cell to its natural max
  // (which for a long unwrapped Markup is the full maxWidth budget,
  // resulting in three full-width columns stacked vertically).
  inner := Widgets.Grid.WithGutter(3).WithExpand(True);
  inner.AddColumn(TGridColumnWidth.Star, 1, TAlignment.Left);
  inner.AddColumn(TGridColumnWidth.Star, 1, TAlignment.Left);
  inner.AddColumn(TGridColumnWidth.Star, 1, TAlignment.Left);

  para1 := Widgets.Markup('[green]'    + LOREM + '[/]').WithAlignment(TAlignment.Left);
  para2 := Widgets.Markup('[yellow]'   + LOREM + '[/]').WithAlignment(TAlignment.Center);
  para3 := Widgets.Markup('[blue]'     + LOREM + '[/]').WithAlignment(TAlignment.Right);
  inner.AddRow([para1, para2, para3]);
  rs.Add(inner);

  result := rs;
end;

{ Encode an astral codepoint (>= U+10000) as a UTF-16 surrogate pair.
  Used to assemble flag emoji from two regional-indicator codepoints
  without relying on compile-time concatenation of `#$xxxx` literals,
  which Delphi's string-folding can corrupt when adjacent literals both
  start with a high surrogate. }
function CpToUtf16(cp : Cardinal) : string;
var
  hi, lo : Cardinal;
begin
  if cp < $10000 then
  begin
    SetLength(result, 1);
    result[1] := Char(cp);
    Exit;
  end;
  cp := cp - $10000;
  hi := $D800 + (cp shr 10);
  lo := $DC00 + (cp and $3FF);
  SetLength(result, 2);
  result[1] := Char(hi);
  result[2] := Char(lo);
end;

function Flag(regionA, regionB : Cardinal) : string;
begin
  result := CpToUtf16(regionA) + CpToUtf16(regionB);
end;

function AsianContent : IRenderable;
const
  // Flag-themed markers using national colours. We deliberately don't use
  // regional-indicator emoji here because the default Windows Terminal
  // font fallback chain (Cascadia + Segoe UI Emoji) doesn't ship flag-
  // glyph entries for the indicator pairs, so they render as separate
  // letter glyphs instead of combined flags. These coloured tags read
  // the same on every terminal regardless of font support.
  TAG_CN = '[bold yellow on red] CN [/]';     // red field, yellow accent
  TAG_JP = '[bold red on white] JP [/]';      // hinomaru: red on white
  TAG_KR = '[bold blue on white] KR [/]';     // taegeuk: blue on white
begin
  result := Widgets.Markup(
    TAG_CN + ' [magenta]'#$8BE5#$5E93#$652F#$6301#$4E2D#$6587#$FF0C#$65E5#$6587#$548C#$97E9#$6587#$6587#$672C#$FF01'[/]' + #10 +
    TAG_JP + ' [magenta]'#$30E9#$30A4#$30D6#$30E9#$30EA#$306F#$4E2D#$56FD#$8A9E#$3001#$65E5#$672C#$8A9E#$3001#$97D3#$56FD#$8A9E#$306E#$30C6#$30AD#$30B9#$30C8#$3092#$30B5#$30DD#$30FC#$30C8#$3057#$3066#$3044#$307E#$3059'[/]' + #10 +
    TAG_KR + ' [magenta]'#$C774' '#$B77C#$C774#$BE0C#$B7EC#$B9AC'   '#$C911#$AD6D#$C5B4' , '#$C77C#$BCF8#$C5B4' '#$BC0F' '#$D55C#$AD6D#$C5B4' '#$D14D#$C2A4#$D2B8#$B97C' '#$C9C0#$C6D0#$D569#$B2C8#$B2E4'[/]'
  );
end;

function MarkupContent : IRenderable;
begin
  result := Widgets.Markup(
    'Supports a simple [italic]bbcode[/] like [bold]markup[/] ' +
    'for [green]color[/], [yellow]style[/], and emoji! ' +
    ':thumbs_up: :red_apple: :smiling_face_with_horns: :bear: :baguette_bread: :bus:');
end;

function TablesContent : IRenderable;
var
  t : ITable;
begin
  t := Widgets.Table.WithBorder(TTableBorderKind.Square);
  t.AddColumn('[bold]Date[/]',            TGridColumnWidth.Auto, 0, TAlignment.Left);
  t.AddColumn('[bold]Title[/]',           TGridColumnWidth.Auto, 0, TAlignment.Left);
  t.AddColumn('[bold]Production Budget[/]', TGridColumnWidth.Auto, 0, TAlignment.Right);
  t.AddColumn('[bold]Box Office[/]',      TGridColumnWidth.Auto, 0, TAlignment.Right);
  t.AddRow(['[grey78]Dec 20, 2019[/]', '[grey78]Star Wars: The Rise of Skywalker[/]', '[grey78]$275,000,000[/]', '[grey78]$375,126,118[/]']);
  t.AddRow(['[grey78]May 25, 2018[/]', '[grey78]Solo: A Star Wars Story[/]',          '[grey78]$275,000,000[/]', '[grey78]$393,151,347[/]']);
  t.AddRow(['[bold]Dec 15, 2017[/]',   '[bold]Star Wars Ep. VIII: The Last Jedi[/]', '[bold]$262,000,000[/]',   '[bold green]$1,332,539,889[/]']);
  t.AddRow(['[grey78]May 19, 1999[/]', '[grey78]Star Wars Ep. I: [italic]The phantom Menace[/][/]', '[grey78]$115,000,000[/]', '[grey78]$1,027,044,677[/]']);
  result := t;
end;

function SyntaxAndPrettyContent : IRenderable;
var
  inner : IGrid;
  code, dict : IMarkup;
begin
  // Sub-grid: code on left (~50 cells), pretty-printed dict on right.
  inner := Widgets.Grid.WithGutter(2);
  inner.AddColumn(TGridColumnWidth.Star, 3, TAlignment.Left);
  inner.AddColumn(TGridColumnWidth.Star, 2, TAlignment.Left);

  code := Widgets.Markup(
    '[grey50] 1[/] [orange1]def[/] [yellow]iter_last[/]([cyan]values[/]: [magenta]Iterable[/][[T]]) -> Ite' + #10 +
    '[grey50] 2[/]     [green]"""Iterate and generate a tuple with[/]'   + #10 +
    '[grey50] 3[/]     iter_values = [yellow]iter[/]([cyan]values[/])'   + #10 +
    '[grey50] 4[/]     [orange1]try[/]:'                                    + #10 +
    '[grey50] 5[/]         previous_value = [yellow]next[/]([cyan]iter_values[/])' + #10 +
    '[grey50] 6[/]     [orange1]except[/] [magenta]StopIteration[/]:'       + #10 +
    '[grey50] 7[/]         [orange1]return[/]'                              + #10 +
    '[grey50] 8[/]     [orange1]for[/] value [orange1]in[/] iter_values:'      + #10 +
    '[grey50] 9[/]         [orange1]yield[/] [magenta]False[/], previous_value' + #10 +
    '[grey50]10[/]         previous_value = value'                       + #10 +
    '[grey50]11[/]     [orange1]yield[/] [magenta]True[/], previous_value');

  dict := Widgets.Markup(
    '{'                                                                  + #10 +
    '    [green]''foo''[/]: [['                                          + #10 +
    '        [magenta]3.1427[/],'                                        + #10 +
    '        ('                                                          + #10 +
    '            [green]''Paul Atreides''[/],'                           + #10 +
    '            [green]''Vladimir Harkonnen''[/],'                      + #10 +
    '            [green]''Thufir Hawat''[/]'                             + #10 +
    '        )'                                                          + #10 +
    '    ]],'                                                            + #10 +
    '    [green]''atomic''[/]: ([italic magenta]False[/], [italic magenta]True[/], [italic magenta]None[/])' + #10 +
    '}');

  inner.AddRow([code, dict]);
  result := inner;
end;

function MarkdownContent : IRenderable;
var
  inner : IGrid;
  src, rendered : IRenderable;
  pnl : IPanel;
begin
  inner := Widgets.Grid.WithGutter(2);
  inner.AddColumn(TGridColumnWidth.Star, 1, TAlignment.Left);
  inner.AddColumn(TGridColumnWidth.Star, 1, TAlignment.Left);

  src := Widgets.Markup(
    '[bold]# Markdown[/]'                                                + #10 +
                                                                           #10 +
    'Supports much of the [italic]*markdown*[/], [bold]__syntax__[/]!'   + #10 +
                                                                           #10 +
    '- Headers'                                                          + #10 +
    '- Basic formatting: [bold]**bold**[/], [italic]*italic*[/], [underline]`code`[/]' + #10 +
    '- Block quotes'                                                     + #10 +
    '- Lists, and more...');

  pnl := Widgets.Panel(
    Widgets.Markup(
      'Supports much of the [italic]markdown[/], [bold]syntax[/]!'       + #10 +
                                                                           #10 +
      #$2022' Headers'                                                   + #10 +
      #$2022' Basic formatting: [bold]bold[/], [italic]italic[/], [reverse]code[/]' + #10 +
      #$2022' Block quotes'                                              + #10 +
      #$2022' Lists, and more...')
  ).WithHeader('Markdown').WithBorder(TBoxBorderKind.Square);
  rendered := pnl;

  inner.AddRow([src, rendered]);
  result := inner;
end;

function MoreContent : IRenderable;
begin
  result := Widgets.Markup(
    '[italic]Progress bars, columns, status, trees, select etc...[/]');
end;

procedure AddSection(g : IGrid; const labelText : string;
                       const content : IRenderable);
begin
  g.AddRow([
    Widgets.Markup('[red bold]' + labelText + '[/]').WithAlignment(TAlignment.Right),
    content
  ]);
  g.AddRow([Widgets.Text(''), Widgets.Text('')]);
end;

var
  outer : IGrid;
begin
  try
    AnsiConsole.WriteLine;
    // Centered italic title at the top of the demo. Aligning a Markup
    // widget centres it within the surrounding console width.
    AnsiConsole.Write(Widgets.Markup('[italic]VSoft.AnsiConsole features[/]').WithAlignment(TAlignment.Center));
    AnsiConsole.WriteLine;
    AnsiConsole.WriteLine;

    outer := Widgets.Grid.WithGutter(GUTTER).WithWidth(TOTAL_WIDTH);
    outer.AddColumn(TGridColumnWidth.Fixed, LABEL_WIDTH, TAlignment.Right);
    outer.AddColumn(TGridColumnWidth.Star,  1,            TAlignment.Left);

    AddSection(outer, 'Colors',           ColorsContent);
    AddSection(outer, 'Styles',           StylesContent);
    AddSection(outer, 'Text',             TextContent);
    AddSection(outer, 'Asian'#10'language'#10'support', AsianContent);
    AddSection(outer, 'Markup',           MarkupContent);
    AddSection(outer, 'Tables',           TablesContent);
    AddSection(outer, 'Syntax'#10'highlighting'#10'&'#10'pretty'#10'printing', SyntaxAndPrettyContent);
    AddSection(outer, 'Markdown',         MarkdownContent);
    AddSection(outer, '+more!',           MoreContent);

    AnsiConsole.Write(outer);
    AnsiConsole.WriteLine;

    Write('Press <Enter> to quit...');
    Readln;
  except
    on E : Exception do
    begin
      AnsiConsole.WriteLine;
      AnsiConsole.Write(Widgets.ExceptionWidget(E));
      AnsiConsole.WriteLine;
      Readln;
    end;
  end;
end.
