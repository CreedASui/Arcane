-- Shared animated health and shield bar renderer.
local C = Arcane

------------------------------------------------------------------------ a bar in the timer's style
-- A dark glass trough, a shaded fill with a three-color gradient, an echo of lost health, a
-- shield, flowing light, a gloss, a glowing head and the timer's metal rim. Text sits on top.
local FLOW_SIZE, FLOW_PERIOD = 1024, 0.125 -- the flow art spans 1024 px (stored 512 wide: the game's limit)

function C.NewBar(parent, w, h, flow)
	local b = { w = w, h = h, value = 0, vel = 0, echo = 0, echoHold = 0, shield = 0, shieldShown = 0,
		flowU = math.random() * FLOW_PERIOD, flow = flow and true or false, snap = true }
	local base = CreateFrame("Frame", nil, parent)
	b.frame = base
	C.Size(base, w, h)
	b.trough = C.Tex(base, "BACKGROUND", C.FLAT)
	b.trough:SetAllPoints(base)
	b.echoTex = C.Tex(base, "BORDER", C.FLAT)
	b.echoTex:SetPoint("TOPLEFT", base, "TOPLEFT", 0, 0)
	b.echoTex:SetPoint("BOTTOMLEFT", base, "BOTTOMLEFT", 0, 0)
	b.fillA = C.Tex(base, "ARTWORK", C.ART .. "Fill")
	b.fillA:SetPoint("TOPLEFT", base, "TOPLEFT", 0, 0)
	b.fillA:SetPoint("BOTTOMLEFT", base, "BOTTOMLEFT", 0, 0)
	b.fillB = C.Tex(base, "ARTWORK", C.ART .. "Fill")
	b.fillB:SetPoint("TOPLEFT", b.fillA, "TOPRIGHT", 0, 0)
	b.fillB:SetPoint("BOTTOMLEFT", b.fillA, "BOTTOMRIGHT", 0, 0)
	b.fx = C.Layer(base)
	b.flowTex = C.Tex(b.fx, "BACKGROUND", C.ART .. "Flow", "ADD")
	b.flowTex:SetPoint("TOPLEFT", base, "TOPLEFT", 0, 0)
	b.flowTex:SetPoint("BOTTOMLEFT", base, "BOTTOMLEFT", 0, 0)
	b.gloss = C.Tex(b.fx, "BORDER", C.FLAT)
	b.gloss:SetPoint("TOPLEFT", base, "TOPLEFT", 0, 0)
	b.gloss:SetPoint("TOPRIGHT", base, "TOPRIGHT", 0, 0)
	b.gloss:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.16)
	-- a shield: an icy pane with drifting stripes and a bright edge where it begins
	b.shieldTex = C.Tex(b.fx, "ARTWORK", C.FLAT)
	b.shieldTex:SetGradientAlpha("VERTICAL", 0.24, 0.56, 1, 0.78, 0.74, 0.92, 1, 0.9)
	b.shieldTex:SetPoint("TOPLEFT", base, "TOPLEFT", 0, 0)
	b.stripeTex = C.Tex(b.fx, "OVERLAY", C.ART .. "Stripes", "ADD")
	b.stripeTex:SetVertexColor(0.86, 0.96, 1)
	b.stripeTex:SetPoint("TOPLEFT", base, "TOPLEFT", 0, 0)
	b.edgeTex = C.Tex(b.fx, "OVERLAY", C.FLAT)
	b.edgeTex:SetVertexColor(0.9, 0.98, 1, 0.95)
	b.edgeTex:SetPoint("TOPLEFT", base, "TOPLEFT", 0, 0)
	b.spark = C.Tex(b.fx, "OVERLAY", C.ART .. "Spark", "ADD")
	b.rim = C.Layer(base)
	b.rimL = C.Tex(b.rim, "ARTWORK", C.ART .. "FrameL")
	b.rimR = C.Tex(b.rim, "ARTWORK", C.ART .. "FrameR")
	b.rimM = C.Tex(b.rim, "ARTWORK", C.ART .. "FrameM")
	b.top = C.Layer(base)
	C.BarLayout(b, w, h)
	C.Vis(b.shieldTex, false)
	C.Vis(b.stripeTex, false)
	C.Vis(b.edgeTex, false)
	C.Vis(b.echoTex, false)
	return b
end

