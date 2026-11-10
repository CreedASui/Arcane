-- Native nameplate discovery and reversible state management.
-- Azeroth Survivors 1.12 plates have a fixed, documented shape:
-- anonymous WorldFrame Button; six root regions (4 textures, name + level FontStrings);
-- one direct StatusBar child. Identify that exact object once, then cache its regions.
local C = Arcane
C.Nameplates = C.Nameplates or {}
local P = C.Nameplates
P.State = {}

local function NormalizeName(text)
	if not text then return nil end
	text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
	text = string.gsub(text, "|r", "")
	text = string.gsub(text, "^%s+", "")
	text = string.gsub(text, "%s+$", "")
	if text == "" then return nil end
	return text
end

local function IsOwnObject(frame, object)
	return object == frame.arcaneNameplatesOverlay
		or object == frame.arcaneNameplatesDebuffRow
		or object == frame.arcaneNameplatesShrunkLabelHolder
		or object == frame.arcaneNameplatesBossGuardianLabelHolder
		or object == frame.arcaneNameplatesBossGuardianLabel
end

local function IsHealthStatusBar(bar)
	if not bar or bar:GetObjectType() ~= "StatusBar" then return false end
	local width, height = bar:GetWidth(), bar:GetHeight()
	-- Native plate bars are bounded horizontal strips. The upper bounds reject unrelated
	-- world-space widgets whose very wide StatusBars could otherwise create screen-sized overlays.
	return width and height and width >= 20 and width <= 512
		and height >= 3 and height <= 128 and width >= height * 2
end

local function CacheNativeParts(frame)
	if frame.arcaneNameplatesNativeRegions and frame.arcaneNameplatesNativeBar then return true end
	local regions = { frame:GetRegions() }
	if table.getn(regions) ~= 6 then return false end
	local children = { frame:GetChildren() }
	if table.getn(children) ~= 1 or not IsHealthStatusBar(children[1]) then return false end

	-- Exact order from CGNamePlateFrame: border, glow, name, level, skull, raid mark.
	if regions[1]:GetObjectType() ~= "Texture"
			or regions[2]:GetObjectType() ~= "Texture"
			or regions[3]:GetObjectType() ~= "FontString"
			or regions[4]:GetObjectType() ~= "FontString"
			or regions[5]:GetObjectType() ~= "Texture"
			or regions[6]:GetObjectType() ~= "Texture" then
		return false
	end
	frame.arcaneNameplatesNativeRegions = regions
	frame.arcaneNameplatesNameRegion = regions[3]
	frame.arcaneNameplatesLevelRegion = regions[4]
	frame.arcaneNameplatesNativeBar = children[1]
	return true
end

local function IdentifyNameplate(frame)
	if not frame or not frame.GetObjectType or frame:GetObjectType() ~= "Button" then return false end
	-- The native constructor explicitly creates an anonymous Button under WorldFrame.
	if type(frame.GetName) == "function" and frame:GetName() ~= nil then return false end
	local width, height = frame:GetWidth(), frame:GetHeight()
	if not width or not height or width <= 0 or width > 640 or height <= 0 or height > 192 then
		return false
	end
	return CacheNativeParts(frame)
end

local function GetPlateName(frame)
	local region = frame.arcaneNameplatesNameRegion
	if not region then
		if not CacheNativeParts(frame) then return nil end
		region = frame.arcaneNameplatesNameRegion
	end
	return NormalizeName(region:GetText())
end

local function GetPlateLevel(frame)
	local region = frame.arcaneNameplatesLevelRegion
	if not region then
		if not CacheNativeParts(frame) then return nil end
		region = frame.arcaneNameplatesLevelRegion
	end
	local value = region:GetText()
	if value and string.find(value, "^%d+$") then return tonumber(value) end
	return nil
end

