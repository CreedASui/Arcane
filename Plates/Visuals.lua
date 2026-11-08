-- Nameplate visuals: overlay creation, health display and labels.
local C = Arcane
C.Plates = C.Plates or {}
local P = C.Plates
P.Visuals = {}

local function FindStyledVisual(frame, source)
	local children = { frame:GetChildren() }
	for i = 1, table.getn(children) do
		local child = children[i]
		local width, height = child:GetWidth(), child:GetHeight()
		if child ~= source and child ~= frame.arcanePlatesOverlay
				and child:GetObjectType() ~= "StatusBar"
				and width and height and width >= 30 and width <= 200
				and height >= 5 and height <= 60
				and P.State.ContainsStatusBar(child) then
			if not frame.arcanePlatesStyledOriginalScale then
				frame.arcanePlatesStyledOriginalScale = child:GetScale()
			end
			return child
		end
	end
	return nil
end

local function IsPlaceholderShrunk(frame)
	local visual = frame.arcanePlatesStyledVisual
	if visual and visual:IsShown() and frame.arcanePlatesStyledOriginalScale then
		return visual:GetScale() < frame.arcanePlatesStyledOriginalScale * 0.99
	end
	local overlay = frame.arcanePlatesOverlay
	if overlay and overlay:IsShown() and frame.arcanePlatesOverlayBaseWidth then
		return overlay:GetWidth() < frame.arcanePlatesOverlayBaseWidth * 0.99
	end
	local source = frame.arcanePlatesSourceBar
	if source and source:IsShown() and frame.arcanePlatesSourceOriginalWidth then
		return source:GetWidth() < frame.arcanePlatesSourceOriginalWidth * 0.99
	end
	return false
end

local function HideShrunkNameLabel(frame)
	if frame.arcanePlatesShrunkLabelHolder then frame.arcanePlatesShrunkLabelHolder:Hide() end
end

local function UpdateShrunkNameLabel(frame)
	local name = frame.arcanePlatesPlateName
	if not P.Option("showShrunkName") or frame.arcanePlatesBossGuardian
			or not name or name == "" then
		HideShrunkNameLabel(frame)
		return
	end
	local holder = frame.arcanePlatesShrunkLabelHolder
	if not holder then
		holder = CreateFrame("Frame", nil, frame)
		holder:SetAllPoints(frame)
		holder:SetFrameLevel(frame:GetFrameLevel() + 10)
		local text = C.Text(holder, C.FONT, 10, "OUTLINE", "CENTER", 160)
		text:SetHeight(12)
		text:SetTextColor(1, 0.86, 0.78)
		holder.text = text
		frame.arcanePlatesShrunkLabelHolder = holder
	end
	local anchor = frame.arcanePlatesOverlay or frame.arcanePlatesSourceBar or frame
	holder.text:ClearAllPoints()
	holder.text:SetPoint("BOTTOM", anchor, "TOP", 0, 2)
	holder.text:SetText(name)
	holder.text:SetAlpha(1)
	holder:Show()
end

local function UpdateNamePlaceholder(frame)
	local label = frame.arcanePlatesBossGuardianLabel
	if IsPlaceholderShrunk(frame) then
		if label then label:Hide() end
		UpdateShrunkNameLabel(frame)
		return
	end
	HideShrunkNameLabel(frame)
	if frame.arcanePlatesBossGuardian and P.Option("hideBossName") then
		if label then label:Hide() end
		if frame.arcanePlatesBossGuardianLabelHolder then frame.arcanePlatesBossGuardianLabelHolder:Hide() end
		local visual = frame.arcanePlatesStyledVisual
		local native = visual and P.State.FindNameFontString(visual, frame.arcanePlatesPlateName)
		if native then native:SetAlpha(0); native:Hide() end
		P.State.HideMatchingNameText(frame, frame.arcanePlatesPlateName, nil)
		return
	end
	local visual = frame.arcanePlatesStyledVisual
	local native = visual and P.State.FindNameFontString(visual, frame.arcanePlatesPlateName)
	if native and P.State.NormalizeName(native:GetText()) == frame.arcanePlatesPlateName then
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
	P.State.HideMatchingNameText(frame, frame.arcanePlatesPlateName,
		frame.arcanePlatesBossGuardianLabel)
