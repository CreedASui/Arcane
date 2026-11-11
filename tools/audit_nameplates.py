#!/usr/bin/env python3
"""Static lifecycle, geometry, text-layout and tooltip guards for Arcane Nameplates."""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
TOC = (ROOT / "Arcane.toc").read_text(encoding="utf-8")
FILES = (
    "Nameplates/State.lua",
    "Nameplates/SpecialTargets.lua",
    "Nameplates/Visuals.lua",
    "Nameplates/ArcaneNameplates.lua",
    "Nameplates/ArcaneNameplatesOptions.lua",
)
SOURCES = {name: (ROOT / name).read_text(encoding="utf-8") for name in FILES}
STATE = SOURCES["Nameplates/State.lua"]
SPECIAL = SOURCES["Nameplates/SpecialTargets.lua"]
VISUALS = SOURCES["Nameplates/Visuals.lua"]
CONTROLLER = SOURCES["Nameplates/ArcaneNameplates.lua"]
OPTIONS = SOURCES["Nameplates/ArcaneNameplatesOptions.lua"]
TOOLTIP = (ROOT / "Frames" / "WorldTooltip.lua").read_text(encoding="utf-8")
CORE_OPTIONS = (ROOT / "Core" / "Options.lua").read_text(encoding="utf-8")
README = (ROOT / "README.md").read_text(encoding="utf-8")
ARCH = README.split("## Architecture and module ownership", 1)[1].split(
    "## Attribution and project provenance", 1
)[0]


def require(condition, message):
    if not condition:
        raise SystemExit("Arcane Nameplates audit failed: " + message)


# Load order and required ownership boundaries.
ORDER = (
    "Nameplates/State.lua",
    "Nameplates/SpecialTargets.lua",
    "Nameplates/Visuals.lua",
    "Nameplates/ArcaneNameplates.lua",
    "Nameplates/ArcaneNameplatesOptions.lua",
)
positions = [TOC.find(path) for path in ORDER]
require(all(position >= 0 for position in positions), "all Nameplates modules must be listed in Arcane.toc")
require(positions == sorted(positions), "Nameplates module dependency order is incorrect")
require(TOC.find("Core/Bars.lua") < positions[0], "the shared Arcane bar renderer must load before Nameplates")
require(TOC.find("Frames/WorldTooltip.lua") >= 0, "the world-hover tooltip guard must be loaded")

# Exact native 1.12 Azeroth Survivors plate contract: anonymous WorldFrame Button,
# six root regions in fixed creation order, and one direct horizontal StatusBar child.
for token in (
    'frame:GetObjectType() ~= "Button"',
    "frame:GetName() ~= nil",
    "local regions = { frame:GetRegions() }",
    "table.getn(regions) ~= 6",
    "local children = { frame:GetChildren() }",
    "table.getn(children) ~= 1",
    'regions[1]:GetObjectType() ~= "Texture"',
    'regions[2]:GetObjectType() ~= "Texture"',
    'regions[3]:GetObjectType() ~= "FontString"',
    'regions[4]:GetObjectType() ~= "FontString"',
    'regions[5]:GetObjectType() ~= "Texture"',
    'regions[6]:GetObjectType() ~= "Texture"',
    "frame.arcaneNameplatesNativeRegions = regions",
    "frame.arcaneNameplatesNativeBar = children[1]",
    "width <= 512",
    "height <= 128",
):
    require(token in STATE, f"exact native plate identification is missing {token!r}")
require("local function GetPlateName(frame)" in STATE and "frame.arcaneNameplatesNameRegion" in STATE,
        "known plate names must be read from the cached native name FontString")
require("local function GetPlateLevel(frame)" in STATE and "frame.arcaneNameplatesLevelRegion" in STATE,
        "known plate levels must be read from the cached native level FontString")
require("local function ContainsStatusBar" not in STATE
        and "local function CollectStatusBars" not in STATE
        and "local function GetPlateName(frame, root)" not in STATE,
        "native plate identification must not recursively search arbitrary children")

# Dynamic native pool handling. Retired plate frames remain cached; reuse is detected from
# OnShow/OnHide and the native name identity, without restoring root visibility or geometry.
for token in (
    'frame:GetScript("OnShow")',
    'frame:GetScript("OnHide")',
    'frame:SetScript("OnShow"',
    'frame:SetScript("OnHide"',
    "if oldOnShow then oldOnShow() end",
    "if oldOnHide then oldOnHide() end",
    "frame.arcaneNameplatesPendingReuse = true",
    "frame.arcaneNameplatesNeedsStyle = true",
    "frame.arcaneNameplatesNameChangedPending = true",
    "RestoreNativeState(frame)",
):
    require(token in STATE, f"pooled plate lifecycle handling is missing {token!r}")
