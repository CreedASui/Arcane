-- Damage-number commands: slash commands, Arcane registration and client events.
local AUI = Arcane
local N = AUI.Numbers
N.Commands = N.Commands or {}
local S = N.Commands
local C = N.Config

------------------------------------------------------------------------------
-- Slash commands

AUI.NumbersHelp = function()
	C.Print(C.L("damage number commands:"))
	C.Print(C.L("/Arcane numbers - options window"))
	C.Print(C.L("/Arcane numbers on | off - Arcane UI's numbers or the game's own"))
	C.Print(C.L("/Arcane numbers minimal | clean | detailed - pick a style"))
	C.Print(C.L("/Arcane numbers size 120 - number size in percent (60 to 180)"))
	C.Print(C.L("/Arcane numbers icons - skill icons on or off"))
	C.Print(C.L("/Arcane numbers dots - DoT totals until the enemy dies, on or off"))
	C.Print(C.L("/Arcane numbers crowd - merge a spell hitting 3+ enemies, on or off"))
	C.Print(C.L("/Arcane numbers spells - merge every spell, on or off"))
	C.Print(C.L("/Arcane numbers smooth | fountain | rise | impact - choose how numbers move"))
	C.Print(C.L("/Arcane numbers preview - show some pretend numbers"))
	C.Print(C.L("/Arcane numbers reset - default settings"))
end

AUI.NumbersSlash = function(msg)
	if not C.db then
		C.InitDB()
	end
	local _, _, command, rest = string.find(msg or "", "^%s*(%S*)%s*(.-)%s*$")
	command = string.lower(command or "")
	if command == "" or command == "options" or command == "config" then
		N.Options.ToggleOptions()
	elseif command == "on" then
		N.Lifecycle.SetEnabled(true)
		if N.CombatAPI.active then
			C.Print(C.L("on."))
		end
	elseif command == "off" then
		N.Lifecycle.SetEnabled(false)
		C.Print(C.L("off: the game's own numbers are back."))
	elseif C.PRESETS[command] then
		C.ApplyPreset(command)
		if N.Options.RefreshOptions then
			N.Options.RefreshOptions()
		end
		C.Print(C.L("style: ") .. L(C.PRESET_NAMES[command]) .. ". " .. L(C.PRESET_NOTES[command]))
	elseif C.MOTION_NAMES[command] then
		C.db.motion = command
		N.Options.RefreshOptions()
		C.Print(C.L("number motion: ") .. L(C.MOTION_NAMES[command]) .. ". " .. L(C.MOTION_NOTES[command]))
	elseif command == "size" then
		local value = tonumber(rest)
		if value then
			if value > 3 then
				value = value / 100
			end
			C.db.size = AUI.Clamp(value, 0.6, 1.8)
			N.Options.RefreshOptions()
			C.Print(string.format(C.L("size %d%%."), math.floor(C.db.size * 100 + 0.5)))
		else
			AUI.NumbersHelp()
		end
	elseif command == "dots" or command == "dot" then
		C.db.dotTotals = not C.db.dotTotals
		N.Options.RefreshOptions()
		if C.db.dotTotals then
			C.Print(C.L("DoT totals on: a DoT's damage adds up until its enemy dies."))
		else
			C.Print(C.L("DoT totals off: DoT ticks show like other hits."))
		end
	elseif command == "icons" then
		C.db.icons = not C.db.icons
		N.Options.OnSettingChanged("icons")
		N.Options.RefreshOptions()
		if C.db.icons then
			C.Print(C.L("skill icons on."))
		else
			C.Print(C.L("skill icons off."))
		end
	elseif command == "crowd" or command == "crowds" then
		C.db.crowd = not C.db.crowd
		N.Options.RefreshOptions()
		if C.db.crowd then
			C.Print(C.L("a spell hitting 3 or more enemies now adds up into one number a second."))
		else
			C.Print(C.L("spells on crowds show on each enemy again."))
		end
	elseif command == "spells" or command == "spell" then
		C.db.bySpell = not C.db.bySpell
		N.Options.RefreshOptions()
		if C.db.bySpell then
			C.Print(C.L("every spell now adds up into one number a second."))
		else
			C.Print(C.L("spells show on each enemy again (spells on crowds still merge if that's on)."))
		end
	elseif command == "preview" or command == "test" then
		N.Preview.StartTest()
	elseif command == "reset" then
		for key, value in pairs(C.DEFAULTS) do
			if key ~= "enabled" then
				C.db[key] = value
			end
		end
		N.Widgets.ApplyFontAll()
		N.Widgets.RefreshAllText()
		N.Options.RefreshOptions()
		C.Print(C.L("settings reset."))
	else
		AUI.NumbersHelp()
	end
