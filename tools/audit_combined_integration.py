#!/usr/bin/env python3
"""Cross-module regression guards for consolidated co-op and performance releases."""
from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def src(path):
    return (ROOT / path).read_text(encoding="utf-8")


def require(test, message):
    if not test:
        raise SystemExit("FAIL: combined integration: " + message)


toc = src("Arcane.toc")
core = src("Core.lua")
meter = src("Windows/Meter.lua")
combat_api = src("Numbers/CombatAPI.lua")
hit_history = src("Core/Math.lua")
numbers = src("Numbers/Lifecycle.lua")
plates = src("Nameplates/ArcaneNameplates.lua")
readme = src("README.md")
workflow = src(".github/workflows/arcane-audit.yml")

match = re.search(r'Arcane\.VERSION\s*=\s*"([^"]+)"', core)
require(match is not None, "Core.VERSION must be present")
version = match.group(1)
tag = "v" + version
require(f'Arcane.VERSION = "{version}"' in core
        and f"## Version: {tag}" in toc
        and f"**Current release: {tag}**" in readme,
        "version metadata must agree across source and README")
require(readme.count(f"### {tag} —") == 1
        and f"ArcaneV{version}.zip" in readme,
        "single-README release notes and installer metadata must agree")
require(toc.index("Core/Poll.lua") < toc.index("Core/Cards.lua")
        and toc.index("Core/Poll.lua") < toc.index("Numbers/Numbers.lua")
        and toc.index("Core/Poll.lua") < toc.index("Nameplates/State.lua"),
        "shared polling bus must initialize before any consumers")
require("party = { metric = \"damage\", scope = \"party\", period = \"run\", groupBy = \"owner\", windowSeconds = 10 }" in meter
        and 'damage = { metric = "damage", scope = "self", period = "run", groupBy = "actor_source", windowSeconds = 10 }' in meter,
        "party and personal heading rates must use same ten-second window")
require("e.rate = RateValue(row.recentRate) or RateValue(row.displayRate)" in meter
        and "query.windowSeconds = 0" in meter
        and "S.rate = RateValue(totals.recentRate) or RateValue(totals.displayRate)" in meter,
        "party members, heading and cumulative best-skill query must remain coherent")
for name in ("SetPartyRun", "LeavePlayer", "FillPartyBestSkills", "ReadPlayer", "ReadSnapshot", "Reset"):
    require(re.search(r"local function " + name + r"\(", meter) is not None,
            "co-op owner and reset lifecycle missing " + name)
require('S.usedLines) and "avg dps" or tab.unit' in meter,
        "fallback averages must not be mislabeled as recent DPS")
require("C.Poll.Add" in plates and 'ScanNameplates()' in plates
        and 'P.State.HideNativePresentation(frame)' in plates,
        "plate data refresh can be polled but lifecycle must stay frame-reactive")
require("S.ReadEvents = function(now)" in combat_api
        and "MAX_BATCHES_PER_FRAME = 2" in combat_api
        and "EVENTS_PER_BATCH = 128" in combat_api
        and "N.Combat.NoteHit(ev, now)" in combat_api
        and "AUI.NoteHitValue(ev)" in combat_api,
        "cosmetic event budget must feed existing combat and tooltip consumers")
require("table.remove(v.times, 1)" not in hit_history
        and "v.timeCount" in hit_history
        and 'AUI.Poll.Add("numbers.housekeeping"' in numbers,
        "late-game event history and housekeeping must stay bounded")
require("if: github.event_name == 'workflow_dispatch' && github.ref == 'refs/heads/main'" in workflow,
        "manual stable-release permission gate must remain unchanged")
print("PASS: co-op ownership, rates, run/reset, polling load order and release guard integration")

lua = shutil.which("lua5.1")
require(lua is not None, "Lua 5.1 runtime is required for integrated behavior exercise")
script = r'''
Arcane = {Numbers={}}
local N = Arcane.Numbers
local now = 5
function GetTime() return now end
dofile("Core/Math.lua")
N.Config={STALE=0.6,db={misses=false}}
N.Combat={nPending=0,pending={}}
N.CombatAPI={}
N.Icons={}
N.Icons.NoteSource=function() end
N.Combat.NoteHit=function() end
N.Combat.ClearAll=function() end
local reads=0
function AZS_GetCombatTextEvents(cursor, limit)
  assert(limit==128)
  reads=reads+1
  if cursor==nil then return {cursor="tail",events={},hasMore=false} end
  local events={}
  for i=1,128 do
    events[i]={kind="damage",targetId="enemy"..i,meterSourceKey="fire:r2",
               meterSource="fire",amount=20,presentedAt=now,
               periodic=(i%2==0)}
  end
  return {cursor="next"..reads, events=events, hasMore=true}
end
dofile("Numbers/CombatAPI.lua")
N.CombatAPI.ReadEvents(now) -- subscribe without replaying old events
assert(reads==1)
N.CombatAPI.ReadEvents(now)
assert(reads==3 and N.Combat.nPending==256)
local rec=Arcane.hitValues["fire:r2"]
assert(rec and Arcane.hitValues.fire==rec)
assert(rec.timeCount==128 and math.abs(Arcane.HitRate(rec)-12.8)<0.00001,
       "cosmetic event budget must keep direct-hit tooltip data valid")
now=16
assert(Arcane.HitRate(rec)==0, "tooltips must age expired hits out of the ring")
'''
run = subprocess.run([lua, "-"], input=script, text=True, capture_output=True, cwd=ROOT)
require(run.returncode == 0, "integrated combat stream + tooltip ring failed:\n"
        + run.stdout + run.stderr)
print("PASS: real event-adapter to shared hit-history Lua integration")
print("PASS: combined regression and manual stable-release gate")
