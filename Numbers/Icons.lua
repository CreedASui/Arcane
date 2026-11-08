-- Damage-number icons: weapon, spell, pet and summon artwork in one place.
local AUI = Arcane
local N = AUI.Numbers
local I = N.Icons
local C = N.Config

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
I.RefreshFallbackIcons = function(now)
	meleeIcon = GearIcon(16) or C.MELEE_ICON
	shotIcon = GearIcon(18) or C.SHOT_ICON
	RefreshSummonIcons(now)
	totemIcon = TotemIcon()
end

-- The summon list changes as they come and go: read it again the moment it does.
I.WatchSummons = function(now)
	local stamp = AZS_PETS_UPDATED
	if stamp ~= petsStamp then
		petsStamp = stamp
		RefreshSummonIcons(now)
	end
end

-- Do hits name their attacker with the summon list's own ids? Every pet or summon hit counts,
-- and the ids are trusted once they keep matching (the game may number them apart).
I.NoteSource = function(ev)
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

I.IconOf = function(ev)
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
