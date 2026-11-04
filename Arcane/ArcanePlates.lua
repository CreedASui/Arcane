-- Arcane Tiny Plates
-- Based on ArcanePlates by Valorless (MIT); see ATTRIBUTION.md and ArcanePlates-LICENSE.txt.
-- Adapted for Arcane's shared DB, menu, lifecycle and Lua 5.0 client.
local C = Arcane
local knownPlates = {}
local orderedPlates = {}
local active = true
local scanClock = 0
local SCAN_INTERVAL = 0.50
local OVERLAY_INTERVAL = 0.10
local DEBUFF_INTERVAL = 0.25
local overlayClock = 0
local debuffClock = 0
local refreshPending = true
local styleRevision = 0
local scanFrame
local ApplyBarOverride

local function Opt(key)
	if type(C.ArcanePlatesOption) == "function" then return C.ArcanePlatesOption(key) end
	return false
end
local BORDER = "Interface\\Tooltips\\Nameplate-Border";
local PLATE_SCALE = 0.5;
local HORIZONTAL_OFFSET = 10;
local VERTICAL_OFFSET = 14;
local bossGuardianNames = {};
local bossGuardianUnitsByName = {};
local lastSpecialPhase;
local lastSpecialUnitsUpdate;
local lastSpecialDebuffsUpdate;
local lastSpecialRefreshTime = 0;

local function AddBossGuardianNames(units, requireKind)
	if ( type(units) ~= "table" ) then return; end
	for i = 1, table.getn(units) do
		local unit = units[i];
		if ( unit.name and ( not requireKind or unit.kind == "final"
				or unit.kind == "boss" or unit.kind == "guardian" ) ) then
			bossGuardianNames[unit.name] = true;
			if ( unit.id ) then
				local candidates = bossGuardianUnitsByName[unit.name];
				if ( not candidates ) then
					candidates = {};
					bossGuardianUnitsByName[unit.name] = candidates;
				end
				local replaced = false;
				for j = 1, table.getn(candidates) do
					if ( candidates[j].id == unit.id ) then
						candidates[j] = unit;
						replaced = true;
						break;
					end
				end
				if ( not replaced ) then table.insert(candidates, unit); end
			end
		end
	end
end

local function ClearBossGuardianPlateFlags()
	for i = 1, table.getn(orderedPlates) do
		local frame = orderedPlates[i]
		frame.arcanePlatesBossGuardian = nil
		frame.arcanePlatesBossGuardianName = nil
		frame.arcanePlatesDebuffUnitID = nil
		frame.arcanePlatesDebuffSignature = nil
		if frame.arcanePlatesDebuffRow then frame.arcanePlatesDebuffRow:Hide() end
	end
end

local function RefreshBossGuardianNames(force)
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
		ClearBossGuardianPlateFlags()
	end
	local retryCache = phase ~= "ready" and GetTime() - lastSpecialRefreshTime >= 1
	if phase ~= "ready" and (force or retryCache or phase ~= lastSpecialPhase
			or unitsUpdate ~= lastSpecialUnitsUpdate
			or debuffsUpdate ~= lastSpecialDebuffsUpdate or newRun) then
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
local function NormalizeName(text)
	if ( not text ) then return nil; end
	text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "");
	text = string.gsub(text, "|r", "");
	text = string.gsub(text, "^%s+", "");
	text = string.gsub(text, "%s+$", "");
	if ( text == "" ) then return nil; end
	return text;
end

local function IsOwnObject(frame, object)
	return object == frame.arcanePlatesOverlay
		or object == frame.arcanePlatesDebuffRow
		or object == frame.arcanePlatesShrunkLabelHolder
end

-- Searches the plate and its descendants, because UI replacements such as SDUI
-- may move the name FontString into a child frame or blank the native one.
local function GetPlateName(frame, root)
	root = root or frame;
	local regions = { root:GetRegions() };
	for i = 1, table.getn(regions) do
		local region = regions[i];
		if ( region and region ~= frame.arcanePlatesBossGuardianLabel
				and region:GetObjectType() == "FontString" ) then
			local name = NormalizeName(region:GetText());
			-- Purely numeric text is a level indicator, not a name.
			if ( name and not string.find(name, "^%d+$") ) then
				frame.arcanePlatesNameRegion = region;
				return name;
			end
		end
	end
	local children = { root:GetChildren() };
	for i = 1, table.getn(children) do
		if ( not IsOwnObject(frame, children[i]) ) then
			local name = GetPlateName(frame, children[i]);
			if ( name ) then return name; end
		end
	end
	return nil;
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

local function SaveObjectState(object, states)
	local state = { object = object, shown = object:IsShown() }
	if object.GetAlpha then state.alpha = object:GetAlpha() end
	table.insert(states, state)
	local kind = object:GetObjectType()
	-- Regions (Texture/FontString) have visibility and alpha, but no child tree.
	if kind ~= "Texture" and kind ~= "FontString" then
		local regions = { object:GetRegions() }
		for i = 1, table.getn(regions) do SaveObjectState(regions[i], states) end
		local children = { object:GetChildren() }
		for i = 1, table.getn(children) do SaveObjectState(children[i], states) end
	end
end

local function CaptureNativeState(frame)
	if frame.arcanePlatesNativeCaptured then return end
	local previouslyStyled = frame.arcanePlatesStyledVisual or frame.arcanePlatesOverlay;
	local point, relativeTo, relativePoint, x, y = frame:GetPoint();
	frame.arcanePlatesNativeWidth = frame.arcanePlatesStackOriginalWidth or frame:GetWidth();
	frame.arcanePlatesNativeHeight = frame.arcanePlatesStackOriginalHeight or frame:GetHeight();
	frame.arcanePlatesNativeScale = frame.arcanePlatesStackOriginalScale
		or frame.arcanePlatesOriginalScale or frame:GetScale();
	frame.arcanePlatesNativePoint = frame.arcanePlatesStackPoint or point;
	frame.arcanePlatesNativeRelativeTo = frame.arcanePlatesStackRelativeTo or relativeTo;
	frame.arcanePlatesNativeRelativePoint = frame.arcanePlatesStackRelativePoint or relativePoint;
	frame.arcanePlatesNativeX = frame.arcanePlatesStackPoint and frame.arcanePlatesStackX or x;
	frame.arcanePlatesNativeY = frame.arcanePlatesStackPoint and frame.arcanePlatesStackY or y;
	local states = {};
	SaveObjectState(frame, states);
	-- A reload can leave our old custom visual attached while the native plate
	-- is already hidden; in that case restore all native children below.
	if not previouslyStyled then frame.arcanePlatesNativeState = states end
	frame.arcanePlatesNativeCaptured = true
end

