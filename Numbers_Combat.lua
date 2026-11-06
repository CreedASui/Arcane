-- Damage-number combat model: classify hits, group them and maintain labels.
local AUI = Arcane
local N = AUI.Numbers
local S = N.Combat
local C = N.Config

------------------------------------------------------------------------------
-- Labels: one number on screen and the hits it holds.

S.labels, S.nLabels = {}, 0
S.byKey, S.missByKey = {}, {}  -- the open number for an enemy (and skill)
local nextLabelId = 0
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
local function SkillOf(ev)
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
	local skill = SkillOf(ev)
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
local function Merges(ev)
	if ev.kind ~= "damage" then
		return false
	end
	if C.db.bySpell then
		return true
	end
	return C.db.crowd and Crowded(SkillOf(ev), S.frameNow) or false
end

-- A tick of a DoT, with "DoT totals" on (and not merged with a crowd).
local function IsDotTick(ev)
	return ev.periodic and ev.kind == "damage" and C.db.dotTotals and not Merges(ev)
end

-- With icons on, every number holds one skill's hits on one enemy, so its
-- icon is always right; with them off, one number holds all of an enemy's.
S.KeyOf = function(ev)
	if not ev.targetId then
		return nil
	end
	if Merges(ev) then
		return "spell#" .. SkillOf(ev)
	end
	if IsDotTick(ev) then
		-- A DoT's ticks add up in a number of their own, apart from the hits.
		if C.db.icons then
			return ev.targetId .. "#dot#" .. SkillOf(ev)
		end
		return ev.targetId .. "#dot"
	end
	if C.db.icons then
		return ev.targetId .. "#" .. SkillOf(ev)
	end
	return ev.targetId
end

local meleeIcon, shotIcon, summonIcon, totemIcon = C.MELEE_ICON, C.SHOT_ICON, nil, nil
local petIcon, classPetIcon = nil, nil
local summonById = {}          -- a summon's id -> { icon, seen }, kept a little after it goes
local idsMatch, idsMiss = 0, 0 -- whether hits name their attacker with the summon list's ids
local petsStamp
-- what a pet or summon's swing shows when nothing better is known: the class's own summoning art
local CLASS_PET_ICONS = {
	HUNTER = "Interface\\Icons\\Ability_Hunter_BeastCall",
	WARLOCK = "Interface\\Icons\\Spell_Shadow_SummonImp",
	SHAMAN = "Interface\\Icons\\Spell_Nature_SpiritWolf",
	DRUID = "Interface\\Icons\\Spell_Nature_Regeneration",
	MAGE = "Interface\\Icons\\Spell_Frost_FrostBolt02",
}

local function GearIcon(slot)
	if type(GetInventoryItemTexture) ~= "function" then
		return nil
	end
	local ok, texture = pcall(GetInventoryItemTexture, "player", slot)
	if ok and type(texture) == "string" and texture ~= "" then
		return texture
	end
	return nil
end

-- Your pets and summons: each one's icon by its id (when a swing names its
-- attacker), the main pet's (the one that stays), and the most numerous
-- temporary summons' (Infernals, Legion Gate's demons...).
local function RefreshSummonIcons(now)
	petIcon, summonIcon = nil, nil
	now = now or 0
	if type(AZS_GetSummonGroups) == "function" then
		local ok, groups = pcall(AZS_GetSummonGroups)
		if ok and type(groups) == "table" then
			local most = 0
			for i = 1, table.getn(groups) do
				local g = groups[i]
				if type(g) == "table" and type(g.icon) == "string" and g.icon ~= "" then
					if not petIcon and (tonumber(g.permanent) or 0) > 0 then petIcon = g.icon end
					local temporary = tonumber(g.temporary) or 0
					if temporary > most then summonIcon, most = g.icon, temporary end
					if not petIcon and g.kind == "pet" then petIcon = g.icon end
				end
			end
			if not petIcon and type(groups[1]) == "table" and type(groups[1].icon) == "string" then petIcon = groups[1].icon end
			summonIcon = summonIcon or petIcon
		end
	end
	if type(AZS_GetSummons) == "function" then
		local ok, list = pcall(AZS_GetSummons)
		if ok and type(list) == "table" then
			for i = 1, table.getn(list) do
				local one = list[i]
				if type(one) == "table" and one.id ~= nil and type(one.icon) == "string" and one.icon ~= "" then
					local key = tostring(one.id)
					local rec = summonById[key]
					if not rec then
						rec = {}
						summonById[key] = rec
					end
					rec.icon, rec.seen = one.icon, now
				end
			end
		end
	end
	-- one that's gone stays a while: its last hits can still be on their way
	for key, rec in pairs(summonById) do
		if now - rec.seen > 8 then
			summonById[key] = nil
		end
	end
	if type(UnitClass) == "function" then
		local ok, _, class = pcall(UnitClass, "player")
		classPetIcon = ok and CLASS_PET_ICONS[class or ""] or nil
	end
end

