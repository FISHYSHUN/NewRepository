--[[ shell: window, top bar, tabs, header, command bar, page + open/close management ]]
local M = ...
local S, cfg = M.S, M.cfg
local make, tw, round, stroke, pad = M.make, M.tw, M.round, M.stroke, M.pad
local UIS, RunService = M.UIS, M.RunService
local LEFT = Enum.TextXAlignment.Left
local ROOT_W, FRAME_H = 680, 570
M.FRAME_H = FRAME_H

--// gui + root --------------------------------------------------------------------------------------
local gui = make("ScreenGui", { Name = "CheatMenuUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
gui.Parent = M.getParent()
M.ui.gui, M.Gui = gui, gui

local root = make("Frame", { Name = "Root", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 30), Size = UDim2.fromOffset(ROOT_W, 720), BackgroundTransparency = 1 }, gui)
M.ui.root = root
local rootScale = make("UIScale", {}, root)
M.ui.rootScale = rootScale
local function fit()
	local v = gui.AbsoluteSize
	rootScale.Scale = math.clamp(math.min(v.X / 720, (v.Y - 40) / 710), 0.45, 1) * ((S.menuScale or 100) / 100)
end
M.connect(gui:GetPropertyChangedSignal("AbsoluteSize"), fit)
cfg.on("menuScale", fit, true)

local DEFAULT_POS = UDim2.new(0.5, 0, 0, 30)
function M.resetPosition()
	root.Position = DEFAULT_POS
	M.saved.pos = nil
	cfg.save()
end
if M.saved.pos and tonumber(M.saved.pos.x) and tonumber(M.saved.pos.y) then
	root.Position = UDim2.new(0.5, M.saved.pos.x, 0, M.saved.pos.y)
end

--// neon chase border ---------------------------------------------------------------------------------------
local chasers = {}
local function chaseStroke(parent)
	local state = false
	local st = make("UIStroke", { Color = function(T) return state and T.bright or T.idle end, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
	local g = make("UIGradient", {
		Color = function(T) return ColorSequence.new(T.c1, T.c2) end,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(0.7, 0), NumberSequenceKeypoint.new(0.9, 0), NumberSequenceKeypoint.new(1, 1) }),
		Enabled = false,
	}, st)
	table.insert(chasers, g)
	return function(on)
		state = on
		g:SetAttribute("on", on)
		g.Enabled = on and S.glow
		tw(st, 0.4, { Thickness = on and (S.borderThick or 2) or 1, Color = function(T) return state and T.bright or T.idle end })
	end
end
M.connect(RunService.Heartbeat, function()
	local r = (os.clock() * (S.chaseSpeed or 180)) % 360
	for _, g in ipairs(chasers) do if g.Enabled then g.Rotation = r end end
end)
cfg.on("glow", function(v) for _, g in ipairs(chasers) do g.Enabled = v and g:GetAttribute("on") == true end end)

--// top bar --------------------------------------------------------------------------------------------------------
local barLive = false
local bar = make("TextButton", { Name = "Bar", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(150, 40), BackgroundColor3 = "bg" }, root)
round(bar, 20)
local barChase = chaseStroke(bar)
local barDot = make("Frame", { Position = UDim2.new(0, 26, 0.5, -3.5), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = function(T) return barLive and T.accents[1] or T.idle end }, bar)
round(barDot, 4)
local function barTextCol(T) return barLive and T.bright or T.idleText end
local barText = make("TextLabel", { Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -72, 1, 0), Text = "CHEATS", W = 2, TextSize = 13, TextColor3 = barTextCol, TextXAlignment = LEFT }, bar)
local barBadge = make("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(22, 16), Text = "0", W = 3, TextSize = 10, TextColor3 = "onAcc", BackgroundColor3 = M.acc(1), BackgroundTransparency = 1, TextTransparency = 1 }, bar)
round(barBadge, 8)
local function setBarLive(on)
	barLive = on
	barChase(on)
	tw(barDot, 0.4, { BackgroundColor3 = function(T) return barLive and T.accents[1] or T.idle end })
	tw(barText, 0.4, { TextColor3 = barTextCol })
end
M.on("active", function()
	local n = 0
	for _, ch in ipairs(M.FLAT) do if ch.on then n += 1 end end
	barBadge.Text = tostring(n)
	tw(barBadge, 0.25, { BackgroundTransparency = n > 0 and 0 or 1, TextTransparency = n > 0 and 0 or 1 })
end)

--// tabs --------------------------------------------------------------------------------------------------------------
local TB = { { "MAIN", "⭐" }, { "MORE", "➕" }, { "PLAYERS", "👥" }, { "PLACES", "📍" }, { "BINDS", "⌨" }, { "SETTINGS", "⚙" } }
local TAB_X, TAB_Y = (ROOT_W - (5 * 100 + 94)) / 2, 56
local tabs = {}
for i, tb in ipairs(TB) do
	local live = false
	local function tcol(T) return live and T.bright or T.idleText end
	local cg = make("CanvasGroup", { Size = UDim2.fromOffset(94, 38), Position = UDim2.fromOffset(TAB_X + (i - 1) * 100, TAB_Y - 16), BackgroundTransparency = 1, GroupTransparency = 1 }, root)
	local btn = make("TextButton", { Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundColor3 = "bg", Text = tb[2] .. " " .. tb[1], W = 2, TextSize = 11, TextColor3 = tcol }, cg)
	round(btn, 16)
	local chase = chaseStroke(btn)
	tabs[i] = { cg = cg, setLive = function(on) live = on; chase(on); tw(btn, 0.3, { TextColor3 = tcol }) end }
	btn.MouseButton1Click:Connect(function() M.click(); M.setPage(i) end)
end
local function setLive(idx) for k, t in ipairs(tabs) do t.setLive(k == idx) end end

--// frame, header, holder ---------------------------------------------------------------------------------------------------
local frame = make("Frame", { Name = "Frame", Position = UDim2.fromOffset(18, 110), Size = UDim2.new(1, -36, 0, 0), BackgroundColor3 = Color3.new(1, 1, 1), ClipsDescendants = true, Visible = false }, root)
round(frame, 20)
stroke(frame, "line", 1)
make("UIGradient", { Rotation = 90, Color = function(T) return ColorSequence.new(T.top, T.bot) end }, frame)
cfg.on("menuOpacity", function(v) frame.BackgroundTransparency = 1 - v / 100 end, true)
local body = make("Frame", { Size = UDim2.new(1, 0, 0, FRAME_H), BackgroundTransparency = 1 }, frame)
local headerL = make("TextLabel", { Position = UDim2.fromOffset(18, 12), Size = UDim2.new(0.5, 0, 0, 14), W = 2, TextSize = 10.5, TextColor3 = "dim", TextXAlignment = LEFT }, body)
local hintL = make("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 12), Size = UDim2.new(0.5, 0, 0, 14), W = 2, TextSize = 10.5, TextColor3 = "hint", TextXAlignment = Enum.TextXAlignment.Right }, body)
local holder = make("Frame", { Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 1, -82), BackgroundTransparency = 1 }, body)
M.ui.frame, M.ui.body, M.ui.holder = frame, body, holder

--// pages -----------------------------------------------------------------------------------------------------------------------
M.pages, M.PINFO = {}, {}
M.cur, M.isOpen = 1, false
function M.newPage(grid)
	local sf = make("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = "line", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, holder)
	pad(sf, 14, 10, 14, 14)
	if grid then make("UIGridLayout", { CellSize = UDim2.fromOffset(302, 224), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
	else make("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, sf) end
	local pg = { sf = sf, panels = {} }
	table.insert(M.pages, pg)
	return pg
end

local pageGen, openGen = 0, 0
local function enterPage(i)
	pageGen += 1
	local g = pageGen
	for si, p in ipairs(M.pages[i].panels) do
		p.cg.GroupTransparency, p.scale.Scale = 1, 0.85
		for _, c in ipairs(p.cards) do c.scale.Scale = 0.7 end
		task.delay(0.2 + (si - 1) * 0.11, function()
			if g ~= pageGen then return end
			tw(p.cg, 0.45, { GroupTransparency = 0 })
			tw(p.scale, 0.65, { Scale = 1 }, Enum.EasingStyle.Back)
			for j, c in ipairs(p.cards) do
				task.delay(0.15 + ((j - 1) % 10) * 0.045, function()
					if g == pageGen then tw(c.scale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back) end
				end)
			end
		end)
	end
end

function M.setPage(i)
	local old = M.cur
	M.cur = i
	if old ~= i and M.pages[old].sf.Visible then
		for _, p in ipairs(M.pages[old].panels) do tw(p.cg, 0.15, { GroupTransparency = 1 }) end
		task.delay(0.17, function() if M.cur ~= old then M.pages[old].sf.Visible = false end end)
	end
	M.pages[i].sf.Visible = true
	M.pages[i].sf.CanvasPosition = Vector2.zero
	local info = M.PINFO[i]
	if info then headerL.Text, hintL.Text = info[1], info[2] end
	if M.hideConfig then M.hideConfig() end
	M.hideTip()
	if M.onPage then M.onPage(i) end
	if M.isOpen then setLive(i) end
	enterPage(i)
	if S.rememberPage then M.saved.page = i; cfg.save() end
end

--// blur ----------------------------------------------------------------------------------------------------------------------------------
local blur
local function setBlur(on)
	if not blur then
		if (S.blur or 0) <= 0 then return end
		blur = Instance.new("BlurEffect")
		blur.Name = "CM_Blur"; blur.Size = 0
		blur.Parent = M.Lighting
		table.insert(M.cleanups, function() blur:Destroy() end)
	end
	tw(blur, 0.4, { Size = on and (S.blur or 0) or 0 })
end
cfg.on("blur", function() if M.isOpen then setBlur(true) end end)

--// command bar ---------------------------------------------------------------------------------------------------------------------------------
local cmdFrame = make("Frame", { Position = UDim2.new(0, 14, 1, -42), Size = UDim2.new(1, -28, 0, 32), BackgroundColor3 = "card", ZIndex = 3 }, body)
round(cmdFrame, 16)
local cmdStroke = stroke(cmdFrame, "line", 1)
make("TextLabel", { Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(14, 32), Text = "›", W = 3, TextSize = 16, TextColor3 = M.acc(1), ZIndex = 4 }, cmdFrame)
local cmdBox = make("TextBox", { Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -44, 1, 0), BackgroundTransparency = 1, PlaceholderText = "command…   e.g. fly 8  ·  goto name  ·  theme  ·  set blur 12  ·  cmds", PlaceholderColor3 = "dim", Mono = true, TextSize = 13, TextXAlignment = LEFT, ZIndex = 4 }, cmdFrame)
M.ui.cmdBox = cmdBox
local sugg = make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -48), Size = UDim2.new(1, -28, 0, 0), BackgroundColor3 = "pop", Visible = false, ZIndex = 6, ClipsDescendants = true }, body)
round(sugg, 12)
stroke(sugg, "line", 1)
pad(sugg, 4, 4, 4, 4)
make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, sugg)
local suggRows, topSug = {}, nil
local hist, histIdx = {}, 0
M.cmdHist = function() return hist end