local function RestoreNativeState(frame)
	-- Always reapply the captured native state: the boss-name path can hide name
	-- text after its first restore, and turning Tiny Plates off must undo that too.
	if frame.arcanePlatesOverlay then frame.arcanePlatesOverlay:Hide() end
	if frame.arcanePlatesNativeState then
		for i = 1, table.getn(frame.arcanePlatesNativeState) do
			local state = frame.arcanePlatesNativeState[i]
			local object = state.object
			if object ~= frame.arcanePlatesOverlay and object ~= frame.arcanePlatesDebuffRow
					and object ~= frame.arcanePlatesBossGuardianLabel
				and object ~= frame.arcanePlatesShrunkLabelHolder then
				if object.SetAlpha and state.alpha ~= nil then object:SetAlpha(state.alpha) end
				if state.shown then object:Show() else object:Hide() end
			end
		end
	else
		-- Recover plates left modified by an older ArcanePlates revision that did not
		-- store a native visibility snapshot.
		local regions = { frame:GetRegions() }
		for i = 1, table.getn(regions) do
			if regions[i]:GetObjectType() == "FontString" then regions[i]:SetAlpha(1) end
			regions[i]:Show()
		end
		local children = { frame:GetChildren() }
		for i = 1, table.getn(children) do
			if children[i] ~= frame.arcanePlatesOverlay then children[i]:Show() end
		end
	end
	if frame.arcanePlatesStyledVisual then
		local styled = frame.arcanePlatesStyledVisual
		if frame.arcanePlatesStyledOriginalScale then styled:SetScale(frame.arcanePlatesStyledOriginalScale) end
		styled:ClearAllPoints()
		styled:SetPoint(frame.arcanePlatesStyledPoint or "CENTER",
			frame.arcanePlatesStyledRelativeTo or frame,
			frame.arcanePlatesStyledRelativePoint or "CENTER",
			frame.arcanePlatesStyledX or 0, frame.arcanePlatesStyledY or 0)
	end
	if frame.arcanePlatesSourceBar then
		if frame.arcanePlatesSourceOriginalWidth then frame.arcanePlatesSourceBar:SetWidth(frame.arcanePlatesSourceOriginalWidth) end
		if frame.arcanePlatesSourceOriginalHeight then frame.arcanePlatesSourceBar:SetHeight(frame.arcanePlatesSourceOriginalHeight) end
	end
	for bar in pairs(frame.arcanePlatesColoredBars or {}) do ApplyBarOverride(bar, nil) end
	if frame.arcanePlatesNativeWidth then frame:SetWidth(frame.arcanePlatesNativeWidth) end
	if frame.arcanePlatesNativeHeight then frame:SetHeight(frame.arcanePlatesNativeHeight) end
	if frame.arcanePlatesNativeScale then frame:SetScale(frame.arcanePlatesNativeScale) end
	if frame.arcanePlatesNativePoint then
		frame:ClearAllPoints()
		frame:SetPoint(frame.arcanePlatesNativePoint,
			frame.arcanePlatesNativeRelativeTo or frame:GetParent(),
			frame.arcanePlatesNativeRelativePoint or frame.arcanePlatesNativePoint,
			frame.arcanePlatesNativeX or 0, frame.arcanePlatesNativeY or 0)
	end
	if frame.arcanePlatesBossGuardianLabel then frame.arcanePlatesBossGuardianLabel:Hide() end
	if frame.arcanePlatesShrunkLabelHolder then frame.arcanePlatesShrunkLabelHolder:Hide() end
	if frame.arcanePlatesDebuffRow then frame.arcanePlatesDebuffRow:Hide() end
	frame.arcanePlatesNativeRestored = true
end

local function HasStatusBar(frame)
	local children = { frame:GetChildren() }
	for i = 1, table.getn(children) do
		local child = children[i]
		if child:GetObjectType() == "StatusBar" or HasStatusBar(child) then return true end
	end
	return false
end

local function IdentifyNameplate(frame)
	local regions = { frame:GetRegions() }
	local hasBorder = false
	for i = 1, table.getn(regions) do
		local region = regions[i]
		if region and region:GetObjectType() == "Texture"
				and region:GetTexture() == BORDER then
			hasBorder = true
			break
		end
	end
	local hasName = GetPlateName(frame) ~= nil
	return hasName and (hasBorder or HasStatusBar(frame))
end

local function HideNameText(frame)
	local regions = { frame:GetRegions() };
	for i = 1, table.getn(regions) do
		local region = regions[i];
		if ( region and region ~= frame.arcanePlatesBossGuardianLabel
				and region:GetObjectType() == "FontString" ) then
			region:SetAlpha(0);
			region:Hide();
		end
	end
end

local function HideMatchingNameText(frame, name, keep)
	if ( not name or name == "" or frame == keep ) then return; end
	local regions = { frame:GetRegions() };
	for i = 1, table.getn(regions) do
		local region = regions[i];
		if ( region and region ~= keep and region:GetObjectType() == "FontString"
				and region:GetText() == name ) then
			region:SetAlpha(0);
			region:Hide();
		end
	end
	local children = { frame:GetChildren() };
	for i = 1, table.getn(children) do
		HideMatchingNameText(children[i], name, keep);
	end
end

local function ShowNameText(frame)
	if ( frame.arcanePlatesNameRegion and frame.arcanePlatesPlateName ) then
		local text = frame.arcanePlatesNameRegion:GetText();
		if ( not text or text == "" ) then
			frame.arcanePlatesNameRegion:SetText(frame.arcanePlatesPlateName);
		end
	end
	local regions = { frame:GetRegions() };
	for i = 1, table.getn(regions) do
		local region = regions[i];
		if ( region and region:GetObjectType() == "FontString" ) then
			local text = region:GetText();
			if ( ( not text or text == "" ) and frame.arcanePlatesPlateName ) then
				region:SetText(frame.arcanePlatesPlateName);
			end
			region:SetAlpha(1);
			region:Show();
		end
	end
end

local function UpdateBossGuardianLabel(frame)
	local name = frame.arcanePlatesPlateName;
	if ( not name or name == "" ) then
		if ( frame.arcanePlatesBossGuardianLabel ) then frame.arcanePlatesBossGuardianLabel:Hide(); end
		return;
	end
	local label = frame.arcanePlatesBossGuardianLabel;
	if ( not label ) then
		label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		label:SetWidth(180);
		label:SetHeight(14);
		label:SetJustifyH("CENTER");
		label:SetTextColor(1, 0.82, 0.15, 1);
		frame.arcanePlatesBossGuardianLabel = label;
	end
	local bar = frame.arcanePlatesSourceBar;
	if ( not bar ) then
		local children = { frame:GetChildren() };
		for i = 1, table.getn(children) do
			if ( children[i]:GetObjectType() == "StatusBar" ) then
				bar = children[i];
				break;
			end
		end
	end
	frame.arcanePlatesBossGuardianBar = bar;
	label:ClearAllPoints();
	if ( bar ) then
		label:SetPoint("BOTTOM", bar, "TOP", 0, 2);
	else
		label:SetPoint("BOTTOM", frame, "TOP", 0, 2);
	end
	label:SetText(name);
	label:SetAlpha(1);
	label:Show();
end

local function HideFontStrings(frame)
	local regions = { frame:GetRegions() };
	for i = 1, table.getn(regions) do
		local region = regions[i];
		if ( region and region:GetObjectType() == "FontString" ) then
			region:SetAlpha(0);
			region:Hide();
		end
	end
	local children = { frame:GetChildren() };
	for i = 1, table.getn(children) do HideFontStrings(children[i]); end
end

local function ContainsStatusBar(frame)
	local children = { frame:GetChildren() };
	for i = 1, table.getn(children) do
		if ( children[i]:GetObjectType() == "StatusBar" or ContainsStatusBar(children[i]) ) then
			return true;
		end
	end
	return false;
end

local function FindStyledVisual(frame, source)
	local children = { frame:GetChildren() };
	for i = 1, table.getn(children) do
		local child = children[i];
		local width, height = child:GetWidth(), child:GetHeight();
		if ( child ~= source and child ~= frame.arcanePlatesOverlay
				and child:GetObjectType() ~= "StatusBar"
				and width and height and width >= 30 and width <= 200
				and height >= 5 and height <= 60 and ContainsStatusBar(child) ) then
			return child;
		end
	end
	return nil;
end

