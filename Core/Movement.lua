-- Saved frame positions, dragging, locking and registered UI parts.
local C = Arcane

------------------------------------------------------------------------ frames you can move
C.movers = {}
C.unlocked = false

local function SavePos(m)
	local f = m.frame
	local l, t = f:GetLeft(), f:GetTop()
	if not (l and t) then return end
	local s = f:GetScale()
	local root = C.Root()
	if type(root.pos) ~= "table" then root.pos = {} end
	root.pos[m.key] = { x = math.floor(l * s + 0.5), y = math.floor(t * s + 0.5) }
	C.ApplyPos(m)
end

C.SavePos = function(m) SavePos(m) end

function C.ApplyPos(m)
	local f = m.frame
	local root = C.Root()
	local p = type(root.pos) == "table" and root.pos[m.key]
	local s = f:GetScale()
	if type(p) == "table" and tonumber(p.x) and tonumber(p.y) then
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", p.x / s, p.y / s)
	elseif m.default then
		m.default(f)
	end
end

-- frame: the movable root; key: where its place is saved; default(frame) anchors it fresh
function C.Movable(frame, key, label, default)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	local m = { frame = frame, key = key, label = label, default = default }
	local box = CreateFrame("Frame", nil, frame)
	box:SetAllPoints(frame)
	box:SetBackdrop({ bgFile = C.FLAT, edgeFile = C.FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
	box:SetBackdropColor(0.1, 0.2, 0.4, 0.35)
	box:SetBackdropBorderColor(0.91, 0.70, 0.30, 0.8)
	box:EnableMouse(true)
	box:RegisterForDrag("LeftButton")
	box:SetScript("OnDragStart", function() frame:StartMoving() end)
	box:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		SavePos(m)
	end)
	box.text = C.Text(box, C.FONT, 11, "OUTLINE", "CENTER", 260)
	box.text:SetPoint("CENTER", box, "CENTER", 0, 0)
	C.LText(box.text, label)
	box.text:SetTextColor(0.98, 0.85, 0.52)
	box:Hide()
	m.box = box
	table.insert(C.movers, m)
	C.ApplyPos(m)
	return m
end

-- A window with drag handles, active only while Move frames is enabled. In normal play
-- its contents remain interactive, but dragging cannot change the saved position.
function C.Draggable(frame, mover)
	local d = { endedAt = 0 }
	function d.start()
		if not C.unlocked then return end
		d.moving = true
		if d.onStart then d.onStart() end
		frame:StartMoving()
	end
	function d.stop()
		if not d.moving then return end
		d.moving = false
		frame:StopMovingOrSizing()
		d.endedAt = GetTime()
		C.SavePos(mover)
	end
	function d.handle(f)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", d.start)
		f:SetScript("OnDragStop", d.stop)
	end
	d.handle(frame)
	return d
end

function C.SetUnlocked(on)
	C.unlocked = on and true or false
	for i = 1, table.getn(C.movers) do
		local m = C.movers[i]
		if C.unlocked then
			m.box:SetFrameLevel(m.frame:GetFrameLevel() + 20)
			m.box:Show()
		else
			m.box:Hide()
		end
	end
	if C.timerLock then C.timerLock(not C.unlocked) end
end

function C.ResetPositions()
	local root = C.Root()
	root.pos = {}
	-- Reset the separately managed timer before its dependent boss bars.
	if C.timerReset then C.timerReset() end
	-- Some defaults are intentionally stacked relative to another movable frame
	-- (Luck → Damage meter → Stats, timer → boss bars → stock error messages).
	-- Reapply once after their anchors have all returned to defaults so every
	-- linked stack settles in one reset.
	for pass = 1, 2 do
		for i = 1, table.getn(C.movers) do C.ApplyPos(C.movers[i]) end
	end
end

------------------------------------------------------------------------ parts, for the hub
-- info: { key, name, note, get(), set(on), getScale(), setScale(v) } (the size pair is optional)
C.parts = {}
function C.RegisterPart(info)
	table.insert(C.parts, info)
end
