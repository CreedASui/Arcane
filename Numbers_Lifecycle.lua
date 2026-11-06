-- Damage-number lifecycle: frame stepping, activation, recovery and game-number handoff.
local AUI = Arcane
local N = AUI.Numbers
local S = N.Lifecycle
local C = N.Config

------------------------------------------------------------------------------
-- Every frame

S.lastNow, S.nextBossRefresh, S.nextSweep = nil, 0, 0

local function RefreshBossNames()
	N.Combat.bossNames = {}
	local units = AZS_UNITS
	if type(units) ~= "table" then
		return
	end
	if type(AZS_GetPhase) == "function" then
		local phase = AZS_GetPhase()
		if phase == nil or phase == "ready" then
			return -- out of a run the list may be the last run's
		end
	end
	for i = 1, table.getn(units) do
		local unit = units[i]
		if type(unit) == "table" then
			local kind = unit.kind or unit[1]
			local name = unit.name or unit[3]
			if name and (kind == "final" or kind == "boss" or kind == "guardian") then
				N.Combat.bossNames[name] = true
			end
		end
	end
end

local function Sweep()
	for key, label in pairs(N.Combat.byKey) do
		if label.dead then
			N.Combat.byKey[key] = nil
		end
	end
	for key, label in pairs(N.Combat.missByKey) do
		if label.dead then
			N.Combat.missByKey[key] = nil
		end
	end
end

-- The level-up cards: while they're up the numbers step aside (under the game's veil their icons
-- come out black), and the ones from before are dropped as the cards close, so none of them flies
-- across the screen to where its enemy has gone meanwhile. New hits show as the fight resumes.
local cards = { was = false, alpha = 1 }

local function StepCards()
	local up = AUI.cardsUp and true or false
	if cards.was and not up then
		N.Combat.ClearAll()
	end
	cards.was = up
	local a = 1 - AUI.Clamp(AUI.cardsFade or 0, 0, 1)
	if up then a = 0 end
	if a ~= cards.alpha then
		cards.alpha = a
		N.Widgets.layer:SetAlpha(a)
	end
end

local function Step(now)
	N.Combat.frameNow = now
	StepCards()
	local dt = 0
	if S.lastNow then
		dt = now - S.lastNow
	end
	dt = AUI.Clamp(dt, 0, 0.1)
	S.lastNow = now
	if now >= S.nextBossRefresh then
		RefreshBossNames()
		S.nextBossRefresh = now + 1
	end
	if now >= S.nextSweep then
		Sweep()
		N.Icons.RefreshFallbackIcons(now)
		S.nextSweep = now + 2
	end
	N.Icons.WatchSummons(now)

	if N.CombatAPI.active then
		N.CombatAPI.ReadEvents(now)
	end
	if N.Preview.testUntil then
		N.Preview.TestHits(now, dt)
	end
	if N.Combat.nLabels == 0 and N.Combat.nPending == 0 then
		return
	end
	if N.Anchors.Project(now) == "world" then
		N.Combat.ClearAll()
		return
	end
	for i = 1, N.Combat.nPending do
		N.Combat.Intake(N.Combat.pending[i], now)
		N.Combat.pending[i] = nil
	end
	N.Combat.nPending = 0
	for i = 1, N.Combat.nLabels do
		local label = N.Combat.labels[i]
		if label.dot and label.targetGone and not label.finished then
			-- The enemy died: the DoT's whole total pops and stays a moment.
			label.finished = true
			label.finishAt = now
			label.bump = math.min(0.6, label.bump + 0.35)
		end
	end
	N.Layout.Cull(now)
	N.Layout.Spread(now, dt)
	N.Animation.Render(now, dt)
end

S.errors, S.lastErrorAt, S.errorShown, S.giveUp = 0, 0, false, false
S.blocked = false  -- Smooth Numbers itself is running, so this part stays off
S.SetEnabled = nil -- below

-- A problem in one frame never reaches the game: that frame's numbers are
-- dropped. Many problems in a row switch the addon off (done from OnUpdate,
-- not inside the game's frame handler).
S.SafeStep = function(now)
	local ok, err = pcall(Step, now)
	if not ok then
		if now - S.lastErrorAt > 10 then
			S.errors = 0
		end
		S.lastErrorAt = now
		S.errors = S.errors + 1
		pcall(N.Combat.ClearAll)
		if not S.errorShown then
			S.errorShown = true
			C.Print(C.L("ran into a problem and skipped it: ") .. tostring(err))
		end
		if S.errors >= 30 then
			S.giveUp = true
		end
	end
end

-- The game calls this every frame in the world, after the camera moved and
-- before anything is drawn, so the numbers stay glued to the enemies.
S.handlerAt = -1
S.OnFrame = function()
	local now = GetTime()
	S.handlerAt = now
	S.SafeStep(now)
end

------------------------------------------------------------------------------
-- On and off

local function HideGameNumbers()
	if type(GetCVar) ~= "function" or type(SetCVar) ~= "function" then
		return
	end
	local current = GetCVar("CombatDamage")
	if not C.db.hidGame then
		C.db.gameNumbers = current or "1"
		C.db.hidGame = true
	end
	if current ~= "0" then
		SetCVar("CombatDamage", "0")
	end
end

S.ShowGameNumbers = function()
	if type(GetCVar) ~= "function" or type(SetCVar) ~= "function" then
		return
	end
	if C.db.hidGame then
		local wanted = C.db.gameNumbers or "1"
		if GetCVar("CombatDamage") ~= wanted then
			SetCVar("CombatDamage", wanted)
		end
		C.db.hidGame = nil
	end
end

S.Activate = function()
	N.CombatAPI.apiReady = N.CombatAPI.ApiReady()
	if not N.CombatAPI.apiReady then
		N.CombatAPI.active = false
		if not N.CombatAPI.warnedNoApi then
			N.CombatAPI.warnedNoApi = true
			C.Print(C.L("this version of the game doesn't give addons its hits yet, so the game's own numbers stay on."))
		end
		return
	end
	if not N.CombatAPI.registered then
		local ok, result, failure = pcall(AZS_RegisterCombatTextFrameHandler, S.OnFrame)
		N.CombatAPI.registered = ok and failure == nil and result ~= false
	end
	N.Combat.ClearAll()
	N.CombatAPI.cursor = nil
	HideGameNumbers()
	N.CombatAPI.active = true
end

local function Deactivate()
	N.CombatAPI.active = false
	if N.CombatAPI.registered and type(AZS_UnregisterCombatTextFrameHandler) == "function" then
		pcall(AZS_UnregisterCombatTextFrameHandler, S.OnFrame)
	end
	N.CombatAPI.registered = false
	N.CombatAPI.cursor = nil
	N.Combat.ClearAll()
	S.ShowGameNumbers()
end

N.Options.RefreshOptions = nil -- below

S.SetEnabled = function(on)
	C.db.enabled = on and true or false
	if C.db.enabled then
		S.errors = 0
		S.Activate()
	else
		Deactivate()
	end
	if N.Options.RefreshOptions then
		N.Options.RefreshOptions()
	end
end
