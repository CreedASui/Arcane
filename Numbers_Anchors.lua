-- Damage-number anchors: project world positions and calculate merged centroids.
local AUI = Arcane
local N = AUI.Numbers
N.Anchors = N.Anchors or {}
local S = N.Anchors
local C = N.Config

------------------------------------------------------------------------------
-- Where things are on screen

-- Puts the labels' and the new hits' places through the camera. Returns
-- "world" when the world changed under us.
local function ProjectAnchors(now)
	local ids, refs, n = {}, {}, 0
	for i = 1, N.Combat.nLabels do
		local label = N.Combat.labels[i]
		label.onScreen = false
		if label.spots then
			if not label.frozen and not (label.culled and not label.w) then
				for j = 1, table.getn(label.spots) do
					local spot = label.spots[j]
					spot.onScreen = false
					if spot.fake then
						spot.x, spot.y = N.Preview.FakePosition(spot.fake, now)
						spot.onScreen = true
					elseif spot.id and not spot.lost then
						n = n + 1
						ids[n] = spot.id
						refs[n] = spot
					end
				end
			end
		elseif label.fake then
			if label.deadX then
				label.x, label.y = label.deadX, label.deadY
			else
				label.x, label.y = N.Preview.FakePosition(label.fake, now)
			end
			label.onScreen = true
		elseif label.anchorId and not label.frozen and not (label.culled and not label.w and not label.dot) then
			-- (a number that will never show needs no place; a DoT's may come back)
			n = n + 1
			ids[n] = label.anchorId
			refs[n] = label
		end
	end
	for i = 1, N.Combat.nPending do
		local ev = N.Combat.pending[i]
		ev.onScreen = false
		if ev.fake then
			ev.x, ev.y = N.Preview.FakePosition(ev.fake, now)
			ev.onScreen = true
		elseif ev.anchorId and ev.kind == "damage" and not N.Combat.IsOpen(N.Combat.byKey[N.Combat.KeyOf(ev) or ""], now) then
			-- Only a hit that may start a number needs its place.
			n = n + 1
			ids[n] = ev.anchorId
			refs[n] = ev
		elseif ev.anchorId and ev.kind == "miss" then
			n = n + 1
			ids[n] = ev.anchorId
			refs[n] = ev
		end
	end
	if n == 0 or not N.CombatAPI.apiReady then
		return true
	end
	local first = 1
	while first <= n do
		local last = math.min(n, first + 255)
		local chunk = ids
		if first > 1 or last < n then
			chunk = {}
			for j = first, last do
				chunk[j - first + 1] = ids[j]
			end
		end
		local ok, result = pcall(AZS_ProjectCombatTextAnchors, chunk, "follow")
		if not ok or type(result) ~= "table" or type(result.entries) ~= "table" then
			return false
		end
		local entries = result.entries
		for j = first, last do
			local entry = entries[j - first + 1]
			local ref = refs[j]
			if type(entry) == "table" then
				if entry.targetState == "dead" or entry.targetState == "unavailable" then
					ref.targetGone = true
				end
				if entry.state == "onScreen" and type(entry.x) == "number" and type(entry.y) == "number" then
					ref.x, ref.y = entry.x, entry.y
					ref.onScreen = true
				elseif entry.state == "worldChanged" then
					return "world"
				elseif entry.state == "expired" or entry.state == "unknownAnchor" then
					ref.lost = true
				end
			end
		end
		first = last + 1
	end
	return true
end

-- A merged number sits over the middle of the enemies its spell hit; a newly
-- hit enemy eases into that middle instead of yanking the number over.
local function Centroids(now)
	for i = 1, N.Combat.nLabels do
		local label = N.Combat.labels[i]
		if label.spots and not label.frozen then
			local sx, sy, sw, seen = 0, 0, 0, false
			for j = 1, table.getn(label.spots) do
				local spot = label.spots[j]
				if spot.onScreen then
					spot.lx, spot.ly = spot.x, spot.y
					seen = true
				end
				if spot.lx then
					local w = AUI.Smooth((now - spot.at) / 0.35) + 0.002
					sx, sy, sw = sx + spot.lx * w, sy + spot.ly * w, sw + w
				end
			end
			if sw > 0 then
				label.x, label.y = sx / sw, sy / sw
			end
			label.onScreen = seen
		end
	end
end

S.Project = function(now)
	local result = ProjectAnchors(now)
	if result ~= "world" then
		Centroids(now)
	end
	return result
end
