#!/usr/bin/env python3
"""Party meter regression checks: source ownership, identity, lifecycle and Reset."""
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "Windows/Meter.lua").read_text(encoding="utf-8")


def fail(message):
    raise SystemExit("FAIL: " + message)


def section(start, end):
    a = source.find(start)
    if a < 0:
        fail("missing " + start)
    b = source.find(end, a + len(start))
    if b < 0:
        fail("missing end marker after " + start)
    return source[a:b].strip() + "\n"


# Guardrails against a second renderer or broken lifecycle integration.
for fragment in (
    'e.key, e.amount, e.ownerId = "o" .. tostring(row.ownerId)',
    'S.partyOwners, S.partyPortraits = owners, portraits',
    'if not owners[e.name] or owners[e.name] == false then e.ownerId = nil end',
    'query.scope, query.ownerId = "owner", f.ownerId',
    'FromSnapshot(snap, "player")',
    'if tab == "damage" then',
    'if tab == "party" and S.partyBaseOnly then',
    'if checkpointMade then',
    'if S.focus then LeavePlayer(); return end',
    'if button ~= "LeftButton" or drag.moving',
    'SetPartyRun(nil) -- expire focus',
    'if not db or db.tab ~= "party" or S.focus then return end',
    'S.partyAt = tonumber(AZS_PARTY_UPDATED) or 0',
    'S.partyStartStamp = tonumber(AZS_PARTY_UPDATED) or -1',
    'local sourceName = (tab == "player") and SkillName(src.name)',
    'local top = SkillName(l.top)',
    'local name = row and SkillName(row.top)',
    'stamp and (not S.partyAt or stamp > S.partyAt) and GameParty()',
    'if tab == "party" and context.partyState == "solo" then',
    'context.runId ~= S.partyRun then',
    'party = { metric = "damage", scope = "party", period = "run", groupBy = "owner", windowSeconds = 10 }',
    'e.rate = RateValue(row.recentRate) or RateValue(row.displayRate)',
    'query.windowSeconds = 0',
    'S.usedLines) and "avg dps" or tab.unit',
):
    if fragment not in source:
        fail("required meter contract missing: " + fragment)

for path in ("Locales/Locale_ja.lua", "Locales/Locale_ko.lua", "Locales/Locale_pl.lua",
             "Locales/Locale_ru.lua", "Locales/Locale_tr.lua", "Locales/Locale_zh.lua"):
    if '["Click for their skills."]' not in (ROOT / path).read_text(encoding="utf-8"):
        fail("missing translation " + path)
if '{ "Click for their skills.",' not in (ROOT / "Locales/Locale.lua").read_text(encoding="utf-8"):
    fail("missing core translation")

lua = shutil.which("lua5.1")
if not lua:
    fail("Lua 5.1 interpreter needed for behavior tests")

setup = r'''
C = { Vis = function() end, NoteSources = function() end, L = function(s) return s end }
db = { tab = "party" }
S = { list = {}, partyRun = "r1", partyAt = 10, partyStartStamp = 10,
      partyOwners = {}, partyPortraits = {},
      readClock = 0, n = 0, usedLines = false, partyBaseOnly = false }
CLASS_COLORS = { MAGE = {0.1,0.7,1} }
HARD_ERRORS = { INVALID_ARGUMENT = true }
EMPTY_BY_CODE = { NO_PARTY = "No party" }
QUERIES = { party = { metric = "damage", scope = "party", period = "run",
                     groupBy = "owner", windowSeconds = 10 } }
byKey = {}
function GetTime() return 30 end
function Call(f, args)
  if type(f) == "function" then return f(args) end
end
function Line(n)
  local e = S.list[n] or {}
  S.list[n] = e
  e.top, e.pet, e.topRate, e.rawTop, e.ownerId = nil,nil,nil,nil,nil
  return e
end
function ClearRows() S.n = 0; S.list = {}; S.cleared = (S.cleared or 0) + 1 end
function LeavePlayer() S.focus = nil; ClearRows() end
function SetPartyRun(id)
  S.partyRun = id; S.partyOwners = {}; S.partyAt = nil
  S.partyBaseOnly = false; S.base = nil; ClearRows()
end
function SortLines() end
function SchoolOf() return nil end
function getglobal(k) return _G[k] end
GETTERS = { party = function() S.nativeCalls = (S.nativeCalls or 0) + 1; return {}, 0, 0 end }
AZS_PARTY = { { name = "Mage", dmg = 90, top = "Fireball" } }
AZS_PARTY_UPDATED = 10
'''

