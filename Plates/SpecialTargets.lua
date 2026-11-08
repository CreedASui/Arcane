-- Boss/guardian identity, labels and debuff presentation.
local C = Arcane
C.Plates = C.Plates or {}
local P = C.Plates
P.Special = {}

local bossGuardianNames = {}
local bossGuardianUnitsByName = {}
local lastSpecialPhase
local lastSpecialUnitsUpdate
local lastSpecialDebuffsUpdate
local lastSpecialRefreshTime = 0
local debuffCache = {}

local function AddBossGuardianNames(units, requireKind)
	if type(units) ~= "table" then return end
	for i = 1, table.getn(units) do
		local unit = units[i]
		if unit.name and (not requireKind or unit.kind == "final"
				or unit.kind == "boss" or unit.kind == "guardian") then
			bossGuardianNames[unit.name] = true
			if unit.id then
				local candidates = bossGuardianUnitsByName[unit.name]
				if not candidates then
					candidates = {}
					bossGuardianUnitsByName[unit.name] = candidates
				end
				local replaced = false
				for j = 1, table.getn(candidates) do
					if candidates[j].id == unit.id then
						candidates[j] = unit
						replaced = true
						break
					end
				end
				if not replaced then table.insert(candidates, unit) end
			end
		end
	end
end

local function ClearPlateFlags(orderedPlates)
	for i = 1, table.getn(orderedPlates) do
		local frame = orderedPlates[i]
		frame.arcanePlatesBossGuardian = nil
		frame.arcanePlatesBossGuardianName = nil
		frame.arcanePlatesDebuffUnitID = nil
		frame.arcanePlatesDebuffSignature = nil
		if frame.arcanePlatesDebuffRow then frame.arcanePlatesDebuffRow:Hide() end
	end
end

local function RefreshBossGuardianNames(force, orderedPlates)
	local phase
	if type(AZS_GetPhase) == "function" then
		local ok, value = pcall(AZS_GetPhase)
		if ok then phase = value end
	end
	local unitsUpdate = AZS_UNITS_UPDATED or 0
	local debuffsUpdate = AZS_DEBUFFS_UPDATED or 0
	local newRun = phase == "playing" and (lastSpecialPhase == nil
		or lastSpecialPhase == "ready" or lastSpecialPhase == "dead"
		or lastSpecialPhase == "victory")
	local resetNames = (phase == "ready" and lastSpecialPhase ~= "ready") or newRun
	if resetNames then
		bossGuardianNames = {}
		bossGuardianUnitsByName = {}
		debuffCache = {}
		ClearPlateFlags(orderedPlates)
	end
	local retryCache = phase ~= "ready" and GetTime() - lastSpecialRefreshTime >= 1
	if phase ~= "ready" and (force or retryCache or phase ~= lastSpecialPhase
			or unitsUpdate ~= lastSpecialUnitsUpdate
			or debuffsUpdate ~= lastSpecialDebuffsUpdate or newRun) then
		-- Rebuild both indexes together so names from an earlier data snapshot do not linger.
		bossGuardianNames = {}
		bossGuardianUnitsByName = {}
		AddBossGuardianNames(AZS_UNITS, true)
		if type(AZS_GetBosses) == "function" then
			local ok, units = pcall(AZS_GetBosses)
			if ok then AddBossGuardianNames(units, false) end
		end
		if type(AZS_GetGuardians) == "function" then
			local ok, units = pcall(AZS_GetGuardians)
			if ok then AddBossGuardianNames(units, false) end
		end
		lastSpecialRefreshTime = GetTime()
	end
	lastSpecialPhase = phase
	lastSpecialUnitsUpdate = unitsUpdate
	lastSpecialDebuffsUpdate = debuffsUpdate
end

local function IsBossOrGuardianName(name)
	return name and bossGuardianNames[name] or false
end