end

local PLATE_ENEMY_COLORS = {
	{ 0.30, 0.02, 0.02 }, { 0.72, 0.05, 0.04 }, { 1.00, 0.30, 0.14 },
}

local function BarColor(category)
	if type(C.ArcanePlatesBarColor) == "function" then return C.ArcanePlatesBarColor(category) end
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
		if frame.arcanePlatesHealthText and frame.arcanePlatesHealthText:IsShown() then
			frame.arcanePlatesHealthText:Hide()
		end
		return
	end
	if not frame.arcanePlatesHealthText then
		local special = frame.arcanePlatesBossGuardian and true or false
		local size = special and 10 or 8
		local text = C.Text(frame.arcanePlatesHealthBar.top, C.FONT, size, "OUTLINE",
			"CENTER", frame.arcanePlatesOverlayWidth + 20)
		text:SetPoint("CENTER", frame.arcanePlatesOverlay, "CENTER", 0, 0)
		frame.arcanePlatesHealthText = text
		frame.arcanePlatesHealthTextSize = size
		frame.arcanePlatesHealthTextWidth = frame.arcanePlatesOverlayWidth + 20
	elseif frame.arcanePlatesHealthTextSize ~= (frame.arcanePlatesBossGuardian and 10 or 8) then
		local size = frame.arcanePlatesBossGuardian and 10 or 8
		C.SetFace(frame.arcanePlatesHealthText, C.FONT, size, "OUTLINE")
		frame.arcanePlatesHealthTextSize = size
	end
	local width = frame.arcanePlatesOverlayWidth + 20
	if frame.arcanePlatesHealthTextWidth ~= width then
		frame.arcanePlatesHealthText:SetWidth(width)
		frame.arcanePlatesHealthTextWidth = width
	end
	local _, maximum = source:GetMinMaxValues()
	local value = source:GetValue()
	if frame.arcanePlatesHealthTextValue ~= value
			or frame.arcanePlatesHealthTextMaximum ~= maximum then
		C.SetText(frame.arcanePlatesHealthText, PlateHealthText(value, maximum))
		frame.arcanePlatesHealthTextValue = value
		frame.arcanePlatesHealthTextMaximum = maximum
	end
	if not frame.arcanePlatesHealthText:IsShown() then frame.arcanePlatesHealthText:Show() end
end

