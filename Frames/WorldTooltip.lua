-- Suppress the game's persistent default-anchored world-hover information panel.
-- World units, corpses and world objects use GameTooltip_SetDefaultAnchor, which marks
-- GameTooltip.default. Ordinary control tooltips use their own anchors and remain available.
-- This file is deliberately standalone: it must not depend on Arcane's initialization table.
local function HideDefaultTooltip()
	if GameTooltip and GameTooltip.default and GameTooltip:IsShown() then
		GameTooltip:Hide()
	end
end

local function ChainTooltipScript(scriptName)
	if not GameTooltip or type(GameTooltip.GetScript) ~= "function"
			or type(GameTooltip.SetScript) ~= "function" then return end
	local previous = GameTooltip:GetScript(scriptName)
	GameTooltip:SetScript(scriptName, function()
		if previous then previous() end
		HideDefaultTooltip()
	end)
end

if GameTooltip then
	-- The native default-anchor script sets GameTooltip.default before this wrapper hides it.
	ChainTooltipScript("OnTooltipSetDefaultAnchor")
	-- Also catch clients/addons which show a tooltip after setting the default anchor.
	ChainTooltipScript("OnShow")
end
