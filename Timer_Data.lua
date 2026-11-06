-- Arcane Timer data: zone themes, fallback schedules, and particle motifs.
-- Keep zone-specific variations here as data; Timer.lua owns the behavior.
local AUI = Arcane

------------------------------------------------------------------------ themes
-- Colors are { r, g, b }. fillA -> fillM -> fillB run along the fill, glow lights its head and
-- flowing light, gem colors the boss markers, rim tints the metal, mc colors the particles.
local THEMES = {
	default = {
		name = "Azeroth", sub = "",
		title = { 1.00, 0.84, 0.40 }, rim = { 0.95, 0.80, 0.46 },
		fillA = { 0.08, 0.18, 0.46 }, fillM = { 0.20, 0.44, 0.88 }, fillB = { 0.56, 0.80, 1.00 },
		glow = { 0.72, 0.88, 1.00 }, gem = { 1.00, 0.80, 0.30 }, trough = { 0.03, 0.04, 0.08 },
		motif = "motes", mc = { 0.75, 0.88, 1.00 },
	},
	elwynn = {
		name = "Elwynn Forest", sub = "The Defias Uprising",
		title = { 1.00, 0.85, 0.42 }, rim = { 1.00, 0.80, 0.42 },
		fillA = { 0.10, 0.34, 0.09 }, fillM = { 0.36, 0.64, 0.15 }, fillB = { 0.90, 0.88, 0.34 },
		glow = { 1.00, 0.94, 0.60 }, gem = { 0.95, 0.27, 0.20 }, trough = { 0.04, 0.07, 0.03 },
		motif = "fireflies", mc = { 1.00, 0.88, 0.45 },
	},
	duskwood = {
		name = "Duskwood", sub = "Night of the Nightbane",
		title = { 0.82, 0.82, 1.00 }, rim = { 0.76, 0.78, 0.90 },
		fillA = { 0.12, 0.08, 0.30 }, fillM = { 0.28, 0.24, 0.66 }, fillB = { 0.62, 0.64, 1.00 },
		glow = { 0.80, 0.85, 1.00 }, gem = { 1.00, 0.70, 0.24 }, trough = { 0.04, 0.03, 0.08 },
		motif = "mist", mc = { 0.70, 0.68, 1.00 },
	},
	wsg = {
		name = "Warsong Gulch", sub = "The Burning Legion",
		title = { 0.66, 1.00, 0.32 }, rim = { 0.58, 0.68, 0.36 },
		fillA = { 0.05, 0.20, 0.02 }, fillM = { 0.24, 0.62, 0.06 }, fillB = { 0.72, 1.00, 0.18 },
		glow = { 0.80, 1.00, 0.40 }, gem = { 0.78, 0.34, 1.00 }, trough = { 0.02, 0.05, 0.01 },
		motif = "fel", mc = { 0.55, 1.00, 0.25 },
	},
	ungoro = {
		name = "Un'Goro Crater", sub = "The Primal Hunt",
		title = { 0.58, 1.00, 0.72 }, rim = { 0.88, 0.80, 0.62 },
		fillA = { 0.02, 0.22, 0.18 }, fillM = { 0.08, 0.55, 0.38 }, fillB = { 0.52, 0.98, 0.60 },
		glow = { 0.76, 1.00, 0.76 }, gem = { 1.00, 0.54, 0.16 }, trough = { 0.01, 0.06, 0.04 },
		motif = "spores", mc = { 0.82, 1.00, 0.45 },
	},
	ab = {
		name = "Arathi Basin", sub = "The Highlands Rise",
		title = { 0.84, 0.90, 1.00 }, rim = { 0.78, 0.78, 0.76 },
		fillA = { 0.08, 0.14, 0.36 }, fillM = { 0.20, 0.38, 0.72 }, fillB = { 0.58, 0.78, 1.00 },
		glow = { 0.84, 0.92, 1.00 }, gem = { 1.00, 0.80, 0.30 }, trough = { 0.02, 0.03, 0.08 },
		motif = "wind", mc = { 1.00, 0.90, 0.66 },
	},
	feralas = {
		name = "Feralas", sub = "The Gates of Dire Maul",
		title = { 0.92, 0.70, 1.00 }, rim = { 0.84, 0.76, 0.56 },
		fillA = { 0.03, 0.16, 0.26 }, fillM = { 0.30, 0.32, 0.70 }, fillB = { 0.94, 0.50, 0.96 },
		glow = { 1.00, 0.76, 1.00 }, gem = { 0.38, 1.00, 0.54 }, trough = { 0.02, 0.04, 0.06 },
		motif = "leaves", mc = { 0.42, 0.86, 0.46 },
	},
	arena = {
		name = "Gurubashi Arena", sub = "The Blood God Wakes",
		title = { 1.00, 0.54, 0.50 }, rim = { 0.94, 0.72, 0.34 },
		fillA = { 0.26, 0.01, 0.06 }, fillM = { 0.62, 0.04, 0.16 }, fillB = { 1.00, 0.26, 0.38 },
		glow = { 1.00, 0.56, 0.60 }, gem = { 0.38, 1.00, 0.58 }, trough = { 0.07, 0.01, 0.02 },
		motif = "blood", mc = { 1.00, 0.22, 0.26 },
	},
	sm = {
		name = "Scarlet Monastery", sub = "The Crusade's Last Stand",
		title = { 1.00, 0.88, 0.62 }, rim = { 0.98, 0.92, 0.78 },
		fillA = { 0.34, 0.02, 0.02 }, fillM = { 0.78, 0.10, 0.08 }, fillB = { 1.00, 0.48, 0.24 },
		glow = { 1.00, 0.90, 0.62 }, gem = { 1.00, 0.80, 0.30 }, trough = { 0.06, 0.01, 0.01 },
		motif = "holy", mc = { 1.00, 0.92, 0.66 },
	},
	av = {
		name = "Alterac Valley", sub = "The Frozen Wilds",
		title = { 0.84, 0.95, 1.00 }, rim = { 0.82, 0.90, 0.98 },
		fillA = { 0.05, 0.16, 0.36 }, fillM = { 0.22, 0.52, 0.86 }, fillB = { 0.82, 0.96, 1.00 },
		glow = { 0.88, 0.97, 1.00 }, gem = { 0.58, 0.86, 1.00 }, trough = { 0.02, 0.04, 0.08 },
		motif = "snow", mc = { 0.95, 0.98, 1.00 },
	},
	brm = {
		name = "Blackrock Mountain", sub = "The Lord of Blackrock",
		title = { 1.00, 0.68, 0.32 }, rim = { 0.64, 0.56, 0.50 },
		fillA = { 0.26, 0.03, 0.00 }, fillM = { 0.72, 0.18, 0.02 }, fillB = { 1.00, 0.60, 0.12 },
		glow = { 1.00, 0.78, 0.36 }, gem = { 0.82, 0.44, 1.00 }, trough = { 0.06, 0.02, 0.00 },
		motif = "embers", mc = { 1.00, 0.56, 0.16 },
	},
	scholomance = {
		name = "Scholomance", sub = "The Great Ossuary",
		title = { 0.86, 0.96, 0.78 }, rim = { 0.80, 0.82, 0.74 },
		fillA = { 0.06, 0.12, 0.08 }, fillM = { 0.26, 0.48, 0.30 }, fillB = { 0.84, 0.94, 0.70 },
		glow = { 0.82, 1.00, 0.78 }, gem = { 0.70, 1.00, 0.46 }, trough = { 0.02, 0.04, 0.08 },
		motif = "necrotic", mc = { 0.66, 0.96, 0.62 },
	},
	aq = {
		name = "Gates of Ahn'Qiraj", sub = "The Old God Stirs",
		title = { 1.00, 0.88, 0.56 }, rim = { 0.92, 0.80, 0.56 },
		fillA = { 0.30, 0.18, 0.05 }, fillM = { 0.70, 0.48, 0.16 }, fillB = { 1.00, 0.88, 0.50 },
		glow = { 1.00, 0.93, 0.68 }, gem = { 0.76, 0.36, 1.00 }, trough = { 0.05, 0.03, 0.01 },
		motif = "sand", mc = { 1.00, 0.85, 0.56 },
	},
	naxx = {
		name = "Naxxramas", sub = "The Scourge Invasion",
		title = { 0.64, 1.00, 0.78 }, rim = { 0.82, 0.86, 0.78 },
		fillA = { 0.12, 0.04, 0.20 }, fillM = { 0.14, 0.38, 0.34 }, fillB = { 0.50, 1.00, 0.58 },
		glow = { 0.72, 1.00, 0.82 }, gem = { 0.58, 0.84, 1.00 }, trough = { 0.03, 0.02, 0.05 },
		motif = "necrotic", mc = { 0.52, 1.00, 0.62 },
	},
}
local ZONE_ORDER = { "elwynn", "duskwood", "wsg", "ungoro", "ab", "feralas", "arena", "sm", "av", "brm", "scholomance", "aq", "naxx" }
local PAL_KEYS = { "title", "rim", "fillA", "fillM", "fillB", "glow", "gem", "trough", "mc" }

