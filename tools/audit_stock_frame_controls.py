#!/usr/bin/env python3
"""Static checks for Arcane's reversible, themed stock error-frame controls."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

def fail(message: str) -> None:
    print("FAIL:", message, file=sys.stderr)
    raise SystemExit(1)

toc = [line.strip() for line in (ROOT / "Arcane.toc").read_text(encoding="utf-8").splitlines()
       if line.strip() and not line.lstrip().startswith("#")]
name = "Frames/StockErrors.lua"
if name not in toc or not (ROOT / name).is_file():
    fail("the stock error-frame control module must exist and load from Arcane.toc")

code = (ROOT / name).read_text(encoding="utf-8")
contracts = (
    ('local DEFAULTS = { enabled = true }', "stock error messages must remain visible by default"),
    ('C.Movable(frame, "stockErrors", "Stock error messages"', "the stock frame must use Arcane's native mover"),
    ('C.HideStock("UIErrorsFrame")', "the off state must hide the stock frame through Arcane's stock-frame helper"),
    ('C.RestoreStock("UIErrorsFrame")', "the on state must restore the stock frame"),
    ('C.OnWorld(function()', "the saved visibility state must be reapplied on world entry"),
    ('C.RegisterPart({', "the visibility switch must appear in Arcane's own Options hub"),
    ('key = "errors"', "the stock frame must have an Arcane part command"),
    ('f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)', "the default position must center near the Move to Begin prompt"),
    ('local nativeAddMessage = frame.AddMessage', "the stock MessageFrame AddMessage method must be preserved"),
    ('frame.AddMessage = function(self, message, red, green, blue, alpha)', "all stock message paths must be recolored at the common AddMessage boundary"),
    ('local title = C.Pal().title', "each new message must resolve the active Arcane UX palette"),
    ('nativeAddMessage(self, message, title[1], title[2], title[3], alpha)', "the original MessageFrame method must receive the active theme color"),
)
for contract, message in contracts:
    if contract not in code:
        fail(message)

if "C.Panel(" in code or "C.PanelTheme(" in code:
    fail("the stock notification feed must remain transparent, without an Arcane panel shell")
if "themeStamp" in code or "ArcaneStockErrorsThemeDriver" in code:
    fail("message colors must read the current palette directly instead of maintaining a separate theme driver")
if 'C.OnLogout(function()' not in code or 'C.RestoreStock("UIErrorsFrame") end' not in code:
    fail("a disabled stock frame must be restored during logout cleanup")
if "UnregisterEvent" in code or 'SetScript("OnEvent"' in code:
    fail("Arcane must not remove or replace the stock frame's event handling")
if "SetFont(" in code or "SetText(" in code:
    fail("Arcane must leave stock message text and font behavior unchanged")

luck = (ROOT / "Windows/Luck.lua").read_text(encoding="utf-8")
meter = (ROOT / "Windows/Meter.lua").read_text(encoding="utf-8")
stats = (ROOT / "Windows/Stats.lua").read_text(encoding="utf-8")
movement = (ROOT / "Core/Movement.lua").read_text(encoding="utf-8")
if 'f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -58, 60)' not in luck:
    fail("Luck must retain its original bottom-right default position")
if 'f:SetPoint("BOTTOMRIGHT", ArcaneLuck, "TOPRIGHT", 0, 8)' not in meter:
    fail("Damage meter must retain its original position directly above Luck")
if 'f:SetPoint("BOTTOMRIGHT", meter, "TOPRIGHT", 0, 14)' not in stats:
    fail("Stats must be the only window newly anchored above the right-side Damage meter")
if 'f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -58, 282)' not in meter:
    fail("Damage meter fallback position must retain its original right-side anchor")
if "for pass = 1, 2 do" not in movement:
    fail("Reset positions must reapply dependent default anchors so stacked windows settle together")
if movement.index("if C.timerReset then C.timerReset() end") > movement.index("for pass = 1, 2 do"):
    fail("the boss timer must reset before dependent frame anchors are reapplied")

print("PASS: stock error frame has a reversible Arcane Options toggle")
print("PASS: stock error frame uses Arcane's Move frames position system")
print("PASS: stock notification text uses the active Arcane UX palette without a panel shell")
print("PASS: original message text, routing, font and display behavior remain unchanged")
print("PASS: Luck and Damage meter keep their original right-side defaults; only Stats is added above the meter")