-- The first totem out's icon (Searing and Magma's own hits name their spell anyway).
local function TotemIcon()
	if type(AZS_GetTotems) ~= "function" then
		return nil
	end
	local ok, list = pcall(AZS_GetTotems)
	if ok and type(list) == "table" then
		for i = 1, table.getn(list) do
			local t = list[i]
			if type(t) == "table" and type(t.icon) == "string" and t.icon ~= "" then
				return t.icon
			end
		end
	end
	return nil
end

-- Read now and then: the weapon in hand, the summons and totem out.
S.RefreshFallbackIcons = function(now)
	meleeIcon = GearIcon(16) or C.MELEE_ICON
	shotIcon = GearIcon(18) or C.SHOT_ICON
	RefreshSummonIcons(now)
	totemIcon = TotemIcon()
end

-- The summon list changes as they come and go: read it again the moment it does.
S.WatchSummons = function(now)
	local stamp = AZS_PETS_UPDATED
	if stamp ~= petsStamp then
		petsStamp = stamp
		RefreshSummonIcons(now)
	end
end

-- Do hits name their attacker with the summon list's own ids? Every pet or summon hit counts,
-- and the ids are trusted once they keep matching (the game may number them apart).
S.NoteSource = function(ev)
	local source = ev.sourceKind
	if not source or source == "player" or source == "totem" or ev.sourceId == nil then
		return
	end
	if summonById[tostring(ev.sourceId)] then
		idsMatch = idsMatch + 1
	else
		idsMiss = idsMiss + 1
	end
	if idsMatch + idsMiss > 400 then
		idsMatch, idsMiss = idsMatch * 0.5, idsMiss * 0.5
	end
end

local function IconOf(ev)
	-- your proc in another spell's look (Shadow Weaving floating as Shadow Word: Pain): the icon of
	-- its own line, as the meter shows it, when the game has one
	local own = ev.meterSource
	if type(own) == "string" and own ~= "" and ev.abilityName and own ~= ev.abilityName
		and (ev.sourceKind == nil or ev.sourceKind == "player") then
		local art = (AUI.SourceIcon and AUI.SourceIcon(ev.meterSourceKey)) or (AUI.icons and AUI.icons[own])
		if art then
			return art
		end
	end
	local icon = ev.icon
	-- A question mark means the game has no art for it: use the fallbacks.
	if type(icon) == "string" and icon ~= "" and not string.find(string.lower(icon), "questionmark", 1, true) then
		if not string.find(icon, "[\\/]") then
			icon = "Interface\\Icons\\" .. icon -- a bare name
		end
		return icon
	end
	if ev.reflected then
		return C.SHIELD_ICON
	end
	local source = ev.sourceKind
	if source == "totem" then
		return totemIcon
	end
	if source and source ~= "player" then
		-- a pet's or summon's swing: that very one's icon when the hit names it and the ids
		-- have proved to be the summon list's
		if ev.sourceId ~= nil and idsMatch >= 4 and idsMatch >= idsMiss * 4 then
			local rec = summonById[tostring(ev.sourceId)]
			if rec then
				return rec.icon
			end
		end
		if source == "pet" then
			return petIcon or summonIcon or classPetIcon
		end
		return summonIcon or petIcon or classPetIcon
	end
	if ev.spellId or ev.damageType == "spell" then
		return nil -- a spell the game has no art for: no icon beats a wrong one
	end
	if ev.damageType == "ranged" then
		return shotIcon
	end
	return meleeIcon
end

S.Retire = function(label)
	label.dead = true
	if label.w then
		N.Widgets.ReleaseWidget(label.w)
		label.w = nil
	end
	if label.key then
		if S.byKey[label.key] == label then
			S.byKey[label.key] = nil
		end
		if S.missByKey[label.key] == label then
			S.missByKey[label.key] = nil
		end
	end
end

S.ClearAll = function()
	for i = 1, S.nLabels do
		S.Retire(S.labels[i])
		S.labels[i] = nil
	end
	S.nLabels = 0
	S.byKey, S.missByKey = {}, {}
	for i = 1, S.nPending do
		S.pending[i] = nil
	end
	S.nPending = 0
end

local function MissWord(ev)
	local result = ev.result
	if type(result) == "table" then
		if type(result.text) == "string" and result.text ~= "" then
			return result.text
		end
		if result.key then
			return C.L(C.Capitalize(result.key))
		end
	end
	return C.L("Miss")
end