-- Each zone's bosses, used when the game hasn't sent the schedule (right after a /reload).
-- { run length, time, name, time, name, ... } in seconds.
local FALLBACK = {
	elwynn = { 960, 180, "Hogger", 360, "Mother Fang", 540, "Rhahk'Zor", 720, "Mr. Smite", 960, "Edwin VanCleef" },
	duskwood = { 960, 180, "Naraxis", 360, "Mor'Ladim", 540, "Stitches", 720, "Lupos", 960, "Morbent Fel" },
	wsg = { 960, 180, "Doomguard Commander", 360, "Mannoroth's Herald", 540, "Varimathras", 720, "Lord Hel'nurath", 960, "Lord Kazzak" },
	ungoro = { 960, 180, "Ravasaur Matriarch", 360, "Uhk'loc", 540, "Lar'korwi", 720, "Tyrant Devilsaur", 960, "King Mosh" },
	ab = { 1080, 240, "Kovork", 420, "Nimar the Slayer", 660, "Marez Cowl", 840, "Lord Falconcrest", 1080, "Lord Aliden Perenolde" },
	feralas = { 1080, 240, "Zevrim Thornhoof", 420, "Alzzin the Wildshaper", 660, "Tendris Warpwood", 840, "Immol'thar", 1080, "King Gordok" },
	arena = { 1080, 240, "High Priestess Jeklik", 420, "High Priest Venoxis", 660, "Bloodlord Mandokir", 840, "Jin'do the Hexxer", 1080, "Hakkar the Soulflayer" },
	sm = { 1080, 240, "Houndmaster Loksey", 420, "Arcanist Doan", 660, "Herod", 840, "Scarlet Commander Mograine", 1080, "High Inquisitor Whitemane" },
	av = { 1200, 240, "Korrak the Bloodrager", 480, "Ivus the Forest Lord", 720, "Lokholar the Ice Lord", 960, "Glacius the Frozen Titan", 1200, "Azuregos" },
	brm = { 1200, 240, "General Angerforge", 480, "Warchief Rend Blackhand", 720, "Emperor Dagran Thaurissan", 960, "Majordomo Executus", 1200, "Nefarian" },
	scholomance = { 1200, 240, "Kirtonos the Herald", 480, "Ras Frostwhisper", 720, "Doctor Theolen Krastinov", 960, "Lord Alexei Barov", 1200, "Darkmaster Gandling" },
	aq = { 1200, 240, "Kurinnaxx", 480, "General Rajaxx", 720, "Princess Huhuran", 960, "Ossirian the Unscarred", 1200, "C'Thun" },
	naxx = { 1200, 240, "Anub'Rekhan", 480, "Noth the Plaguebringer", 720, "Patchwerk", 960, "Sapphiron", 1200, "Kel'Thuzad" },
}