function C.BarLayout(b, w, h)
	b.w, b.h = w, h
	C.Size(b.frame, w, h)
	local k = h / 12
	local rimH, reach = 22 * k, 11 * k
	b.rimL:SetWidth(rimH)
	b.rimL:SetHeight(rimH)
	b.rimL:ClearAllPoints()
	b.rimL:SetPoint("LEFT", b.frame, "LEFT", -reach, 0)
	b.rimR:SetWidth(rimH)
	b.rimR:SetHeight(rimH)
	b.rimR:ClearAllPoints()
	b.rimR:SetPoint("RIGHT", b.frame, "RIGHT", reach, 0)
	b.rimM:SetHeight(rimH)
	b.rimM:ClearAllPoints()
	b.rimM:SetPoint("LEFT", b.rimL, "RIGHT", 0, 0)
	b.rimM:SetPoint("RIGHT", b.rimR, "LEFT", 0, 0)
	b.gloss:SetHeight(math.max(2, h * 0.5))
	b.spark:SetWidth(math.max(6, h * 0.9))
	b.spark:SetHeight(h * 2.4)
	b.drawnW = nil
end

-- levels: call after the bar's frame is shown under its owner
function C.BarLevels(b, base)
	b.frame:SetFrameLevel(base)
	b.fx:SetFrameLevel(base + 1)
	b.rim:SetFrameLevel(base + 2)
	b.top:SetFrameLevel(base + 3)
end

-- colors: the fill runs a -> m -> b; trough and rim come from the map's palette
function C.BarColors(b, a, m, c)
	b.fillA:SetGradientAlpha("HORIZONTAL", a[1], a[2], a[3], 1, m[1], m[2], m[3], 1)
	b.fillB:SetGradientAlpha("HORIZONTAL", m[1], m[2], m[3], 1, c[1], c[2], c[3], 1)
	b.headR, b.headG, b.headB = 0.55 + c[1] * 0.45, 0.55 + c[2] * 0.45, 0.55 + c[3] * 0.45
end

function C.BarTheme(b, pal)
	local rim, tr = pal.rim, pal.trough
	b.rimL:SetVertexColor(rim[1], rim[2], rim[3])
	b.rimM:SetVertexColor(rim[1], rim[2], rim[3])
	b.rimR:SetVertexColor(rim[1], rim[2], rim[3])
	b.trough:SetVertexColor(tr[1] * 0.8, tr[2] * 0.8, tr[3] * 0.8, 0.92)
end

-- move the bar toward `target` (0..1): it glides up, and a drop leaves a pale echo that
-- lingers a moment, then drains after the fill. The echo waits only when it had caught up, and
-- the longer it is the faster it drains, so a stream of big hits never leaves it parked behind.
local ECHO_HOLD, ECHO_RATE, ECHO_FLOOR = 0.2, 7, 0.35 -- seconds; per second; bar per second

