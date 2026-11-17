-- Damage-number options: own the settings window and its refresh behavior.
local AUI = Arcane
local N = AUI.Numbers
local S = N.Options
local C = N.Config

------------------------------------------------------------------------------
-- The options window (/Arcane numbers)

local options

local function Fill(parent, drawLayer, r, g, b, a)
	local texture = parent:CreateTexture(nil, drawLayer)
	texture:SetTexture(C.FLAT)
	texture:SetVertexColor(r, g, b, a)
	return texture
end

local function Text(parent, size, r, g, b)
	local text = parent:CreateFontString(nil, "OVERLAY")
	if AUI.SetFace then AUI.SetFace(text, C.FONTS[1].path, size) else text:SetFont(C.FONTS[1].path, size) end
	text:SetTextColor(r, g, b)
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(1, -1)
	return text
end

local function PaintButton(button)
	if button.selected then
		button:SetBackdropColor(0.50, 0.38, 0.07, 1)
		button:SetBackdropBorderColor(0.91, 0.70, 0.30, 1)
	elseif button.hot then
		button:SetBackdropColor(0.24, 0.24, 0.28, 1)
		button:SetBackdropBorderColor(0.65, 0.65, 0.7, 1)
	else
		button:SetBackdropColor(0.13, 0.13, 0.16, 1)
		button:SetBackdropBorderColor(0.32, 0.32, 0.36, 1)
	end
end

