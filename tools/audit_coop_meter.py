#!/usr/bin/env python3
"""Static regression checks for Party DPS in co-op: it keeps moving while the game's ledger answers
"not ready", names each friend's best skill (procs too), reads new meter data right away, and a
click on a hero's line opens that hero's own skills."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
meter = (ROOT / "Windows/Meter.lua").read_text(encoding="utf-8")


def fail(message: str) -> None:
    print("FAIL:", message, file=sys.stderr)
    raise SystemExit(1)


read = re.search(r"local function ReadSnapshot\(tab\)(.*?)\nend\n", meter, re.S)
if not read:
    fail("Windows/Meter.lua must read the meter in ReadSnapshot")
body = read.group(1)
for fragment, message in (
    ('code == "NOT_READY" and tab == "party" and not S.checkpoint and GameParty()',
     'a "not ready" party ledger must fall back to the game\'s own party lines (not after a Reset)'),
    ("AZS_PARTY_UPDATED > S.partyAt", "only party lines newer than the ledger's last answer may replace its numbers"),
    ('return "game"', "the fallback must keep the ledger as the meter's source (Reset keeps its checkpoint)"),
    ("S.partyAt = GetTime()", "a party answer from the ledger must be remembered"),
):
    if fragment not in body:
        fail(message)
for fragment, message in (
    ('if not done or done == "game" then ReadLines(tab) end', "the game's party lines must be read on that fallback"),
    ('if tab == "party" then GameBestSkills() end', "a hero with no named best skill must take the game's own top spell"),
    ('e.key = "o" .. (e.name ~= "?" and e.name or tostring(row.ownerId))',
     "ledger lines and the game's lines must share keys, so a line keeps its place"),
    ("e.portrait = S.portraitOf[l.name]", "a hero must keep their portrait on the game's lines"),
    ('driver:RegisterEvent("CHAT_MSG_ADDON")', "the meter must hear the game's meter data arrive"),
    ('if arg1 ~= "AZSM" and arg1 ~= "AZSPARTY" then return end', "only the meter's own messages may hurry a read"),
    ('if db.tab == "party" and not S.focus then\n\t\t\t\t\ttagW = Fit(r.petTag, e.pet, left)',
     "a best skill short of room must keep its first words, not its last"),
):
    if fragment not in meter:
        fail(message)

# A click on a hero's line opens that hero's own skills; the title goes back.
focus = re.search(r"local function ReadFocus\(\)(.*?)\nend\n", meter, re.S)
if not focus:
    fail("Windows/Meter.lua must read a clicked hero's own skills in ReadFocus")
for fragment, message in (
    ('query.scope, query.ownerId = "owner", f.ownerId', "a friend's skills must be read with scope owner"),
    ('if own then query.scope = "self"', "your own line must read your own skills"),
    ('FromSnapshot(snap, "friend")', "a friend's skills must not overwrite your pet bar's"),
    ('code == "UNKNOWN_OWNER" or code == "OWNER_NOT_PRESENT"', "a friend who left must send the view back to Party DPS"),
):
    if fragment not in focus.group(1):
        fail(message)
for fragment, message in (
    ('f:SetScript("OnMouseUp", function()', "a meter line must take clicks"),
    ('if button ~= "LeftButton" or drag.moving or GetTime() - drag.endedAt < 0.25 then return end',
     "only a left click that ends no drag may open a hero"),
    ('if focus then names = { "< " .. focus.name } end', "a hero's view must be titled with their name and the way back"),
    ('C.L("Click for their skills.")', "a hero's line must say a click opens their skills"),
    ('if db.tab == "party" and not S.focus then return e.color', "a hero's skills must take their schools' colors, not a class's"),
    ("S.focus, S.headKey = nil, nil\n\t\t\tClearRows()", "picking a view must leave a hero's view"),
):
    if fragment not in meter:
        fail(message)
for name in ("Locale_zh", "Locale_ru", "Locale_ja", "Locale_ko", "Locale_pl", "Locale_tr"):
    if '["Click for their skills."]' not in (ROOT / f"Locales/{name}.lua").read_text(encoding="utf-8"):
        fail(f"Locales/{name}.lua must translate the click hint")
if '{ "Click for their skills.",' not in (ROOT / "Locales/Locale.lua").read_text(encoding="utf-8"):
    fail("Locales/Locale.lua must translate the click hint")

print("PASS: Party DPS keeps moving in co-op, names each friend's best skill, reads new data at once, and opens a hero's skills on a click")
