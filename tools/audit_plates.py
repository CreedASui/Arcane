#!/usr/bin/env python3
"""Static ownership and regression guards for the Tiny Plates subsystem."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
TOC = (ROOT / "Arcane.toc").read_text(encoding="utf-8")
PLATE_FILES = [
    "Plates/State.lua",
    "Plates/SpecialTargets.lua",
    "Plates/Visuals.lua",
    "Plates/ArcanePlates.lua",
    "Plates/ArcanePlatesOptions.lua",
]
sources = {name: (ROOT / name).read_text(encoding="utf-8") for name in PLATE_FILES}

def require(condition, message):
    if not condition:
        raise SystemExit("Tiny Plates audit failed: " + message)

positions = [TOC.find(name) for name in PLATE_FILES]
require(all(pos >= 0 for pos in positions), "all plate modules must be listed in Arcane.toc")
require(positions == sorted(positions), "plate dependency/load order is incorrect")
require(TOC.find("Core/Bars.lua") < positions[0], "shared Core bar renderer must load before Tiny Plates")

state = sources["Plates/State.lua"]
special = sources["Plates/SpecialTargets.lua"]
visuals = sources["Plates/Visuals.lua"]
controller = sources["Plates/ArcanePlates.lua"]
options = sources["Plates/ArcanePlatesOptions.lua"]

require("CapturePoints" not in state and "RestorePoints" not in state,
        "Tiny Plates must not snapshot or restore game-owned WorldFrame anchors")
require("frame:SetPoint(" not in state and "frame:ClearAllPoints()" not in state,
        "native restoration must not reposition the moving WorldFrame plate")
require("SaveObjectState" in state and "object ~= plate" in state,
        "native state snapshots must not own plate visibility")
require('if state.shown then object:Show() else object:Hide() end' in state,
        "captured child visibility must be restored exactly")
require("if state.shown then frame:Show()" not in state,
        "restoration must never re-show a pooled root nameplate")
require("arcanePlatesNativeWidth" not in state
        and "arcanePlatesNativeScale" not in state
        and "arcanePlatesNativePoints" not in state,
        "native restoration must not restore stale root geometry")
require("regions[i]:Show()" not in state and "children[i]:Show()" not in state
        and "SetAlpha(1)" not in state,
        "do not use blanket show/alpha restoration when native state is unknown")
require("frame.arcanePlatesSourceBar = nil" in state
        and "frame.arcanePlatesStyledVisual = nil" in state,
        "recycled plates must discard stale native-child references")
require("bossGuardianNames = {}" in special and "bossGuardianUnitsByName = {}" in special,
        "boss identity indexes must be rebuilt together")
require("debuffCache[unitID]" in special,
        "fallback debuff API reads must be cached by unit")
require("runTimeRead" in special,
        "run time should be queried at most once per plate update")
require("local function ContainsStatusBar" not in visuals,
        "recursive status-bar search must have one implementation")
require("P.State.RegisterPlate" in controller and "P.Visuals.Apply(frame)" in controller,
        "controller must delegate registration and presentation to their owning modules")
require(re.search(r"if P\.Visuals\.Apply\(frame\) then[\s\S]+?frame\.arcanePlatesStyleRevision = styleRevision", controller) is not None,
        "style revision must be recorded only after application succeeds")
require('CreateFrame("Frame", "ArcanePlatesOptions", parent or UIParent)' in options,
        "the settings panel must inherit visibility through its parent frame instead of replacing parent scripts")
require("HasStatusBar" not in state,
        "duplicate HasStatusBar helper should be consolidated into ContainsStatusBar")


require("arcanePlatesStackOriginalWidth" not in visuals
        and "arcanePlatesStackPoint" not in visuals
        and "frame:ClearAllPoints()" not in visuals,
        "Tiny Plates visuals must not rewrite game-owned plate root geometry")

require('P.Option("hideShrunkPlates")' not in controller
        and 'd["hideShrunkPlates"] = nil' in controller
        and "hideShrunkPlates" not in visuals
        and "hideShrunkPlates" not in options,
        "Tiny Plates must not have a second hide switch; only clear the retired saved key")
require("Hide regular plates" not in options,
        "the settings panel must not offer a fake stock-plate fallback")
require("C.RegisterPart" not in controller and "SetEnabled" not in controller
        and "local active" not in controller,
        "Tiny Plates is a required Arcane renderer, not a separately toggleable part")
require("C.NewBar(frame, width, height, true)" in visuals
        and "frame.arcanePlatesOverlay = bar.frame" in visuals,
        "the Arcane replacement bar must remain a child of the native plate so V visibility is inherited")
require("frame.arcanePlatesHiddenByOption" not in controller
        and "frame.arcanePlatesHiddenByOption" not in visuals,
        "retired per-option plate masking state must be removed")
require("local oldOnHide = parent:GetScript" not in options,
        "the options panel should rely on parent-child visibility, not replace the hub OnHide script")
require("frame.arcanePlatesHealthTextValue" in visuals
        and "frame.arcanePlatesHealthTextMaximum" in visuals,
        "health numbers should only be reformatted when the health values change")
require("width >= 20 and height >= 3 and width >= height * 2" in state
        and "P.State.IsHealthStatusBar(children[i])" in visuals,
        "discovery and rendering must use the same plausible horizontal health-bar signature")
require('if frame:GetObjectType() ~= "Button" then return false end' in state
        and 'if objectType ~= "Button" then return end' in controller,
        "only the game's native WorldFrame plate buttons should enter the registry")
require("local fresh = {}" in state
        and "frame.arcanePlatesNativeState = fresh" in state,
        "recycled plate snapshots must replace stale child references instead of growing forever")
require("C.OnLogout(function() RestoreAll() end)" in controller,
        "native plate state must still be restored on logout")
require("C.NewBar(frame, width, height, true)" in visuals,
        "Tiny Plates must continue using Arcane's shared bar renderer")
require("SetBinding" not in controller and "SetBinding" not in visuals,
        "Tiny Plates must not replace or intercept the game's V key binding")
require("reuses free pool slots" in controller,
        "the registry lifecycle must document the game's native bounded frame pool")

print("Tiny Plates ownership and regression audits passed.")
