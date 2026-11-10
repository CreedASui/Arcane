-- Arcane Nameplates controller: cached native-plate pool and immediate lifecycle updates.
local C = Arcane
C.Nameplates = C.Nameplates or {}
local P = C.Nameplates

P.Option = function(key)
	if type(C.ArcaneNameplatesOption) == "function" then return C.ArcaneNameplatesOption(key) end
	return false
end

-- Native plates are pooled WorldFrame children. Identify their fixed 6-region/1-StatusBar
-- signature once, cache those objects, then only read the two identity strings from known frames.
local knownPlates = {}
local orderedPlates = {}
local checkedWorldChildren = {}
local OVERLAY_INTERVAL = 0.10
local DEBUFF_INTERVAL = 0.25
local overlayClock = 0
local debuffClock = 0
local refreshPending = true
local styleRevision = 0
local scanFrame

local reportedErrors = {}

local function ReportError(scope, err)
	local message = tostring(err)
	if reportedErrors[scope] == message then return end
	reportedErrors[scope] = message
	C.Print(C.L("Arcane Nameplates encountered an error in ") .. scope .. ": " .. message)
end

local function SafeCall(scope, callback, first, second)
	local ok, result, extra, fourth = pcall(callback, first, second)
	if not ok then
		ReportError(scope, result)
		return false
	end
	reportedErrors[scope] = nil
	return true, result, extra, fourth
end

local function RegisterPlate(frame)
	return P.State.RegisterPlate(frame, knownPlates, orderedPlates)
end

local function SyncOverlayValues()
	SafeCall("health-bar update", P.Visuals.SyncOverlayValues, orderedPlates)
end

local function ApplyKnownPlate(frame, updateDebuffs)
	if not frame or not frame.GetObjectType or frame:GetObjectType() ~= "Button" then return end
	if not frame.IsVisible or not frame:IsVisible() then return end

	local special = P.Special.IsBossOrGuardianPlate(frame)
	local category = special and "boss" or "regular"
	if frame.arcaneNameplatesAppliedCategory ~= category
			or frame.arcaneNameplatesStyleRevision ~= styleRevision then
		if P.Visuals.Apply(frame) then
			frame.arcaneNameplatesAppliedCategory = category
			frame.arcaneNameplatesStyleRevision = styleRevision
		else
			frame.arcaneNameplatesAppliedCategory = nil
			frame.arcaneNameplatesStyleRevision = -1
		end
	end

	if special then
		if updateDebuffs then
			if P.Option("showDebuffs") then
				SafeCall("boss debuff update", P.Special.UpdateDebuffs, frame)
			else
				P.Special.HideDebuffs(frame)
			end
		end
	elseif frame.arcaneNameplatesDebuffRow then
		P.Special.HideDebuffs(frame)
	end
end

local function StyleKnownPlates(updateDebuffs)
	SafeCall("boss and guardian index", P.Special.RefreshNames, false, orderedPlates)
	for i = 1, table.getn(orderedPlates) do
		local frame = orderedPlates[i]
		local scope = "plate " .. tostring(frame)
		local ok = SafeCall(scope, ApplyKnownPlate, frame, updateDebuffs)
		if not ok then
			frame.arcaneNameplatesAppliedCategory = nil
			frame.arcaneNameplatesStyleRevision = -1
		end
	end
end

local function DiscoverNativePool(children)
	for i = 1, table.getn(children) do
		local frame = children[i]
		if frame and not checkedWorldChildren[frame] then
			if frame.GetObjectType and frame:GetObjectType() == "Button" then
				local ok, recognized = SafeCall("plate discovery", P.State.IdentifyNameplate, frame)
				if ok and recognized then
					checkedWorldChildren[frame] = true
					SafeCall("plate registration", RegisterPlate, frame)
				elseif frame.GetWidth and frame:GetWidth() > 0
						and frame.GetHeight and frame:GetHeight() > 0 then
						checkedWorldChildren[frame] = true
				end
			else
				checkedWorldChildren[frame] = true
			end
		end
	end
end

