-- Nameplate visuals: overlay creation, health display and labels.
local C = Arcane
C.Nameplates = C.Nameplates or {}
local P = C.Nameplates
P.Visuals = {}

local function IsPlaceholderShrunk(frame)
	local visual = frame.arcaneNameplatesStyledVisual
	if visual and visual:IsShown() and frame.arcaneNameplatesStyledOriginalScale then
		return visual:GetScale() < frame.arcaneNameplatesStyledOriginalScale * 0.99
	end
	local overlay = frame.arcaneNameplatesOverlay
	if overlay and overlay:IsShown() and frame.arcaneNameplatesOverlayBaseWidth then
		local expected = frame.arcaneNameplatesOverlayBaseWidth
			* (frame.arcaneNameplatesOverlayScale or 1)
		return overlay:GetWidth() < expected * 0.99
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
		if frame.arcaneNameplatesBossGuardianLabelHolder then
			frame.arcaneNameplatesBossGuardianLabelHolder:Hide()
		end
		return
	end
	P.Special.UpdateBossGuardianLabel(frame)
	P.Special.ApplyBossGuardianLabelFont(frame)
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
	-- No spaces around the separator: a FontString may wrap at spaces, which made the
	-- health pair appear as two stacked rows when a large health value crossed the width limit.
	if hpm >= 100000 then return C.Short(hp) .. "/" .. C.Short(hpm) end
	return C.Commas(hp) .. "/" .. C.Commas(hpm)
end

local function FitHealthText(frame, width, baseSize)
	local text = frame.arcaneNameplatesHealthText
	if not text then return end
	if frame.arcaneNameplatesHealthTextWidth ~= width then
		text:SetWidth(width)
		frame.arcaneNameplatesHealthTextWidth = width
	end
	if frame.arcaneNameplatesHealthTextBaseSize == baseSize
			and frame.arcaneNameplatesHealthTextFitWidth == width
			and frame.arcaneNameplatesHealthTextFitValue == frame.arcaneNameplatesHealthTextValue
			and frame.arcaneNameplatesHealthTextFitMaximum == frame.arcaneNameplatesHealthTextMaximum then
		return
	end

	local size = baseSize
	C.SetFace(text, C.FONT, size, "OUTLINE")
	local measured = text:GetStringWidth() or 0
	while measured > width and size > 6 do
		size = size - 0.5
		C.SetFace(text, C.FONT, size, "OUTLINE")
		measured = text:GetStringWidth() or 0
	end
	text:SetHeight(size * 1.6)
	frame.arcaneNameplatesHealthTextSize = size
	frame.arcaneNameplatesHealthTextBaseSize = baseSize
	frame.arcaneNameplatesHealthTextFitWidth = width
	frame.arcaneNameplatesHealthTextFitValue = frame.arcaneNameplatesHealthTextValue
	frame.arcaneNameplatesHealthTextFitMaximum = frame.arcaneNameplatesHealthTextMaximum
end

local function UpdatePlateHealthText(frame, source)
	if not P.Option("showHealthText") then
		if frame.arcaneNameplatesHealthText and frame.arcaneNameplatesHealthText:IsShown() then
			frame.arcaneNameplatesHealthText:Hide()
		end
		return
	end
	local baseSize = frame.arcaneNameplatesBossGuardian and 10 or 8
	local width = math.max(36, frame.arcaneNameplatesOverlayWidth - 8)
	if not frame.arcaneNameplatesHealthText then
		local text = C.Text(frame.arcaneNameplatesHealthBar.top, C.FONT, baseSize, "OUTLINE",
			"CENTER", width)
		text:SetPoint("CENTER", frame.arcaneNameplatesOverlay, "CENTER", 0, 0)
		frame.arcaneNameplatesHealthText = text
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
	FitHealthText(frame, width, baseSize)
	if not frame.arcaneNameplatesHealthText:IsShown() then frame.arcaneNameplatesHealthText:Show() end
end

local function EnsureLevelBadge(frame)
	if frame.arcaneNameplatesLevelBadge then return frame.arcaneNameplatesLevelBadge end
	local overlay = frame.arcaneNameplatesOverlay
	if not overlay then return nil end

	local size = math.max(16, math.min(20, frame.arcaneNameplatesOverlayHeight + 9))
	local badge = CreateFrame("Frame", nil, overlay)
	badge:SetWidth(size)
	badge:SetHeight(size)
	badge:SetPoint("LEFT", overlay, "RIGHT", -1, 0)
	badge:SetFrameLevel(overlay:GetFrameLevel() + 5)

	badge.edge = C.Tex(badge, "BACKGROUND", C.FLAT)
	badge.edge:SetAllPoints(badge)
	badge.fill = C.Tex(badge, "BORDER", C.FLAT)
	badge.fill:SetPoint("TOPLEFT", badge, "TOPLEFT", 1, -1)
	badge.fill:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", -1, 1)
	badge.text = C.Text(badge, C.FONT, 8, "OUTLINE", "CENTER", size - 2)
	badge.text:SetHeight(size - 2)
	badge.text:SetPoint("CENTER", badge, "CENTER", 0, 0)
	badge.text:SetText("")

	frame.arcaneNameplatesLevelBadge = badge
	frame.arcaneNameplatesLevelBadgeSize = size
	return badge
