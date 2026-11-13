#!/usr/bin/env python3
"""Static guardrails for paired guardians, their labels, and narrow-width fallback."""
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
        fail(f"the guardian look must set {field} (the pair gap and supported debuffs)")

# The regression math must use the actual Lua constants, not a second set of
# numbers which could silently drift away from the runtime layout.
pair_match = re.search(r"local GUARD_PAIR_MIN = (\d+)", source)
gap_match = re.search(r"\bside = (\d+)", look.group(1))
width_match = re.search(
    r"db\.width = C\.Clamp\(tonumber\(db\.width\) or (\d+), (\d+), (\d+)\)",
    source,
)
if not (pair_match and gap_match and width_match):
    fail("could not read guardian width rules from the Lua implementation")
PAIR_MIN = int(pair_match.group(1))
GAP = int(gap_match.group(1))
DEFAULT, MIN_WIDTH, MAX_WIDTH = map(int, width_match.groups())
if not (MIN_WIDTH < PAIR_MIN < MAX_WIDTH and MIN_WIDTH <= DEFAULT <= MAX_WIDTH):
    fail("the paired-to-single guardian threshold is outside the permitted width range")
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
    ("local half = (math.floor((db.width - LOOKS.guardian.side) / 2) + LOOKS.guardian.side) / 2",
     "paired guardian offsets must use the same gap as their widths"),
):
    if fragment not in source:
        fail(message)

# Cover saved narrow widths, the exact transition, the default and the maximum.
# At paired widths, four guardians require two rows; at narrower widths, four.
widths = sorted(set((MIN_WIDTH, min(MIN_WIDTH + 60, MAX_WIDTH), PAIR_MIN - 1,
                     PAIR_MIN, DEFAULT, 500, MAX_WIDTH)))
for width in widths:
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
    if width == DEFAULT and paired and (bar_width != (width - GAP) // 2 or lines_for_four != 2):
        fail("four guardians should occupy two rows at the default width")

print("PASS: paired guardian bars retain readable names/HP, narrow widths fall back to single rows")
