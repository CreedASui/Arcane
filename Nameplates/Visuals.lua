-- Nameplate visuals: overlay creation, health display and labels.
local C = Arcane
C.Nameplates = C.Nameplates or {}
local P = C.Nameplates
P.Visuals = {}

local function FindStyledVisual(frame, source)
	local children = { frame:GetChildren() }
	for i = 1, table.getn(children) do
		local child = children[i]
		local width, height = child:GetWidth(), child:GetHeight()
		if child ~= source and child ~= frame.arcaneNameplatesOverlay
				and child:GetObjectType() ~= "StatusBar"
				and width and height and width >= 30 and width <= 200
				and height >= 5 and height <= 60
				and P.State.ContainsStatusBar(child) then
			if not frame.arcaneNameplatesStyledOriginalScale then
				frame.arcaneNameplatesStyledOriginalScale = child:GetScale()
			end
			return child
		end
	end
	return nil
end

local function IsPlaceholderShrunk(frame)
	local visual = frame.arcaneNameplatesStyledVisual
	if visual and visual:IsShown() and frame.arcaneNameplatesStyledOriginalScale then
		return visual:GetScale() < frame.arcaneNameplatesStyledOriginalScale * 0.99
	end
	local overlay = frame.arcaneNameplatesOverlay
	if overlay and overlay:IsShown() and frame.arcaneNameplatesOverlayBaseWidth then
		return overlay:GetWidth() < frame.arcaneNameplatesOverlayBaseWidth * 0.99
	end
	local source = frame.arcaneNameplatesSourceBar
	if source and source:IsShown() and frame.arcaneNameplatesSourceOriginalWidth then
		return source:GetWidth() < frame.arcaneNameplatesSourceOriginalWidth * 0.99
	end
	return false
end

local function HideShrunkNameLabel(frame)
	if frame.arcaneNameplatesShrunkLabelHolder then frame.arcaneNameplatesShrunkLabelHolder:Hide() end
end

local function UpdateShrunkNameLabel(frame)
	local name = frame.arcaneNameplatesPlateName
	if not P.Option("showShrunkName") or frame.arcaneNameplatesBossGuardian
			or not name or name == "" then
		HideShrunkNameLabel(frame)
		return
	end
	local holder = frame.arcaneNameplatesShrunkLabelHolder
	if not holder then
		holder = CreateFrame("Frame", nil, frame)
		holder:SetAllPoints(frame)
		holder:SetFrameLevel(frame:GetFrameLevel() + 10)
		local text = C.Text(holder, C.FONT, 10, "OUTLINE", "CENTER", 160)
		text:SetHeight(12)
		text:SetTextColor(1, 0.86, 0.78)
		holder.text = text
		frame.arcaneNameplatesShrunkLabelHolder = holder
	end
	local anchor = frame.arcaneNameplatesOverlay or frame.arcaneNameplatesSourceBar or frame
	holder.text:ClearAllPoints()
	holder.text:SetPoint("BOTTOM", anchor, "TOP", 0, 2)
	holder.text:SetText(name)
	holder.text:SetAlpha(1)
	holder:Show()
end

local function UpdateNamePlaceholder(frame)
	local label = frame.arcaneNameplatesBossGuardianLabel
	if IsPlaceholderShrunk(frame) then
		if label then label:Hide() end
		UpdateShrunkNameLabel(frame)
		return
	end
	HideShrunkNameLabel(frame)
	if frame.arcaneNameplatesBossGuardian and P.Option("hideBossName") then
		if label then label:Hide() end
		if frame.arcaneNameplatesBossGuardianLabelHolder then frame.arcaneNameplatesBossGuardianLabelHolder:Hide() end
		local visual = frame.arcaneNameplatesStyledVisual
		local native = visual and P.State.FindNameFontString(visual, frame.arcaneNameplatesPlateName)
		if native then native:SetAlpha(0); native:Hide() end
		P.State.HideMatchingNameText(frame, frame.arcaneNameplatesPlateName, nil)
		return
	end
	local visual = frame.arcaneNameplatesStyledVisual
	local native = visual and P.State.FindNameFontString(visual, frame.arcaneNameplatesPlateName)
	if native and P.State.NormalizeName(native:GetText()) == frame.arcaneNameplatesPlateName then
		-- Let the replacement UI draw its own name where it expects it.
		native:SetAlpha(1)
		native:Show()
		if native:IsVisible() then
			if label then label:Hide() end
			return
		end
	end
	P.Special.UpdateBossGuardianLabel(frame)
	P.Special.ApplyBossGuardianLabelFont(frame)
	P.State.HideMatchingNameText(frame, frame.arcaneNameplatesPlateName,
		frame.arcaneNameplatesBossGuardianLabel)
