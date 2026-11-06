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


def validate_rle_tga(path: Path) -> None:
    """Validate the complete row-safe 32-bit RLE TGA stream, not just its header."""
    data = path.read_bytes()
    if len(data) < 18:
        fail(f"Hybrid medallion texture is truncated: Art/{path.name}")
    header = data[:18]
    width = int.from_bytes(header[12:14], "little")
    height = int.from_bytes(header[14:16], "little")
    if (header[1] != 0 or header[2] != 10 or width != 128 or height != 128
            or header[16] != 32 or (header[17] & 0x0F) != 8
            or (header[17] & 0x20) == 0):
        fail(f"Hybrid medallion texture must be top-origin 128x128 32-bit alpha RLE TGA: Art/{path.name}")
    offset = 18 + header[0]
    for _row in range(height):
        row_pixels = 0
        while row_pixels < width:
            if offset >= len(data):
                fail(f"Hybrid medallion TGA RLE data ends early: Art/{path.name}")
            packet = data[offset]
            offset += 1
            count = (packet & 0x7F) + 1
            if row_pixels + count > width:
                fail(f"Hybrid medallion TGA RLE packet crosses a row: Art/{path.name}")
            byte_count = 4 if packet & 0x80 else count * 4
            if offset + byte_count > len(data):
                fail(f"Hybrid medallion TGA RLE packet is truncated: Art/{path.name}")
            offset += byte_count
            row_pixels += count
    if offset != len(data):
        fail(f"Hybrid medallion TGA has unexpected trailing data: Art/{path.name}")


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
    if 'SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -HYBRID_OUT, -HYBRID_FOOT)' not in styles:
        fail("Hybrid Arcane medallion must be anchored on the left")
    if 'PlaceEmblem(panel.classEmblems[2], panel.frame, "RIGHT", theme.emblem)' not in styles:
        fail("Hybrid must place the active class emblem on the right")
    if 'panel.classGems[i]:SetVertexColor(theme.gem[1], theme.gem[2], theme.gem[3], 1)' not in styles:
        fail("Hybrid center diamonds must use the active class gem color")
    if 'table.insert(root.deco.classGems, d)' not in bar:
        fail("Bar.lua must register the two center diamonds for class coloring")
    if 'panel.endRight or {}' not in styles:
        fail("Hybrid must hide the stock right-end frame beneath the class crest")
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
        validate_rle_tga(path)
    print("PASS: dedicated Hybrid Arcane medallion and class-tinted gem are valid power-of-two 32-bit alpha TGAs")

    for name in ("Core.lua", "Bar.lua", "Bar_Styles.lua", "Bar_Styles_Data.lua"):
        count = count_chunk_level_locals(source(name))
        if count >= 180:
            fail(f"{name} has {count} file-scope locals; keep a safety margin below Lua's 200 limit")
        print(f"PASS: {name} has {count} file-scope locals (safety ceiling: 179)")
    print("PASS: Arcane skill-bar style architecture audit complete")


if __name__ == "__main__":
    main()