local function SaveObjectState(object, states, plate)
	plate = plate or object
	-- The root plate's visibility belongs to the game. Never restore it from our snapshot.
	if object ~= plate then
		if IsOwnObject(plate, object) then return end
		local state = { object = object, shown = object:IsShown() }
		if object.GetAlpha then state.alpha = object:GetAlpha() end
		table.insert(states, state)
	end
	local kind = object:GetObjectType()
	if kind ~= "Texture" and kind ~= "FontString" then
		local regions = { object:GetRegions() }
		for i = 1, table.getn(regions) do SaveObjectState(regions[i], states, plate) end
		local children = { object:GetChildren() }
		for i = 1, table.getn(children) do SaveObjectState(children[i], states, plate) end
	end
end

local function CaptureNativeState(frame)
	if frame.arcaneNameplatesNativeCaptured then return end
	if not CacheNativeParts(frame) then return end
	local states = {}
	SaveObjectState(frame, states)
	frame.arcaneNameplatesNativeState = states
	frame.arcaneNameplatesNativeCaptured = true
end

local function RestoreNativeState(frame)
	if frame.arcaneNameplatesOverlay then frame.arcaneNameplatesOverlay:Hide() end
	if type(frame.arcaneNameplatesNativeState) == "table" then
		for i = 1, table.getn(frame.arcaneNameplatesNativeState) do
			local state = frame.arcaneNameplatesNativeState[i]
			local object = state.object
			if object and not IsOwnObject(frame, object) then
				if object.SetAlpha and state.alpha ~= nil then object:SetAlpha(state.alpha) end
				if state.shown then object:Show() else object:Hide() end
			end
		end
	end
	-- Root position, scale, size and visibility remain entirely game-owned.
	if frame.arcaneNameplatesBossGuardianLabel then frame.arcaneNameplatesBossGuardianLabel:Hide() end
	if frame.arcaneNameplatesBossGuardianLabelHolder then frame.arcaneNameplatesBossGuardianLabelHolder:Hide() end
	if frame.arcaneNameplatesShrunkLabelHolder then frame.arcaneNameplatesShrunkLabelHolder:Hide() end
	if frame.arcaneNameplatesDebuffRow then frame.arcaneNameplatesDebuffRow:Hide() end
	frame.arcaneNameplatesNativeRestored = true
end

local function HideNameText(frame)
	local regions = frame.arcaneNameplatesNativeRegions
	if not regions then return end
	for i = 3, 4 do
		local region = regions[i]
		if region and region:IsShown() then region:Hide() end
	end
end

local function HideNativePlate(frame, keep)
	local regions = frame.arcaneNameplatesNativeRegions
	if regions then
		for index = 1, 6 do
			if index == 1 or index == 2 or index == 5 or index == 6 then
				local region = regions[index]
				if region and region:IsShown() then region:Hide() end
			end
		end
	end
	local bar = frame.arcaneNameplatesNativeBar
	if bar and bar ~= keep and bar:IsShown() then bar:Hide() end
end

local function HideArcanePresentation(frame)
	if frame.arcaneNameplatesOverlay then frame.arcaneNameplatesOverlay:Hide() end
	if frame.arcaneNameplatesDebuffRow then frame.arcaneNameplatesDebuffRow:Hide() end
	if frame.arcaneNameplatesBossGuardianLabelHolder then frame.arcaneNameplatesBossGuardianLabelHolder:Hide() end
	if frame.arcaneNameplatesBossGuardianLabel then frame.arcaneNameplatesBossGuardianLabel:Hide() end
	if frame.arcaneNameplatesShrunkLabelHolder then frame.arcaneNameplatesShrunkLabelHolder:Hide() end
end

local function HideNativePresentation(frame)
	HideNameText(frame)
	HideNativePlate(frame, nil)
end