local function NewLabel(ev, now)
	nextLabelId = nextLabelId + 1
	local amount = ev.amount or 0
	local label = {
		id = nextLabelId,
		target = ev.targetId,
		key = S.KeyOf(ev),
		skill = SkillOf(ev),
		icon = IconOf(ev),
		miss = ev.kind == "miss",
		total = amount,
		shown = amount,
		count = 1,
		crit = (ev.critical and not IsDotTick(ev)) and true or false, -- a DoT's total is never gold
		critDamage = 0,
		direct = not ev.periodic,
		dot = IsDotTick(ev) and true or false,
		lastTick = ev.periodic and now or nil,
		biggest = amount,
		school = ev.schoolMask,
		anchorId = ev.anchorId,
		fake = ev.fake,
		born = now,
		lastHit = now,
		boss = (ev.targetName ~= nil and S.bossNames[ev.targetName]) and true or false,
		bump = 0,
		nudge = 0,
		nudgeGoal = 0,
		placed = false,
		crowd = 0,
		cullFade = 1,
		culled = false,
		dying = false,
		vis = 1,
		x = ev.x,
		y = ev.y,
		onScreen = ev.onScreen and true or false,
	}
	if label.key and string.sub(label.key, 1, 6) == "spell#" then
		-- a merged number: it sits over the middle of the enemies its spell hit
		label.merged = true
		label.target = nil
		label.anchorId = nil
		label.fake = nil
		label.spots = { { id = ev.anchorId, fake = ev.fake, target = ev.targetId, at = now,
			lx = ev.onScreen and ev.x or nil, ly = ev.onScreen and ev.y or nil } }
	end
	if label.miss then
		label.word = MissWord(ev)
	elseif ev.critical then
		label.critDamage = amount
	end
	S.nLabels = S.nLabels + 1
	S.labels[S.nLabels] = label
	if label.key then
		if label.miss then
			S.missByKey[label.key] = label
		else
			S.byKey[label.key] = label
		end
	end
	return label
end

local function Merge(label, ev, now)
	local amount = ev.amount or 0
	label.total = label.total + amount
	label.count = label.count + 1
	label.lastHit = now
	-- Every crit gives the number a pop; it turns gold when crits are at
	-- least half of what it holds.
	if ev.critical then
		label.critDamage = label.critDamage + amount
		label.bump = label.bump + 0.3
	elseif label.dot then
		label.bump = label.bump + 0.07 -- a soft pulse each tick
	else
		label.bump = label.bump + 0.1
	end
	if label.dot and ev.periodic then
		-- Ticks closer than this are one round of the DoT's stacks.
		if label.lastTick and now - label.lastTick > 0.15 then
			local gap = now - label.lastTick
			if not label.tickGap or gap > label.tickGap then
				label.tickGap = gap
			end
		end
		label.lastTick = now
	end
	label.crit = (not label.dot) and label.critDamage > 0 and label.critDamage * 2 >= label.total
	if label.bump > 0.45 then
		label.bump = 0.45
	end
	if not ev.periodic then
		label.direct = true
	end
	if amount > label.biggest then
		-- The colour and icon follow the hardest hit in the number.
		label.biggest = amount
		label.school = ev.schoolMask
		label.icon = IconOf(ev)
	end
	if ev.targetName and S.bossNames[ev.targetName] then
		label.boss = true
	end
	-- One enemy's number follows its newest hit, whose place lasts longest.
	if ev.anchorId and ev.targetId ~= nil and ev.targetId == label.target then
		label.anchorId = ev.anchorId
	end
	if label.spots and (ev.anchorId or ev.fake) then
		local spots, found = label.spots, nil
		for i = 1, table.getn(spots) do
			if spots[i].target == ev.targetId then
				found = spots[i]
			end
		end
		if found then
			found.id, found.lost = ev.anchorId or found.id, nil
		elseif table.getn(spots) < C.MAX_SPOTS then
			table.insert(spots, { id = ev.anchorId, fake = ev.fake, target = ev.targetId, at = now })
		end
	end
end

S.Intake = function(ev, now)
	local key = S.KeyOf(ev)
	if ev.kind == "miss" then
		local label = key and S.missByKey[key]
		if S.IsOpen(label, now) then
			label.count = label.count + 1
			label.lastHit = now
			label.bump = math.min(0.3, label.bump + 0.08)
		elseif ev.anchorId or ev.fake then
			NewLabel(ev, now)
		end
		return
	end
	local label = key and S.byKey[key]
	if not S.IsOpen(label, now) then
		label = nil
		local boss = ev.targetName ~= nil and S.bossNames[ev.targetName]
		if C.db.group and ev.onScreen and not boss and not IsDotTick(ev) and not Merges(ev) then
			-- The nearest open number around this spot takes the hit (the
			-- same skill's, with icons on).
			local skill = C.db.icons and SkillOf(ev)
			local radius = C.GROUP_RADIUS * C.db.size
			local best, bestDistance = nil, radius * radius
			for i = 1, S.nLabels do
				local other = S.labels[i]
				if not other.miss and not other.boss and not other.dot and other.onScreen
					and S.IsOpen(other, now) and (not skill or other.skill == skill) then
					local dx, dy = other.x - ev.x, other.y - ev.y
					local distance = dx * dx + dy * dy
					if distance < bestDistance then
						best, bestDistance = other, distance
					end
				end
			end
			label = best
		end
	end
	if label then
		Merge(label, ev, now)
		if key then
			S.byKey[key] = label
		end
	elseif ev.anchorId or ev.fake then
		NewLabel(ev, now)
	end
end
