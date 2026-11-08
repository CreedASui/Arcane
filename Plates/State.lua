-- Native nameplate discovery and reversible state management.
local C = Arcane
C.Plates = C.Plates or {}
local P = C.Plates
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
	return object == frame.arcanePlatesOverlay
		or object == frame.arcanePlatesDebuffRow
		or object == frame.arcanePlatesShrunkLabelHolder
		or object == frame.arcanePlatesBossGuardianLabelHolder
		or object == frame.arcanePlatesBossGuardianLabel
end

-- Searches descendants because replacement UIs may put the name in a child frame.
local function GetPlateName(frame, root)
	root = root or frame
	local regions = { root:GetRegions() }
	for i = 1, table.getn(regions) do
		local region = regions[i]
		if region and region ~= frame.arcanePlatesBossGuardianLabel
				and region:GetObjectType() == "FontString" then
			local name = NormalizeName(region:GetText())
			-- Purely numeric text is a level indicator, not a name.
			if name and not string.find(name, "^%d+$") then
				return name
			end
		end
	end
	local children = { root:GetChildren() }
	for i = 1, table.getn(children) do
		if not IsOwnObject(frame, children[i]) then
			local name = GetPlateName(frame, children[i])
			if name then return name end
		end
	end
	return nil
end

local function FindNameFontString(frame, name)
	local fallback
	local regions = { frame:GetRegions() }
	for i = 1, table.getn(regions) do
		local region = regions[i]
		if region and region:GetObjectType() == "FontString" then
			local text = region:GetText()
			if text == name then return region end
			if not fallback and text and text ~= "" then fallback = region end
		end
	end
	local children = { frame:GetChildren() }
	for i = 1, table.getn(children) do
		if not IsOwnObject(frame, children[i]) then
			local found = FindNameFontString(children[i], name)
			if found and found:GetText() == name then return found end
			if not fallback and found then fallback = found end
		end
	end
	return fallback
end

local function SaveObjectState(object, states, plate)
	plate = plate or object
	-- The root plate's visibility belongs to the game. Never restore it from our snapshot:
	-- a pooled plate may have been hidden by the game since it was first discovered.
	if object ~= plate then
		-- Arcane-owned overlays have independent lifetimes and are not native state.
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
	if frame.arcanePlatesNativeCaptured then return end
	local previouslyStyled = frame.arcanePlatesStyledVisual or frame.arcanePlatesOverlay
	local states = {}
	SaveObjectState(frame, states)
	-- If an older version already modified this frame, an accurate child snapshot no longer
	-- exists. Keep any snapshot already saved on the frame; do not invent a blanket "show all"
	-- restoration policy for another addon or the game's UI.
	if not previouslyStyled then
		frame.arcanePlatesNativeState = states
	elseif type(frame.arcanePlatesNativeState) ~= "table" then
		frame.arcanePlatesNativeState = nil
	end
	frame.arcanePlatesNativeCaptured = true
end

local function RestoreNativeState(frame)
	if frame.arcanePlatesOverlay then frame.arcanePlatesOverlay:Hide() end
	if type(frame.arcanePlatesNativeState) == "table" then
		for i = 1, table.getn(frame.arcanePlatesNativeState) do
			local state = frame.arcanePlatesNativeState[i]
			local object = state.object
			if object and not IsOwnObject(frame, object) then
				if object.SetAlpha and state.alpha ~= nil then object:SetAlpha(state.alpha) end
				if state.shown then object:Show() else object:Hide() end
			end
		end
	end

	-- The WorldFrame plate's size and world-projected anchor belong to the game. Tiny Plates
	-- restores only native child visibility/alpha that it explicitly changed.
	if frame.arcanePlatesBossGuardianLabel then frame.arcanePlatesBossGuardianLabel:Hide() end
	if frame.arcanePlatesBossGuardianLabelHolder then frame.arcanePlatesBossGuardianLabelHolder:Hide() end
	if frame.arcanePlatesShrunkLabelHolder then frame.arcanePlatesShrunkLabelHolder:Hide() end
	if frame.arcanePlatesDebuffRow then frame.arcanePlatesDebuffRow:Hide() end
	frame.arcanePlatesNativeRestored = true
end

local function IsHealthStatusBar(bar)
	if not bar or bar:GetObjectType() ~= "StatusBar" then return false end
	local width, height = bar:GetWidth(), bar:GetHeight()
	-- The game plate has one wide horizontal health bar. Exclude incidental meter bars.
	return width and height and width >= 20 and height >= 3 and width >= height * 2
end

local function ContainsStatusBar(frame)
	local children = { frame:GetChildren() }
	for i = 1, table.getn(children) do
		local child = children[i]
		if IsHealthStatusBar(child) then
			return true
		elseif child:GetObjectType() ~= "StatusBar" and ContainsStatusBar(child) then
			return true
		end
	end
	return false
end