require("if object ~= plate then" in STATE and "if state.shown then object:Show() else object:Hide() end" in STATE,
        "native restoration must restore child state, never the root plate visibility")
require("frame:SetPoint(" not in STATE and "frame:ClearAllPoints()" not in STATE,
        "native restoration must not reposition the projected WorldFrame plate")
require("local function HideNativePresentation(frame)" in STATE,
        "native regions must have one targeted suppression path")
for token in ("regions[3]", "regions[4]", "regions[index]", "frame.arcaneNameplatesNativeBar"):
    require(token in STATE, f"native presentation suppression is missing {token!r}")
require("regions[i]:Show()" not in STATE and "children[i]:Show()" not in STATE
        and "SetAlpha(1)" not in STATE,
        "do not use blanket show/alpha restoration")

# The controller performs one-time structural recognition and processes known cached plate
# objects each update; there must be no half-second discovery delay or recursive frame walk.
require("local checkedWorldChildren = {}" in CONTROLLER,
        "new WorldFrame children must be structurally classified once")
require("local function DiscoverNativePool(children)" in CONTROLLER
        and 'SafeCall("plate discovery", P.State.IdentifyNameplate, frame)' in CONTROLLER,
        "unseen WorldFrame buttons must go through the exact native signature")
require("local function ScanNameplates(updateDebuffs)" in CONTROLLER
        and "return P.State.RegisterPlate(frame, knownPlates, orderedPlates)" in CONTROLLER,
        "known pool entries must refresh their identity and reuse state")
require("ScanNameplates(updateDebuffs)" in CONTROLLER and "scanFrame:SetScript(\"OnUpdate\"" in CONTROLLER,
        "native plate lifecycle must be driven without a half-second timer")
require("SCAN_INTERVAL" not in CONTROLLER and "scanClock" not in CONTROLLER,
        "there must be no arbitrary half-second discovery delay")
require("P.State.HideNativePresentation(frame)" in CONTROLLER,
        "late native level/skull/raid/glow writes must be suppressed after the game updates them")
require("frame.arcaneNameplatesNeedsStyle" in CONTROLLER
        and "frame.arcaneNameplatesNameChangedPending" in CONTROLLER,
        "same-frame plate reuse must trigger replacement styling and boss identity refresh")

# Geometry is based on the cached direct native StatusBar. The replacement is centered
# on the source bar, with bounded dimensions and no root-plate SetPoint/scale mutation.
for token in (
    "frame.arcaneNameplatesNativeBar",
    "local originalWidth, originalHeight = source:GetWidth(), source:GetHeight()",
    "local visualScale = P.Special.IsBossOrGuardianPlate(frame) and 1 or 0.75",
    'overlay:SetPoint("CENTER", source, "CENTER", offsetX, offsetY)',
    "frame.arcaneNameplatesSourceOriginalWidth",
):
    require(token in VISUALS, f"replacement bar geometry is missing {token!r}")
require("FindStyledVisual" not in VISUALS and "CollectStatusBars" not in VISUALS,
        "replacement-bar creation must not recursively search arbitrary visual trees")
require("C.NewBar(frame, width, height, true)" in VISUALS
        and "frame.arcaneNameplatesOverlay = bar.frame" in VISUALS,
        "the Arcane bar must use the shared renderer and remain parented to the native plate")
require("frame:ClearAllPoints()" not in VISUALS and "frame:SetPoint(" not in VISUALS,
        "the WorldFrame plate root geometry remains game-owned")

# Health values must not wrap at whitespace. The font is fitted only inside the bar's inner width.
require('C.Short(hp) .. "/" .. C.Short(hpm)' in VISUALS
        and 'C.Commas(hp) .. "/" .. C.Commas(hpm)' in VISUALS,
        "current/maximum health must have no breakable whitespace around the separator")
require('" / "' not in VISUALS,
        "health text must not reintroduce a whitespace wrap point")
require("local function FitHealthText(frame, width, baseSize)" in VISUALS
        and "text:GetStringWidth()" in VISUALS
        and "while measured > width and size > 6 do" in VISUALS,
        "health text must fit its full measured string to the bar's usable width")
