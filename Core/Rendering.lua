-- Shared frame-region creation and memoized drawing writers.
local C = Arcane

------------------------------------------------------------------------ writers that skip unchanged values
-- The client re-sorts and redraws on every write, so a frame at rest should cost nothing.
-- A region drawn through these must not be shown, hidden, sized or tinted any other way.
function C.Size(r, w, h)
	if r.mw ~= w or r.mh ~= h then
		r.mw, r.mh = w, h
		r:SetWidth(w)
		r:SetHeight(h)
	end
end

function C.Width(r, w)
	if r.mw ~= w then
		r.mw = w
		r:SetWidth(w)
	end
end

function C.Color(r, red, green, blue, a)
	if r.mr ~= red or r.mg ~= green or r.mb ~= blue or r.ma ~= a then
		r.mr, r.mg, r.mb, r.ma = red, green, blue, a
		r:SetVertexColor(red, green, blue, a)
	end
end

function C.TextColor(r, red, green, blue)
	if r.mr ~= red or r.mg ~= green or r.mb ~= blue then
		r.mr, r.mg, r.mb = red, green, blue
		r:SetTextColor(red, green, blue)
	end
end

function C.Vis(r, on)
	if on then
		if r.mv ~= true then
			r.mv = true
			r:Show()
		end
	elseif r.mv ~= false then
		r.mv = false
		r:Hide()
	end
end

function C.Alpha(r, a)
	if r.mal ~= a then
		r.mal = a
		r:SetAlpha(a)
	end
end

function C.SetText(fs, text)
	if fs.mt ~= text then
		fs.mt = text
		fs:SetText(text)
		fs.mtw = nil
	end
end

-- a font string's width, measured once per text (again while the font isn't ready)
function C.TextWidth(fs)
	if not fs.mtw or fs.mtw <= 0 then fs.mtw = fs:GetStringWidth() end
	return fs.mtw or 0
end

-- anchor a region at one point, skipping repeats
function C.Place(r, point, rel, relPoint, x, y)
	if r.mpx ~= x or r.mpy ~= y or r.mprel ~= rel or r.mpp ~= point then
		r.mpx, r.mpy, r.mprel, r.mpp = x, y, rel, point
		r:ClearAllPoints()
		r:SetPoint(point, rel, relPoint, x, y)
	end
end
------------------------------------------------------------------------ regions
function C.Tex(parent, layer, file, blend)
	local t = parent:CreateTexture(nil, layer)
	t:SetTexture(file)
	if blend then t:SetBlendMode(blend) end
	return t
end

function C.Text(parent, font, size, flags, justify, width)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	C.SetFace(fs, font or C.FONT, size, flags)
	fs:SetJustifyH(justify or "CENTER")
	if width then fs:SetWidth(width) end
	fs:SetShadowColor(0, 0, 0, 1)
	fs:SetShadowOffset(1, -1)
	return fs
end

-- a child frame covering its parent, drawn above it
function C.Layer(parent)
	local f = CreateFrame("Frame", nil, parent)
	f:SetAllPoints(parent)
	return f
end
