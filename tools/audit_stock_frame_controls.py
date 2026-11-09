#!/usr/bin/env python3
"""Static checks for Arcane's reversible stock error-frame controls."""
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
    ('C.OnWorld(Apply)', "the saved visibility state must be reapplied on world entry"),
    ('C.RegisterPart({', "the visibility switch must appear in Arcane's own Options hub"),
    ('key = "errors"', "the stock frame must have an Arcane part command"),
    ('f:SetPoint("TOP", bosses, "BOTTOM", 0, -22)', "the default position must sit immediately beneath Arcane's boss and mini-boss stack"),
)
for contract, message in contracts:
    if contract not in code:
        fail(message)

if 'getglobal("ArcaneBosses")' not in code or 'f:SetPoint("TOP", UIParent, "TOP", 0, -122)' not in code:
    fail("the stock frame must use Arcane's boss stack as its default anchor, with a safe fallback")
if 'C.OnLogout(function()' not in code or 'C.RestoreStock("UIErrorsFrame") end' not in code:
    fail("a disabled stock frame must be restored during logout cleanup")
if "UnregisterEvent" in code or 'SetScript("OnEvent"' in code:
    fail("Arcane must not remove or replace the stock frame's event handling")

# Preserve the existing right-side Damage meter/Luck defaults; only Stats is
# newly stacked above the meter. Reset must settle dependent anchors together.
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
print("PASS: stock error frame defaults beneath Arcane's boss bars; original event handling is untouched")
print("PASS: Luck and Damage meter keep their original right-side defaults; only Stats is added above the meter")