local function IsBossOrGuardianPlate(frame)
	local name = frame.arcanePlatesPlateName
	if not name then
		frame.arcanePlatesBossGuardian = false
		frame.arcanePlatesBossGuardianName = nil
		return false
	end
	if frame.arcanePlatesBossGuardianName ~= name then
		frame.arcanePlatesDebuffUnitID = nil
		frame.arcanePlatesDebuffSignature = nil
		if frame.arcanePlatesDebuffRow then frame.arcanePlatesDebuffRow:Hide() end
	end
	if IsBossOrGuardianName(name) then
		frame.arcanePlatesBossGuardian = true
		frame.arcanePlatesBossGuardianName = name
		return true
	end
	frame.arcanePlatesBossGuardian = false
	frame.arcanePlatesBossGuardianName = nil
	return false
end

local function UpdateBossGuardianLabel(frame)
	local name = frame.arcanePlatesPlateName
	local holder = frame.arcanePlatesBossGuardianLabelHolder
	if not name or name == "" then
		if holder then holder:Hide() end
		return
	end
	if not holder then
		holder = CreateFrame("Frame", nil, frame)
		holder:SetAllPoints(frame)
		holder:SetFrameLevel(frame:GetFrameLevel() + 12)
		local label = C.Text(holder, C.FONT, 11, "OUTLINE", "CENTER", 180)
		label:SetHeight(14)
		label:SetTextColor(1, 0.86, 0.78)
		frame.arcanePlatesBossGuardianLabelHolder = holder
		frame.arcanePlatesBossGuardianLabel = label
	end
	local label = frame.arcanePlatesBossGuardianLabel
	local bar = frame.arcanePlatesOverlay or frame.arcanePlatesSourceBar
	label:ClearAllPoints()
	if bar then
		label:SetPoint("BOTTOM", bar, "TOP", 0, 3)
	else
		label:SetPoint("BOTTOM", frame, "TOP", 0, 3)
	end
	label:SetText(name)
	label:SetAlpha(1)
	holder:Show()
end

local function ApplyBossGuardianLabelFont(frame)
	local label = frame.arcanePlatesBossGuardianLabel
	if not label then return end
	C.SetFace(label, C.FONT, 11, "OUTLINE")
	C.TextColor(label, 1, 0.86, 0.78)
end

local DEBUFF_ICON_SIZE = 16
local DEBUFF_ICON_GAP = 2
local MAX_DEBUFF_ICONS = 10

local function CreateDebuffIcon(row, index)
	local icon = CreateFrame("Frame", nil, row)
	icon:SetWidth(DEBUFF_ICON_SIZE)
	icon:SetHeight(DEBUFF_ICON_SIZE)
	icon:SetPoint("LEFT", row, "LEFT", (index - 1) * (DEBUFF_ICON_SIZE + DEBUFF_ICON_GAP), 0)
	icon.texture = icon:CreateTexture(nil, "ARTWORK")
	icon.texture:SetAllPoints(icon)
	icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	icon.overlay = CreateFrame("Frame", nil, icon)
	icon.overlay:SetAllPoints(icon)
	icon.overlay:SetFrameLevel(icon:GetFrameLevel() + 1)
	local borderColor = { 0.05, 0.05, 0.05, 1 }
	icon.borderTop = icon.overlay:CreateTexture(nil, "OVERLAY")
	icon.borderTop:SetTexture("Interface\\Buttons\\WHITE8X8")
	icon.borderTop:SetVertexColor(unpack(borderColor))
	icon.borderTop:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
	icon.borderTop:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
	icon.borderTop:SetHeight(1)
	icon.borderBottom = icon.overlay:CreateTexture(nil, "OVERLAY")
	icon.borderBottom:SetTexture("Interface\\Buttons\\WHITE8X8")
	icon.borderBottom:SetVertexColor(unpack(borderColor))
	icon.borderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
	icon.borderBottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
	icon.borderBottom:SetHeight(1)
	icon.borderLeft = icon.overlay:CreateTexture(nil, "OVERLAY")
	icon.borderLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
	icon.borderLeft:SetVertexColor(unpack(borderColor))
	icon.borderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
	icon.borderLeft:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
	icon.borderLeft:SetWidth(1)
	icon.borderRight = icon.overlay:CreateTexture(nil, "OVERLAY")
	icon.borderRight:SetTexture("Interface\\Buttons\\WHITE8X8")
	icon.borderRight:SetVertexColor(unpack(borderColor))
	icon.borderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
	icon.borderRight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
	icon.borderRight:SetWidth(1)
	icon.stacks = icon.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	icon.stacks:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
	icon.stacks:SetTextColor(1, 1, 1, 1)
	icon.stacks:SetShadowColor(0, 0, 0, 1)
	icon.stacks:SetShadowOffset(1, -1)
	local stackFont, stackHeight = icon.stacks:GetFont()
	if stackFont and stackHeight then icon.stacks:SetFont(stackFont, stackHeight, "OUTLINE") end
	icon.duration = icon.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	icon.duration:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1)
	icon.duration:SetTextColor(1, 1, 1, 1)
	icon.duration:SetShadowColor(0, 0, 0, 1)
	icon.duration:SetShadowOffset(1, -1)
	local durationFont, durationHeight = icon.duration:GetFont()
	if durationFont and durationHeight then
		icon.duration:SetFont(durationFont, durationHeight * 0.8, "OUTLINE")
	end
	return icon
