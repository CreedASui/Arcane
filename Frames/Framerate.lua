-- Arcane UI: theme and reposition the game's native FPS readout.
-- The 1.12 client owns the live number; the Options checkbox becomes its only toggle.
local C = Arcane
local DEFAULTS = { enabled = false }

-- A generous move-only grab box around the compact native text.
local WIDTH, HEIGHT = 144, 36
local LABEL_WIDTH, VALUE_WIDTH, VALUE_GAP = 40, 46, 5
local TEXT_Y = 0

local db, frame, label, value, mover
local themeState = { palStamp = -1, styleStamp = -1 }
local displayState = { shown = nil, elapsed = 0, themeElapsed = 0 }

local function NativeShown()
	return value and value.IsVisible and value:IsVisible() and true or false
end

local function SuppressCtrlRToggle()
	-- Match the game's existing FPS binding only. Never overwrite a different Ctrl+R action.
	if type(GetBindingAction) ~= "function" or type(SetBinding) ~= "function" then return end
	local ok, action = pcall(GetBindingAction, "CTRL-R")
	if ok and action == "TOGGLEFPS" then
		pcall(SetBinding, "CTRL-R")
	end
	-- Leave the player's saved keymap untouched.
end

local function PositionReadout()
	-- Center the combined "FPS: 130.4" group rather than each string independently.
	label:ClearAllPoints()
	label:SetPoint("RIGHT", frame, "CENTER", -6, TEXT_Y)
	value:ClearAllPoints()
	value:SetPoint("LEFT", label, "RIGHT", VALUE_GAP, 0)
end

local function PreserveSavedTextPosition()
	-- The larger mover grows 24 px on each side and 7 px vertically. Shift its saved
	-- top-left by the inverse so an already-positioned FPS readout stays where it was.
	if db.moverBoxVersion then return end
	local root = C.Root()
	local pos = root and type(root.pos) == "table" and root.pos.fps
	if type(pos) == "table" then
		local scale = frame:GetScale() or 1
		if tonumber(pos.x) then pos.x = tonumber(pos.x) - 24 * scale end
		if tonumber(pos.y) then pos.y = tonumber(pos.y) + 7 * scale end
	end
	db.moverBoxVersion = 2
end

local function ApplyTheme()
	local pal = C.Pal()
	local styleStamp = C.BarStyles and C.BarStyles.Stamp and C.BarStyles.Stamp() or 0
	local palStamp = C.palStamp or 0
	if themeState.palStamp == palStamp and themeState.styleStamp == styleStamp then return end
	themeState.palStamp, themeState.styleStamp = palStamp, styleStamp
	C.TextColor(label, pal.title[1], pal.title[2], pal.title[3])
	C.TextColor(value, pal.title[1], pal.title[2], pal.title[3])
end

local function SetShown(on)
	on = on and true or false
	if not frame or not label or not value then return end

	-- Use the same native function as the original keybinding, but Ctrl+R is unbound.
	if NativeShown() ~= on and type(ToggleFramerate) == "function" then
		ToggleFramerate()
	end

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
	SuppressCtrlRToggle()

	-- WoW 1.12 splits the native readout into "FPS:" and its separately updated number.
	label = getglobal("FramerateLabel")
	value = getglobal("FramerateText")
	if not label or not value or type(label.ClearAllPoints) ~= "function"
			or type(value.ClearAllPoints) ~= "function" then return end

	-- Invisible movement root; the native FontStrings remain the only visible elements.
	frame = CreateFrame("Frame", "ArcaneFPSPanel", UIParent)
	frame:SetFrameStrata("MEDIUM")
	frame:SetWidth(WIDTH)
	frame:SetHeight(HEIGHT)
	PreserveSavedTextPosition()

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

	-- Arcane's native mover, with a transparent handle and its own saved position.
	mover = C.Movable(frame, "fps", "FPS display", function(f)
		f:ClearAllPoints()
		if ArcaneBar then
			f:SetPoint("BOTTOM", ArcaneBar, "TOP", 0, 1)
		else
			f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 193)
		end
	end)
	-- Keep the gold mover outline visible while Move frames is enabled, but leave
	-- its interior transparent so the native FPS text remains unobstructed.
	mover.box:SetBackdropColor(0, 0, 0, 0)
	mover.box.text:Hide()

	SetShown(db.enabled)

	C.OnWorld(function()
		SuppressCtrlRToggle()
		PositionReadout()
		SetShown(db.enabled)
	end)

	-- Poll only to mirror the native visibility into the Options checkbox.
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
	note = "Show or hide the game's FPS readout with this checkbox. Ctrl+R is disabled while Arcane is loaded.",
	get = function() return db and db.enabled end,
	set = function(on) SetShown(on) end,
})
