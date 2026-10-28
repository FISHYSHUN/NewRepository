--[[ kit: reusable UI components (controls, panels, toasts, tooltips) ]]
local M = ...
local S, cfg = M.S, M.cfg
local make, tw, round, stroke, pad, col = M.make, M.tw, M.round, M.stroke, M.pad, M.col
local UIS = M.UIS
local LEFT, RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right
local LO = Enum.SortOrder.LayoutOrder

--// global drag controller (sliders / bar) --------------------------------------------------
M.drag = { move = nil, release = nil }
M.connect(UIS.InputChanged, function(i)
	if M.drag.move and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then M.drag.move(i) end
end)
M.connect(UIS.InputEnded, function(i)
	if M.isPress(i) then
		local r = M.drag.release
		M.drag.move, M.drag.release = nil, nil
		if r then r() end
	end
end)

--// key capture (used by every keybind control) ------------------------------------------------
function M.captureKey(cb)
	if M.capturing then M.capturing(nil) end
	M.capturing = cb
end

--// click sound ---------------------------------------------------------------------------------
local snd = Instance.new("Sound")
snd.SoundId = "rbxassetid://6895079853"
snd.Parent = game:GetService("SoundService")
table.insert(M.cleanups, function() snd:Destroy() end)
function M.click()
	if S.sound then
		snd.Volume = (S.volume or 50) / 100
		snd:Play()
	end
end

--// toasts ---------------------------------------------------------------------------------------
local toastHolder, toastLayout, toastN = nil, nil, 0
local TOAST_POS = {
	["Bottom"] = { Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -26), Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom },
	["Top Right"] = { Vector2.new(1, 0), UDim2.new(1, -16, 0, 16), Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Top },
	["Bottom Left"] = { Vector2.new(0, 1), UDim2.new(0, 16, 1, -16), Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Bottom },
}
local function placeToasts()
	if not toastHolder then return end
	local p = TOAST_POS[S.toastPos] or TOAST_POS["Bottom"]
	toastHolder.AnchorPoint, toastHolder.Position = p[1], p[2]
	toastLayout.HorizontalAlignment, toastLayout.VerticalAlignment = p[3], p[4]
end
cfg.on("toastPos", placeToasts)

function M.notify(msg, color)
	if not S.notify then return end
	if not toastHolder then
		toastHolder = make("Frame", { Size = UDim2.fromOffset(460, 240), BackgroundTransparency = 1, ZIndex = 30 }, M.ui.gui)
		toastLayout = make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = LO }, toastHolder)
		placeToasts()
	end
	local accent = col(color or M.acc(1))
	toastN += 1
	local kids = {}
	for _, c in ipairs(toastHolder:GetChildren()) do if c:IsA("Frame") then table.insert(kids, c) end end
	table.sort(kids, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	while #kids >= 4 do table.remove(kids, 1):Destroy() end
	local f = make("Frame", { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), BackgroundColor3 = "bg", BackgroundTransparency = 1, LayoutOrder = toastN, ZIndex = 31 }, toastHolder)
	round(f, 15)
	pad(f, 0, 0, 16, 0)
	local st = stroke(f, accent, 1, 1)
	local dot = make("Frame", { Position = UDim2.new(0, 12, 0.5, -3.5), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = accent, BackgroundTransparency = 1, ZIndex = 32 }, f)
	round(dot, 4)
	local lb = make("TextLabel", { Position = UDim2.fromOffset(28, 0), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), Text = msg, W = 2, TextSize = 12, TextTransparency = 1, ZIndex = 32 }, f)
	tw(f, 0.25, { BackgroundTransparency = 0.05 })
	tw(st, 0.25, { Transparency = 0.35 })
	tw(dot, 0.25, { BackgroundTransparency = 0 })
	tw(lb, 0.25, { TextTransparency = 0 })
	task.delay(S.toastTime or 2, function()
		if not f.Parent then return end
		tw(f, 0.3, { BackgroundTransparency = 1 }); tw(st, 0.3, { Transparency = 1 }); tw(dot, 0.3, { BackgroundTransparency = 1 }); tw(lb, 0.3, { TextTransparency = 1 })
		task.delay(0.35, function() if f.Parent then f:Destroy() end end)
	end)
end

--// tooltip --------------------------------------------------------------------------------------
local tipF, tipL
local tipGen = 0
local function moveTip()
	local m, vp = UIS:GetMouseLocation(), M.ui.gui.AbsoluteSize
	tipF.Position = UDim2.fromOffset(math.min(m.X + 16, vp.X - 250), math.min(m.Y + 20, vp.Y - 90))
end
function M.hideTip() tipGen += 1; if tipF then tipF.Visible = false end end
function M.showTip(name, desc)
	if not S.tips or not desc then return end
	tipGen += 1
	local g = tipGen
	task.delay((S.tipDelay or 350) / 1000, function()
		if g ~= tipGen then return end
		if not tipF then
			tipF = make("Frame", { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), BackgroundColor3 = "bg", Visible = false, ZIndex = 40 }, M.ui.gui)
			round(tipF, 10)
			stroke(tipF, "line", 1)
			pad(tipF, 10, 7, 10, 7)
			tipL = make("TextLabel", { Size = UDim2.fromOffset(210, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, RichText = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, TextSize = 11.5, ZIndex = 41 }, tipF)
		end
		tipL.Text = string.format('<font color="#%s"><b>%s</b></font>\n<font color="#%s">%s</font>', M.T.bright:ToHex(), name, M.T.dim:ToHex(), desc)
		moveTip()
		tipF.Visible = true
	end)