end

local PLATE_ENEMY_COLORS = {
	{ 0.30, 0.02, 0.02 }, { 0.72, 0.05, 0.04 }, { 1.00, 0.30, 0.14 },
}

local function BarColor(category)
	if type(C.ArcaneNameplatesBarColor) == "function" then return C.ArcaneNameplatesBarColor(category) end
	return nil
end

local function PlateColorStops(category)
	local color = BarColor(category)
	if not color then return PLATE_ENEMY_COLORS end
	return {
		{ color[1] * 0.32, color[2] * 0.32, color[3] * 0.32 },
		{ color[1] * 0.86, color[2] * 0.86, color[3] * 0.86 },
		{ C.Clamp(color[1] * 1.08, 0, 1), C.Clamp(color[2] * 1.08, 0, 1), C.Clamp(color[3] * 1.08, 0, 1) },
	}
end

local function PlateHealthText(value, maximum)
	local hp = math.floor((value or 0) + 0.5)
	local hpm = math.floor((maximum or 0) + 0.5)
	if hpm >= 100000 then return C.Short(hp) .. " / " .. C.Short(hpm) end
	return C.Commas(hp) .. " / " .. C.Commas(hpm)
end

local function UpdatePlateHealthText(frame, source)
	if not P.Option("showHealthText") then
		if frame.arcaneNameplatesHealthText and frame.arcaneNameplatesHealthText:IsShown() then
			frame.arcaneNameplatesHealthText:Hide()
		end
		return
	end
	if not frame.arcaneNameplatesHealthText then
		local special = frame.arcaneNameplatesBossGuardian and true or false
		local size = special and 10 or 8
		local text = C.Text(frame.arcaneNameplatesHealthBar.top, C.FONT, size, "OUTLINE",
			"CENTER", frame.arcaneNameplatesOverlayWidth + 20)
		text:SetPoint("CENTER", frame.arcaneNameplatesOverlay, "CENTER", 0, 0)
		frame.arcaneNameplatesHealthText = text
		frame.arcaneNameplatesHealthTextSize = size
		frame.arcaneNameplatesHealthTextWidth = frame.arcaneNameplatesOverlayWidth + 20
	elseif frame.arcaneNameplatesHealthTextSize ~= (frame.arcaneNameplatesBossGuardian and 10 or 8) then
		local size = frame.arcaneNameplatesBossGuardian and 10 or 8
		C.SetFace(frame.arcaneNameplatesHealthText, C.FONT, size, "OUTLINE")
		frame.arcaneNameplatesHealthTextSize = size
	end
	local width = frame.arcaneNameplatesOverlayWidth + 20
	if frame.arcaneNameplatesHealthTextWidth ~= width then
		frame.arcaneNameplatesHealthText:SetWidth(width)
		frame.arcaneNameplatesHealthTextWidth = width
	end
	local _, maximum = source:GetMinMaxValues()
	local value = source:GetValue()
	if frame.arcaneNameplatesHealthTextValue ~= value
			or frame.arcaneNameplatesHealthTextMaximum ~= maximum then
		C.SetText(frame.arcaneNameplatesHealthText, PlateHealthText(value, maximum))
		frame.arcaneNameplatesHealthTextValue = value
		frame.arcaneNameplatesHealthTextMaximum = maximum
	end
	if not frame.arcaneNameplatesHealthText:IsShown() then frame.arcaneNameplatesHealthText:Show() end
