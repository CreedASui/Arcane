#!/usr/bin/env python3
"""Static regression checks for the damage-number looks (Custom, Elemental, Comic, Royal, Grim):
every font and crit backdrop a look names exists, its art is a texture the game can draw, every
word it shows is translated, and Custom keeps the numbers exactly as the player set them."""
from __future__ import annotations

import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOOK_ORDER = ["custom", "elemental", "comic", "royal", "grim"]
SCHOOLS = [1, 2, 4, 8, 16, 32, 64]


def fail(message: str) -> None:
    print("FAIL:", message, file=sys.stderr)
    raise SystemExit(1)


def source(name: str) -> str:
    path = ROOT / name
    if not path.is_file():
        fail(f"{name} is missing")
    return path.read_text(encoding="utf-8")


numbers = source("Numbers/Numbers.lua")
looks = source("Numbers/Looks.lua")
widgets = source("Numbers/Widgets.lua")
animation = source("Numbers/Animation.lua")
options = source("Numbers/Options.lua")
commands = source("Numbers/Commands.lua")


def block(source: str, start: str) -> str:
    """The text of a Lua table from `start` to its matching closing brace."""
    at = source.find(start)
    if at < 0:
        fail(f"missing {start!r}")
    depth, i = 0, source.index("{", at)
    begin = i
    while i < len(source):
        if source[i] == "{":
            depth += 1
        elif source[i] == "}":
            depth -= 1
            if depth == 0:
                return source[begin:i + 1]
        i += 1
    fail(f"unclosed table after {start!r}")


def strings_in(text: str) -> list[str]:
    return re.findall(r'"((?:[^"\\]|\\.)*)"', text)


# --- the fonts and backdrops there are
fonts = set(re.findall(r'\{\s*name\s*=\s*"([^"]+)",\s*path\s*=', block(numbers, "C.FONTS = ")))
backdrops = block(numbers, "C.CRIT_BACKDROPS = ")
back_tex = dict(re.findall(r'(\w+)\s*=\s*"(Num\w+)"', block(backdrops, "tex = ")))
back_names = dict(re.findall(r'(\w+)\s*=\s*"([^"]+)"', block(backdrops, "names = ")))
back_order = strings_in(block(backdrops, "order = "))
for key in back_order:
    if key != "none" and key not in back_tex:
        fail(f"crit backdrop {key} has no texture")
    if key not in back_names:
        fail(f"crit backdrop {key} has no name")
for key in ("steel", "burst", "gilded"):
    if key not in back_order:
        fail(f"the {key} crit backdrop must be one the player can pick")

# --- every crit backdrop's art: an uncompressed BLP2 no more than 512 a side
for key, tex in back_tex.items():
    path = ROOT / "Art" / f"{tex}.blp"
    if not path.is_file():
        fail(f"Art/{tex}.blp is missing")
    head = path.read_bytes()[:28]
    if head[:4] != b"BLP2":
        fail(f"Art/{tex}.blp is not a BLP2 texture")
    width, height = struct.unpack("<II", head[12:20])
    if width > 512 or height > 512 or width & (width - 1) or height & (height - 1):
        fail(f"Art/{tex}.blp is {width}x{height}: textures must be powers of two, at most 512")
if not (ROOT / "tools/build_crit_backdrops.py").is_file():
    fail("the script that draws NumSteel, NumBurst and NumGilded must stay in tools/")

# --- the looks
table = block(numbers, "C.LOOKS = ")
if strings_in(block(table, "order = ")) != LOOK_ORDER:
    fail("the looks must be, in order: " + ", ".join(LOOK_ORDER))
look_names = dict(re.findall(r'(\w+)\s*=\s*"([^"]+)"', block(table, "names = ")))
look_notes = dict(re.findall(r'(\w+)\s*=\s*"((?:[^"\\]|\\.)*)"', block(table, "notes = ")))
for key in LOOK_ORDER:
    if key not in look_names or key not in look_notes:
        fail(f"the {key} look needs a name and a note")
defined = block(table, "looks = ")
if "custom =" in defined:
    fail("Custom is no look: it must keep the player's own picks")