end
M.connect(UIS.InputChanged, function(i)
	if tipF and tipF.Visible and i.UserInputType == Enum.UserInputType.MouseMovement then moveTip() end
end)

--// controls ----------------------------------------------------------------------------------------
-- every control returns (frame, setter) ; setter updates the visual without firing the callback
function M.toggle(parent, o)
	local h = o.desc and 44 or 26
	local accent = o.accent or M.acc(1)
	local f = make("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = o.order or 0 }, parent)
	make("TextLabel", { Size = UDim2.new(1, -56, 0, o.desc and 22 or h), Text = o.label, TextSize = 12.5, TextXAlignment = LEFT }, f)
	if o.desc then make("TextLabel", { Position = UDim2.fromOffset(0, 21), Size = UDim2.new(1, -56, 0, 18), Text = o.desc, TextSize = 10.5, TextColor3 = "dim", TextXAlignment = LEFT }, f) end
	local on = o.value and true or false
	local sw = make("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(38, 20) }, f)
	M.bind(sw, "BackgroundColor3", function(T) return on and col(accent) or T.track end)
	round(sw, 10)
	local knob = make("Frame", { Position = UDim2.fromOffset(on and 21 or 3, 3), Size = UDim2.fromOffset(14, 14) }, sw)
	M.bind(knob, "BackgroundColor3", function(T) return on and T.bright or T.knob end)
	round(knob, 7)
	local function apply(v, fire)
		on = v
		tw(sw, 0.3, { BackgroundColor3 = on and col(accent) or M.T.track })
		tw(knob, 0.35, { Position = UDim2.fromOffset(on and 21 or 3, 3), BackgroundColor3 = on and M.T.bright or M.T.knob }, Enum.EasingStyle.Back)
		if fire and o.cb then o.cb(on) end
	end
	make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, f).MouseButton1Click:Connect(function() M.click(); apply(not on, true) end)
	return f, function(v) apply(v and true or false, false) end
end

function M.slider(parent, o)
	local accent = o.accent or M.acc(1)
	local f = make("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = o.order or 0 }, parent)
	make("TextLabel", { Size = UDim2.new(0.7, 0, 0, 18), Text = o.label, TextSize = 12.5, TextXAlignment = LEFT }, f)
	local vL = make("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.3, 0, 0, 18), W = 2, TextSize = 12, TextColor3 = accent, TextXAlignment = RIGHT }, f)
	local track = make("Frame", { Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = "track" }, f)
	round(track, 3)
	local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = accent }, track)
	round(fill, 3)
	local knob = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = "bright" }, track)
	round(knob, 7)
	stroke(knob, "line", 1)
	local min, max, unit = o.min, o.max, o.unit or ""
	local function set(v, fire)
		v = math.clamp(math.floor(v + 0.5), min, max)
		local fr = (v - min) / math.max(1, max - min)
		vL.Text = v .. unit
		tw(fill, 0.08, { Size = UDim2.fromScale(fr, 1) })
		tw(knob, 0.08, { Position = UDim2.fromScale(fr, 0.5) })
		if fire and o.cb then o.cb(v) end
	end
	set(o.value or min, false)
	local hit = make("TextButton", { Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, f)
	hit.InputBegan:Connect(function(i)
		if not M.isPress(i) then return end
		M.drag.move = function(inp) set(min + (max - min) * math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1), true) end
		M.drag.move(i)
	end)
	return f, function(v) set(v, false) end
end

