-- Damage-number placement: give visible labels clear, stable positions without overlap.
local AUI = Arcane
local N = AUI.Numbers
local S = N.Placement
local C = N.Config

-- Who gets a seat first: the numbers still taking hits and already showing
-- (they stay put), then new ones, then the finished ones on their way out,
-- which move up out of the way as new ones come in under them.
local function SeatRank(label, now)
	if label.miss then
		if label.w then
			return 1
		end
		return 0
	end
	local rank = 10
	if N.Combat.IsOpen(label, now) then
		rank = 20
		if label.w then
			rank = 30
		elseif label.crit or label.boss then
			rank = 40 -- a new crit or boss number takes its seat first
		end
	end
	if label.boss then
		rank = rank + 2
	end
	if label.crit then
		rank = rank + 1
	end
	return rank
end

local function SeatOrder(a, b)
	if a.rank ~= b.rank then
		return a.rank > b.rank
	end
	if a.rank >= 30 and a.rank < 40 then
		return a.id < b.id -- showing: the older keeps its seat
	end
	if a.rank >= 20 and a.total ~= b.total then
		return a.total > b.total -- new: the bigger first
	end
	return a.id > b.id
end

-- Numbers that would cover each other step up (or down) a line. A new one
-- with no room doesn't show; one already showing that is boxed in for a
-- moment fades out, unless it is a crit or a boss's.
local STEPS = { 0, 1, -1, 2, -2, 3, 4 }
local NSTEPS = 7
local MOVES = { 0, 1, -1 }      -- a number on screen: stay, or move a line
                                -- (one fading out only stays or moves up)
local placedX, placedY, placedW, placedH = {}, {}, {}, {}

S.Spread = function(now, dt)
	local list, n = {}, 0
	for i = 1, N.Combat.nLabels do
		local label = N.Combat.labels[i]
		if not label.culled and label.onScreen then
			n = n + 1
			list[n] = label
			label.rank = SeatRank(label, now)
		end
	end
	if n == 0 then
		return
	end
	if not C.db.spread then
		for i = 1, n do
			list[i].nudgeGoal = 0
			list[i].crowd = 0
		end
		return
	end
	table.sort(list, SeatOrder)
	local placed = 0
	for i = 1, n do
		local label = list[i]
		local scale = N.Layout.BaseScale(label)
		local width = label.textWidth
		if not width then
			width = string.len(C.FormatAmount(label.total)) * C.FONT_SIZE * 0.55
		end
		if C.db.icons and label.icon then
			width = width + C.ICON_SIZE + C.ICON_GAP
		end
		local halfW = width * scale * 0.5 + 3
		local halfH = C.FONT_SIZE * scale * 0.42 + 1
		local cx = label.x
		local cy = label.y + N.Layout.Lift(label, now)
		-- A number already showing puts up with a little overlap before it
		-- moves, so numbers don't hop about as the enemies shuffle.
		local slack = 1
		if label.w then
			slack = 0.85
		end
		-- A new number takes the nearest free line. One already showing keeps
		-- its line or moves a single line, never sliding across the others;
		-- boxed in, it fades out instead.
		local goal
		local line = halfH * 2 + 1 -- a hair more than a number's height, so neighbours fit
		local moving = label.w and label.placed
		local tries = NSTEPS
		if moving then
			tries = 3
			if label.dying then
				tries = 2
			end
		end
		for k = 1, tries do
			local offset
			if moving then
				offset = (label.nudgeGoal or 0) + MOVES[k] * line
			else
				offset = STEPS[k] * line
			end
			local y = cy + offset
			-- never wander more than a few lines from its enemy
			local clear = offset <= 4.5 * line and offset >= -2.5 * line
			for j = 1, placed do
				if not clear then
					break
				end
				if math.abs(cx - placedX[j]) < (halfW + placedW[j]) * slack
					and math.abs(y - placedY[j]) < (halfH + placedH[j]) * slack then
					clear = false
					break
				end
			end
			if clear then
				goal = offset
				break
			end
		end
		local important = (label.crit or label.boss) and label.rank >= 20 -- and still taking hits
		if goal then
			label.crowd = 0
		elseif not label.w and not important then
			goal = 0
			N.Layout.CullLabel(label, now)
		elseif important then
			goal = label.nudgeGoal or 0
			label.crowd = 0
		else
			goal = label.nudgeGoal or 0
			label.crowd = label.crowd + dt
			if label.crowd > C.CROWD_TIME then
				N.Layout.CullLabel(label, now, true)
			end
		end
		label.nudgeGoal = goal
		if not label.placed then
			label.nudge = goal
			label.nudgeSpeed = 0
			label.placed = true
		end
		if not label.culled then
			placed = placed + 1
			placedX[placed] = cx
			placedY[placed] = cy + goal
			placedW[placed] = halfW
			placedH[placed] = halfH
		end
	end
end
