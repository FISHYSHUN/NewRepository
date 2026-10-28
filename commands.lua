--[[ commands: command bar parser (inspired by Infinite Yield) ]]
local M = ...
local S, cfg, FLAT = M.S, M.cfg, M.FLAT
local Features = M.Features
local Cmds, CmdList = {}, {}
M.Cmds, M.CmdList = Cmds, CmdList

local function addCmd(names, desc, fn, usage)
	local c = { n = names[1], names = names, desc = desc, fn = fn, usage = usage or names[1] }
	for _, nm in ipairs(names) do Cmds[nm] = c end
	table.insert(CmdList, c)
	return c
end
local function alias(existing, new)
	local c = Cmds[existing]
	if c then Cmds[new] = c; table.insert(c.names, new) end
end

-- one toggle + one "un" command per cheat
for _, ch in ipairs(FLAT) do
	local key = (ch.n:lower():gsub("[^%w]", ""))
	local slider
	for _, f in ipairs(ch.f) do if f.k == "s" then slider = f break end end
	addCmd({ key }, "Toggle " .. ch.n .. (slider and (" · optional " .. slider.l:lower()) or ""), function(args)
		local a = args[1]
		if a == "on" or a == "off" then Features.set(ch, a == "on")
		elseif a and tonumber(a) then
			if slider then slider.cur = math.clamp(tonumber(a), slider.min, slider.max) end
			Features.set(ch, true)
		else Features.userToggle(ch) end
	end, key .. (slider and " [value]" or ""))
	addCmd({ "un" .. key }, "Disable " .. ch.n, function() Features.set(ch, false) end)
end
alias("speed", "ws"); alias("jump", "jp"); alias("infinitejump", "infjump"); alias("unnoclip", "clip")
alias("fullbright", "fb"); alias("lowgravity", "grav"); alias("freecam", "fc"); alias("antiafk", "afk")
alias("clicktp", "ctp"); alias("unfly", "nofly"); alias("godmode", "god")

addCmd({ "goto", "to" }, "Teleport to a player", function(args)
	local p = M.findPlayer(args[1])
	if not p then return "Player not found" end
	M.gotoPlayer(p)
end, "goto [player]")
addCmd({ "view", "spectate" }, "Spectate a player", function(args)
	local p = M.findPlayer(args[1])
	if not p then return "Player not found" end
	M.view(p)
end, "view [player]")
addCmd({ "unview", "unspectate" }, "Stop spectating", function() M.unview(); return "View reset" end)
addCmd({ "tp", "tpposition" }, "Teleport to coordinates", function(args)
	local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
	if not (x and y and z) then return "Usage: tp x y z" end
	M.tpTo(CFrame.new(x, y, z))
end, "tp [x] [y] [z]")
addCmd({ "setwaypoint", "swp" }, "Save a waypoint at your position", function(args) return M.addWP(table.concat(args, " ")) end, "swp [name]")
addCmd({ "waypoint", "wp" }, "Teleport to a waypoint", function(args)
	local w = M.findWP(table.concat(args, " "))
	if not w then return "Waypoint not found" end
	M.tpTo(CFrame.new(w.x, w.y, w.z))
end, "wp [name]")
addCmd({ "deletewaypoint", "dwp" }, "Delete a waypoint", function(args)
	local name, WP = table.concat(args, " "):lower(), M.saved.waypoints
	for i = #WP, 1, -1 do
		if WP[i].pid == game.PlaceId and WP[i].n:lower() == name then
			table.remove(WP, i); cfg.save()
			if M.refreshPlaces then M.refreshPlaces() end
			return "Deleted " .. name
		end
	end
	return "Waypoint not found"
end, "dwp [name]")
addCmd({ "clearwaypoints", "cwp" }, "Delete this place's waypoints", function()
	local WP = M.saved.waypoints
	for i = #WP, 1, -1 do if WP[i].pid == game.PlaceId then table.remove(WP, i) end end
	cfg.save()
	if M.refreshPlaces then M.refreshPlaces() end
	return "Waypoints cleared"
end)
addCmd({ "notify" }, "Show a notification", function(args) M.notify(table.concat(args, " ")) end, "notify [text]")
addCmd({ "ping" }, "Show your ping", function() return math.round(M.LP:GetNetworkPing() * 1000) .. "ms" end)
addCmd({ "reset", "respawn" }, "Reset your character", function() local h = M.getHum(); if h then h.Health = 0 end end)
addCmd({ "sit" }, "Sit down", function() local h = M.getHum(); if h then h.Sit = true end end)
addCmd({ "rejoin", "rj" }, "Rejoin this server", function()
	if #M.Players:GetPlayers() <= 1 then
		M.LP:Kick("\nRejoining…")
		task.wait(0.3)
		M.TeleportService:Teleport(game.PlaceId, M.LP)
	else
		M.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, M.LP)
	end
