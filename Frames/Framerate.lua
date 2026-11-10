-- Arcane UI: a compact FPS readout using the same movable-frame system as every other part.
-- The value comes from the game's FPS API; the readout itself lives inside Arcane's movable root.
local C = Arcane
local DEFAULTS = { enabled = false }

local WIDTH, HEIGHT = 144, 36
local TEXT_WIDTH, TEXT_HEIGHT = 120, 20

local db, frame, readout, mover
local elapsed, themeElapsed = 0, 0
local themeState = { palStamp = -1, styleStamp = -1 }

local function SuppressCtrlRToggle()
	-- Match the game's existing FPS binding only. Never overwrite a different Ctrl+R action.
	if type(GetBindingAction) ~= "function" or type(SetBinding) ~= "function" then return end
	local ok, action = pcall(GetBindingAction, "CTRL-R")
	if ok and action == "TOGGLEFPS" then
		pcall(SetBinding, "CTRL-R")
	end
	-- Leave the player's saved keymap untouched.
end

local function HideNativeReadout()
	-- Arcane draws the value inside its movable frame, so hide the two stock strings.
	local label = getglobal("FramerateLabel")
	local value = getglobal("FramerateText")
	if label and type(label.Hide) == "function" then label:Hide() end
	if value and type(value.Hide) == "function" then value:Hide() end
end

local function PreserveSavedTextPosition()
	-- The move box grows 24 px on each side and 7 px vertically. Keep the readout's
	-- previous center when upgrading a saved FPS position to the larger movable root.
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
	C.TextColor(readout, pal.title[1], pal.title[2], pal.title[3])
end

local function SetShown(on)
	if not frame then return end
	on = on and true or false
	HideNativeReadout()
	db.enabled = on
	if on then frame:Show() else frame:Hide() end
end

C.OnInit(function()
	db = C.DB("fps", DEFAULTS)
	SuppressCtrlRToggle()
	HideNativeReadout()

	-- The text is a child of this root. Arcane's mover therefore moves the box and
	-- the FPS readout together, using the exact same path as the other movable parts.
	frame = CreateFrame("Frame", "ArcaneFPSPanel", UIParent)
	frame:SetFrameStrata("MEDIUM")
	frame:SetWidth(WIDTH)
	frame:SetHeight(HEIGHT)
	PreserveSavedTextPosition()

	readout = C.Text(frame, C.FONT, 14, "OUTLINE", "CENTER", TEXT_WIDTH)
	readout:SetPoint("CENTER", frame, "CENTER", 0, 0)
	readout:SetHeight(TEXT_HEIGHT)
	C.SetText(readout, "FPS: --")
	ApplyTheme()

	mover = C.Movable(frame, "fps", "FPS display", function(f)
		f:ClearAllPoints()
		if ArcaneBar then
			f:SetPoint("BOTTOM", ArcaneBar, "TOP", 0, 1)
		else
			f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 193)
		end
	end)
	-- Keep the standard Arcane gold outline visible in Move frames mode; no filled panel.
	mover.box:SetBackdropColor(0, 0, 0, 0)
	mover.box.text:Hide()

	SetShown(db.enabled)

	C.OnWorld(function()
		SuppressCtrlRToggle()
		HideNativeReadout()
		C.ApplyPos(mover)
		SetShown(db.enabled)
	end)

	local watch = CreateFrame("Frame", "ArcaneFPSDriver")
	watch:SetScript("OnUpdate", function()
		if not db.enabled then return end
		local dt = arg1 or 0
		elapsed = elapsed + dt
		themeElapsed = themeElapsed + dt
		if elapsed >= 0.25 then
			elapsed = 0
			local fps = GetFramerate()
			if type(fps) == "number" then
				C.SetText(readout, string.format("FPS: %d", math.floor(fps + 0.5)))
			end
		end
		if themeElapsed >= 0.5 then
			themeElapsed = 0
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