local function ScanNameplates(updateDebuffs)
	if type(WorldFrame) ~= "table" or type(WorldFrame.GetChildren) ~= "function" then return end
	local children = { WorldFrame:GetChildren() }
	DiscoverNativePool(children)

	local refreshSpecialNames = false
	local anyIdentityChange = false
	for i = 1, table.getn(orderedPlates) do
		local frame = orderedPlates[i]
		local ok, registered, identityChanged, nameWasChanged = SafeCall(
			"plate lifecycle", RegisterPlate, frame)
		if ok and registered and frame:IsVisible() then
			if identityChanged or nameWasChanged or frame.arcaneNameplatesNeedsStyle
					or frame.arcaneNameplatesStyleRevision ~= styleRevision then
				anyIdentityChange = true
			end
			if nameWasChanged or frame.arcaneNameplatesNameChangedPending then
				refreshSpecialNames = true
			end
		end
	end

	-- Run snapshots are independent of plate discovery: a boss can become known in AZS_UNITS
	-- while its native nameplate frame and name remain unchanged.
	if refreshPending or refreshSpecialNames then
		SafeCall("boss and guardian index", P.Special.RefreshNames, refreshSpecialNames, orderedPlates)
		refreshPending = false
	elseif anyIdentityChange then
		SafeCall("boss and guardian index", P.Special.RefreshNames, false, orderedPlates)
	end

	-- Reuse the one cached plate registry directly. No temporary active/dirty arrays are
	-- allocated each frame, and a pooled frame is styled on the same update that notices reuse.
	for i = 1, table.getn(orderedPlates) do
		local frame = orderedPlates[i]
		if frame:IsVisible() then
			local special = P.Special.IsBossOrGuardianPlate(frame)
			local category = special and "boss" or "regular"
			if frame.arcaneNameplatesNeedsStyle
					or frame.arcaneNameplatesNameChangedPending
					or frame.arcaneNameplatesAppliedCategory ~= category
					or frame.arcaneNameplatesStyleRevision ~= styleRevision then
					SafeCall("plate style", ApplyKnownPlate, frame, updateDebuffs)
					frame.arcaneNameplatesNeedsStyle = nil
					frame.arcaneNameplatesNameChangedPending = nil
			end
			-- The native game updates level/skull/raid/hover regions after creating the pooled plate.
			-- Re-hide only the cached native presentation after those writes each UI update.
			P.State.HideNativePresentation(frame)
		end
	end
end

local function RefreshAll()
	refreshPending = true
end

local function RestoreAll()
	for i = 1, table.getn(orderedPlates) do
		local frame = orderedPlates[i]
		if frame then
			SafeCall("native plate restoration", P.State.RestoreNativeState, frame)
			if frame.arcaneNameplatesOverlay then frame.arcaneNameplatesOverlay:Hide() end
			P.Special.HideDebuffs(frame)
			if frame.arcaneNameplatesBossGuardianLabel then frame.arcaneNameplatesBossGuardianLabel:Hide() end
			if frame.arcaneNameplatesBossGuardianLabelHolder then frame.arcaneNameplatesBossGuardianLabelHolder:Hide() end
			if frame.arcaneNameplatesShrunkLabelHolder then frame.arcaneNameplatesShrunkLabelHolder:Hide() end
			frame.arcaneNameplatesNativeRestored = true
		end
	end
end

C.ArcaneNameplatesRefresh = function(force)
	styleRevision = styleRevision + 1
	if force then RefreshAll() else refreshPending = true end
end

C.OnInit(function()
	local d = C.DB("nameplates", {
		showDebuffs = true, hideBossName = false,
		showShrunkName = false, showHealthText = true,
	})
	-- Arcane Nameplates is always active while Arcane is loaded; remove its retired global toggle.
	d["enabled"] = nil
	d["hideShrunkPlates"] = nil
	scanFrame = CreateFrame("Frame", "ArcaneNameplatesDriver")
	scanFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	scanFrame:RegisterEvent("CHAT_MSG_ADDON")
	scanFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	scanFrame:SetScript("OnEvent", function()
		if event == "CHAT_MSG_ADDON" and arg1 ~= "AZSUNITS" then return end
		RefreshAll()
	end)
	scanFrame:SetScript("OnUpdate", function()
		local dt = arg1 or 0
		if dt > 0.1 then dt = 0.1 end
		if dt < 0 then dt = 0 end

		-- Scan the tiny native child pool every UI frame. Recognition is exact and cached;
		-- known frames are read by their two cached native FontStrings, never recursively walked.
		local updateDebuffs = false
		debuffClock = debuffClock - dt
		if debuffClock <= 0 then
			debuffClock = DEBUFF_INTERVAL
			updateDebuffs = true
		end
		ScanNameplates(updateDebuffs)

		overlayClock = overlayClock - dt
		if overlayClock <= 0 then
			overlayClock = OVERLAY_INTERVAL
			SyncOverlayValues()
		end
		if refreshPending then
			refreshPending = false
			StyleKnownPlates(updateDebuffs)
		elseif updateDebuffs then
			SafeCall("boss and guardian index", P.Special.RefreshNames, false, orderedPlates)
			for i = 1, table.getn(orderedPlates) do
				local frame = orderedPlates[i]
				if frame.arcaneNameplatesBossGuardian and frame:IsVisible() and P.Option("showDebuffs") then
					SafeCall("boss debuff update", P.Special.UpdateDebuffs, frame)
				end
			end
		end
	end)
end)

C.OnWorld(function()
	if scanFrame then RefreshAll(); scanFrame:Show() end
end)

C.OnLogout(function() RestoreAll() end)