-- Particles per zone. where: fill (along the fill), head (near its leading edge), bar (along
-- the whole bar), above (falling from above it). Speeds in UI units per second, +y is up.
local MOTIFS = {
	motes = { tex = "Mote", blend = "ADD", rate = 2.2, where = "fill", y0 = -4, y1 = 5, vx0 = -3, vx1 = 3,
		vy0 = 4, vy1 = 10, wob = 4, wobf = 0.9, life0 = 2.0, life1 = 3.2, w0 = 4, w1 = 7, a = 0.8 },
	fireflies = { tex = "Mote", blend = "ADD", rate = 3.0, where = "fill", y0 = -4, y1 = 6, vx0 = -4, vx1 = 4,
		vy0 = 5, vy1 = 11, wob = 5, wobf = 1.2, life0 = 2.2, life1 = 3.6, w0 = 5, w1 = 9, a = 0.95, twinkle = 5 },
	mist = { tex = "Glow", blend = "ADD", rate = 1.7, where = "fill", y0 = -3, y1 = 3, vx0 = 5, vx1 = 11,
		vy0 = 0, vy1 = 3, wob = 2, wobf = 0.4, life0 = 3.5, life1 = 5.5, w0 = 28, w1 = 46, aspect = 0.42,
		a = 0.26, grow = 0.35 },
	fel = { tex = "Spark", blend = "ADD", rate = 7.5, where = "head", spread = 40, y0 = -5, y1 = 4, vx0 = -5, vx1 = 5,
		vy0 = 18, vy1 = 36, wob = 2, wobf = 3, life0 = 0.8, life1 = 1.5, w0 = 3, w1 = 5, aspect = 2.6, a = 0.95,
		flicker = 14, grow = -0.4 },
	spores = { tex = "Mote", blend = "ADD", rate = 2.6, where = "fill", y0 = -5, y1 = 5, vx0 = -3, vx1 = 3,
		vy0 = 3, vy1 = 9, wob = 7, wobf = 0.7, life0 = 3.0, life1 = 4.8, w0 = 4, w1 = 8, a = 0.85,
		alt = { chance = 0.2, tex = "Twinkle", w0 = 5, w1 = 8, mc = { 1.00, 0.62, 0.22 } } },
	wind = { tex = "Spark", blend = "ADD", rate = 4.5, where = "bar", y0 = -12, y1 = 12, vx0 = 34, vx1 = 60,
		vy0 = -2, vy1 = 2, wob = 2, wobf = 1.5, life0 = 1.0, life1 = 1.8, w0 = 9, w1 = 16, aspect = 0.22,
		a = 0.6, rot = 1.5708 },
	leaves = { tex = "Leaf", blend = "BLEND", rate = 1.3, where = "above", y0 = 13, y1 = 20, vx0 = 5, vx1 = 13,
		vy0 = -14, vy1 = -9, wob = 6, wobf = 0.5, life0 = 3.0, life1 = 3.8, w0 = 8, w1 = 11, a = 0.9,
		spin = 1.6 },
	blood = { tex = "Mote", blend = "ADD", rate = 4.5, where = "fill", y0 = -4, y1 = 4, vx0 = -3, vx1 = 3,
		vy0 = 10, vy1 = 22, wob = 2, wobf = 1.5, life0 = 1.1, life1 = 1.8, w0 = 3, w1 = 6, a = 0.95, grow = -0.3 },
	holy = { tex = "Twinkle", blend = "ADD", rate = 2.6, where = "fill", y0 = -4, y1 = 5, vx0 = -2, vx1 = 2,
		vy0 = 5, vy1 = 11, wob = 3, wobf = 0.8, life0 = 1.4, life1 = 2.4, w0 = 7, w1 = 11, a = 0.95, twinkle = 7 },
	snow = { tex = "Flake", blend = "BLEND", rate = 4.0, where = "above", y0 = 15, y1 = 22, vx0 = -4, vx1 = 4,
		vy0 = -24, vy1 = -13, wob = 5, wobf = 0.6, life0 = 2.2, life1 = 3.0, w0 = 5, w1 = 9, a = 0.9, spin = 1.2 },
	embers = { tex = "Spark", blend = "ADD", rate = 6.0, where = "head", spread = 52, y0 = -5, y1 = 4, vx0 = -8, vx1 = 8,
		vy0 = 16, vy1 = 34, wob = 3, wobf = 2.5, life0 = 0.9, life1 = 1.7, w0 = 3, w1 = 4, aspect = 2.4, a = 0.95,
		flicker = 12, grow = -0.4 },
	sand = { tex = "Mote", blend = "ADD", rate = 9.0, where = "bar", y0 = -11, y1 = 11, vx0 = 45, vx1 = 80,
		vy0 = -3, vy1 = 3, wob = 2, wobf = 1.2, life0 = 0.9, life1 = 1.6, w0 = 2, w1 = 3.5, a = 0.8,
		alt = { chance = 0.04, tex = "Twinkle", w0 = 6, w1 = 9, mc = { 0.78, 0.40, 1.00 } } },
	necrotic = { tex = "Glow", blend = "ADD", rate = 3.0, where = "fill", y0 = -4, y1 = 4, vx0 = -3, vx1 = 3,
		vy0 = 5, vy1 = 12, wob = 4, wobf = 0.7, life0 = 1.8, life1 = 2.8, w0 = 9, w1 = 15, a = 0.5, grow = 0.4,
		alt = { chance = 0.3, tex = "Twinkle", w0 = 5, w1 = 8, mc = { 0.70, 0.90, 1.00 } } },
}

