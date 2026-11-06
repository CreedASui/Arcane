local AUI = Arcane
AUI.Numbers = AUI.Numbers or {}
local N = AUI.Numbers
N.Config = N.Config or {}
N.Widgets = N.Widgets or {}
N.Combat = N.Combat or {}
N.Icons = N.Icons or {}
N.CombatAPI = N.CombatAPI or {}
N.Preview = N.Preview or {}
N.Anchors = N.Anchors or {}
N.Layout = N.Layout or {}
N.Culling = N.Culling or {}
N.Placement = N.Placement or {}
N.Animation = N.Animation or {}
N.Lifecycle = N.Lifecycle or {}
N.Options = N.Options or {}
N.Commands = N.Commands or {}
local C = N.Config
--[[
Arcane UI: damage numbers (Smooth Numbers) - calmer, cleaner damage numbers for Azeroth Survivors.

The game gives addons every hit you deal, with a place in the world to draw it
(its world-anchored combat text API). Smooth Numbers turns the game's own
floating numbers off and draws its own in their place:

  - the hits on one enemy add up into one number that counts up
  - the skill's icon beside each number (then each number is one skill's)
  - a DoT's ticks add up in one number until its enemy dies
  - big numbers are shortened: 12.3K, 1.2M
  - when the screen gets busy only the biggest numbers show
  - numbers that would overlap step aside, or quietly drop out
  - a soft pop, a slow drift, and a smooth melt instead of flying text: every
    fade, push and move is eased (no number ever blinks out or jumps)

A spell hitting a crowd (three or more enemies) adds up into one number a
second over the middle of the enemies it hits; on one or two enemies its hits
show as usual (a DoT's total counting up until the enemy dies).

/Arcane numbers opens the options. /Arcane numbers off gives the game its own
numbers back.

Written for the 1.12 client's Lua 5.0: no # operator, no string methods,
table.getn and math.mod, and the this/event/arg1 globals in handlers.
]]

-- the words in the language picked (Core); as they are when run on their own
C.L = AUI.L or function(s) return s end
C.LText = AUI.LText or function(fs, s) fs:SetText(s) end
C.VERSION = AUI.VERSION

------------------------------------------------------------------------------
-- Look and timing

C.FONT_SIZE = 24             -- every number is drawn at this size, then scaled
C.FLAT = "Interface\\ChatFrame\\ChatFrameBackground"

