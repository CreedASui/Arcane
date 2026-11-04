-- Arcane Tiny Plates
-- Based on ASTinyPlates by Valorless (MIT); see ATTRIBUTION.md and TinyPlates-LICENSE.txt.
-- Adapted for Arcane's shared DB, menu, lifecycle and Lua 5.0 client.
local C = Arcane
local knownPlates = {}
local orderedPlates = {}
local active = true
local scanClock = 0
local SCAN_INTERVAL = 0.10
local refreshPending = true
local scanFrame

local function Opt(key)
	return C.TinyPlatesOption and C.TinyPlatesOption(key) or false
end
local debugPlates = orderedPlates;
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
		frame.astinyplatesBossGuardian = nil
		frame.astinyplatesBossGuardianName = nil
		frame.astinyplatesDebuffUnitID = nil
		frame.astinyplatesDebuffSignature = nil
		if frame.astinyplatesDebuffRow then frame.astinyplatesDebuffRow:Hide() end
	end
end

local function RefreshBossGuardianNames(force)
	local phase = AZS_GetPhase and AZS_GetPhase() or nil;
	local unitsUpdate = AZS_UNITS_UPDATED or 0;
	local debuffsUpdate = AZS_DEBUFFS_UPDATED or 0;
	local newRun = phase == "playing" and ( lastSpecialPhase == nil
		or lastSpecialPhase == "ready" or lastSpecialPhase == "dead"
		or lastSpecialPhase == "victory" );
	local resetNames = (phase == "ready" and lastSpecialPhase ~= "ready") or newRun;
	if ( resetNames ) then
		bossGuardianNames = {};
		bossGuardianUnitsByName = {};
		ClearBossGuardianPlateFlags();
	end
    local retryCache = phase ~= "ready" and GetTime() - lastSpecialRefreshTime >= 1;
	if ( phase ~= "ready" and ( force or retryCache or phase ~= lastSpecialPhase
			or unitsUpdate ~= lastSpecialUnitsUpdate
			or debuffsUpdate ~= lastSpecialDebuffsUpdate or newRun ) ) then
		bossGuardianUnitsByName = {};
		AddBossGuardianNames(AZS_UNITS, true);
		if ( type(AZS_GetBosses) == "function" ) then AddBossGuardianNames(AZS_GetBosses(), false); end
		if ( type(AZS_GetGuardians) == "function" ) then AddBossGuardianNames(AZS_GetGuardians(), false); end
		lastSpecialRefreshTime = GetTime();
	end
	lastSpecialPhase = phase;
	lastSpecialUnitsUpdate = unitsUpdate;
	lastSpecialDebuffsUpdate = debuffsUpdate;
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
	return object == frame.astinyplatesOverlay or object == frame.astinyplatesDebuffRow;
end

-- Searches the plate and its descendants, because UI replacements such as SDUI
-- may move the name FontString into a child frame or blank the native one.
local function GetPlateName(frame, root)
	root = root or frame;
	local regions = { root:GetRegions() };
	for i = 1, table.getn(regions) do
		local region = regions[i];
		if ( region and region ~= frame.astinyplatesBossGuardianLabel
				and region:GetObjectType() == "FontString" ) then
			local name = NormalizeName(region:GetText());
			-- Purely numeric text is a level indicator, not a name.
			if ( name and not string.find(name, "^%d+$") ) then
				frame.astinyplatesNameRegion = region;
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

local function CachePlateName(frame)
	-- Plates are recycled for other units, so a stale name must never survive
	-- a failed lookup.
	frame.astinyplatesPlateName = GetPlateName(frame);
end

local function IsBossOrGuardianName(name)
	return name and bossGuardianNames[name] or false;
end

local function FindBossGuardianName(frame)
	local regions = { frame:GetRegions() };
	for i = 1, table.getn(regions) do
		local region = regions[i];
		if ( region and region ~= frame.astinyplatesBossGuardianLabel
				and region:GetObjectType() == "FontString" ) then
			local name = NormalizeName(region:GetText());
			if ( name and IsBossOrGuardianName(name) ) then
				frame.astinyplatesNameRegion = region;
				return name;
			end
		end
	end
	local children = { frame:GetChildren() };
	for i = 1, table.getn(children) do
		local name = FindBossGuardianName(children[i]);
		if ( name ) then return name; end
	end
	return nil;
end

local function IsBossOrGuardianPlate(frame)
	local matchedName = FindBossGuardianName(frame);
	if ( matchedName ) then
		frame.astinyplatesPlateName = matchedName;
	else
		CachePlateName(frame);
	end
	local name = frame.astinyplatesPlateName;
	if ( not name ) then
		frame.astinyplatesBossGuardian = false;
		frame.astinyplatesBossGuardianName = nil;
		return false;
	end
	if ( frame.astinyplatesBossGuardianName
			and frame.astinyplatesBossGuardianName ~= name ) then
		frame.astinyplatesDebuffUnitID = nil;
		if ( frame.astinyplatesDebuffRow ) then frame.astinyplatesDebuffRow:Hide(); end
	end
	if ( IsBossOrGuardianName(name) ) then
		frame.astinyplatesBossGuardian = true;
		frame.astinyplatesBossGuardianName = name;
		return true;
	end
	if ( frame.astinyplatesBossGuardian and frame.astinyplatesBossGuardianName == name ) then
		return true;
	end
	frame.astinyplatesBossGuardian = false;
	frame.astinyplatesBossGuardianName = nil;
	return false;
end