local HEROIC_COLORS = {
	{ 0.45, 0.70, 1.00 }, { 0.55, 0.72, 0.92 }, { 0.95, 0.62, 0.36 }, { 1.00, 0.34, 0.26 }, { 0.95, 0.16, 0.16 },
}
local ROMAN = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" }
local AFFIX_NAMES = { bolstering = "Bolstering", sanguine = "Sanguine", explosive = "Explosive" }

local NAME_TO_ZONE, ZNAME_TO_ZONE = {}, {}
for key, list in pairs(FALLBACK) do
	for i = 3, table.getn(list), 2 do
		NAME_TO_ZONE[string.lower(list[i])] = key
	end
	ZNAME_TO_ZONE[string.lower(THEMES[key].name)] = key
end

AUI.TimerData = {
	THEMES = THEMES,
	ZONE_ORDER = ZONE_ORDER,
	PAL_KEYS = PAL_KEYS,
	FALLBACK = FALLBACK,
	MOTIFS = MOTIFS,
	HEROIC_COLORS = HEROIC_COLORS,
	ROMAN = ROMAN,
	AFFIX_NAMES = AFFIX_NAMES,
	NAME_TO_ZONE = NAME_TO_ZONE,
	ZNAME_TO_ZONE = ZNAME_TO_ZONE,
}
