-- Damage-number combat model: classify hits, group them and maintain labels.
local AUI = Arcane
local N = AUI.Numbers
local S = N.Combat
local C = N.Config

------------------------------------------------------------------------------
-- Labels: one number on screen and the hits it holds.

S.labels, S.nLabels = {}, 0
S.byKey, S.missByKey = {}, {}  -- the open number for an enemy (and skill)
S.nextLabelId = 0
S.pending, S.nPending = {}, 0
S.bossNames = {}
S.frameNow = 0            -- the time of the frame being worked on
local crowdTargets = {}      -- per spell: enemy -> until when it counts as hit
local dotCrowd, crowdAt, crowdUntil = {}, {}, {}

-- How long a DoT's number waits for its next tick: a bit more than the
-- longest wait seen between its ticks so far.
S.DotHold = function(label)
	if label.tickGap then
		return AUI.Clamp(label.tickGap * 1.25 + 0.35, 1, C.DOT_MAX_HOLD)
	end
	return C.DOT_FIRST_HOLD
end

-- Whether a number still takes hits. A DoT's stays open as long as the DoT
-- keeps ticking, until its enemy dies; any other closes after a moment.
S.IsOpen = function(label, now)
	if label == nil or label.dead then
		return false
	end
	if label.finished then
		return now - label.finishAt < C.KILL_GRACE
	end
	if label.merged then
		return now - label.born < C.MERGE_WINDOW
	end
	if label.dot then
		return now - label.lastHit < S.DotHold(label)
	end
	return now - label.born < C.db.mergeAge and now - label.lastHit < C.HOLD
end

-- What dealt a hit: the damage meter's line it counts toward when the hit says (a proc floating
-- in another spell's look is its own; a skill's ranks are one), else its spell, else how it landed
-- (a pet's swing is not yours).
S.SkillOf = function(ev)
	local m = ev.meterSourceKey
	if type(m) == "string" and m ~= "" then
		local skill = ev.arcaneSkill
		if not skill then
			skill = "m" .. (string.gsub(m, ":r%d+.*$", "")) .. "|" .. tostring(ev.meterSource or "") .. "|" .. tostring(ev.sourceKind or "player")
			ev.arcaneSkill = skill
		end
		return skill
	end
	if ev.spellId then
		return "s" .. ev.spellId
	end
	if ev.abilityName then
		return "n" .. ev.abilityName
	end
	if ev.reflected then
		return "shield"
	end
	return (ev.sourceKind or "player") .. ":" .. (ev.damageType or "melee")
end

-- Every spell counts the enemies it hit lately. On a crowd (three or more) its
-- hits merge, and stay merged two seconds after the crowd thins out, so it
-- can't flip back and forth around three.
S.NoteHit = function(ev, now)
	if not (ev.kind == "damage" and ev.targetId) then
		return
	end
	local skill = S.SkillOf(ev)
	local t = crowdTargets[skill]
	if not t then
		t = {}
		crowdTargets[skill] = t
	end
	local untilAt = now + (ev.periodic and C.CROWD_TICK or C.CROWD_HIT)
	if not t[ev.targetId] or t[ev.targetId] < untilAt then
		t[ev.targetId] = untilAt
	end
end

local function Crowded(skill, now)
	if crowdAt[skill] == now then
		return dotCrowd[skill]
	end
	crowdAt[skill] = now
	local t = crowdTargets[skill]
	local n = 0
	if t then
		for id, untilAt in pairs(t) do
			if untilAt < now then
				t[id] = nil
			else
				n = n + 1
			end
		end
	end
	if n >= C.CROWD_COUNT then
		crowdUntil[skill] = now + 2
	end
	dotCrowd[skill] = (crowdUntil[skill] or 0) > now
	return dotCrowd[skill]
end

-- Whether a hit joins its spell's one number a second (over the middle of the
-- enemies it hit) instead of a number on its enemy.
S.Merges = function(ev)
	if ev.kind ~= "damage" then
		return false
	end
	if C.db.bySpell then
		return true
	end
	return C.db.crowd and Crowded(S.SkillOf(ev), S.frameNow) or false
end

-- A tick of a DoT, with "DoT totals" on (and not merged with a crowd).
S.IsDotTick = function(ev)
	return ev.periodic and ev.kind == "damage" and C.db.dotTotals and not S.Merges(ev)
end

-- With icons on, every number holds one skill's hits on one enemy, so its
-- icon is always right; with them off, one number holds all of an enemy's.
S.KeyOf = function(ev)
	if not ev.targetId then
		return nil
	end
	if S.Merges(ev) then
		return "spell#" .. S.SkillOf(ev)
	end
	if S.IsDotTick(ev) then
		-- A DoT's ticks add up in a number of their own, apart from the hits.
		if C.db.icons then
			return ev.targetId .. "#dot#" .. S.SkillOf(ev)
		end
		return ev.targetId .. "#dot"
	end
	if C.db.icons then
		return ev.targetId .. "#" .. S.SkillOf(ev)
	end
	return ev.targetId
end
