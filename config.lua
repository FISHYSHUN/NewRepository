--[[ config: settings schema, persistence, profiles, import / export ]]
local M = ...
local S, HttpService = M.S, M.HttpService
local cfg = {}
M.cfg = cfg
M.saved = { keys = {}, opts = {}, waypoints = {}, pos = nil, page = 1 }
local PATH = "CheatMenuUI/config.json"

local function tog(key, label, def, desc) return { k = "toggle", key = key, label = label, def = def, desc = desc } end
local function sli(key, label, min, max, def, unit, desc) return { k = "slider", key = key, label = label, min = min, max = max, def = def, unit = unit or "", desc = desc } end
local function opts(key, label, list, def, desc) return { k = "opts", key = key, label = label, opts = list, def = def, desc = desc } end
local function key(key_, label, def, desc) return { k = "key", key = key_, label = label, def = def, desc = desc } end

M.SCHEMA = {
	{ id = "appearance", title = "APPEARANCE", groups = {
		{ title = "WINDOW", items = {
			sli("menuOpacity", "Menu opacity", 40, 100, 92, "%"),
			sli("menuScale", "Menu scale", 70, 140, 100, "%"),
			sli("radius", "Roundness", 0, 200, 100, "%"),
			sli("blur", "Background blur", 0, 24, 0),
		} },
		{ title = "TEXT", items = {
			opts("font", "Font", { "Gotham", "Ubuntu", "SourceSans", "Arial", "Code" }, "Gotham"),
			sli("textScale", "Text size", 80, 130, 100, "%"),
		} },
		{ title = "CARDS", items = {
			tog("compact", "Compact cards", false),
			tog("showIcons", "Show card icons", true),
			tog("showHints", "Show key hints on cards", true),
		} },
		{ title = "EFFECTS", items = {
			tog("glow", "Neon border", true),
			sli("chaseSpeed", "Border speed", 30, 500, 180, "°/s"),
			sli("borderThick", "Active border width", 1, 4, 2, "px"),
			tog("animations", "Animations", true),
			sli("animSpeed", "Animation speed", 50, 250, 100, "%"),
		} },
	} },
	{ id = "behavior", title = "BEHAVIOR", groups = {
		{ title = "FEEDBACK", items = {
			tog("sound", "Click sounds", false),
			sli("volume", "Sound volume", 0, 100, 50, "%"),
			tog("notify", "Notifications", true),
			sli("toastTime", "Notification time", 1, 6, 2, "s"),
			opts("toastPos", "Notification position", { "Bottom", "Top Right", "Bottom Left" }, "Bottom"),
			tog("tips", "Tooltips", true),
			sli("tipDelay", "Tooltip delay", 0, 1000, 350, "ms"),
		} },
		{ title = "INTERACTION", items = {
			tog("closeOnToggle", "Close menu after toggling", false),
			sli("holdDelay", "Long-press delay", 200, 800, 450, "ms"),
			tog("autoOpen", "Open menu on load", false),
			tog("rememberPage", "Remember last page", true),
			tog("lockPos", "Lock menu position", false),
		} },
		{ title = "KEYS", items = {
			key("menuKey", "Show / hide menu", "RightShift"),
			key("cmdKey", "Focus command bar", "Semicolon"),
		} },
		{ title = "TELEPORT", items = {
			tog("tween", "Tween teleports", false),
			sli("tweenTime", "Tween time", 1, 5, 1, "s"),
		} },
	} },
}

local DEF = { theme = "Midnight", customHue = 190, customSat = 75, customShift = 70, customBg = 28, customTint = 35 }
M.ITEMS = {}
for _, sec in ipairs(M.SCHEMA) do
	for _, g in ipairs(sec.groups) do
		for _, it in ipairs(g.items) do
			DEF[it.key] = it.def
			M.ITEMS[it.key:lower()] = it
		end
	end
end
M.DEF = DEF
for k, v in pairs(DEF) do S[k] = v end

local function snapshot()
	local s = {}
	for k in pairs(DEF) do s[k] = S[k] end
	return s
end
local function applyTable(t, runtime)
	if type(t.settings) ~= "table" then return end
	for k, v in pairs(t.settings) do
		if DEF[k] ~= nil and type(v) == type(DEF[k]) then
			if runtime then cfg.set(k, v, true) else S[k] = v end
		end
	end
end

--// hooks ---------------------------------------------------------------------
local hooks = {}
function cfg.on(k, fn, now)
	hooks[k] = hooks[k] or {}
	table.insert(hooks[k], fn)
	if now then pcall(fn, S[k]) end
end
local savePending = false
function cfg.save()
	if not writefile or savePending then return end
	savePending = true
	task.delay(1.2, function()
		savePending = false
		local data = { v = 3, settings = snapshot(), keys = M.saved.keys, opts = M.saved.opts, waypoints = M.saved.waypoints, pos = M.saved.pos, page = M.saved.page }
		local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
		if ok then M.fs.write(PATH, json) end
	end)
end
function cfg.set(k, v, silent)
	S[k] = v
	for _, f in ipairs(hooks[k] or {}) do pcall(f, v) end
	if not silent then cfg.save() end
end

--// load -----------------------------------------------------------------------
do
	local raw = M.fs.read(PATH)
	if raw then
		local ok, d = pcall(function() return HttpService:JSONDecode(raw) end)
		if ok and type(d) == "table" then
			applyTable(d, false)
			if type(d.keys) == "table" then M.saved.keys = d.keys end
			if type(d.opts) == "table" then M.saved.opts = d.opts end
			if type(d.waypoints) == "table" then M.saved.waypoints = d.waypoints end
			if type(d.pos) == "table" then M.saved.pos = d.pos end
			if type(d.page) == "number" then M.saved.page = d.page end
		end
	end
end

--// import / export / profiles ----------------------------------------------------------
function cfg.export()
	return HttpService:JSONEncode({ settings = snapshot(), keys = M.saved.keys })
end
function cfg.import(str)
	local ok, d = pcall(function() return HttpService:JSONDecode(str) end)
	if not ok or type(d) ~= "table" or type(d.settings) ~= "table" then return false end
	applyTable(d, true)
	if type(d.keys) == "table" then M.saved.keys = d.keys; M.fire("keys") end
	cfg.save()
	return true
end
function cfg.reset()
	for k, v in pairs(DEF) do cfg.set(k, v, true) end
	M.saved.keys = {}
	M.fire("keys")
	cfg.save()
end
local function slotPath(n) return "CheatMenuUI/profile_" .. n .. ".json" end
function cfg.saveSlot(n) return M.fs.write(slotPath(n), cfg.export()) end
function cfg.loadSlot(n)
	local raw = M.fs.read(slotPath(n))
	return raw and cfg.import(raw) or false
end
function cfg.hasSlot(n) return M.fs.read(slotPath(n)) ~= nil end
