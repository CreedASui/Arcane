-- Saved-variable access and lifecycle callback registration.
local C = Arcane

------------------------------------------------------------------------ saved settings
C.inits, C.worlds, C.logouts = {}, {}, {}
function C.OnInit(fn) table.insert(C.inits, fn) end
function C.OnWorld(fn) table.insert(C.worlds, fn) end
function C.OnLogout(fn) table.insert(C.logouts, fn) end

function C.Root()
	if type(ArcaneDB) ~= "table" then ArcaneDB = {} end
	return ArcaneDB
end

-- a part's own table inside ArcaneDB, with its defaults filled in
function C.DB(name, defaults)
	local root = C.Root()
	root.drops = nil -- the drops window is gone: forget what it kept
	if type(root[name]) ~= "table" then root[name] = {} end
	local db = root[name]
	if defaults then
		for k, v in pairs(defaults) do
			if db[k] == nil then db[k] = v end
		end
	end
	return db
end