function C.BarStep(b, target, dt, now)
	target = C.Clamp(target or 0, 0, 1)
	if b.snap then
		b.value, b.vel, b.echo, b.snap = target, 0, target, nil
		b.lastTarget = target
	end
	if target < (b.lastTarget or target) - 0.0005 then
		-- a hit: the echo marks where the fill stood
		if b.echo < b.value then b.echo = b.value end
		if b.echo - b.value < 0.01 then b.echoHold = ECHO_HOLD end
	end
	b.lastTarget = target
	b.value, b.vel = C.Spring(b.value, b.vel, target, 16, dt)
	if math.abs(b.value - target) < 0.0004 and math.abs(b.vel) < 0.004 then b.value, b.vel = target, 0 end
	if b.value < 0 then b.value, b.vel = 0, 0 end
	if b.echoHold > 0 then
		b.echoHold = b.echoHold - dt
	else
		local gap = b.echo - b.value
		if gap > 0 then
			b.echo = b.echo - math.min(gap, gap * (1 - math.exp(-ECHO_RATE * dt)) + ECHO_FLOOR * dt)
		end
	end
	if b.echo < b.value then b.echo = b.value end
	if b.echo - b.value < 0.002 then b.echo = b.value end

	local w = b.w
	local fw = w * b.value
	if fw < 0.6 then
		C.Vis(b.fillA, false)
		C.Vis(b.fillB, false)
		C.Vis(b.flowTex, false)
		C.Vis(b.spark, false)
	else
		local half = fw * 0.5
		C.Width(b.fillA, half)
		C.Width(b.fillB, fw - half)
		local fa = C.Smooth(fw / 4)
		C.Alpha(b.fillA, fa)
		C.Alpha(b.fillB, fa)
		C.Vis(b.fillA, true)
		C.Vis(b.fillB, true)
		if b.flow and ArcaneDB and not ArcaneDB.calm then
			b.flowU = math.mod(b.flowU + dt * 20 / FLOW_SIZE, FLOW_PERIOD)
			local u = FLOW_PERIOD - b.flowU
			C.Width(b.flowTex, fw)
			b.flowTex:SetTexCoord(u, u + fw / FLOW_SIZE, 0, 1)
			C.Vis(b.flowTex, true)
		else
			C.Vis(b.flowTex, false)
		end
		-- the head glows while the bar moves, and rests dim
		local moving = C.Clamp(math.abs(b.vel) * 12 + (b.echo - b.value) * 6, 0, 1)
		local a = (0.22 + 0.55 * moving) * C.Smooth(fw / 6) * C.Smooth((w - fw) / 3 + 0.3)
		C.Place(b.spark, "CENTER", b.frame, "LEFT", fw, 0)
		C.Color(b.spark, b.headR or 1, b.headG or 1, b.headB or 1, a)
		C.Vis(b.spark, a > 0.01)
	end
	-- every strip gets its height as well as its width: a single anchor carries no height
	local ew = w * (b.echo - b.value)
	if ew > 0.5 then
		C.Place(b.echoTex, "TOPLEFT", b.frame, "TOPLEFT", fw, 0)
		C.Size(b.echoTex, ew, b.h)
		C.Color(b.echoTex, 1, 0.92, 0.82, 0.55 * C.Smooth(ew / 3))
		C.Vis(b.echoTex, true)
	else
		C.Vis(b.echoTex, false)
	end
	C.BarShield(b, w, fw, dt, now)
	return fw
end

-- a shield sits after the health, laid over its end when it doesn't fit; it flashes as it grows
local STRIPE_SPAN, STRIPE_PERIOD = 256, 8 -- the stripes art spans 256 px, a stripe every 8

function C.BarShield(b, w, fw, dt, now)
	local sh = C.Clamp(b.shield or 0, 0, 1)
	if sh > (b.shieldLast or 0) + 0.01 then b.shieldFlash = 1 end
	b.shieldLast = sh
	b.shieldShown = C.Ease(b.shieldShown, sh, 1 - math.exp(-dt * 10))
	local sw = math.min(w * b.shieldShown, w)
	if sw <= 0.6 then
		C.Vis(b.shieldTex, false)
		C.Vis(b.stripeTex, false)
		C.Vis(b.edgeTex, false)
		b.shieldFlash = 0
		return
	end
	local x0, h = fw, b.h
	if x0 + sw > w then x0 = math.max(0, w - sw) end
	local flash = b.shieldFlash or 0
	if flash > 0 then b.shieldFlash = math.max(0, flash - dt * 2.5) end
	local t = now or 0
	C.Place(b.shieldTex, "TOPLEFT", b.frame, "TOPLEFT", x0, 0)
	C.Size(b.shieldTex, sw, h)
	C.Alpha(b.shieldTex, math.min(1, 0.84 + 0.06 * math.sin(t * 2.6) + 0.16 * flash))
	C.Vis(b.shieldTex, true)
	-- the stripes drift slowly (still with the calm option)
	local drift = 0
	if not (ArcaneDB and ArcaneDB.calm) then drift = math.mod(t * 7, STRIPE_PERIOD) end
	local u0 = (x0 + STRIPE_PERIOD - drift) / STRIPE_SPAN
	local u1 = u0 + sw / STRIPE_SPAN
	if u1 > 1 then u0, u1 = u0 - (u1 - 1), 1 end
	if b.stripeU0 ~= u0 or b.stripeU1 ~= u1 then
		b.stripeU0, b.stripeU1 = u0, u1
		b.stripeTex:SetTexCoord(u0, u1, 0, 1)
	end
	C.Place(b.stripeTex, "TOPLEFT", b.frame, "TOPLEFT", x0, 0)
	C.Size(b.stripeTex, sw, h)
	C.Alpha(b.stripeTex, math.min(1, 0.5 + 0.35 * flash))
	C.Vis(b.stripeTex, true)
	-- a bright edge where the shield begins
	C.Place(b.edgeTex, "TOPLEFT", b.frame, "TOPLEFT", math.max(0, x0 - 1), 0)
	C.Size(b.edgeTex, 2, h)
	C.Vis(b.edgeTex, true)
end
