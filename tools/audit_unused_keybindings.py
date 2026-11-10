#!/usr/bin/env python3
"""Regression checks for suppressing the unused Azeroth Survivors world-map key."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "Core/Startup.lua").read_text(encoding="utf-8")


def fail(message: str) -> None:
    print("FAIL:", message, file=sys.stderr)
    raise SystemExit(1)


required = (
    ("local function RemoveUnusedWorldMapKey()", "the unused world-map key must have a named startup guard"),
    ('pcall(GetBindingAction, "M")', "the current M binding must be inspected before changing it"),
    ('action ~= "TOGGLEWORLDMAP"', "only the stock world-map action may be suppressed"),
    ('pcall(SetBinding, "M")', "the M key must be unbound only when it opens the stock world map"),
    ("C.OnWorld(RemoveUnusedWorldMapKey)", "the binding guard must run on world entry"),
)
for fragment, message in required:
    if fragment not in source:
        fail(message)

start = source.find("local function RemoveUnusedWorldMapKey()")
end = source.find("C.OnWorld(RemoveUnusedWorldMapKey)", start)
body = source[start:end]
if "SaveBindings" in source:
    fail("Arcane must not persistently overwrite the player's saved key configuration")
if body.find('GetBindingAction, "M"') > body.find('SetBinding, "M"'):
    fail("the map key action must be checked before unbinding")
if 'action ~= "TOGGLEWORLDMAP"' not in body:
    fail("custom M bindings must be left untouched")

print("PASS: M is suppressed only when it opens the stock world map")
print("PASS: custom M bindings and the saved key configuration are preserved")
