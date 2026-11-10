-- Arcane UI: give the game's native FPS readout a home in the shared HUD style.
-- The native label remains the source of the number; Arcane only restyles and reanchors it.
local C = Arcane

local WIDTH, HEIGHT = 188, 58
local LABEL_Y = 15

local function ApplyTheme(panel, label, state)
	local pal = C.Pal()
	local styleStamp = C.BarStyles and C.BarStyles.Stamp and C.BarStyles.Stamp() or 0
	local palStamp = C.palStamp or 0
	if state.palStamp == palStamp and state.styleStamp == styleStamp then return end
	state.palStamp, state.styleStamp = palStamp, styleStamp
	C.PanelTheme(panel, pal)
	C.TextColor(label, pal.title[1], pal.title[2], pal.title[3])
end

C.OnInit(function()
	-- Azeroth Survivors updates this FontString itself. Keep that live readout rather than
	-- running a second FPS counter beside it.
	local label = getglobal("FramerateLabel")
	if not label or type(label.ClearAllPoints) ~= "function" then return end

	local frame = CreateFrame("Frame", "ArcaneFPSPanel", UIParent)
	frame:SetFrameStrata("LOW")
	frame:SetWidth(WIDTH)
	frame:SetHeight(HEIGHT)

	-- The open upper half is deliberate: it leaves room to tuck the panel against the HUD.
	-- The readout sits in the slightly taller lower shelf.
	local panel = C.Panel(frame, false)
	local themeState = { palStamp = -1, styleStamp = -1 }
	ApplyTheme(panel, label, themeState)

	C.SetFace(label, C.FONT, 15, "OUTLINE")
	label:SetJustifyH("CENTER")
	label:SetWidth(WIDTH - 20)
	label:SetHeight(22)
	label:SetShadowColor(0, 0, 0, 1)
	label:SetShadowOffset(1, -1)
	label:ClearAllPoints()
	label:SetPoint("CENTER", frame, "BOTTOM", 0, LABEL_Y)

	-- This is an Arcane-native mover. Its position is saved under ArcaneDB.pos.fps.
	C.Movable(frame, "fps", "FPS display", function(f)
		f:ClearAllPoints()
		if ArcaneBar then
			f:SetPoint("BOTTOM", ArcaneBar, "TOP", 0, 8)
		else
			f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
		end
	end)

	-- Full Class can change its metal and text color when the active class is discovered.
	local watch = CreateFrame("Frame", "ArcaneFPSThemeDriver")
	local elapsed = 0
	watch:SetScript("OnUpdate", function()
		elapsed = elapsed + (arg1 or 0)
		if elapsed < 0.5 then return end
		elapsed = 0
		ApplyTheme(panel, label, themeState)
	end)
end)
