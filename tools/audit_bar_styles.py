#!/usr/bin/env python3
"""Static architecture checks for Arcane's optional class skill-bar styles."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CLASSES = (
    "warrior", "paladin", "hunter", "rogue", "priest",
    "shaman", "mage", "warlock", "druid",
)


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def source(name: str) -> str:
    path = ROOT / name
    if not path.is_file():
        fail(f"Required file is missing: {name}")
    return path.read_text(encoding="utf-8")


def count_chunk_level_locals(text: str) -> int:
    """Count file-scope locals; nested/function locals belong to their own scopes."""
    count = 0
    for line in text.splitlines():
        if not line.startswith("local "):
            continue
        declaration = line[len("local "):].split("=", 1)[0].strip()
        if declaration.startswith("function "):
            count += 1
        else:
            count += len([item for item in declaration.split(",") if item.strip()])
    return count


def main() -> None:
    toc = [line.strip() for line in source("Arcane.toc").splitlines()
           if line.strip() and not line.lstrip().startswith("#")]
    required_order = ("Bar_Styles_Data.lua", "Bar_Styles.lua", "Bar.lua")
    positions = []
    for name in required_order:
        if name not in toc:
            fail(f"Arcane.toc is missing {name}")
        if not (ROOT / name).is_file():
            fail(f"TOC entry does not exist: {name}")
        positions.append(toc.index(name))
    if positions != sorted(positions):
        fail("Skill-bar style data/controller must load before Bar.lua")
    print("PASS: skill-bar style modules load in dependency order")

    data = source("Bar_Styles_Data.lua")
    styles = source("Bar_Styles.lua")
    bar = source("Bar.lua")
    core = source("Core.lua")

    found = set(re.findall(r"^\t([a-z]+)\s*=\s*\{", data, re.M))
    if found != set(CLASSES):
        fail("Class palette data must define exactly the nine supported classes; "
             f"found {', '.join(sorted(found)) or 'none'}")
    if "Arcane.BarStyleData = {" not in data:
        fail("Bar_Styles_Data.lua must own Arcane.BarStyleData")
    if "local THEMES = C.BarStyleData" not in styles:
        fail("Bar_Styles.lua must consume the shared class data, not duplicate it")
    print("PASS: one shared data table owns all nine class palettes")

    if "local Styles = C.BarStyles" not in bar:
        fail("Bar.lua must consume the style controller")
    for contract in ("Styles.Update(dt)", "Styles.Palette()", "Styles.Theme(root.deco, pal)",
                     "Styles.PanelMetal(pal)"):
        if contract not in bar:
            fail(f"Bar.lua is missing style integration: {contract}")
    if "local function Theme(" not in bar:
        fail("Bar.lua must retain one shared rendering theme pass")
    if "C.PanelTheme(root.deco, pal)" in bar:
        fail("Bar.lua must route panel theming through Bar_Styles.lua")
    print("PASS: existing slot/cooldown renderer delegates visual modes to one controller")

    for contract in ("p.railT = Rail(", "p.railB = Rail(", "endLeft = {}",
                     "endLeft = {}", "endRight = {}", "function C.PanelTheme(p, pal)"):
        if contract not in core:
            fail(f"Core panel API is missing shared style support: {contract}")
    for contract in ('StyleChoice(C.BarStyles.CLASSIC, "Arcane"',
                     'StyleChoice(C.BarStyles.HYBRID, "Hybrid"',
                     'StyleChoice(C.BarStyles.FULL_CLASS, "Full class"'):
        if contract not in core:
            fail(f"Arcane options hub is missing a mode choice: {contract}")
    if 'C.LText(styleLabel, "Skill bar style")' not in core:
        fail("Options hub must label the skill-bar style selector")
    if 'panel.endLeft or {}' not in styles or 'PanelHybridArcane.tga' not in styles:
        fail("Hybrid must use its own left Arcane medallion endcap")
    if 'panel.endRight or {}' not in styles:
        fail("Hybrid must reserve the right side for the class crest")
    if "state.db.style = CLASSIC" not in styles:
        fail("Classic Arcane style must remain the default for existing saved variables")
    if 'C.DB("bar")' not in styles:
        fail("Style selection must persist in ArcaneDB.bar")
    print("PASS: shared panel seams, one three-mode selector and persistent Classic default")

    assets = []
    for class_name in CLASSES:
        pretty = class_name[0].upper() + class_name[1:]
        assets.extend((f"PanelEmblem{pretty}L.blp", f"PanelEmblem{pretty}R.blp",
                       f"PanelRail{pretty}T.blp", f"PanelRail{pretty}B.blp"))
    assets.append("PanelGlass.blp")
    for name in assets:
        path = ROOT / "Art" / name
        if not path.is_file():
            fail(f"Missing class-bar art: Art/{name}")
        if path.stat().st_size < 16 or path.read_bytes()[:4] != b"BLP2":
            fail(f"Invalid or empty BLP texture: Art/{name}")
    print(f"PASS: all {len(assets)} class emblems, rails and glass textures are valid BLP2 assets")

    for name in ("PanelHybridArcane.tga", "PanelHybridArcaneGem.tga"):
        path = ROOT / "Art" / name
        if not path.is_file():
            fail(f"Missing Hybrid Arcane medallion art: Art/{name}")
        header = path.read_bytes()[:18]
        if (len(header) != 18 or header[2] != 10
                or int.from_bytes(header[12:14], "little") != 128
                or int.from_bytes(header[14:16], "little") != 128
                or header[16] != 32 or (header[17] & 0x0F) != 8):
            fail(f"Hybrid medallion texture must be 128x128 32-bit alpha RLE TGA: Art/{name}")
    print("PASS: dedicated Hybrid Arcane medallion and class-tinted gem are valid 32-bit alpha TGAs")

    for name in ("Core.lua", "Bar.lua", "Bar_Styles.lua", "Bar_Styles_Data.lua"):
        count = count_chunk_level_locals(source(name))
        if count >= 180:
            fail(f"{name} has {count} file-scope locals; keep a safety margin below Lua's 200 limit")
        print(f"PASS: {name} has {count} file-scope locals (safety ceiling: 179)")
    print("PASS: Arcane skill-bar style architecture audit complete")


if __name__ == "__main__":
    main()
