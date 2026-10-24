#!/system/bin/sh
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Glyph Matrix exerciser for the Nothing Phone (4a) -- Awinic AW20144 on
# /sys/class/leds/matrix-leds. Needs root; run under /system/bin/sh.
#
# WHAT THE PANEL IS (measured, from Nothing's own kernel source
# drivers/leds/aw20144/leds-aw20144.c plus stock's SystemUI RRO):
#
#   - the chip has 144 channels (ALL_CHANNEL), of which VALID_CHANNEL = 137
#     are wired to LEDs;
#   - stock's SystemUI RRO sets integer/glyph_matrix_length = 13;
#   - a 13x13 grid masked to a circle of radius 6.5 holds EXACTLY 137 cells.
#
# So the panel is a circular dot matrix addressed as a 13x13 grid with the
# corners cut off. The "169 LEDs" in this project's older notes is 13*13, the
# bounding square -- not the LED count.
#
#   . . . . # # # # # . . . .
#   . . # # # # # # # # # . .
#   . # # # # # # # # # # # .
#   . # # # # # # # # # # # .
#   # # # # # # # # # # # # #     13 rows, 137 lit cells
#   # # # # # # # # # # # # #
#   # # # # # # # # # # # # #
#   # # # # # # # # # # # # #
#   # # # # # # # # # # # # #
#   . # # # # # # # # # # # .
#   . # # # # # # # # # # # .
#   . . # # # # # # # # # . .
#   . . . . # # # # # . . . .
#
# CONFIRMED ON HARDWARE 2026-09-17, by watching the panel:
#   - `rows` travels TOP to BOTTOM, so grid row 0 is the camera end;
#   - each row is a solid unbroken line, so the walk really is row-major;
#   - rows are narrow at top and bottom and widest in the middle, which is the
#     circular mask showing itself;
#   - `cols` travels LEFT to RIGHT, so grid column 0 is the left edge;
#   - a letter F drawn through `grid` renders as a correct F -- not mirrored,
#     not rotated. Rows and columns alone cannot detect mirroring; only an
#     asymmetric glyph can, which is why the F test exists.
# So logical index 0..136 is a plain row-major walk of the mask from the
# top-left, and no transform is needed between grid coordinates and the wire.
#
# Writing frame_brightness with exactly 137 space-separated values is ONE whole
# frame: the driver maps them through its own mapping_channels[137] table and
# does a single block I2C write. That is the animation primitive.

SYS=/sys/class/leds/matrix-leds
SIDE=13
CENTER=6
RADIUS_SQ=42      # 6.5^2 = 42.25, and no integer lands in between
COUNT=137
DEFAULT_LEVEL=40  # modest: all 137 at 255 draws real current

die() { echo "glyphctl: $*" >&2; exit 1; }

[ -d "$SYS" ] || die "$SYS not present"

# Checked only where we actually write, so that `dump` and `dryrun` stay usable
# without root.
need_root() {
    [ -w "$SYS/frame_brightness" ] || die "cannot write $SYS -- need root (adb root)"
}

LEVEL=$DEFAULT_LEVEL
TARGET=-1; ROW=-1; COL=-1; LIMIT=-1
FRAME=""

# Builds FRAME as 137 space-separated values. Deliberately free of command
# substitution: a per-cell $(...) meant ~19k forks for one sweep.
build_frame() {
    _mode=$1
    _out=""; _idx=0; _y=0
    while [ $_y -lt $SIDE ]; do
        _x=0
        while [ $_x -lt $SIDE ]; do
            _dx=$(( _x - CENTER )); _dy=$(( _y - CENTER ))
            if [ $(( _dx * _dx + _dy * _dy )) -le $RADIUS_SQ ]; then
                _v=0
                case $_mode in
                    all)   _v=$LEVEL ;;
                    zero)  _v=0 ;;
                    index) [ $_idx -eq $TARGET ] && _v=$LEVEL ;;
                    row)   [ $_y   -eq $ROW    ] && _v=$LEVEL ;;
                    col)   [ $_x   -eq $COL    ] && _v=$LEVEL ;;
                    upto)  [ $_idx -lt $LIMIT  ] && _v=$LEVEL ;;
                esac
                _out="$_out $_v"
                _idx=$(( _idx + 1 ))
            fi
            _x=$(( _x + 1 ))
        done
        _y=$(( _y + 1 ))
    done
    # No leading space: frame_brightness_store() sscanf's the first value and
    # THEN does strchr(buf, ' '), so a leading space makes it read value 1
    # twice -- 137 values arrive as frame_num 138, which matches no branch in
    # the driver and silently paints 144 zeros. Measured via dmesg.
    FRAME=${_out# }
    NCELLS=$_idx
}

