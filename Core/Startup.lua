-- Addon initialization, world/logout lifecycle and stock pause-menu guard.
local C = Arcane

------------------------------------------------------------------------ start up
local core = CreateFrame("Frame", "ArcaneCore")
local started = false
core:RegisterEvent("ADDON_LOADED")
core:RegisterEvent("VARIABLES_LOADED")
core:RegisterEvent("PLAYER_ENTERING_WORLD")
core:RegisterEvent("PLAYER_LOGOUT")
core:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" or event == "VARIABLES_LOADED" then
		if (event == "VARIABLES_LOADED" or arg1 == "Arcane") and not started then
			started = true
			local root = C.Root()
			C.SetLanguage(root.lang or C.DetectLanguage())
			for i = 1, table.getn(C.inits) do
				local ok, err = pcall(C.inits[i])
				if not ok then C.Print(C.L("error while starting: ") .. tostring(err)) end
			end
			-- the two addons Arcane UI grew out of would draw everything twice
			local old = {}
			if type(IsAddOnLoaded) == "function" then
				if IsAddOnLoaded("SmoothNumbers") then table.insert(old, "Smooth Numbers") end
				if IsAddOnLoaded("SmoothBossTimer") then table.insert(old, "Smooth Boss Timer") end
			end
			if table.getn(old) > 0 then
				C.Print(C.F("{1} are part of Arcane UI now. Turn them off in Options -> AddOns; until then Arcane UI leaves that part to them.",
					table.concat(old, C.L(" and "))))
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		for i = 1, table.getn(C.worlds) do pcall(C.worlds[i]) end
		pcall(C.KeepOverCards, true)
	elseif event == "PLAYER_LOGOUT" then
		for i = 1, table.getn(C.logouts) do pcall(C.logouts[i]) end
	end
end)
------------------------------------------------------------------------ the old game menu
-- On the game's own Paused screen, Escape resumes the run, but the same key also reaches the
-- stock 1.12 game menu, which then pops up over the game. That menu is put away again when it
-- opens while the run is paused (or just was). Out of a run it opens as usual.
local menu = { pausedAt = -10, hideNext = false, done = false }

local function Paused()
	if type(AZS_GetPhase) ~= "function" then return false end
	local ok, phase = pcall(AZS_GetPhase)
	return ok and phase == "paused"
end

local function GuardGameMenu()
	if menu.done or type(GameMenuFrame) ~= "table" or type(GameMenuFrame.GetScript) ~= "function" then return end
	menu.done = true
	local old = GameMenuFrame:GetScript("OnShow")
	GameMenuFrame:SetScript("OnShow", function()
		if old then old() end
		if Paused() or GetTime() - menu.pausedAt < 0.6 then
			GameMenuFrame:SetAlpha(0) -- unseen until it's closed, next frame
			menu.hideNext = true
		end
	end)
	local watch = CreateFrame("Frame", "ArcaneMenuGuard")
	watch:SetScript("OnUpdate", function()
		if Paused() then menu.pausedAt = GetTime() end
		if menu.hideNext then
			menu.hideNext = false
			if GameMenuFrame:IsShown() then
				if type(HideUIPanel) == "function" then
					pcall(HideUIPanel, GameMenuFrame)
				end
				if GameMenuFrame:IsShown() then GameMenuFrame:Hide() end
			end
			GameMenuFrame:SetAlpha(1)
		end
	end)
end
C.OnInit(function() pcall(GuardGameMenu) end)

-- The client still ships WoW's bag bindings, but Azeroth Survivors has no bag system.
-- Suppress B only when it is actually assigned to opening a bag; leave every other B binding
-- alone. Do not save the changed map: Arcane reapplies this while loaded, without overwriting
-- the player's saved key configuration.
local BAG_BINDINGS = {
	TOGGLEBACKPACK = true, OPENALLBAGS = true,
	TOGGLEBAG1 = true, TOGGLEBAG2 = true, TOGGLEBAG3 = true, TOGGLEBAG4 = true,
}
local function RemoveUnusedBackpackKey()
	if type(GetBindingAction) ~= "function" or type(SetBinding) ~= "function" then return end
	local ok, action = pcall(GetBindingAction, "B")
	if not ok or not BAG_BINDINGS[action] then return end
	pcall(SetBinding, "B")
end
C.OnWorld(RemoveUnusedBackpackKey)

-- is the addon this part grew out of still running? then that part stays off
function C.OldAddon(name)
	return type(IsAddOnLoaded) == "function" and IsAddOnLoaded(name) and true or false
end