local function ApplyPlateStyle(frame)
	local special = P.Special.IsBossOrGuardianPlate(frame)
	frame.arcanePlatesNativeRestored = nil
	if not special then
		if frame.arcanePlatesBossGuardianLabel then frame.arcanePlatesBossGuardianLabel:Hide() end
		if frame.arcanePlatesDebuffRow then frame.arcanePlatesDebuffRow:Hide() end
	end
	P.State.HideNameText(frame)
	if frame.arcanePlatesStyledVisual then frame.arcanePlatesStyledVisual:Hide() end
	local overlay = frame.arcanePlatesOverlay
	local bar = frame.arcanePlatesHealthBar
	local source = frame.arcanePlatesSourceBar
	if not overlay or not bar or not source then return false end
	local width = frame.arcanePlatesOverlayWidth
	local height = frame.arcanePlatesOverlayHeight
	if bar.w ~= width or bar.h ~= height then C.BarLayout(bar, width, height) end
	overlay:SetFrameLevel(math.max(frame:GetFrameLevel() + 2, source:GetFrameLevel() + 1))
	C.BarLevels(bar, overlay:GetFrameLevel())
	if frame.arcanePlatesBarThemeStamp ~= C.palStamp then
		C.BarTheme(bar, C.Pal())
		frame.arcanePlatesBarThemeStamp = C.palStamp
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

	if not frame.arcanePlatesStyledVisual then
		frame.arcanePlatesStyledVisual = FindStyledVisual(frame, frame.arcanePlatesSourceBar)
	end
	if not frame.arcanePlatesSourceBar then
		local children = { frame:GetChildren() }
		for i = 1, table.getn(children) do
			if P.State.IsHealthStatusBar(children[i]) then
				frame.arcanePlatesSourceBar = children[i]
				break
			end
		end
	end
	if not frame.arcanePlatesSourceBar and frame.arcanePlatesStyledVisual then
		local bars = {}
		P.State.CollectStatusBars(frame.arcanePlatesStyledVisual, bars)
		for i = 1, table.getn(bars) do
			if bars[i]:GetWidth() > 0 and bars[i]:GetHeight() > 0 then
				frame.arcanePlatesSourceBar = bars[i]
				break
			end
		end
	end
	if not frame.arcanePlatesSourceBar then
		local bars = {}
		P.State.CollectStatusBars(frame, bars)
		for i = 1, table.getn(bars) do
			if bars[i] ~= frame.arcanePlatesOverlay
					and bars[i]:GetWidth() > 0 and bars[i]:GetHeight() > 0 then
				frame.arcanePlatesSourceBar = bars[i]
				break
			end
		end
	end
	if not frame.arcanePlatesSourceBar then return false end

	local source = frame.arcanePlatesSourceBar
	local originalWidth = frame.arcanePlatesSourceOriginalWidth or source:GetWidth()
	local originalHeight = frame.arcanePlatesSourceOriginalHeight or source:GetHeight()
	local point, relativeTo, relativePoint, x, y = source:GetPoint()
	local oldVisuals = frame.arcanePlatesVisuals or {}
	for j = 1, table.getn(oldVisuals) do
		if oldVisuals[j].region == source then
			originalWidth, originalHeight = oldVisuals[j].width, oldVisuals[j].height
			point, relativeTo, relativePoint = oldVisuals[j].point, oldVisuals[j].relativeTo, oldVisuals[j].relativePoint
			x, y = oldVisuals[j].x, oldVisuals[j].y
			break
		end
	end
	if not point then return false end
	frame.arcanePlatesSourceOriginalWidth, frame.arcanePlatesSourceOriginalHeight = originalWidth, originalHeight
	local visualScale = P.Special.IsBossOrGuardianPlate(frame) and 1 or 0.5
	local width, height = originalWidth * visualScale, originalHeight * visualScale
	local adjustedX, adjustedY = x or 0, y or 0
	if string.find(point, "LEFT") then adjustedX = adjustedX + width / 2 end
	if string.find(point, "BOTTOM") then adjustedY = adjustedY + height / 2 end
	local offsetX, offsetY = 10, 14
	if visualScale == 1 then offsetX, offsetY = 0, 0 end

	if not frame.arcanePlatesHealthBar then
		local bar = C.NewBar(frame, width, height, true)
		frame.arcanePlatesHealthBar = bar
		frame.arcanePlatesOverlay = bar.frame
	else
		local bar = frame.arcanePlatesHealthBar
		if bar.w ~= width or bar.h ~= height then C.BarLayout(bar, width, height) end
	end
	frame.arcanePlatesOverlayPoint = point
	frame.arcanePlatesOverlayRelativeTo = relativeTo or frame
	frame.arcanePlatesOverlayRelativePoint = relativePoint or point
	frame.arcanePlatesOverlayX, frame.arcanePlatesOverlayY = adjustedX, adjustedY
	frame.arcanePlatesOverlayWidth, frame.arcanePlatesOverlayHeight = width, height
	frame.arcanePlatesOverlayBaseWidth, frame.arcanePlatesOverlayBaseHeight = originalWidth, originalHeight
	local overlay = frame.arcanePlatesOverlay
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
		local bar = frame.arcanePlatesHealthBar
		local source = frame.arcanePlatesSourceBar
		if bar and source and frame:IsVisible() and frame.arcanePlatesOverlay
				and frame.arcanePlatesOverlay:IsShown() then
			local minimum, maximum = source:GetMinMaxValues()
			local range = (maximum or 0) - (minimum or 0)
			local value = source:GetValue() or 0
			local ratio = range > 0 and C.Clamp((value - minimum) / range, 0, 1) or 0
			C.BarStep(bar, ratio, dt, now)
			UpdatePlateHealthText(frame, source)
			if frame.arcanePlatesBarThemeStamp ~= C.palStamp then
				C.BarTheme(bar, C.Pal())
				frame.arcanePlatesBarThemeStamp = C.palStamp
			end
		end
	end
end

P.Visuals.Apply = Apply
P.Visuals.SyncOverlayValues = SyncOverlayValues
