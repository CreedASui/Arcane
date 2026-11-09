-- Arcane UI: your own frame, in the boss timer's style, with the real health numbers.
-- It shows your shield, energy, mana or rage, your class's meter (combo points, soul shards...)
-- and your extra lives. The game's PlayerFrame is tucked away while this replacement is on.

local C = Arcane
local Unit = C.UnitFrames
local DEFAULTS = { player = true, playerScale = 1 }
local W, H = 300, 74
local HP_W, HP_H = 200, 14
local RES_H = 8
local BAR_X = 88

local db
local P

local HP_COLORS = {
	{ 0.04, 0.28, 0.07 }, { 0.14, 0.62, 0.18 }, { 0.58, 0.96, 0.36 },
}
local LOW_COLORS = {
	{ 0.36, 0.04, 0.02 }, { 0.80, 0.16, 0.06 }, { 1.00, 0.52, 0.20 },
}
local Call = C.Call -- no stray nil arguments (see Core)



local function Mix(a, b, t, out)
	out[1] = a[1] + (b[1] - a[1]) * t
	out[2] = a[2] + (b[2] - a[2]) * t
	out[3] = a[3] + (b[3] - a[3]) * t
	return out
end

------------------------------------------------------------------------ building a frame
local function Build(name, key, label, default)
	local u = { low = 0, colA = { 0, 0, 0 }, colM = { 0, 0, 0 }, colB = { 0, 0, 0 } }
	local f = CreateFrame("Frame", name, UIParent)
	u.root = f
	f:SetWidth(W)
	f:SetHeight(H)
	f:SetFrameStrata("LOW")

	-- portrait in a metal ring, with the level on a badge
	u.face = CreateFrame("Frame", nil, f)
	u.face:SetWidth(66)
	u.face:SetHeight(66)
	u.face:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4)
	u.faceBg = C.Tex(u.face, "BACKGROUND", C.ART .. "Badge")
	u.faceBg:SetWidth(60)
	u.faceBg:SetHeight(60)
	u.faceBg:SetPoint("CENTER", u.face, "CENTER", 0, 0)
	u.portrait = u.face:CreateTexture(nil, "BORDER")
	u.portrait:SetWidth(54)
	u.portrait:SetHeight(54)
	u.portrait:SetPoint("CENTER", u.face, "CENTER", 0, 0)
	u.faceTop = CreateFrame("Frame", nil, u.face)
	u.faceTop:SetAllPoints(u.face)
	u.ring = C.Tex(u.faceTop, "ARTWORK", C.ART .. "Portrait")
	u.ring:SetAllPoints(u.face)
	u.badge = C.Tex(u.faceTop, "OVERLAY", C.ART .. "Badge")
	u.badge:SetWidth(24)
	u.badge:SetHeight(24)
	u.badge:SetPoint("CENTER", u.face, "BOTTOMLEFT", 10, 10)
	u.levelTop = CreateFrame("Frame", nil, u.faceTop)
	u.levelTop:SetAllPoints(u.face)
	u.level = C.Text(u.levelTop, C.FONT, 11, "OUTLINE", "CENTER", 40)
	u.level:SetPoint("CENTER", u.badge, "CENTER", 0, 0)

	-- health
	u.hp = C.NewBar(f, HP_W, HP_H, true)
	u.hp.frame:SetPoint("TOPLEFT", f, "TOPLEFT", BAR_X, -26)
	u.hpText = C.Text(u.hp.top, C.FONT, 11, "OUTLINE", "CENTER", HP_W + 40)
	u.hpText:SetPoint("CENTER", u.hp.frame, "CENTER", 0, 0)
	u.name = C.Text(u.hp.top, C.FONT, 13, "OUTLINE", "LEFT", HP_W)
	u.name:SetPoint("BOTTOMLEFT", u.hp.frame, "TOPLEFT", 4, 6)

		u.res = C.NewBar(f, HP_W - 24, RES_H, false)
		u.res.frame:SetPoint("TOPLEFT", u.hp.frame, "BOTTOMLEFT", 0, -9)
		u.resText = C.Text(u.res.top, C.FONT, 9, "OUTLINE", "CENTER", HP_W)
		u.resText:SetPoint("CENTER", u.res.frame, "CENTER", 0, 0)
		-- the class meter: up to six gems under the bars
		u.pipFrame = CreateFrame("Frame", nil, f)
		u.pipFrame:SetAllPoints(f)
		u.pips = {}
		for i = 1, 6 do
			local p = C.Tex(u.pipFrame, "ARTWORK", C.ART .. "Diamond")
			p:SetWidth(14)
			p:SetHeight(14)
			p:SetPoint("CENTER", u.res.frame, "BOTTOMLEFT", 7 + (i - 1) * 16, -11)
			u.pips[i] = { tex = p, lit = 0 }
		end
		u.pipText = C.Text(u.pipFrame, C.FONT, 10, "OUTLINE", "LEFT", 140)
		u.pipText:SetPoint("LEFT", u.res.frame, "BOTTOMLEFT", 0, -10)
		-- extra lives, beside the name
		u.lifeGem = C.Tex(u.pipFrame, "ARTWORK", C.ART .. "Gem")
		u.lifeGem:SetWidth(14)
		u.lifeGem:SetHeight(14)
		u.lifeText = C.Text(u.hp.top, C.FONT, 11, "OUTLINE", "LEFT", 40)

	f:Hide()
	u.mover = C.Movable(f, key, label, default)
	return u