local function InstallLifecycleHooks(frame)
	if frame.arcaneNameplatesLifecycleHooks then return end
	local oldOnShow = frame:GetScript("OnShow")
	local oldOnHide = frame:GetScript("OnHide")
	frame:SetScript("OnShow", function()
		if oldOnShow then oldOnShow() end
		-- The game reuses hidden pool entries. Suppress both the old overlay and the just-shown
		-- native regions immediately; the same-frame driver below binds the new unit identity.
		frame.arcaneNameplatesPendingReuse = true
		frame.arcaneNameplatesWasShown = false
		HideArcanePresentation(frame)
		HideNativePresentation(frame)
	end)
	frame:SetScript("OnHide", function()
		if oldOnHide then oldOnHide() end
		frame.arcaneNameplatesPendingReuse = true
		frame.arcaneNameplatesWasShown = false
		HideArcanePresentation(frame)
	end)
	frame.arcaneNameplatesLifecycleHooks = true
end

local function RegisterPlate(frame, knownPlates, orderedPlates)
	if not frame or not frame.GetObjectType or frame:GetObjectType() ~= "Button" then
		return false, false, false
	end

	local known = knownPlates[frame] and true or false
	if not known then
		if not IdentifyNameplate(frame) then return false, false, false end
		knownPlates[frame] = true
		table.insert(orderedPlates, frame)
		CaptureNativeState(frame)
		InstallLifecycleHooks(frame)
		frame.arcaneNameplatesSourceBar = frame.arcaneNameplatesNativeBar
		frame.arcaneNameplatesAppliedCategory = nil
		frame.arcaneNameplatesStyleRevision = -1
	end
	if not frame.arcaneNameplatesNativeCaptured then CaptureNativeState(frame) end
	if not frame.arcaneNameplatesNativeCaptured then return false, false, false end

	local visible = frame.IsShown and frame:IsShown()
		and frame.IsVisible and frame:IsVisible()
	if not visible then
		frame.arcaneNameplatesWasShown = false
		return true, false, false
	end

	local currentName = GetPlateName(frame)
	local currentLevel = GetPlateLevel(frame)
	local oldName = frame.arcaneNameplatesPlateName
	local reactivated = frame.arcaneNameplatesPendingReuse or not frame.arcaneNameplatesWasShown
	frame.arcaneNameplatesPendingReuse = nil
	local nameChanged = currentName and currentName ~= oldName
	local changed = not known or nameChanged or reactivated

	if known and changed then
		-- Restore the one original snapshot before reapplying Arcane's child visuals.
		-- The native pool keeps the same six regions and StatusBar for the frame's lifetime.
		RestoreNativeState(frame)
	end
	if currentName then frame.arcaneNameplatesPlateName = currentName end
	if currentLevel then
		frame.arcaneNameplatesPlateLevel = currentLevel
	elseif changed then
		frame.arcaneNameplatesPlateLevel = nil
	end
	frame.arcaneNameplatesWasShown = true

	if changed then
		frame.arcaneNameplatesDebuffUnitID = nil
		frame.arcaneNameplatesDebuffSignature = nil
		frame.arcaneNameplatesAppliedCategory = nil
		frame.arcaneNameplatesStyleRevision = -1
		frame.arcaneNameplatesNativeRestored = false
		frame.arcaneNameplatesNeedsStyle = true
		if nameChanged then frame.arcaneNameplatesNameChangedPending = true end
		if frame.arcaneNameplatesHealthBar then frame.arcaneNameplatesHealthBar.snap = true end
	end
	return true, changed, nameChanged and true or false
end

P.State.NormalizeName = NormalizeName
P.State.IsOwnObject = IsOwnObject
P.State.GetPlateName = GetPlateName
P.State.GetPlateLevel = GetPlateLevel
P.State.IsHealthStatusBar = IsHealthStatusBar
P.State.IdentifyNameplate = IdentifyNameplate
P.State.CacheNativeParts = CacheNativeParts
P.State.CaptureNativeState = CaptureNativeState
P.State.RestoreNativeState = RestoreNativeState
P.State.HideNameText = HideNameText
P.State.HideNativePlate = HideNativePlate
P.State.HideNativePresentation = HideNativePresentation
P.State.RegisterPlate = RegisterPlate
