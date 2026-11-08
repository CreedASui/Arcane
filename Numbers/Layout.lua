-- Shared geometry helpers used by culling, placement and animation.
local AUI = Arcane
local N = AUI.Numbers
local S = N.Layout
local C = N.Config

------------------------------------------------------------------------------
-- Which numbers show

S.BaseScale = function(label)
	local scale
	if label.miss then
		scale = 0.62
	elseif label.crit then
		scale = 1.15
	elseif label.finished then
		scale = 0.95 -- a DoT's final total grows a little as its enemy dies
	elseif label.merged then
		scale = 0.86 -- a crowd's total, a little larger than one enemy's tick
	elseif not label.direct then
		scale = 0.74
	else
		scale = 0.88
	end
	if label.boss then
		scale = scale * 1.12
	end
	-- a number adding hit after hit grows with how long it has stacked, to a cap: a DoT ticking
	-- on, a spell's crowd total climbing; one hit stays its size
	if (label.count or 1) > 1 and label.lastHit and label.born then
		scale = scale * (1 + C.STACK.grow * AUI.Smooth((label.lastHit - label.born) / C.STACK.time))
	end
	return scale * C.STACK.shrink * C.db.size
end

S.Lift = function(label, now)
	local age = now - label.born
	return (C.BASE_RISE + C.DRIFT * (1 - math.exp(-age * 2.5))) * C.db.size
end
