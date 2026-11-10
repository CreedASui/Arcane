#!/usr/bin/env python3
"""Static guardrails for floating combat-text styling and untouched zone announcements."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOC = (ROOT / "Arcane.toc").read_text(encoding="utf-8")
THEME = (ROOT / "Frames" / "NativeText.lua").read_text(encoding="utf-8")
STOCK = (ROOT / "Frames" / "StockErrors.lua").read_text(encoding="utf-8")
ARCH = (ROOT / "docs" / "ARCHITECTURE.md").read_text(encoding="utf-8")

assert "Frames/StockErrors.lua\nFrames/NativeText.lua" in TOC

for token in (
    '"SPELL_CAST"',
    '"AURA_START"',
    '"AURA_END"',
    '"HEAL"',
    '"HEAL_CRIT"',
    '"PERIODIC_HEAL"',
    "COMBAT_TEXT_TYPE_INFO",
    "SetCombatColor(info, AURA_TYPES[i], pal.title)",
    "SetCombatColor(info, HEAL_TYPES[i], pal.mc)",
    "local pal = C.Pal()",
    "C.SetFace(fs, face, size, \"OUTLINE\")",
    'getglobal("CombatText" .. i)',
    'watch:RegisterEvent("ADDON_LOADED")',
):
    assert token in THEME, f"Floating combat-text theme is missing {token!r}"

# Zone/subzone announcements must remain entirely Blizzard-owned.
for forbidden in (
    "ZoneTextString",
    "SubZoneTextString",
    "ZoneTextFrame",
    "SubZoneTextFrame",
    "SetZoneText",
    "ZoneFadeInDuration",
    "ZoneHoldDuration",
    "ZoneFadeOutDuration",
    "CreateFontString",
    "STROKE_OFFSETS",
    "FrameL",
    "FrameM",
    "FrameR",
    "CRIMSON_",
    "BANNER_HEIGHT",
):
    assert forbidden not in THEME, f"Zone announcement code must not be present: {forbidden!r}"

# Keep native floating message creation, event handling, filters and animation untouched.
for forbidden in (
    "CombatText_AddMessage =",
    "CombatText_OnEvent =",
    "COMBAT_TEXT_SCROLLSPEED =",
    "COMBAT_TEXT_FADEOUT_TIME =",
    "CombatText_OnUpdate =",
):
    assert forbidden not in THEME, f"Native combat-text behavior must not be replaced: {forbidden!r}"

# The known-good gameplay notification treatment from the user's reference ZIP stays active.
for token in (
    "local function ThemeFont(frame)",
    "ThemeFont(self)",
    "local title = C.Pal().title",
    "nativeAddMessage(self, message, title[1], title[2], title[3], alpha)",
):
    assert token in STOCK, f"Stock gameplay notification theme is missing {token!r}"

assert "Zone and subzone announcements remain entirely native" in ARCH

print("PASS positive aura/cast and heal text use the known-good Arcane palette mapping")
print("PASS Blizzard's floating message creation, filtering, movement and fade remain native")
print("PASS NativeText.lua does not hook, move, recolor or decorate zone announcements")
print("PASS stock gameplay notices retain the known-good Arcane font and color treatment")
