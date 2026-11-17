#!/usr/bin/env python3
"""Behavior and static performance guardrails for Arcane's late-game hot paths."""
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
lua = shutil.which("lua5.1")
if not lua:
    raise SystemExit("FAIL: Lua 5.1 is required for performance regressions")


def check(ok, message):
    if not ok:
        raise SystemExit("FAIL: " + message)


def source(path):
    return (ROOT / path).read_text(encoding="utf-8")


def run_lua(name, code):
    result = subprocess.run([lua, "-"], input=code, text=True, capture_output=True, cwd=ROOT)
    if result.returncode:
        raise SystemExit("FAIL: " + name + "\n" + result.stdout + result.stderr)
    print("PASS:", name)


toc = source("Arcane.toc")
poll = source("Core/Poll.lua")
plate = source("Nameplates/ArcaneNameplates.lua")
plate_state = source("Nameplates/State.lua")
numbers_api = source("Numbers/CombatAPI.lua")
numbers_lifecycle = source("Numbers/Lifecycle.lua")
numbers_combat = source("Numbers/Combat.lua")
numbers_labels = source("Numbers/Labels.lua")
core_math = source("Core/Math.lua")
check("Core/Storage.lua\nCore/Poll.lua\nCore/HUD.lua" in toc,
      "poll bus must load before the first clients")
check('scanFrame:SetScript("OnUpdate"' in plate and 'ScanNameplates()' in plate,
      "pooled plate reuse must remain same-frame")
check("WorldFrame:GetNumChildren()" in plate and plate.count("WorldFrame:GetChildren()") == 1,
      "WorldFrame enumeration is not cached by child count")
check('C.Poll.Add("nameplates.overlay"' in plate and 'C.Poll.Add("nameplates.debuffs"' in plate,
      "nameplate low-frequency reads must use shared polling")
check('AUI.Poll.Add("numbers.boss_names"' in numbers_lifecycle
      and 'AUI.Poll.Add("numbers.housekeeping"' in numbers_lifecycle,
      "damage-number housekeeping must use shared polling")
check('N.Combat.PruneCrowd(now)' in numbers_lifecycle
      and 'S.ResetCrowd()' in numbers_labels,
      "crowd history needs periodic and world-transition cleanup")
check("MAX_BATCHES_PER_FRAME = 2" in numbers_api and "EVENTS_PER_BATCH = 128" in numbers_api,
      "combat-number event budget was removed")
check("table.remove(v.times, 1)" not in core_math
      and "v.timeNext" in core_math and "v.timeCount" in core_math,
      "direct-hit history must use a bounded ring")
check("frame.arcaneNameplatesRawName" in plate_state
      and "frame.arcaneNameplatesRawLevel" in plate_state,
      "native plate text must cache unchanged raw values")
for path, poll_key in (
    ("Core/Cards.lua", "cards.layer_order"),
    ("Frames/LevelUps.lua", "levelups.storing"),
    ("Frames/Framerate.lua", "fps.readout"),
    ("Frames/Framerate.lua", "fps.theme"),
    ("Frames/NativeText.lua", "native_text.theme"),
    ("Windows/Talents.lua", "talents.refresh"),
):
    check(f'C.Poll.Add("{poll_key}"' in source(path),
          f"{path} must schedule {poll_key} on the shared bus")
check('SetScript("OnUpdate"' not in source("Frames/Framerate.lua")
      and 'SetScript("OnUpdate"' not in source("Frames/NativeText.lua")
      and 'SetScript("OnUpdate"' not in source("Windows/Talents.lua"),
      "slow FPS, native text and talents readers must not own individual frame drivers")

run_lua("shared keyed polling cadence, coalescing, errors and removal", r'''
Arcane = { errors = {}, Print = function(msg) end }
local now = 0
function GetTime() return now end
local frame = { shown = false }
function frame:Show() self.shown = true end
function frame:Hide() self.shown = false end
function frame:SetScript(event, fn) self[event] = fn end
function CreateFrame() return frame end
dofile("Core/Poll.lua")
local fast, slow = 0, 0
assert(Arcane.Poll.Add("fast", 0.10, function() fast=fast+1 end, true))
assert(Arcane.Poll.Add("slow", 0.25, function() slow=slow+1 end, true))
assert(frame.shown)
frame.OnUpdate()
assert(fast==1 and slow==1)
now=0.11; frame.OnUpdate()
assert(fast==2 and slow==1)
now=0.26; frame.OnUpdate()
assert(fast==3 and slow==2)
now=5; frame.OnUpdate()
assert(fast==4 and slow==3, "a long frame must not replay missed ticks")
now=5.01; frame.OnUpdate()
assert(fast==4 and slow==3)
assert(Arcane.Poll.Kick("fast") and Arcane.Poll.Kick("fast"))
frame.OnUpdate()
assert(fast==5 and slow==3, "event requests should coalesce")
local unique=0
Arcane.Poll.Add("fast", 0.20, function() unique=unique+1 end, false)
now=5.15; frame.OnUpdate()
assert(unique==0)
now=5.22; frame.OnUpdate()
assert(unique==1, "re-registering a key must not duplicate a poll job")
local reports=0
Arcane.Print=function() reports=reports+1 end
Arcane.Poll.Add("broken", 0.1, function() error("test failure") end, true)
frame.OnUpdate()
now=5.33; frame.OnUpdate()
assert(reports==1, "recurring identical poll errors must not flood chat")
assert(Arcane.Poll.Remove("broken"))
assert(Arcane.Poll.Remove("fast"))
assert(Arcane.Poll.Remove("slow"))
assert(not frame.shown, "empty polling bus should stop updating")
''')

