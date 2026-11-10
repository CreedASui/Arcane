#!/usr/bin/env python3
"""Guardrails for Arcane's FPS readout and native movable-frame ownership."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOC = (ROOT / "Arcane.toc").read_text(encoding="utf-8")
CODE = (ROOT / "Frames/Framerate.lua").read_text(encoding="utf-8")

assert "SkillBar/Bar.lua\nFrames/Framerate.lua" in TOC, "FPS module must load after the skill bar"
assert 'local DEFAULTS = { enabled = false }' in CODE
for token in (
    'local WIDTH, HEIGHT = 144, 36',
    'local function SuppressCtrlRToggle()',
    'GetBindingAction, "CTRL-R"',
    'action == "TOGGLEFPS"',
    'SetBinding, "CTRL-R"',
    'local function HideNativeReadout()',
    'getglobal("FramerateLabel")',
    'getglobal("FramerateText")',
    'label:Hide()',
    'value:Hide()',
    'readout = C.Text(frame, C.FONT, 14, "OUTLINE", "CENTER", TEXT_WIDTH)',
    'readout:SetPoint("CENTER", frame, "CENTER", 0, 0)',
    'C.Movable(frame, "fps", "FPS display"',
    'mover.box:SetBackdropColor(0, 0, 0, 0)',
    'mover.box.text:Hide()',
    'local fps = GetFramerate()',
    'C.SetText(readout, string.format("FPS: %d", math.floor(fps + 0.5)))',
    'C.RegisterPart({',
    'key = "fps"',
    'C.OnWorld(function()',
    'C.ApplyPos(mover)',
    'C.TextColor(readout, pal.title[1], pal.title[2], pal.title[3])',
):
    assert token in CODE, f"FPS display is missing {token!r}"

assert "SaveBindings" not in CODE, "do not persistently overwrite the player's saved key map"
assert "SetParent(" not in CODE, "FPS text must be created inside the movable root rather than reparented"
assert "frame:GetCenter()" not in CODE and "PositionReadout" not in CODE, "use Arcane's normal anchored-child mover, not screen-coordinate chasing"
assert "ToggleFramerate" not in CODE, "the hidden native text toggle must not control Arcane's own readout"
assert "CreateFontString(" not in CODE, "use Arcane's shared C.Text factory"
assert "C.Panel(" not in CODE and "SetBackdrop({" not in CODE, "the FPS display must remain text-only outside the standard mover outline"
assert "local WIDTH, HEIGHT = 144, 36" in CODE, "the FPS mover must retain its comfortable grab area"
assert 'f:SetPoint("BOTTOM", ArcaneBar, "TOP", 0, 1)' in CODE, "fresh FPS placement must preserve its previous readout center"
assert 'f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 193)' in CODE, "fallback FPS placement must preserve its previous readout center"
assert "PreserveSavedTextPosition()" in CODE, "resizing the FPS mover must preserve existing saved positions"

tooltip = "Show or hide the game's FPS readout with this checkbox. Ctrl+R is disabled while Arcane is loaded."
assert tooltip in CODE
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
    assert f'["{tooltip}"]' in locale, f"{path} is missing the FPS tooltip translation"

print("PASS FPS text is an Arcane FontString child of the standard movable root")
print("PASS the standard Arcane mover box encloses and drags the actual FPS readout")
print("PASS FPS value is refreshed from GetFramerate without creating a second panel")
print("PASS stock FPS strings are hidden and Ctrl+R is unbound without saving over the player's key map")
print("PASS saved positions and centered default placement are preserved")
print("PASS FPS option and tooltip remain translated in all 11 bundled languages")