end

local function UpdatePlateLevelBadge(frame)
	local badge = EnsureLevelBadge(frame)
	if not badge then return end
	local size = math.max(16, math.min(20, frame.arcaneNameplatesOverlayHeight + 9))
	if frame.arcaneNameplatesLevelBadgeSize ~= size then
		badge:SetWidth(size)
		badge:SetHeight(size)
		badge.text:SetWidth(size - 2)
		badge.text:SetHeight(size - 2)
		frame.arcaneNameplatesLevelBadgeSize = size
	end
	if frame.arcaneNameplatesLevelBadgeFrameLevel ~= frame.arcaneNameplatesOverlay:GetFrameLevel() + 5 then
		badge:SetFrameLevel(frame.arcaneNameplatesOverlay:GetFrameLevel() + 5)
		frame.arcaneNameplatesLevelBadgeFrameLevel = frame.arcaneNameplatesOverlay:GetFrameLevel() + 5
	end
	local level = frame.arcaneNameplatesPlateLevel
	if type(level) ~= "number" or level < 1 then
		if badge:IsShown() then badge:Hide() end
		return
	end

	local levelText = tostring(math.floor(level))
	if frame.arcaneNameplatesLevelBadgeText ~= levelText then
		C.SetText(badge.text, levelText)
		frame.arcaneNameplatesLevelBadgeText = levelText
	end

	if frame.arcaneNameplatesLevelBadgeThemeStamp ~= C.palStamp then
		local pal = C.Pal()
		badge.edge:SetVertexColor(pal.rim[1], pal.rim[2], pal.rim[3], 1)
		badge.fill:SetVertexColor(pal.trough[1], pal.trough[2], pal.trough[3], 0.98)
		badge.text:SetTextColor(pal.title[1], pal.title[2], pal.title[3])
		frame.arcaneNameplatesLevelBadgeThemeStamp = C.palStamp
	end
	if not badge:IsShown() then badge:Show() end
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
	UpdatePlateLevelBadge(frame)
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
	-- The native StatusBar is the one direct StatusBar child of the exact WorldFrame plate.
	-- Center the replacement on that bar; do not reuse its BOTTOMLEFT point with a center offset.
	local source = frame.arcaneNameplatesSourceBar or frame.arcaneNameplatesNativeBar
	if not source or not P.State.IsHealthStatusBar(source) then return false end
	frame.arcaneNameplatesSourceBar = source

	local originalWidth, originalHeight = source:GetWidth(), source:GetHeight()
	if not originalWidth or not originalHeight or originalWidth < 20 or originalWidth > 512
			or originalHeight < 3 or originalHeight > 128 then return false end
	frame.arcaneNameplatesSourceOriginalWidth = originalWidth
	frame.arcaneNameplatesSourceOriginalHeight = originalHeight

	local visualScale = P.Special.IsBossOrGuardianPlate(frame) and 1 or 0.75
	local width, height = originalWidth * visualScale, originalHeight * visualScale
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

	frame.arcaneNameplatesOverlayWidth, frame.arcaneNameplatesOverlayHeight = width, height
	frame.arcaneNameplatesOverlayBaseWidth, frame.arcaneNameplatesOverlayBaseHeight = originalWidth, originalHeight
	frame.arcaneNameplatesOverlayScale = visualScale
	local overlay = frame.arcaneNameplatesOverlay
	overlay:ClearAllPoints()
	overlay:SetPoint("CENTER", source, "CENTER", offsetX, offsetY)
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
			local sourceWidth, sourceHeight = source:GetWidth(), source:GetHeight()
			if math.abs(sourceWidth - (frame.arcaneNameplatesSourceOriginalWidth or 0)) > 0.5
					or math.abs(sourceHeight - (frame.arcaneNameplatesSourceOriginalHeight or 0)) > 0.5 then
				-- The game's plate geometry changes on viewport resize. Recompute the child bar
				-- from the live native StatusBar dimensions instead of keeping stale geometry.
				if Apply(frame) then
					bar = frame.arcaneNameplatesHealthBar
				else
					bar = nil
				end
			end
			if bar then
				local minimum, maximum = source:GetMinMaxValues()
				local range = (maximum or 0) - (minimum or 0)
				local value = source:GetValue() or 0
				local ratio = range > 0 and C.Clamp((value - minimum) / range, 0, 1) or 0
				C.BarStep(bar, ratio, dt, now)
				UpdatePlateHealthText(frame, source)
				UpdatePlateLevelBadge(frame)
				if frame.arcaneNameplatesBarThemeStamp ~= C.palStamp then
					C.BarTheme(bar, C.Pal())
					frame.arcaneNameplatesBarThemeStamp = C.palStamp
				end
			end
		end
	end
end

P.Visuals.Apply = Apply
P.Visuals.SyncOverlayValues = SyncOverlayValues
