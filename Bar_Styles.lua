-- Arcane UI: the skill bar's three visual treatments.
-- Slot logic stays in Bar.lua; this module owns only class selection, palettes and panel art.
local C = Arcane
local THEMES = C.BarStyleData
local CLASSIC, HYBRID, FULL_CLASS = 1, 2, 3
local EMBLEM_U = 76 / 110 * 0.85
local EMBLEM_W, EMBLEM_H = 512 * EMBLEM_U, 256 * EMBLEM_U
local EMBLEM_L, EMBLEM_R, EMBLEM_IN = 220, 292, 24
local RAIL_H, BASE_RAIL_H = 16 * 76 / 110, C.PANEL_RAIL or 8
local PANEL_CORNER = C.PANEL_CORNER or 16
local HYBRID_SIGIL = (C.PANEL_SIGIL or 122) * 1.14
local HYBRID_OUT = HYBRID_SIGIL * 0.40
local HYBRID_FOOT = HYBRID_SIGIL * 25 / 370
local state = {
	db = nil, class = nil, runId = nil, readClock = 0, stamp = 0,
	palette = {}, paletteBase = nil, palettePalStamp = -1,
	paletteStyleStamp = -1, paletteMode = 0, paletteClass = nil,
}

local M = {}
C.BarStyles = M
M.CLASSIC, M.HYBRID, M.FULL_CLASS = CLASSIC, HYBRID, FULL_CLASS

local function DB()
	if not state.db then state.db = C.DB("bar") end
	if state.db.style == nil then state.db.style = CLASSIC end
	return state.db
end

local function Mode()
	local mode = tonumber(DB().style) or CLASSIC
	if mode < CLASSIC or mode > FULL_CLASS then
		mode = CLASSIC
		DB().style = mode
	end
	return mode
end

local function ClassKey(value)
	if type(value) ~= "string" then return nil end
	local _, _, key = string.find(string.lower(value), "(%a+)$")
	if key and THEMES[key] then return key end
	return nil
end

local function CurrentTheme()
	local key = state.class or ClassKey(DB().heroClass)
	if not key and type(UnitClass) == "function" then
		local _, class = UnitClass("player")
		key = ClassKey(class)
	end
	key = key or "warrior"
	return THEMES[key], key
end

local function ReadRunClass()
	if type(AZS_GetMeterContext) ~= "function" or type(AZS_GetMeterLoadout) ~= "function" then return end
	local context = C.Call(AZS_GetMeterContext)
	if type(context) ~= "table" or not context.runId or context.runId == state.runId then return end
	local loadout = C.Call(AZS_GetMeterLoadout, { apiVersion = 1, runId = context.runId })
	local actors = type(loadout) == "table" and type(loadout.actors) == "table" and loadout.actors
	local me = actors and actors[context.localOwnerId or loadout.ownerId or ""]
	local key = type(me) == "table" and ClassKey(me.classKey)
	if not key then return end -- the loadout may not be ready yet; try again next second
	state.runId = context.runId
	if state.class ~= key then
		state.class = key
		DB().heroClass = key
		state.stamp = state.stamp + 1
	end
end

function M.Mode()
	return Mode()
end

function M.SetMode(mode)
	mode = tonumber(mode)
	if mode ~= CLASSIC and mode ~= HYBRID and mode ~= FULL_CLASS then return false end
	local db = DB()
	if db.style == mode then return false end
	db.style = mode
	state.stamp = state.stamp + 1
	state.paletteBase = nil
	state.readClock = 0
	if mode ~= CLASSIC then M.Update(0, true) end
	return true
end

function M.Stamp()
	return state.stamp
end

function M.Update(dt, force)
	if Mode() == CLASSIC then return end
	state.readClock = state.readClock - (dt or 0)
	if force or state.readClock <= 0 then
		state.readClock = 1
		ReadRunClass()
	end
end

