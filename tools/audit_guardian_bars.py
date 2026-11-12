#!/usr/bin/env python3
"""Static regression checks for the guardians' bars: two side by side under the bosses' full
bars, so four guardians up at once take two short lines instead of a tall column."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "Frames/Bosses.lua").read_text(encoding="utf-8")


def fail(message: str) -> None:
    print("FAIL:", message, file=sys.stderr)
    raise SystemExit(1)


look = re.search(r"guardian = \{([^}]*)\}", source)
if not look or "half = true" not in look.group(1):
    fail("a guardian's bar must be half a boss bar wide, so two fit side by side")
for field in ("side", "dbMax"):
    if not re.search(rf"\b{field} = \d+", look.group(1)):
        fail(f"the guardian look must set {field} (the space between the pair, and the debuffs that fit)")
for fragment, message in (
    ("local function StepRow(r, e, slotX, slotY, dt, now, pal, since)", "a row must take its place across as well as down"),
    ("if ga ~= gb then return gb end", "the bosses must come first, then the guardians"),
    ("if paired and not (k == guards and col == 0) then x = (col == 0) and -half or half end",
     "guardians must go two by two, a lone last one in the middle"),
    ("if not paired or col == 2 or k == guards then",
     "narrow guardian bars must stack singly; wide ones pair up"),
    ("n < cap", "the number of guardian debuffs must follow the available bar width"),
    ("math.floor((width - 16 + DB_GAP) / (r.look.db + DB_GAP))", "debuff capacity must scale down with bar width"),
    ('r.name:SetHeight(L.font + 4)', "a long guardian name must stay on one line"),
    ('r.name:SetWidth(w - 22)', "guardian name must use almost all the bar's width"),
    ('r.value:SetPoint("CENTER", r.bar.frame, "CENTER", 0, 0)',
     "health and percentage must have a separate line within the guardian bar"),
    ('r.value:SetPoint("BOTTOMRIGHT", r.bar.frame, "TOPRIGHT", 0, 4)',
     "boss health must retain its original location"),
    ("local paired = db.width >= GUARD_PAIR_MIN", "pairing must depend on available width"),
    ("LOOKS.guardianSingle", "narrow layouts must give guardians a full-width bar"),
):
    if fragment not in source:
        fail(message)

# Geometry regression: the minimum user width has to stay readable; at normal
# and large widths, the four Horsemen stay in two balanced rows below the boss.
PAIR_MIN, GAP = 340, 24
for width in (240, 300, 339, 340, 380, 500, 700):
    paired = width >= PAIR_MIN
    bar_width = (width - GAP) // 2 if paired else width
    name_width = bar_width - 22
    value_width = bar_width - 16
    if name_width < 80 or value_width <= 0:
        fail(f"guardian text has too little room at {width}px")
    if paired:
        center = (bar_width + GAP) / 2
        left_end = -center + bar_width / 2
        right_start = center - bar_width / 2
        if right_start - left_end < GAP - 0.1:
            fail(f"guardian pair overlaps at {width}px")
        lines_for_four = 2
    else:
        lines_for_four = 4
    if width == 380 and (bar_width != 178 or lines_for_four != 2):
        fail("four Horsemen should occupy two rows at the default width")

print("PASS: paired guardian bars retain readable names/HP, narrow widths fall back to single rows")
