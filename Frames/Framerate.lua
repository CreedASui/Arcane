-- Arcane UI: frame the game's native FPS readout without replacing it.
-- The 1.12 client owns the live number and Ctrl+R toggle; Arcane themes and positions both strings.
local C = Arcane
local DEFAULTS = { enabled = false }

local WIDTH, HEIGHT = 108, 28
local LABEL_WIDTH, VALUE_WIDTH, VALUE_GAP = 40, 46, 5
local TEXT_Y = -1

local db, frame, label, value, art, mover
local themeState = { palStamp = -1, styleStamp = -1 }
local displayState = { shown = nil, elapsed = 0, themeElapsed = 0 }

local function NativeShown()
	return value and value.IsVisible and value:IsVisible() and true or false
end

local function PositionReadout()
	-- Center the combined "FPS: 130.4" group, not the two strings separately.
	label:ClearAllPoints()
	label:SetPoint("RIGHT", frame, "CENTER", -9, TEXT_Y)
	value:ClearAllPoints()
	value:SetPoint("LEFT", label, "RIGHT", VALUE_GAP, 0)
end

local function ApplyTheme()
	local pal = C.Pal()
	local styleStamp = C.BarStyles and C.BarStyles.Stamp and C.BarStyles.Stamp() or 0
	local palStamp = C.palStamp or 0
	if themeState.palStamp == palStamp and themeState.styleStamp == styleStamp then return end
	themeState.palStamp, themeState.styleStamp = palStamp, styleStamp

	local red, green, blue = C.PanelMetal(pal)
	for i = 1, table.getn(art) do
		C.Color(art[i], red, green, blue, 1)
	end
	C.TextColor(label, pal.title[1], pal.title[2], pal.title[3])
	C.TextColor(value, pal.title[1], pal.title[2], pal.title[3])
end

local function SetShown(on)
	on = on and true or false
	if not frame or not label or not value then return end

	-- Use the game's own Ctrl+R handler so its native state and timer stay in step.
	if NativeShown() ~= on then
		if type(ToggleFramerate) == "function" then
			ToggleFramerate()
		else
			if on then
				label:Show()
				value:Show()
			else
				label:Hide()
				value:Hide()
			end
		end
	end

	-- Keep the pair together even if a client build exposes a partial native state.
	if label:IsVisible() ~= on then
		if on then label:Show() else label:Hide() end
	end
	if value:IsVisible() ~= on then
		if on then value:Show() else value:Hide() end
	end

	db.enabled = on
	if on then frame:Show() else frame:Hide() end
	displayState.shown = on
end

local function SyncFromGame()
	local shown = NativeShown()
	if label and label:IsVisible() ~= shown then
		if shown then label:Show() else label:Hide() end
	end
	if db then db.enabled = shown end
	if frame then
		if shown then frame:Show() else frame:Hide() end
	end
	if displayState.shown ~= shown then
		displayState.shown = shown
		if C.RefreshHub then C.RefreshHub() end
	end
end

C.OnInit(function()
	db = C.DB("fps", DEFAULTS)

	-- WoW 1.12 splits the native readout into "FPS:" and its separately updated number.
	label = getglobal("FramerateLabel")
	value = getglobal("FramerateText")
	if not label or not value or type(label.ClearAllPoints) ~= "function"
			or type(value.ClearAllPoints) ~= "function" then return end

	frame = CreateFrame("Frame", "ArcaneFPSPanel", UIParent)
	frame:SetFrameStrata("MEDIUM")
	frame:SetWidth(WIDTH)
	frame:SetHeight(HEIGHT)

	-- Transparent open-bottom half-frame: one top rail and two short side rails.
	-- There is deliberately no fill, backdrop or lower rail.
	art = {}
	local top = C.Tex(frame, "BORDER", C.ART .. "PanelRailT")
	top:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, 0)
	top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, 0)
	top:SetHeight(6)
	table.insert(art, top)

	local left = C.Tex(frame, "BORDER", C.ART .. "PanelRailL")
	left:SetWidth(6)
	left:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -2)
	left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 7)
	table.insert(art, left)

	local right = C.Tex(frame, "BORDER", C.ART .. "PanelRailR")
	right:SetWidth(6)
	right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -2)
	right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 7)
	table.insert(art, right)

	for _, corner in ipairs({
		{ "TOPLEFT", "PanelCornerTL" },
		{ "TOPRIGHT", "PanelCornerTR" },
	}) do
		local t = C.Tex(frame, "ARTWORK", C.ART .. corner[2])
		t:SetWidth(9)
		t:SetHeight(9)
		t:SetPoint("CENTER", frame, corner[1], corner[1] == "TOPLEFT" and 6 or -6, -1)
		table.insert(art, t)
	end

	-- Keep both native strings; do not create a duplicate FPS counter.
	C.SetFace(label, C.FONT, 14, "OUTLINE")
	C.SetFace(value, C.FONT, 14, "OUTLINE")
	label:SetJustifyH("RIGHT")
	value:SetJustifyH("LEFT")
	label:SetWidth(LABEL_WIDTH)
	value:SetWidth(VALUE_WIDTH)
	label:SetHeight(20)
	value:SetHeight(20)
	label:SetShadowColor(0, 0, 0, 1)
	value:SetShadowColor(0, 0, 0, 1)
	label:SetShadowOffset(1, -1)
	value:SetShadowOffset(1, -1)
	PositionReadout()

	ApplyTheme()

	-- Arcane's native mover and saved position. The edit hitbox is transparent and unlabelled.
	mover = C.Movable(frame, "fps", "FPS display", function(f)
		f:ClearAllPoints()
		if ArcaneBar then
			f:SetPoint("BOTTOM", ArcaneBar, "TOP", 0, 8)
		else
			f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
		end
	end)
	mover.box:SetBackdrop(nil)
	mover.box.text:Hide()

	-- Restore the saved checkbox state through the same native handler used by Ctrl+R.
	SetShown(db.enabled)

	C.OnWorld(function()
		PositionReadout()
		SetShown(db.enabled)
	end)

	-- Ctrl+R is handled by the game. Poll only to mirror its visibility into the Options checkbox.
	local watch = CreateFrame("Frame", "ArcaneFPSThemeDriver")
	watch:SetScript("OnUpdate", function()
		local dt = arg1 or 0
		displayState.elapsed = displayState.elapsed + dt
		displayState.themeElapsed = displayState.themeElapsed + dt
		if displayState.elapsed >= 0.15 then
			displayState.elapsed = 0
			SyncFromGame()
		end
		if displayState.themeElapsed >= 0.5 then
			displayState.themeElapsed = 0
			ApplyTheme()
		end
	end)
end)

C.RegisterPart({
	key = "fps", name = "FPS display",
	note = "The game's FPS readout in Arcane lettering and a small open metal frame. Ctrl+R toggles it too.",
	get = function() return db and db.enabled end,
	set = function(on) SetShown(on) end,
})