local function FindNameFontString(frame, name)
	local fallback;
	local regions = { frame:GetRegions() };
	for i = 1, table.getn(regions) do
		local region = regions[i];
		if ( region and region:GetObjectType() == "FontString" ) then
			local text = region:GetText();
			if ( text == name ) then return region; end
			if ( not fallback and text and text ~= "" ) then fallback = region; end
		end
	end
	local children = { frame:GetChildren() };
	for i = 1, table.getn(children) do
		local found = FindNameFontString(children[i], name);
		if ( found and found:GetText() == name ) then return found; end
		if ( not fallback and found ) then fallback = found; end
	end
	return fallback;
end

local function ApplyBossGuardianLabelFont(frame)
	local label = frame.arcanePlatesBossGuardianLabel;
	local name = frame.arcanePlatesPlateName;
	local source;
	local visual = frame.arcanePlatesBossGuardianStyleVisual;
	if ( not visual ) then
		local sourceBar = frame.arcanePlatesSourceBar;
		if ( not sourceBar ) then
			local children = { frame:GetChildren() };
			for i = 1, table.getn(children) do
				if ( children[i]:GetObjectType() == "StatusBar" ) then
					sourceBar = children[i];
					break;
				end
			end
		end
		visual = FindStyledVisual(frame, sourceBar);
		frame.arcanePlatesBossGuardianStyleVisual = visual;
	end
	if ( visual ) then source = FindNameFontString(visual, name); end
	if ( not source ) then source = frame.arcanePlatesNameRegion; end
	if ( not source or not source.GetFont ) then return; end
	local font, height, flags = source:GetFont();
	if ( font and height ) then label:SetFont(font, height, flags); end
	if ( source.GetTextColor ) then
		local r, g, b, a = source:GetTextColor();
		if ( a ) then label:SetTextColor(r, g, b, a);
		else label:SetTextColor(r, g, b); end
	end
	if ( source.GetShadowColor and label.SetShadowColor ) then
		local r, g, b, a = source:GetShadowColor();
		if ( a ) then label:SetShadowColor(r, g, b, a);
		else label:SetShadowColor(r, g, b); end
	end
	if ( source.GetShadowOffset and label.SetShadowOffset ) then
		local x, y = source:GetShadowOffset();
		if ( x and y ) then label:SetShadowOffset(x, y); end
	end
	if ( source.GetJustifyH and label.SetJustifyH ) then label:SetJustifyH(source:GetJustifyH()); end
	if ( source.GetJustifyV and label.SetJustifyV ) then label:SetJustifyV(source:GetJustifyV()); end
end

local DEBUFF_ICON_SIZE = 16;
local DEBUFF_ICON_GAP = 2;
local MAX_DEBUFF_ICONS = 10;

local function CreateDebuffIcon(row, index)
	local icon = CreateFrame("Frame", nil, row);
	icon:SetWidth(DEBUFF_ICON_SIZE);
	icon:SetHeight(DEBUFF_ICON_SIZE);
	icon:SetPoint("LEFT", row, "LEFT", (index - 1) * (DEBUFF_ICON_SIZE + DEBUFF_ICON_GAP), 0);
	icon.texture = icon:CreateTexture(nil, "ARTWORK");
	icon.texture:SetAllPoints(icon);
	icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93);
	icon.overlay = CreateFrame("Frame", nil, icon);
	icon.overlay:SetAllPoints(icon);
	icon.overlay:SetFrameLevel(icon:GetFrameLevel() + 1);
	local borderColor = { 0.05, 0.05, 0.05, 1 };
	icon.borderTop = icon.overlay:CreateTexture(nil, "OVERLAY");
	icon.borderTop:SetTexture("Interface\\Buttons\\WHITE8X8");
	icon.borderTop:SetVertexColor(unpack(borderColor));
	icon.borderTop:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0);
	icon.borderTop:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0);
	icon.borderTop:SetHeight(1);
	icon.borderBottom = icon.overlay:CreateTexture(nil, "OVERLAY");
	icon.borderBottom:SetTexture("Interface\\Buttons\\WHITE8X8");
	icon.borderBottom:SetVertexColor(unpack(borderColor));
	icon.borderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0);
	icon.borderBottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0);
	icon.borderBottom:SetHeight(1);
	icon.borderLeft = icon.overlay:CreateTexture(nil, "OVERLAY");
	icon.borderLeft:SetTexture("Interface\\Buttons\\WHITE8X8");
	icon.borderLeft:SetVertexColor(unpack(borderColor));
	icon.borderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0);
	icon.borderLeft:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0);
	icon.borderLeft:SetWidth(1);
	icon.borderRight = icon.overlay:CreateTexture(nil, "OVERLAY");
	icon.borderRight:SetTexture("Interface\\Buttons\\WHITE8X8");
	icon.borderRight:SetVertexColor(unpack(borderColor));
	icon.borderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0);
	icon.borderRight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0);
	icon.borderRight:SetWidth(1);
	icon.stacks = icon.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	icon.stacks:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1);
	icon.stacks:SetTextColor(1, 1, 1, 1);
	icon.stacks:SetShadowColor(0, 0, 0, 1);
	icon.stacks:SetShadowOffset(1, -1);
	local stackFont, stackHeight = icon.stacks:GetFont();
	if ( stackFont and stackHeight ) then icon.stacks:SetFont(stackFont, stackHeight, "OUTLINE"); end
	icon.duration = icon.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	icon.duration:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1);
	icon.duration:SetTextColor(1, 1, 1, 1);
	icon.duration:SetShadowColor(0, 0, 0, 1);
	icon.duration:SetShadowOffset(1, -1);
	local durationFont, durationHeight = icon.duration:GetFont();
	if ( durationFont and durationHeight ) then
		icon.duration:SetFont(durationFont, durationHeight * 0.8, "OUTLINE");
	end
	return icon;
end

local function FindBossGuardianUnit(frame, name)
	local candidates = name and bossGuardianUnitsByName[name];
	if ( not candidates or table.getn(candidates) == 0 ) then return nil; end
	local bar = frame.arcanePlatesBossGuardianBar;
	local currentHealthRatio;
	if ( bar ) then
		local value = bar:GetValue();
		local minimum, maximum = bar:GetMinMaxValues();
		if ( value and minimum and maximum and maximum > minimum ) then
			currentHealthRatio = (value - minimum) / (maximum - minimum);
		end
	end
	if ( not currentHealthRatio ) then return candidates[1]; end
	local best, bestDifference;
	for i = 1, table.getn(candidates) do
		local candidate = candidates[i];
		if ( candidate.hpm and candidate.hpm > 0 and candidate.hp ) then
			local difference = math.abs(candidate.hp / candidate.hpm - currentHealthRatio);
			if ( not bestDifference or difference < bestDifference ) then
				best, bestDifference = candidate, difference;
			end
		end
	end
	return best or candidates[1];
end