end

local function ApplyPlateStyle(frame)
	local special = P.Special.IsBossOrGuardianPlate(frame)
	frame.arcaneNameplatesNativeRestored = nil
	if not special then
		if frame.arcaneNameplatesBossGuardianLabel then frame.arcaneNameplatesBossGuardianLabel:Hide() end
		if frame.arcaneNameplatesDebuffRow then frame.arcaneNameplatesDebuffRow:Hide() end
	end
	P.State.HideNameText(frame)
	if frame.arcaneNameplatesStyledVisual then frame.arcaneNameplatesStyledVisual:Hide() end
	local overlay = frame.arcaneNameplatesOverlay
	local bar = frame.arcaneNameplatesHealthBar
	local source = frame.arcaneNameplatesSourceBar
	if not overlay or not bar or not source then return false end
	local width = frame.arcaneNameplatesOverlayWidth
	local height = frame.arcaneNameplatesOverlayHeight
	if bar.w ~= width or bar.h ~= height then C.BarLayout(bar, width, height) end
	overlay:SetFrameLevel(math.max(frame:GetFrameLevel() + 2, source:GetFrameLevel() + 1))
	C.BarLevels(bar, overlay:GetFrameLevel())
	if frame.arcaneNameplatesBarThemeStamp ~= C.palStamp then
		C.BarTheme(bar, C.Pal())
		frame.arcaneNameplatesBarThemeStamp = C.palStamp
	end
	local stops = PlateColorStops(special and "boss" or "regular")
	C.BarColors(bar, stops[1], stops[2], stops[3])
	UpdatePlateHealthText(frame, source)
	bar.snap = true
	if not overlay:IsShown() then overlay:Show() end
	P.State.HideNativePlate(frame, nil)
	UpdateNamePlaceholder(frame)
	return true
end

