-- Arcane UI: the game's gameplay notification feed, using the active UX text palette.
-- Keep the native MessageFrame transparent and intact. Arcane owns its saved position,
-- visibility switch, font treatment and the color used for each new message.
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

local function ThemeFont(frame)
	if type(frame.GetFont) ~= "function" or type(frame.SetFont) ~= "function" then return end
	local _, size = frame:GetFont()
	if type(size) ~= "number" or size <= 0 then size = 16 end
	local face = type(C.Face) == "function" and C.Face(C.FONT) or C.FONT
	pcall(frame.SetFont, frame, face, size, "OUTLINE")
end

C.OnInit(function()
	db = C.DB("stockErrors", DEFAULTS)
	local frame = getglobal("UIErrorsFrame")
	if type(frame) ~= "table" then return end

	C.Movable(frame, "stockErrors", "Stock error messages", function(f)
		f:ClearAllPoints()
		-- Keep the default centered near the game's "Move to Begin" prompt.
		-- The saved Arcane mover position takes over as soon as the user drags it.
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
	end)

	-- The stock red/yellow values describe game message categories, not Lua errors.
	-- Gameplay notices (including chest costs and boss mechanics) all share this feed;
	-- actual Lua script errors use a separate window. Resolve the active UX palette for
	-- each message so Arcane, Hybrid and Full Class modes are all honored immediately.
	local nativeAddMessage = frame.AddMessage
	if type(nativeAddMessage) == "function" then
		frame.AddMessage = function(self, message, red, green, blue, alpha)
			ThemeFont(self)
			local title = C.Pal().title
			return nativeAddMessage(self, message, title[1], title[2], title[3], alpha)
		end
	end

	ThemeFont(frame)
	Apply()
end)

C.OnWorld(function()
	Apply()
end)

C.OnLogout(function()
	-- Do not leave the game's own frame parented under Arcane's hidden container at logout.
	if db and not db.enabled then C.RestoreStock("UIErrorsFrame") end
end)

C.RegisterPart({
	key = "errors",
	name = "Stock error messages",
	note = "The game's original gameplay messages, using the active text theme. Turn it off to compare without them; use Move frames to reposition it.",
	get = function() return db and db.enabled end,
	set = function(on)
		if not db then return end
		db.enabled = on and true or false
		Apply()
	end,
})
