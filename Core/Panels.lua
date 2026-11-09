-- Shared Arcane metal panel, rail, endcap and medallion construction.
local C = Arcane

------------------------------------------------------------------------ an MMO panel
-- A panel in the timer's metal: brushed dark glass inside a thin round rail lit as the timer's
-- (darkish bronze, one fine bright line on its lit side), the timer's diamonds on its corners,
-- and the Arcane A medallion at each end. The transparent gold-and-black sigil overlaps the end
-- rail and extends outward, leaving the slots clear while making the bar unmistakably Arcane.
local P_RAIL, P_CORNER, P_SIGIL = 8, 16, 122
C.PANEL_RAIL, C.PANEL_CORNER, C.PANEL_SIGIL = P_RAIL, P_CORNER, P_SIGIL
-- Keep the slightly enlarged Classic artwork, but use the exact Hybrid left-medallion
-- anchor offsets. The right Classic medallion mirrors the same anchor from the right edge.
local HYBRID_MEDALLION_SIZE = P_SIGIL * 1.40
C.PANEL_MEDALLION = HYBRID_MEDALLION_SIZE * 401 / 388 * 1.025
-- Match visible artwork centers, not just the square texture origins.
-- Default art alpha center: (250, 256); Hybrid art alpha center: (255.5, 279).
C.PANEL_MEDALLION_X = HYBRID_MEDALLION_SIZE * 0.10
	+ (6 * C.PANEL_MEDALLION - 0.5 * HYBRID_MEDALLION_SIZE) / 512
-- The default art is vertically centered; Hybrid's visible art sits 23px lower.
-- WoW's positive Y offset moves up, so cancel that difference here.
C.PANEL_MEDALLION_Y = -8
-- Keep the original endcap clearance; the new medallions fit inside that reserved room.
local P_OUT, P_FOOT = P_SIGIL * 0.40, P_SIGIL * 25 / 370
C.PANEL_ROOM = math.floor(P_SIGIL - P_OUT + 6)
-- Arcane UI's gold, taken from the user's bar picture (dev/art/source/bar_reference.webp).
local GOLD = { 0.95, 0.79, 0.44 }
function C.Panel(frame, sigils)
	local p = { frame = frame, metal = {}, ends = {}, endLeft = {}, endRight = {} }
	p.baseFill = C.ART .. "PanelFill"
	p.fill = C.Tex(frame, "BACKGROUND", p.baseFill)
	p.fill:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
	p.fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
	local function Rail(art, a1, x1, y1, a2, x2, y2)
		local t = C.Tex(frame, "BORDER", C.ART .. art)
		t:SetPoint(a1, frame, a1, x1, y1)
		t:SetPoint(a2, frame, a2, x2, y2)
		table.insert(p.metal, t)
		return t
	end
	p.railT = Rail("PanelRailT", "TOPLEFT", P_CORNER, 0, "TOPRIGHT", -P_CORNER, 0)
	p.railT:SetHeight(P_RAIL)
	p.railB = Rail("PanelRailB", "BOTTOMLEFT", P_CORNER, 0, "BOTTOMRIGHT", -P_CORNER, 0)
	p.railB:SetHeight(P_RAIL)
	local railL = Rail("PanelRailL", "TOPLEFT", 0, -P_CORNER, "BOTTOMLEFT", 0, P_CORNER)
	local railR = Rail("PanelRailR", "TOPRIGHT", 0, -P_CORNER, "BOTTOMRIGHT", 0, P_CORNER)
	railL:SetWidth(P_RAIL)
	railR:SetWidth(P_RAIL)
	table.insert(p.ends, railL)
	table.insert(p.ends, railR)
	table.insert(p.endLeft, railL)
	table.insert(p.endRight, railR)
	for _, c in ipairs({ { "TOPLEFT", "TL", 1, -1 }, { "TOPRIGHT", "TR", -1, -1 }, { "BOTTOMLEFT", "BL", 1, 1 }, { "BOTTOMRIGHT", "BR", -1, 1 } }) do
		local t = C.Tex(frame, "BORDER", C.ART .. "PanelCorner" .. c[2])
		t:SetWidth(P_CORNER)
		t:SetHeight(P_CORNER)
		t:SetPoint(c[1], frame, c[1], 0, 0)
		table.insert(p.metal, t)
		table.insert(p.ends, t)
		local sideEnds = string.find(c[1], "LEFT") and p.endLeft or p.endRight
		table.insert(sideEnds, t)
		local d = C.Tex(frame, "ARTWORK", C.ART .. "Diamond")
		d:SetWidth(13)
		d:SetHeight(13)
		d:SetPoint("CENTER", frame, c[1], c[3] * 2, c[4] * 2)
		table.insert(p.metal, d)
		table.insert(p.ends, d)
		table.insert(sideEnds, d)
	end
	if sigils then
		p.sigils = {}
		for i, side in ipairs({ "LEFT", "RIGHT" }) do
			local right = side == "RIGHT"
			local x = right and -C.PANEL_MEDALLION_X or C.PANEL_MEDALLION_X
			local t = C.Tex(frame, "OVERLAY", C.ART .. "PanelDefaultMedallion.tga")
			t:SetWidth(C.PANEL_MEDALLION)
			t:SetHeight(C.PANEL_MEDALLION)
			t:SetPoint("CENTER", frame, side, x, C.PANEL_MEDALLION_Y)
			if right then t:SetTexCoord(1, 0, 0, 1) end
			p.sigils[i] = t
		end
	end
	return p
end

function C.PanelMetal(pal)
	local styles = C.BarStyles
	if styles and styles.Mode and styles.PanelMetal and styles.Mode() == styles.FULL_CLASS then
		return styles.PanelMetal(pal)
	end
	return GOLD[1], GOLD[2], GOLD[3]
end

function C.PanelTheme(p, pal)
	local tr = pal.trough
	local mr, mg, mb = C.PanelMetal(pal)
	for i = 1, table.getn(p.metal) do p.metal[i]:SetVertexColor(mr, mg, mb) end
	p.fill:SetVertexColor(0.5 + tr[1] * 0.3, 0.47 + tr[2] * 0.3, 0.44 + tr[3] * 0.3, 0.95)
	if p.sigils then
		for i = 1, 2 do p.sigils[i]:SetVertexColor(1, 1, 1) end
	end
end
