-- Shared math, number formatting and combat-hit summaries.
local C = Arcane

------------------------------------------------------------------------ math
function C.Clamp(v, lo, hi)
	if v < lo then return lo elseif v > hi then return hi end
	return v
end

function C.Smooth(p)
	if p <= 0 then return 0 elseif p >= 1 then return 1 end
	return p * p * (3 - 2 * p)
end

function C.Toward(cur, target, rate, dt)
	local v = cur + (target - cur) * (1 - math.exp(-rate * dt))
	if math.abs(target - v) < 0.001 then return target end -- land, so the writes stop
	return v
end

-- a critically damped spring: no overshoot, no stepping
function C.Spring(pos, vel, target, omega, dt)
	local x = pos - target
	local e = math.exp(-omega * dt)
	local c = vel + omega * x
	return target + (x + c * dt) * e, (vel - c * omega * dt) * e
end

-- an exponential approach that lands exactly on its target
function C.Ease(cur, target, k)
	local v = cur + (target - cur) * k
	if v - target < 0.0015 and target - v < 0.0015 then return target end
	return v
end
------------------------------------------------------------------------ numbers as text
-- A stable spell key shared by rank-specific and display-name variants.
function C.SkillKey(k)
	if type(k) ~= "string" or k == "" then return nil end
	k = string.gsub(k, ":r%d+.*$", "")
	k = string.gsub(k, "^.*:", "")
	return string.lower((string.gsub(k, "[%s%-']+", "_")))
end

-- Recent per-skill hit values, used by the pet bar's tooltip.
C.hitValues = {}
function C.NoteHitValue(ev)
	if type(ev) ~= "table" then return end
	local amount = tonumber(ev.amount)
	if ev.kind ~= "damage" or not amount or amount <= 0 or ev.periodic then return end
	-- This runs for every direct combat hit. Keep the same three aliases
	-- without allocating a temporary keys table for every single event.
	local first, second, third
	if ev.meterSourceKey ~= nil then
		first, second, third = ev.meterSourceKey, C.SkillKey(ev.meterSourceKey), ev.meterSource
	else
		first, second, third = ev.meterSource, ev.abilityName, C.SkillKey(ev.meterSource or ev.abilityName)
	end
	local v
	if first and C.hitValues[first] then v = C.hitValues[first] end
	if second and C.hitValues[second] then v = C.hitValues[second] end
	if third and C.hitValues[third] then v = C.hitValues[third] end
	if not v then v = { times = {} } end
	if first then C.hitValues[first] = v end
	if second then C.hitValues[second] = v end
	if third then C.hitValues[third] = v end
	if ev.critical then
		v.crit = amount
	else
		v.avg = v.avg and (v.avg + (amount - v.avg) * 0.25) or amount
		v.last = amount
		if not v.low or amount < v.low then v.low = amount end
		if not v.high or amount > v.high then v.high = amount end
	end
	-- Fixed ring of the most recent 200 timestamps. The previous front
	-- table.remove shifted up to 199 elements on every late-game hit.
	local slot = v.timeNext or 1
	v.times[slot] = GetTime()
	v.timeNext = slot == 200 and 1 or slot + 1
	v.timeCount = math.min((v.timeCount or 0) + 1, 200)
end

function C.HitRate(v)
	if not v or not v.times then return 0 end
	local now, n = GetTime(), 0
	for i = 1, v.timeCount or 0 do
		if now - v.times[i] <= 10 then n = n + 1 end
	end
	return n / 10
end

function C.Short(n)
	n = n or 0
	local neg = n < 0
	if neg then n = -n end
	local s
	if n >= 1e12 then s = string.format("%.1fT", math.floor(n / 1e11) / 10)
	elseif n >= 1e9 then s = string.format("%.1fB", math.floor(n / 1e8) / 10)
	elseif n >= 1e6 then s = string.format("%.1fM", math.floor(n / 1e5) / 10)
	elseif n >= 1e4 then s = string.format("%.1fK", math.floor(n / 1e2) / 10)
	else s = C.Commas(math.floor(n + 0.5)) end
	s = string.gsub(s, "%.0([KMBT])", "%1")
	if neg then s = "-" .. s end
	return s
end

function C.Commas(n)
	local s = tostring(math.floor(n))
	local out = ""
	while string.len(s) > 3 do
		out = "," .. string.sub(s, -3) .. out
		s = string.sub(s, 1, -4)
	end
	return s .. out
end

-- seconds as m:ss, or h:mm:ss from an hour
function C.Clock(s)
	s = math.floor(math.max(0, s or 0))
	local h, m, sec = math.floor(s / 3600), math.floor(math.mod(s, 3600) / 60), math.mod(s, 60)
	if h > 0 then return string.format("%d:%02d:%02d", h, m, sec) end
	return string.format("%d:%02d", m, sec)
end

function C.Print(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc55Arcane UI|r: " .. msg)
	end
end