local function SaveObjectState(object, states)
	local state = { object = object, shown = object:IsShown() };
	if ( object.GetAlpha ) then state.alpha = object:GetAlpha(); end
	table.insert(states, state);
	if ( object.GetRegions ) then
		local regions = { object:GetRegions() };
		for i = 1, table.getn(regions) do SaveObjectState(regions[i], states); end
	end
	if ( object.GetChildren ) then
		local children = { object:GetChildren() };
		for i = 1, table.getn(children) do SaveObjectState(children[i], states); end
	end
end

local function CaptureNativeState(frame)
	if ( frame.astinyplatesNativeState ) then return; end
	local previouslyStyled = frame.astinyplatesStyledVisual or frame.astinyplatesOverlay;
	local point, relativeTo, relativePoint, x, y = frame:GetPoint();
	frame.astinyplatesNativeWidth = frame.astinyplatesStackOriginalWidth or frame:GetWidth();
	frame.astinyplatesNativeHeight = frame.astinyplatesStackOriginalHeight or frame:GetHeight();
	frame.astinyplatesNativeScale = frame.astinyplatesStackOriginalScale
		or frame.astinyplatesOriginalScale or frame:GetScale();
	frame.astinyplatesNativePoint = frame.astinyplatesStackPoint or point;
	frame.astinyplatesNativeRelativeTo = frame.astinyplatesStackRelativeTo or relativeTo;
	frame.astinyplatesNativeRelativePoint = frame.astinyplatesStackRelativePoint or relativePoint;
	frame.astinyplatesNativeX = frame.astinyplatesStackPoint and frame.astinyplatesStackX or x;
	frame.astinyplatesNativeY = frame.astinyplatesStackPoint and frame.astinyplatesStackY or y;
	local states = {};
	SaveObjectState(frame, states);
	-- A reload can leave our old custom visual attached while the native plate
	-- is already hidden; in that case restore all native children below.
	if ( not previouslyStyled ) then frame.astinyplatesNativeState = states; end
end

local function RestoreNativeState(frame)
	if frame.astinyplatesNativeRestored then return end
	local wasModified = frame.astinyplatesOverlay or frame.astinyplatesStyledVisual
		or frame.astinyplatesNativeState or frame.astinyplatesSourceBar
	if not wasModified then
		frame.astinyplatesNativeRestored = true
		return
	end
	if frame.astinyplatesOverlay then frame.astinyplatesOverlay:Hide() end
	if frame.astinyplatesNativeState then
		for i = 1, table.getn(frame.astinyplatesNativeState) do
			local state = frame.astinyplatesNativeState[i]
			local object = state.object
			if object ~= frame.astinyplatesOverlay and object ~= frame.astinyplatesDebuffRow
					and object ~= frame.astinyplatesBossGuardianLabel
				and object ~= frame.astinyplatesShrunkLabelHolder then
				if object.SetAlpha and state.alpha ~= nil then object:SetAlpha(state.alpha) end
				if state.shown then object:Show() else object:Hide() end
			end
		end
	end
	if frame.astinyplatesStyledVisual then
		local styled = frame.astinyplatesStyledVisual
		if frame.astinyplatesStyledOriginalScale then styled:SetScale(frame.astinyplatesStyledOriginalScale) end
		styled:ClearAllPoints()
		styled:SetPoint(frame.astinyplatesStyledPoint or "CENTER",
			frame.astinyplatesStyledRelativeTo or frame,
			frame.astinyplatesStyledRelativePoint or "CENTER",
			frame.astinyplatesStyledX or 0, frame.astinyplatesStyledY or 0)
	end
	if frame.astinyplatesSourceBar then
		if frame.astinyplatesSourceOriginalWidth then frame.astinyplatesSourceBar:SetWidth(frame.astinyplatesSourceOriginalWidth) end
		if frame.astinyplatesSourceOriginalHeight then frame.astinyplatesSourceBar:SetHeight(frame.astinyplatesSourceOriginalHeight) end
	end
	for bar in pairs(frame.astinyplatesColoredBars or {}) do ApplyBarOverride(bar, nil) end
	if frame.astinyplatesNativeWidth then frame:SetWidth(frame.astinyplatesNativeWidth) end
	if frame.astinyplatesNativeHeight then frame:SetHeight(frame.astinyplatesNativeHeight) end
	if frame.astinyplatesNativeScale then frame:SetScale(frame.astinyplatesNativeScale) end
	if frame.astinyplatesNativePoint then
		frame:ClearAllPoints()
		frame:SetPoint(frame.astinyplatesNativePoint,
			frame.astinyplatesNativeRelativeTo or frame:GetParent(),
			frame.astinyplatesNativeRelativePoint or frame.astinyplatesNativePoint,
			frame.astinyplatesNativeX or 0, frame.astinyplatesNativeY or 0)
	end
	if frame.astinyplatesBossGuardianLabel then frame.astinyplatesBossGuardianLabel:Hide() end
	if frame.astinyplatesShrunkLabelHolder then frame.astinyplatesShrunkLabelHolder:Hide() end
	if frame.astinyplatesDebuffRow then frame.astinyplatesDebuffRow:Hide() end
	frame.astinyplatesNativeRestored = true
end

