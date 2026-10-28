--[[ pages: cheat cards, players, places, binds, settings ]]
local M = ...
local S, cfg, FLAT = M.S, M.cfg, M.FLAT
local make, tw, round, stroke, pad = M.make, M.tw, M.round, M.stroke, M.pad
local acc, Features = M.acc, M.Features
local gui = M.ui.gui
local UIS = M.UIS
local LEFT, RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right
local LO = Enum.SortOrder.LayoutOrder

--// keybind chips ------------------------------------------------------------------------------------------
local function refreshChips(ch)
	for n = #ch.chips, 1, -1 do
		local c = ch.chips[n]
		if c.Parent then c.Text = M.keyLabel(ch.key) else table.remove(ch.chips, n) end
	end
	for _, h in ipairs(ch.hints) do h.Text = M.keyLabel(ch.key) end
end
M.refreshChips = refreshChips

local function keyChip(parent, ch, ac)
	local b = make("TextButton", { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 22), BackgroundColor3 = "card", Text = M.keyLabel(ch.key), Mono = true, TextSize = 11, TextColor3 = ac }, parent)
	round(b, 10)
	stroke(b, ac, 1, 0.35)
	pad(b, 9, 0, 9, 0)
	table.insert(ch.chips, b)
	b.MouseButton1Click:Connect(function()
		b.Text = "…"
		M.captureKey(function(name)
			if name then
				ch.key = name
				M.saved.keys[ch.n] = name
				cfg.save()
				M.Hooks.OnKeybind(ch.n, name)
			end
			refreshChips(ch)
		end)
	end)
	return b
end

--// config popover ---------------------------------------------------------------------------------------------
local catcher = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 18 }, gui)
local cfgCG = make("CanvasGroup", { Name = "Config", Size = UDim2.fromOffset(232, 100), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, ZIndex = 20 }, gui)
local cfgScale = make("UIScale", {}, cfgCG)
pad(cfgCG, 2, 2, 2, 2)
local cfgBody = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = "pop" }, cfgCG)
round(cfgBody, 16)
local cfgStroke = stroke(cfgBody, M.T.line, 1)
pad(cfgBody, 14, 14, 14, 14)
make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = LO }, cfgBody)

local cfgGen, selCard = 0, nil
local function hideConfig()
	cfgGen += 1
	local g = cfgGen
	catcher.Visible = false
	if selCard then selCard.setSel(false); selCard = nil end
	if cfgCG.Visible then
		tw(cfgScale, 0.2, { Scale = cfgScale.Scale * 0.85 })
		tw(cfgCG, 0.2, { GroupTransparency = 1 })
		task.delay(0.22, function() if g == cfgGen then cfgCG.Visible = false end end)
	end
end
M.hideConfig = hideConfig
catcher.MouseButton1Down:Connect(hideConfig)

local function saveOpt(ch, label, v)
	M.saved.opts[ch.n] = M.saved.opts[ch.n] or {}
	M.saved.opts[ch.n][label] = v
	cfg.save()
end

