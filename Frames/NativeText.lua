-- Arcane UI: theme positive floating status text while preserving the game's message behavior.
-- Zone and subzone announcements are intentionally left completely to Blizzard.
local C = Arcane

local AURA_TYPES = { "SPELL_CAST", "AURA_START", "AURA_END" }
local HEAL_TYPES = { "HEAL", "HEAL_CRIT", "PERIODIC_HEAL" }

local themedCombatFonts = false
local lastPalette = {}
local poll = 0

local function SetFont(fs, face)
	if not fs or type(fs.GetFont) ~= "function" then return end
	local _, size = fs:GetFont()
	if type(size) ~= "number" or size <= 0 then size = 20 end
	if fs.cface ~= face or fs.csize ~= size or fs.cflags ~= "OUTLINE" then
		C.SetFace(fs, face, size, "OUTLINE")
	end
	if type(fs.SetShadowColor) == "function" then fs:SetShadowColor(0, 0, 0, 1) end
	if type(fs.SetShadowOffset) == "function" then fs:SetShadowOffset(1, -1) end
end

local function SetCombatColor(info, name, color)
	local entry = info[name]
	if type(entry) == "table" then
		entry.r, entry.g, entry.b = color[1], color[2], color[3]
	end
end

local function ApplyCombatText(pal)
	local info = COMBAT_TEXT_TYPE_INFO
	if type(info) ~= "table" then return false end

	-- Preserve the client's message types, show/filter flags, event handling and animation.
	-- Only retint the positive aura/cast and healing categories that Blizzard paints green.
	for i = 1, table.getn(AURA_TYPES) do
		SetCombatColor(info, AURA_TYPES[i], pal.title)
	end
	for i = 1, table.getn(HEAL_TYPES) do
		SetCombatColor(info, HEAL_TYPES[i], pal.mc)
	end

	if not themedCombatFonts then
		local found = 0
		for i = 1, 20 do
			local fs = getglobal("CombatText" .. i)
			if fs then
				SetFont(fs, C.FONT)
				found = found + 1
			end
		end
		themedCombatFonts = found == 20
	end
	return true
end

local function ApplyTheme()
	local pal = C.Pal()
	local changed = pal.title[1] ~= lastPalette.titleR
		or pal.title[2] ~= lastPalette.titleG
		or pal.title[3] ~= lastPalette.titleB
		or pal.mc[1] ~= lastPalette.mcR
		or pal.mc[2] ~= lastPalette.mcG
		or pal.mc[3] ~= lastPalette.mcB
	if not changed then return end

	lastPalette.titleR, lastPalette.titleG, lastPalette.titleB = pal.title[1], pal.title[2], pal.title[3]
	lastPalette.mcR, lastPalette.mcG, lastPalette.mcB = pal.mc[1], pal.mc[2], pal.mc[3]
	ApplyCombatText(pal)
end

C.OnInit(function()
	local watch = CreateFrame("Frame", "ArcaneNativeTextTheme")
	watch:RegisterEvent("ADDON_LOADED")
	watch:RegisterEvent("PLAYER_ENTERING_WORLD")
	watch:SetScript("OnEvent", function()
		if event == "ADDON_LOADED" then
			ApplyCombatText(C.Pal())
		end
		ApplyTheme()
		if not themedCombatFonts then ApplyCombatText(C.Pal()) end
	end)
	watch:SetScript("OnUpdate", function()
		poll = poll + (arg1 or 0)
		if poll < 0.2 then return end
		poll = 0
		ApplyTheme()
		if not themedCombatFonts then ApplyCombatText(C.Pal()) end
	end)

	ApplyTheme()
	ApplyCombatText(C.Pal())
end)
