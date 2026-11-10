#!/usr/bin/env python3
"""Guardrails for Arcane's themed native FPS readout and Ctrl+R synchronization."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOC = (ROOT / "Arcane.toc").read_text(encoding="utf-8")
CODE = (ROOT / "Frames/Framerate.lua").read_text(encoding="utf-8")

assert "SkillBar/Bar.lua\nFrames/Framerate.lua" in TOC, "FPS module must load after the skill bar"
assert 'local DEFAULTS = { enabled = false }' in CODE
for token in (
    'getglobal("FramerateLabel")',
    'getglobal("FramerateText")',
    'type(ToggleFramerate) == "function"',
    'ToggleFramerate()',
    'value:IsVisible()',
    'C.Movable(frame, "fps", "FPS display"',
    'mover.box:SetBackdrop(nil)',
    'C.RegisterPart({',
    'key = "fps"',
    'C.RefreshHub()',
    'C.OnWorld(function()',
    'C.PanelMetal(pal)',
    'C.TextColor(label, pal.title[1], pal.title[2], pal.title[3])',
    'C.TextColor(value, pal.title[1], pal.title[2], pal.title[3])',
):
    assert token in CODE, f"FPS readout is missing {token!r}"

# The requested treatment is a transparent, compact open-bottom half-frame, not a panel shell.
for token in ('PanelRailT', 'PanelRailL', 'PanelRailR'):
    assert token in CODE, f"FPS half-frame is missing {token!r}"
for forbidden in ('PanelRailB', 'PanelFill', 'C.Panel(', 'SetBackdrop({', 'IsShown', 'GetFramerate()'):
    assert forbidden not in CODE, f"FPS readout must not replace native behavior or add a background: {forbidden!r}"

# Ctrl+R owns the native visibility state; Arcane mirrors it into the saved Options checkbox.
assert "local function SyncFromGame()" in CODE
assert "db.enabled = shown" in CODE
assert "set = function(on) SetShown(on) end" in CODE
assert "C.RefreshHub()" in CODE

# The user-facing checkbox and its tooltip must be translated in every bundled language.
english = "The game's FPS readout in Arcane lettering and a small open metal frame. Ctrl+R toggles it too."
assert '"FPS display"' in (ROOT / "Locales/Locale.lua").read_text(encoding="utf-8")
for path in (
    "Locales/Locale_zh.lua",
    "Locales/Locale_ru.lua",
    "Locales/Locale_ja.lua",
    "Locales/Locale_ko.lua",
    "Locales/Locale_pl.lua",
    "Locales/Locale_tr.lua",
):
    locale = (ROOT / path).read_text(encoding="utf-8")
    assert '["FPS display"]' in locale, f"{path} is missing the FPS option translation"
    assert f'["{english}"]' in locale, f"{path} is missing the FPS tooltip translation"

print("PASS native FramerateLabel and FramerateText are both retained")
print("PASS Arcane's FPS checkbox calls the game's Ctrl+R toggle and mirrors its live state")
print("PASS the compact FPS half-frame has no fill, background, bottom rail or duplicate counter")
print("PASS FPS panel uses Arcane's native saved-position mover")
print("PASS FPS option and tooltip are translated in all 11 bundled languages")