local function UpdateBossGuardianDebuffs(frame)
	local name = frame.arcanePlatesPlateName
	local unit = FindBossGuardianUnit(frame, name)
	local row = frame.arcanePlatesDebuffRow
	if not row then
		row = CreateFrame("Frame", nil, frame)
		row:SetHeight(DEBUFF_ICON_SIZE)
		row:SetFrameLevel(frame:GetFrameLevel() + 5)
		frame.arcanePlatesDebuffRow = row
	end
	if unit and unit.id then frame.arcanePlatesDebuffUnitID = unit.id end
	local unitID = frame.arcanePlatesDebuffUnitID
	if not unitID then row:Hide(); return end
	-- Prefer the already cached boss/guardian unit snapshot to avoid an extra
	-- API call on every plate update. Query by ID only when the snapshot has no data.
	local debuffs = unit and unit.debuffs
	if type(debuffs) ~= "table" and type(AZS_GetDebuffs) == "function" then
		local ok, value = pcall(AZS_GetDebuffs, unitID)
		if ok and type(value) == "table" then debuffs = value end
	end
	if type(debuffs) ~= "table" then
		row:Hide()
		return
	end

	-- Debuff structure only changes when the game's revision changes. Reuse icons and
	-- skip texture/stack writes until the actual content changes; durations tick separately.
	local signatureParts = {}
	local count = math.min(table.getn(debuffs), MAX_DEBUFF_ICONS)
	for i = 1, count do
		local d = debuffs[i]
		if d then
			signatureParts[i] = tostring(d.icon or "") .. ":" .. tostring(d.stacks or 0)
				.. ":" .. tostring(d.permanent and 1 or 0) .. ":" .. tostring(d.ends or "")
		end
	end
	local signature = table.concat(signatureParts, "|")
	local changed = frame.arcanePlatesDebuffSignature ~= signature
	frame.arcanePlatesDebuffSignature = signature
	local iconIndex = 0
	for i = 1, count do
		local debuff = debuffs[i]
		if debuff then
			iconIndex = iconIndex + 1
			local icons = frame.arcanePlatesDebuffIcons
			if not icons then icons = {}; frame.arcanePlatesDebuffIcons = icons end
			local icon = icons[iconIndex]
			if not icon then
				icon = CreateDebuffIcon(row, iconIndex)
				icons[iconIndex] = icon
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
				local ok, runTime = pcall(AZS_GetRunTime)
				if ok and runTime and debuff.ends >= 0 then remaining = debuff.ends - runTime end
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
	local icons = frame.arcanePlatesDebuffIcons or {}
	for i = iconIndex + 1, table.getn(icons) do if icons[i]:IsShown() then icons[i]:Hide() end end
	if iconIndex == 0 then row:Hide(); return end
	local width = iconIndex * DEBUFF_ICON_SIZE + (iconIndex - 1) * DEBUFF_ICON_GAP
	if row:GetWidth() ~= width then row:SetWidth(width) end
	local bar = frame.arcanePlatesStyledVisual or frame.arcanePlatesBossGuardianBar or frame.arcanePlatesOverlay or frame
	local point, relativeTo, relativePoint, x, y = row:GetPoint()
	if point ~= "TOP" or relativeTo ~= bar or relativePoint ~= "BOTTOM" or x ~= 0 or y ~= -3 then
		row:ClearAllPoints()
		row:SetPoint("TOP", bar, "BOTTOM", 0, -3)
	end
	if not row:IsShown() then row:Show() end
end
local function EnsureOverlayBorder(frame, overlay)
	if ( frame.arcanePlatesOverlayBorder ) then return; end
	local border = CreateFrame("Frame", nil, overlay);
	border:SetPoint("TOPLEFT", overlay, "TOPLEFT", -3, 3);
	border:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 3, -3);
	border:SetFrameLevel(overlay:GetFrameLevel() + 1);
	border:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 7.5,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	});
	border:SetBackdropBorderColor(1, 1, 1, 1);
	frame.arcanePlatesOverlayBorder = border;
end

local function HideNativePlate(frame, keep)
	local regions = { frame:GetRegions() };
	for i = 1, table.getn(regions) do
		local region = regions[i];
		if ( region and region:GetObjectType() == "Texture" ) then region:Hide(); end
	end
	local children = { frame:GetChildren() };
	for i = 1, table.getn(children) do
		if ( children[i] ~= keep and children[i] ~= frame.arcanePlatesOverlay
				and children[i] ~= frame.arcanePlatesShrunkLabelHolder ) then
			children[i]:Hide();
		end
	end
end

local function IsPlaceholderShrunk(frame)
	local visual = frame.arcanePlatesStyledVisual;
	if ( visual and visual:IsShown() and frame.arcanePlatesStyledOriginalScale ) then
		return visual:GetScale() < frame.arcanePlatesStyledOriginalScale * 0.99;
	end
	local overlay = frame.arcanePlatesOverlay;
	if ( overlay and overlay:IsShown() and frame.arcanePlatesOverlayBaseWidth ) then
		return overlay:GetWidth() < frame.arcanePlatesOverlayBaseWidth * 0.99;
	end
	local source = frame.arcanePlatesSourceBar;
	if ( source and source:IsShown() and frame.arcanePlatesSourceOriginalWidth ) then
		return source:GetWidth() < frame.arcanePlatesSourceOriginalWidth * 0.99;
	end
	return false;
end

local function HideShrunkNameLabel(frame)
	if ( frame.arcanePlatesShrunkLabelHolder ) then frame.arcanePlatesShrunkLabelHolder:Hide(); end
end

-- Name above a shrunken plate; lives on its own child frame so the native-child hiding does not remove it.
local function UpdateShrunkNameLabel(frame)
	local name = frame.arcanePlatesPlateName;
	if ( not Opt("showShrunkName") or frame.arcanePlatesBossGuardian
			or not name or name == "" ) then
		HideShrunkNameLabel(frame);
		return;
	end
	local holder = frame.arcanePlatesShrunkLabelHolder;
	if ( not holder ) then
		holder = CreateFrame("Frame", nil, frame);
		holder:SetAllPoints(frame);
		holder:SetFrameLevel(frame:GetFrameLevel() + 10);
		local text = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		text:SetWidth(140);
		text:SetHeight(12);
		text:SetJustifyH("CENTER");
		text:SetTextColor(1, 1, 1, 1);
		holder.text = text;
		frame.arcanePlatesShrunkLabelHolder = holder;
	end
	local anchor = frame.arcanePlatesStyledVisual or frame.arcanePlatesOverlay
		or frame.arcanePlatesSourceBar or frame;
	holder.text:ClearAllPoints();
	holder.text:SetPoint("BOTTOM", anchor, "TOP", 0, 2);
	holder.text:SetText(name);
	holder.text:SetAlpha(1);
	holder:Show();
end

local function UpdateNamePlaceholder(frame)
	local label = frame.arcanePlatesBossGuardianLabel;
	if ( IsPlaceholderShrunk(frame) ) then
		if ( label ) then label:Hide(); end
		UpdateShrunkNameLabel(frame);
		return;
	end
	HideShrunkNameLabel(frame);
	if ( frame.arcanePlatesBossGuardian and Opt("hideBossName") ) then
		if ( label ) then label:Hide(); end
		local visual = frame.arcanePlatesStyledVisual;
		local native = visual and FindNameFontString(visual, frame.arcanePlatesPlateName);
		if ( native ) then native:SetAlpha(0); native:Hide(); end
		HideMatchingNameText(frame, frame.arcanePlatesPlateName, nil);
		return;
	end
	local visual = frame.arcanePlatesStyledVisual;
	local native = visual and FindNameFontString(visual, frame.arcanePlatesPlateName);
	if ( native and NormalizeName(native:GetText()) == frame.arcanePlatesPlateName ) then
		-- Let the replacement UI draw its own name where it expects it; our label
		-- sits behind its child frames and was not visible.
		native:SetAlpha(1);
		native:Show();
		if ( native:IsVisible() ) then
			if ( label ) then label:Hide(); end
			return;
		end
	end
	UpdateBossGuardianLabel(frame);
	ApplyBossGuardianLabelFont(frame);
	HideMatchingNameText(frame, frame.arcanePlatesPlateName,
		frame.arcanePlatesBossGuardianLabel);
end