behavior = r'''
local function check(ok, message)
  if not ok then error(message) end
end

-- The native update stamp is in its own domain, not wall-clock time.
check(GameParty() == nil, "old party update must not override ledger")
AZS_PARTY_UPDATED = 11
check(GameParty() and GameParty().Mage.name == "Mage", "fresh party update missing")
check(SkillName(nil) == nil and SkillName(" Nil ") == nil and SkillName("nIL") == nil
  and SkillName("   ") == nil, "unresolved skill names must not appear")
check(SkillName(" Windfury Weapon ") == "Windfury Weapon", "real spell name was rejected")
S.partyAt = 11
check(GameParty().Mage.top == "Fireball", "existing current-run labels must outlive the amount freshness window")
S.partyAt = 10
AZS_PARTY[2] = {name="Mage",top="Wrong Spell"}
check(GameParty().Mage == false, "ambiguous native names must not be mapped")
AZS_PARTY[2] = nil

-- Owner IDs remain the canonical key. The name cache must be per snapshot.
local row = { rows = {{ownerId="a",displayAmount=100}}, actors={a={name="Mage",classKey="MAGE"}} }
check(OwnerLines(row) == 1, "ledger owner line missing")
check(S.list[1].key == "oa" and S.partyOwners.Mage == "a", "owner ID changed")
local changed = { rows={{ownerId="b",displayAmount=80}}, actors={b={name="Rogue"}} }
OwnerLines(changed)
check(S.partyOwners.Mage == nil and S.partyOwners.Rogue == "b", "departed owner cached")
local ambiguous = { rows={{ownerId="a",displayAmount=80},{ownerId="b",displayAmount=60}},
                   actors={a={name="Mage"},b={name="Mage"}} }
OwnerLines(ambiguous)
check(S.partyOwners.Mage == false, "duplicate names must not resolve to an owner")
check(S.list[1].ownerId == nil and S.list[2].ownerId == nil, "duplicate name remains clickable")

-- The party overview must show a ready last-10-second DPS rate, not the
-- period or checkpoint average, while damage totals and shares stay cumulative.
S.checkpoint = nil
local rateRow = {
  rows={{ownerId="a",displayAmount=85000,share=0.6,
         periodAverage={status="ready",value=85},
         recentRate={status="ready",value=250},
         displayRate={status="ready",value=250}}},
  actors={a={name="Mage",classKey="MAGE"}},
  totals={displayAmount=150000,
          periodAverage={status="ready",value=150},
          recentRate={status="ready",value=400},
          displayRate={status="ready",value=400}}
}
FromSnapshot(rateRow, "party")
check(S.n==1 and S.list[1].rate==250 and S.rate==400, "party DPS is not the recent rate")
check(S.total==150000 and S.list[1].amount==85000 and S.list[1].share==0.6,
      "changing rate window modified cumulative amounts or damage shares")
S.checkpoint = "cp1"
rateRow.rows[1].checkpointAverage={status="ready",value=40}
rateRow.totals.checkpointAverage={status="ready",value=70}
FromSnapshot(rateRow, "party")
check(S.list[1].rate==250 and S.rate==400,
      "party DPS wrongly used checkpoint average instead of recent rate")
rateRow.rows[1].recentRate={status="unavailable"}
rateRow.rows[1].displayRate={status="unavailable"}
rateRow.totals.recentRate={status="warming_up"}
rateRow.totals.displayRate={status="warming_up"}
FromSnapshot(rateRow, "party")
check(S.list[1].rate==nil and S.rate==nil,
      "unavailable recent history must not silently display whole-run averages")
check(S.total==150000 and S.list[1].amount==85000,
      "unavailable recent history must not hide cumulative damage")
S.checkpoint = nil

-- A remote source with unresolved metadata must never put literal Nil into
-- the tag; the previously received, current-run native best skill can help
-- even when it is NOT newer than the ledger snapshot.
S.partyOwners = { Mage="a" }
S.list = {{name="Mage",ownerId="a"}}; S.n = 1
AZS_PARTY = {{name="Mage",top=" Nil ",topdps=0}}
AZS_PARTY_UPDATED = 12; S.partyAt = 12; S.partyStartStamp = 10
BestSkills({rows={{ownerId="a",sourceKey="Nil:r1",displayAmount=400}},
            sources={["Nil:r1"]={name="Nil"}}})
check(S.list[1].top == nil and S.list[1].pet == nil,
      "unresolved ledger spell leaked through as Nil")
FillPartyBestSkills()
check(S.list[1].top == nil, "unresolved native spell leaked through as Nil")
AZS_PARTY[1].top = "Windfury Weapon"; AZS_PARTY[1].topdps = 80
FillPartyBestSkills()
check(S.list[1].top == "Windfury Weapon" and S.list[1].pet == "Windfury Weapon",
      "current-run native label was not used after a successful ledger snapshot")
AZS_PARTY[1].top = "Nil"
S.list = {{name="Mage",ownerId="a"}}; S.n = 1
BestSkills({rows={{ownerId="a",sourceKey="windfury:r1",displayAmount=400}},
            sources={["windfury:r1"]={name="Windfury Weapon"}}})
check(S.list[1].top == "Windfury Weapon",
      "valid detailed-ledger top skill must outrank unresolved native data")
C.petSkills = {marker = true}
S.list = {}; S.n = 0
local ownRows = {rows={{actorId="a",ownerId="a",sourceKey="Spell:r1",displayAmount=100}},
                 actors={a={kind="hero"}},sources={["Spell:r1"]={name=" NIL "}}}
check(SourceLines(ownRows, "player") == 1 and S.list[1].name == "?",
      "focused player view displayed unresolved source name")
check(C.petSkills.marker == true, "focused view clobbered the local pet bar")

-- Duplicate native names must not collide in the row renderer or inherit a
-- ledger owner ID by an unsafe name match.
local previousGetter = GETTERS.party
GETTERS.party = function()
  return {{name="Mage",dmg=100,dps=10,top=" Nil "},
          {name="Mage",dmg=90,dps=9,top="Fireball"}}, 190, 19
end
S.list = {}; S.n = 0; S.base = nil; S.partyOwners = {Mage="a"}
check(ReadLines("party") and S.n == 2, "duplicate native rows disappeared")
check(S.list[1].key ~= S.list[2].key, "duplicate native rows share a renderer key")
check(S.list[1].ownerId == nil and S.list[2].ownerId == nil,
      "duplicate native names wrongly inherited a ledger identity")
check(S.list[1].top == nil and S.list[2].top == "Fireball",
      "native labels did not correctly reject unresolved names")
check(S.list[1].rate==10 and S.list[2].rate==9 and S.rate==19,
      "native party fallback must retain its existing average rates")
GETTERS.party = previousGetter

-- Native data from a prior run cannot supply a spell label.
local prior = AZS_PARTY_UPDATED
S.partyRun, S.partyStartStamp = "r2", prior
check(GameParty() == nil, "previous run's native party feed remained trusted")
S.partyRun, S.partyStartStamp = "r1", 10

-- A co-op ledger that is temporarily NOT_READY may use only newer party lines.
S.partyRun, S.partyAt, S.partyStartStamp, S.checkpoint, S.partyBaseOnly = "r1", 10, 5, nil, false
AZS_PARTY = {{name="Mage",dmg=90,top="Fireball"}}
AZS_PARTY_UPDATED = 11
AZS_GetMeterContext = function() return {runId="r1",localOwnerId="self"} end
AZS_GetMeterSnapshot = function() return nil, {code="NOT_READY"} end
check(ReadSnapshot("party") == "game", "fresh party fallback blocked")
S.checkpoint, S.checkpointRun = "cp1", "r1"
check(ReadSnapshot("party") == true, "checkpoint must disable whole-run fallback")
S.checkpoint, S.checkpointRun = nil, nil
S.partyAt = 11
check(ReadSnapshot("party") == true, "stale party feed should not override ledger")
check(GameParty() and GameParty().Mage.top == "Fireball",
      "valid label lost when amount fallback became stale")

-- Party overview must request 10-second rates and the second (best-skill)
-- snapshot must not request recent-rate calculations it does not use.
local queries = {}
S.checkpoint = "cp123"; S.checkpointRun = "r1"
AZS_GetMeterSnapshot = function(q)
  queries[#queries+1] = q
  if q.groupBy=="owner" then
    return {rows={{ownerId="a",displayAmount=1000,share=1,
                   recentRate={status="ready",value=17}}},
            actors={a={name="Mage"}}, totals={displayAmount=1000,
                   recentRate={status="ready",value=17}}}
  end
  return {rows={},sources={}}
end
check(ReadSnapshot("party")==true and #queries==2, "party did not fetch both API snapshots")
check(queries[1].windowSeconds==10 and queries[1].groupBy=="owner" and
      queries[1].checkpointId=="cp123", "party overview used wrong rate window or checkpoint")
check(queries[2].windowSeconds==0 and queries[2].groupBy=="actor_source" and
      queries[2].checkpointId=="cp123", "best-skill query unnecessarily requested recent history")
check(S.total==1000 and S.rate==17 and S.list[1].rate==17,
      "queried party rate does not match its header and row")
S.checkpoint = nil; S.checkpointRun = nil

-- Focusing an owner must never query other owners, nor rewrite the pet bar.
S.focus = {ownerId="a",name="Mage",runId="r1"}
S.checkpoint = nil
local requested
AZS_GetMeterSnapshot = function(q)
  requested=q
  return {rows={{actorId="a",ownerId="a",sourceKey="Fireball:r1",displayAmount=20}},
          actors={a={kind="hero"}},sources={["Fireball:r1"]={name="Fireball"}},
          totals={displayAmount=20,recentRate={status="ready",value=5}}}
end
ReadPlayer()
check(requested and requested.scope=="owner" and requested.ownerId=="a", "owner drilldown scope wrong")
check(requested.groupBy=="actor_source" and requested.windowSeconds==10 and
      S.list[1].name=="Fireball" and S.total==20,
      "detail did not reuse skill reader with the existing rate window")
S.focus = {ownerId="self",name="Me",runId="r1"}
ReadPlayer()
check(requested.scope=="self" and requested.ownerId==nil, "self detail must use self scope")
S.focus = {ownerId="a",name="Mage",runId="old-run"}
ReadPlayer()
check(S.focus==nil, "old-run focus must close")

-- Reset during native fallback should create a ledger checkpoint if available,
-- clear whole-run rows, and not retain stale visible totals.
S.focus=nil; S.usedLines=true; S.partyRun="r1"; S.partyBaseOnly=false
S.list={{key="oa",amount=100}}; S.n=1; S.cleared=0
AZS_CreateMeterCheckpoint=function() return {checkpointId="cp1"} end
Reset()
check(S.checkpoint=="cp1" and S.cleared==1 and S.base==nil, "fallback Reset checkpoint broken")

-- If no checkpoint is available, keep the native baseline and do not mix it
-- with the ledger's whole-run totals.
S.checkpoint=nil; S.list={{key="oa",amount=100}}; S.n=1
S.usedLines=true; S.partyRun="r1"; S.partyBaseOnly=false
AZS_CreateMeterCheckpoint=function() return nil end
Reset()
check(S.partyBaseOnly==true and S.base.oa==100, "missing checkpoint lost native baseline")
local before=S.nativeCalls or 0
Read()
check((S.nativeCalls or 0)>before, "native baseline no longer read")

-- The current world can start a new run without calling a world-loading hook.
-- This must expire the previous run's native Reset baseline immediately.
AZS_GetMeterContext = function() return {runId="r2",partyState="party"} end
Read()
check(S.partyRun=="r2" and S.partyBaseOnly==false and S.base==nil,
      "new run retained the old native Reset baseline")
-- Leaving the party must also clear that old baseline without requiring a new zone.
S.partyRun="r2"; S.partyBaseOnly=true
AZS_GetMeterContext = function() return {runId="r2",partyState="solo"} end
Read()
check(S.partyBaseOnly==false and S.status=="empty", "solo transition retained old party rows")

print("PASS: run-scoped identity, native freshness, owner skill queries and Reset lifecycle")
'''