ensure_on() {
    [ "$(cat $SYS/operating_mode 2>/dev/null)" = "1" ] || echo 1 > $SYS/operating_mode
}

push() {
    need_root
    ensure_on
    echo "$FRAME" > $SYS/frame_brightness
}

show() { build_frame "$1"; push; }

# ---- geometry notes -------------------------------------------------------
# Mask row widths, top to bottom: 5 9 11 11 13 13 13 13 13 11 11 9 5 = 137.
# So grid rows 4..8 are each the FULL 13 wide -- a 13x5 rectangle inscribed in
# the circle. That is the text band: characters scroll through it edge to edge
# with no clipping. Rows 0-3 are 36 cells and rows 9-12 are another 36, and in
# text mode both are blank, so a text frame is 36 zeros + 65 cells + 36 zeros.
Z36=" 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0"
BAND_TOP=4

# The 36 perimeter cells as logical indices, clockwise from 12 o'clock.
# Precomputed: deriving it needs atan2, which the shell has not got.
PERIM="2 3 4 12 13 24 35 48 61 74 87 100 111 122 131 130 136 135 134 133 132 124 123 112 101 88 75 62 49 36 25 14 5 6 0 1"

# 5x5 font, stored as five 5-char rows concatenated into 25 chars. Started as
# 3x5, but at that size several letters were unreadable on the panel -- and the
# hand-joined table had real errors in it ("2" and "3" were the same glyph).
# Now built and validated from explicit rows.
glyph_for() {
    case "$1" in
        " ") G="........................." ;;
        "!") G="..#....#....#.........#.." ;;
        "%") G="#...#...#...#...#...#...#" ;;
        \') G="..#....#................." ;;
        "(") G="...#...#....#....#.....#." ;;
        ")") G=".#.....#....#....#...#..." ;;
        "+") G=".......#..#####..#......." ;;
        ",") G=".................#...#..." ;;
        "-") G="..........#####.........." ;;
        ".") G="......................#.." ;;
        "/") G="....#...#...#...#...#...." ;;
        "0") G=".###.#...##...##...#.###." ;;
        "1") G="..#...##....#....#...###." ;;
        "2") G=".###.#...#..##..#...#####" ;;
        "3") G="####.....#.###.....#####." ;;
        "4") G="#..#.#..#.#####...#....#." ;;
        "5") G="######....####.....#####." ;;
        "6") G=".###.#....####.#...#.###." ;;
        "7") G="#####....#...#...#....#.." ;;
        "8") G=".###.#...#.###.#...#.###." ;;
        "9") G=".###.#...#.####....#.###." ;;
        ":") G=".......#.........#......." ;;
        "=") G=".....#####.....#####....." ;;
        "?") G=".###.#...#..##........#.." ;;
        "A") G=".###.#...#######...##...#" ;;
        "B") G="####.#...#####.#...#####." ;;
        "C") G=".#####....#....#.....####" ;;
        "D") G="####.#...##...##...#####." ;;
        "E") G="######....####.#....#####" ;;
        "F") G="######....####.#....#...." ;;
        "G") G=".#####....#..###...#.###." ;;
        "H") G="#...##...#######...##...#" ;;
        "I") G=".###...#....#....#...###." ;;
        "J") G="..###...#....#.#..#..##.." ;;
        "K") G="#...##..#.###..#..#.#...#" ;;
        "L") G="#....#....#....#....#####" ;;
        "M") G="#...###.###.#.##...##...#" ;;
        "N") G="#...###..##.#.##..###...#" ;;
        "O") G=".###.#...##...##...#.###." ;;
        "P") G="####.#...#####.#....#...." ;;
        "Q") G=".###.#...##...##..#..##.#" ;;
        "R") G="####.#...#####.#..#.#...#" ;;
        "S") G=".#####.....###.....#####." ;;
        "T") G="#####..#....#....#....#.." ;;
        "U") G="#...##...##...##...#.###." ;;
        "V") G="#...##...##...#.#.#...#.." ;;
        "W") G="#...##...##.#.###.###...#" ;;
        "X") G="#...#.#.#...#...#.#.#...#" ;;
        "Y") G="#...#.#.#...#....#....#.." ;;
        "Z") G="#####...#...#...#...#####" ;;
        *) G="#########################" ;;   # unknown -> solid block
    esac
}