function M.Palette()
	local base = C.Pal()
	local mode = Mode()
	if mode == CLASSIC then return base end
	local theme, key = CurrentTheme()
	if state.paletteBase ~= base or state.palettePalStamp ~= C.palStamp
			or state.paletteStyleStamp ~= state.stamp or state.paletteMode ~= mode
			or state.paletteClass ~= key then
		for k, v in pairs(base) do state.palette[k] = v end
		state.palette.title = theme.title
		state.palette.rim = theme.rim
		state.palette.gem = theme.gem
		state.palette.glow = theme.glow
		state.palette.trough = theme.trough
		state.palette.mc = theme.mc
		state.palette.fillA = { theme.fill[1] * 0.55, theme.fill[2] * 0.55, theme.fill[3] * 0.55 }
		state.palette.fillM = theme.fill
		state.palette.fillB = theme.gem
		state.paletteBase = base
		state.palettePalStamp = C.palStamp
		state.paletteStyleStamp = state.stamp
		state.paletteMode = mode
		state.paletteClass = key
	end
	return state.palette
end

function M.PanelMetal(pal)
	if Mode() == CLASSIC or Mode() == HYBRID then return C.PanelMetal(pal) end
	local theme = CurrentTheme()
	return theme.metal[1], theme.metal[2], theme.metal[3]
end

local function PlaceEmblem(texture, frame, side, emblem)
	local left = side == "LEFT"
	local middle = left and EMBLEM_L or EMBLEM_R
	local x = left and (EMBLEM_IN - middle * EMBLEM_U) or (-EMBLEM_IN - middle * EMBLEM_U)
	texture:SetTexture(C.ART .. "PanelEmblem" .. emblem .. (left and "L" or "R"))
	texture:SetWidth(EMBLEM_W)
	texture:SetHeight(EMBLEM_H)
	texture:ClearAllPoints()
	texture:SetPoint("TOPLEFT", frame, side, x, EMBLEM_H / 2)
	C.Vis(texture, true)
end

local function EnsureClassEmblems(panel)
	if panel.classEmblems then return end
	panel.classEmblems = {
		C.Tex(panel.frame, "OVERLAY", C.ART .. "Glow"),
		C.Tex(panel.frame, "OVERLAY", C.ART .. "Glow"),
	}
	C.Vis(panel.classEmblems[1], false)
	C.Vis(panel.classEmblems[2], false)
end

local function EnsureHybridArcane(panel)
	if panel.hybridArcane then return end
	local frame = panel.frame
	panel.hybridArcane = C.Tex(frame, "OVERLAY", C.ART .. "PanelHybridArcane.tga")
	panel.hybridGem = C.Tex(frame, "OVERLAY", C.ART .. "PanelHybridArcaneGem.tga")
	-- The Arcane dragon faces inward from the right endcap.
	panel.hybridArcane:SetTexCoord(1, 0, 0, 1)
	panel.hybridGem:SetTexCoord(1, 0, 0, 1)
	for _, texture in ipairs({ panel.hybridArcane, panel.hybridGem }) do
		texture:SetWidth(HYBRID_SIGIL)
		texture:SetHeight(HYBRID_SIGIL)
		texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", HYBRID_OUT, -HYBRID_FOOT)
		C.Vis(texture, false)
	end
end

local function RestoreBasePanel(panel)
	local frame = panel.frame
	panel.railT:SetTexture(C.ART .. "PanelRailT")
	panel.railB:SetTexture(C.ART .. "PanelRailB")
	panel.railT:SetHeight(BASE_RAIL_H)
	panel.railB:SetHeight(BASE_RAIL_H)
	panel.railT:ClearAllPoints()
	panel.railT:SetPoint("TOPLEFT", frame, "TOPLEFT", PANEL_CORNER, 0)
	panel.railT:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PANEL_CORNER, 0)
	panel.railB:ClearAllPoints()
	panel.railB:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PANEL_CORNER, 0)
	panel.railB:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PANEL_CORNER, 0)
	panel.fill:SetTexture(panel.baseFill or (C.ART .. "PanelFill"))
	for i = 1, table.getn(panel.ends) do C.Vis(panel.ends[i], true) end
	if panel.sigils then
		C.Vis(panel.sigils[1], true)
		C.Vis(panel.sigils[2], true)
	end
	if panel.classEmblems then
		C.Vis(panel.classEmblems[1], false)
		C.Vis(panel.classEmblems[2], false)
	end
	if panel.hybridArcane then C.Vis(panel.hybridArcane, false) end
	if panel.hybridGem then C.Vis(panel.hybridGem, false) end
