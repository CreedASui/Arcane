-- Handoff and restoration of the game's own HUD and stock frames.
local C = Arcane

------------------------------------------------------------------------ the game's own HUD parts
-- Each part is hidden only while the Arcane UI part that replaces it is on, and only what we
-- hid is shown again (a part the player had turned off stays off).
function C.TakeHud(part)
	if type(AZS_SetHudShown) ~= "function" or type(AZS_IsHudShown) ~= "function" then return end
	local ok, shown = pcall(AZS_IsHudShown, part)
	if ok and shown then
		local root = C.Root()
		if type(root.hudWas) ~= "table" then root.hudWas = {} end
		root.hudWas[part] = true
		pcall(AZS_SetHudShown, part, false)
	end
end

function C.ReleaseHud(part)
	local root = C.Root()
	if type(root.hudWas) == "table" and root.hudWas[part] and type(AZS_SetHudShown) == "function" then
		pcall(AZS_SetHudShown, part, true)
		root.hudWas[part] = nil
	end
end

-- stock frames (PlayerFrame, TargetFrame, MainMenuBar...) go under a hidden parent
C.hidden = CreateFrame("Frame", "ArcaneHidden", UIParent)
C.hidden:Hide()
C.stock = {}
function C.HideStock(name)
	local f = getglobal(name)
	if type(f) ~= "table" or C.stock[name] or type(f.SetParent) ~= "function" then return end
	C.stock[name] = f:GetParent() or UIParent
	f:SetParent(C.hidden)
end

function C.RestoreStock(name)
	local f, parent = getglobal(name), C.stock[name]
	if type(f) == "table" and parent then
		f:SetParent(parent)
		C.stock[name] = nil
	end
end
