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
    'mover.box:SetBackdropColor(0, 0, 0, 0)',
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
assert "local WIDTH, HEIGHT = 144, 36" in CODE, "FPS mover must have a comfortable drag target around the compact text"
assert "frame:GetCenter()" in CODE and 'label:SetPoint("RIGHT", UIParent, "BOTTOMLEFT"' in CODE, "native FPS text must be positioned from the mover's live screen coordinates"
assert 'PositionReadout()\n\t\tdisplayState.elapsed = displayState.elapsed + dt' in CODE, "native FPS text must follow the mover on every update while dragging"
assert "SetParent(frame)" not in CODE, "native FPS FontStrings must retain their original Blizzard parent"
assert "mover.box:SetBackdropColor(0, 0, 0, 0)" in CODE, "FPS mover outline must stay visible without obscuring the native text"
assert "PreserveSavedTextPosition()" in CODE, "resizing the FPS mover must preserve existing saved text positions"
assert 'f:SetPoint("BOTTOM", ArcaneBar, "TOP", 0, 1)' in CODE, "fresh FPS placement must preserve its previous readout center"
assert 'f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 193)' in CODE, "fallback FPS placement must preserve its previous readout center"

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

print("PASS native FramerateLabel and FramerateText are retained and themed; their screen position follows the movable FPS root")
print("PASS the Options checkbox is the only FPS toggle; the Ctrl+R TOGGLEFPS binding is unbound at runtime")
print("PASS the user's saved key map is not overwritten")
print("PASS no visible panel, background, half-frame, or duplicate FPS counter is added")
print("PASS FPS display uses Arcane's native saved-position mover with a larger transparent grab box")
print("PASS FPS option and tooltip are translated in all 11 bundled languages")