end

function M.Apply(panel)
	if not panel or not panel.sigils or not panel.railT or not panel.railB then return end
	local mode = Mode()
	local theme, key = CurrentTheme()
	if panel.barStyleMode == mode and panel.barStyleClass == key then return end
	panel.barStyleMode, panel.barStyleClass = mode, key
	RestoreBasePanel(panel)
	if mode == CLASSIC then return end
	EnsureClassEmblems(panel)
	if mode == HYBRID then
		EnsureHybridArcane(panel)
		C.Vis(panel.sigils[1], false)
		C.Vis(panel.sigils[2], false)
		C.Vis(panel.hybridArcane, true)
		C.Vis(panel.hybridGem, true)
		for i = 1, table.getn(panel.endLeft or {}) do C.Vis(panel.endLeft[i], false) end
		for i = 1, table.getn(panel.endRight or {}) do C.Vis(panel.endRight[i], false) end
		PlaceEmblem(panel.classEmblems[1], panel.frame, "LEFT", theme.emblem)
		return
	end
	for i = 1, table.getn(panel.ends) do C.Vis(panel.ends[i], false) end
	C.Vis(panel.sigils[1], false)
	C.Vis(panel.sigils[2], false)
	PlaceEmblem(panel.classEmblems[1], panel.frame, "LEFT", theme.emblem)
	PlaceEmblem(panel.classEmblems[2], panel.frame, "RIGHT", theme.emblem)
	local y = RAIL_H / 2 - BASE_RAIL_H / 2
	panel.railT:SetTexture(C.ART .. "PanelRail" .. theme.emblem .. "T")
	panel.railT:SetHeight(RAIL_H)
	panel.railT:ClearAllPoints()
	panel.railT:SetPoint("TOPLEFT", panel.frame, "TOPLEFT", 0, y)
	panel.railT:SetPoint("TOPRIGHT", panel.frame, "TOPRIGHT", 0, y)
	panel.railB:SetTexture(C.ART .. "PanelRail" .. theme.emblem .. "B")
	panel.railB:SetHeight(RAIL_H)
	panel.railB:ClearAllPoints()
	panel.railB:SetPoint("BOTTOMLEFT", panel.frame, "BOTTOMLEFT", 0, -y)
	panel.railB:SetPoint("BOTTOMRIGHT", panel.frame, "BOTTOMRIGHT", 0, -y)
	panel.fill:SetTexture(C.ART .. "PanelGlass")
end

function M.Theme(panel, pal)
	if not panel then return end
	M.Apply(panel)
	local mode = Mode()
	if mode == CLASSIC then
		C.PanelTheme(panel, pal)
		return
	end
	local theme = CurrentTheme()
	local mr, mg, mb
	if mode == HYBRID then
		mr, mg, mb = C.PanelMetal(pal)
	else
		mr, mg, mb = theme.metal[1], theme.metal[2], theme.metal[3]
	end
	for i = 1, table.getn(panel.metal) do
		panel.metal[i]:SetVertexColor(mr, mg, mb, 1)
	end
	if mode == HYBRID then
		local fill = theme.fill
		panel.fill:SetVertexColor(fill[1] * 0.48, fill[2] * 0.48, fill[3] * 0.48, 0.97)
		panel.hybridArcane:SetVertexColor(1, 1, 1, 1)
		panel.hybridGem:SetVertexColor(theme.gem[1], theme.gem[2], theme.gem[3], 1)
		panel.classEmblems[1]:SetVertexColor(1, 1, 1, 1)
	else
		local fill = theme.fill
		panel.fill:SetVertexColor(fill[1], fill[2], fill[3], 0.97)
		panel.railT:SetVertexColor(1, 1, 1, 1)
		panel.railB:SetVertexColor(1, 1, 1, 1)
		panel.classEmblems[1]:SetVertexColor(1, 1, 1, 1)
		panel.classEmblems[2]:SetVertexColor(1, 1, 1, 1)
	end
end

C.OnInit(function()
	DB()
end)