local function MakeButton(parent, width, height, label, onClick)
	local button = CreateFrame("Button", nil, parent)
	button:SetWidth(width)
	button:SetHeight(height)
	button:EnableMouse(true)
	button:SetBackdrop({ bgFile = C.FLAT, edgeFile = C.FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
	button.text = Text(button, 11, 1, 1, 1)
	button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
	button.text:SetText(label or "")
	button.hot, button.selected = false, false
	button:SetScript("OnEnter", function()
		button.hot = true
		PaintButton(button)
	end)
	button:SetScript("OnLeave", function()
		button.hot = false
		PaintButton(button)
	end)
	button:SetScript("OnClick", onClick)
	PaintButton(button)
	return button
end

S.OnSettingChanged = function(key)
	if key == "short" or key == "count" or key == "icons" then
		N.Widgets.RefreshAllText()
	elseif key == "font" then
		N.Widgets.ApplyFontAll()
	end
end

local function MakeCheck(parent, y, label, key)
	local check = CreateFrame("Button", nil, parent)
	check:SetWidth(272)
	check:SetHeight(20)
	check:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
	check:EnableMouse(true)
	check.edge = Fill(check, "BORDER", 0.38, 0.38, 0.42, 1)
	check.edge:SetWidth(14)
	check.edge:SetHeight(14)
	check.edge:SetPoint("LEFT", check, "LEFT", 0, 0)
	check.box = Fill(check, "ARTWORK", 0.06, 0.06, 0.08, 1)
	check.box:SetPoint("TOPLEFT", check.edge, "TOPLEFT", 1, -1)
	check.box:SetPoint("BOTTOMRIGHT", check.edge, "BOTTOMRIGHT", -1, 1)
	check.mark = Fill(check, "OVERLAY", 0.91, 0.70, 0.30, 1)
	check.mark:SetPoint("TOPLEFT", check.edge, "TOPLEFT", 3, -3)
	check.mark:SetPoint("BOTTOMRIGHT", check.edge, "BOTTOMRIGHT", -3, 3)
	check.label = Text(check, 11, 0.92, 0.92, 0.92)
	check.label:SetPoint("LEFT", check.edge, "RIGHT", 8, 0)
	C.LText(check.label, label)
	check.key = key
	check:SetScript("OnEnter", function()
		check.label:SetTextColor(0.98, 0.85, 0.52)
	end)
	check:SetScript("OnLeave", function()
		check.label:SetTextColor(0.92, 0.92, 0.92)
	end)
	check:SetScript("OnClick", function()
		C.db[key] = not C.db[key]
		S.OnSettingChanged(key)
		S.RefreshOptions()
	end)
	return check
end

S.RefreshOptions = function()
	if not options or not C.db then
		return
	end
	local o = options
	o.toggle.selected = C.db.enabled
	if C.db.enabled then
		o.toggle.text:SetText(C.L("ON: Arcane UI draws your damage"))
	else
		o.toggle.text:SetText(C.L("OFF: the game's own numbers"))
	end
	PaintButton(o.toggle)
	for i = 1, 3 do
		local button = o.presets[i]
		button.selected = C.db.preset == button.preset
		PaintButton(button)
	end
	o.styleNote:SetText(C.L(C.PRESET_NOTES[C.db.preset] or ""))
	for i = 1, table.getn(o.motions) do
		local button = o.motions[i]
		button.selected = C.db.motion == button.motion
		PaintButton(button)
	end
	o.motionNote:SetText(C.L(C.MOTION_NOTES[C.db.motion] or ""))
	local look = C.db.look or "custom"
	o.lookText:SetText(C.L(C.LOOKS.names[look] or "Custom"))
	o.lookNote:SetText(C.L(C.LOOKS.notes[look] or ""))
	o.sizeText:SetText(string.format("%d%%", math.floor(C.db.size * 100 + 0.5)))
	o.fontText:SetText(C.FONTS[C.db.font].name)
	o.backText:SetText(C.L(C.CRIT_BACKDROPS.names[C.db.backdrop or "none"] or "None"))
	-- A look brings its own letters and crit backdrop: your own picks wait, dimmed, for Custom.
	local own = (look == "custom") and 1 or 0.4
	o.fontHead:SetAlpha(own)
	o.fontText:SetAlpha(own)
	o.backdropHead:SetAlpha(own)
	o.backText:SetAlpha(own)
	for i = 1, table.getn(o.checks) do
		local check = o.checks[i]
		if C.db[check.key] then
			check.mark:Show()
		else
			check.mark:Hide()
		end
	end
end

local function BuildOptions()
	local o = CreateFrame("Frame", "ArcaneNumbersOptions", UIParent)
	options = o
	o:SetWidth(300)
	o:SetHeight(700)
	o:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
	if AUI.AboveHub then AUI.AboveHub(o) else o:SetFrameStrata("DIALOG") end
	o:SetBackdrop({ bgFile = C.FLAT, edgeFile = C.FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
	o:SetBackdropColor(0.05, 0.05, 0.07, 0.96)
	o:SetBackdropBorderColor(0, 0, 0, 1)
	o:EnableMouse(true)
	o:SetMovable(true)
	o:SetClampedToScreen(true)
	o:RegisterForDrag("LeftButton")
	o:SetScript("OnDragStart", function()
		o:StartMoving()
	end)
	o:SetScript("OnDragStop", function()
		o:StopMovingOrSizing()
	end)
	o:Hide()
	if type(UISpecialFrames) == "table" then
		table.insert(UISpecialFrames, "ArcaneNumbersOptions") -- Escape closes it
	end

	local title = Text(o, 16, 1, 0.82, 0.25)
	title:SetPoint("TOPLEFT", o, "TOPLEFT", 14, -14)
	C.LText(title, "Damage numbers")
	local version = Text(o, 10, 0.55, 0.55, 0.6)
	version:SetPoint("LEFT", title, "RIGHT", 8, -1)
	version:SetText("v" .. C.VERSION)

	local close = MakeButton(o, 22, 22, "x", function()
		o:Hide()
	end)
	close:SetPoint("TOPRIGHT", o, "TOPRIGHT", -10, -10)

	o.toggle = MakeButton(o, 272, 28, "", function()
		N.Lifecycle.SetEnabled(not C.db.enabled)
	end)
	o.toggle:SetPoint("TOPLEFT", o, "TOPLEFT", 14, -46)

	local styleHead = Text(o, 12, 0.85, 0.85, 0.9)
	styleHead:SetPoint("TOPLEFT", o, "TOPLEFT", 14, -88)
	C.LText(styleHead, "Style")
	o.presets = {}
	for i = 1, 3 do
		local name = C.PRESET_ORDER[i]
		local button = MakeButton(o, 88, 24, C.PRESET_NAMES[name], function()
			C.ApplyPreset(name)
			S.RefreshOptions()
		end)
		button.preset = name
		C.LText(button.text, C.PRESET_NAMES[name])
		button:SetPoint("TOPLEFT", o, "TOPLEFT", 14 + (i - 1) * 92, -106)
		o.presets[i] = button
	end
	o.styleNote = Text(o, 10, 0.6, 0.6, 0.65)
	o.styleNote:SetPoint("TOPLEFT", o, "TOPLEFT", 14, -136)
	o.styleNote:SetWidth(272)
	o.styleNote:SetJustifyH("LEFT")

	-- The look: letters, colors and a crit backdrop that go together. Custom is your own picks.
	local lookHead = Text(o, 12, 0.85, 0.85, 0.9)
	lookHead:SetPoint("TOPLEFT", o, "TOPLEFT", 14, -166)
	C.LText(lookHead, "Look")
	local function ChangeLook(step)
		local order = C.LOOKS.order
		local count = table.getn(order)
		local index = 1
		for i = 1, count do
			if order[i] == C.db.look then index = i; break end
		end
		index = math.mod(index - 1 + step + count, count) + 1
		C.SetLook(order[index])
		S.RefreshOptions()
	end
	local previousLook = MakeButton(o, 22, 22, "<", function() ChangeLook(-1) end)
	previousLook:SetPoint("TOPLEFT", o, "TOPLEFT", 120, -162)
	o.lookText = Text(o, 11, 1, 1, 1)
	o.lookText:SetPoint("LEFT", previousLook, "RIGHT", 0, 0)
	o.lookText:SetWidth(122)
	o.lookText:SetJustifyH("CENTER")
	local nextLook = MakeButton(o, 22, 22, ">", function() ChangeLook(1) end)
	nextLook:SetPoint("LEFT", previousLook, "RIGHT", 122, 0)
	o.lookNote = Text(o, 10, 0.6, 0.6, 0.65)
	o.lookNote:SetPoint("TOPLEFT", o, "TOPLEFT", 14, -190)
	o.lookNote:SetWidth(272)
	o.lookNote:SetJustifyH("LEFT")
	-- Picking a font or a crit backdrop by hand goes back to Custom, where your picks apply.
	local function OwnPicks()
		if (C.db.look or "custom") ~= "custom" then
			C.SetLook("custom")
		end
	end

	local sizeHead = Text(o, 12, 0.85, 0.85, 0.9)
	sizeHead:SetPoint("TOPLEFT", o, "TOPLEFT", 14, -222)
	C.LText(sizeHead, "Size")
	-- Size, Font and the crit backdrop: each picker starts clear of its label (the longest is
	-- "Critical hit backdrop") and ends at the row's right edge, with room for a long name.
	local smaller = MakeButton(o, 22, 22, "-", function()
		C.db.size = AUI.Clamp(math.floor(C.db.size * 10 + 0.5) / 10 - 0.1, 0.6, 1.8)
		S.RefreshOptions()
	end)
	smaller:SetPoint("TOPLEFT", o, "TOPLEFT", 150, -218)
	o.sizeText = Text(o, 12, 1, 1, 1)
	o.sizeText:SetPoint("LEFT", smaller, "RIGHT", 0, 0)
	o.sizeText:SetWidth(92)
	o.sizeText:SetJustifyH("CENTER")
	local bigger = MakeButton(o, 22, 22, "+", function()
		C.db.size = AUI.Clamp(math.floor(C.db.size * 10 + 0.5) / 10 + 0.1, 0.6, 1.8)
		S.RefreshOptions()
	end)
	bigger:SetPoint("LEFT", smaller, "RIGHT", 92, 0)

	local fontHead = Text(o, 12, 0.85, 0.85, 0.9)
	fontHead:SetPoint("TOPLEFT", o, "TOPLEFT", 14, -254)
	C.LText(fontHead, "Font")
	o.fontHead = fontHead
	local previous = MakeButton(o, 22, 22, "<", function()
		OwnPicks()
		C.db.font = C.db.font - 1
		if C.db.font < 1 then
			C.db.font = table.getn(C.FONTS)
		end
		S.OnSettingChanged("font")
		S.RefreshOptions()
	end)
	previous:SetPoint("TOPLEFT", o, "TOPLEFT", 150, -250)
	o.fontText = Text(o, 11, 1, 1, 1)
	o.fontText:SetPoint("LEFT", previous, "RIGHT", 0, 0)
	o.fontText:SetWidth(92)
	o.fontText:SetJustifyH("CENTER")
	local nextFont = MakeButton(o, 22, 22, ">", function()
		OwnPicks()
		C.db.font = C.db.font + 1
		if C.db.font > table.getn(C.FONTS) then
			C.db.font = 1
		end
		S.OnSettingChanged("font")
		S.RefreshOptions()
	end)
	nextFont:SetPoint("LEFT", previous, "RIGHT", 92, 0)

	local backdropHead = Text(o, 12, 0.85, 0.85, 0.9)
	backdropHead:SetPoint("TOPLEFT", o, "TOPLEFT", 14, -286)
	C.LText(backdropHead, "Critical hit backdrop")
	o.backdropHead = backdropHead
	local function ChangeBackdrop(step)
		OwnPicks()
		local order = C.CRIT_BACKDROPS.order
		local count = table.getn(order)
		local index = 1
		for i = 1, count do
			if order[i] == C.db.backdrop then index = i; break end
		end
		-- the count added before the remainder: Lua 5.0's math.mod of a negative stays negative,
		-- and stepping back from the first went nowhere
		index = math.mod(index - 1 + step + count, count) + 1
		C.db.backdrop = order[index]
		S.RefreshOptions()
	end
	local previousBackdrop = MakeButton(o, 22, 22, "<", function() ChangeBackdrop(-1) end)
	previousBackdrop:SetPoint("TOPLEFT", o, "TOPLEFT", 150, -282)
	o.backText = Text(o, 11, 1, 1, 1)
	o.backText:SetPoint("LEFT", previousBackdrop, "RIGHT", 0, 0)
	o.backText:SetWidth(92)
	o.backText:SetJustifyH("CENTER")
	local nextBackdrop = MakeButton(o, 22, 22, ">", function() ChangeBackdrop(1) end)
	nextBackdrop:SetPoint("LEFT", previousBackdrop, "RIGHT", 92, 0)

	local divider = Fill(o, "ARTWORK", 1, 1, 1, 0.08)
	divider:SetPoint("TOPLEFT", o, "TOPLEFT", 14, -316)
	divider:SetWidth(272)
	divider:SetHeight(1)

	o.checks = {
		MakeCheck(o, -326, "Skill icons (one number per skill)", "icons"),
		MakeCheck(o, -348, "DoT totals until the enemy dies", "dotTotals"),
		MakeCheck(o, -370, "Short numbers (12.3K)", "short"),
		MakeCheck(o, -392, "One number per group of enemies", "group"),
		MakeCheck(o, -414, "Move overlapping numbers apart", "spread"),
		MakeCheck(o, -436, "Show hit count (x5)", "count"),
		MakeCheck(o, -458, "Color by spell school", "school"),
		MakeCheck(o, -480, "Show Miss and Immune", "misses"),
		MakeCheck(o, -502, "Merge a spell on 3+ enemies: one number a second", "crowd"),
		MakeCheck(o, -524, "Merge every spell: one number a second", "bySpell"),
	}

	local preview = MakeButton(o, 132, 26, "Preview", function()
		N.Preview.StartTest()
	end)
	preview:SetPoint("TOPLEFT", o, "TOPLEFT", 14, -556)
	C.LText(preview.text, "Preview")
	local reset = MakeButton(o, 132, 26, "Reset", function()
		for key, value in pairs(C.DEFAULTS) do
			if key ~= "enabled" then
				C.db[key] = value
			end
		end
		N.Widgets.ApplyFontAll()
		N.Widgets.RefreshAllText()
		S.RefreshOptions()
		C.Print(C.L("settings reset."))
	end)
	reset:SetPoint("TOPLEFT", o, "TOPLEFT", 154, -556)
	C.LText(reset.text, "Reset settings")

	local motionHead = Text(o, 12, 0.85, 0.85, 0.9)
	motionHead:SetPoint("TOPLEFT", o, "TOPLEFT", 14, -592)
	C.LText(motionHead, "Motion")
	o.motions = {}
	for i = 1, table.getn(C.MOTION_ORDER) do
		local name = C.MOTION_ORDER[i]
		local button = MakeButton(o, 66, 24, C.MOTION_NAMES[name], function()
			C.db.motion = name
			S.RefreshOptions()
		end)
		button.motion = name
		C.LText(button.text, C.MOTION_NAMES[name])
		button:SetPoint("TOPLEFT", o, "TOPLEFT", 14 + (i - 1) * 69, -610)
		o.motions[i] = button
	end
	o.motionNote = Text(o, 10, 0.6, 0.6, 0.65)
	o.motionNote:SetPoint("TOPLEFT", o, "TOPLEFT", 14, -640)
	o.motionNote:SetWidth(272)
	o.motionNote:SetJustifyH("LEFT")

	local footer = Text(o, 10, 0.5, 0.5, 0.55)
	footer:SetPoint("BOTTOM", o, "BOTTOM", 0, 10)
	C.LText(footer, "Type /Arcane numbers to open this window.")
	if AUI.OnLanguage then AUI.OnLanguage(function() if o:IsShown() then S.RefreshOptions() end end) end
end

S.ToggleOptions = function()
	if not options then
		BuildOptions()
	end
	if options:IsShown() then
		options:Hide()
	else
		if AUI.AboveHub then AUI.AboveHub(options) end
		S.RefreshOptions()
		options:Show()
	end
end