end

local function FindBossGuardianUnit(frame, name)
	local candidates = name and bossGuardianUnitsByName[name]
	if not candidates or table.getn(candidates) == 0 then return nil end
	local bar = frame.arcanePlatesSourceBar
	local currentHealthRatio
	if bar and bar.GetValue and bar.GetMinMaxValues then
		local value = bar:GetValue()
		local minimum, maximum = bar:GetMinMaxValues()
		if value and minimum and maximum and maximum > minimum then
			currentHealthRatio = (value - minimum) / (maximum - minimum)
		end
	end
	if not currentHealthRatio then return candidates[1] end
	local best, bestDifference
	for i = 1, table.getn(candidates) do
		local candidate = candidates[i]
		if candidate.hpm and candidate.hpm > 0 and candidate.hp then
			local difference = math.abs(candidate.hp / candidate.hpm - currentHealthRatio)
			if not bestDifference or difference < bestDifference then
				best, bestDifference = candidate, difference
			end
		end
	end
	return best or candidates[1]
end

local function GetDebuffs(unitID, unit)
	if unit and type(unit.debuffs) == "table" then return unit.debuffs end
	if type(AZS_GetDebuffs) ~= "function" then return nil end
	local revision = AZS_DEBUFFS_UPDATED or 0
	local now = GetTime()
	local cached = debuffCache[unitID]
	if not cached or cached.revision ~= revision or now - cached.checkedAt >= 1 then
		local ok, value = pcall(AZS_GetDebuffs, unitID)
		cached = {
			revision = revision,
			checkedAt = now,
			debuffs = ok and type(value) == "table" and value or nil,
		}
		debuffCache[unitID] = cached
	end
	return cached.debuffs
end

