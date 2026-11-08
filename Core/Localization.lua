-- Language tables, live text updates, font fallback and tooltip localization.
local C = Arcane

------------------------------------------------------------------------ languages
-- Arcane UI's own words in the language picked (the game's own names, of bosses, zones and
-- spells, come in the game's language already). English is the source: each language's table
-- (Locale.lua) maps the English words to its own. In a template, {1}, {2}... stand for what goes
-- in, in whatever order the language wants them. Changing the language changes the words at once:
-- a text set with C.LText follows by itself; a part that makes its words once and keeps them
-- watches C.langStamp, or asks C.OnLanguage to tell it.
C.LANGS = {}
C.LANG_LIST = { { code = "en", name = "English" } }
C.lang, C.langStamp = "en", 0
C.ltexts, C.langHooks = {}, {}
local words = nil

function C.L(s)
	local t = words
	return t and t[s] or s
end

function C.F(template, ...)
	local args = arg
	return (string.gsub(C.L(template), "{(%d)}", function(n)
		local v = args[tonumber(n)]
		if v == nil then return "" end
		return tostring(v)
	end))
end

-- a font string whose words are always in the language picked
function C.LText(fs, key)
	if fs.lkey == nil then table.insert(C.ltexts, fs) end
	fs.lkey = key
	C.SetText(fs, C.L(key))
end

function C.OnLanguage(fn) table.insert(C.langHooks, fn) end

-- a language: its code, its name in its own words, the face its letters need (nil: Friz Quadrata
-- and Morpheus have them; below), and its words
C.SCRIPTS = {}
function C.AddLanguage(code, name, face, words)
	C.LANGS[code] = words
	if type(face) ~= "string" then face = nil end
	table.insert(C.LANG_LIST, { code = code, name = name, face = face })
	C.SCRIPTS[code] = face
end

------------------------------------------------------------------------ faces
-- Arcane UI draws its words in Friz Quadrata and Morpheus, which have no Cyrillic, no Chinese,
-- Japanese or Korean, and not all of Polish or Turkish; the client draws nothing for a letter its
-- face lacks. So a language in other letters draws everything in a face of Arcane UI's own that has
-- them (Fonts\, both under the SIL Open Font License), and back to the two when the language is
-- changed again. Each font string made through C.Text or C.SetFace is kept so its face can change.
C.FACE_LETTERS = "Interface\\AddOns\\Arcane\\Fonts\\Letters.ttf" -- Latin, Latin Extended-A, Cyrillic
C.FACE_CJK = "Interface\\AddOns\\Arcane\\Fonts\\LettersCJK.ttf" -- Chinese, Japanese, Korean (and Latin, Cyrillic)
C.faced = {}
local langFace = nil

-- the face to draw in, for one Arcane UI meant
function C.Face(face)
	return langFace or face or C.FONT
end

-- a font string's face, size and flags, kept so the face can change with the language; `fixed`
-- draws it in that face whatever the language (a language's name in its own letters)
function C.SetFace(fs, face, size, flags, fixed)
	if not fs.cface then table.insert(C.faced, fs) end
	fs.cface, fs.csize, fs.cflags, fs.cfixed = face or C.FONT, size, flags, fixed
	fs:SetFont(fixed or C.Face(fs.cface), size, flags)
	fs.mtw = nil
end

local function Reface(code)
	local want = C.SCRIPTS[code]
	if want == langFace then return end
	langFace = want
	for i = 1, table.getn(C.faced) do
		local fs = C.faced[i]
		fs:SetFont(fs.cfixed or C.Face(fs.cface), fs.csize, fs.cflags)
		fs.mtw = nil
	end
end

-- the game's tooltip in that face while it carries Arcane UI's words (its own faces lack these
-- letters too): each line's font is kept and comes back the moment anyone takes the tooltip again
local tipKept, tipHooked = {}, false
local function TipBack()
	if not next(tipKept) then return end
	for fs, k in pairs(tipKept) do
		if k.object then fs:SetFontObject(k.object) end -- following the game's font again
		if k.face and fs:GetFont() ~= k.face then fs:SetFont(k.face, k.size, k.flags) end
	end
	tipKept = {}
end
local function TipFace(fs)
	local face, size, flags = fs:GetFont()
	if not tipKept[fs] then
		tipKept[fs] = { object = fs.GetFontObject and fs:GetFontObject() or nil, face = face, size = size or 12, flags = flags }
	end
	if face ~= langFace then fs:SetFont(langFace, size or 12, flags) end
end
function C.ShowTip()
	local tip = GameTooltip
	if not tip then return end
	if not tipHooked and type(tip.SetOwner) == "function" then
		tipHooked = true
		local own = tip.SetOwner
		tip.SetOwner = function(self, ...)
			TipBack()
			return own(self, unpack(arg))
		end
	end
	if langFace then
		local i = 1
		while getglobal("GameTooltipTextLeft" .. i) do
			TipFace(getglobal("GameTooltipTextLeft" .. i))
			local r = getglobal("GameTooltipTextRight" .. i)
			if r then TipFace(r) end
			i = i + 1
		end
	else
		TipBack()
	end
	tip:Show()
end

function C.LangName(code)
	for i = 1, table.getn(C.LANG_LIST) do
		if C.LANG_LIST[i].code == code then return C.LANG_LIST[i].name end
	end
	return code
end

-- the client's language, as far as it tells (the game's own picker can say another: the menu or
-- /Arcane language sets it then)
local LOCALES = { frFR = "fr", deDE = "de", esES = "es", esMX = "es", ptBR = "pt", ptPT = "pt", zhCN = "zh", zhTW = "zh",
	ruRU = "ru", koKR = "ko", jaJP = "ja", plPL = "pl", trTR = "tr" }
function C.DetectLanguage()
	local ok, loc = false, nil
	if type(GetLocale) == "function" then ok, loc = pcall(GetLocale) end
	local code = ok and LOCALES[loc] or nil
	if code and C.LANGS[code] then return code end
	return "en"
end

function C.SetLanguage(code, save)
	if code ~= "en" and not C.LANGS[code] then return false end
	C.lang = code
	words = C.LANGS[code]
	C.langStamp = C.langStamp + 1
	if save then C.Root().lang = code end
	Reface(code)
	for i = 1, table.getn(C.ltexts) do
		local fs = C.ltexts[i]
		C.SetText(fs, C.L(fs.lkey))
	end
	for i = 1, table.getn(C.langHooks) do pcall(C.langHooks[i]) end
	return true
end
