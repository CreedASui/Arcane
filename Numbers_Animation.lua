-- Damage-number animation: format, color, animate and draw visible labels.
local AUI = Arcane
local N = AUI.Numbers
local S = N.Animation
local C = N.Config

------------------------------------------------------------------------------
-- Drawing

local function LabelColor(label)
	if label.miss then
		return C.COLOR_MISS
	end
	if label.crit then
		return C.COLOR_CRIT
	end
	if C.db.school and label.school and C.SCHOOL_COLORS[label.school] then
		return C.SCHOOL_COLORS[label.school]
	end
	if not label.direct and not label.finished then
		return C.COLOR_DOT
	end
	return C.COLOR_NORMAL
end

local function LabelText(label)
	local text
	if label.miss then
		text = label.word
	else
		text = C.FormatAmount(label.shown)
	end
	if C.db.count and label.count > 1 then
		text = text .. " |cffbbbbbbx" .. label.count .. "|r"
	end
	return text
end

-- Returns false when the label is done. Every way a number leaves is eased:
-- it floats up, shrinks a little and melts away; pushed out, it melts where
-- it is; leaving the view (or losing its place) it fades where it last was.
local function Animate(label, now, dt, ratio)
	if label.frozen then
		label.onScreen = label.x ~= nil
	end
	-- A hit's number fades a moment after its last hit; a DoT's when the DoT
	-- stops ticking, or a moment after its enemy died.
	local fadeAt
	if label.finished then
		fadeAt = label.finishAt + C.KILL_HOLD
	elseif label.dot then
		fadeAt = label.lastHit + N.Combat.DotHold(label)
	else
		fadeAt = label.lastHit + C.HOLD
	end
	local fadeP = 0
	if now > fadeAt then
		label.dying = true
		fadeP = (now - fadeAt) / C.FADE_OUT
		if fadeP >= 1 then
			return false
		end
	end
	-- Its place comes from its newest hit, which the game keeps 5 s: near the
	-- end of that, or with the place lost, it slips away where it is.
	local leaving = now - label.lastHit > C.MAX_AGE or label.lost
	if leaving then
		if not label.culled then
			N.Layout.CullLabel(label, now)
		end
		if label.lost then
			label.frozen = true
			label.onScreen = label.x ~= nil
		end
	end
	if label.culled then
		-- Off the screen (or never on it), it still takes its enemy's hits
		-- until it would have faded, so they don't start a new number each
		-- frame.
		if not label.w then
			return not leaving
		end
		label.cullFade = label.cullFade - dt / (label.cullTime or C.CULL_FADE)
		if label.cullFade <= 0 then
			N.Widgets.ReleaseWidget(label.w)
			label.w = nil
			return not leaving
		end
	end
	-- Out of the view it fades where it last was; back in, it fades back.
	if label.onScreen then
		label.vis = math.min(1, label.vis + dt / C.EDGE_FADE)
	else
		label.vis = math.max(0, label.vis - dt / C.EDGE_FADE)
	end
	local w = label.w
	if not label.onScreen and (not w or label.vis <= 0 or not label.x) then
		if w and w.shown then
			w.holder:Hide()
			w.shown = false
		end
		return true
	end
	if not w then
		w = N.Widgets.AcquireWidget()
		label.w = w
		if not label.shownAt then
			label.shownAt = now
		end
	end

	-- The number counts up to what it holds.
	if label.shown < label.total then
		label.shown = label.shown + (label.total - label.shown) * (1 - math.exp(-dt * 16))
		if label.total - label.shown < 1 then
			label.shown = label.total
		end
	end
	local text = LabelText(label)
	if text ~= w.lastText then
		w.text:SetText(text)
		w.lastText = text
		local width = w.text:GetStringWidth()
		if type(width) ~= "number" or width <= 0 then
			width = string.len(text) * C.FONT_SIZE * 0.55
		end
		label.textWidth = width
	end
	local icon = nil
	if C.db.icons then
		icon = label.icon
	end
	N.Widgets.Layout(w, label.textWidth or 0, icon, dt)

	-- Colours blend into each other (a crit's gold, a DoT's final white).
	local color = LabelColor(label)
	local r, g, b = color[1], color[2], color[3]
	if w.r then
		local k = 1 - math.exp(-dt * 12)
		r = w.r + (r - w.r) * k
		g = w.g + (g - w.g) * k
		b = w.b + (b - w.b) * k
		if math.abs(r - color[1]) + math.abs(g - color[2]) + math.abs(b - color[3]) < 0.01 then
			r, g, b = color[1], color[2], color[3]
		end
	end
	if w.r ~= r or w.g ~= g or w.b ~= b then
		w.text:SetTextColor(r, g, b)
		w.r, w.g, w.b = r, g, b
	end

	-- Pop and fade in from when it first shows (it may have been off screen).
	local shownAge = now - label.shownAt
	-- A hit's punch swells in and relaxes on a quick soft spring: no frame
	-- ever jumps in size.
	label.bump = label.bump * math.exp(-dt * 10)
	local away = (label.swell or 0) - label.bump
	local speed = label.swellSpeed or 0
	local decay = math.exp(-C.POP_SPRING * dt)
	local push = (speed + C.POP_SPRING * away) * dt
	label.swellSpeed = (speed - C.POP_SPRING * push) * decay
	label.swell = label.bump + (away + push) * decay
	local pop = 1
	local motion = C.db.motion
	local popTime = (motion == "impact") and 0.32 or C.POP_TIME
	if shownAge < popTime then
		local t = 1 - shownAge / popTime
		local strength = 0.25
		if label.crit then
			strength = 0.55
		elseif label.miss then
			strength = 0.1
		end
		if motion == "impact" then strength = strength * 2.6 end
		pop = 1 + strength * t * t * t
	end
	local fading = AUI.Smooth(fadeP)
	local pushed = 0
	if label.culled then
		pushed = AUI.Smooth(1 - label.cullFade)
	end
	-- A change of size (a number turning gold, a DoT's final total) grows in.
	local base = N.Layout.BaseScale(label)
	if label.base then
		base = label.base + (base - label.base) * (1 - math.exp(-dt * 14))
	end
	label.base = base
	local scale = base * pop * (1 + label.swell) * (1 - C.FADE_SHRINK * fading) * (1 - C.CULL_SHRINK * pushed)
	if not w.scale or math.abs(w.scale - scale) > 0.003 then
		w.visual:SetScale(scale)
		w.scale = scale
	end

	local alpha = (1 - fading) * (1 - pushed) * AUI.Smooth(label.vis)
	if shownAge < C.FADE_IN then
		alpha = alpha * AUI.Smooth(shownAge / C.FADE_IN)
	end
	alpha = AUI.Clamp(alpha, 0, 1)
	if not w.alpha or math.abs(w.alpha - alpha) > 0.004 then
		w.holder:SetAlpha(alpha)
		w.alpha = alpha
	end

	-- It drifts up as it lives; fading, it floats off, gently at first.
	-- Stepping aside rides a critically damped spring: it starts gently,
	-- speeds up, and settles without overshoot.
	local offset = label.nudge - label.nudgeGoal
	local speed = label.nudgeSpeed or 0
	local decay = math.exp(-C.SPRING * dt)
	local push = (speed + C.SPRING * offset) * dt
	label.nudgeSpeed = (speed - C.SPRING * push) * decay
	label.nudge = label.nudgeGoal + (offset + push) * decay
	local rise = N.Layout.Lift(label, now) + label.nudge + C.FADE_RISE * C.db.size * fadeP * fadeP
	local sideways = 0
	local age = now - label.born
	if motion == "fountain" then
		if not label.side then label.side = (math.mod(math.floor(label.born * 997), 2) == 0) and 1 or -1 end
		sideways = label.side * 52 * C.db.size * (1 - math.exp(-age * 1.8))
		rise = (C.BASE_RISE + 95 * age - 80 * age * age) * C.db.size + label.nudge
	elseif motion == "rise" then
		rise = (C.BASE_RISE + 85 * age) * C.db.size + label.nudge + C.FADE_RISE * C.db.size * fadeP
	elseif motion == "impact" then
		rise = C.BASE_RISE * C.db.size + label.nudge
		if label.crit and shownAge < 0.3 then
			sideways = math.sin(shownAge * 95) * 5 * C.db.size * (1 - shownAge / 0.3)
		end
	end
	local px = math.floor((label.x + sideways) * ratio * 10 + 0.5) / 10
	local py = math.floor((label.y + rise) * ratio * 10 + 0.5) / 10
	if w.px ~= px or w.py ~= py then
		w.holder:SetPoint("CENTER", WorldFrame, "BOTTOMLEFT", px, py)
		w.px, w.py = px, py
	end
	if not w.shown then
		w.holder:Show()
		w.shown = true
	end
	return true
end

S.Render = function(now, dt)
	-- The game's places are in WorldFrame's units; ours may be scaled.
	local ratio = 1
	local worldScale = WorldFrame:GetEffectiveScale()
	local layerScale = N.Widgets.layer:GetEffectiveScale()
	if type(worldScale) == "number" and type(layerScale) == "number" and layerScale > 0 then
		ratio = worldScale / layerScale
	end
	local kept = 0
	for i = 1, N.Combat.nLabels do
		local label = N.Combat.labels[i]
		if Animate(label, now, dt, ratio) then
			kept = kept + 1
			N.Combat.labels[kept] = label
		else
			N.Combat.Retire(label)
		end
	end
	for i = kept + 1, N.Combat.nLabels do
		N.Combat.labels[i] = nil
	end
	N.Combat.nLabels = kept
end
