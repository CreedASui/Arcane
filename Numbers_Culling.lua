-- Damage-number culling: decide which labels remain visible when the screen gets busy.
local AUI = Arcane
local N = AUI.Numbers
local S = N.Culling
local C = N.Config

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