-- Custom bar colors. The color the game/SDUI last set is remembered per bar so it can be restored
-- when the override is turned off or a recycled plate changes category.
local function BarColor(category)
	if type(C.ArcanePlatesBarColor) == "function" then return C.ArcanePlatesBarColor(category) end
	return nil
end

local function ColorsDiffer(r1, g1, b1, r2, g2, b2)
	return math.abs((r1 or 0) - r2) > 0.01 or math.abs((g1 or 0) - g2) > 0.01
		or math.abs((b1 or 0) - b2) > 0.01;
end

ApplyBarOverride = function(bar, color)
	if not bar or not bar.SetStatusBarColor then return end
	if color then
		local r, g, b, a = bar:GetStatusBarColor()
		local applied = bar.arcanePlatesAppliedColor
		if not applied or ColorsDiffer(r, g, b, applied[1], applied[2], applied[3]) then
			bar.arcanePlatesOriginalColor = { r or 1, g or 1, b or 1, a }
		end
		if ColorsDiffer(r, g, b, color[1], color[2], color[3]) then
			if a ~= nil then bar:SetStatusBarColor(color[1], color[2], color[3], a)
			else bar:SetStatusBarColor(color[1], color[2], color[3]) end
		end
		bar.arcanePlatesAppliedColor = { color[1], color[2], color[3] }
	else
		local original = bar.arcanePlatesOriginalColor
		if bar.arcanePlatesAppliedColor and original then
			if original[4] ~= nil then
				bar:SetStatusBarColor(original[1], original[2], original[3], original[4])
			else
				bar:SetStatusBarColor(original[1], original[2], original[3])
			end
		end
		bar.arcanePlatesAppliedColor = nil
		bar.arcanePlatesOriginalColor = nil
	end
end
local function CollectStatusBars(frame, list)
	local children = { frame:GetChildren() };
	for i = 1, table.getn(children) do
		if ( children[i]:GetObjectType() == "StatusBar" ) then table.insert(list, children[i]); end
		CollectStatusBars(children[i], list);
	end
	return list;
end

-- Covers SDUI's styled visual and the native health bar; our overlay copies the native bar.
local function ApplyPlateBarColor(frame, color)
	local bars = frame.arcanePlatesColorBars
	if not bars then
		bars = {}
		local styled = frame.arcanePlatesStyledVisual
		if styled then CollectStatusBars(styled, bars) end
		local source = frame.arcanePlatesSourceBar
		if not source then
			local children = { frame:GetChildren() }
			for i = 1, table.getn(children) do
				if children[i]:GetObjectType() == "StatusBar" then source = children[i]; break end
			end
		end
		if source then table.insert(bars, source) end
		frame.arcanePlatesColorBars = bars
	end
	frame.arcanePlatesColoredBars = frame.arcanePlatesColoredBars or {}
	for i = 1, table.getn(bars) do
		local bar = bars[i]
		ApplyBarOverride(bar, color)
		if color then frame.arcanePlatesColoredBars[bar] = true else frame.arcanePlatesColoredBars[bar] = nil end
	end
end

local function HideShrunkPlate(frame)
	if ( frame.arcanePlatesBossGuardianLabel ) then frame.arcanePlatesBossGuardianLabel:Hide(); end
	HideShrunkNameLabel(frame);
	HideNameText(frame);
	if ( frame.arcanePlatesStyledVisual ) then frame.arcanePlatesStyledVisual:Hide(); end
	if ( frame.arcanePlatesOverlay ) then frame.arcanePlatesOverlay:Hide(); end
	HideNativePlate(frame, nil);
end

local function ApplyPlateStyle(frame)
	if ( IsBossOrGuardianPlate(frame) ) then
		RestoreNativeState(frame);
		ApplyPlateBarColor(frame, BarColor("boss"));
		HideNameText(frame);
		UpdateNamePlaceholder(frame);
		if ( Opt("showDebuffs") ) then
			UpdateBossGuardianDebuffs(frame);
		elseif ( frame.arcanePlatesDebuffRow ) then
			frame.arcanePlatesDebuffRow:Hide();
		end
		return;
	end
	if ( frame.arcanePlatesBossGuardianLabel ) then frame.arcanePlatesBossGuardianLabel:Hide(); end
	if ( frame.arcanePlatesDebuffRow ) then frame.arcanePlatesDebuffRow:Hide(); end
	frame.arcanePlatesNativeRestored = nil;
	if ( Opt("hideShrunkPlates") ) then
		HideShrunkPlate(frame);
		return;
	end
	local visualScale = PLATE_SCALE;
	ApplyPlateBarColor(frame, BarColor("regular"));
	HideNameText(frame);
	local styled = frame.arcanePlatesStyledVisual;
	if ( styled ) then
		styled:Show();
		HideFontStrings(styled);
		local scale = frame.arcanePlatesStyledOriginalScale * visualScale;
		if ( styled:GetScale() ~= scale ) then styled:SetScale(scale); end
		local point, relativeTo, relativePoint, x, y = styled:GetPoint();
		local offsetX, offsetY = HORIZONTAL_OFFSET, VERTICAL_OFFSET;
		if ( visualScale == 1 ) then offsetX, offsetY = 0, 0; end
		local targetX = frame.arcanePlatesStyledX + offsetX;
		local targetY = frame.arcanePlatesStyledY + offsetY;
		if ( point ~= frame.arcanePlatesStyledPoint
				or relativeTo ~= frame.arcanePlatesStyledRelativeTo
				or relativePoint ~= frame.arcanePlatesStyledRelativePoint
				or x ~= targetX or y ~= targetY ) then
			styled:ClearAllPoints();
			styled:SetPoint(frame.arcanePlatesStyledPoint, frame.arcanePlatesStyledRelativeTo,
				frame.arcanePlatesStyledRelativePoint, targetX, targetY);
		end
		if ( frame.arcanePlatesOverlay ) then frame.arcanePlatesOverlay:Hide(); end
		HideNativePlate(frame, styled);
		UpdateNamePlaceholder(frame);
		return;
	end
	local source = frame.arcanePlatesSourceBar;
	local overlay = frame.arcanePlatesOverlay;
	if ( not source or not overlay ) then
		return;
	end
	local originalOverlayScale = frame.arcanePlatesOverlayOriginalScale or overlay:GetScale();
	frame.arcanePlatesOverlayOriginalScale = originalOverlayScale;
	local overlayScale = originalOverlayScale;
	if ( overlay:GetScale() ~= overlayScale ) then overlay:SetScale(overlayScale); end
	EnsureOverlayBorder(frame, overlay);
	if ( not overlay:IsShown() ) then overlay:Show(); end
	if ( not frame.arcanePlatesOverlayBaseWidth ) then
		frame.arcanePlatesOverlayBaseWidth = frame.arcanePlatesSourceOriginalWidth
			or frame.arcanePlatesOverlayWidth / PLATE_SCALE;
		frame.arcanePlatesOverlayBaseHeight = frame.arcanePlatesSourceOriginalHeight
			or frame.arcanePlatesOverlayHeight / PLATE_SCALE;
		local baseX, baseY = frame.arcanePlatesOverlayX, frame.arcanePlatesOverlayY;
		if ( string.find(frame.arcanePlatesOverlayPoint, "LEFT") ) then
			baseX = baseX - frame.arcanePlatesOverlayWidth / 2;
		end
		if ( string.find(frame.arcanePlatesOverlayPoint, "BOTTOM") ) then
			baseY = baseY - frame.arcanePlatesOverlayHeight / 2;
		end
		frame.arcanePlatesOverlayBaseX = baseX;
		frame.arcanePlatesOverlayBaseY = baseY;
	end
	local width = frame.arcanePlatesOverlayBaseWidth * visualScale;
	local height = frame.arcanePlatesOverlayBaseHeight * visualScale;
	local baseX, baseY = frame.arcanePlatesOverlayBaseX, frame.arcanePlatesOverlayBaseY;
	if ( string.find(frame.arcanePlatesOverlayPoint, "LEFT") ) then baseX = baseX + width / 2; end
	if ( string.find(frame.arcanePlatesOverlayPoint, "BOTTOM") ) then baseY = baseY + height / 2; end
	local offsetX, offsetY = HORIZONTAL_OFFSET, VERTICAL_OFFSET;
	if ( visualScale == 1 ) then offsetX, offsetY = 0, 0; end
	local x = baseX + offsetX;
	local y = baseY + offsetY;
	local point, relativeTo, relativePoint, currentX, currentY = overlay:GetPoint();
	if ( overlay:GetWidth() ~= width or overlay:GetHeight() ~= height ) then
		overlay:SetWidth(width);
		overlay:SetHeight(height);
	end
	if ( point ~= frame.arcanePlatesOverlayPoint or relativeTo ~= frame.arcanePlatesOverlayRelativeTo
			or relativePoint ~= frame.arcanePlatesOverlayRelativePoint
			or currentX ~= x or currentY ~= y ) then
		overlay:ClearAllPoints();
		overlay:SetPoint(frame.arcanePlatesOverlayPoint, frame.arcanePlatesOverlayRelativeTo,
			frame.arcanePlatesOverlayRelativePoint, x, y);
	end
	local minValue, maxValue = source:GetMinMaxValues();
	overlay:SetMinMaxValues(minValue, maxValue);
	overlay:SetValue(source:GetValue());
	if ( source.GetStatusBarTexture ) then
		local statusTexture = source:GetStatusBarTexture();
		local texturePath;
		if ( type(statusTexture) == "string" ) then
			texturePath = statusTexture;
		elseif ( statusTexture and statusTexture.GetTexture ) then
			texturePath = statusTexture:GetTexture();
		end
		if ( texturePath and texturePath ~= ""
				and frame.arcanePlatesOverlayTexture ~= texturePath ) then
			overlay:SetStatusBarTexture(texturePath);
			frame.arcanePlatesOverlayTexture = texturePath;
		end
	end
	local r, g, b, a = source:GetStatusBarColor();
	if ( a ) then
		overlay:SetStatusBarColor(r, g, b, a);
	else
		overlay:SetStatusBarColor(r, g, b);
	end
	local regions = { frame:GetRegions() };
	for i = 1, table.getn(regions) do
		local region = regions[i];
		if ( region and region:GetObjectType() == "Texture" ) then region:Hide(); end
	end
	local children = { frame:GetChildren() };
	for i = 1, table.getn(children) do
		local child = children[i];
		if ( child ~= overlay and child ~= frame.arcanePlatesShrunkLabelHolder ) then child:Hide(); end
	end
	UpdateNamePlaceholder(frame);