end

local function Levels(u)
	local base = u.root:GetFrameLevel()
	u.face:SetFrameLevel(base + 1)
	u.faceTop:SetFrameLevel(base + 3)
	u.levelTop:SetFrameLevel(base + 4)
	C.BarLevels(u.hp, base + 1)
	if u.res then
		C.BarLevels(u.res, base + 1)
		u.pipFrame:SetFrameLevel(base + 5)
	end
end

------------------------------------------------------------------------ your frame
local function StepPlayer(u, dt, now, pal)
	local run = type(AZS_RUN) == "table" and AZS_RUN or {}
	local phase = Call(AZS_GetPhase)
	local inRun = phase == "playing" or phase == "choosing" or phase == "paused" or phase == "dead" or phase == "victory"
	local hp, hpm = Call(UnitHealth, "player") or 0, Call(UnitHealthMax, "player") or 0
	if inRun and tonumber(run.hpm) and run.hpm > 0 and (hpm <= 1 or math.abs(run.hpm - hpm) > 1) then
		hp, hpm = tonumber(run.hp) or hp, run.hpm
	end
	if hpm <= 0 then hpm = 1 end
	local frac = C.Clamp(hp / hpm, 0, 1)
	local sh = inRun and tonumber(run.sh) or 0
	u.hp.shield = (sh and sh > 0) and sh / hpm or 0
	C.BarStep(u.hp, frac, dt, now)

	-- health turns hot and pulses when it runs low
	local lowT = frac < 0.3 and 1 or 0
	u.low = C.Toward(u.low, lowT, 3, dt)
	if u.low > 0.002 or not u.colorsDone then
		u.colorsDone = true
		local t = u.low * (0.8 + 0.2 * math.sin(now * 5))
		C.BarColors(u.hp, Mix(HP_COLORS[1], LOW_COLORS[1], t, u.colA), Mix(HP_COLORS[2], LOW_COLORS[2], t, u.colM),
			Mix(HP_COLORS[3], LOW_COLORS[3], t, u.colB))
	end
	local text = Unit.HealthText(math.floor(hp + 0.5), math.floor(hpm + 0.5))
	if sh and sh > 0 then text = text .. "  |cffbde6ff+" .. C.Short(sh) .. "|r" end
	C.SetText(u.hpText, text)

	-- energy, mana or rage
	local power = Call(UnitPowerType, "player") or 0
	local mp, mpm = Call(UnitMana, "player") or 0, Call(UnitManaMax, "player") or 0
	if u.power ~= power then
		u.power = power
		local cols = Unit.POWER_COLORS[power] or Unit.POWER_COLORS[0]
		C.BarColors(u.res, cols[1], cols[2], cols[3])
	end
	if mpm > 0 then
		C.BarStep(u.res, mp / mpm, dt, now)
		C.SetText(u.resText, math.floor(mp + 0.5) .. " / " .. math.floor(mpm + 0.5))
		C.Vis(u.res.frame, true)
	else
		C.Vis(u.res.frame, false)
	end

	-- the class meter
	local proc, pv, pm = run.proc, tonumber(run.pv) or 0, tonumber(run.pm) or 0
	local pipsShown = 0
	if inRun and type(proc) == "string" and proc ~= "" and pm > 0 and pm <= 6 then pipsShown = math.floor(pm + 0.5) end
	local gem, glow = pal.gem, pal.glow
	for i = 1, 6 do
		local p = u.pips[i]
		local on = i <= pipsShown
		p.lit = C.Toward(p.lit, (on and pv >= i) and 1 or 0, 10, dt)
		if on then
			local l = p.lit
			C.Color(p.tex, 0.22 + (1 - 0.22) * l, 0.22 + (0.78 - 0.22) * l, 0.24 + (0.30 - 0.24) * l, 0.6 + 0.4 * l)
			local s = 12 + 4 * l
			C.Size(p.tex, s, s)
		end
		C.Vis(p.tex, on)
	end
	if inRun and pipsShown == 0 and type(proc) == "string" and proc ~= "" and pm > 0 then
		C.SetText(u.pipText, string.format("%d%%", math.floor(pv / pm * 100 + 0.5)))
		C.TextColor(u.pipText, glow[1], glow[2], glow[3])
		C.Vis(u.pipText, true)
	else
		C.Vis(u.pipText, false)
	end

	-- name, level and lives
	local name = Call(UnitName, "player") or C.L("You")
	C.SetText(u.name, name)
	local t = pal.title
	C.TextColor(u.name, t[1], t[2], t[3])
	local level = (inRun and tonumber(run.lvl)) or Call(UnitLevel, "player") or 1
	C.SetText(u.level, tostring(level))
	local lives = inRun and tonumber(run.lives) or 0
	if lives and lives > 0 then
		local nw = C.TextWidth(u.name)
		C.Place(u.lifeGem, "LEFT", u.name, "LEFT", math.min(nw, HP_W - 60) + 8, 0)
		C.Place(u.lifeText, "LEFT", u.lifeGem, "RIGHT", 2, 0)
		C.Color(u.lifeGem, 0.45, 1, 0.55, 1)
		C.SetText(u.lifeText, "x" .. lives)
		C.TextColor(u.lifeText, 0.6, 1, 0.65)
		C.Vis(u.lifeGem, true)
		C.Vis(u.lifeText, true)
	else
		C.Vis(u.lifeGem, false)
		C.Vis(u.lifeText, false)
	end