local function IdentifyNameplate(frame)
	-- Azeroth Survivors creates its native V-plates as anonymous Button children of WorldFrame.
	-- Requiring their name and health bar keeps unrelated WorldFrame frames out of the registry.
	if frame:GetObjectType() ~= "Button" then return false end
	local width, height = frame:GetWidth(), frame:GetHeight()
	if not width or not height or width <= 0 or height <= 0 then return false end
	return GetPlateName(frame) ~= nil and ContainsStatusBar(frame)
end

local function HideNameText(frame)
	local regions = { frame:GetRegions() }
	for i = 1, table.getn(regions) do
		local region = regions[i]
		if region and region ~= frame.arcanePlatesBossGuardianLabel
				and region:GetObjectType() == "FontString" then
			region:SetAlpha(0)
			region:Hide()
		end
	end
end

local function HideMatchingNameText(frame, name, keep)
	if not name or name == "" or frame == keep then return end
	local regions = { frame:GetRegions() }
	for i = 1, table.getn(regions) do
		local region = regions[i]
		if region and region ~= keep and region:GetObjectType() == "FontString"
				and region:GetText() == name then
			region:SetAlpha(0)
			region:Hide()
		end
	end
	local children = { frame:GetChildren() }
	for i = 1, table.getn(children) do
		if not IsOwnObject(frame, children[i]) then
			HideMatchingNameText(children[i], name, keep)
		end
	end
end

local function HideNativePlate(frame, keep)
	local regions = { frame:GetRegions() }
	for i = 1, table.getn(regions) do
		local region = regions[i]
		if region and region:GetObjectType() == "Texture" then region:Hide() end
	end
	local children = { frame:GetChildren() }
	for i = 1, table.getn(children) do
		if children[i] ~= keep and children[i] ~= frame.arcanePlatesOverlay
				and children[i] ~= frame.arcanePlatesShrunkLabelHolder then
			children[i]:Hide()
		end
	end
end

local function CollectStatusBars(frame, list)
	local children = { frame:GetChildren() }
	for i = 1, table.getn(children) do
		local child = children[i]
		if IsHealthStatusBar(child) then
			table.insert(list, child)
		elseif child:GetObjectType() ~= "StatusBar" then
			CollectStatusBars(child, list)
		end
	end
	return list
end

local function RegisterPlate(frame, knownPlates, orderedPlates)
	if not frame or not frame.IsVisible or not frame:IsVisible()
			or not frame.GetWidth or frame:GetWidth() <= 0
			or not frame.GetHeight or frame:GetHeight() <= 0 then return false end
	local known = knownPlates[frame] and true or false
	if not known and not IdentifyNameplate(frame) then return false end

	local currentName = GetPlateName(frame)
	local oldName = frame.arcanePlatesPlateName
	-- A briefly blank name is common while a pooled plate is being reused. Do not treat
	-- that transient state as a new unit or throw away the last valid identity.
	local nameChanged = currentName and currentName ~= oldName
	if known and nameChanged and oldName ~= nil then
		RestoreNativeState(frame)
	end

	if not known then
		knownPlates[frame] = true
		table.insert(orderedPlates, frame)
		CaptureNativeState(frame)
	elseif nameChanged then
		-- A recycled frame may contain new native regions/children. Capture those after
		-- restoring the previous unit, while retaining the original objects' snapshots.
		if type(frame.arcanePlatesNativeState) == "table" then
			-- The old unit's captured state has just been restored. Replace the snapshot
			-- with this pooled unit's current tree instead of accumulating retired objects.
			local fresh = {}
			SaveObjectState(frame, fresh)
			frame.arcanePlatesNativeState = fresh
		end
	end

	if nameChanged then
		frame.arcanePlatesPlateName = currentName
		-- A pooled frame may receive a different native visual tree. Drop cached references so
		-- the replacement bar is rebound to the new unit's actual StatusBar and name container.
		frame.arcanePlatesSourceBar = nil
		frame.arcanePlatesStyledVisual = nil
		frame.arcanePlatesStyledOriginalScale = nil
		frame.arcanePlatesSourceOriginalWidth = nil
		frame.arcanePlatesSourceOriginalHeight = nil
		frame.arcanePlatesDebuffUnitID = nil
		frame.arcanePlatesDebuffSignature = nil
		frame.arcanePlatesAppliedCategory = nil
		frame.arcanePlatesStyleRevision = -1
		frame.arcanePlatesNativeRestored = false
		if frame.arcanePlatesHealthBar then frame.arcanePlatesHealthBar.snap = true end
	end
	return true
end

P.State.NormalizeName = NormalizeName
P.State.GetPlateName = GetPlateName
P.State.FindNameFontString = FindNameFontString
P.State.IsOwnObject = IsOwnObject
P.State.CaptureNativeState = CaptureNativeState
P.State.RestoreNativeState = RestoreNativeState
P.State.ContainsStatusBar = ContainsStatusBar
P.State.IsHealthStatusBar = IsHealthStatusBar
P.State.IdentifyNameplate = IdentifyNameplate
P.State.HideNameText = HideNameText
P.State.HideMatchingNameText = HideMatchingNameText
P.State.HideNativePlate = HideNativePlate
P.State.CollectStatusBars = CollectStatusBars
P.State.RegisterPlate = RegisterPlate
