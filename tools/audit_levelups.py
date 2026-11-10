#!/usr/bin/env python3
"""Regression checks for the Arcane/native Store Level-Ups setting bridge."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "Frames/LevelUps.lua").read_text(encoding="utf-8")


def fail(message: str) -> None:
    print("FAIL:", message, file=sys.stderr)
    raise SystemExit(1)


required = (
    ("local function NativeStoring()", "the native setting must have one shared reader"),
    ("C.Call(AZS_IsStoringLevels)", "the game setting must be read through its public getter"),
    ("C.Call(AZS_SetStoringLevels, requested)", "the Arcane switch must call the native setting setter"),
    ('f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 276)', "the stored-level button must default to the clear tested height above the skill bar"),
    ("local function SyncStoring(refreshHub)", "external native setting changes must be synchronized"),
    ("if refreshHub and C.RefreshHub then C.RefreshHub() end", "the open Arcane hub must refresh when the native setting changes"),
    ("if actual ~= nil then db.enabled = actual end", "the native preference must initialize the Arcane switch"),
    ("if actual == nil or actual == db.enabled then return end", "unchanged or unavailable settings must not cause repeated application"),
    ("get = function()\n\t\tif not db then return false end\n\t\tSyncStoring()\n\t\treturn db.enabled", "the hub must read the synchronized setting"),
    ("set = function(on)\n\t\tif db then SetStoring(on) end", "the hub must write the native setting"),
)
for fragment, message in required:
    if fragment not in source:
        fail(message)

driver = source.find('driver:SetScript("OnUpdate", function()')
sync = source.find("SyncStoring(true)", driver)
guard = source.find("if not db.enabled then return end", driver)
step = source.find("local ok, err = pcall(Step, dt, GetTime())", driver)
if min(driver, sync, guard, step) < 0 or not (driver < sync < guard < step):
    fail("the live native preference must sync before the driver decides whether the replacement runs")

if "and not C.Call(AZS_IsStoringLevels)" in source:
    fail("do not treat numeric zero as true when checking the native setting")

print("PASS: Arcane switch reads the native Store Level-Ups preference")
print("PASS: Arcane switch calls AZS_SetStoringLevels")
print("PASS: native Options changes are reflected back into Arcane")
print("PASS: the replacement/native HUD ownership follows the synchronized setting")
