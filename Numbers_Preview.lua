-- Damage-number preview: generate synthetic targets and hits for the options preview.
local AUI = Arcane
local N = AUI.Numbers
N.Preview = N.Preview or {}
local S = N.Preview
local C = N.Config

------------------------------------------------------------------------------
-- Preview: a ring of pretend enemies around the middle of the screen.

local TEST_ENEMIES = 9
-- A pretend hero's skills: four spells and a weapon swing, plus a DoT ticking
-- on every pretend enemy until it dies (then a new one takes its place).
local TEST_SKILLS = {
	{ id = 133, name = "Fireball", school = 4, icon = "Interface\\Icons\\Spell_Fire_FlameBolt" },
	{ id = 116, name = "Frostbolt", school = 16, icon = "Interface\\Icons\\Spell_Frost_FrostBolt02" },
	{ id = 403, name = "Lightning Bolt", school = 8, icon = "Interface\\Icons\\Spell_Nature_Lightning" },
	{ id = 8921, name = "Moonfire", school = 64, icon = "Interface\\Icons\\Spell_Nature_StarFall" },
	{ school = 1 },
}
local TEST_DOT = { id = 172, name = "Corruption", school = 32, icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion" }
S.testUntil, S.testSerial, S.testAcc= nil, 0, 0
local testLives = {} -- per pretend enemy: which life it is on, when it dies, its next tick

S.FakePosition = function(index, now)
	local width = WorldFrame:GetWidth() or 1024
	local height = WorldFrame:GetHeight() or 768
	local angle = index * 2 * math.pi / TEST_ENEMIES + now * 0.35
	local radius = 55 + 42 * math.mod(index, 3)
	return width / 2 + math.cos(angle) * radius * 1.35, height / 2 + math.sin(angle) * radius * 0.75
end

local function TestTarget(index)
	return "preview-enemy-" .. index .. "-" .. testLives[index].life
end

local function TestEvent(index, now, skill)
	S.testSerial = S.testSerial + 1
	local ev = {
		eventId = "preview" .. testSerial,
		presentedAt = now,
		targetId = TestTarget(index),
		targetName = "Training Dummy",
		sourceKind = "player",
		fake = index,
		spellId = skill.id,
		abilityName = skill.name,
		icon = skill.icon,
		schoolMask = skill.school,
		damageType = "melee",
	}
	if skill.id then
		ev.damageType = "spell"
	end
	return ev
end

local function Queue(ev, now)
	if N.CombatAPI.Wanted(ev, now) then
		N.Combat.NoteHit(ev, now)
		N.Combat.NoteSource(ev)
		N.Combat.nPending = N.Combat.nPending + 1
		N.Combat.pending[N.Combat.nPending] = ev
	end
end

S.TestHits = function(now, dt)
	if now > S.testUntil then
		S.testUntil = nil
		return
	end
	for index = 1, TEST_ENEMIES do
		local life = testLives[index]
		if now >= life.diesAt then
			-- It dies: its numbers stay where it fell, and a new one comes.
			local target = TestTarget(index)
			local x, y = S.FakePosition(index, now)
			for i = 1, N.Combat.nLabels do
				local label = N.Combat.labels[i]
				if label.target == target then
					label.targetGone = true
					label.deadX, label.deadY = x, y
				end
			end
			life.life = life.life + 1
			life.diesAt = now + 3 + math.random() * 3.5
			life.nextTick = now + 0.3 + math.random() * 0.6
		elseif now >= life.nextTick then
			life.nextTick = life.nextTick + 1
			local ev = TestEvent(index, now, TEST_DOT)
			ev.kind = "damage"
			ev.periodic = true
			ev.critical = math.random() < 0.1
			ev.amount = math.random(300, 650)
			if ev.critical then
				ev.amount = ev.amount * 2
			end
			Queue(ev, now)
		end
	end
	S.testAcc = S.testAcc + dt * 30 -- hits per second
	while S.testAcc >= 1 do
		S.testAcc = S.testAcc - 1
		local ev = TestEvent(math.random(1, TEST_ENEMIES), now, TEST_SKILLS[math.random(1, 5)])
		if math.random() < 0.05 then
			ev.kind = "miss"
			ev.result = { key = "immune" }
		else
			ev.kind = "damage"
			ev.critical = math.random() < 0.18
			ev.amount = math.random(900, 3800)
			if ev.critical then
				ev.amount = ev.amount * 2
			end
		end
		Queue(ev, now)
	end
end

S.StartTest = function()
	local now = GetTime()
	S.testUntil = now + 9
	S.testAcc = 0
	for index = 1, TEST_ENEMIES do
		local life = 1
		if testLives[index] then
			life = testLives[index].life + 1
		end
		testLives[index] = { life = life, diesAt = now + 2.5 + math.random() * 4, nextTick = now + math.random() }
	end
	C.Print(C.L("preview for 9 seconds around the middle of the screen."))
end
