-- Main /Arcane command router.
local C = Arcane

------------------------------------------------------------------------ /Arcane
local function Slash(msg)
	msg = msg or ""
	local _, _, cmd, rest = string.find(msg, "^%s*(%S*)%s*(.-)%s*$")
	cmd = string.lower(cmd or "")
	if cmd == "" or cmd == "options" or cmd == "config" then
		C.ToggleHub()
	elseif cmd == "timer" or cmd == "sbt" then
		if C.timerSlash then C.timerSlash(rest) end
	elseif cmd == "numbers" or cmd == "sn" or cmd == "dmg" then
		if C.numberSlash then C.numberSlash(rest) end
	elseif cmd == "talents" then
		if C.ToggleTalents then C.ToggleTalents() end
	elseif cmd == "probe" then
		if C.Probe then C.Probe() end
		if C.ProbeAnchors then C.ProbeAnchors() end
		if C.ProbeRanks then C.ProbeRanks() end
	elseif cmd == "move" or cmd == "unlock" then
		C.SetUnlocked(true)
		C.Print(C.L("drag the frames, then type /Arcane lock."))
	elseif cmd == "lock" then
		C.SetUnlocked(false)
		C.Print(C.L("frames locked."))
	elseif cmd == "reset" then
		C.ResetPositions()
		C.Print(C.L("frames are back in their places."))
	elseif cmd == "language" or cmd == "lang" or cmd == "langue" or cmd == "sprache" or cmd == "idioma" then
		local want = string.lower(rest or "")
		if want == "auto" then want = C.DetectLanguage() end
		local codes = {}
		for i = 1, table.getn(C.LANG_LIST) do
			local l = C.LANG_LIST[i]
			table.insert(codes, l.code .. " (" .. l.name .. ")")
			if string.lower(l.name) == want then want = l.code end
		end
		if want ~= "" and C.SetLanguage(want, true) then
			C.Print(C.F("language: {1}", C.LangName(C.lang)))
		else
			C.Print(C.F("/Arcane language followed by one of: {1}, or auto", table.concat(codes, ", ")))
		end
	else
		local handled = false
		for i = 1, table.getn(C.parts) do
			local p = C.parts[i]
			if p.key == cmd then
				local r = string.lower(rest or "")
				if r == "on" then p.set(true) elseif r == "off" then p.set(false) else p.set(not p.get()) end
				C.Print(C.F(p.get() and "{1}: on." or "{1}: off.", C.L(p.name)))
				handled = true
			end
		end
		if not handled then
			local keys = {}
			for i = 1, table.getn(C.parts) do table.insert(keys, C.parts[i].key) end
			C.Print(C.F("/Arcane (options), move, lock, reset, language, timer ..., numbers ..., or a part on/off: {1}",
				table.concat(keys, ", ")))
		end
	end
	-- Options owns the hub refresh callback on Arcane, not as a global.
	if C.RefreshHub then C.RefreshHub() end
end

SLASH_ARCANE1 = "/Arcane"
SLASH_ARCANE2 = "/AUI"
SlashCmdList["ARCANE"] = Slash
