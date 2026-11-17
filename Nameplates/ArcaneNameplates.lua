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
local refreshPending = true
local worldChildCount = -1
local nextPoolProbe = 0
local retryUnreadyChildren = false
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

local function ApplyKnownPlate(frame)
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

	if not special and frame.arcaneNameplatesDebuffRow then
		P.Special.HideDebuffs(frame)
	end
end

-- Only debuff metadata needs the slow polling bus; plate identity/reuse
-- remains same-frame to avoid showing the previous enemy on a pooled plate.
local function RefreshDebuffs()
	SafeCall("boss and guardian index", P.Special.RefreshNames, false, orderedPlates)
	for i = 1, table.getn(orderedPlates) do
		local frame = orderedPlates[i]
		if frame.arcaneNameplatesBossGuardian and frame:IsVisible() then
			if P.Option("showDebuffs") then
				SafeCall("boss debuff update", P.Special.UpdateDebuffs, frame)
			else
				P.Special.HideDebuffs(frame)
			end
		end
	end
end

local function DiscoverNativePool(children)
	local retry = false
	for i = 1, table.getn(children) do
		local frame = children[i]
		if frame and not checkedWorldChildren[frame] then
			if frame.GetObjectType and frame:GetObjectType() == "Button" then
				local ok, recognized = SafeCall("plate discovery", P.State.IdentifyNameplate, frame)
				if ok and recognized then
					local registered, success = SafeCall("plate registration", RegisterPlate, frame)
					if registered and success then checkedWorldChildren[frame] = true
					else retry = true end
				else
					-- The native button can be sized before its FontStrings and
					-- StatusBar are constructed. Retry plausible anonymous plates.
					local width = frame.GetWidth and frame:GetWidth()
					local height = frame.GetHeight and frame:GetHeight()
					local anonymous = not frame.GetName or frame:GetName() == nil
					if anonymous and width and height and width > 0 and width <= 640
							and height > 0 and height <= 192 then
						retry = true
					elseif width and height and width > 0 and height > 0 then
						checkedWorldChildren[frame] = true
					else
						retry = true
					end
				end
			else
				checkedWorldChildren[frame] = true
			end
		end
	end
	return retry
end

local function ScanNameplates()
	if type(WorldFrame) ~= "table" or type(WorldFrame.GetChildren) ~= "function" then return end
	local now = GetTime()
	local childCount = type(WorldFrame.GetNumChildren) == "function" and WorldFrame:GetNumChildren() or nil
	-- Direct WorldFrame children are not destroyed in this client. Re-enumerate
	-- when the pool grows; known pooled plates still get their identity checked
	-- every frame. A sparse periodic probe covers incomplete initial frames and
	-- clients lacking GetNumChildren, without allocating an array every frame.
	if childCount ~= worldChildCount or now >= nextPoolProbe then
		local children = { WorldFrame:GetChildren() }
		retryUnreadyChildren = DiscoverNativePool(children)
		worldChildCount = childCount
		nextPoolProbe = now + ((childCount == nil or retryUnreadyChildren) and 0.10 or 2)
	end

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

	-- Reuse the one cached plate registry directly. Pooled frames are checked
	-- on the very update that notices reuse; full child discovery is infrequent.
	for i = 1, table.getn(orderedPlates) do
		local frame = orderedPlates[i]
		if frame:IsVisible() then
			local special = P.Special.IsBossOrGuardianPlate(frame)
			local category = special and "boss" or "regular"
			if frame.arcaneNameplatesNeedsStyle
					or frame.arcaneNameplatesNameChangedPending
					or frame.arcaneNameplatesAppliedCategory ~= category
					or frame.arcaneNameplatesStyleRevision ~= styleRevision then
					SafeCall("plate style", ApplyKnownPlate, frame)
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
	-- These are the only nameplate jobs that need a regular interval. Their
	-- clocks and error isolation now belong to the shared Arcane polling bus.
	C.Poll.Add("nameplates.overlay", OVERLAY_INTERVAL, SyncOverlayValues, true)
	C.Poll.Add("nameplates.debuffs", DEBUFF_INTERVAL, RefreshDebuffs, true)
	scanFrame:SetScript("OnUpdate", function()
		-- Native nameplate reuse can occur between any two frames; keep this
		-- inexpensive identity check immediate, never delay it behind a poll.
		ScanNameplates()
	end)
end)

C.OnWorld(function()
	if scanFrame then
		RefreshAll()
		worldChildCount, nextPoolProbe = -1, 0
		scanFrame:Show()
		C.Poll.Kick("nameplates.overlay")
		C.Poll.Kick("nameplates.debuffs")
	end
end)

C.OnLogout(function() RestoreAll() end)
