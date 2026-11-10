-- Arcane UI: frame the game's native FPS readout without replacing it.
-- The 1.12 client owns the live number; Arcane only themes and repositions its two FontStrings.
local C = Arcane

local WIDTH, HEIGHT = 132, 34
local LABEL_WIDTH, VALUE_WIDTH, VALUE_GAP = 38, 48, 6
local TEXT_Y = -1

local function PositionReadout(frame, label, value)
	-- Center the combined "FPS: 130.4" group, not the two strings separately.
	label:ClearAllPoints()
	label:SetPoint("RIGHT", frame, "CENTER", -9, TEXT_Y)
	value:ClearAllPoints()
	value:SetPoint("LEFT", label, "RIGHT", VALUE_GAP, 0)
end

local function ApplyTheme(art, label, value, state)
	local pal = C.Pal()
	local styleStamp = C.BarStyles and C.BarStyles.Stamp and C.BarStyles.Stamp() or 0
	local palStamp = C.palStamp or 0
	if state.palStamp == palStamp and state.styleStamp == styleStamp then return end
	state.palStamp, state.styleStamp = palStamp, styleStamp

	local red, green, blue = C.PanelMetal(pal)
	for i = 1, table.getn(art) do
		C.Color(art[i], red, green, blue, 1)
	end
	C.TextColor(label, pal.title[1], pal.title[2], pal.title[3])
	C.TextColor(value, pal.title[1], pal.title[2], pal.title[3])
end

C.OnInit(function()
	-- WoW 1.12 splits the native readout into "FPS:" and its separately updated number.
	local label = getglobal("FramerateLabel")
	local value = getglobal("FramerateText")
	if not label or not value or type(label.ClearAllPoints) ~= "function"
			or type(value.ClearAllPoints) ~= "function" then return end

	local frame = CreateFrame("Frame", "ArcaneFPSPanel", UIParent)
	frame:SetFrameStrata("MEDIUM")
	frame:SetWidth(WIDTH)
	frame:SetHeight(HEIGHT)

	-- Transparent open-bottom half-frame: one top rail and two short side rails.
	-- There is deliberately no fill, backdrop or lower rail.
	local art = {}
	local top = C.Tex(frame, "BORDER", C.ART .. "PanelRailT")
	top:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 0)
	top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, 0)
	top:SetHeight(6)
	table.insert(art, top)

	local left = C.Tex(frame, "BORDER", C.ART .. "PanelRailL")
	left:SetWidth(6)
	left:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -2)
	left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8)
	table.insert(art, left)

	local right = C.Tex(frame, "BORDER", C.ART .. "PanelRailR")
	right:SetWidth(6)
	right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -2)
	right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
	table.insert(art, right)

	for _, corner in ipairs({
		{ "TOPLEFT", "PanelCornerTL" },
		{ "TOPRIGHT", "PanelCornerTR" },
	}) do
		local t = C.Tex(frame, "ARTWORK", C.ART .. corner[2])
		t:SetWidth(12)
		t:SetHeight(12)
		t:SetPoint("CENTER", frame, corner[1], corner[1] == "TOPLEFT" and 8 or -8, -1)
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
	PositionReadout(frame, label, value)

	local themeState = { palStamp = -1, styleStamp = -1 }
	ApplyTheme(art, label, value, themeState)

	-- Arcane's own mover and saved position. Its edit overlay stays invisible so it
	-- doesn't cover the text or half-frame while the user is arranging the HUD.
	local mover = C.Movable(frame, "fps", "FPS display", function(f)
		f:ClearAllPoints()
		if ArcaneBar then
			f:SetPoint("BOTTOM", ArcaneBar, "TOP", 0, 8)
		else
			f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
		end
	end)
	mover.box:SetBackdrop(nil)
	mover.box.text:Hide()

	C.OnWorld(function()
		PositionReadout(frame, label, value)
	end)

	-- Full Class can change the active metal and text colors after the run class is read.
	local watch = CreateFrame("Frame", "ArcaneFPSThemeDriver")
	local elapsed = 0
	watch:SetScript("OnUpdate", function()
		elapsed = elapsed + (arg1 or 0)
		if elapsed < 0.5 then return end
		elapsed = 0
		ApplyTheme(art, label, value, themeState)
	end)
end)