chunks = [
    section("local function RateValue(r)", "-- The game can publish"),
    section("local function SkillName(value)", "-- Changing views"),
    section("local function GameParty()", "------------------------------------------------------------------------ reading: the meter API"),
    section("local function SourceLines(snap, tab)", "-- One line per party member"),
    section("local function OwnerLines(snap)", "local function BestSkills(snap)"),
    section("local function BestSkills(snap)", "-- If the ledger cannot name"),
    section("local function FillPartyBestSkills()", "local function FromSnapshot(snap, tab)"),
    section("local function FromSnapshot(snap, tab)", "-- A party member's skills"),
    section("local function ReadPlayer()", "-- true when it read the API"),
    section("local function ReadSnapshot(tab)", "------------------------------------------------------------------------ reading: the older getters"),
    section("local function ReadLines(tab)", "-- the most first:"),
    section("local function Read()", "------------------------------------------------------------------------ Reset: this window only"),
    section("local function Reset()", "------------------------------------------------------------------------ building"),
]
program = setup + "\n".join(chunks) + "\n" + behavior
result = subprocess.run([lua, "-"], input=program, text=True, capture_output=True)
if result.returncode:
    fail("meter behavior harness failed:\n" + result.stdout + result.stderr)
print(result.stdout.strip())
print("PASS: co-op meter integration guardrails and localization")