run_lua("direct-hit ring retains aliases, 200-hit cap and 10-second rates", r'''
Arcane = {}
local now = 0
function GetTime() return now end
dofile("Core/Math.lua")
for i=1,1500 do
  Arcane.NoteHitValue({kind="damage",amount=i,meterSourceKey="fire:r1",meterSource="fire"})
end
local v = Arcane.hitValues["fire:r1"]
assert(v and v==Arcane.hitValues.fire)
assert(v.timeCount==200 and table.getn(v.times)==200)
assert(Arcane.HitRate(v)==20)
assert(v.last==1500 and v.high==1500 and v.low==1)
now=10.1
assert(Arcane.HitRate(v)==0, "expired timestamps must not count")
Arcane.NoteHitValue({kind="damage",amount=1501,meterSourceKey="fire:r1",meterSource="fire"})
assert(math.abs(Arcane.HitRate(v)-0.1)<0.0001)
Arcane.NoteHitValue({kind="damage",amount=5,periodic=true,meterSourceKey="fire:r1"})
assert(math.abs(Arcane.HitRate(v)-0.1)<0.0001, "DoT ticks do not populate direct-hit tooltip history")
assert(v.timeCount==200 and table.getn(v.times)==200, "no growth past ring capacity")
''')

run_lua("combat-text event batches stay bounded under sustained burst", r'''
Arcane = { Numbers = {} }
local N = Arcane.Numbers
N.Config = { STALE=0.6, db={misses=false} }
N.CombatAPI = {}
N.Combat = { pending={}, nPending=0 }
N.Icons = {}
local accepted, noted, icons, hitValues = 0, 0, 0, 0
N.Combat.NoteHit = function() noted=noted+1 end
N.Combat.ClearAll = function() N.Combat.nPending=0; N.Combat.pending={}; accepted=accepted+1 end
N.Icons.NoteSource = function() icons=icons+1 end
Arcane.NoteHitValue = function() hitValues=hitValues+1 end
local calls = 0
function AZS_GetCombatTextEvents(cursor, limit)
  calls=calls+1
  assert(limit==128, "cosmetic event reads should be bounded to 128")
  if cursor==nil then return {cursor="start",events={},hasMore=false} end
  local events={}
  for i=1,128 do events[i]={kind="damage",amount=25,presentedAt=5,targetId="x"} end
  return {cursor=tostring(calls),events=events,hasMore=true}
end
dofile("Numbers/CombatAPI.lua")
local api = N.CombatAPI
api.ReadEvents(5)
assert(calls==1 and N.Combat.nPending==0, "subscription must not replay old hits")
api.ReadEvents(5)
assert(calls==3 and N.Combat.nPending==256, "at most two cosmetic batches per frame")
assert(noted==256 and icons==256 and hitValues==256)
assert(not api.Wanted({kind="damage",amount=1,presentedAt=3},5))
assert(not api.Wanted({kind="miss",amount=1,presentedAt=5},5))
local resubscribe=0
function AZS_GetCombatTextEvents(cursor,limit)
  resubscribe=resubscribe+1
  if not cursor then return {cursor="fresh"} end
  return nil, {code="STREAM_CHANGED"}
end
api.ReadEvents(5)
assert(accepted==1 and api.cursor=="fresh" and resubscribe==2,
       "stream changes should clear old labels and resubscribe")
''')

run_lua("spell crowd cache expires and resets on new runs", r'''
Arcane = { Numbers = {}, Clamp=function(x,lo,hi) return math.max(lo,math.min(x,hi)) end }
local N = Arcane.Numbers
N.Config = {db={crowd=true,bySpell=false,dotTotals=true,icons=true,mergeAge=0.9},
            CROWD_HIT=1.6,CROWD_TICK=3.2,CROWD_COUNT=3,DOT_MAX_HOLD=3.9,
            DOT_FIRST_HOLD=3.4,HOLD=0.5,KILL_GRACE=0.4}
N.Combat = {}
dofile("Numbers/Combat.lua")
local S=N.Combat
S.frameNow=0
for i=1,3 do S.NoteHit({kind="damage",targetId="t"..i,spellId=4,periodic=true},0) end
local many={kind="damage",targetId="t1",spellId=4,periodic=true}
assert(S.Merges(many) and S.KeyOf(many)=="spell#s4")
assert(not S.IsDotTick(many), "merged AoE ticks must not become separate DoT labels")
S.ResetCrowd()
local alone={kind="damage",targetId="t1",spellId=4,periodic=true}
assert(not S.Merges(alone) and S.IsDotTick(alone))
assert(S.KeyOf(alone)=="t1#dot#s4")
S.NoteHit({kind="damage",targetId="t1",spellId=4,periodic=true},0)
S.PruneCrowd(10)
S.frameNow=10
assert(not S.Merges({kind="damage",targetId="t1",spellId=4,periodic=true}))
N.Config.db.crowd=false
S.NoteHit({kind="damage",targetId="x",spellId=4,periodic=true},10)
N.Config.db.bySpell=true
assert(S.Merges({kind="damage",targetId="x",spellId=4}), "explicit by-spell merge is preserved")
''')

