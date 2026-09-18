"""BioVirus containment HUD tab bar for kitty  (tab_bar_style custom).

Pairs with the BioVirus starship.toml — same vocabulary and
palette as the lock screen's fx/HudFrame.qml in the omarchy-biovirus repo.

    ┤ <badge> 1·fish ├  2·nvim   3·ssh host ───────────── <badge> BIOVIRUS·LVL-4

  active tab      accent #4bffa5, bold, bracketed with ┤ ├
  inactive tab    dim    #63a186
  needs attention alarm  #ff4d5e (a bell in a background tab — the "breach")
  rail + status   muted  #2e8f63, right-aligned after the last tab

Every glyph is a \\u escape on purpose: Nerd Font codepoints are Private Use
Area and do not survive every edit/transport path (see the note at the top of
starship.toml). Keep them as escapes.

Reload after editing:  kitten @ load-config   (or restart kitty).
kitty caches this module per process, so load-config alone may keep the old
draw_tab — a new kitty window is the reliable check.
"""

from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb
from kitty.utils import color_as_int

ACCENT = 0x4BFFA5
DIM = 0x63A186
ALARM = 0xFF4D5E
RAIL = 0x2E8F63

BIOHAZARD = "\U000F00A7"          # nf-md-biohazard, the lock-screen badge glyph
LBRACKET = "┤"               # ┤
RBRACKET = "├"               # ├
RAIL_CHAR = "─"              # ─
DOT = "·"                    # ·
STATUS = f" {BIOHAZARD} BIOVIRUS{DOT}LVL-4 "


def _title(tab: TabBarData, max_len: int) -> str:
    t = tab.title
    if tab.num_windows > 1:
        t = f"{t} :{tab.num_windows}:"
    return t if len(t) <= max_len else t[: max(1, max_len - 1)] + "…"


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    bg = as_rgb(color_as_int(draw_data.default_bg))
    screen.cursor.bg = bg
    screen.cursor.italic = False

    # max_tab_length is the whole width kitty allots this tab, decoration
    # included, and on the real pass it equals what we measured in the layout
    # pass — so the allowance must be exact or titles truncate for no reason.
    #   active:   " ┤ " + badge + " " + "N·" + title + " ├ "   = 10 + title
    #   inactive: "   " + "N·" + title + "   "                 =  8 + title
    deco = 10 if tab.is_active else 8
    title = _title(tab, max(4, max_tab_length - deco))

    if tab.is_active:
        screen.cursor.fg = as_rgb(RAIL)
        screen.cursor.bold = False
        screen.draw(f" {LBRACKET} ")
        screen.cursor.fg = as_rgb(ACCENT)
        screen.cursor.bold = True
        screen.draw(f"{BIOHAZARD} {index}{DOT}{title}")
        screen.cursor.bold = False
        screen.cursor.fg = as_rgb(RAIL)
        screen.draw(f" {RBRACKET} ")
    else:
        screen.cursor.fg = as_rgb(ALARM if tab.needs_attention else DIM)
        screen.cursor.bold = tab.needs_attention
        screen.draw(f"   {index}{DOT}{title}   ")
        screen.cursor.bold = False

    end = screen.cursor.x

    if is_last and not extra_data.for_layout:
        # Rail out to the right edge, then the containment status flush right.
        # Only on the real pass: during kitty's layout pass the tab's measured
        # width becomes its allotted width, and this would claim the whole bar.
        # The cursor is deliberately LEFT at the end of the line — kitty runs
        # erase_in_line from the cursor after the last tab, so parking it back
        # at `end` would wipe the status we just drew.
        rail_len = screen.columns - end - len(STATUS)
        screen.cursor.fg = as_rgb(RAIL)
        screen.cursor.bold = False
        if rail_len > 0:
            screen.draw(RAIL_CHAR * rail_len)
            screen.draw(STATUS)

    return end