local function IdentifyNameplate(frame)
	local regions = { frame:GetRegions() };
	local hasBorder = false;
	local hasName = false;
	for i = 1, table.getn(regions) do
		local region = regions[i];
		if ( region and region:GetObjectType() == "Texture"
				and region:GetTexture() == BORDER ) then
			hasBorder = true;
		elseif ( region and region:GetObjectType() == "FontString" ) then
			hasName = true;
		end
	end
	local children = { frame:GetChildren() };
	local hasHealthBar = false;
	for i = 1, table.getn(children) do
		if ( children[i]:GetObjectType() == "StatusBar" ) then
			hasHealthBar = true;
			break;
		end
	end
	return hasName and ( hasBorder or hasHealthBar );
end

local function HideNameText(frame)
	local regions = { frame:GetRegions() };
	for i = 1, table.getn(regions) do
		local region = regions[i];
		if ( region and region ~= frame.astinyplatesBossGuardianLabel
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
	if ( frame.astinyplatesNameRegion and frame.astinyplatesPlateName ) then
		local text = frame.astinyplatesNameRegion:GetText();
		if ( not text or text == "" ) then
			frame.astinyplatesNameRegion:SetText(frame.astinyplatesPlateName);
		end
	end
	local regions = { frame:GetRegions() };
	for i = 1, table.getn(regions) do
		local region = regions[i];
		if ( region and region:GetObjectType() == "FontString" ) then
			local text = region:GetText();
			if ( ( not text or text == "" ) and frame.astinyplatesPlateName ) then
				region:SetText(frame.astinyplatesPlateName);
			end
			region:SetAlpha(1);
			region:Show();
		end
	end
end

local function UpdateBossGuardianLabel(frame)
	local name = frame.astinyplatesPlateName;
	if ( not name or name == "" ) then
		if ( frame.astinyplatesBossGuardianLabel ) then frame.astinyplatesBossGuardianLabel:Hide(); end
		return;
	end
	local label = frame.astinyplatesBossGuardianLabel;
	if ( not label ) then
		label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		label:SetWidth(180);
		label:SetHeight(14);
		label:SetJustifyH("CENTER");
		label:SetTextColor(1, 0.82, 0.15, 1);
		frame.astinyplatesBossGuardianLabel = label;
	end
	local bar = frame.astinyplatesSourceBar;
	if ( not bar ) then
		local children = { frame:GetChildren() };
		for i = 1, table.getn(children) do
			if ( children[i]:GetObjectType() == "StatusBar" ) then
				bar = children[i];
				break;
			end
		end
	end
	frame.astinyplatesBossGuardianBar = bar;
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
		if ( child ~= source and child ~= frame.astinyplatesOverlay
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
	local label = frame.astinyplatesBossGuardianLabel;
	local name = frame.astinyplatesPlateName;
	local source;
	local visual = frame.astinyplatesBossGuardianStyleVisual;
	if ( not visual ) then
		local sourceBar = frame.astinyplatesSourceBar;
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
		frame.astinyplatesBossGuardianStyleVisual = visual;
	end
	if ( visual ) then source = FindNameFontString(visual, name); end
	if ( not source ) then source = frame.astinyplatesNameRegion; end
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
	local bar = frame.astinyplatesBossGuardianBar;
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
	local name = frame.astinyplatesPlateName;
	local unit = FindBossGuardianUnit(frame, name);
	local row = frame.astinyplatesDebuffRow;
	if ( not row ) then
		row = CreateFrame("Frame", nil, frame);
		row:SetHeight(DEBUFF_ICON_SIZE);
		row:SetFrameLevel(frame:GetFrameLevel() + 5);
		frame.astinyplatesDebuffRow = row;
	end
	if ( unit and unit.id ) then
		frame.astinyplatesDebuffUnitID = unit.id;
	end
	local unitID = frame.astinyplatesDebuffUnitID;
	if ( not unitID ) then row:Hide(); return; end
	local debuffs;
	if ( unitID and type(AZS_GetDebuffs) == "function" ) then debuffs = AZS_GetDebuffs(unitID); end
	if ( (not debuffs or type(debuffs) ~= "table") and unit
			and type(unit.debuffs) == "table" ) then
		debuffs = unit.debuffs;
	end
	-- A nil response is transient/unavailable; retain the last known row.
	if ( type(debuffs) ~= "table" ) then return; end
	local iconIndex = 0;
	for i = 1, table.getn(debuffs) do
		local debuff = debuffs[i];
		if ( debuff and iconIndex < MAX_DEBUFF_ICONS ) then
			iconIndex = iconIndex + 1;
			local icon = frame.astinyplatesDebuffIcons
				and frame.astinyplatesDebuffIcons[iconIndex];
			if ( not icon ) then
				if ( not frame.astinyplatesDebuffIcons ) then frame.astinyplatesDebuffIcons = {}; end
				icon = CreateDebuffIcon(row, iconIndex);
				frame.astinyplatesDebuffIcons[iconIndex] = icon;
			end
			local iconTexture = debuff.icon;
			if ( not iconTexture or iconTexture == "" ) then
				iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark";
			end
			icon.texture:SetTexture(iconTexture);
			if ( debuff.stacks and debuff.stacks > 1 ) then
				icon.stacks:SetText(debuff.stacks);
			else
				icon.stacks:SetText("");
			end
			local remaining = debuff.remaining;
			if ( not remaining and debuff.ends and type(AZS_GetRunTime) == "function" ) then
				local runTime = AZS_GetRunTime();
				if ( runTime and debuff.ends >= 0 ) then remaining = debuff.ends - runTime; end
			end
			if ( debuff.permanent ) then
				icon.duration:SetText("∞");
			elseif ( type(remaining) == "number" and remaining >= 0 ) then
				icon.duration:SetText(math.ceil(remaining));
			else
				icon.duration:SetText("");
			end
			icon:Show();
			icon.overlay:Show();
		end
	end
	for i = iconIndex + 1, table.getn(frame.astinyplatesDebuffIcons or {}) do
		frame.astinyplatesDebuffIcons[i]:Hide();
	end
	if ( iconIndex == 0 ) then row:Hide(); return; end
	row:SetWidth(iconIndex * DEBUFF_ICON_SIZE + (iconIndex - 1) * DEBUFF_ICON_GAP);
	row:ClearAllPoints();
	local bar = frame.astinyplatesStyledVisual or frame.astinyplatesBossGuardianBar
		or frame.astinyplatesOverlay;
	if ( bar ) then
		row:SetPoint("TOP", bar, "BOTTOM", 0, -3);
	else
		row:SetPoint("TOP", frame, "BOTTOM", 0, -3);
	end
	row:Show();
end

local function EnsureOverlayBorder(frame, overlay)
	if ( frame.astinyplatesOverlayBorder ) then return; end
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
	frame.astinyplatesOverlayBorder = border;
end

local function HideNativePlate(frame, keep)
	local regions = { frame:GetRegions() };
	for i = 1, table.getn(regions) do
		local region = regions[i];
		if ( region and region:GetObjectType() == "Texture" ) then region:Hide(); end
	end
	local children = { frame:GetChildren() };
	for i = 1, table.getn(children) do
		if ( children[i] ~= keep and children[i] ~= frame.astinyplatesOverlay
				and children[i] ~= frame.astinyplatesShrunkLabelHolder ) then
			children[i]:Hide();
		end
	end
end

local function IsPlaceholderShrunk(frame)
	local visual = frame.astinyplatesStyledVisual;
	if ( visual and visual:IsShown() and frame.astinyplatesStyledOriginalScale ) then
		return visual:GetScale() < frame.astinyplatesStyledOriginalScale * 0.99;
	end
	local overlay = frame.astinyplatesOverlay;
	if ( overlay and overlay:IsShown() and frame.astinyplatesOverlayBaseWidth ) then
		return overlay:GetWidth() < frame.astinyplatesOverlayBaseWidth * 0.99;
	end
	local source = frame.astinyplatesSourceBar;
	if ( source and source:IsShown() and frame.astinyplatesSourceOriginalWidth ) then
		return source:GetWidth() < frame.astinyplatesSourceOriginalWidth * 0.99;
	end
	return false;
end

local function HideShrunkNameLabel(frame)
	if ( frame.astinyplatesShrunkLabelHolder ) then frame.astinyplatesShrunkLabelHolder:Hide(); end
end

-- Name above a shrunken plate; lives on its own child frame so the native-child hiding does not remove it.
local function UpdateShrunkNameLabel(frame)
	local name = frame.astinyplatesPlateName;
	if ( not Opt("showShrunkName") or frame.astinyplatesBossGuardian
			or not name or name == "" ) then
		HideShrunkNameLabel(frame);
		return;
	end
	local holder = frame.astinyplatesShrunkLabelHolder;
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
		frame.astinyplatesShrunkLabelHolder = holder;
	end
	local anchor = frame.astinyplatesStyledVisual or frame.astinyplatesOverlay
		or frame.astinyplatesSourceBar or frame;
	holder.text:ClearAllPoints();
	holder.text:SetPoint("BOTTOM", anchor, "TOP", 0, 2);
	holder.text:SetText(name);
	holder.text:SetAlpha(1);
	holder:Show();
end

local function UpdateNamePlaceholder(frame)
	local label = frame.astinyplatesBossGuardianLabel;
	if ( IsPlaceholderShrunk(frame) ) then
		if ( label ) then label:Hide(); end
		UpdateShrunkNameLabel(frame);
		return;
	end
	HideShrunkNameLabel(frame);
	if ( frame.astinyplatesBossGuardian and Opt("hideBossName") ) then
		if ( label ) then label:Hide(); end
		local visual = frame.astinyplatesStyledVisual;
		local native = visual and FindNameFontString(visual, frame.astinyplatesPlateName);
		if ( native ) then native:SetAlpha(0); native:Hide(); end
		HideMatchingNameText(frame, frame.astinyplatesPlateName, nil);
		return;
	end
	local visual = frame.astinyplatesStyledVisual;
	local native = visual and FindNameFontString(visual, frame.astinyplatesPlateName);
	if ( native and NormalizeName(native:GetText()) == frame.astinyplatesPlateName ) then
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
	HideMatchingNameText(frame, frame.astinyplatesPlateName,
		frame.astinyplatesBossGuardianLabel);
end

-- Custom bar colors. The color the game/SDUI last set is remembered per bar so it can be restored
-- when the override is turned off or a recycled plate changes category.
local function BarColor(category)
	if ( ASTinyPlatesBarColor ) then return ASTinyPlatesBarColor(category); end
	return nil;
end

local function ColorsDiffer(r1, g1, b1, r2, g2, b2)
	return math.abs((r1 or 0) - r2) > 0.01 or math.abs((g1 or 0) - g2) > 0.01
		or math.abs((b1 or 0) - b2) > 0.01;
end

local function ApplyBarOverride(bar, color)
	if not bar or not bar.SetStatusBarColor then return end
	if color then
		local r, g, b, a = bar:GetStatusBarColor()
		local applied = bar.astinyplatesAppliedColor
		if not applied or ColorsDiffer(r, g, b, applied[1], applied[2], applied[3]) then
			bar.astinyplatesOriginalColor = { r or 1, g or 1, b or 1, a }
		end
		if ColorsDiffer(r, g, b, color[1], color[2], color[3]) then
			bar:SetStatusBarColor(color[1], color[2], color[3], a)
		end
		bar.astinyplatesAppliedColor = { color[1], color[2], color[3] }
	else
		local original = bar.astinyplatesOriginalColor
		if bar.astinyplatesAppliedColor and original then
			bar:SetStatusBarColor(original[1], original[2], original[3], original[4])
		end
		bar.astinyplatesAppliedColor = nil
		bar.astinyplatesOriginalColor = nil
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
	local bars = frame.astinyplatesColorBars
	if not bars then
		bars = {}
		local styled = frame.astinyplatesStyledVisual
		if styled then CollectStatusBars(styled, bars) end
		local source = frame.astinyplatesSourceBar
		if not source then
			local children = { frame:GetChildren() }
			for i = 1, table.getn(children) do
				if children[i]:GetObjectType() == "StatusBar" then source = children[i]; break end
			end
		end
		if source then table.insert(bars, source) end
		frame.astinyplatesColorBars = bars
	end
	frame.astinyplatesColoredBars = frame.astinyplatesColoredBars or {}
	for i = 1, table.getn(bars) do
		local bar = bars[i]
		ApplyBarOverride(bar, color)
		if color then frame.astinyplatesColoredBars[bar] = true else frame.astinyplatesColoredBars[bar] = nil end
	end
end

local function HideShrunkPlate(frame)
	if ( frame.astinyplatesBossGuardianLabel ) then frame.astinyplatesBossGuardianLabel:Hide(); end
	HideShrunkNameLabel(frame);
	HideNameText(frame);
	if ( frame.astinyplatesStyledVisual ) then frame.astinyplatesStyledVisual:Hide(); end
	if ( frame.astinyplatesOverlay ) then frame.astinyplatesOverlay:Hide(); end
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
		elseif ( frame.astinyplatesDebuffRow ) then
			frame.astinyplatesDebuffRow:Hide();
		end
		return;
	end
	if ( frame.astinyplatesBossGuardianLabel ) then frame.astinyplatesBossGuardianLabel:Hide(); end
	if ( frame.astinyplatesDebuffRow ) then frame.astinyplatesDebuffRow:Hide(); end
	frame.astinyplatesNativeRestored = nil;
	if ( Opt("hideShrunkPlates") ) then
		HideShrunkPlate(frame);
		return;
	end
	local visualScale = PLATE_SCALE;
	ApplyPlateBarColor(frame, BarColor("regular"));
	HideNameText(frame);
	local styled = frame.astinyplatesStyledVisual;
	if ( styled ) then
		styled:Show();
		HideFontStrings(styled);
		local scale = frame.astinyplatesStyledOriginalScale * visualScale;
		if ( styled:GetScale() ~= scale ) then styled:SetScale(scale); end
		local point, relativeTo, relativePoint, x, y = styled:GetPoint();
		local offsetX, offsetY = HORIZONTAL_OFFSET, VERTICAL_OFFSET;
		if ( visualScale == 1 ) then offsetX, offsetY = 0, 0; end
		local targetX = frame.astinyplatesStyledX + offsetX;
		local targetY = frame.astinyplatesStyledY + offsetY;
		if ( point ~= frame.astinyplatesStyledPoint
				or relativeTo ~= frame.astinyplatesStyledRelativeTo
				or relativePoint ~= frame.astinyplatesStyledRelativePoint
				or x ~= targetX or y ~= targetY ) then
			styled:ClearAllPoints();
			styled:SetPoint(frame.astinyplatesStyledPoint, frame.astinyplatesStyledRelativeTo,
				frame.astinyplatesStyledRelativePoint, targetX, targetY);
		end
		if ( frame.astinyplatesOverlay ) then frame.astinyplatesOverlay:Hide(); end
		HideNativePlate(frame, styled);
		UpdateNamePlaceholder(frame);
		return;
	end
	local source = frame.astinyplatesSourceBar;
	local overlay = frame.astinyplatesOverlay;
	if ( not source or not overlay ) then
		return;
	end
	local originalOverlayScale = frame.astinyplatesOverlayOriginalScale or overlay:GetScale();
	frame.astinyplatesOverlayOriginalScale = originalOverlayScale;
	local overlayScale = originalOverlayScale;
	if ( overlay:GetScale() ~= overlayScale ) then overlay:SetScale(overlayScale); end
	EnsureOverlayBorder(frame, overlay);
	if ( not overlay:IsShown() ) then overlay:Show(); end
	if ( not frame.astinyplatesOverlayBaseWidth ) then
		frame.astinyplatesOverlayBaseWidth = frame.astinyplatesSourceOriginalWidth
			or frame.astinyplatesOverlayWidth / PLATE_SCALE;
		frame.astinyplatesOverlayBaseHeight = frame.astinyplatesSourceOriginalHeight
			or frame.astinyplatesOverlayHeight / PLATE_SCALE;
		local baseX, baseY = frame.astinyplatesOverlayX, frame.astinyplatesOverlayY;
		if ( string.find(frame.astinyplatesOverlayPoint, "LEFT") ) then
			baseX = baseX - frame.astinyplatesOverlayWidth / 2;
		end
		if ( string.find(frame.astinyplatesOverlayPoint, "BOTTOM") ) then
			baseY = baseY - frame.astinyplatesOverlayHeight / 2;
		end
		frame.astinyplatesOverlayBaseX = baseX;
		frame.astinyplatesOverlayBaseY = baseY;
	end
	local width = frame.astinyplatesOverlayBaseWidth * visualScale;
	local height = frame.astinyplatesOverlayBaseHeight * visualScale;
	local baseX, baseY = frame.astinyplatesOverlayBaseX, frame.astinyplatesOverlayBaseY;
	if ( string.find(frame.astinyplatesOverlayPoint, "LEFT") ) then baseX = baseX + width / 2; end
	if ( string.find(frame.astinyplatesOverlayPoint, "BOTTOM") ) then baseY = baseY + height / 2; end
	local offsetX, offsetY = HORIZONTAL_OFFSET, VERTICAL_OFFSET;
	if ( visualScale == 1 ) then offsetX, offsetY = 0, 0; end
	local x = baseX + offsetX;
	local y = baseY + offsetY;
	local point, relativeTo, relativePoint, currentX, currentY = overlay:GetPoint();
	if ( overlay:GetWidth() ~= width or overlay:GetHeight() ~= height ) then
		overlay:SetWidth(width);
		overlay:SetHeight(height);
	end
	if ( point ~= frame.astinyplatesOverlayPoint or relativeTo ~= frame.astinyplatesOverlayRelativeTo
			or relativePoint ~= frame.astinyplatesOverlayRelativePoint
			or currentX ~= x or currentY ~= y ) then
		overlay:ClearAllPoints();
		overlay:SetPoint(frame.astinyplatesOverlayPoint, frame.astinyplatesOverlayRelativeTo,
			frame.astinyplatesOverlayRelativePoint, x, y);
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
				and frame.astinyplatesOverlayTexture ~= texturePath ) then
			overlay:SetStatusBarTexture(texturePath);
			frame.astinyplatesOverlayTexture = texturePath;
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
		if ( child ~= overlay and child ~= frame.astinyplatesShrunkLabelHolder ) then child:Hide(); end
	end
	UpdateNamePlaceholder(frame);
end

local function CreatePlateOverlay(frame)
	if ( not frame.astinyplatesStackOriginalWidth ) then
		frame.astinyplatesStackOriginalWidth = frame:GetWidth();
	end
	if ( not frame.astinyplatesStackOriginalHeight ) then
		frame.astinyplatesStackOriginalHeight = frame:GetHeight();
	end
	if ( not frame.astinyplatesStackOriginalScale ) then
		frame.astinyplatesStackOriginalScale = frame.astinyplatesOriginalScale or frame:GetScale();
	end
	if ( frame:GetWidth() ~= frame.astinyplatesStackOriginalWidth ) then
		frame:SetWidth(frame.astinyplatesStackOriginalWidth);
	end
	if ( frame:GetHeight() ~= frame.astinyplatesStackOriginalHeight ) then
		frame:SetHeight(frame.astinyplatesStackOriginalHeight);
	end
	if ( frame.astinyplatesStackPoint ) then
		frame:ClearAllPoints();
		frame:SetPoint(frame.astinyplatesStackPoint,
			frame.astinyplatesStackRelativeTo or frame:GetParent(),
			frame.astinyplatesStackRelativePoint,
			frame.astinyplatesStackX, frame.astinyplatesStackY);
		frame.astinyplatesStackPoint = nil;
		frame.astinyplatesStackRelativeTo = nil;
		frame.astinyplatesStackRelativePoint = nil;
		frame.astinyplatesStackX = nil;
		frame.astinyplatesStackY = nil;
	end
	if ( frame.astinyplatesStackNativePoint ) then
		frame:ClearAllPoints();
		frame:SetPoint(frame.astinyplatesStackNativePoint,
			frame.astinyplatesStackNativeRelativeTo or frame:GetParent(),
			frame.astinyplatesStackNativeRelativePoint,
			frame.astinyplatesStackNativeX, frame.astinyplatesStackNativeY);
		frame.astinyplatesStackNativePoint = nil;
		frame.astinyplatesStackNativeRelativeTo = nil;
		frame.astinyplatesStackNativeRelativePoint = nil;
		frame.astinyplatesStackNativeX = nil;
		frame.astinyplatesStackNativeY = nil;
	end
	frame.astinyplatesStackScaleApplied = nil;
	frame.astinyplatesStackCorrectionPending = nil;
	frame.astinyplatesVisualCorrectionX = nil;
	frame.astinyplatesVisualCorrectionY = nil;
	if ( frame:GetScale() ~= frame.astinyplatesStackOriginalScale ) then
		frame:SetScale(frame.astinyplatesStackOriginalScale);
	end
	if ( not frame.astinyplatesSourceBar ) then
		local children = { frame:GetChildren() };
		for i = 1, table.getn(children) do
			if ( children[i]:GetObjectType() == "StatusBar" ) then
				frame.astinyplatesSourceBar = children[i];
				frame.astinyplatesSourceOriginalWidth = children[i]:GetWidth();
				frame.astinyplatesSourceOriginalHeight = children[i]:GetHeight();
				break;
			end
		end
	end
	local sourceBar = frame.astinyplatesSourceBar;
	if ( sourceBar ) then
		if ( not frame.astinyplatesSourceOriginalWidth ) then
			frame.astinyplatesSourceOriginalWidth = sourceBar:GetWidth();
		end
		if ( not frame.astinyplatesSourceOriginalHeight ) then
			frame.astinyplatesSourceOriginalHeight = sourceBar:GetHeight();
		end
		if ( sourceBar:GetWidth() ~= frame.astinyplatesSourceOriginalWidth ) then
			sourceBar:SetWidth(frame.astinyplatesSourceOriginalWidth);
		end
		if ( sourceBar:GetHeight() ~= frame.astinyplatesSourceOriginalHeight ) then
			sourceBar:SetHeight(frame.astinyplatesSourceOriginalHeight);
		end
	end
	if ( not frame.astinyplatesStyledVisual ) then
		frame.astinyplatesStyledVisual = FindStyledVisual(frame, frame.astinyplatesSourceBar);
		if ( frame.astinyplatesStyledVisual ) then
			local styled = frame.astinyplatesStyledVisual;
			frame.astinyplatesStyledOriginalScale = styled:GetScale();
			local point, relativeTo, relativePoint, x, y = styled:GetPoint();
			frame.astinyplatesStyledPoint = point or "CENTER";
			frame.astinyplatesStyledRelativeTo = relativeTo or frame;
			frame.astinyplatesStyledRelativePoint = relativePoint or frame.astinyplatesStyledPoint;
			frame.astinyplatesStyledX = x or 0;
			frame.astinyplatesStyledY = y or 0;
			return true;
		end
	end
	if ( frame.astinyplatesOverlay ) then
		local source = frame.astinyplatesSourceBar;
		if ( source and ( not frame.astinyplatesOverlayWidth
				or not frame.astinyplatesOverlayPoint ) ) then
			local point, relativeTo, relativePoint, x, y = source:GetPoint();
			local originalWidth = frame.astinyplatesSourceOriginalWidth or source:GetWidth();
			local originalHeight = frame.astinyplatesSourceOriginalHeight or source:GetHeight();
			local oldVisuals = frame.astinyplatesVisuals or {};
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
				frame.astinyplatesOverlayPoint = point;
				frame.astinyplatesOverlayRelativeTo = relativeTo or frame;
				frame.astinyplatesOverlayRelativePoint = relativePoint or point;
				frame.astinyplatesOverlayX = adjustedX;
				frame.astinyplatesOverlayY = adjustedY;
				frame.astinyplatesOverlayWidth = width;
				frame.astinyplatesOverlayHeight = height;
				frame.astinyplatesOverlayBaseX = x or 0;
				frame.astinyplatesOverlayBaseY = y or 0;
				frame.astinyplatesOverlayBaseWidth = originalWidth;
				frame.astinyplatesOverlayBaseHeight = originalHeight;
				frame.astinyplatesOverlay:SetWidth(width);
				frame.astinyplatesOverlay:SetHeight(height);
				frame.astinyplatesOverlay:ClearAllPoints();
				frame.astinyplatesOverlay:SetPoint(point, relativeTo or frame,
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
			local originalWidth = frame.astinyplatesSourceOriginalWidth or child:GetWidth();
			local originalHeight = frame.astinyplatesSourceOriginalHeight or child:GetHeight();
			-- A previous addon revision may already have resized the native bar.
			local oldVisuals = frame.astinyplatesVisuals or {};
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
			frame.astinyplatesOverlayPoint = point;
			frame.astinyplatesOverlayRelativeTo = relativeTo or frame;
			frame.astinyplatesOverlayRelativePoint = relativePoint or point;
			frame.astinyplatesOverlayX = adjustedX;
			frame.astinyplatesOverlayY = adjustedY;
			frame.astinyplatesOverlayWidth = width;
			frame.astinyplatesOverlayHeight = height;
			frame.astinyplatesOverlayBaseX = x or 0;
			frame.astinyplatesOverlayBaseY = y or 0;
			frame.astinyplatesOverlayBaseWidth = originalWidth;
			frame.astinyplatesOverlayBaseHeight = originalHeight;
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
			frame.astinyplatesSourceBar = child;
			frame.astinyplatesOverlay = overlay;
			frame.astinyplatesOverlayOriginalScale = overlay:GetScale();
			child:Hide();
			return true;
		end
	end
	return false;
end

local function UpdateNameplates()
	RefreshBossGuardianNames();
	local children = { WorldFrame:GetChildren() };
	for i = 1, table.getn(children) do
		local frame = children[i];
		if ( not knownPlates[frame] and IdentifyNameplate(frame) ) then
			knownPlates[frame] = true;
			table.insert(debugPlates, frame);
			local specialPlate = IsBossOrGuardianPlate(frame);
			CaptureNativeState(frame);
			if ( not specialPlate ) then
				-- Restore cached scale only for plates TinyPlates will style.
				local originalScale = frame.astinyplatesOriginalScale or 1;
				frame:SetScale(originalScale);
				frame.astinyplatesOriginalScale = originalScale;
			end
		end
		if ( knownPlates[frame] ) then
			if ( IsBossOrGuardianPlate(frame) ) then
				ApplyPlateStyle(frame);
			elseif ( CreatePlateOverlay(frame) ) then
				ApplyPlateStyle(frame);
			end
		end
	end
end

SLASH_ASTINYPLATESDEBUG1 = "/astpdebug";
local function DumpBossPlates()
	local found = 0;
	for i = 1, table.getn(debugPlates) do
		local frame = debugPlates[i];
		if ( ( frame.astinyplatesBossGuardian or not frame.astinyplatesPlateName ) and frame:IsVisible() ) then
			found = found + 1;
			local label = frame.astinyplatesBossGuardianLabel;
			local lines = {};
			local function Dump(obj, depth)
				local regs = { obj:GetRegions() };
				for r = 1, table.getn(regs) do
					if ( regs[r]:GetObjectType() == "FontString" ) then
						table.insert(lines, string.rep(" ", depth) .. "fs"
							.. (regs[r] == label and "(LABEL)" or "") .. " '"
							.. tostring(regs[r]:GetText()) .. "' a=" .. tostring(regs[r]:GetAlpha())
							.. " shown=" .. tostring(regs[r]:IsShown())
							.. " visible=" .. tostring(regs[r]:IsVisible()));
					end
				end
				local kids = { obj:GetChildren() };
				for k = 1, table.getn(kids) do
					table.insert(lines, string.rep(" ", depth) .. "child " .. kids[k]:GetObjectType()
						.. " shown=" .. tostring(kids[k]:IsShown()) .. " scale=" .. tostring(kids[k]:GetScale()));
					Dump(kids[k], depth + 1);
				end
			end
			Dump(frame, 1);
			DEFAULT_CHAT_FRAME:AddMessage("ASTinyPlates boss " .. found .. ": name="
				.. tostring(frame.astinyplatesPlateName)
				.. " alpha=" .. tostring(frame:GetAlpha())
				.. " shrunk=" .. tostring(IsPlaceholderShrunk(frame))
				.. " styled=" .. tostring(frame.astinyplatesStyledVisual ~= nil)
				.. " overlay=" .. tostring(frame.astinyplatesOverlay ~= nil));
			for l = 1, table.getn(lines) do DEFAULT_CHAT_FRAME:AddMessage(lines[l]); end
		end
	end
	if ( found == 0 ) then
		DEFAULT_CHAT_FRAME:AddMessage("ASTinyPlates: no visible boss/guardian plates");
	end
end

SlashCmdList["ASTINYPLATESDEBUG"] = function(msg)
	if ( msg and string.lower(msg) == "boss" ) then
		DumpBossPlates();
		return;
	end
	DEFAULT_CHAT_FRAME:AddMessage("ASTinyPlates: " .. table.getn(debugPlates) .. " plates detected");
	for i = 1, table.getn(debugPlates) do
		local frame = debugPlates[i];
		local bars = { frame:GetChildren() };
		local point, relativeTo, relativePoint, x, y = frame:GetPoint();
		local centerX, centerY = frame:GetCenter();
		local relativeName = relativeTo and relativeTo.GetName and relativeTo:GetName() or "nil";
		local details = "plate=" .. tostring(frame:GetScale()) .. "x "
			.. tostring(frame:GetWidth()) .. "x" .. tostring(frame:GetHeight())
			.. " anchor=" .. tostring(point) .. "/" .. tostring(relativePoint)
			.. " to=" .. tostring(relativeName) .. " " .. tostring(x) .. "," .. tostring(y)
			.. " center=" .. tostring(centerX) .. "," .. tostring(centerY)
			.. " styled=" .. tostring(frame.astinyplatesStyledVisual ~= nil)
			.. " overlay=" .. tostring(frame.astinyplatesOverlay ~= nil);
		for j = 1, table.getn(bars) do
			if ( bars[j]:GetObjectType() == "StatusBar" ) then
				details = details .. " bar=" .. tostring(bars[j]:GetWidth()) .. "x"
					.. tostring(bars[j]:GetHeight()) .. " scale=" .. tostring(bars[j]:GetScale());
				break;
			end
		end
		DEFAULT_CHAT_FRAME:AddMessage("ASTinyPlates " .. i .. ": " .. details);
		if ( frame.astinyplatesOverlay ) then
			local overlayX, overlayY = frame.astinyplatesOverlay:GetCenter();
			local overlayPoint, overlayRelativeTo, overlayRelativePoint, overlayOffsetX, overlayOffsetY =
				frame.astinyplatesOverlay:GetPoint();
			local overlayRelativeName = overlayRelativeTo and overlayRelativeTo.GetName
				and overlayRelativeTo:GetName() or "nil";
			DEFAULT_CHAT_FRAME:AddMessage("ASTinyPlates overlay: "
				.. frame.astinyplatesOverlay:GetWidth() .. "x"
				.. frame.astinyplatesOverlay:GetHeight()
				.. " scale=" .. tostring(frame.astinyplatesOverlay:GetScale())
				.. " anchor=" .. tostring(overlayPoint) .. "/" .. tostring(overlayRelativePoint)
				.. " to=" .. tostring(overlayRelativeName) .. " "
				.. tostring(overlayOffsetX) .. "," .. tostring(overlayOffsetY)
				.. " center=" .. tostring(overlayX) .. "," .. tostring(overlayY)
				.. " shown=" .. tostring(frame.astinyplatesOverlay:IsShown()));
			DEFAULT_CHAT_FRAME:AddMessage("ASTinyPlates source shown="
				.. tostring(frame.astinyplatesSourceBar:IsShown()));
		end
		if ( frame.astinyplatesStyledVisual ) then
			DEFAULT_CHAT_FRAME:AddMessage("ASTinyPlates styled visual shown="
				.. tostring(frame.astinyplatesStyledVisual:IsShown()));
		end
	end
end

local updater = CreateFrame("Frame");
updater:SetScript("OnUpdate", function()
	UpdateNameplates();
end);
updater:RegisterEvent("PLAYER_ENTERING_WORLD");
updater:RegisterEvent("VARIABLES_LOADED");
updater:RegisterEvent("CHAT_MSG_ADDON");
updater:SetScript("OnEvent", function()
    if ( event == "PLAYER_ENTERING_WORLD" or event == "VARIABLES_LOADED"
            or arg1 == "AZSUNITS" ) then
        RefreshBossGuardianNames(true);
    end
	UpdateNameplates();
end);