local function openConfig(ch, card)
	hideConfig()
	cfgGen += 1
	M.hideTip()
	local ac = ch.acc or acc(1)
	for _, c in ipairs(cfgBody:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	cfgStroke.Color = M.T.line:Lerp(M.col(ac), 0.4)
	selCard = card
	card.setSel(true)

	local hd = make("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 0 }, cfgBody)
	make("TextLabel", { Size = UDim2.fromOffset(24, 24), Text = ch.i, TextSize = 18 }, hd)
	make("TextLabel", { Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -90, 1, 0), Text = ch.n, W = 3, TextSize = 13, TextColor3 = "bright", TextXAlignment = LEFT }, hd)
	local chip = keyChip(hd, ch, ac)
	chip.AnchorPoint, chip.Position = Vector2.new(1, 0.5), UDim2.fromScale(1, 0.5)

	local resets, sumH = {}, 0
	for idx, f in ipairs(ch.f) do
		if f.k == "t" then
			sumH += 26
			local cur = f.cur
			if cur == nil then cur = f.on end
			local _, setter = M.toggle(cfgBody, { order = idx, label = f.l, value = cur, accent = ac, cb = function(v) f.cur = v; saveOpt(ch, f.l, v); M.Hooks.OnSwitch(ch.n, f.l, v) end })
			table.insert(resets, function() f.cur = nil; saveOpt(ch, f.l, nil); setter(f.on) end)
		else
			sumH += 40
			local _, setter = M.slider(cfgBody, { order = idx, label = f.l, min = f.min, max = f.max, unit = f.u, value = f.cur or f.v, accent = ac, cb = function(v) f.cur = v; saveOpt(ch, f.l, v); M.Hooks.OnSlider(ch.n, f.l, v) end })
			table.insert(resets, function() f.cur = nil; saveOpt(ch, f.l, nil); setter(f.v) end)
		end
	end
	M.button(cfgBody, { order = 100, label = "Reset to default", accent = "dim", h = 32, cb = function() for _, r in ipairs(resets) do r() end end })

	local H = 28 + 24 + 32 + sumH + 10 * (#ch.f + 1) + 4
	local s, vp = M.ui.rootScale.Scale, gui.AbsoluteSize
	local px = math.clamp(card.face.AbsolutePosition.X + card.face.AbsoluteSize.X * 0.55, 8, math.max(8, vp.X - 236 * s - 8))
	local py = math.clamp(card.face.AbsolutePosition.Y + card.face.AbsoluteSize.Y * 0.8, 8, math.max(8, vp.Y - (H + 4) * s - 8))
	cfgCG.Size = UDim2.fromOffset(232, H)
	cfgCG.Position = UDim2.fromOffset(px - gui.AbsolutePosition.X, py - gui.AbsolutePosition.Y)
	cfgScale.Scale, cfgCG.GroupTransparency, cfgCG.Visible, catcher.Visible = s * 0.6, 1, true, true
	tw(cfgScale, 0.35, { Scale = s }, Enum.EasingStyle.Back)
	tw(cfgCG, 0.2, { GroupTransparency = 0 })
end

--// cards -------------------------------------------------------------------------------------------------------------
local cards, compactGrids = {}, {}
local holdId, lpBlock = 0, false

local function makeCard(parent, order, ch, accIdx, mode, refresh)
	local ac = acc(accIdx)
	local isT = mode == "toggle"
	if isT then ch.acc = ac end
	local function faceCol(T) return (isT and ch.on) and T.card:Lerp(ac(T), 0.12) or T.card end
	local function stCol(T) return (isT and ch.on) and ac(T) or T.line end
	local function tileCol(T) return T.card:Lerp(ac(T), (isT and ch.on) and 0.4 or 0.14) end
	local function nameCol(T) return (isT and ch.on) and T.bright or T.text end
	local function hintCol(T) return (isT and ch.on) and ac(T) or T.dim end

	local cell = make("Frame", { BackgroundTransparency = 1, LayoutOrder = order }, parent)
	local face = make(isT and "TextButton" or "Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = faceCol }, cell)
	round(face, 12)
	local st = stroke(face, stCol, 1)
	local sc = make("UIScale", {}, face)
	local tile = make("Frame", { Position = UDim2.new(0, 11, 0.5, -13), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = tileCol }, face)
	round(tile, 8)
	make("TextLabel", { Size = UDim2.fromScale(1, 1), Text = ch.i, TextSize = 14 }, tile)
	local nameL = make("TextLabel", { Position = UDim2.fromOffset(45, 0), Size = UDim2.new(1, isT and -78 or -112, 1, 0), Text = ch.n, TextSize = 12.5, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, TextColor3 = nameCol }, face)
	local card = { face = face, scale = sc, tile = tile, nameL = nameL }
	table.insert(cards, card)

	if not isT then
		local chip = keyChip(face, ch, ac)
		chip.AnchorPoint, chip.Position = Vector2.new(1, 0.5), UDim2.new(1, -8, 0.5, 0)
		card.setSel = function() end
		return card
	end

	local bar2 = make("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(3, 0), BackgroundColor3 = ac }, face)
	round(bar2, 2)
	local hint = make("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(34, 16), Text = M.keyLabel(ch.key), Mono = true, TextSize = 10, TextColor3 = hintCol, TextXAlignment = RIGHT }, face)
	table.insert(ch.hints, hint)
	card.hint = hint

	function card.setOn()
		tw(st, 0.3, { Color = stCol, Thickness = ch.on and 1.5 or 1 })
		tw(nameL, 0.3, { TextColor3 = nameCol })
		tw(tile, 0.3, { BackgroundColor3 = tileCol })
		tw(bar2, 0.35, { Size = UDim2.fromOffset(3, ch.on and 18 or 0) }, Enum.EasingStyle.Back)
		tw(hint, 0.3, { TextColor3 = hintCol })
		tw(face, 0.3, { BackgroundColor3 = faceCol })
	end
	function card.setSel(sel)
		if sel then tw(st, 0.2, { Color = "bright", Thickness = 2 })
		else tw(st, 0.2, { Color = stCol, Thickness = ch.on and 1.5 or 1 }) end
	end
	function ch.setState(on)
		ch.on = on
		card.setOn()
		refresh()
		M.fire("active")
		Features.apply(ch)
		M.Hooks.OnToggle(ch.n, on)
	end

	face.MouseEnter:Connect(function() tw(face, 0.2, { Position = UDim2.new(0.5, 0, 0.5, -2) }); M.showTip(ch.n, ch.desc) end)
	face.MouseLeave:Connect(function() tw(face, 0.2, { Position = UDim2.fromScale(0.5, 0.5) }); tw(sc, 0.15, { Scale = 1 }); M.hideTip() end)
	face.MouseButton1Down:Connect(function() tw(sc, 0.1, { Scale = 0.96 }) end)
	face.MouseButton1Up:Connect(function() tw(sc, 0.2, { Scale = 1 }, Enum.EasingStyle.Back) end)
	face.MouseButton1Click:Connect(function()
		if lpBlock then return end
		Features.userToggle(ch)
		if S.closeOnToggle then M.setMenu(false) end
	end)
	face.MouseButton2Click:Connect(function() openConfig(ch, card) end)
	face.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			holdId += 1
			local id = holdId
			task.delay((S.holdDelay or 450) / 1000, function()
				if holdId == id then
					lpBlock = true
					openConfig(ch, card)
					task.delay(0.7, function() lpBlock = false end)
				end
			end)
		end
	end)
	face.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then holdId += 1 end end)
	face.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then holdId += 1 end end)
	return card
end

local function restyleCards()
	for i = #cards, 1, -1 do
		local c = cards[i]
		if not c.face.Parent then table.remove(cards, i)
		else
			c.tile.Visible = S.showIcons
			c.nameL.Position = UDim2.fromOffset(S.showIcons and 45 or 16, 0)
			if c.hint then c.hint.Visible = S.showHints end
		end
	end
end
cfg.on("showIcons", restyleCards)
cfg.on("showHints", restyleCards)
cfg.on("compact", function(v)
	for _, e in ipairs(compactGrids) do e.layout.CellSize = UDim2.new(e.sx, e.ox, 0, v and 34 or 42) end
end)

local function cheatPage(secs, offset)
	local pg = M.newPage(true)
	for si, sec in ipairs(secs) do
		local accIdx = offset + si
		local p = M.panel(pg, si, sec[1], sec[2], accIdx, nil, (si - 1) % 2, math.floor((si - 1) / 2))
		local gl = make("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, S.compact and 34 or 42), CellPadding = UDim2.fromOffset(8, 8), SortOrder = LO }, p.hold)
		table.insert(compactGrids, { layout = gl, sx = 0.5, ox = -4 })
		local function refresh()
			local n = 0
			for _, c in ipairs(sec[3]) do if c.on then n += 1 end end
			p.count.Text = string.format('%d cheats · <font color="#%s">%d on</font>', #sec[3], p.acc(M.T):ToHex(), n)
		end
		refresh()
		M.on("theme", refresh)
		for j, ch in ipairs(sec[3]) do table.insert(p.cards, makeCard(p.hold, j, ch, accIdx, "toggle", refresh)) end
	end
end
cheatPage(M.T0, 0)
cheatPage(M.T1, 3)

--// list panels (players / places) ---------------------------------------------------------------------------------------
local function listPanel(name, icon, accIdx, height, inset)
	local pg = M.newPage(false)
	local p = M.panel(pg, 1, name, icon, accIdx, UDim2.new(1, 0, 0, height), 0.5, 0)
	local sf = make("ScrollingFrame", { Position = UDim2.fromOffset(0, inset), Size = UDim2.new(1, 0, 1, -inset), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = "line", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, p.hold)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = LO }, sf)
	return p, sf
end
local function emptyRow(sf, msg)
	local f = make("Frame", { Size = UDim2.new(1, -6, 0, 50), BackgroundTransparency = 1 }, sf)
	make("TextLabel", { Size = UDim2.fromScale(1, 1), Text = msg, TextColor3 = "dim", TextSize = 12 }, f)
end
local function listRow(sf, order, strokeCol)
	local row = make("Frame", { Size = UDim2.new(1, -6, 0, 38), BackgroundColor3 = "card", LayoutOrder = order }, sf)
	round(row, 10)
	stroke(row, strokeCol or "line", 1)
	return row
end

local playersPanel, playersSF = listPanel("PLAYERS", "👥", 2, 440, 0)
function M.refreshPlayers()
	for _, c in ipairs(playersSF:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local list = {}
	for _, p in ipairs(M.Players:GetPlayers()) do if p ~= M.LP then table.insert(list, p) end end
	table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
	playersPanel.count.Text = string.format("%d other player%s", #list, #list == 1 and "" or "s")
	if #list == 0 then emptyRow(playersSF, "You're alone in this server") end
	for i, p in ipairs(list) do
		local row = listRow(playersSF, i, function(T) return M.getViewing() == p and acc(6)(T) or T.line end)
		make("TextLabel", { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -140, 0, 16), Text = p.DisplayName, W = 2, TextSize = 12.5, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd }, row)
		make("TextLabel", { Position = UDim2.fromOffset(12, 20), Size = UDim2.new(1, -140, 0, 14), Text = "@" .. p.Name, TextSize = 10.5, TextColor3 = "dim", TextXAlignment = LEFT }, row)
		local gotoB = M.pill(row, "GOTO", acc(2), -8)
		local viewB = M.pill(row, M.getViewing() == p and "UNVIEW" or "VIEW", acc(6), -60, 56)
		gotoB.MouseButton1Click:Connect(function() M.click(); M.gotoPlayer(p) end)
		viewB.MouseButton1Click:Connect(function() M.click(); if M.getViewing() == p then M.unview() else M.view(p) end end)
	end
end

local placesPanel, placesSF = listPanel("WAYPOINTS", "📍", 3, 440, 38)
local wpBox = make("TextBox", { Size = UDim2.new(1, -110, 0, 30), BackgroundColor3 = "card", PlaceholderText = "Waypoint name…", PlaceholderColor3 = "dim", TextXAlignment = LEFT }, placesPanel.hold)
round(wpBox, 10)
stroke(wpBox, "line", 1)
pad(wpBox, 10, 0, 10, 0)
local saveB = M.pill(placesPanel.hold, "SAVE HERE", acc(3), 0, 96)
saveB.Position, saveB.Size = UDim2.new(1, 0, 0, 15), UDim2.fromOffset(96, 30)
saveB.MouseButton1Click:Connect(function()
	M.click()
	M.notify(M.addWP(wpBox.Text), acc(3))
	wpBox.Text = ""
end)
function M.refreshPlaces()
	for _, c in ipairs(placesSF:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local n = 0
	for i, w in ipairs(M.saved.waypoints) do
		if w.pid == game.PlaceId then
			n += 1
			local row = listRow(placesSF, n)
			make("TextLabel", { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -140, 0, 16), Text = w.n, W = 2, TextSize = 12.5, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd }, row)
			make("TextLabel", { Position = UDim2.fromOffset(12, 20), Size = UDim2.new(1, -140, 0, 14), Text = string.format("%.0f, %.0f, %.0f", w.x, w.y, w.z), Mono = true, TextSize = 10, TextColor3 = "dim", TextXAlignment = LEFT }, row)
			local g = M.pill(row, "GOTO", acc(3), -8)
			local d = M.pill(row, "DELETE", acc(5), -60, 52)
			g.MouseButton1Click:Connect(function() M.click(); M.tpTo(CFrame.new(w.x, w.y, w.z)); M.notify("Teleported to " .. w.n, acc(3)) end)
			d.MouseButton1Click:Connect(function() table.remove(M.saved.waypoints, i); cfg.save(); M.refreshPlaces() end)
		end
	end
	placesPanel.count.Text = n .. " saved here"
	if n == 0 then emptyRow(placesSF, "No waypoints for this place yet") end
end

M.onPage = function(i)
	if i == 3 then M.refreshPlayers() elseif i == 4 then M.refreshPlaces() end
end

--// binds ------------------------------------------------------------------------------------------------------------------
do
	local pg = M.newPage(false)
	local rows = math.ceil(#FLAT / 4)
	local p = M.panel(pg, 1, "KEYBINDS", "⌨", 6, UDim2.new(1, 0, 0, 46 + rows * 50 + 12), 0.5, 0)
	p.count.Text = #FLAT .. " cheats · click a key to rebind"
	local gl = make("UIGridLayout", { CellSize = UDim2.new(0.25, -6, 0, S.compact and 34 or 42), CellPadding = UDim2.fromOffset(8, 8), SortOrder = LO }, p.hold)
	table.insert(compactGrids, { layout = gl, sx = 0.25, ox = -6 })
	for j, ch in ipairs(FLAT) do p.cards[j] = makeCard(p.hold, j, ch, 6, "bind") end
end

--// settings ---------------------------------------------------------------------------------------------------------------------
local function buildItem(it, parent, order)
	local setter, _
	if it.k == "toggle" then
		_, setter = M.toggle(parent, { order = order, label = it.label, desc = it.desc, value = S[it.key], cb = function(v) cfg.set(it.key, v); M.Hooks.OnSwitch("settings", it.label, v) end })
	elseif it.k == "slider" then
		_, setter = M.slider(parent, { order = order, label = it.label, min = it.min, max = it.max, unit = it.unit, value = S[it.key], cb = function(v) cfg.set(it.key, v); M.Hooks.OnSlider("settings", it.label, v) end })
	elseif it.k == "opts" then
		_, setter = M.options(parent, { order = order, label = it.label, opts = it.opts, value = S[it.key], cb = function(v) cfg.set(it.key, v) end })
	elseif it.k == "key" then
		_, setter = M.keyBtn(parent, { order = order, label = it.label, value = S[it.key], cb = function(v) cfg.set(it.key, v) end })
	end
	if setter then cfg.on(it.key, function(v) setter(v) end) end
end

local function textRow(parent, order, placeholder, btnLabel, accent, onApply)
	local row = make("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = order }, parent)
	local box = make("TextBox", { Size = UDim2.new(1, -78, 1, 0), BackgroundColor3 = "panel", PlaceholderText = placeholder, PlaceholderColor3 = "dim", Mono = true, TextSize = 11, TextXAlignment = LEFT, ClipsDescendants = true }, row)
	round(box, 8)
	stroke(box, "line", 1)
	pad(box, 10, 0, 10, 0)
	local b = M.pill(row, btnLabel, accent, 0, 70)
	b.Size = UDim2.fromOffset(70, 28)
	b.MouseButton1Click:Connect(function() M.click(); onApply(box.Text); box.Text = "" end)
	return row
end

local function buildThemeTab(content)
	local g1 = M.group(content, "THEMES", 1)
	local grid = make("Frame", { AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = 1 }, g1)
	make("UIGridLayout", { CellSize = UDim2.new(0.25, -8, 0, 62), CellPadding = UDim2.fromOffset(10, 10), SortOrder = LO }, grid)
	local cells = {}
	local function addCell(name, T, order)
		local b = make("TextButton", { BackgroundColor3 = T.card, LayoutOrder = order }, grid)
		round(b, 10)
		local st = stroke(b, T.line, 1)
		local lbl = make("TextLabel", { Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -20, 0, 16), Text = name, W = 3, TextSize = 12, TextColor3 = T.text, TextXAlignment = LEFT }, b)
		local dots = {}
		for i = 1, 5 do
			local d = make("Frame", { Position = UDim2.fromOffset(10 + (i - 1) * 20, 36), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = T.accents[i] }, b)
			round(d, 7)
			dots[i] = d
		end
		b.MouseButton1Click:Connect(function() M.click(); cfg.set("theme", name) end)
		local cell = { name = name, st = st, T = T, btn = b, lbl = lbl, dots = dots }
		table.insert(cells, cell)
		return cell
	end
	for i, T in ipairs(M.themes) do addCell(T.name, T, i) end
	local custom = addCell("Custom", M.buildCustom(), #M.themes + 1)
	local function refreshCells()
		for _, c in ipairs(cells) do
			local sel = S.theme == c.name
			tw(c.st, 0.2, { Color = sel and c.T.accents[1] or c.T.line, Thickness = sel and 2 or 1 })
		end
	end
	cfg.on("theme", refreshCells, true)
	local function updateCustom()
		local T = M.buildCustom()
		custom.T = T
		custom.btn.BackgroundColor3 = T.card
		custom.lbl.TextColor3 = T.text
		for i, d in ipairs(custom.dots) do d.BackgroundColor3 = T.accents[i] end
		refreshCells()
	end

	local g2 = M.group(content, "CUSTOM THEME  ·  moving a slider switches to Custom", 2)
	local defs = {
		{ "customHue", "Accent hue", 0, 360, "°" }, { "customSat", "Saturation", 0, 100, "%" }, { "customShift", "Secondary hue shift", 0, 360, "°" },
		{ "customBg", "Background brightness", 0, 100, "%" }, { "customTint", "Background tint", 0, 100, "%" },
	}
	for i, d in ipairs(defs) do
		local _, set = M.slider(g2, { order = i, label = d[2], min = d[3], max = d[4], unit = d[5], value = S[d[1]], cb = function(v) cfg.set(d[1], v) end })
		cfg.on(d[1], function(v) set(v); updateCustom() end)
	end
	M.button(g2, { order = 6, label = "🎲  Randomize custom theme", accent = acc(4), cb = function()
		local r = math.random
		cfg.set("customHue", r(0, 360), true); cfg.set("customSat", r(55, 95), true); cfg.set("customShift", r(30, 180), true)
		cfg.set("customBg", r(10, 45), true); cfg.set("customTint", r(15, 60), true)
		cfg.save()
	end })
	M.button(g2, { order = 7, label = "📋  Copy custom theme code", accent = acc(1), cb = function()
		local code = string.format("%d,%d,%d,%d,%d", S.customHue, S.customSat, S.customShift, S.customBg, S.customTint)
		M.notify(M.setClipboard(code) and "Theme code copied" or ("Theme code: " .. code))
	end })
	textRow(g2, 8, "paste theme code  (e.g. 190,75,70,28,35)", "APPLY", acc(2), function(str)
		local nums = {}
		for n in str:gmatch("%-?%d+") do table.insert(nums, tonumber(n)) end
		if #nums < 5 then M.notify("Need 5 numbers", acc(5)); return end
		for i, d in ipairs(defs) do cfg.set(d[1], math.clamp(nums[i], d[3], d[4]), true) end
		cfg.save()
		M.notify("Theme applied", acc(2))
	end)
end

local function buildSchemaTab(content, sec)
	for gi, grp in ipairs(sec.groups) do
		local g = M.group(content, grp.title, gi)
		for ii, it in ipairs(grp.items) do buildItem(it, g, ii) end
	end
end

local function buildDataTab(content)
	local gp = M.group(content, "PROFILES  ·  settings + keybinds", 1)
	for n = 1, 3 do
		local row = make("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = n }, gp)
		make("TextLabel", { Size = UDim2.new(0.3, 0, 1, 0), Text = "Profile " .. n, TextSize = 12.5, TextXAlignment = LEFT }, row)
		local status = make("TextLabel", { Position = UDim2.new(0.3, 0, 0, 0), Size = UDim2.new(0.3, 0, 1, 0), Text = cfg.hasSlot(n) and "saved" or "empty", TextSize = 11, TextColor3 = "dim", TextXAlignment = LEFT }, row)
		local loadB = M.pill(row, "LOAD", acc(2), 0, 56)
		local saveB = M.pill(row, "SAVE", acc(1), -64, 56)
		saveB.MouseButton1Click:Connect(function()
			M.click()
			if cfg.saveSlot(n) then status.Text = "saved"; M.notify("Saved profile " .. n) else M.notify("This executor can't write files", acc(5)) end
		end)
		loadB.MouseButton1Click:Connect(function()
			M.click()
			if cfg.loadSlot(n) then M.notify("Loaded profile " .. n, acc(2)) else M.notify("Profile " .. n .. " is empty", acc(5)) end
		end)
	end
	local gb = M.group(content, "BACKUP & RESET", 2)
	M.button(gb, { order = 1, label = "📋  Copy settings code", accent = acc(1), cb = function()
		M.notify(M.setClipboard(cfg.export()) and "Settings code copied" or "Clipboard unavailable", acc(1))
	end })
	textRow(gb, 2, "paste settings code…", "IMPORT", acc(2), function(str)
		local ok = cfg.import(str)
		M.notify(ok and "Settings imported" or "Invalid code", ok and acc(2) or acc(5))
	end)
	M.button(gb, { order = 3, label = "↺  Reset menu position", accent = acc(6), cb = function() M.resetPosition(); M.notify("Position reset") end })
	M.button(gb, { order = 4, label = "⚠  Reset all settings", accent = acc(5), cb = function() cfg.reset(); M.notify("Settings reset", acc(5)) end })
	M.button(gb, { order = 5, label = "⏻  Unload menu", accent = acc(5), cb = function() M.Destroy() end })
end

do
	local pg = M.newPage(false)
	local sf = pg.sf
	local nav = make("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = 1 }, sf)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = LO, VerticalAlignment = Enum.VerticalAlignment.Center }, nav)
	local sub = 1
	local defs = { { "THEME", "🎨" }, { "APPEARANCE", "🖼" }, { "BEHAVIOR", "🧠" }, { "DATA", "💾" } }
	local contents, navBtns = {}, {}
	local function bgCol(i) return function(T) return sub == i and T.card:Lerp(acc(1)(T), 0.2) or T.card end end
	local function txCol(i) return function(T) return sub == i and T.bright or T.dim end end
	for i, d in ipairs(defs) do
		local btn = make("TextButton", { Size = UDim2.fromOffset(124, 30), BackgroundColor3 = bgCol(i), Text = d[2] .. "  " .. d[1], TextSize = 11, W = 3, TextColor3 = txCol(i), LayoutOrder = i }, nav)
		round(btn, 15)
		stroke(btn, "line", 1)
		navBtns[i] = btn
		local c = make("Frame", { AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = 2, Visible = i == 1 }, sf)
		make("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = LO }, c)
		contents[i] = c
		btn.MouseButton1Click:Connect(function()
			M.click()
			sub = i
			for j, cc in ipairs(contents) do
				cc.Visible = j == i
				tw(navBtns[j], 0.25, { BackgroundColor3 = bgCol(j), TextColor3 = txCol(j) })
			end
			sf.CanvasPosition = Vector2.zero
		end)
	end
	buildThemeTab(contents[1])
	buildSchemaTab(contents[2], M.SCHEMA[1])
	buildSchemaTab(contents[3], M.SCHEMA[2])
	buildDataTab(contents[4])
end

local touchOnly = UIS.TouchEnabled and not UIS.KeyboardEnabled
local RC = touchOnly and "LONG-PRESS FOR CONFIG" or "RIGHT-CLICK FOR CONFIG"
local function count(group) local n = 0; for _, s in ipairs(group) do n += #s[3] end; return n end
M.PINFO = {
	{ "MAIN CHEATS · " .. count(M.T0), RC },
	{ "MORE CHEATS · " .. count(M.T1), RC },
	{ "PLAYERS", "GOTO OR SPECTATE" },
	{ "PLACES", "SAVE & TELEPORT" },
	{ "KEYBINDS", "CLICK A KEY TO REBIND" },
	{ "SETTINGS", "THEME · APPEARANCE · BEHAVIOR · DATA" },
}
restyleCards()
for _, e in ipairs(compactGrids) do e.layout.CellSize = UDim2.new(e.sx, e.ox, 0, S.compact and 34 or 42) end
