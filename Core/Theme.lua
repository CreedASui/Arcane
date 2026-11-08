-- Shared palette defaults and the Arcane bronze-metal treatment.
local C = Arcane

------------------------------------------------------------------------ the map's colors
-- The boss timer owns the theme (it knows the zone) and shares its gliding palette here.
C.DEFAULT_PAL = {
	title = { 1.00, 0.84, 0.40 }, rim = { 0.95, 0.80, 0.46 },
	fillA = { 0.08, 0.18, 0.46 }, fillM = { 0.20, 0.44, 0.88 }, fillB = { 0.56, 0.80, 1.00 },
	glow = { 0.72, 0.88, 1.00 }, gem = { 1.00, 0.80, 0.30 }, trough = { 0.03, 0.04, 0.08 },
	mc = { 0.75, 0.88, 1.00 },
}
C.palStamp = 0
-- Every part's metal is the skill bar's bronze gold, in every zone: the zone's palette (the timer's,
-- which keeps its own colors) with its rims, titles, gems, glows and troughs swapped for it.
C.BRONZE = {
	title = { 0.98, 0.85, 0.52 }, rim = { 0.95, 0.79, 0.44 }, gem = { 1.00, 0.78, 0.32 },
	glow = { 1.00, 0.80, 0.45 }, trough = { 0.07, 0.05, 0.03 }, mc = { 1.00, 0.88, 0.60 },
}
local bronzed, bronzedFrom, bronzedAt = {}, nil, nil
function C.Pal()
	local base = C.pal or C.DEFAULT_PAL
	if base ~= bronzedFrom or C.palStamp ~= bronzedAt then
		bronzedFrom, bronzedAt = base, C.palStamp
		for k, v in pairs(base) do bronzed[k] = v end
		for k, v in pairs(C.BRONZE) do bronzed[k] = v end
	end
	return bronzed
end