# Builds FRAME from ON, a space-delimited set of logical indices (" 3 7 12 ").
build_set() {
    _out=""; _i=0
    while [ $_i -lt $COUNT ]; do
        case "$ON" in
            *" $_i "*) _out="$_out $LEVEL" ;;
            *)         _out="$_out 0" ;;
        esac
        _i=$(( _i + 1 ))
    done
    FRAME=${_out# }
}

# Reads 13 lines of 13 characters on stdin into FRAME. '.' and space are off.
read_grid() {
    _out=""; _y=0
    while [ $_y -lt $SIDE ]; do
        read -r _line || _line=""
        _x=0
        while [ $_x -lt $SIDE ]; do
            _dx=$(( _x - CENTER )); _dy=$(( _y - CENTER ))
            if [ $(( _dx * _dx + _dy * _dy )) -le $RADIUS_SQ ]; then
                case "${_line:$_x:1}" in
                    ""|"."|" ") _out="$_out 0" ;;
                    *)          _out="$_out $LEVEL" ;;
                esac
            fi
            _x=$(( _x + 1 ))
        done
        _y=$(( _y + 1 ))
    done
    FRAME=${_out# }
}

# Renders five 13-char row strings into the text band, blanking everything else.
band_frame() {
    _acc=""
    for _r in "$1" "$2" "$3" "$4" "$5"; do
        _k=0
        while [ $_k -lt $SIDE ]; do
            case "${_r:$_k:1}" in
                "."|" "|"") _acc="$_acc 0" ;;
                *)          _acc="$_acc $LEVEL" ;;
            esac
            _k=$(( _k + 1 ))
        done
    done
    FRAME="$Z36$_acc$Z36"
    FRAME=${FRAME# }
}

