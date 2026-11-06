-- Damage-number layout: decide which labels show and resolve overlap.
local AUI = Arcane
local N = AUI.Numbers
N.Layout = N.Layout or {}
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

local function ScoreOrder(a, b)
	if a.score ~= b.score then
		return a.score > b.score
	end
	return a.id > b.id
end

S.CullLabel = function(label, now, quick)
	label.culled = true
	label.culledAt = now
	label.cullTime = C.CULL_FADE
	if quick then
		label.cullTime = C.CROWD_FADE
	end
end

-- A DoT's number left out for room may come back once its total has grown
-- (a DoT starts small and keeps adding up), after a pause so it can't flicker.
local function MayReturn(label, now)
	return label.culled and label.dot and not label.w and not label.finished
		and label.culledAt ~= nil and now - label.culledAt > 1
end

-- Too many numbers: the biggest (and the bosses') stay, the rest never show
-- or fade out. A number already on screen keeps its place unless a new one
-- is clearly bigger, so they don't flicker in and out; a DoT's, which stays
-- up for a long time, holds on to its place firmly. A DoT's growing total
-- counts for more, and one left out can come back once it has grown: into a
-- free place, or (one a frame) in place of a number far smaller.
S.Cull = function(now)
	local list, n, biggest, returning = {}, 0, 0, false
	for i = 1, N.Combat.nLabels do
		local label = N.Combat.labels[i]
		label.back = label.onScreen and MayReturn(label, now)
		if label.onScreen and (not label.culled or label.back) then
			n = n + 1
			list[n] = label
			returning = returning or label.back
			local score
			if label.miss then
				score = -1
				if label.w then
					score = -0.5
				end
			else
				score = label.total
				if label.crit then
					score = score * 1.6
				end
				if label.dot and not C.db.group then
					score = score * 1.8 -- a DoT's growing total (groups keep it plain)
				end
				if label.w then
					if label.dot then
						score = score * 3
					else
						score = score * 2
					end
				elseif label.back then
					score = score * 0.5
				end
				if not N.Combat.IsOpen(label, now) then
					score = score * 0.6
				end
				if label.boss then
					score = score + 1e15
				else
					if label.w and label.shownAt and now - label.shownAt < C.MIN_SHOW then
						score = score + 1e14 -- just shown: not pushed out yet
					elseif label.finished and now - label.finishAt < C.KILL_HOLD then
						score = score + 1e14 -- a DoT's final total: kept for its moment
					end
					if label.total > biggest then
						biggest = label.total -- bosses aside, so they don't hide the rest
					end
				end
			end
			label.score = score
		end
	end
	if C.db.minShare > 0 and biggest > 0 then
		local floor = biggest * C.db.minShare
		for i = 1, n do
			local label = list[i]
			-- (only numbers not on screen yet: one showing is never cut short)
			if not label.boss and not label.crit and not label.w and (label.miss or label.total < floor) then
				if label.back then
					label.back = false
				elseif not label.culled then
					S.CullLabel(label, now)
				end
			end
		end
	end
	if n <= C.db.maxLabels and not returning then
		return
	end
	table.sort(list, ScoreOrder)
	-- DoTs' totals take at most three places in four, so the hits always
	-- have some (a boss's DoT doesn't count).
	local dotCap = math.max(2, math.floor(C.db.maxLabels * 0.75 + 0.5))
	local kept, keptDots, weakest, weakestDot = 0, 0, nil, nil
	for i = 1, n do
		local label = list[i]
		if not label.culled then
			local isDot = label.dot and not label.boss
			if kept >= C.db.maxLabels or (isDot and keptDots >= dotCap) then
				S.CullLabel(label, now)
			else
				kept = kept + 1
				if isDot then
					keptDots = keptDots + 1
				end
				if label.score < 1e14 then
					weakest = label -- the smallest one kept that may give way
					if isDot then
						weakestDot = label
					end
				end
			end
		end
	end
	for i = 1, n do
		local label = list[i]
		if label.back then
			local room = kept < C.db.maxLabels and keptDots < dotCap
			if not room then
				local victim = weakest
				if keptDots >= dotCap then
					victim = weakestDot
				end
				if victim and label.score > victim.score * 2 then
					S.CullLabel(victim, now)
					kept = kept - 1
					if victim.dot and not victim.boss then
						keptDots = keptDots - 1
					end
					weakest, weakestDot = nil, nil -- one a frame
					room = true
				end
			end
			if room then
				-- Back on screen: it fades in and pops as if new.
				kept = kept + 1
				keptDots = keptDots + 1
				label.culled = false
				label.cullFade = 1
				label.crowd = 0
				label.placed = false
				label.shownAt = nil
			end
		end
	end
end

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
		local scale = S.BaseScale(label)
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
		local cy = label.y + S.Lift(label, now)
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
			S.CullLabel(label, now)
		elseif important then
			goal = label.nudgeGoal or 0
			label.crowd = 0
		else
			goal = label.nudgeGoal or 0
			label.crowd = label.crowd + dt
			if label.crowd > C.CROWD_TIME then
				S.CullLabel(label, now, true)
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
