-- Combat-text API adapter: validate the client API and collect incoming events.
local AUI = Arcane
local N = AUI.Numbers
local S = N.CombatAPI
local C = N.Config

------------------------------------------------------------------------------
-- Reading the game's hits

S.apiReady, S.active, S.registered, S.warnedNoApi = false, false, false, false
S.cursor = nil

S.ApiReady = function()
	if type(AZS_GetCombatTextCapabilities) ~= "function"
		or type(AZS_GetCombatTextEvents) ~= "function"
		or type(AZS_ProjectCombatTextAnchors) ~= "function"
		or type(AZS_RegisterCombatTextFrameHandler) ~= "function" then
		return false
	end
	local ok, caps = pcall(AZS_GetCombatTextCapabilities)
	return ok and type(caps) == "table" and type(caps.apiVersion) == "number" and caps.apiVersion >= 1
end

S.Wanted = function(ev, now)
	if type(ev) ~= "table" then
		return false
	end
	if type(ev.presentedAt) == "number" and now - ev.presentedAt > C.STALE then
		return false
	end
	if ev.kind == "damage" then
		return type(ev.amount) == "number" and ev.amount > 0
	end
	if ev.kind == "miss" then
		return C.db.misses and true or false
	end
	return false
end

local function Subscribe()
	-- With no cursor the game starts us at the newest hit, with no history.
	local ok, batch = pcall(AZS_GetCombatTextEvents, nil, 256)
	if ok and type(batch) == "table" and batch.cursor then
		S.cursor = batch.cursor
	end
end

S.ReadEvents = function(now)
	if not S.cursor then
		Subscribe()
		return
	end
	for round = 1, 8 do
		local ok, batch, err = pcall(AZS_GetCombatTextEvents, S.cursor, 256)
		if not ok then
			return
		end
		if type(batch) ~= "table" then
			if type(err) == "table" and err.code == "STREAM_CHANGED" then
				-- A new world, run or /reload: start over.
				N.Combat.ClearAll()
				S.cursor = nil
				Subscribe()
			end
			return
		end
		if batch.cursor then
			S.cursor = batch.cursor
		end
		local events = batch.events
		if type(events) == "table" then
			local count = table.getn(events)
			for i = 1, count do
				local ev = events[i]
				if S.Wanted(ev, now) then
					N.Combat.NoteHit(ev, now)
					N.Icons.NoteSource(ev)
					if ev.abilityName and ev.icon and AUI.LearnIcon then AUI.LearnIcon(ev.abilityName, ev.icon) end
					if AUI.NoteHitValue then AUI.NoteHitValue(ev) end
					N.Combat.nPending = N.Combat.nPending + 1
					N.Combat.pending[N.Combat.nPending] = ev
				end
			end
		end
		if not batch.hasMore then
			return
		end
	end
end