# Expands a message into five row strings B0..B4, one column of gap per char.
build_bitmap() {
    B0=""; B1=""; B2=""; B3=""; B4=""
    _i=0; _n=${#1}
    while [ $_i -lt $_n ]; do
        glyph_for "${1:$_i:1}"
        B0="$B0${G:0:5}."
        B1="$B1${G:5:5}."
        B2="$B2${G:10:5}."
        B3="$B3${G:15:5}."
        B4="$B4${G:20:5}."
        _i=$(( _i + 1 ))
    done
}

upper() { echo "$1" | tr 'a-z' 'A-Z'; }
PAD13="............."

cmd=$1
[ $# -gt 0 ] && shift

case "$cmd" in
  on)     need_root; echo 1 > $SYS/operating_mode; echo "operating_mode=1" ;;
  off)    show zero; echo 0 > $SYS/operating_mode; echo "operating_mode=0" ;;
  clear)  show zero; echo "cleared" ;;
  all)    LEVEL=${1:-$DEFAULT_LEVEL}; show all; echo "all = $LEVEL" ;;

  pixel)  TARGET=${1:?usage: pixel <0-136> [level]}; LEVEL=${2:-$DEFAULT_LEVEL}
          show index; echo "pixel $TARGET = $LEVEL" ;;

  row)    ROW=${1:?usage: row <0-12> [level]}; LEVEL=${2:-$DEFAULT_LEVEL}
          show row; echo "row $ROW = $LEVEL" ;;

  col)    COL=${1:?usage: col <0-12> [level]}; LEVEL=${2:-$DEFAULT_LEVEL}
          show col; echo "col $COL = $LEVEL" ;;

  bar)    _pct=${1:?usage: bar <0-100> [level]}; LEVEL=${2:-$DEFAULT_LEVEL}
          LIMIT=$(( COUNT * _pct / 100 )); show upto
          echo "bar $_pct% = $LIMIT/$COUNT LEDs" ;;

  sweep)  _delay=${1:-0.12}; LEVEL=${2:-$DEFAULT_LEVEL}; TARGET=0
          while [ $TARGET -lt $COUNT ]; do
              show index; sleep $_delay; TARGET=$(( TARGET + 1 ))
          done
          show zero; echo "swept $COUNT LEDs" ;;

  rows)   _delay=${1:-0.4}; LEVEL=${2:-$DEFAULT_LEVEL}; ROW=0
          while [ $ROW -lt $SIDE ]; do
              echo "  row $ROW"; show row; sleep $_delay; ROW=$(( ROW + 1 ))
          done
          show zero ;;

  cols)   _delay=${1:-0.4}; LEVEL=${2:-$DEFAULT_LEVEL}; COL=0
          while [ $COL -lt $SIDE ]; do
              echo "  col $COL"; show col; sleep $_delay; COL=$(( COL + 1 ))
          done
          show zero ;;

  # 13 lines of 13 chars on stdin; '.' or space is off, anything else is on.
  grid)   LEVEL=${1:-$DEFAULT_LEVEL}; read_grid; push; echo "grid pushed" ;;

  text)   _msg=$(upper "${1:?usage: text <message> [level]}"); LEVEL=${2:-$DEFAULT_LEVEL}
          build_bitmap "$_msg"
          B0="$B0$PAD13"; B1="$B1$PAD13"; B2="$B2$PAD13"; B3="$B3$PAD13"; B4="$B4$PAD13"
          band_frame "${B0:0:13}" "${B1:0:13}" "${B2:0:13}" "${B3:0:13}" "${B4:0:13}"
          push; echo "text: $_msg (first 13 columns)" ;;

  scroll) _msg=$(upper "${1:?usage: scroll <message> [delay] [level] [loops]}")
          _delay=${2:-0.07}; LEVEL=${3:-$DEFAULT_LEVEL}; _loops=${4:-1}
          build_bitmap "$_msg"
          # Pad both ends so the message scrolls in from the right and fully off
          # to the left rather than appearing and vanishing mid-panel.
          B0="$PAD13$B0$PAD13"; B1="$PAD13$B1$PAD13"; B2="$PAD13$B2$PAD13"
          B3="$PAD13$B3$PAD13"; B4="$PAD13$B4$PAD13"
          _w=${#B0}; _last=$(( _w - SIDE )); _l=0
          echo "scroll: $_msg (${_w} columns, $(( _last + 1 )) frames x $_loops)"
          while [ $_l -lt $_loops ]; do
              _off=0
              while [ $_off -le $_last ]; do
                  band_frame "${B0:$_off:13}" "${B1:$_off:13}" "${B2:$_off:13}" \
                             "${B3:$_off:13}" "${B4:$_off:13}"
                  push; sleep $_delay
                  _off=$(( _off + 1 ))
              done
              _l=$(( _l + 1 ))
          done
          show zero ;;

  arc)    _pct=${1:?usage: arc <0-100> [level]}; LEVEL=${2:-$DEFAULT_LEVEL}
          _n=$(( 36 * _pct / 100 )); ON=" "; _k=0
          for _p in $PERIM; do
              [ $_k -lt $_n ] && ON="$ON$_p "
              _k=$(( _k + 1 ))
          done
          build_set; push; echo "arc $_pct% = $_n/36 perimeter LEDs" ;;

  spin)   _delay=${1:-0.05}; LEVEL=${2:-$DEFAULT_LEVEL}; _turns=${3:-3}
          _t=0
          while [ $_t -lt $_turns ]; do
              _k=0
              for _p in $PERIM; do
                  ON=" $_p "; build_set; push; sleep $_delay
                  _k=$(( _k + 1 ))
              done
              _t=$(( _t + 1 ))
          done
          show zero ;;

  icon)   _name=${1:?usage: icon <heart|check|cross|bell|battery> [level]}
          LEVEL=${2:-$DEFAULT_LEVEL}
          case "$_name" in
            heart)   read_grid <<'ICON'