end

local function CreatePlateOverlay(frame)
	if ( not frame.arcanePlatesStackOriginalWidth ) then
		frame.arcanePlatesStackOriginalWidth = frame:GetWidth();
	end
	if ( not frame.arcanePlatesStackOriginalHeight ) then
		frame.arcanePlatesStackOriginalHeight = frame:GetHeight();
	end
	if ( not frame.arcanePlatesStackOriginalScale ) then
		frame.arcanePlatesStackOriginalScale = frame.arcanePlatesOriginalScale or frame:GetScale();
	end
	if ( frame:GetWidth() ~= frame.arcanePlatesStackOriginalWidth ) then
		frame:SetWidth(frame.arcanePlatesStackOriginalWidth);
	end
	if ( frame:GetHeight() ~= frame.arcanePlatesStackOriginalHeight ) then
		frame:SetHeight(frame.arcanePlatesStackOriginalHeight);
	end
	if ( frame.arcanePlatesStackPoint ) then
		frame:ClearAllPoints();
		frame:SetPoint(frame.arcanePlatesStackPoint,
			frame.arcanePlatesStackRelativeTo or frame:GetParent(),
			frame.arcanePlatesStackRelativePoint,
			frame.arcanePlatesStackX, frame.arcanePlatesStackY);
		frame.arcanePlatesStackPoint = nil;
		frame.arcanePlatesStackRelativeTo = nil;
		frame.arcanePlatesStackRelativePoint = nil;
		frame.arcanePlatesStackX = nil;
		frame.arcanePlatesStackY = nil;
	end
	if ( frame.arcanePlatesStackNativePoint ) then
		frame:ClearAllPoints();
		frame:SetPoint(frame.arcanePlatesStackNativePoint,
			frame.arcanePlatesStackNativeRelativeTo or frame:GetParent(),
			frame.arcanePlatesStackNativeRelativePoint,
			frame.arcanePlatesStackNativeX, frame.arcanePlatesStackNativeY);
		frame.arcanePlatesStackNativePoint = nil;
		frame.arcanePlatesStackNativeRelativeTo = nil;
		frame.arcanePlatesStackNativeRelativePoint = nil;
		frame.arcanePlatesStackNativeX = nil;
		frame.arcanePlatesStackNativeY = nil;
	end
	frame.arcanePlatesStackScaleApplied = nil;
	frame.arcanePlatesStackCorrectionPending = nil;
	frame.arcanePlatesVisualCorrectionX = nil;
	frame.arcanePlatesVisualCorrectionY = nil;
	if ( frame:GetScale() ~= frame.arcanePlatesStackOriginalScale ) then
		frame:SetScale(frame.arcanePlatesStackOriginalScale);
	end
	if ( not frame.arcanePlatesSourceBar ) then
		local children = { frame:GetChildren() };
		for i = 1, table.getn(children) do
			if ( children[i]:GetObjectType() == "StatusBar" ) then
				frame.arcanePlatesSourceBar = children[i];
				frame.arcanePlatesSourceOriginalWidth = children[i]:GetWidth();
				frame.arcanePlatesSourceOriginalHeight = children[i]:GetHeight();
				break;
			end
		end
	end
	local sourceBar = frame.arcanePlatesSourceBar;
	if ( sourceBar ) then
		if ( not frame.arcanePlatesSourceOriginalWidth ) then
			frame.arcanePlatesSourceOriginalWidth = sourceBar:GetWidth();
		end
		if ( not frame.arcanePlatesSourceOriginalHeight ) then
			frame.arcanePlatesSourceOriginalHeight = sourceBar:GetHeight();
		end
		if ( sourceBar:GetWidth() ~= frame.arcanePlatesSourceOriginalWidth ) then
			sourceBar:SetWidth(frame.arcanePlatesSourceOriginalWidth);
		end
		if ( sourceBar:GetHeight() ~= frame.arcanePlatesSourceOriginalHeight ) then
			sourceBar:SetHeight(frame.arcanePlatesSourceOriginalHeight);
		end
	end
	if ( not frame.arcanePlatesStyledVisual ) then
		frame.arcanePlatesStyledVisual = FindStyledVisual(frame, frame.arcanePlatesSourceBar);
		if ( frame.arcanePlatesStyledVisual ) then
			local styled = frame.arcanePlatesStyledVisual;
			frame.arcanePlatesStyledOriginalScale = styled:GetScale();
			local point, relativeTo, relativePoint, x, y = styled:GetPoint();
			frame.arcanePlatesStyledPoint = point or "CENTER";
			frame.arcanePlatesStyledRelativeTo = relativeTo or frame;
			frame.arcanePlatesStyledRelativePoint = relativePoint or frame.arcanePlatesStyledPoint;
			frame.arcanePlatesStyledX = x or 0;
			frame.arcanePlatesStyledY = y or 0;
			return true;
		end
	end
	if ( frame.arcanePlatesOverlay ) then
		local source = frame.arcanePlatesSourceBar;
		if ( source and ( not frame.arcanePlatesOverlayWidth
				or not frame.arcanePlatesOverlayPoint ) ) then
			local point, relativeTo, relativePoint, x, y = source:GetPoint();
			local originalWidth = frame.arcanePlatesSourceOriginalWidth or source:GetWidth();
			local originalHeight = frame.arcanePlatesSourceOriginalHeight or source:GetHeight();
			local oldVisuals = frame.arcanePlatesVisuals or {};
			for j = 1, table.getn(oldVisuals) do
				if ( oldVisuals[j].region == source ) then
					originalWidth, originalHeight = oldVisuals[j].width, oldVisuals[j].height;
					point = oldVisuals[j].point;
					relativeTo = oldVisuals[j].relativeTo;
					relativePoint = oldVisuals[j].relativePoint;
					x, y = oldVisuals[j].x, oldVisuals[j].y;
					break;
				end
			end
			if ( point ) then
				local width = originalWidth * PLATE_SCALE;
				local height = originalHeight * PLATE_SCALE;
				local adjustedX, adjustedY = x or 0, y or 0;
				if ( string.find(point, "LEFT") ) then adjustedX = adjustedX + width / 2; end
				if ( string.find(point, "BOTTOM") ) then adjustedY = adjustedY + height / 2; end
				frame.arcanePlatesOverlayPoint = point;
				frame.arcanePlatesOverlayRelativeTo = relativeTo or frame;
				frame.arcanePlatesOverlayRelativePoint = relativePoint or point;
				frame.arcanePlatesOverlayX = adjustedX;
				frame.arcanePlatesOverlayY = adjustedY;
				frame.arcanePlatesOverlayWidth = width;
				frame.arcanePlatesOverlayHeight = height;
				frame.arcanePlatesOverlayBaseX = x or 0;
				frame.arcanePlatesOverlayBaseY = y or 0;
				frame.arcanePlatesOverlayBaseWidth = originalWidth;
				frame.arcanePlatesOverlayBaseHeight = originalHeight;
				frame.arcanePlatesOverlay:SetWidth(width);
				frame.arcanePlatesOverlay:SetHeight(height);
				frame.arcanePlatesOverlay:ClearAllPoints();
				frame.arcanePlatesOverlay:SetPoint(point, relativeTo or frame,
					relativePoint or point,
					adjustedX + HORIZONTAL_OFFSET,
					adjustedY + VERTICAL_OFFSET);
			end
		end
		return true;
	end
	local children = { frame:GetChildren() };
	for i = 1, table.getn(children) do
		local child = children[i];
		if ( child:GetObjectType() == "StatusBar"
				and child:GetWidth() > 0 and child:GetHeight() > 0 ) then
			local point, relativeTo, relativePoint, x, y = child:GetPoint();
			if ( not point ) then return false; end
			local originalWidth = frame.arcanePlatesSourceOriginalWidth or child:GetWidth();
			local originalHeight = frame.arcanePlatesSourceOriginalHeight or child:GetHeight();
			-- A previous addon revision may already have resized the native bar.
			local oldVisuals = frame.arcanePlatesVisuals or {};
			for j = 1, table.getn(oldVisuals) do
				if ( oldVisuals[j].region == child ) then
					originalWidth, originalHeight = oldVisuals[j].width, oldVisuals[j].height;
					point = oldVisuals[j].point;
					relativeTo = oldVisuals[j].relativeTo;
					relativePoint = oldVisuals[j].relativePoint;
					x, y = oldVisuals[j].x, oldVisuals[j].y;
					break;
				end
			end
			local width = originalWidth * PLATE_SCALE;
			local height = originalHeight * PLATE_SCALE;
			local adjustedX, adjustedY = x or 0, y or 0;
			if ( string.find(point, "LEFT") ) then adjustedX = adjustedX + width / 2; end
			if ( string.find(point, "BOTTOM") ) then adjustedY = adjustedY + height / 2; end
			frame.arcanePlatesOverlayPoint = point;
			frame.arcanePlatesOverlayRelativeTo = relativeTo or frame;
			frame.arcanePlatesOverlayRelativePoint = relativePoint or point;
			frame.arcanePlatesOverlayX = adjustedX;
			frame.arcanePlatesOverlayY = adjustedY;
			frame.arcanePlatesOverlayWidth = width;
			frame.arcanePlatesOverlayHeight = height;
			frame.arcanePlatesOverlayBaseX = x or 0;
			frame.arcanePlatesOverlayBaseY = y or 0;
			frame.arcanePlatesOverlayBaseWidth = originalWidth;
			frame.arcanePlatesOverlayBaseHeight = originalHeight;
			local overlay = CreateFrame("StatusBar", nil, frame);
			overlay:SetWidth(width);
			overlay:SetHeight(height);
			overlay:SetPoint(point, relativeTo or frame, relativePoint or point,
			adjustedX + HORIZONTAL_OFFSET,
			adjustedY + VERTICAL_OFFSET);
			overlay:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
			overlay:SetFrameLevel(child:GetFrameLevel() + 1);
			local background = overlay:CreateTexture(nil, "BACKGROUND");
			background:SetAllPoints(overlay);
			background:SetTexture("Interface\\Buttons\\WHITE8X8");
			background:SetVertexColor(0, 0, 0, 0.9);
			frame.arcanePlatesSourceBar = child;
			frame.arcanePlatesOverlay = overlay;
			frame.arcanePlatesOverlayOriginalScale = overlay:GetScale();
			child:Hide();
			return true;
		end
	end
	return false;