end)
addCmd({ "hide" }, "Hide the menu", function() M.setMenu(false) end)
addCmd({ "show" }, "Show the menu", function() M.setMenu(true) end)

-- customisation commands
addCmd({ "theme" }, "Set a theme (no argument = next theme)", function(args)
	local names = M.themeNames
	local want = args[1] and args[1]:lower()
	if want then
		for _, n in ipairs(names) do
			if n:lower() == want then cfg.set("theme", n); return "Theme: " .. n end
		end
		return "Themes: " .. table.concat(names, ", ")
	end
	local idx = 1
	for i, n in ipairs(names) do if n == S.theme then idx = i end end
	local nxt = names[idx % #names + 1]
	cfg.set("theme", nxt)
	return "Theme: " .. nxt
end, "theme [name]")
addCmd({ "set" }, "Change any setting (see Settings page)", function(args)
	local it = args[1] and M.ITEMS[args[1]:lower()]
	if not it then return "Unknown setting" end
	local a, v = (args[2] or ""):lower(), nil
	if it.k == "toggle" then
		if a == "on" or a == "true" then v = true elseif a == "off" or a == "false" then v = false else v = not S[it.key] end
	elseif it.k == "slider" then
		local n = tonumber(a)
		v = n and math.clamp(n, it.min, it.max)
	elseif it.k == "opts" then
		for _, o in ipairs(it.opts) do if o:lower() == a then v = o end end
	end
	if v == nil then return "Invalid value for " .. it.key end
	cfg.set(it.key, v)
	return it.key .. " = " .. tostring(v)
end, "set [key] [value]")
for _, pair in ipairs({ { "opacity", "menuOpacity" }, { "scale", "menuScale" }, { "blur", "blur" }, { "roundness", "radius" } }) do
	addCmd({ pair[1] }, "Set " .. pair[2], function(args)
		local n = tonumber(args[1])
		if not n then return "Usage: " .. pair[1] .. " [number]" end
		local it = M.ITEMS[pair[2]:lower()]
		cfg.set(pair[2], math.clamp(n, it.min, it.max))
	end, pair[1] .. " [number]")
end
addCmd({ "cmds", "help" }, "How many commands exist", function() return #CmdList .. " commands · type to see them · chain with \\" end)
table.sort(CmdList, function(a, b) return a.n < b.n end)

function M.runCommand(line)
	for part in line:gmatch("[^\\]+") do
		local args = {}
		for w in part:gmatch("%S+") do table.insert(args, w) end
		local name = table.remove(args, 1)
		if name then
			name = (name:lower():gsub("^;", ""))
			local c = Cmds[name]
			if c then
				local ok, res = pcall(c.fn, args)
				if not ok then M.notify("Error: " .. tostring(res), M.acc(5))
				elseif type(res) == "string" then M.notify(res) end
			else
				M.notify("Unknown command: " .. name, M.acc(5))
			end
		end
	end
end

-- returns list of matching commands for the current text
function M.suggest(raw)
	local t = (raw:gsub("^;", "")):lower()
	local tok = t:match("^(%S*)") or ""
	local list = {}
	if tok == "" then return list end
	if t:find("%s") then
		if Cmds[tok] then list = { Cmds[tok] } end
		return list
	end
	for _, c in ipairs(CmdList) do
		for _, nm in ipairs(c.names) do
			if nm:sub(1, #tok) == tok then table.insert(list, c) break end
		end
		if #list >= 6 then break end
	end
	return list
end