local function UpdateBossGuardianDebuffs(frame)
	local name = frame.arcanePlatesPlateName
	local unit = FindBossGuardianUnit(frame, name)
	local unitID = unit and unit.id or nil
	if unitID ~= frame.arcanePlatesDebuffUnitID then
		frame.arcanePlatesDebuffUnitID = unitID
		frame.arcanePlatesDebuffSignature = nil
	end
	if not unitID then
		if frame.arcanePlatesDebuffRow then frame.arcanePlatesDebuffRow:Hide() end
		return
	end
	local debuffs = GetDebuffs(unitID, unit)
	if type(debuffs) ~= "table" then
		if frame.arcanePlatesDebuffRow then frame.arcanePlatesDebuffRow:Hide() end
		return
	end

	local row = frame.arcanePlatesDebuffRow
	if not row then
		row = CreateFrame("Frame", nil, frame)
		row:SetHeight(DEBUFF_ICON_SIZE)
		row:SetFrameLevel(frame:GetFrameLevel() + 5)
		frame.arcanePlatesDebuffRow = row
	end

	-- Build a dense signature even if the API ever returns a sparse debuff array.
	local signatureParts = {}
	local count = math.min(table.getn(debuffs), MAX_DEBUFF_ICONS)
	local iconIndex = 0
	for i = 1, count do
		local d = debuffs[i]
		if d then
			iconIndex = iconIndex + 1
			signatureParts[iconIndex] = tostring(d.icon or "") .. ":" .. tostring(d.stacks or 0)
				.. ":" .. tostring(d.permanent and 1 or 0) .. ":" .. tostring(d.ends or "")
		end
	end
	local signature = table.concat(signatureParts, "|")
	local changed = frame.arcanePlatesDebuffSignature ~= signature
	frame.arcanePlatesDebuffSignature = signature

	local icons = frame.arcanePlatesDebuffIcons
	if not icons then icons = {}; frame.arcanePlatesDebuffIcons = icons end
	local visibleIndex = 0
	local runTime
	local runTimeRead = false
	for i = 1, count do
		local debuff = debuffs[i]
		if debuff then
			visibleIndex = visibleIndex + 1
			local icon = icons[visibleIndex]
			if not icon then
				icon = CreateDebuffIcon(row, visibleIndex)
				icons[visibleIndex] = icon
				changed = true
			end
			if changed then
				local texture = debuff.icon
				if not texture or texture == "" then texture = "Interface\\Icons\\INV_Misc_QuestionMark" end
				icon.texture:SetTexture(texture)
				if debuff.stacks and debuff.stacks > 1 then icon.stacks:SetText(debuff.stacks)
				else icon.stacks:SetText("") end
			end
			local remaining = debuff.remaining
			if not remaining and debuff.ends and type(AZS_GetRunTime) == "function" then
				if not runTimeRead then
					local ok, value = pcall(AZS_GetRunTime)
					if ok then runTime = value end
					runTimeRead = true
				end
				if runTime and debuff.ends >= 0 then remaining = debuff.ends - runTime end
			end
			local durationText
			if debuff.permanent then durationText = "∞"
			elseif type(remaining) == "number" and remaining >= 0 then durationText = math.ceil(remaining)
			else durationText = "" end
			if icon.duration.arcaneText ~= durationText then
				icon.duration.arcaneText = durationText
				icon.duration:SetText(durationText)
			end
			if not icon:IsShown() then icon:Show() end
			if not icon.overlay:IsShown() then icon.overlay:Show() end
		end
	end
	for i = visibleIndex + 1, table.getn(icons) do
		if icons[i]:IsShown() then icons[i]:Hide() end
	end
	if visibleIndex == 0 then row:Hide(); return end
	local width = visibleIndex * DEBUFF_ICON_SIZE + (visibleIndex - 1) * DEBUFF_ICON_GAP
	if row:GetWidth() ~= width then row:SetWidth(width) end
	local bar = frame.arcanePlatesOverlay or frame.arcanePlatesBossGuardianBar
		or frame.arcanePlatesStyledVisual or frame
	local point, relativeTo, relativePoint, x, y = row:GetPoint()
	if point ~= "TOP" or relativeTo ~= bar or relativePoint ~= "BOTTOM" or x ~= 0 or y ~= -3 then
		row:ClearAllPoints()
		row:SetPoint("TOP", bar, "BOTTOM", 0, -3)
	end
	if not row:IsShown() then row:Show() end
end

local function HideDebuffs(frame)
	if frame.arcanePlatesDebuffRow and frame.arcanePlatesDebuffRow:IsShown() then
		frame.arcanePlatesDebuffRow:Hide()
	end
end

P.Special.ClearPlateFlags = ClearPlateFlags
P.Special.RefreshNames = RefreshBossGuardianNames
P.Special.IsBossOrGuardianPlate = IsBossOrGuardianPlate
P.Special.UpdateBossGuardianLabel = UpdateBossGuardianLabel
P.Special.ApplyBossGuardianLabelFont = ApplyBossGuardianLabelFont
P.Special.UpdateDebuffs = UpdateBossGuardianDebuffs
P.Special.HideDebuffs = HideDebuffs
