#!/usr/bin/env python3
"""Static regression checks for two numbers players read every run: each friend's best skill on
Party DPS, and the rank in each skill bar slot's box."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
meter = (ROOT / "Windows/Meter.lua").read_text(encoding="utf-8")
bar = (ROOT / "SkillBar/Bar.lua").read_text(encoding="utf-8")


def fail(message: str) -> None:
    print("FAIL:", message, file=sys.stderr)
    raise SystemExit(1)


# Party DPS: the lines by player carry no skill, so the best skills come from the same party's
# damage read again by skill (groupBy "source"), and a row without a skill is never a best skill.
from_snapshot = re.search(r"local function FromSnapshot\(snap, tab\)(.*?)\nend\n", meter, re.S)
if not from_snapshot:
    fail("Windows/Meter.lua must build its lines in FromSnapshot")
if "BestSkills(" in from_snapshot.group(1):
    fail("best skills must not be read from the lines by player: they have no skill and read nil")
read = re.search(r"local function ReadSnapshot\(tab\)(.*?)\nend\n", meter, re.S)
if not read:
    fail("Windows/Meter.lua must read the meter in ReadSnapshot")
body = read.group(1)
for fragment, message in (
    ('query.groupBy = "source"', "Party DPS must read the party's damage again by skill"),
    ("local bySkill = Call(AZS_GetMeterSnapshot, query)", "the by-skill snapshot must go through Call"),
    ("BestSkills(bySkill)", "best skills must come from the by-skill snapshot"),
):
    if fragment not in body:
        fail(message)
if "row.sourceKey ~= nil" not in meter:
    fail("a row with no skill must never become a hero's best skill")

# The ranks: a skill can be listed more than once with the same icon. The one in that very slot
# wins, else the highest rank, never just whichever came last.
for fragment, message in (
    ("local function Higher(list, key, rank)", "ranks must keep the higher of two entries"),
    ("Higher(byIcon, icon, rank)", "the rank by icon must be the highest with that icon"),
    ('Higher(bySlotIcon, slot .. "|" .. icon, rank)', "ranks must also be kept by slot and icon together"),
    ('bySlotIcon[s.action .. "|" .. icon] or byIcon[icon]', "a slot must first take the rank of its own slot's entry"),
):
    if fragment not in bar:
        fail(message)
if re.search(r"byIcon\[icon\]\s*=\s*rank", bar):
    fail("the last entry with an icon must not overwrite a higher rank")

print("PASS: Party DPS names each friend's best skill; each slot shows its own skill's highest rank")
