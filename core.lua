--[[ core: services, helpers, theme-aware instance factory ]]
local M = ...
M.Version = "3.0"

M.Players = game:GetService("Players")
M.TweenService = game:GetService("TweenService")
M.UIS = game:GetService("UserInputService")
M.RunService = game:GetService("RunService")
M.Lighting = game:GetService("Lighting")
M.Workspace = game:GetService("Workspace")
M.HttpService = game:GetService("HttpService")
M.CAS = game:GetService("ContextActionService")
M.TeleportService = game:GetService("TeleportService")
M.VirtualUser = game:GetService("VirtualUser")
M.LP = M.Players.LocalPlayer

M.S, M.T, M.ui = {}, {}, {}
M.binds, M.texts, M.corners, M.conns, M.cleanups = {}, {}, {}, {}, {}
M.Hooks = {
	OnToggle = function(name, state) end,
	OnSwitch = function(cheat, label, state) end,
	OnSlider = function(cheat, label, value) end,
	OnKeybind = function(cheat, keyName) end,
}

function M.connect(sig, fn)
	local c = sig:Connect(fn)
	table.insert(M.conns, c)
	return c
end

--// tiny event bus
local ev = {}
function M.on(name, fn) ev[name] = ev[name] or {}; table.insert(ev[name], fn) end
function M.fire(name, ...)
	for _, f in ipairs(ev[name] or {}) do pcall(f, ...) end
end

--// file helpers
M.fs = {}
function M.fs.read(path)
	if readfile and isfile and isfile(path) then
		local ok, r = pcall(readfile, path)
		if ok and r ~= nil and r ~= "" then return r end
	end
end
function M.fs.write(path, data)
	if not writefile then return false end
	pcall(function() if makefolder and isfolder and not isfolder("CheatMenuUI") then makefolder("CheatMenuUI") end end)
	return pcall(writefile, path, data)
end
function M.setClipboard(str)
	local f = setclipboard or toclipboard or set_clipboard
	if f then pcall(f, tostring(str)); return true end
	return false
end

--// character helpers
function M.getHum(c)
	c = c or M.LP.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
function M.getRoot(c)
	c = c or M.LP.Character
	if not c then return nil end
	return c:FindFirstChild("HumanoidRootPart") or (M.getHum(c) and M.getHum(c).RootPart)
end
function M.isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