end

------------------------------------------------------------------------ portraits and theme
local function PortraitPlayer()
	if type(SetPortraitTexture) == "function" and Call(UnitExists, "player") then
		pcall(SetPortraitTexture, P.portrait, "player")
		P.portrait:Show()
	end
end

local function Theme(u, pal)
	C.BarTheme(u.hp, pal)
	if u.res then C.BarTheme(u.res, pal) end
	local rim = pal.rim
	u.ring:SetVertexColor(rim[1], rim[2], rim[3])
	u.badge:SetVertexColor(rim[1], rim[2], rim[3])
	u.faceBg:SetVertexColor(0.5, 0.5, 0.5)
end

------------------------------------------------------------------------ on and off
local function ApplyPlayer()
	if db.player then
		C.HideStock("PlayerFrame")
	else
		C.RestoreStock("PlayerFrame")
		P.root:Hide()
		P.root.mv = false
	end
end

local function Rescale(u, s)
	u.root:SetScale(s)
	C.ApplyPos(u.mover)
end

local levelled, portraitClock, stamp = false, 0, -1

local function Tick(dt)
	local now = GetTime()
	local pal = C.Pal()
	if stamp ~= C.palStamp then
		stamp = C.palStamp
		Theme(P, pal)
	end
	portraitClock = portraitClock - dt
	if portraitClock <= 0 then
		portraitClock = 3
		PortraitPlayer()
	end
	if not levelled then
		levelled = true
		Levels(P)
	end
	if db.player then
		C.Vis(P.root, true)
		StepPlayer(P, dt, now, pal)
	end
end

C.OnInit(function()
	db = C.DB("units", DEFAULTS)
	-- The target pane is gone. Forget its old on/off, scale and saved-position settings.
	db.target, db.targetScale = nil, nil
	local root = C.Root()
	if type(root.pos) == "table" then root.pos.target = nil end

	P = Build("ArcanePlayer", "player", "Your frame", function(f)
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 14, -10)
	end)
	P.root:SetScale(db.playerScale)
	C.ApplyPos(P.mover)
	C.OverCards(P.root)

	-- Keep the stock target pane and combo-point overlay hidden without replacing
	-- them with another target window. The game's target selection itself is untouched.
	local function HideUnusedTargetStock()
		C.HideStock("TargetFrame")
		C.HideStock("ComboFrame")
	end

	local driver = CreateFrame("Frame", "ArcaneUnitsDriver")
	driver:RegisterEvent("UNIT_PORTRAIT_UPDATE")
	driver:RegisterEvent("PLAYER_ENTERING_WORLD")
	driver:SetScript("OnEvent", function()
		if event == "UNIT_PORTRAIT_UPDATE" then
			if arg1 == "player" then PortraitPlayer() end
		else
			PortraitPlayer()
			HideUnusedTargetStock()
			if db.player then C.HideStock("PlayerFrame") end
		end
	end)
	local broken = false
	driver:SetScript("OnUpdate", function()
		if broken then return end
		local dt = arg1 or 0
		if dt > 0.1 then dt = 0.1 end
		local ok, err = pcall(Tick, dt)
		if not ok then
			broken = true
			C.RestoreStock("PlayerFrame")
			P.root:Hide()
			C.Print(C.L("unit frames stopped after an error, so the game's own are back: ") .. tostring(err))
		end
	end)
	HideUnusedTargetStock()
	ApplyPlayer()
end)

C.RegisterPart({
	key = "player", name = "Your frame",
	note = "Your health with the real numbers, shield, energy/mana/rage, class meter and extra lives. Replaces the game's player frame.",
	get = function() return db and db.player end,
	set = function(on) if db then db.player = on and true or false; ApplyPlayer() end end,
	getScale = function() return db and db.playerScale or 1 end,
	setScale = function(v) if db then db.playerScale = v; Rescale(P, v) end end,
})
