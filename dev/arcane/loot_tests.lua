-- Focused behavior tests for Arcane's loot pop-up under the mock 1.12 client.
-- usage: lua5.1 loot_tests.lua <dev folder> <addon folder>
MOCK_SCRATCH = arg[1]
local DIR = arg[2]
dofile(MOCK_SCRATCH .. "/arcane/mock_arcane.lua")
local M = MOCK

local passed, failed = 0, {}
local function check(ok, label)
	if ok then
		passed = passed + 1
	else
		table.insert(failed, label)
		print("FAIL: " .. label)
	end
end
local function frames(n)
	for i = 1, n do M.Frame(1 / 30) end
end
local function under(o, root)
	local p = o.__parent
	while p do
		if p == root then return true end
		p = p.__parent
	end
	return false
end
local function findText(root, expected)
	for _, o in ipairs(M.All()) do
		if o.__kind == "FontString" and o.__text == expected and under(o, root) and M.Visible(o) then
			return o
		end
	end
	return nil
end
local function findTexture(root, expected)
	for _, o in ipairs(M.All()) do
		if o.__kind == "Texture" and o.__tex == expected and under(o, root) and M.Visible(o) then return o end
	end
	return nil
end
local function visibleToasts()
	local n = 0
	for _, o in ipairs(M.All()) do
		if o.__kind == "Frame" and o.__parent == ArcaneLoot and M.Visible(o) then n = n + 1 end
	end
	return n
end

M.InstallAPI()
M.phase = "ready"
M.hud.loot = true
M.Load(DIR)
frames(30)

check(ArcaneLoot ~= nil, "Arcane creates its loot window")
check(M.hud.loot == false, "Arcane hides the game's own loot pop-up")

local drop = "You receive loot: [Ashbringer] New in your collection!"
ChatFrame1:AddMessage(drop)
ChatFrame2:AddMessage(drop) -- one chat line displayed in two windows counts once
frames(8)
check(findText(ArcaneLoot, "Ashbringer") ~= nil, "a loot line shows the item name")
check(findText(ArcaneLoot, "New in your collection!") ~= nil, "new collection status is shown")
check(visibleToasts() == 1, "duplicate chat-window lines make only one notification")

-- Real item hyperlinks must preserve the item icon, rarity and collection status.
GetItemInfo = function(id)
	if id == 12345 then
		return "Ashbringer", nil, 4, 60, 60, "Weapon", "Two-Handed Swords", 1,
			"INVTYPE_2HWEAPON", "Interface\\\\Icons\\\\INV_Sword_39"
	end
end
local itemLink = "|cffa335ee|Hitem:12345:0:0:0:0:0:0:0|h[Ashbringer]|h|r"
ChatFrame1:AddMessage("You receive loot: " .. itemLink .. " New in your collection!")
frames(8)
check(findTexture(ArcaneLoot, "Interface\\\\Icons\\\\INV_Sword_39") ~= nil,
	"linked items use GetItemInfo's tenth return value as the icon")
check(findText(ArcaneLoot, "New in your collection!") ~= nil,
	"linked items keep their new-collection status")
ChatFrame1:AddMessage("You receive loot: " .. itemLink .. " Already in your collection.")
frames(8)
check(findText(ArcaneLoot, "Already in your collection.") ~= nil,
	"linked items keep their already-collected status")

frames(1)
ChatFrame1:AddMessage("You earn 5 marks (120 in all).")
frames(8)
check(findText(ArcaneLoot, "+5 marks") ~= nil, "earned marks get their own notification")
check(findText(ArcaneLoot, "120 in all") ~= nil, "earned marks show the running total")

local part
for i = 1, table.getn(Arcane.parts) do
	if Arcane.parts[i].key == "loot" then part = Arcane.parts[i] end
end
check(part ~= nil, "Loot is registered in Arcane Options")
if part then
	part.set(false)
	frames(2)
	check(M.hud.loot == true, "turning Loot off restores the game's own pop-up")
	check(visibleToasts() == 0, "turning Loot off clears queued Arcane notifications")
	part.set(true)
	frames(2)
	check(M.hud.loot == false, "turning Loot back on hides the game's pop-up again")
end

print(string.format("Arcane loot tests: %d passed, %d failed", passed, table.getn(failed)))
if table.getn(failed) > 0 then os.exit(1) end