require("frame.arcaneNameplatesOverlayWidth - 8" in VISUALS,
        "health text must have inner padding from the Arcane bar rim")
require("frame.arcaneNameplatesHealthTextValue" in VISUALS
        and "frame.arcaneNameplatesHealthTextMaximum" in VISUALS,
        "health text should be recomputed only when source values change")
require("local size = math.max(16, math.min(20, frame.arcaneNameplatesOverlayHeight + 9))" in VISUALS,
        "the level badge must be sized from the visible bar")

# Keep all existing nameplate compatibility contracts.
require("bossGuardianNames = {}" in SPECIAL and "bossGuardianUnitsByName = {}" in SPECIAL,
        "boss identity indexes must be rebuilt together")
require("debuffCache[unitID]" in SPECIAL and "runTimeRead" in SPECIAL,
        "special-target and debuff fallback queries must remain cached")
require('CreateFrame("Frame", "ArcaneNameplatesOptions", parent or UIParent)' in OPTIONS,
        "the settings frame must continue to inherit visibility from its parent")
for token in (
    "panel:SetMovable(true)",
    "panel:SetClampedToScreen(true)",
    'panel:RegisterForDrag("LeftButton")',
    'panel:SetScript("OnDragStart", function() panel:StartMoving() end)',
    'panel:SetScript("OnDragStop", function() panel:StopMovingOrSizing() end)',
):
    require(token in OPTIONS, f"the Nameplates settings window must support dragging: {token!r}")
require('P.Option("hideShrunkPlates")' not in CONTROLLER
        and 'd["hideShrunkPlates"] = nil' in CONTROLLER
        and "hideShrunkPlates" not in VISUALS + OPTIONS,
        "the retired second hide switch must remain removed")
require("C.RegisterPart" not in CONTROLLER and "SetBinding" not in CONTROLLER + VISUALS,
        "Nameplates remain required and must not intercept the native V key")
require('C.DB("nameplates"' in CONTROLLER and 'C.DB("nameplates"' in OPTIONS,
        "the existing ArcaneDB.nameplates saved-variable contract must remain stable")
require('arg1 ~= "AZSUNITS"' in CONTROLLER and "AZS_UNITS" in SPECIAL,
        "game integration identifiers must remain unchanged")
require("C.ArcaneNameplatesToggleOptions" in CORE_OPTIONS,
        "the options hub must call the canonical Arcane entry point")

# World-hover information is the native default-anchored GameTooltip. Suppress only
# GameTooltip.default; ordinary control tooltips use their own anchors and remain visible.
for token in (
    "GameTooltip.default",
    'ChainTooltipScript("OnTooltipSetDefaultAnchor")',
    'ChainTooltipScript("OnShow")',
    "local previous = GameTooltip:GetScript(scriptName)",
    "if previous then previous() end",
    "GameTooltip:Hide()",
):
    require(token in TOOLTIP, f"default-tooltip suppression is missing {token!r}")
require("local C = Arcane" not in TOOLTIP and "C.OnInit" not in TOOLTIP
        and 'SetScript("OnUpdate"' not in TOOLTIP,
        "tooltip guard must be standalone and must not run a per-frame poll")
require("OnTooltipSetDefaultAnchor" in ARCH and "GameTooltip.default" in ARCH,
        "default-tooltip ownership behavior must be documented")

# Arcane-owned branding and namespace, game-owned APIs untouched.
owned = CONTROLLER + OPTIONS + STATE + SPECIAL + VISUALS
require("C.Nameplates" in STATE and "C.Nameplates" in SPECIAL
        and "C.Nameplates" in VISUALS and "C.Nameplates" in CONTROLLER,
        "all Nameplates modules must share the Arcane-owned namespace")
require(("Tiny" + " Plates") not in owned and ("Arcane" + "Plates") not in owned,
        "retired branding must not leak into Nameplates")
require("Plates/" not in TOC, "the old module path must remain removed")

print("PASS exact native 1.12 WorldFrame plate signature and cached references")
print("PASS pooled plate reuse and per-update native-layer suppression")
print("PASS no half-second frame-discovery delay or recursive visual search")
print("PASS bounded replacement geometry centered on the native health bar")
print("PASS one-line, dynamically fitted health text and right-side level badge")
print("PASS draggable, screen-clamped Nameplates settings panel")
print("PASS native V, saved variables, AZS_* integration and shared bar renderer preserved")
print("PASS world-hover GameTooltip is suppressed only when owned by UIParent")
