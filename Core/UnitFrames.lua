-- Shared health-text formatting and power-bar palettes for player, target and party frames.
local C = Arcane

C.UnitFrames = C.UnitFrames or {}
C.UnitFrames.POWER_COLORS = {
	[0] = { { 0.03, 0.10, 0.36 }, { 0.10, 0.34, 0.86 }, { 0.48, 0.74, 1.00 } }, -- mana
	[1] = { { 0.34, 0.02, 0.02 }, { 0.76, 0.08, 0.06 }, { 1.00, 0.38, 0.26 } }, -- rage
	[2] = { { 0.36, 0.16, 0.02 }, { 0.84, 0.44, 0.08 }, { 1.00, 0.72, 0.32 } }, -- focus
	[3] = { { 0.40, 0.33, 0.02 }, { 0.86, 0.74, 0.10 }, { 1.00, 0.96, 0.46 } }, -- energy
}

function C.UnitFrames.HealthText(hp, hpm)
	if hpm >= 100000 then return C.Short(hp) .. " / " .. C.Short(hpm) end
	return C.Commas(hp) .. " / " .. C.Commas(hpm)
end