.............
.............
...##...##...
..####.####..
..#########..
..#########..
...#######...
....#####....
.....###.....
......#......
.............
.............
.............
ICON
;;
            check)   read_grid <<'ICON'
.............
.............
.............
..........#..
.........##..
........##...
..#....##....
..##..##.....
...####......
....##.......
.............
.............
.............
ICON
;;
            cross)   read_grid <<'ICON'
.............
.............
...#.....#...
...##...##...
....##.##....
.....###.....
......#......
.....###.....
....##.##....
...##...##...
...#.....#...
.............
.............
ICON
;;
            bell)    read_grid <<'ICON'
.............
......#......
.....###.....
....#####....
....#####....
...#######...
...#######...
..#########..
..#########..
.###########.
.............
......#......
.....###.....
ICON
;;
            battery) read_grid <<'ICON'
.............
.............
...#######...
...#.....#...
..##.....##..
..##.....##..
..##.....##..
..##.....##..
..##.....##..
...#######...
.............
.............
.............
ICON
;;
            *) die "unknown icon: $_name" ;;
          esac
          push; echo "icon: $_name" ;;

  # Prints the frame it WOULD push, and its value count. Touches nothing.
  dryrun) _m=${1:-all}; LEVEL=${2:-$DEFAULT_LEVEL}
          build_frame "$_m"
          echo "mode=$_m cells=$NCELLS"
          # Count as the driver does -- every space-separated field, empties
          # included, because a leading space is exactly what broke this once.
          echo "values=$(echo "$FRAME" | awk '{print NF}')"
          echo "leading=[$(echo "$FRAME" | cut -c1)] first=[$(echo "$FRAME" | cut -c1-12)]" ;;

  dump)   for n in operating_mode imax chipid hwen brightness max_brightness; do
              printf '  %-16s %s\n' "$n" "$(cat $SYS/$n 2>/dev/null)"
          done ;;

  *) cat <<USAGE
glyphctl -- Glyph Matrix exerciser (137 LEDs, circular, 13x13 addressing)

  on | off | clear
  all    [level]                every LED
  pixel  <0-136> [level]        one LED by logical index
  row    <0-12>  [level]        one grid row
  col    <0-12>  [level]        one grid column
  bar    <0-100> [level]        first N% of LEDs in logical order
  sweep  [delay] [level]        every LED in turn  <- reveals index order
  rows   [delay] [level]        row by row         <- reveals orientation
  cols   [delay] [level]        column by column
  grid   [level]                13 lines of 13 chars on stdin ('.' = off)
  text   <message> [level]      static text in the 13x5 band (rows 4-8)
  scroll <message> [delay] [level] [loops]
                                scroll a message right to left
  arc    <0-100> [level]        progress ring, clockwise from 12 o'clock
  spin   [delay] [level] [turns]  single dot around the perimeter
  icon   <heart|check|cross|bell|battery> [level]
  dryrun [mode] [level]         print the frame, push nothing
  dump                          node states

level is 0-255, default $DEFAULT_LEVEL. All 137 at 255 draws real current.
USAGE
     ;;
esac
