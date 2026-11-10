-- Shared buttons and the main Arcane options hub.
local C = Arcane

------------------------------------------------------------------------ the options hub
local hub, RefreshHub

-- A settings window opened from the hub is a sibling of the hub under UIParent.
-- Give the whole child window a higher frame level: otherwise the hub's direct
-- FontStrings can draw over the child's title even while its child controls draw
-- above the hub. Keep the same DIALOG strata so it stays below true fullscreen
-- dialogs (such as the game's level-up cards).
function C.AboveHub(frame)
	if not frame then return end
	frame:SetFrameStrata("DIALOG")
	local level = UIParent:GetFrameLevel() + 10
	if hub then level = math.max(level, hub:GetFrameLevel() + 10) end
	frame:SetFrameLevel(level)
end

local function HubText(parent, size, r, g, b)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	C.SetFace(fs, C.FONT, size)
	fs:SetTextColor(r, g, b)
	fs:SetShadowColor(0, 0, 0, 1)
	fs:SetShadowOffset(1, -1)
	return fs
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

function C.Button(parent, width, height, label, onClick)
	local button = CreateFrame("Button", nil, parent)
	button:SetWidth(width)
	button:SetHeight(height)
	button:EnableMouse(true)
	button:SetBackdrop({ bgFile = C.FLAT, edgeFile = C.FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
	button.text = HubText(button, 11, 1, 1, 1)
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

local function PartRow(parent, x, y, info)
	local row = CreateFrame("Button", nil, parent)
	row:SetWidth(200)
	row:SetHeight(20)
	row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	row:EnableMouse(true)
	local edge = row:CreateTexture(nil, "BORDER")
	edge:SetTexture(C.FLAT)
	edge:SetVertexColor(0.38, 0.38, 0.42, 1)
	edge:SetWidth(14)
	edge:SetHeight(14)
	edge:SetPoint("LEFT", row, "LEFT", 0, 0)
	local box = row:CreateTexture(nil, "ARTWORK")
	box:SetTexture(C.FLAT)
	box:SetVertexColor(0.06, 0.06, 0.08, 1)
	box:SetPoint("TOPLEFT", edge, "TOPLEFT", 1, -1)
	box:SetPoint("BOTTOMRIGHT", edge, "BOTTOMRIGHT", -1, 1)
	row.mark = row:CreateTexture(nil, "OVERLAY")
	row.mark:SetTexture(C.FLAT)
	row.mark:SetVertexColor(0.91, 0.70, 0.30, 1)
	row.mark:SetPoint("TOPLEFT", edge, "TOPLEFT", 3, -3)
	row.mark:SetPoint("BOTTOMRIGHT", edge, "BOTTOMRIGHT", -3, 3)
	row.label = HubText(row, 12, 0.92, 0.92, 0.92)
	row.label:SetPoint("LEFT", edge, "RIGHT", 8, 0)
	C.LText(row.label, info.name)
	row:SetScript("OnEnter", function()
		row.label:SetTextColor(0.98, 0.85, 0.52)
		if GameTooltip and info.note then
			GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
			GameTooltip:AddLine(C.L(info.name), 0.98, 0.85, 0.52)
			GameTooltip:AddLine(C.L(info.note), 1, 1, 1, 1)
			C.ShowTip()
		end
	end)
	row:SetScript("OnLeave", function()
		row.label:SetTextColor(0.92, 0.92, 0.92)
		if GameTooltip then GameTooltip:Hide() end
	end)
	row:SetScript("OnClick", function()
		info.set(not info.get())
		RefreshHub()
	end)
	row.info = info
	if info.getScale then
		row.less = C.Button(parent, 22, 20, "-", function()
			info.setScale(C.Clamp(math.floor((info.getScale() - 0.05) * 20 + 0.5) / 20, 0.5, 1.8))
			RefreshHub()
		end)
		row.less:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 206, y)
		row.size = HubText(parent, 11, 1, 1, 1)
		row.size:SetPoint("LEFT", row.less, "RIGHT", 0, 0)
		row.size:SetWidth(46)
		row.size:SetJustifyH("CENTER")
		row.more = C.Button(parent, 22, 20, "+", function()
			info.setScale(C.Clamp(math.floor((info.getScale() + 0.05) * 20 + 0.5) / 20, 0.5, 1.8))
			RefreshHub()
		end)
		row.more:SetPoint("LEFT", row.less, "RIGHT", 46, 0)
	end
	return row
end

RefreshHub = function()
	if not hub then return end
	for i = 1, table.getn(hub.rows) do
		local row = hub.rows[i]
		if row.info.get() then row.mark:Show() else row.mark:Hide() end
		if row.size then
			row.size:SetText(string.format("%d%%", math.floor((row.info.getScale() or 1) * 100 + 0.5)))
		end
	end
	hub.move.selected = C.unlocked
	C.LText(hub.move.text, C.unlocked and "Lock frames" or "Move frames")
	PaintButton(hub.move)
	hub.calm.selected = ArcaneDB and ArcaneDB.calm and true or false
	PaintButton(hub.calm)
	local locked = ArcaneDB and ArcaneDB.lockWindows and true or false
	hub.lock.selected = locked
	C.LText(hub.lock.text, locked and "Meter and luck windows: resizing locked" or "Meter and luck windows: resizing enabled")
	PaintButton(hub.lock)
	C.SetText(hub.lang.text, C.F("Language: {1}", C.LangName(C.lang)))
	hub.lang.selected = hub.langMenu:IsShown()
	PaintButton(hub.lang)
	for i = 1, table.getn(hub.langMenu.items) do
		local b = hub.langMenu.items[i]
		b.selected = b.code == C.lang
		PaintButton(b)
	end
	if hub.barStyleButtons and C.BarStyles then
		local mode = C.BarStyles.Mode()
		for i = 1, table.getn(hub.barStyleButtons) do
			local b = hub.barStyleButtons[i]
			b.selected = b.mode == mode
			PaintButton(b)
		end
	end
end
C.RefreshHub = function() RefreshHub() end

-- The parts in two columns, the first half down the left, so the window stays well inside a
-- 768 px screen however many parts there are; the buttons under them run across its width.
local HUB_W, COL_W = 638, 312

local function BuildHub()
	local o = CreateFrame("Frame", "ArcaneOptions", UIParent)
	hub = o
	o:SetWidth(HUB_W)
	local perColumn = math.ceil(table.getn(C.parts) / 2)
	o:SetHeight(62 + perColumn * 26 + 14 + 60 + 24 + 12 + 60) -- rows, panels and three lines of buttons
	o:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
	o:SetFrameStrata("DIALOG")
	o:SetBackdrop({ bgFile = C.FLAT, edgeFile = C.FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
	o:SetBackdropColor(0.05, 0.05, 0.07, 0.96)
	o:SetBackdropBorderColor(0, 0, 0, 1)
	o:EnableMouse(true)
	o:SetMovable(true)
	o:SetClampedToScreen(true)
	o:RegisterForDrag("LeftButton")
	o:SetScript("OnDragStart", function() o:StartMoving() end)
	o:SetScript("OnDragStop", function() o:StopMovingOrSizing() end)
	o:Hide()
	if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, "ArcaneOptions") end

	local title = HubText(o, 18, 1, 0.82, 0.25)
	C.SetFace(title, C.TITLE_FONT, 20)
	title:SetPoint("TOPLEFT", o, "TOPLEFT", 14, -12)
	title:SetText("Arcane UI")
	local version = HubText(o, 10, 0.55, 0.55, 0.6)
	version:SetPoint("LEFT", title, "RIGHT", 8, -2)
	version:SetText("v" .. C.VERSION)
	local close = C.Button(o, 22, 22, "x", function() o:Hide() end)
	close:SetPoint("TOPRIGHT", o, "TOPRIGHT", -10, -10)

	for col = 0, 1 do
		local head = HubText(o, 10, 0.6, 0.6, 0.65)
		head:SetPoint("TOPLEFT", o, "TOPLEFT", 14 + col * COL_W, -46)
		C.LText(head, "PART")
		local head2 = HubText(o, 10, 0.6, 0.6, 0.65)
		head2:SetPoint("TOPLEFT", o, "TOPLEFT", 244 + col * COL_W, -46)
		C.LText(head2, "SIZE")
	end

	o.rows = {}
	for i = 1, table.getn(C.parts) do
		local col = (i > perColumn) and 1 or 0
		local line = i - 1 - col * perColumn
		table.insert(o.rows, PartRow(o, 14 + col * COL_W, -62 - line * 26, C.parts[i]))
	end
	local y = -62 - perColumn * 26

	local divider = o:CreateTexture(nil, "ARTWORK")
	divider:SetTexture(C.FLAT)
	divider:SetVertexColor(1, 1, 1, 0.08)
	divider:SetWidth(HUB_W - 28)
	divider:SetHeight(1)
	divider:SetPoint("TOPLEFT", o, "TOPLEFT", 14, y - 4)
	y = y - 14

	local timerButton = C.Button(o, 148, 24, "", function()
		if C.timerOptions then C.timerOptions() end
	end)
	C.LText(timerButton.text, "Boss timer settings")
	timerButton:SetPoint("TOPLEFT", o, "TOPLEFT", 14, y)
	local numbersButton = C.Button(o, 148, 24, "", function()
		if C.numberOptions then C.numberOptions() end
	end)
	C.LText(numbersButton.text, "Damage number settings")
	numbersButton:SetPoint("TOPLEFT", o, "TOPLEFT", 168, y)
	o.move = C.Button(o, 148, 24, "Move frames", function()
		C.SetUnlocked(not C.unlocked)
		RefreshHub()
	end)
	o.move:SetPoint("TOPLEFT", o, "TOPLEFT", 14 + COL_W, y)
	local reset = C.Button(o, 148, 24, "", function()
		C.ResetPositions()
		C.Print(C.L("frames are back in their places."))
	end)
	C.LText(reset.text, "Reset positions")
	reset:SetPoint("TOPLEFT", o, "TOPLEFT", 168 + COL_W, y)
	y = y - 30
	o.calm = C.Button(o, 302, 24, "", function()
		local root = C.Root()
		root.calm = not root.calm
		RefreshHub()
	end)
	C.LText(o.calm.text, "Calm mode: no flowing light in the bars")
	o.calm:SetPoint("TOPLEFT", o, "TOPLEFT", 14, y)
	o.lock = C.Button(o, 302, 24, "Meter and luck windows: drag them to move", function()
		local root = C.Root()
		root.lockWindows = not root.lockWindows
		RefreshHub()
	end)
	o.lock:SetPoint("TOPLEFT", o, "TOPLEFT", 14 + COL_W, y)
	y = y - 30
	local nameplatesButton = C.Button(o, 148, 24, "", function()
		if C.ArcaneNameplatesToggleOptions then C.ArcaneNameplatesToggleOptions(o) end
	end)
	C.LText(nameplatesButton.text, "Arcane Nameplates settings")
	nameplatesButton:SetPoint("TOPLEFT", o, "TOPLEFT", 14, y)
	local langButton = C.Button(o, 148, 24, "", function()
		if o.langMenu:IsShown() then o.langMenu:Hide() else o.langMenu:Show() end
		RefreshHub()
	end)
	C.LText(langButton.text, "Language")
	langButton:SetPoint("TOPLEFT", o, "TOPLEFT", 168, y)
	-- A dedicated row keeps the three skill-bar treatments easy to identify.
	local styleY = y - 30
	local styleLabel = HubText(o, 9, 0.62, 0.62, 0.68)
	styleLabel:SetPoint("BOTTOMLEFT", o, "TOPLEFT", 326, styleY + 4)
	C.LText(styleLabel, "UI style")
	local function StyleChoice(mode, label, x)
		local button = C.Button(o, 96, 24, "", function()
			if C.BarStyles then C.BarStyles.SetMode(mode) end
			RefreshHub()
		end)
		C.LText(button.text, label)
		button.mode = mode
		button:SetPoint("TOPLEFT", o, "TOPLEFT", x, styleY)
		return button
	end
	o.barStyleButtons = {
		StyleChoice(C.BarStyles.CLASSIC, "Arcane", 326),
		StyleChoice(C.BarStyles.HYBRID, "Hybrid", 429),
		StyleChoice(C.BarStyles.FULL_CLASS, "Full class", 532),
	}
	-- the language: a button that opens the list of them, each in its own words
	o.lang = langButton
	local menu = CreateFrame("Frame", "ArcaneLanguageMenu", o)
	o.langMenu = menu
	local n = table.getn(C.LANG_LIST)
	local rows = math.ceil(n / 2) -- two columns
	menu:SetWidth(298)
	menu:SetHeight(rows * 22 + 8)
	menu:SetPoint("BOTTOM", o.lang, "TOP", 0, 2) -- upward: the options reach low on the screen
	menu:SetFrameStrata("FULLSCREEN_DIALOG")
	menu:SetBackdrop({ bgFile = C.FLAT, edgeFile = C.FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
	menu:SetBackdropColor(0.05, 0.05, 0.07, 0.98)
	menu:SetBackdropBorderColor(0.91, 0.70, 0.30, 0.8)
	menu:EnableMouse(true)
	menu:Hide()
	menu.items = {}
	for i = 1, n do
		local info = C.LANG_LIST[i]
		local b = C.Button(menu, 142, 20, info.name, function()
			C.SetLanguage(this.code, true)
			menu:Hide()
			RefreshHub()
		end)
		b.code = info.code
		-- each name in its own letters, in the face that has them, whatever the language
		if info.face then C.SetFace(b.text, C.FONT, 11, nil, info.face) end
		local col, row = math.mod(i - 1, 2), math.floor((i - 1) / 2)
		b:SetPoint("TOPLEFT", menu, "TOPLEFT", 4 + col * 148, -4 - row * 22)
		menu.items[i] = b
	end
end

function C.ToggleHub()
	if not hub then BuildHub() end
	if hub:IsShown() then
		hub:Hide()
	else
		RefreshHub()
		hub:Show()
	end
end