local function CreatePlateOverlay(frame)
	-- Do not move, resize or rescale the WorldFrame plate. The game owns its projected
	-- position; our replacement bar is anchored to the native health bar below.

	if not frame.arcaneNameplatesStyledVisual then
		frame.arcaneNameplatesStyledVisual = FindStyledVisual(frame, frame.arcaneNameplatesSourceBar)
	end
	if not frame.arcaneNameplatesSourceBar then
		local children = { frame:GetChildren() }
		for i = 1, table.getn(children) do
			if P.State.IsHealthStatusBar(children[i]) then
				frame.arcaneNameplatesSourceBar = children[i]
				break
			end
		end
	end
	if not frame.arcaneNameplatesSourceBar and frame.arcaneNameplatesStyledVisual then
		local bars = {}
		P.State.CollectStatusBars(frame.arcaneNameplatesStyledVisual, bars)
		for i = 1, table.getn(bars) do
			if bars[i]:GetWidth() > 0 and bars[i]:GetHeight() > 0 then
				frame.arcaneNameplatesSourceBar = bars[i]
				break
			end
		end
	end
	if not frame.arcaneNameplatesSourceBar then
		local bars = {}
		P.State.CollectStatusBars(frame, bars)
		for i = 1, table.getn(bars) do
			if bars[i] ~= frame.arcaneNameplatesOverlay
					and bars[i]:GetWidth() > 0 and bars[i]:GetHeight() > 0 then
				frame.arcaneNameplatesSourceBar = bars[i]
				break
			end
		end
	end
	if not frame.arcaneNameplatesSourceBar then return false end

	local source = frame.arcaneNameplatesSourceBar
	local originalWidth = frame.arcaneNameplatesSourceOriginalWidth or source:GetWidth()
	local originalHeight = frame.arcaneNameplatesSourceOriginalHeight or source:GetHeight()
	local point, relativeTo, relativePoint, x, y = source:GetPoint()
	local oldVisuals = frame.arcaneNameplatesVisuals or {}
	for j = 1, table.getn(oldVisuals) do
		if oldVisuals[j].region == source then
			originalWidth, originalHeight = oldVisuals[j].width, oldVisuals[j].height
			point, relativeTo, relativePoint = oldVisuals[j].point, oldVisuals[j].relativeTo, oldVisuals[j].relativePoint
			x, y = oldVisuals[j].x, oldVisuals[j].y
			break
		end
	end
	if not point then return false end
	frame.arcaneNameplatesSourceOriginalWidth, frame.arcaneNameplatesSourceOriginalHeight = originalWidth, originalHeight
	local visualScale = P.Special.IsBossOrGuardianPlate(frame) and 1 or 0.5
	local width, height = originalWidth * visualScale, originalHeight * visualScale
	local adjustedX, adjustedY = x or 0, y or 0
	if string.find(point, "LEFT") then adjustedX = adjustedX + width / 2 end
	if string.find(point, "BOTTOM") then adjustedY = adjustedY + height / 2 end
	local offsetX, offsetY = 10, 14
	if visualScale == 1 then offsetX, offsetY = 0, 0 end

	if not frame.arcaneNameplatesHealthBar then
		local bar = C.NewBar(frame, width, height, true)
		frame.arcaneNameplatesHealthBar = bar
		frame.arcaneNameplatesOverlay = bar.frame
	else
		local bar = frame.arcaneNameplatesHealthBar
		if bar.w ~= width or bar.h ~= height then C.BarLayout(bar, width, height) end
	end
	frame.arcaneNameplatesOverlayPoint = point
	frame.arcaneNameplatesOverlayRelativeTo = relativeTo or frame
	frame.arcaneNameplatesOverlayRelativePoint = relativePoint or point
	frame.arcaneNameplatesOverlayX, frame.arcaneNameplatesOverlayY = adjustedX, adjustedY
	frame.arcaneNameplatesOverlayWidth, frame.arcaneNameplatesOverlayHeight = width, height
	frame.arcaneNameplatesOverlayBaseWidth, frame.arcaneNameplatesOverlayBaseHeight = originalWidth, originalHeight
	local overlay = frame.arcaneNameplatesOverlay
	overlay:ClearAllPoints()
	overlay:SetPoint(point, relativeTo or frame, relativePoint or point, adjustedX + offsetX, adjustedY + offsetY)
	return true
end

local function Apply(frame)
	-- V remains the game's native visibility control. The Arcane bar is parented to
	-- this same pooled plate, so the game hides and shows the replacement with it.
	if not CreatePlateOverlay(frame) then return false end
	return ApplyPlateStyle(frame)
end

local lastOverlaySyncTime

local function SyncOverlayValues(orderedPlates)
	local now = GetTime()
	local dt = 0.1
	if lastOverlaySyncTime then
		dt = math.min(now - lastOverlaySyncTime, 0.2)
	end
	if dt <= 0 then dt = 0.1 end
	lastOverlaySyncTime = now
	for i = 1, table.getn(orderedPlates) do
		local frame = orderedPlates[i]
		local bar = frame.arcaneNameplatesHealthBar
		local source = frame.arcaneNameplatesSourceBar
		if bar and source and frame:IsVisible() and frame.arcaneNameplatesOverlay
				and frame.arcaneNameplatesOverlay:IsShown() then
			local minimum, maximum = source:GetMinMaxValues()
			local range = (maximum or 0) - (minimum or 0)
			local value = source:GetValue() or 0
			local ratio = range > 0 and C.Clamp((value - minimum) / range, 0, 1) or 0
			C.BarStep(bar, ratio, dt, now)
			UpdatePlateHealthText(frame, source)
			if frame.arcaneNameplatesBarThemeStamp ~= C.palStamp then
				C.BarTheme(bar, C.Pal())
				frame.arcaneNameplatesBarThemeStamp = C.palStamp
			end
		end
	end
end

P.Visuals.Apply = Apply
P.Visuals.SyncOverlayValues = SyncOverlayValues
