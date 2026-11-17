-- Shared low-frequency polling bus. Per-frame animation and native frame handlers
-- stay on their own drivers; data refreshes share this one heartbeat.
local C = Arcane
local P = {}
C.Poll = P
local jobs, ordered = {}, {}
local driver = CreateFrame("Frame", "ArcanePollDriver")
driver:Hide()

function P.Add(key, interval, callback, immediate)
	if type(key) ~= "string" or type(interval) ~= "number" or interval <= 0
		or type(callback) ~= "function" then return false end
	local job = jobs[key]
	if not job then
		job = { key = key }
		jobs[key] = job
		table.insert(ordered, job)
	end
	job.interval, job.callback, job.error = interval, callback, nil
	job.nextAt = immediate and 0 or GetTime() + interval
	driver:Show()
	return true
end

-- Events can request an early read; repeated requests coalesce into one tick.
function P.Kick(key)
	local job = jobs[key]
	if not job then return false end
	job.nextAt = 0
	return true
end

function P.Remove(key)
	local job = jobs[key]
	if not job then return false end
	jobs[key] = nil
	for i = 1, table.getn(ordered) do
		if ordered[i] == job then
			table.remove(ordered, i)
			break
		end
	end
	if table.getn(ordered) == 0 then driver:Hide() end
	return true
end

driver:SetScript("OnUpdate", function()
	local now = GetTime()
	for i = 1, table.getn(ordered) do
		local job = ordered[i]
		-- A callback is allowed to unregister a different job while we
		-- traverse this array; a removed slot may be nil later this frame.
		if job and jobs[job.key] == job and now >= job.nextAt then
			-- Never replay missed intervals after an FPS hitch or a loading screen.
			job.nextAt = now + job.interval
			local ok, err = pcall(job.callback, now)
			if ok then
				job.error = nil
			elseif job.error ~= tostring(err) then
				job.error = tostring(err)
				if C.Print then C.Print("poll " .. job.key .. ": " .. job.error) end
			end
		end
	end
end)