for key in LOOK_ORDER[1:]:
    body = block(defined, f"{key} = ")
    for font in re.findall(r'(?:font|critFont)\s*=\s*"([^"]+)"', body):
        if font not in fonts:
            fail(f"the {key} look names a font that isn't bundled: {font}")
    for back in re.findall(r'back\s*=\s*"(\w+)"', body):
        if back not in back_tex:
            fail(f"the {key} look names a crit backdrop that doesn't exist: {back}")
    if "schools = " not in body and ("crit = " not in body or "back = " not in body):
        fail(f"the {key} look must give its crits colors and a backdrop")
elemental = block(defined, "elemental = ")
for school in SCHOOLS:
    if not re.search(rf"\[{school}\]\s*=\s*\{{[^\n]*font\s*=", elemental):
        fail(f"Elemental must give school {school}'s crits letters, a backdrop and colors")

# --- Custom keeps the numbers as they were; a saved look that no longer exists becomes Custom
if 'look = "custom"' not in block(numbers, "C.DEFAULTS = "):
    fail("the numbers must start on the Custom look")
if not re.search(r'if not C\.LOOKS\.names\[C\.db\.look or ""\] then\s*C\.db\.look = "custom"', numbers):
    fail("a saved look that no longer exists must become Custom")
for fragment, message in (
    ("if not look then\n\t\treturn C.db.font", "Custom must draw numbers in the player's own font"),
    ("return C.CRIT_BACKDROPS.tex[C.db.backdrop or \"none\"]", "Custom must keep the player's own crit backdrop"),
    ("color = C.COLOR_CRIT", "Custom crits must stay gold"),
    ("return look and look.critScale or 1.15", "Custom crits must keep their size"),
):
    if fragment not in looks:
        fail(message)

# --- drawing: every number asks its look; nothing of the old fixed color is left
for fragment, message in (
    ("N.Widgets.SetFace(w, N.Looks.Font(label), label.miss)", "each number must take its look's letters"),
    ("N.Looks.Color(label, now)", "each number must take its look's colors"),
    ("N.Looks.Backdrop(label)", "each crit must take its look's backdrop"),
    ("N.Looks.Flash(label)", "a look's crit must land in its flash"),
    ("label.critAt = now", "a crit's backdrop and flash must start when it becomes a crit"),
):
    if fragment not in animation:
        fail(message)
if "local function LabelColor" in animation:
    fail("the old fixed crit color must not come back beside the looks")
if "if w.face == path then" not in widgets:
    fail("a number's face must only be set when it changes")
if "if word and AUI.Face then return AUI.Face(font.path) end" not in widgets:
    fail("a word (Miss, Immune) must keep the face its language draws its letters with")
if "w.block = block" not in widgets:
    fail("a crit's backdrop must be sized to the number it is behind")

# --- the options and the slash command
if options.count("index = math.mod(index - 1 + step + count, count) + 1") != 2:
    fail("stepping back from the first look or backdrop must go round to the last (Lua 5.0's math.mod keeps the sign)")
for fragment, message in (
    ('C.LText(lookHead, "Look")', "the options must offer the looks"),
    ("OwnPicks()", "picking a font or backdrop by hand must go back to Custom"),
    ("o.fontHead:SetAlpha(own)", "your own font and backdrop must show they wait while a look is on"),
):
    if fragment not in options:
        fail(message)
if "elseif C.LOOKS.names[command] then" not in commands:
    fail("/Arcane numbers <look> must put a look on")

# --- every word a look shows, in every language
phrases = set(look_names.values()) | set(look_notes.values()) | set(back_names.values())
phrases |= {"Look", "Critical hit backdrop", "number look: ",
            "/Arcane numbers custom | elemental | comic | royal | grim - pick a look"}
english = source("Locales/Locale.lua")
for phrase in sorted(phrases):
    quoted = '"' + phrase.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if not re.search(r"\{\s*" + re.escape(quoted) + r"\s*,", english):
        fail(f"Locales/Locale.lua must translate {phrase!r}")
    for code in ("zh", "ru", "ja", "ko", "pl", "tr"):
        text = source(f"Locales/Locale_{code}.lua")
        if f"[{quoted}]" not in text:
            fail(f"Locales/Locale_{code}.lua must translate {phrase!r}")

print(f"PASS: {len(LOOK_ORDER)} damage-number looks, {len(back_tex)} crit backdrops and {len(phrases)} words "
      "check out; Custom keeps the player's own picks")
