-- Damage-number looks: the letters, colors and crit backdrop each number wears.
local AUI = Arcane
local N = AUI.Numbers
local S = N.Looks
local C = N.Config

------------------------------------------------------------------------------
-- A look dresses every number in its own way (the looks themselves are in Numbers.lua's
-- C.LOOKS). "Custom" is no look: then each answer here is the player's own pick (the font, the
-- crit backdrop, the school colors switch), exactly as it was before there were looks.
--
-- What a look can do that the picks alone cannot:
--   - a crit in letters of its own (Grim: gothic hits, dripping crits)
--   - every spell school in its own color, and each school's crit in that school's own
--     letters, colors and backdrop (Elemental: a fire crit bursts in flame, a frost one in ice)
--   - a crit that shimmers between two colors, landing white-hot in a flash of light
--   - hits that glow hotter the harder they land (Comic)

local fontAt = {}                         -- a font's place in C.FONTS, by its name
local SCHOOLS = { 64, 32, 16, 8, 4, 2, 1 } -- arcane, shadow, frost, nature, fire, holy, physical
local LAND = 0.22                         -- a crit lands white-hot and takes its colors this fast

S.typical = nil -- how hard a usual hit lands lately; a look's harder hits glow hotter than this

-- the look worn now; nil for Custom, the player's own picks
S.Current = function()
	if not C.db then
		return nil
	end
	return C.LOOKS.looks[C.db.look or "custom"]
end

local function FontAt(name)
	if not name then
		return nil
	end
	local at = fontAt[name]
	if at == nil then
		at = false
		for i = 1, table.getn(C.FONTS) do
			if C.FONTS[i].name == name then
				at = i
				break
			end
		end
		fontAt[name] = at
	end
	return at or nil
end

-- A hit's school: its mask when that is one school, else the highest school in the mask.
local function SchoolOf(mask)
	if type(mask) ~= "number" then
		return nil
	end
	if C.SCHOOL_COLORS[mask] then
		return mask
	end
	local left = math.mod(math.floor(mask), 128)
	for i = 1, 7 do
		if left >= SCHOOLS[i] then
			return SCHOOLS[i]
		end
	end
	return nil
end

-- what a look keeps for a number's school (a hit of no known school goes as a physical one)
local function SchoolLook(look, label)
	if not look.schools then
		return nil
	end
	return look.schools[SchoolOf(label.school) or 1] or look.schools[1]
end

-- How far a hit glows toward the look's hot color: nothing for a usual hit, all the way for one
-- several times as hard. A number is measured against what was usual when it first showed, so
-- it only warms as its own total climbs.
local function Heat(label)
	local total = label.total or 0
	if not label.heatBase then
		local typical = S.typical or total
		label.heatBase = typical
		S.typical = typical + (total - typical) * 0.08
	end
	if label.heatBase <= 0 then
		return 0
	end
	return AUI.Smooth((total / label.heatBase - 1.3) / 2.2)
end

-- The letters a number is drawn in: a font's place in C.FONTS.
S.Font = function(label)
	local look = S.Current()
	if not look then
		return C.db.font
	end
	local name = look.font
	if label.crit and not label.miss then
		local school = SchoolLook(look, label)
		name = (school and school.font) or look.critFont or name
	end
	return FontAt(name) or C.db.font
end

-- The color a number is heading for now: red, green, blue.
S.Color = function(label, now)
	local look = S.Current()
	local color
	if label.miss then
		color = C.COLOR_MISS
	elseif not look then
		-- Custom: gold crits, school colors if switched on, a DoT's ticks a little grey
		if label.crit then
			color = C.COLOR_CRIT
		elseif C.db.school and label.school and C.SCHOOL_COLORS[label.school] then
			color = C.SCHOOL_COLORS[label.school]
		elseif not label.direct and not label.finished then
			color = C.COLOR_DOT
		else
			color = C.COLOR_NORMAL
		end
	elseif label.crit then
		-- A crit shimmers between its two colors, each number in its own time: crits landing
		-- together (a spell's crits on a crowd) shimmer out of step, not in lockstep.
		local school = SchoolLook(look, label)
		local pair = (school and school.crit) or look.crit
		local a, b = pair[1], pair[2]
		local wave = 0.5 + 0.5 * math.sin(now * (look.pulse or 6) + (label.id or 0) * 2.4)
		local red, green, blue = a[1] + (b[1] - a[1]) * wave, a[2] + (b[2] - a[2]) * wave, a[3] + (b[3] - a[3]) * wave
		-- and lands white-hot
		local since = now - (label.critAt or now)
		if since < LAND then
			local k = AUI.Smooth(since / LAND)
			red, green, blue = 1 + (red - 1) * k, 1 + (green - 1) * k, 1 + (blue - 1) * k
		end
		return red, green, blue
	else
		local school = (look.schools or C.db.school) and SchoolOf(label.school)
		if school and C.SCHOOL_COLORS[school] then
			color = C.SCHOOL_COLORS[school]
		elseif not label.direct and not label.finished then
			color = look.dot or C.COLOR_DOT
		else
			color = look.normal or C.COLOR_NORMAL
			if look.heat then
				local heat = Heat(label)
				if heat > 0 then
					local hot = look.heat
					return color[1] + (hot[1] - color[1]) * heat, color[2] + (hot[2] - color[2]) * heat,
						color[3] + (hot[3] - color[3]) * heat
				end
			end
		end
	end
	return color[1], color[2], color[3]
end

-- A crit's backdrop: its art's name (nil for none), and a color to tint it with (or nil).
S.Backdrop = function(label)
	if not label.crit then
		return nil
	end
	local look = S.Current()
	if not look then
		return C.CRIT_BACKDROPS.tex[C.db.backdrop or "none"]
	end
	local school = SchoolLook(look, label)
	local key = (school and school.back) or look.back
	if not key then
		return nil
	end
	return C.CRIT_BACKDROPS.tex[key], school and school.tint or nil
end

-- How large a crit is drawn beside a plain hit.
S.CritScale = function()
	local look = S.Current()
	return look and look.critScale or 1.15
end

-- The color of the flash of light a look's crit lands in (nothing for a look without one): its
-- crit color, more than half way to white, so it reads as a flash over any backdrop.
local FLASH_WHITE = 0.55
S.Flash = function(label)
	local look = S.Current()
	if not (look and look.flash and label.crit) then
		return nil
	end
	local school = SchoolLook(look, label)
	local pair = (school and school.crit) or look.crit
	if not pair then
		return nil
	end
	local c = pair[1]
	return c[1] + (1 - c[1]) * FLASH_WHITE, c[2] + (1 - c[2]) * FLASH_WHITE, c[3] + (1 - c[3]) * FLASH_WHITE
end
