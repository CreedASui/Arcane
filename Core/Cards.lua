-- Frame placement and fade behavior while the game's level-up cards are open.
local C = Arcane

------------------------------------------------------------------------ over the game's cards
-- While level-up or jewelry cards are up, the game veils the screen and the interface goes dark
-- under it, all but the frames it keeps on top (AZS_SetOnTopOfScreens, the game's 0.126 on):
-- those stay lit and take their own clicks. Left under, a frame can even come out half lit, as
-- the game draws some of its art over the veil where a frame on top uses the same. A frame clear
-- of the cards' part of the screen goes on top; one moved over it stays under, so it never
-- covers a card or takes its click. The game reads the list as the cards open, so it is kept
-- current once a second.
local CARDS = { left = 0.22, right = 0.78, top = 0.80 } -- shares of the screen, from the bottom left
C.overCards = {}

function C.OverCards(frame)
	if not frame then return end
	for i = 1, table.getn(C.overCards) do
		if C.overCards[i].frame == frame then return end
	end
	table.insert(C.overCards, { frame = frame })
end

-- clear of the cards (less than a quarter of it over their part)? nil while it has no place yet
local function ClearOfCards(f)
	if type(GetScreenWidth) ~= "function" or type(GetScreenHeight) ~= "function" then return nil end
	local l, b, w, h = f:GetLeft(), f:GetBottom(), f:GetWidth(), f:GetHeight()
	local sw, sh = GetScreenWidth(), GetScreenHeight()
	if not (l and b and w and h and sw and sh) or sw <= 0 or sh <= 0 or w <= 0 or h <= 0 then return nil end
	local k = (f:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1)
	l, b, w, h = l * k / sw, b * k / sh, w * k / sw, h * k / sh
	local ox = math.min(l + w, CARDS.right) - math.max(l, CARDS.left)
	local oy = math.min(b + h, CARDS.top) - math.max(b, 0)
	if ox <= 0 or oy <= 0 then return true end
	return ox * oy < 0.25 * w * h
end

function C.KeepOverCards(force)
	if type(AZS_SetOnTopOfScreens) ~= "function" then return end
	for i = 1, table.getn(C.overCards) do
		local o = C.overCards[i]
		local clear = ClearOfCards(o.frame)
		if o.frame.arcaneDocked then clear = true end -- riding on a frame that's on top
		if clear == nil then clear = o.on ~= false end
		if force or o.on ~= clear then
			o.on = clear
			pcall(AZS_SetOnTopOfScreens, o.frame, clear)
		end
	end
	if force then pcall(AZS_SetOnTopOfScreens, "GameTooltip", true) end
end

-- While the cards are up, the pieces that would lie over them (the skill bar, the meter, the luck,
-- the party and boss bars) fade away: C.cardsFade runs 0 to 1, and back as the cards close.
C.cardsUp, C.cardsFade = false, 0

do
	local overClock = 0
	local watch = CreateFrame("Frame", "ArcaneOverCards")
	watch:SetScript("OnUpdate", function()
		local dt = arg1 or 0
		if dt > 0.1 then dt = 0.1 end
		local up = false
		if type(AZS_GetPhase) == "function" then
			local ok, phase = pcall(AZS_GetPhase)
			up = ok and phase == "choosing"
		end
		C.cardsUp = up
		C.cardsFade = C.Toward(C.cardsFade, up and 1 or 0, up and 10 or 6, dt)
		overClock = overClock - dt
		if overClock > 0 then return end
		overClock = 1
		pcall(C.KeepOverCards, false)
	end)
end