C.FADE_IN = 0.1              -- seconds to appear
C.HOLD = 0.5                 -- a number stays this long after its last hit
C.FADE_OUT = 0.55            -- then floats up and melts away this long
C.CULL_FADE = 0.3            -- a number pushed out (or slipping away) melts this long
C.CROWD_FADE = 0.18          -- one boxed in by others melts quicker, as it overlaps
C.SPRING = 14                -- how briskly a number steps aside (a soft spring)
C.POP_SPRING = 28            -- how briskly a hit's punch swells in
C.EDGE_FADE = 0.2            -- a number leaving (or coming back into) the view
C.POP_TIME = 0.18            -- the pop when a number appears
C.MAX_AGE = 4.6              -- the game keeps a hit's place for 5 seconds
C.STALE = 0.6                -- hits older than this when read are skipped
C.BASE_RISE = 16             -- a number starts this far over the enemy
C.DRIFT = 22                 -- and drifts up this much while it lives
C.FADE_RISE = 18             -- and this much more as it fades, gathering pace
C.FADE_SHRINK = 0.12         -- and shrinks this much as it fades
C.CULL_SHRINK = 0.15         -- a number pushed out shrinks this much as it goes
C.GROUP_RADIUS = 70          -- "one number per group": hits this close share one
C.CROWD_TIME = 0.06          -- a number boxed in this long fades out
C.MIN_SHOW = 0.5             -- once shown, a number stays at least this long
C.ICON_SIZE = 22             -- the skill icon, in the number's own units
C.ICON_GAP = 4               -- between the icon and the number
C.DOT_FIRST_HOLD = 3.4       -- a DoT's number waits this long for the next tick at first
C.DOT_MAX_HOLD = 3.9         -- and never longer (the game keeps a hit's place 5 s)
C.KILL_HOLD = 1.2            -- a DoT's total stays this long once its enemy dies
C.KILL_GRACE = 0.4           -- ticks read just after the death still count
C.CROWD_COUNT = 3            -- a spell hitting this many enemies at once merges
C.CROWD_TICK = 3.2           -- an enemy counts this long after a DoT's tick on it
C.CROWD_HIT = 1.6            -- and this long after any other hit
C.MERGE_WINDOW = 1.0         -- a merged number takes one second of its spell's hits
C.MAX_SPOTS = 12             -- the enemies a merged number centers over
-- Keep stack-sizing controls together; the layout code reads this shared tuning record.
C.STACK = { shrink = 0.88, grow = 0.35, time = 1.5 }

-- Icons for hits that come without one: a swing shows the weapon in hand, a
-- shot the ranged one, a damage shield Thorns (read from your gear when it can).
C.MELEE_ICON = "Interface\\Icons\\INV_Sword_04"
C.SHOT_ICON = "Interface\\Icons\\Ability_Whirlwind"
C.SHIELD_ICON = "Interface\\Icons\\Spell_Nature_Thorns"

C.FONTS = {
	{ name = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
	{ name = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
	{ name = "Skurri", path = "Fonts\\SKURRI.TTF" },
	{ name = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
}

C.COLOR_NORMAL = { 1.00, 0.96, 0.88 }
C.COLOR_CRIT = { 1.00, 0.80, 0.18 }
C.COLOR_DOT = { 0.86, 0.84, 0.80 }
C.COLOR_MISS = { 0.70, 0.70, 0.72 }
C.SCHOOL_COLORS = {
	[1] = { 1.00, 0.96, 0.88 },  -- Physical
	[2] = { 1.00, 0.92, 0.55 },  -- Holy
	[4] = { 1.00, 0.55, 0.22 },  -- Fire
	[8] = { 0.50, 1.00, 0.42 },  -- Nature
	[16] = { 0.52, 0.84, 1.00 }, -- Frost
	[32] = { 0.74, 0.52, 1.00 }, -- Shadow
	[64] = { 1.00, 0.58, 1.00 }, -- Arcane
}

-- The three styles. Picking one sets these; the switches can then be changed.
C.PRESETS = {
	minimal = { maxLabels = 6, group = true, mergeAge = 1.2, misses = false, minShare = 0.12 },
	clean = { maxLabels = 12, group = false, mergeAge = 0.9, misses = false, minShare = 0 },
	detailed = { maxLabels = 20, group = false, mergeAge = 0.5, misses = true, minShare = 0 },
}
C.PRESET_ORDER = { "minimal", "clean", "detailed" }
C.PRESET_NAMES = { minimal = "Minimal", clean = "Clean", detailed = "Detailed" }
C.PRESET_NOTES = {
	minimal = "Fewest numbers: nearby enemies share one.",
	clean = "One number per enemy, counting up.",
	detailed = "More numbers, sooner, plus Miss and Immune.",
}
C.MOTION_ORDER = { "smooth", "fountain", "rise", "impact" }
C.MOTION_NAMES = { smooth = "Smooth", fountain = "Fountain", rise = "Rise", impact = "Impact" }
C.MOTION_NOTES = {
	smooth = "Numbers drift up gently and melt away.",
	fountain = "Numbers arc up and fall away to the side.",
	rise = "Numbers scroll straight up, quickly.",
	impact = "Numbers punch in big and stay put; crits shake.",
}

C.DEFAULTS = {
	enabled = true,
	preset = "clean", motion = "smooth",
	maxLabels = 12, group = false, mergeAge = 0.9, misses = false, minShare = 0,
	size = 1.0, font = 1,
	short = true, spread = true, count = false, school = false, icons = true,
	dotTotals = true, crowd = true, bySpell = false,
}

C.db = nil -- ArcaneDB.numbers, set up when the addon loads

------------------------------------------------------------------------------
-- Small helpers

C.Print = function(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc55Arcane UI|r " .. C.L("numbers") .. ": " .. msg)
	end
end

-- Math helpers are shared with Core.lua; there is one implementation of each.


C.Capitalize = function(word)
	word = tostring(word or "")
	return string.upper(string.sub(word, 1, 1)) .. string.sub(word, 2)
end

-- 1234567 -> "1,234,567" (%.0f, as %d overflows past two billion)
local function Commas(n)
	local s = string.format("%.0f", math.floor(n + 1e-6))
	local len = string.len(s)
	if len <= 3 then
		return s
	end
	local head = math.mod(len, 3)
	if head == 0 then
		head = 3
	end
	local out = string.sub(s, 1, head)
	local i = head + 1
	while i <= len do
		out = out .. "," .. string.sub(s, i, i + 2)
		i = i + 3
	end
	return out
end

-- 950 -> "950", 1234 -> "1.2K", 12345 -> "12.3K", 123456 -> "123K", 1234567 -> "1.2M".
-- Rounded down, so a number counting up never shows more than it holds.
local UNITS = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }

local function Short(n)
	for i = 1, 4 do
		local unit = UNITS[i]
		if n >= unit[1] then
			local v = n / unit[1]
			if v >= 100 then
				return string.format("%.0f", math.floor(v + 1e-6)) .. unit[2]
			end
			v = math.floor(v * 10 + 1e-6) / 10
			local text = string.format("%.1f", v)
			if string.sub(text, -2) == ".0" then
				text = string.sub(text, 1, -3)
			end
			return text .. unit[2]
		end
	end
	return string.format("%.0f", math.floor(n + 1e-6))
end

C.FormatAmount = function(n)
	if n < 0 then
		n = 0
	end
	if C.db and C.db.short == false then
		return Commas(n)
	end
	return Short(n)
end

------------------------------------------------------------------------------
-- Settings

C.InitDB = function()
	C.db = AUI.DB("numbers")
	for key, value in pairs(C.DEFAULTS) do
		if C.db[key] == nil or type(C.db[key]) ~= type(value) then
			C.db[key] = value
		end
	end
	if not C.PRESETS[C.db.preset] then
		C.db.preset = "clean"
	end
	C.db.size = AUI.Clamp(C.db.size, 0.6, 1.8)
	if not C.MOTION_NAMES[C.db.motion or ""] then C.db.motion = "smooth" end
	C.db.maxLabels = AUI.Clamp(math.floor(C.db.maxLabels), 1, 80)
	C.db.mergeAge = AUI.Clamp(C.db.mergeAge, 0.1, 2)
	C.db.minShare = AUI.Clamp(C.db.minShare, 0, 0.9)
	if not C.FONTS[C.db.font] then
		C.db.font = 1
	end
end

C.ApplyPreset = function(name)
	local preset = C.PRESETS[name]
	if not preset then
		return
	end
	for key, value in pairs(preset) do
		C.db[key] = value
	end
	C.db.preset = name
end

------------------------------------------------------------------------------
