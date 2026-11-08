-- Safe game API calls and shared learned-source icon lookup.
local C = Arcane

------------------------------------------------------------------------ calling the game safely
-- pcall without stray arguments: the game's strict functions (the meter API) count a passed nil
-- as an argument and refuse the call.
function C.Call(fn, a, b)
	if type(fn) ~= "function" then return nil end
	local ok, r1, r2, r3
	if b ~= nil then
		ok, r1, r2, r3 = pcall(fn, a, b)
	elseif a ~= nil then
		ok, r1, r2, r3 = pcall(fn, a)
	else
		ok, r1, r2, r3 = pcall(fn)
	end
	if ok then return r1, r2, r3 end
	return nil
end

------------------------------------------------------------------------ icons by name
-- Spell icons the damage numbers have seen, by the spell's name: for meter lines that come by
-- name only (the game's older meter getters).
C.icons = {}
function C.LearnIcon(name, icon)
	if type(name) == "string" and name ~= "" and type(icon) == "string" and icon ~= "" then C.icons[name] = icon end
end

-- The meter's lines' own icons, by their sourceKey. Each hit's combat text names the line it counts
-- toward (meterSourceKey): a proc that floats in another spell's look (Shadow Weaving as Shadow Word:
-- Pain) has a line, and an icon, of its own. The meter's reads note them; a key not seen yet asks
-- the meter once (at most every 2 seconds), whether the meter window is up or not.
C.sourceIcons = {}
local sourceAsked = -10
function C.NoteSources(sources)
	if type(sources) ~= "table" then return end
	for key, src in pairs(sources) do
		local icon = type(src) == "table" and src.icon
		if type(icon) == "table" then
			if icon.status == "ready" and type(icon.path) == "string" and icon.path ~= "" then
				C.sourceIcons[key] = icon.path
			elseif icon.status == "missing" and not C.sourceIcons[key] then
				C.sourceIcons[key] = false -- the game has none: no asking again
			end
		end
	end
end
-- a read of the meter's lines, at most every 2 seconds
function C.RefreshSources()
	if GetTime() - sourceAsked < 2 or type(AZS_GetMeterSnapshot) ~= "function" then return end
	sourceAsked = GetTime()
	local context = C.Call(AZS_GetMeterContext)
	if type(context) == "table" and context.runId then
		local snap = C.Call(AZS_GetMeterSnapshot, { apiVersion = 1, runId = context.runId, metric = "damage", scope = "self",
			period = "run", groupBy = "actor_source", windowSeconds = 0 })
		if type(snap) == "table" then C.NoteSources(snap.sources) end
	end
end
function C.SourceIcon(key)
	if type(key) ~= "string" or key == "" then return nil end
	local icon = C.sourceIcons[key]
	if icon == nil then
		C.RefreshSources()
		icon = C.sourceIcons[key]
	end
	return icon or nil
end