function M.completeTop()
	if topSug then
		cmdBox.Text = topSug.names[1] .. " "
		cmdBox.CursorPosition = #cmdBox.Text + 1
	end
end
local function refreshSuggest()
	for _, r in ipairs(suggRows) do r:Destroy() end
	suggRows, topSug = {}, nil
	local list = cmdBox:IsFocused() and M.suggest(cmdBox.Text) or {}
	topSug = list[1]
	for i, c in ipairs(list) do
		local row = make("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 7 }, sugg)
		make("TextLabel", { Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), RichText = true, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, TextSize = 11.5, ZIndex = 8,
			Text = string.format('<font color="#%s">%s</font>   <font color="#%s">%s</font>', M.T.accents[1]:ToHex(), c.usage, M.T.dim:ToHex(), c.desc) }, row)
		row.MouseEnter:Connect(function() row.BackgroundColor3 = M.T.accents[1]; row.BackgroundTransparency = 0.88 end)
		row.MouseLeave:Connect(function() row.BackgroundTransparency = 1 end)
		row.MouseButton1Click:Connect(function() topSug = c; M.completeTop(); cmdBox:CaptureFocus() end)
		table.insert(suggRows, row)
	end
	sugg.Visible = #list > 0
	sugg.Size = UDim2.new(1, -28, 0, #list * 22 + 8)
end
M.refreshSuggest = refreshSuggest
cmdBox:GetPropertyChangedSignal("Text"):Connect(refreshSuggest)
cmdBox.Focused:Connect(function() tw(cmdStroke, 0.2, { Color = M.acc(1) }); refreshSuggest() end)
cmdBox.FocusLost:Connect(function(enter)
	tw(cmdStroke, 0.2, { Color = "line" })
	if enter and cmdBox.Text ~= "" then
		table.insert(hist, 1, cmdBox.Text)
		if #hist > 30 then table.remove(hist) end
		M.runCommand(cmdBox.Text)
	end
	histIdx = 0
	cmdBox.Text = ""
	task.defer(refreshSuggest)
end)
function M.historyStep(dir)
	histIdx = math.clamp(histIdx + dir, 0, #hist)
	cmdBox.Text = hist[histIdx] or ""
	cmdBox.CursorPosition = #cmdBox.Text + 1
end

--// open / close --------------------------------------------------------------------------------------------------------------------------------------
function M.setMenu(open)
	M.isOpen = open
	openGen += 1
	local g = openGen
	setBarLive(open)
	setBlur(open)
	if open then
		frame.Size, frame.Visible = UDim2.new(1, -36, 0, 0), true
		tw(frame, 0.65, { Size = UDim2.new(1, -36, 0, FRAME_H) }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		for i, t in ipairs(tabs) do
			task.delay(0.1 + (i - 1) * 0.07, function()
				if g ~= openGen then return end
				tw(t.cg, 0.3, { GroupTransparency = 0 })
				tw(t.cg, 0.55, { Position = UDim2.fromOffset(TAB_X + (i - 1) * 100, TAB_Y) }, Enum.EasingStyle.Back)
			end)
		end
		task.delay(0.15, function() if g == openGen then M.pages[M.cur].sf.Visible = true; enterPage(M.cur) end end)
		task.delay(0.6, function() if g == openGen then setLive(M.cur) end end)
	else
		if M.hideConfig then M.hideConfig() end
		M.hideTip()
		cmdBox:ReleaseFocus()
		setLive(0)
		for i, t in ipairs(tabs) do
			tw(t.cg, 0.25, { GroupTransparency = 1, Position = UDim2.fromOffset(TAB_X + (i - 1) * 100, TAB_Y - 16) })
		end
		pageGen += 1
		for _, p in ipairs(M.pages[M.cur].panels) do tw(p.cg, 0.15, { GroupTransparency = 1 }) end
		tw(frame, 0.45, { Size = UDim2.new(1, -36, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.delay(0.47, function()
			if g == openGen then
				frame.Visible = false
				for _, pg in ipairs(M.pages) do pg.sf.Visible = false end
			end
		end)
	end
end

--// bar: click to toggle, drag to move ------------------------------------------------------------------------------------------------------------------
bar.InputBegan:Connect(function(i)
	if not M.isPress(i) then return end
	local startMouse, startPos, moved = i.Position, root.Position, false
	M.drag.move = function(inp)
		if S.lockPos then return end
		local d = inp.Position - startMouse
		if moved or d.Magnitude > 6 then
			moved = true
			root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end
	M.drag.release = function()
		if not moved then
			M.setMenu(not M.isOpen)
		else
			M.saved.pos = { x = root.Position.X.Offset, y = root.Position.Y.Offset }
			cfg.save()
		end
	end
end)
