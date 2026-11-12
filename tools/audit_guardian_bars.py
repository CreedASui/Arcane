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
    ("if not (k == guards and col == 0) then x = (col == 0) and -half or half end",
     "guardians must go two by two, a lone last one in the middle"),
    ("if col == 2 or k == guards then", "a line of guardians must end after two, or after the last"),
    ("n < (r.look.dbMax or DB_MAX)", "a guardian's debuff icons must stop before its neighbour's bar"),
    ('r.name:SetHeight(L.font + 4)', "a long guardian name must stay on one line"),
):
    if fragment not in source:
        fail(message)

print("PASS: guardians' bars go two side by side under the bosses, a lone last one in the middle")