end

local function RegisterPlate(frame)
	if not frame or not frame.IsVisible or not frame:IsVisible()
			or not frame.GetWidth or frame:GetWidth() <= 0
			or not frame.GetHeight or frame:GetHeight() <= 0 then return false end
	local known = knownPlates[frame] and true or false
	if not known and not IdentifyNameplate(frame) then return false end

	local currentName = GetPlateName(frame)
	local oldName = frame.arcanePlatesPlateName
	if known and currentName ~= oldName and oldName ~= nil then
		-- Restore the previous unit before observing the new unit's native layout.
		RestoreNativeState(frame)
	end

	if not known then
		knownPlates[frame] = true
		table.insert(orderedPlates, frame)
		CaptureNativeState(frame)
		frame.arcanePlatesOriginalScale = frame:GetScale() or 1
	elseif currentName ~= oldName then
		-- A recycled frame may have new regions or children. Capture them after
		-- old visuals are restored, so the new snapshot is genuinely native.
		local states = frame.arcanePlatesNativeState or {}
		local seen = {}
		for i = 1, table.getn(states) do seen[states[i].object] = true end
		local fresh = {}
		SaveObjectState(frame, fresh)
		for i = 1, table.getn(fresh) do
			if not seen[fresh[i].object] then table.insert(states, fresh[i]) end
		end
		frame.arcanePlatesNativeState = states
	end

	if currentName ~= oldName then
		frame.arcanePlatesPlateName = currentName
		frame.arcanePlatesDebuffUnitID = nil
		frame.arcanePlatesDebuffSignature = nil
		frame.arcanePlatesAppliedCategory = nil
		frame.arcanePlatesStyleRevision = -1
		frame.arcanePlatesNativeRestored = false
	end
	return true