end

AUI.numberSlash = function(msg)
	if N.Lifecycle.blocked then
		C.Print(C.L("Smooth Numbers is still on, so it draws the numbers. Turn it off in Options -> AddOns."))
		return
	end
	AUI.NumbersSlash(msg)
end
AUI.numberOptions = function()
	AUI.numberSlash("")
end
SLASH_ARCANENUMBERS1 = "/sn"
SlashCmdList["ARCANENUMBERS"] = AUI.numberSlash

AUI.RegisterPart({
	key = "numbers", name = "Damage numbers",
	note = "Your hits as calm numbers with the skill's icon. A spell hitting 3+ enemies adds up into one number a second.",
	get = function() return C.db and C.db.enabled and not N.Lifecycle.blocked end,
	set = function(on) if C.db and not N.Lifecycle.blocked then N.Lifecycle.SetEnabled(on) end end,
	getScale = function() return C.db and C.db.size or 1 end,
	setScale = function(v)
		if C.db then
			C.db.size = AUI.Clamp(v, 0.6, 1.8)
			if N.Options.RefreshOptions then N.Options.RefreshOptions() end
		end
	end,
})

------------------------------------------------------------------------------
-- Events

local driver = CreateFrame("Frame", "ArcaneNumbersDriver")
driver:RegisterEvent("VARIABLES_LOADED")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("PLAYER_LEAVING_WORLD")
driver:RegisterEvent("PLAYER_LOGOUT")

driver:SetScript("OnEvent", function(self, eventArg, argument)
	local name = eventArg or event
	local first = argument or arg1
	if name == "VARIABLES_LOADED" then
		if not C.db then
			C.InitDB()
		end
		N.Lifecycle.blocked = AUI.OldAddon("SmoothNumbers") -- the old addon draws the numbers then
	elseif name == "PLAYER_ENTERING_WORLD" then
		if not C.db then
			C.InitDB()
			N.Lifecycle.blocked = AUI.OldAddon("SmoothNumbers")
		end
		N.Lifecycle.lastNow = nil
		if C.db.enabled and not N.Lifecycle.blocked then
			N.Lifecycle.Activate()
		end
	elseif name == "PLAYER_LEAVING_WORLD" then
		N.Combat.ClearAll()
		N.CombatAPI.cursor = nil
	elseif name == "PLAYER_LOGOUT" then
		-- Give the game its numbers back as it closes, so removing the addon
		-- leaves them on; they are switched off again at the next start.
		if C.db and N.CombatAPI.active then
			N.Lifecycle.ShowGameNumbers()
		end
	end
end)

-- If the game isn't calling our frame handler (the preview while off, or a
-- handler the game dropped), the numbers move from here instead, and the
-- handler is asked for again now and then.
driver.nextRegisterTry = 0
driver:SetScript("OnUpdate", function()
	if not C.db or N.Lifecycle.blocked then
		return
	end
	local now = GetTime()
	if N.Lifecycle.giveUp then
		N.Lifecycle.giveUp = false
		N.Lifecycle.errors = 0
		C.Print(C.L("too many problems, so it switched itself off and gave the game its numbers back. /Arcane numbers on to try again."))
		N.Lifecycle.SetEnabled(false)
		return
	end
	if now - N.Lifecycle.handlerAt <= 0.25 then
		return
	end
	if N.CombatAPI.active or N.Combat.nLabels > 0 or N.Preview.testUntil then
		N.Lifecycle.SafeStep(now)
	end
	if N.CombatAPI.active and now - N.Lifecycle.handlerAt > 1 and now >= driver.nextRegisterTry then
		driver.nextRegisterTry = now + 5
		local ok, result, failure = pcall(AZS_RegisterCombatTextFrameHandler, N.Lifecycle.OnFrame)
		if ok and failure == nil and result ~= false then
			N.CombatAPI.registered = true
		end
	end
end)
