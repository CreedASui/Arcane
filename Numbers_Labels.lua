-- Damage-number labels: create, update, merge and retire the displayed totals.
local AUI = Arcane
local N = AUI.Numbers
local S = N.Combat
local C = N.Config

S.Retire = function(label)
	label.dead = true
	if label.w then
		N.Widgets.ReleaseWidget(label.w)
		label.w = nil
	end
	if label.key then
		if S.byKey[label.key] == label then
			S.byKey[label.key] = nil
		end
		if S.missByKey[label.key] == label then
			S.missByKey[label.key] = nil
		end
	end
end

S.ClearAll = function()
	for i = 1, S.nLabels do
		S.Retire(S.labels[i])
		S.labels[i] = nil
	end
	S.nLabels = 0
	S.byKey, S.missByKey = {}, {}
	for i = 1, S.nPending do
		S.pending[i] = nil
	end
	S.nPending = 0
end

local function MissWord(ev)
	local result = ev.result
	if type(result) == "table" then
		if type(result.text) == "string" and result.text ~= "" then
			return result.text
		end
		if result.key then
			return C.L(C.Capitalize(result.key))
		end
	end
	return C.L("Miss")
end

local function NewLabel(ev, now)
	S.nextLabelId = S.nextLabelId + 1
	local amount = ev.amount or 0
	local label = {
		id = S.nextLabelId,
		target = ev.targetId,
		key = S.KeyOf(ev),
		skill = S.SkillOf(ev),
		icon = N.Icons.IconOf(ev),
		miss = ev.kind == "miss",
		total = amount,
		shown = amount,
		count = 1,
		crit = (ev.critical and not S.IsDotTick(ev)) and true or false, -- a DoT's total is never gold
		critDamage = 0,
		direct = not ev.periodic,
		dot = S.IsDotTick(ev) and true or false,
		lastTick = ev.periodic and now or nil,
		biggest = amount,
		school = ev.schoolMask,
		anchorId = ev.anchorId,
		fake = ev.fake,
		born = now,
		lastHit = now,
		boss = (ev.targetName ~= nil and S.bossNames[ev.targetName]) and true or false,
		bump = 0,
		nudge = 0,
		nudgeGoal = 0,
		placed = false,
		crowd = 0,
		cullFade = 1,
		culled = false,
		dying = false,
		vis = 1,
		x = ev.x,
		y = ev.y,
		onScreen = ev.onScreen and true or false,
	}
	if label.key and string.sub(label.key, 1, 6) == "spell#" then
		-- a merged number: it sits over the middle of the enemies its spell hit
		label.merged = true
		label.target = nil
		label.anchorId = nil
		label.fake = nil
		label.spots = { { id = ev.anchorId, fake = ev.fake, target = ev.targetId, at = now,
			lx = ev.onScreen and ev.x or nil, ly = ev.onScreen and ev.y or nil } }
	end
	if label.miss then
		label.word = MissWord(ev)
	elseif ev.critical then
		label.critDamage = amount
	end
	S.nLabels = S.nLabels + 1
	S.labels[S.nLabels] = label
	if label.key then
		if label.miss then
			S.missByKey[label.key] = label
		else
			S.byKey[label.key] = label
		end
	end
	return label
end

local function Merge(label, ev, now)
	local amount = ev.amount or 0
	label.total = label.total + amount
	label.count = label.count + 1
	label.lastHit = now
	-- Every crit gives the number a pop; it turns gold when crits are at
	-- least half of what it holds.
	if ev.critical then
		label.critDamage = label.critDamage + amount
		label.bump = label.bump + 0.3
	elseif label.dot then
		label.bump = label.bump + 0.07 -- a soft pulse each tick
	else
		label.bump = label.bump + 0.1
	end
	if label.dot and ev.periodic then
		-- Ticks closer than this are one round of the DoT's stacks.
		if label.lastTick and now - label.lastTick > 0.15 then
			local gap = now - label.lastTick
			if not label.tickGap or gap > label.tickGap then
				label.tickGap = gap
			end
		end
		label.lastTick = now
	end
	label.crit = (not label.dot) and label.critDamage > 0 and label.critDamage * 2 >= label.total
	if label.bump > 0.45 then
		label.bump = 0.45
	end
	if not ev.periodic then
		label.direct = true
	end
	if amount > label.biggest then
		-- The colour and icon follow the hardest hit in the number.
		label.biggest = amount
		label.school = ev.schoolMask
		label.icon = N.Icons.IconOf(ev)
	end
	if ev.targetName and S.bossNames[ev.targetName] then
		label.boss = true
	end
	-- One enemy's number follows its newest hit, whose place lasts longest.
	if ev.anchorId and ev.targetId ~= nil and ev.targetId == label.target then
		label.anchorId = ev.anchorId
	end
	if label.spots and (ev.anchorId or ev.fake) then
		local spots, found = label.spots, nil
		for i = 1, table.getn(spots) do
			if spots[i].target == ev.targetId then
				found = spots[i]
			end
		end
		if found then
			found.id, found.lost = ev.anchorId or found.id, nil
		elseif table.getn(spots) < C.MAX_SPOTS then
			table.insert(spots, { id = ev.anchorId, fake = ev.fake, target = ev.targetId, at = now })
		end
	end
end

S.Intake = function(ev, now)
	local key = S.KeyOf(ev)
	if ev.kind == "miss" then
		local label = key and S.missByKey[key]
		if S.IsOpen(label, now) then
			label.count = label.count + 1
			label.lastHit = now
			label.bump = math.min(0.3, label.bump + 0.08)
		elseif ev.anchorId or ev.fake then
			NewLabel(ev, now)
		end
		return
	end
	local label = key and S.byKey[key]
	if not S.IsOpen(label, now) then
		label = nil
		local boss = ev.targetName ~= nil and S.bossNames[ev.targetName]
		if C.db.group and ev.onScreen and not boss and not S.IsDotTick(ev) and not S.Merges(ev) then
			-- The nearest open number around this spot takes the hit (the
			-- same skill's, with icons on).
			local skill = C.db.icons and S.SkillOf(ev)
			local radius = C.GROUP_RADIUS * C.db.size
			local best, bestDistance = nil, radius * radius
			for i = 1, S.nLabels do
				local other = S.labels[i]
				if not other.miss and not other.boss and not other.dot and other.onScreen
					and S.IsOpen(other, now) and (not skill or other.skill == skill) then
					local dx, dy = other.x - ev.x, other.y - ev.y
					local distance = dx * dx + dy * dy
					if distance < bestDistance then
						best, bestDistance = other, distance
					end
				end
			end
			label = best
		end
	end
	if label then
		Merge(label, ev, now)
		if key then
			S.byKey[key] = label
		end
	elseif ev.anchorId or ev.fake then
		NewLabel(ev, now)
	end
end
