-- Arcane UI: reversible controls for the game's own error/notification feed.
-- The stock frame keeps receiving its normal events; this only controls whether it is visible.
local C = Arcane
local DEFAULTS = { enabled = true }
local db

local function Apply()
	if not db then return end
	if db.enabled then
		C.RestoreStock("UIErrorsFrame")
	else
		C.HideStock("UIErrorsFrame")
	end
end

C.OnInit(function()
	db = C.DB("stockErrors", DEFAULTS)
	local frame = getglobal("UIErrorsFrame")
	if type(frame) == "table" then
		C.Movable(frame, "stockErrors", "Stock error messages", function(f)
			f:ClearAllPoints()
			local bosses = getglobal("ArcaneBosses")
			if type(bosses) == "table" then
				-- The reset/default position belongs immediately beneath Arcane's boss stack.
				f:SetPoint("TOP", bosses, "BOTTOM", 0, -22)
			else
				f:SetPoint("TOP", UIParent, "TOP", 0, -122)
			end
		end)
	end
	Apply()
end)

C.OnWorld(Apply)

C.OnLogout(function()
	-- Do not leave the game's own frame parented under Arcane's hidden container at logout.
	if db and not db.enabled then C.RestoreStock("UIErrorsFrame") end
end)

C.RegisterPart({
	key = "errors",
	name = "Stock error messages",
	note = "The game's original red errors, yellow notices and colored system messages. Turn it off to compare without them; use Move frames to reposition it.",
	get = function() return db and db.enabled end,
	set = function(on)
		if not db then return end
		db.enabled = on and true or false
		Apply()
	end,
})