run_lua("nameplate cached identity responds to text and level changes", r'''
Arcane = { Nameplates={} }
dofile("Nameplates/State.lua")
local P=Arcane.Nameplates.State
local name={raw=" |cffffffffMagma Totem|r "}
function name:GetText() return self.raw end
local level={raw="43"}
function level:GetText() return self.raw end
local frame={arcaneNameplatesNameRegion=name,arcaneNameplatesLevelRegion=level}
assert(P.GetPlateName(frame)=="Magma Totem" and P.GetPlateLevel(frame)==43)
assert(P.GetPlateName(frame)=="Magma Totem" and frame.arcaneNameplatesRawName==name.raw)
name.raw=" Deep Wounds "
level.raw="44"
assert(P.GetPlateName(frame)=="Deep Wounds" and P.GetPlateLevel(frame)==44)
level.raw="??"
assert(P.GetPlateLevel(frame)==nil)
name.raw=nil
assert(P.GetPlateName(frame)==nil)
''')


run_lua("same-frame pooled plate reuse without full WorldFrame enumeration", r'''
Arcane = { Nameplates = {State={},Special={},Visuals={} } }
local C=Arcane
local P=C.Nameplates
local now, enumerated, styled, hidden = 0, 0, 0, 0
function GetTime() return now end
local world = { children={} }
function world:GetNumChildren() return table.getn(self.children) end
function world:GetChildren()
  enumerated=enumerated+1
  return unpack(self.children)
end
WorldFrame=world
function C.OnInit(fn) C.init=fn end
function C.OnWorld(fn) C.world=fn end
function C.OnLogout(fn) C.logout=fn end
function C.DB() return {} end
function C.Print() error("nameplate controller unexpectedly errored") end
function C.L(x) return x end
C.Poll={ tasks={},Add=function(key,period,fn) C.Poll.tasks[key]=fn end,
         Kick=function() end }
P.State.IdentifyNameplate=function(frame) return true end
P.State.RegisterPlate=function(frame,known,ordered)
  if not known[frame] then
    known[frame]=true
    table.insert(ordered,frame)
    frame.arcaneNameplatesNeedsStyle=true
    return true,true,true,true
  end
  if frame.generation~=frame.knownGeneration then
    frame.knownGeneration=frame.generation
    frame.arcaneNameplatesNeedsStyle=true
    -- Mirror the real pooled-plate lifecycle: an old category/revision
    -- must be invalidated before the new unit is styled.
    frame.arcaneNameplatesAppliedCategory=nil
    frame.arcaneNameplatesStyleRevision=-1
    return true,true,true,true
  end
  return true,false,false,false
end
P.State.HideNativePresentation=function() hidden=hidden+1 end
P.State.RestoreNativeState=function() end
P.Special.IsBossOrGuardianPlate=function() return false end
P.Special.RefreshNames=function() end
P.Special.HideDebuffs=function() end
P.Visuals.Apply=function() styled=styled+1;return true end
P.Visuals.SyncOverlayValues=function() end
local driver = {}
function driver:RegisterEvent() end
function driver:SetScript(name,fn) self[name]=fn end
function driver:Show() end
function CreateFrame() return driver end
local function plate()
  local f={generation=1}
  function f:GetObjectType() return "Button" end
  function f:IsVisible() return true end
  function f:GetWidth() return 100 end
  function f:GetHeight() return 20 end
  return f
end
dofile("Nameplates/ArcaneNameplates.lua")
C.init()
assert(C.Poll.tasks["nameplates.overlay"] and C.Poll.tasks["nameplates.debuffs"])
world.children[1]=plate()
driver.OnUpdate()
assert(enumerated==1 and styled==1 and hidden==1, "first plate not styled immediately")
for i=1,100 do driver.OnUpdate() end
assert(enumerated==1, "unchanged WorldFrame was re-enumerated every frame")
local first=world.children[1]
first.generation=2
driver.OnUpdate()
assert(styled==2 and enumerated==1, "reused plate must restyle same frame")
world.children[2]=plate()
driver.OnUpdate()
assert(styled==3 and enumerated==2, "new pool entry must style on the growth frame")
now=2.5
driver.OnUpdate()
assert(enumerated==3, "periodic fallback probe missing")
C.ArcaneNameplatesRefresh(true)
driver.OnUpdate()
assert(styled==5, "style revisions must still restyle existing plates")
''')

print("PASS: performance-specific static and Lua 5.1 behavior guardrails")
