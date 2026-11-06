-- Damage-number widgets: creation, pooling, layout and font refresh.
local AUI = Arcane
local N = AUI.Numbers
local S = N.Widgets
local C = N.Config

-- The number widgets: a holder placed on the enemy, a visual inside it that
-- scales (so a pop never moves the number), and the text. Kept in a pool.

S.layer = CreateFrame("Frame", "ArcaneNumbersLayer", WorldFrame)
S.layer:SetAllPoints(WorldFrame)
S.layer:SetFrameStrata("LOW")
S.layer:EnableMouse(false)

local widgetPool, nWidgetPool = {}, 0
local allWidgets, nAllWidgets = {}, 0

-- the face picked; in a language the game's own face draws (Core), that one
local function FontPath()
	local font = C.FONTS[C.db and C.db.font or 1] or C.FONTS[1]
	if AUI.Face then return AUI.Face(font.path) end
	return font.path
end

local function ApplyFont(w)
	local ok = pcall(w.text.SetFont, w.text, FontPath(), C.FONT_SIZE, "OUTLINE")
	if not ok or not w.text:GetFont() then
		pcall(w.text.SetFont, w.text, C.FONTS[1].path, C.FONT_SIZE, "OUTLINE")
	end
	w.lastText = nil
end

local function NewWidget()
	local holder = CreateFrame("Frame", nil, S.layer)
	holder:SetFrameStrata("LOW")
	holder:SetWidth(1)
	holder:SetHeight(1)
	holder:EnableMouse(false)
	holder:Hide()
	local visual = CreateFrame("Frame", nil, holder)
	visual:SetWidth(320)
	visual:SetHeight(64)
	visual:SetPoint("CENTER", holder, "CENTER", 0, 0)
	visual:EnableMouse(false)
	-- The skill's icon, left of the number, on a thin dark edge.
	local icon = visual:CreateTexture(nil, "OVERLAY")
	icon:SetWidth(C.ICON_SIZE)
	icon:SetHeight(C.ICON_SIZE)
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	icon:SetPoint("LEFT", visual, "CENTER", 0, 0)
	icon:Hide()
	local edge = visual:CreateTexture(nil, "ARTWORK")
	edge:SetTexture(C.FLAT)
	edge:SetVertexColor(0, 0, 0, 0.8)
	edge:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
	edge:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
	edge:Hide()
	local text = visual:CreateFontString(nil, "OVERLAY")
	text:SetPoint("LEFT", visual, "CENTER", 0, 0)
	-- Wide on purpose: a tight width makes the client cut digits into "...".
	-- Left-aligned, and placed so icon and number sit centred together.
	text:SetWidth(420)
	text:SetHeight(C.FONT_SIZE * 2)
	text:SetJustifyH("LEFT")
	text:SetJustifyV("MIDDLE")
	text:SetShadowColor(0, 0, 0, 0.9)
	text:SetShadowOffset(1, -1)
	local w = { holder = holder, visual = visual, text = text, icon = icon, edge = edge }
	ApplyFont(w)
	nAllWidgets = nAllWidgets + 1
	allWidgets[nAllWidgets] = w
	return w
end

-- Centres the icon (if any) and the number together on the spot. As the
-- number grows a digit, the pair glides to its new centre instead of jumping.
S.Layout = function(w, textWidth, iconPath, dt)
	local block = textWidth
	if iconPath then
		block = C.ICON_SIZE + C.ICON_GAP + textWidth
		if w.iconPath ~= iconPath then
			w.icon:SetTexture(iconPath)
			w.iconPath = iconPath
		end
	end
	local target = -block / 2
	if w.left == nil or w.layoutIcon ~= iconPath then
		w.left = target
	else
		w.left = w.left + (target - w.left) * (1 - math.exp(-dt * 22))
	end
	local left = math.floor(w.left + 0.5)
	if w.layoutLeft == left and w.layoutIcon == iconPath then
		return
	end
	w.layoutLeft, w.layoutIcon = left, iconPath
	if iconPath then
		w.icon:SetPoint("LEFT", w.visual, "CENTER", left, 0)
		w.text:SetPoint("LEFT", w.visual, "CENTER", left + C.ICON_SIZE + C.ICON_GAP, 0)
		w.icon:Show()
		w.edge:Show()
	else
		w.text:SetPoint("LEFT", w.visual, "CENTER", left, 0)
		w.icon:Hide()
		w.edge:Hide()
	end
end

S.AcquireWidget = function()
	local w
	if nWidgetPool > 0 then
		w = widgetPool[nWidgetPool]
		widgetPool[nWidgetPool] = nil
		nWidgetPool = nWidgetPool - 1
	else
		w = NewWidget()
	end
	w.lastText, w.scale, w.alpha, w.px, w.py = nil, nil, nil, nil, nil
	w.r, w.g, w.b, w.shown = nil, nil, nil, false
	w.layoutIcon, w.layoutLeft, w.left = false, nil, nil
	return w
end

S.ReleaseWidget = function(w)
	w.holder:Hide()
	w.shown = false
	nWidgetPool = nWidgetPool + 1
	widgetPool[nWidgetPool] = w
end

S.ApplyFontAll = function()
	for i = 1, nAllWidgets do
		ApplyFont(allWidgets[i])
	end
end

S.RefreshAllText = function()
	for i = 1, nAllWidgets do
		allWidgets[i].lastText = nil
		allWidgets[i].layoutIcon = false
	end
end

-- a language in other letters draws the numbers in the game's own face (Core): faces again
if AUI.OnLanguage then
	AUI.OnLanguage(function()
		if C.db then
			S.ApplyFontAll()
			S.RefreshAllText()
		end
	end)
end
