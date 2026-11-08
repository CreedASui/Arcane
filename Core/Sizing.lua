-- Shared edge and corner sizing handles, including cursor feedback.
local C = Arcane

------------------------------------------------------------------------ sizing by edges and corners
-- Grab strips on a frame's edges and squares on its corners, an arrow by the mouse showing the
-- way (the art's four: across, up and down, the two diagonals). spec:
--   edges = { LEFT = true, TOPRIGHT = true, ... }
--   can() -> may it be sized now; start(edge); move(edge, dx, dy) in UIParent's units; stop(edge)
-- Call the returned sizer's step() every frame. (The meter has its own, for its lines.)
local SIZE_CELLS = { LEFT = 1, RIGHT = 1, TOP = 2, BOTTOM = 2, TOPLEFT = 3, BOTTOMRIGHT = 3, TOPRIGHT = 4, BOTTOMLEFT = 4 }
local SIZE_TC = { { 0, 0.5, 0, 0.5 }, { 0.5, 1, 0, 0.5 }, { 0, 0.5, 0.5, 1 }, { 0.5, 1, 0.5, 1 } }

local function UICursor()
	local x, y = GetCursorPosition()
	local s = UIParent:GetEffectiveScale() or 1
	return (x or 0) / s, (y or 0) / s
end
C.UICursor = UICursor

-- Over an edge that sizes a window, the cursor itself becomes the arrow (the game's hand would sit
-- on a drawn one); it's the game's again the moment the mouse leaves, lets go or the window hides.
-- Without the game's SetCursor, the arrow is drawn by the cursor instead.
local SIZE_CURSORS = { C.ART .. "CursorSizeH", C.ART .. "CursorSizeV", C.ART .. "CursorSizeD1", C.ART .. "CursorSizeD2" }
local cursorBy, cursorAt = nil, 0
local function CursorOn(owner, cell)
	if type(SetCursor) ~= "function" then return false end
	-- set again now and then: the game may take it back when the mouse crosses another frame
	local now = GetTime()
	if cursorBy ~= owner or cursorBy.cell ~= cell or now - cursorAt > 0.25 then
		cursorBy, cursorAt = owner, now
		owner.cell = cell
		pcall(SetCursor, SIZE_CURSORS[cell])
	end
	return true
end
local function CursorOff(owner)
	if cursorBy ~= owner then return end
	cursorBy = nil
	if type(ResetCursor) == "function" then pcall(ResetCursor) elseif type(SetCursor) == "function" then pcall(SetCursor, nil) end
end
C.SizeCursor, C.SizeCursorOff = CursorOn, CursorOff -- the meter's own edges too

function C.Sizers(frame, name, spec)
	local z = { handles = {} }
	local function Start()
		if not spec.can() then return end
		z.active = this.edge
		z.x, z.y = UICursor()
		spec.start(z.active)
	end
	local function Stop()
		if not z.active then return end
		local edge = z.active
		z.active = nil
		spec.stop(edge)
	end
	for edge in pairs(spec.edges) do
		local h = CreateFrame("Frame", nil, frame)
		h.edge = edge
		if edge == "LEFT" or edge == "RIGHT" then
			h:SetPoint("TOPLEFT", frame, "TOP" .. edge, -3, -6)
			h:SetPoint("BOTTOMRIGHT", frame, "BOTTOM" .. edge, 3, 6)
		elseif edge == "TOP" or edge == "BOTTOM" then
			h:SetPoint("TOPLEFT", frame, edge .. "LEFT", 6, 3)
			h:SetPoint("BOTTOMRIGHT", frame, edge .. "RIGHT", -6, -3)
		else
			h:SetWidth(12)
			h:SetHeight(12)
			h:SetPoint("CENTER", frame, edge, 0, 0)
		end
		h:EnableMouse(true)
		h:RegisterForDrag("LeftButton")
		h:SetScript("OnEnter", function() z.hover = this.edge end)
		h:SetScript("OnLeave", function()
			if z.hover == this.edge then z.hover = nil end
			if not z.active then CursorOff(z) end
		end)
		h:SetScript("OnMouseDown", Start)
		h:SetScript("OnMouseUp", function()
			Stop()
			if not z.hover then CursorOff(z) end
		end)
		h:SetScript("OnDragStop", function()
			Stop()
			if not z.hover then CursorOff(z) end
		end)
		-- hidden under the mouse (its window shut, the cards came): the game's cursor back
		h:SetScript("OnHide", function()
			if z.hover == this.edge then z.hover = nil end
			if not z.active or z.active == this.edge then CursorOff(z) end
		end)
		z.handles[edge] = h
	end
	local a = CreateFrame("Frame", name, UIParent)
	a:SetFrameStrata("TOOLTIP")
	a:SetWidth(22)
	a:SetHeight(22)
	a.tex = C.Tex(a, "OVERLAY", C.ART .. "Resize")
	a.tex:SetAllPoints(a)
	a.tex:SetVertexColor(1, 0.92, 0.66)
	C.Vis(a, false)
	z.arrow = a
	function z.levels(level)
		for _, h in pairs(z.handles) do h:SetFrameLevel(level) end
	end
	function z.step()
		local can = spec.can()
		for _, h in pairs(z.handles) do C.Vis(h, can) end
		if not can and not z.active then z.hover = nil end
		if z.active then
			local x, y = UICursor()
			spec.move(z.active, x - z.x, y - z.y)
		end
		local edge = z.active or z.hover
		if edge and CursorOn(z, SIZE_CELLS[edge]) then
			C.Vis(a, false) -- the cursor is the arrow
		elseif edge then
			local x, y = UICursor()
			C.Place(a, "CENTER", UIParent, "BOTTOMLEFT", math.floor(x + 15), math.floor(y - 15))
			local cell = SIZE_CELLS[edge]
			if a.cell ~= cell then
				a.cell = cell
				local c = SIZE_TC[cell]
				a.tex:SetTexCoord(c[1], c[2], c[3], c[4])
			end
			C.Vis(a, true)
		else
			C.Vis(a, false)
			CursorOff(z)
		end
		return edge
	end
	return z
end
