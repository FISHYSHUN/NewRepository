--[[ themes: presets + generated custom theme ]]
local M = ...
local S, cfg = M.S, M.cfg
local list, by = {}, {}
local function H(x) return Color3.fromHex(x) end

local function add(name, d)
	local T = { name = name, light = d.light }
	for _, k in ipairs({ "bg", "panel", "card", "line", "text", "dim", "c1", "c2" }) do T[k] = H(d[k]) end
	T.accents = {}
	for i, h in ipairs(d.acc) do T.accents[i] = H(h) end
	T.bright = d.light and H("111318") or Color3.new(1, 1, 1)
	T.onAcc = d.light and Color3.new(1, 1, 1) or T.bg
	T.hint = T.accents[4]:Lerp(T.dim, 0.45)
	T.idle = T.line:Lerp(T.dim, 0.45)
	T.idleText = T.dim
	T.track = T.line:Lerp(T.card, 0.25)
	T.knob = T.dim:Lerp(T.text, 0.35)
	T.top = T.panel:Lerp(T.card, 0.4)
	T.bot = T.bg:Lerp(T.panel, 0.6)
	T.pop = T.card:Lerp(T.panel, 0.4)
	table.insert(list, T)
	by[name] = T
	return T
end

add("Midnight", { bg = "0f1015", panel = "131522", card = "181a24", line = "2c2f3d", text = "c9cde0", dim = "6c7088", c1 = "22d3ee", c2 = "e879f9",
	acc = { "22d3ee", "34d399", "f59e0b", "e879f9", "f87171", "60a5fa", "a3e635", "fb923c" } })
add("Neon", { bg = "0a0612", panel = "120a1f", card = "1a1030", line = "3a2260", text = "f0e6ff", dim = "8a76b0", c1 = "ff2bd6", c2 = "00f0ff",
	acc = { "ff2bd6", "00f0ff", "fcee09", "7c3aed", "ff4d6d", "3b82f6", "39ff14", "ff9f1c" } })
add("Ocean", { bg = "0a1218", panel = "0f1c26", card = "142632", line = "24425a", text = "d6ecf7", dim = "6f93a8", c1 = "38bdf8", c2 = "2dd4bf",
	acc = { "38bdf8", "2dd4bf", "60a5fa", "22d3ee", "818cf8", "34d399", "facc15", "fb7185" } })
add("Forest", { bg = "0c130e", panel = "111c14", card = "16251a", line = "29402f", text = "dcebdd", dim = "7a967f", c1 = "4ade80", c2 = "a3e635",
	acc = { "4ade80", "a3e635", "facc15", "2dd4bf", "fb923c", "86efac", "34d399", "f472b6" } })
add("Sunset", { bg = "140d0d", panel = "1d1212", card = "261818", line = "4a2a2a", text = "f6e4dc", dim = "a07f78", c1 = "fb923c", c2 = "f43f5e",
	acc = { "fb923c", "f43f5e", "facc15", "e879f9", "f87171", "fbbf24", "fb7185", "a78bfa" } })
add("Rose", { bg = "140d12", panel = "1c121a", card = "261822", line = "47283d", text = "f8e1ee", dim = "a8798f", c1 = "f472b6", c2 = "c084fc",
	acc = { "f472b6", "c084fc", "fb7185", "e879f9", "f9a8d4", "a78bfa", "fda4af", "f0abfc" } })
add("Dracula", { bg = "191a21", panel = "21222c", card = "282a36", line = "44475a", text = "f8f8f2", dim = "6272a4", c1 = "bd93f9", c2 = "ff79c6",
	acc = { "bd93f9", "50fa7b", "f1fa8c", "ff79c6", "ff5555", "8be9fd", "ffb86c", "6272a4" } })
add("Nord", { bg = "242933", panel = "2b313c", card = "323a47", line = "434c5e", text = "e5e9f0", dim = "7b88a1", c1 = "88c0d0", c2 = "81a1c1",
	acc = { "88c0d0", "a3be8c", "ebcb8b", "b48ead", "bf616a", "81a1c1", "8fbcbb", "d08770" } })
add("Mono", { bg = "0e0e0e", panel = "151515", card = "1c1c1c", line = "333333", text = "e0e0e0", dim = "808080", c1 = "ffffff", c2 = "9a9a9a",
	acc = { "ffffff", "d0d0d0", "b0b0b0", "e8e8e8", "c8c8c8", "a8a8a8", "f0f0f0", "989898" } })
add("Light", { light = true, bg = "f4f5f8", panel = "ffffff", card = "eef0f6", line = "d3d7e2", text = "20232f", dim = "70758a", c1 = "3b82f6", c2 = "8b5cf6",
	acc = { "3b82f6", "10b981", "f59e0b", "8b5cf6", "ef4444", "0ea5e9", "65a30d", "f97316" } })

M.themes = list
M.themeNames = {}
for _, T in ipairs(list) do table.insert(M.themeNames, T.name) end
table.insert(M.themeNames, "Custom")

local function hsv(h, s, v) return Color3.fromHSV(h % 1, math.clamp(s, 0, 1), math.clamp(v, 0, 1)) end
local function hex(c) return string.format("%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end

function M.buildCustom()
	local h = S.customHue / 360
	local sat = S.customSat / 100
	local h2 = (S.customHue + S.customShift) / 360
	local b = 0.03 + (S.customBg / 100) * 0.3
	local tint = (S.customTint / 100) * 0.5
	local saved = { #list }
	local d = {
		bg = hex(hsv(h, tint, b)), panel = hex(hsv(h, tint, b + 0.03)), card = hex(hsv(h, tint * 0.95, b + 0.065)),
		line = hex(hsv(h, tint * 0.8, b + 0.17)), text = hex(hsv(h, 0.08, 0.9)), dim = hex(hsv(h, 0.14, 0.52)),
		c1 = hex(hsv(h, sat, 1)), c2 = hex(hsv(h2, sat, 1)), acc = {},
	}
	for i = 0, 7 do d.acc[i + 1] = hex(hsv(h + i * 0.125, sat, 0.96)) end
	-- build without registering in the preset list
	local n = #list
	local T = add("Custom", d)
	table.remove(list, n + 1)
	by.Custom = nil
	return T
end

function M.setTheme()
	local T = (S.theme == "Custom") and M.buildCustom() or by[S.theme] or list[1]
	M.T = T
	M.refreshTheme()
end
M.T = (S.theme == "Custom") and M.buildCustom() or by[S.theme] or list[1]

cfg.on("theme", function() M.setTheme() end)
for _, k in ipairs({ "customHue", "customSat", "customShift", "customBg", "customTint" }) do
	cfg.on(k, function()
		if S.theme ~= "Custom" then cfg.set("theme", "Custom", true); M.setTheme()
		else M.setTheme() end
	end)
end
cfg.on("font", function() M.applyFonts() end)
cfg.on("textScale", function() M.applyFonts() end)
cfg.on("radius", function() M.applyRadius() end)