end
local function SyncOverlayValues()
	for i = 1, table.getn(orderedPlates) do
		local frame = orderedPlates[i]
		local overlay, source = frame.arcanePlatesOverlay, frame.arcanePlatesSourceBar
		if overlay and source and frame:IsVisible() and overlay:IsShown() then
			local minimum, maximum = source:GetMinMaxValues()
			if minimum ~= frame.arcanePlatesLastMin or maximum ~= frame.arcanePlatesLastMax then
				frame.arcanePlatesLastMin, frame.arcanePlatesLastMax = minimum, maximum
				overlay:SetMinMaxValues(minimum, maximum)
			end
			local value = source:GetValue()
			if value ~= frame.arcanePlatesLastValue then
				frame.arcanePlatesLastValue = value
				overlay:SetValue(value)
			end
			local r, g, b, a = source:GetStatusBarColor()
			if r ~= frame.arcanePlatesLastR or g ~= frame.arcanePlatesLastG
					or b ~= frame.arcanePlatesLastB or a ~= frame.arcanePlatesLastA then
				frame.arcanePlatesLastR, frame.arcanePlatesLastG = r, g
				frame.arcanePlatesLastB, frame.arcanePlatesLastA = b, a
				overlay:SetStatusBarColor(r, g, b, a)
			end
		end
	end
end

local function ApplyKnownPlate(frame, updateDebuffs)
	if not frame or not frame.GetObjectType or frame:GetObjectType() ~= "Frame" or not frame:IsVisible() then return end
	local special = IsBossOrGuardianPlate(frame)
	local category = special and "boss" or "regular"
	if frame.arcanePlatesAppliedCategory ~= category
			or frame.arcanePlatesStyleRevision ~= styleRevision then
		frame.arcanePlatesAppliedCategory = category
		frame.arcanePlatesStyleRevision = styleRevision
		if special then
			if not frame.arcanePlatesNativeRestored then RestoreNativeState(frame) end
			ApplyPlateBarColor(frame, BarColor("boss"))
			HideNameText(frame)
			UpdateNamePlaceholder(frame)
		else
			if frame.arcanePlatesNativeRestored then frame.arcanePlatesNativeRestored = false end
			if CreatePlateOverlay(frame) then ApplyPlateStyle(frame) end
		end
	end
	if special and updateDebuffs then
		if Opt("showDebuffs") then
			UpdateBossGuardianDebuffs(frame)
		elseif frame.arcanePlatesDebuffRow and frame.arcanePlatesDebuffRow:IsShown() then
			frame.arcanePlatesDebuffRow:Hide()
		end
	end
end

local function StyleKnownPlates(updateDebuffs)
	RefreshBossGuardianNames()
	for i = 1, table.getn(orderedPlates) do ApplyKnownPlate(orderedPlates[i], updateDebuffs) end
end

local function ScanNameplates()
	if type(WorldFrame) ~= "table" or type(WorldFrame.GetChildren) ~= "function" then return end
	local children = { WorldFrame:GetChildren() }
	for i = 1, table.getn(children) do
		local frame = children[i]
		-- V controls whether Blizzard/Azeroth Survivors exposes active plates. Only
		-- snapshot a real, laid-out plate; hidden pooled frames can still be 0x0.
		if frame and frame.IsVisible and frame:IsVisible()
				and frame.GetWidth and frame:GetWidth() > 0
				and frame.GetHeight and frame:GetHeight() > 0 then
			RegisterPlate(frame)
			end
	end
end

local function RefreshAll()
	refreshPending = true
	if scanFrame then
		scanClock = 0
	end
end

local function RestoreAll()
	active = false
	for i = 1, table.getn(orderedPlates) do
		local frame = orderedPlates[i]
		if frame then
			RestoreNativeState(frame)
			if frame.arcanePlatesOverlay then frame.arcanePlatesOverlay:Hide() end
			if frame.arcanePlatesDebuffRow then frame.arcanePlatesDebuffRow:Hide() end
			if frame.arcanePlatesBossGuardianLabel then frame.arcanePlatesBossGuardianLabel:Hide() end
			if frame.arcanePlatesShrunkLabelHolder then frame.arcanePlatesShrunkLabelHolder:Hide() end
			frame.arcanePlatesNativeRestored = true
		end
	end
end

local function SetEnabled(on)
	on = on and true or false
	if active == on then
		if active then RefreshAll() end
		return
	end
	active = on
	styleRevision = styleRevision + 1
	for i = 1, table.getn(orderedPlates) do
		orderedPlates[i].arcanePlatesAppliedCategory = nil
		orderedPlates[i].arcanePlatesStyleRevision = -1
	end
	if active then
		scanClock = 0
		refreshPending = true
		if scanFrame then scanFrame:Show() end
	else
		RestoreAll()
		if scanFrame then scanFrame:Hide() end
	end
end

C.ArcanePlatesRefresh = function(force)
	styleRevision = styleRevision + 1
	if force then RefreshAll() else refreshPending = true end
end

C.OnInit(function()
	local d = C.DB("nameplates", {
		showDebuffs = true, hideShrunkPlates = false, hideBossName = false,
		showShrunkName = false, enabled = true,
	})
	active = d.enabled ~= false
	scanFrame = CreateFrame("Frame", "ArcanePlatesDriver")
	scanFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	scanFrame:RegisterEvent("CHAT_MSG_ADDON")
	scanFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	scanFrame:SetScript("OnEvent", function()
		if event == "CHAT_MSG_ADDON" and arg1 ~= "AZSUNITS" then return end
		RefreshAll()
	end)
	scanFrame:SetScript("OnUpdate", function()
		if not active then return end
		local dt = arg1 or 0
		if dt > 0.1 then dt = 0.1 end
		scanClock = scanClock - dt
		if scanClock <= 0 then
			scanClock = SCAN_INTERVAL
			ScanNameplates()
			refreshPending = true
		end
		overlayClock = overlayClock - dt
		if overlayClock <= 0 then
			overlayClock = OVERLAY_INTERVAL
			SyncOverlayValues()
		end
		debuffClock = debuffClock - dt
		local updateDebuffs = false
		if debuffClock <= 0 then
			debuffClock = DEBUFF_INTERVAL
			updateDebuffs = true
		end
		if refreshPending then
			refreshPending = false
			local ok, err = pcall(StyleKnownPlates, updateDebuffs)
			if not ok then
				C.Print(C.L("Arcane nameplates stopped after an error: ") .. tostring(err))
				SetEnabled(false)
			end
		elseif updateDebuffs then
			local ok, err = pcall(function()
				RefreshBossGuardianNames()
				for i = 1, table.getn(orderedPlates) do
					local frame = orderedPlates[i]
					if frame.arcanePlatesBossGuardian and frame:IsVisible() and Opt("showDebuffs") then
						UpdateBossGuardianDebuffs(frame)
					end
				end
			end)
			if not ok then
				C.Print(C.L("Arcane nameplate debuff update stopped after an error: ") .. tostring(err))
				SetEnabled(false)
			end
		end
	end)
	if not active then scanFrame:Hide() end
end)

C.OnWorld(function()
	if active and scanFrame then RefreshAll(); scanFrame:Show() end
end)

C.OnLogout(function() RestoreAll() end)

C.RegisterPart({
	key = "nameplates", name = "Tiny Plates",
	note = "Half-size regular nameplates, with full-size boss and guardian plates.",
	get = function() return active end,
	set = function(on)
		local d = C.DB("nameplates")
		d.enabled = on and true or false
		SetEnabled(on)
	end,
})

