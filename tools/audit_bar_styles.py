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


def validate_tga_rle_32(path: Path) -> None:
    """Fully decode row-bounded 32-bit alpha RLE TGA data used by Hybrid."""
    data = path.read_bytes()
    if len(data) < 18:
        fail(f"Hybrid TGA is truncated: Art/{path.name}")
    header = data[:18]
    width = int.from_bytes(header[12:14], "little")
    height = int.from_bytes(header[14:16], "little")
    if (header[1] != 0 or header[2] != 10 or width != 512 or height != 512
            or header[16] != 32 or (header[17] & 0x0F) != 8
            or (header[17] & 0x20) == 0):
        fail(f"Hybrid texture must be top-origin 512x512 32-bit alpha RLE TGA: Art/{path.name}")
    offset = 18 + header[0]
    alpha_pixels = 0
    for _row in range(height):
        row_pixels = 0
        while row_pixels < width:
            if offset >= len(data):
                fail(f"Hybrid TGA RLE data ends early: Art/{path.name}")
            packet = data[offset]
            offset += 1
            count = (packet & 0x7F) + 1
            if row_pixels + count > width:
                fail(f"Hybrid TGA RLE packet crosses a row: Art/{path.name}")
            if packet & 0x80:
                if offset + 4 > len(data):
                    fail(f"Hybrid TGA RLE run is truncated: Art/{path.name}")
                alpha_pixels += count if data[offset + 3] else 0
                offset += 4
            else:
                byte_count = count * 4
                if offset + byte_count > len(data):
                    fail(f"Hybrid TGA raw packet is truncated: Art/{path.name}")
                alpha_pixels += sum(1 for i in range(offset + 3, offset + byte_count, 4)
                                    if data[i])
                offset += byte_count
            row_pixels += count
    if offset != len(data):
        fail(f"Hybrid TGA has unexpected trailing bytes: Art/{path.name}")
    if alpha_pixels == 0:
        fail(f"Hybrid TGA has no visible pixels: Art/{path.name}")


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
    generator = source("tools/build_hybrid_medallion_variants.py")
    for class_name in ("Warrior", "Paladin", "Rogue", "Priest", "Shaman", "Mage", "Warlock"):
        if f'"{class_name}"' not in generator:
            fail(f"Hybrid variant generator is missing the {class_name} palette output")

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
        fail("Hybrid must use the approved high-resolution Arcane medallion on the left")
    if 'PanelHybridArcaneGem.tga' not in styles:
        fail("Hybrid must retain a separate tintable gemstone layer")
    for class_name in ("warrior", "paladin", "rogue", "priest", "shaman", "mage", "warlock"):
        if f'key == "{class_name}"' not in styles:
            fail(f"Hybrid medallion selector is missing the {class_name} class route")
        pretty = class_name[0].upper() + class_name[1:]
        if f"PanelHybridArcane{pretty}.tga" not in styles:
            fail(f"Hybrid medallion selector is missing the {pretty} texture")
    if 'SetPoint("CENTER", frame, "LEFT", HYBRID_CENTER_X, HYBRID_CENTER_Y)' not in styles:
        fail("Hybrid Arcane medallion must be centered on the left panel edge")
    if 'C.Vis(panel.sigils[1], false)' not in styles or 'C.Vis(panel.sigils[2], false)' not in styles:
        fail("Hybrid must hide both stock Arcane sigils beneath its custom left medallion and right class crest")
    if 'PlaceEmblem(panel.classEmblems[2], panel.frame, "RIGHT", theme.emblem)' not in styles:
        fail("Hybrid must place the active class emblem on the right")
    if 'panel.hybridGem:SetVertexColor(theme.gem[1], theme.gem[2], theme.gem[3], 1)' not in styles:
        fail("Hybrid Arcane gemstone must use the active class gem color")
    if 'panel.classGems[i]:SetVertexColor(theme.gem[1], theme.gem[2], theme.gem[3], 1)' not in styles:
        fail("Hybrid center diamonds must use the active class gem color")
    if 'table.insert(root.deco.classGems, d)' not in bar:
        fail("Bar.lua must register the two center diamonds for class coloring")
    if 'panel.endLeft or {}' not in styles or 'panel.endRight or {}' in styles:
        fail("Hybrid must replace only the left panel end and preserve the complete right endcap beneath the class crest")
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
    assets.extend(("PanelGlass.blp", "PanelSigil.blp"))
    for name in assets:
        path = ROOT / "Art" / name
        if not path.is_file():
            fail(f"Missing class-bar art: Art/{name}")
        if path.stat().st_size < 16 or path.read_bytes()[:4] != b"BLP2":
            fail(f"Invalid or empty BLP texture: Art/{name}")
    print(f"PASS: all {len(assets)} class emblems, rails, glass and Classic sigil textures are valid BLP2 assets")

    for name in ("PanelHybridArcane.tga", "PanelHybridArcaneGem.tga",
                 "PanelHybridArcaneWarrior.tga", "PanelHybridArcanePaladin.tga",
                 "PanelHybridArcaneRogue.tga", "PanelHybridArcanePriest.tga",
                 "PanelHybridArcaneShaman.tga", "PanelHybridArcaneMage.tga",
                 "PanelHybridArcaneWarlock.tga"):
        path = ROOT / "Art" / name
        if not path.is_file():
            fail(f"Missing Hybrid Arcane art: Art/{name}")
        validate_tga_rle_32(path)
    print("PASS: all nine Hybrid base/gem/class medallion textures fully decode as 512x512 alpha TGAs")

    for name in ("Core.lua", "Bar.lua", "Bar_Styles.lua", "Bar_Styles_Data.lua"):
        count = count_chunk_level_locals(source(name))
        if count >= 180:
            fail(f"{name} has {count} file-scope locals; keep a safety margin below Lua's 200 limit")
        print(f"PASS: {name} has {count} file-scope locals (safety ceiling: 179)")
    print("PASS: Arcane skill-bar style architecture audit complete")


if __name__ == "__main__":
    main()