--// accent palette accessor: returns fn(T) -> Color3
function M.acc(i)
	return function(T) return T.accents[((i - 1) % #T.accents) + 1] end
end

local KL = {
	One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0",
	Semicolon = ";", Comma = ",", Period = ".", Slash = "/", Backslash = "\\", Minus = "-", Equals = "=", LeftBracket = "[",
	RightBracket = "]", Quote = "'", Backquote = "`", Return = "Enter", Space = "Space", RightShift = "R-Shift",
	LeftShift = "L-Shift", LeftControl = "L-Ctrl", RightControl = "R-Ctrl", LeftAlt = "L-Alt", RightAlt = "R-Alt",
	Backspace = "Bksp", Insert = "Ins", Delete = "Del", PageUp = "PgUp", PageDown = "PgDn",
}
function M.keyLabel(name) return KL[name] or tostring(name) end

--// theme binding ---------------------------------------------------------------
local COLOR = { BackgroundColor3 = true, TextColor3 = true, BorderColor3 = true, ImageColor3 = true, ScrollBarImageColor3 = true, PlaceholderColor3 = true, TextStrokeColor3 = true, Color = true }
local function resolve(v)
	if type(v) == "string" then return function(T) return T[v] end end
	return v
end
function M.bind(inst, prop, fn)
	table.insert(M.binds, { inst, prop, fn })
	pcall(function() inst[prop] = fn(M.T) end)
end
function M.refreshTheme()
	local T = M.T
	for i = #M.binds, 1, -1 do
		local b = M.binds[i]
		if b[1].Parent == nil then table.remove(M.binds, i)
		else pcall(function() b[1][b[2]] = b[3](T) end) end
	end
	M.fire("theme")
end

--// text registry (font family + size scale) ------------------------------------------
local FAM = {
	Gotham = { Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold, 1 },
	Ubuntu = { Enum.Font.Ubuntu, Enum.Font.Ubuntu, Enum.Font.Ubuntu, 1.02 },
	SourceSans = { Enum.Font.SourceSans, Enum.Font.SourceSansSemibold, Enum.Font.SourceSansBold, 1.14 },
	Arial = { Enum.Font.Arial, Enum.Font.Arial, Enum.Font.ArialBold, 1 },
	Code = { Enum.Font.Code, Enum.Font.Code, Enum.Font.Code, 0.95 },
}
local function applyText(rec)
	local S = M.S
	local scale = (S.textScale or 100) / 100
	if rec.mono then
		rec.inst.Font = Enum.Font.Code
		rec.inst.TextSize = math.floor(rec.size * scale * 2 + 0.5) / 2
	else
		local fam = FAM[S.font or "Gotham"] or FAM.Gotham
		rec.inst.Font = fam[rec.w] or fam[1]
		rec.inst.TextSize = math.floor(rec.size * fam[4] * scale * 2 + 0.5) / 2
	end
end
function M.regText(inst, w, mono)
	local rec = { inst = inst, w = w, mono = mono, size = inst.TextSize }
	table.insert(M.texts, rec)
	applyText(rec)
end
function M.applyFonts()
	for i = #M.texts, 1, -1 do
		local r = M.texts[i]
		if r.inst.Parent == nil then table.remove(M.texts, i) else applyText(r) end
	end
end
function M.applyRadius()
	local k = (M.S.radius or 100) / 100
	for i = #M.corners, 1, -1 do
		local e = M.corners[i]
		if e[1].Parent == nil then table.remove(M.corners, i) else e[1].CornerRadius = UDim.new(0, e[2] * k) end
	end
end

--// factory ----------------------------------------------------------------------------
function M.make(class, props, parent)
	local inst = Instance.new(class)
	local W, Mono = props.W, props.Mono
	props.W, props.Mono = nil, nil
	local isText = class == "TextLabel" or class == "TextButton" or class == "TextBox"
	if isText then
		if props.TextColor3 == nil then props.TextColor3 = "text" end
		if props.TextSize == nil then props.TextSize = 12 end
		if props.Text == nil then props.Text = "" end
		if class == "TextLabel" and props.BackgroundTransparency == nil then props.BackgroundTransparency = 1 end
		if class == "TextButton" and props.AutoButtonColor == nil then props.AutoButtonColor = false end
		if class == "TextBox" and props.ClearTextOnFocus == nil then props.ClearTextOnFocus = false end
	end
	for k, v in pairs(props) do
		if COLOR[k] and (type(v) == "string" or type(v) == "function") then
			M.bind(inst, k, resolve(v))
		else
			inst[k] = v
		end
	end
	inst.Parent = parent
	if isText then M.regText(inst, W or 1, Mono) end
	return inst
end
function M.text(parent, props) return M.make("TextLabel", props, parent) end
function M.round(obj, r)
	local c = M.make("UICorner", { CornerRadius = UDim.new(0, r * (M.S.radius or 100) / 100) }, obj)
	table.insert(M.corners, { c, r })
	return c
end
function M.stroke(obj, color, th, tr)
	return M.make("UIStroke", { Color = color, Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, obj)
end
function M.pad(obj, l, t, r, b)
	return M.make("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b) }, obj)
end

--// tween (respects animation settings, resolves theme colors) -------------------------------
function M.tw(obj, t, props, style, dir)
	local S = M.S
	if S.animations == false then t = 0 else t = t / math.max(0.2, (S.animSpeed or 100) / 100) end
	for k, v in pairs(props) do
		if COLOR[k] then
			if type(v) == "string" then props[k] = M.T[v]
			elseif type(v) == "function" then props[k] = v(M.T) end
		end
	end
	local tween = M.TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

function M.col(v)
	local t = type(v)
	if t == "function" then return v(M.T) elseif t == "string" then return M.T[v] end
	return v
end

function M.getParent()
	local ok, h = pcall(function() return gethui and gethui() end)
	if ok and h then return h end
	local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and cg then
		local probe = Instance.new("Folder")
		local writable = pcall(function() probe.Parent = cg end)
		probe:Destroy()
		if writable then return cg end
	end
	return M.LP:WaitForChild("PlayerGui")
end

function M.Destroy()
	for i = #M.cleanups, 1, -1 do pcall(M.cleanups[i]) end
	for _, c in ipairs(M.conns) do pcall(function() c:Disconnect() end) end
	if M.ui.gui then pcall(function() M.ui.gui:Destroy() end) end
	pcall(function() if getgenv and getgenv().CheatMenuUI == M then getgenv().CheatMenuUI = nil end end)
end