function M.options(parent, o)
	local accent = o.accent or M.acc(1)
	local f = make("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = o.order or 0 }, parent)
	make("TextLabel", { Size = UDim2.new(1, -150, 1, 0), Text = o.label, TextSize = 12.5, TextXAlignment = LEFT }, f)
	local btn = make("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(140, 26), BackgroundColor3 = "panel", TextSize = 11.5, W = 2, TextColor3 = accent }, f)
	round(btn, 8)
	stroke(btn, "line", 1)
	local idx = 1
	for i, v in ipairs(o.opts) do if v == o.value then idx = i end end
	local function show() btn.Text = "‹  " .. o.opts[idx] .. "  ›" end
	show()
	btn.MouseButton1Click:Connect(function() M.click(); idx = idx % #o.opts + 1; show(); if o.cb then o.cb(o.opts[idx]) end end)
	btn.MouseButton2Click:Connect(function() M.click(); idx = (idx - 2) % #o.opts + 1; show(); if o.cb then o.cb(o.opts[idx]) end end)
	return f, function(v) for i, x in ipairs(o.opts) do if x == v then idx = i end end; show() end
end

function M.keyBtn(parent, o)
	local accent = o.accent or M.acc(1)
	local f = make("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = o.order or 0 }, parent)
	make("TextLabel", { Size = UDim2.new(1, -110, 1, 0), Text = o.label, TextSize = 12.5, TextXAlignment = LEFT }, f)
	local value = o.value
	local btn = make("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(100, 26), BackgroundColor3 = "panel", Text = M.keyLabel(value), Mono = true, TextSize = 11.5, TextColor3 = accent }, f)
	round(btn, 8)
	stroke(btn, "line", 1)
	btn.MouseButton1Click:Connect(function()
		btn.Text = "press a key…"
		M.captureKey(function(name)
			if name then value = name; if o.cb then o.cb(name) end end
			btn.Text = M.keyLabel(value)
		end)
	end)
	return f, function(v) value = v; btn.Text = M.keyLabel(v) end
end

function M.button(parent, o)
	local accent = o.accent or M.acc(1)
	local b = make("TextButton", { Size = UDim2.new(1, 0, 0, o.h or 32), BackgroundColor3 = "panel", Text = o.label, TextSize = 12, W = 2, TextColor3 = accent, LayoutOrder = o.order or 0 }, parent)
	round(b, 10)
	local st = stroke(b, accent, 1, 0.6)
	b.MouseEnter:Connect(function() tw(st, 0.15, { Transparency = 0 }); tw(b, 0.15, { BackgroundColor3 = M.T.panel:Lerp(col(accent), 0.18) }) end)
	b.MouseLeave:Connect(function() tw(st, 0.15, { Transparency = 0.6 }); tw(b, 0.15, { BackgroundColor3 = "panel" }) end)
	b.MouseButton1Click:Connect(function() M.click(); if o.cb then o.cb() end end)
	return b
end

function M.pill(parent, label, accent, xOff, w)
	local b = make("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0), Size = UDim2.fromOffset(w or 46, 22), BackgroundColor3 = "panel", Text = label, TextSize = 10, W = 2, TextColor3 = accent }, parent)
	round(b, 11)
	local st = stroke(b, accent, 1, 0.55)
	b.MouseEnter:Connect(function() tw(st, 0.15, { Transparency = 0 }); tw(b, 0.15, { BackgroundColor3 = M.T.panel:Lerp(col(accent), 0.2) }) end)
	b.MouseLeave:Connect(function() tw(st, 0.15, { Transparency = 0.55 }); tw(b, 0.15, { BackgroundColor3 = "panel" }) end)
	return b
end

--// card group with title (used by settings) -------------------------------------------------------------
function M.group(parent, title, order)
	local g = make("Frame", { AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = "card", LayoutOrder = order or 0 }, parent)
	round(g, 12)
	stroke(g, "line", 1)
	pad(g, 14, 12, 14, 12)
	make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = LO }, g)
	make("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Text = title, TextSize = 10.5, W = 3, TextColor3 = "dim", TextXAlignment = LEFT, LayoutOrder = 0 }, g)
	return g
end

--// animated section panel (used by card / list pages) -----------------------------------------------------
function M.panel(pg, idx, name, icon, accIdx, cellSize, ox, oy)
	local ac = M.acc(accIdx)
	local cell = make("Frame", { BackgroundTransparency = 1, LayoutOrder = idx, Size = cellSize or UDim2.fromOffset(302, 224) }, pg.sf)
	local cg = make("CanvasGroup", { AnchorPoint = Vector2.new(ox, oy), Position = UDim2.fromScale(ox, oy), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1 }, cell)
	local scale = make("UIScale", { Scale = 0.85 }, cg)
	local pb = make("Frame", { Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 1, -4), BackgroundColor3 = Color3.new(1, 1, 1) }, cg)
	round(pb, 16)
	stroke(pb, function(T) return T.line:Lerp(ac(T), 0.25) end, 1)
	make("UIGradient", { Rotation = 90, Color = function(T)
		return ColorSequence.new({ ColorSequenceKeypoint.new(0, T.panel:Lerp(ac(T), 0.1)), ColorSequenceKeypoint.new(0.7, T.panel), ColorSequenceKeypoint.new(1, T.panel) })
	end }, pb)
	local chipF = make("Frame", { Position = UDim2.fromOffset(14, 9), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = function(T) return T.panel:Lerp(ac(T), 0.25) end }, pb)
	round(chipF, 8)
	make("TextLabel", { Size = UDim2.fromScale(1, 1), Text = icon, TextSize = 13 }, chipF)
	make("TextLabel", { Position = UDim2.fromOffset(46, 0), Size = UDim2.new(0.45, 0, 0, 42), Text = name, W = 3, TextSize = 12, TextXAlignment = LEFT }, pb)
	local count = make("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(0.5, 0, 0, 42), TextSize = 11, TextColor3 = "dim", RichText = true, TextXAlignment = RIGHT }, pb)
	local hold = make("Frame", { Position = UDim2.fromOffset(12, 46), Size = UDim2.new(1, -24, 1, -58), BackgroundTransparency = 1 }, pb)
	local panel = { cg = cg, scale = scale, hold = hold, count = count, cards = {}, acc = ac }
	table.insert(pg.panels, panel)
	return panel
end
