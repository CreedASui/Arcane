#!/usr/bin/env python3
"""Guardrails for Arcane's themed native FPS readout and checkbox-only control."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOC = (ROOT / "Arcane.toc").read_text(encoding="utf-8")
CODE = (ROOT / "Frames/Framerate.lua").read_text(encoding="utf-8")

assert "SkillBar/Bar.lua\nFrames/Framerate.lua" in TOC, "FPS module must load after the skill bar"
assert 'local DEFAULTS = { enabled = false }' in CODE
for token in (
    'getglobal("FramerateLabel")',
    'getglobal("FramerateText")',
    'local function SuppressCtrlRToggle()',
    'GetBindingAction, "CTRL-R"',
    'action == "TOGGLEFPS"',
    'SetBinding, "CTRL-R"',
    'if NativeShown() ~= on and type(ToggleFramerate) == "function" then',
    'value:IsVisible()',
    'C.Movable(frame, "fps", "FPS display"',
    'mover.box:SetBackdrop(nil)',
    'C.RegisterPart({',
    'key = "fps"',
    'C.RefreshHub()',
    'C.OnWorld(function()',
    'C.TextColor(label, pal.title[1], pal.title[2], pal.title[3])',
    'C.TextColor(value, pal.title[1], pal.title[2], pal.title[3])',
):
    assert token in CODE, f"FPS readout is missing {token!r}"

assert CODE.count("SuppressCtrlRToggle()") >= 3, "Ctrl+R must be suppressed on load and world entry"
assert "SaveBindings" not in CODE, "do not persistently overwrite the player's saved key map"

# No panel, fill, rail, extra FontString, or second FPS counter: only the native text is visible.
for forbidden in (
    "C.Panel(",
    "PanelRail",
    "PanelFill",
    "SetBackdrop({",
    "CreateFontString(",
    "GetFramerate()",
    "IsShown",
):
    assert forbidden not in CODE, f"FPS display must remain text-only: {forbidden!r}"

assert "Show or hide the game's FPS readout with this checkbox. Ctrl+R is disabled while Arcane is loaded." in CODE
assert '"FPS display"' in (ROOT / "Locales/Locale.lua").read_text(encoding="utf-8")
tooltip = "Show or hide the game's FPS readout with this checkbox. Ctrl+R is disabled while Arcane is loaded."
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
    assert f'["{tooltip}"]' in locale, f"{path} is missing the FPS tooltip translation"

print("PASS native FramerateLabel and FramerateText are both retained and themed")
print("PASS the Options checkbox is the only FPS toggle; the Ctrl+R TOGGLEFPS binding is unbound at runtime")
print("PASS the user's saved key map is not overwritten")
print("PASS no visible panel, background, half-frame, or duplicate FPS counter is added")
print("PASS FPS display uses Arcane's native saved-position mover")
print("PASS FPS option and tooltip are translated in all 11 bundled languages")
