--[[ features: cheat data + all client-side logic, teleport / spectate / waypoint helpers ]]
local M = ...
local Players, UIS, RunService, Lighting, Workspace, TweenService, CAS, VirtualUser = M.Players, M.UIS, M.RunService, M.Lighting, M.Workspace, M.TweenService, M.CAS, M.VirtualUser
local LP, S, cfg = M.LP, M.S, M.cfg
local getHum, getRoot = M.getHum, M.getRoot

--// data ---------------------------------------------------------------------------------------
local function TG(l, on) return { k = "t", l = l, on = on or false } end
local function SL(l, a, b, v, u) return { k = "s", l = l, min = a, max = b, v = v, u = u or "" } end
local function CH(i, n, ...) return { i = i, n = n, f = { ... }, on = false, chips = {}, hints = {} } end

M.DESC = {
	["God mode"] = "Keeps health full. Client-side: works in games that trust the client.",
	["Heal"] = "Heals to the chosen percentage, or keeps you there with auto-heal.",
	["Speed"] = "Multiplies walk speed. Optionally only while holding Shift.",
	["Jump"] = "Sets jump power.",
	["Fly"] = "WASD / camera direction, Space up, Ctrl down.",
	["Noclip"] = "Walk through walls.",
	["Infinite jump"] = "Jump again while in mid-air.",
	["Click TP"] = "Teleport to where you click (Ctrl + click by default).",
	["Day"] = "Locks the client clock to a time of day.",
	["Night"] = "Forces midnight on your client.",
	["Fullbright"] = "Removes darkness, shadows and (optionally) fog.",
	["Low gravity"] = "Scales gravity as a percentage of normal.",
	["FOV"] = "Custom field of view.",
	["Free zoom"] = "Raises the maximum camera zoom distance.",
	["Freecam"] = "Detached camera. WASD/QE move, hold right mouse to look, Shift = fast.",
	["X-ray"] = "Makes world parts see-through (local only).",
	["Anti-AFK"] = "Prevents the idle kick.",
	["Spin"] = "Spins your character.",
	["Float"] = "Keeps an invisible platform under your feet.",
	["Anti-void"] = "Launches you upward if you fall below the map.",
}

M.T0 = {
	{ "PLAYER", "🛡", {
		CH("🛡", "God mode", TG("Force field", true)),
		CH("❤", "Heal", SL("Amount", 10, 100, 100, "%"), TG("Auto-heal")),
		CH("⚡", "Speed", SL("Multiplier", 1, 10, 2, "×"), TG("Sprint only")),
		CH("🦘", "Jump", SL("Jump power", 50, 300, 120)),
	} },
	{ "MOVEMENT", "🪽", {
		CH("🪽", "Fly", SL("Fly speed", 1, 20, 6), TG("Face camera", true)),
		CH("👻", "Noclip", TG("Restore collision", true)),
		CH("♾", "Infinite jump"),
		CH("🖱", "Click TP", TG("Require Ctrl", true)),
	} },
	{ "WORLD", "🌍", {
		CH("☀", "Day", SL("Time of day", 0, 24, 12, "h")),
		CH("🌙", "Night", SL("Brightness", 0, 5, 1)),
		CH("💡", "Fullbright", SL("Brightness", 1, 5, 2), TG("Remove fog", true)),
		CH("🌍", "Low gravity", SL("Gravity", 0, 100, 30, "%")),
	} },
}
M.T1 = {
	{ "CAMERA", "🎥", {
		CH("🔭", "FOV", SL("Field of view", 30, 120, 90, "°")),
		CH("🔍", "Free zoom", SL("Max distance", 20, 1000, 400)),
		CH("🎬", "Freecam", SL("Speed", 1, 20, 5), TG("Lock character", true)),
		CH("🧊", "X-ray", SL("Transparency", 10, 90, 60, "%")),
	} },
	{ "UTILITY", "🔧", {
		CH("💤", "Anti-AFK"),
		CH("🌀", "Spin", SL("Spin speed", 1, 20, 5)),
		CH("🛸", "Float", SL("Raise", 0, 50, 0)),
		CH("🕳", "Anti-void"),
	} },
}

local DEFKEYS = { "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Zero", "Z", "X", "C", "V", "B", "N", "M", "K", "L", "J" }
local FLAT, BY = {}, {}
M.FLAT, M.BY = FLAT, BY
for _, group in ipairs({ M.T0, M.T1 }) do
	for _, sec in ipairs(group) do
		for _, ch in ipairs(sec[3]) do
			table.insert(FLAT, ch)
			BY[ch.n] = ch
			ch.defKey = DEFKEYS[#FLAT]
			ch.key = M.saved.keys[ch.n] or ch.defKey
			ch.desc = M.DESC[ch.n]
			local o = M.saved.opts[ch.n]
			if type(o) == "table" then
				for _, f in ipairs(ch.f) do
					if o[f.l] ~= nil and type(o[f.l]) == (f.k == "t" and "boolean" or "number") then f.cur = o[f.l] end
				end
			end
		end
	end
end
M.on("keys", function()
	for _, ch in ipairs(FLAT) do ch.key = M.saved.keys[ch.n] or ch.defKey end
	if M.refreshChips then for _, ch in ipairs(FLAT) do M.refreshChips(ch) end end
end)

function M.opt(name, label)
	for _, f in ipairs(BY[name].f) do
		if f.l == label then
			if f.k == "t" then
				if f.cur ~= nil then return f.cur end
				return f.on
			end
			return f.cur or f.v
		end
	end
end
local opt = M.opt

--// state ---------------------------------------------------------------------------------------
local cam0 = Workspace.CurrentCamera
local orig = {
	gravity = Workspace.Gravity, zoom = LP.CameraMaxZoomDistance, fov = cam0 and cam0.FieldOfView or 70,
	bright = Lighting.Brightness, amb = Lighting.Ambient, oamb = Lighting.OutdoorAmbient,
	shadows = Lighting.GlobalShadows, fog = Lighting.FogEnd, destroyH = Workspace.FallenPartsDestroyHeight,
}
local humOrig = setmetatable({}, { __mode = "k" })
local applied = {}
local function drive(key, on, doApply, doRestore)
	if on then applied[key] = true; doApply()
	elseif applied[key] then applied[key] = nil; doRestore() end
end
local flyObjs, noclipped = {}, {}
local function clearFly() for k, o in pairs(flyObjs) do o:Destroy(); flyObjs[k] = nil end end
local fl, xr, fc = {}, { t = 0, v = -1 }, { active = false, rot = Vector2.zero, look = false }

local function lightingStep()
	local day, night, fb = BY.Day.on, BY.Night.on, BY.Fullbright.on
	if day or night or fb then
		applied.light = true
		if day then Lighting.ClockTime = opt("Day", "Time of day") % 24
		elseif night then Lighting.ClockTime = 0 end
		Lighting.Brightness = fb and opt("Fullbright", "Brightness") or (night and opt("Night", "Brightness") or orig.bright)
		if fb then
			Lighting.Ambient = Color3.fromRGB(178, 178, 178)
			Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
			Lighting.GlobalShadows = false
			if opt("Fullbright", "Remove fog") then Lighting.FogEnd = 1e9 end
		else
			Lighting.Ambient, Lighting.OutdoorAmbient = orig.amb, orig.oamb
			Lighting.GlobalShadows, Lighting.FogEnd = orig.shadows, orig.fog
		end
	elseif applied.light then
		applied.light = nil
		Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient = orig.bright, orig.amb, orig.oamb
		Lighting.GlobalShadows, Lighting.FogEnd = orig.shadows, orig.fog
	end
end

local function xrayApply(v)
	for _, p in ipairs(Workspace:GetDescendants()) do
		if p:IsA("BasePart") and not p:IsA("Terrain") and p.Name ~= "CM_Float" then
			local par = p.Parent
			if not (par and (par:FindFirstChildOfClass("Humanoid") or (par.Parent and par.Parent:FindFirstChildOfClass("Humanoid")))) then
				p.LocalTransparencyModifier = v
			end
		end
	end
end
local function sink() return Enum.ContextActionResult.Sink end

local function step(dt)
	local c = LP.Character
	local h, r = getHum(c), getRoot(c)
	local cam = Workspace.CurrentCamera

	if h and h.Health > 0 then
		local o = humOrig[h]
		if not o then o = { ws = h.WalkSpeed, jp = h.JumpPower, ujp = h.UseJumpPower }; humOrig[h] = o end
		local ff = c:FindFirstChild("CM_FF")
		if BY["God mode"].on then
			h.Health = h.MaxHealth
			if opt("God mode", "Force field") then
				if not ff then ff = Instance.new("ForceField"); ff.Name = "CM_FF"; ff.Visible = false; ff.Parent = c end
			elseif ff then ff:Destroy() end
		elseif ff then ff:Destroy() end
		if BY.Heal.on and opt("Heal", "Auto-heal") then
			h.Health = math.max(h.Health, h.MaxHealth * opt("Heal", "Amount") / 100)
		end
		local sprintOk = not opt("Speed", "Sprint only") or UIS:IsKeyDown(Enum.KeyCode.LeftShift)
		drive("speed", BY.Speed.on and sprintOk,
			function() h.WalkSpeed = o.ws * opt("Speed", "Multiplier") end,
			function() h.WalkSpeed = o.ws end)
		drive("jump", BY.Jump.on,
			function() h.UseJumpPower = true; h.JumpPower = opt("Jump", "Jump power") end,
			function() h.UseJumpPower = o.ujp; h.JumpPower = o.jp end)
	end

	-- Fly
	if BY.Fly.on and r and h and cam and not fc.active then
		local bv, bg = flyObjs.bv, flyObjs.bg
		if not bv or bv.Parent ~= r then
			clearFly()
			bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.one * 1e9; bv.Velocity = Vector3.zero; bv.Parent = r
			bg = Instance.new("BodyGyro"); bg.MaxTorque = Vector3.zero; bg.P = 1e4; bg.Parent = r
			flyObjs.bv, flyObjs.bg = bv, bg
			h.PlatformStand = true
		end
		local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
		local d = Vector3.zero
		if UIS.KeyboardEnabled then
			if UIS:IsKeyDown(Enum.KeyCode.W) then d += look end
			if UIS:IsKeyDown(Enum.KeyCode.S) then d -= look end
			if UIS:IsKeyDown(Enum.KeyCode.D) then d += right end
			if UIS:IsKeyDown(Enum.KeyCode.A) then d -= right end
		else
			d = h.MoveDirection
		end
		if d.Magnitude > 0 then d = d.Unit end
		local spd = opt("Fly", "Fly speed") * 10
		local vert = (UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0)
		bv.Velocity = d * spd + Vector3.new(0, vert * spd, 0)
		local flat = Vector3.new(look.X, 0, look.Z)
		if opt("Fly", "Face camera") and flat.Magnitude > 0.01 then
			bg.MaxTorque = Vector3.one * 1e9
			bg.CFrame = CFrame.lookAt(r.Position, r.Position + flat)
		else
			bg.MaxTorque = Vector3.zero
		end
	elseif flyObjs.bv then
		clearFly()
		if h then h.PlatformStand = false end
	end

	if BY.Spin.on and r then r.CFrame = r.CFrame * CFrame.Angles(0, opt("Spin", "Spin speed") * dt * 1.5, 0) end

	-- Float platform
	if BY.Float.on and r then
		if not fl.part or not fl.part.Parent then
			fl.part = Instance.new("Part")
			fl.part.Name = "CM_Float"; fl.part.Size = Vector3.new(6, 0.4, 6); fl.part.Transparency = 1; fl.part.Anchored = true
			fl.part.Parent = Workspace
			fl.y = r.Position.Y - ((h and h.HipHeight or 2) + r.Size.Y / 2) - 0.2
		end
		fl.part.CFrame = CFrame.new(r.Position.X, fl.y + opt("Float", "Raise"), r.Position.Z)
	elseif fl.part then
		fl.part:Destroy(); fl.part = nil
	end

	if BY["Anti-void"].on and r and r.Position.Y <= orig.destroyH + 25 then
		local v = r.AssemblyLinearVelocity
		r.AssemblyLinearVelocity = Vector3.new(v.X, 250, v.Z)
	end

	-- X-ray
	if BY["X-ray"].on then
		xr.t += dt
		local want = opt("X-ray", "Transparency") / 100
		if xr.t > 2 or xr.v ~= want then
			xr.t, xr.v = 0, want
			applied.xray = true
			xrayApply(want)
		end
	elseif applied.xray then
		applied.xray = nil
		xr.v = -1
		xrayApply(0)
	end

	-- Freecam
	if BY.Freecam.on and cam then
		if not fc.active then
			fc.active = true
			fc.pos = cam.CFrame.Position
			local x, y = cam.CFrame:ToOrientation()
			fc.rot = Vector2.new(x, y)
			if opt("Freecam", "Lock character") then
				CAS:BindActionAtPriority("CM_FC", sink, false, 3000, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space, Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.LeftControl)
			end
		end
		cam.CameraType = Enum.CameraType.Scriptable
		local function k(code) return UIS:IsKeyDown(code) and 1 or 0 end
		local mv = Vector3.new(k(Enum.KeyCode.D) - k(Enum.KeyCode.A), k(Enum.KeyCode.E) + k(Enum.KeyCode.Space) - k(Enum.KeyCode.Q) - k(Enum.KeyCode.LeftControl), k(Enum.KeyCode.S) - k(Enum.KeyCode.W))
		local spd = opt("Freecam", "Speed") * 8 * (UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1)
		local cf = CFrame.new(fc.pos) * CFrame.fromOrientation(fc.rot.X, fc.rot.Y, 0)
		fc.pos = (cf * CFrame.new(mv * spd * dt)).Position
		cam.CFrame = CFrame.new(fc.pos) * CFrame.fromOrientation(fc.rot.X, fc.rot.Y, 0)
	elseif fc.active then
		fc.active, fc.look = false, false
		CAS:UnbindAction("CM_FC")
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		if cam then
			cam.CameraType = Enum.CameraType.Custom
			if h then cam.CameraSubject = h end
		end
	end

	drive("grav", BY["Low gravity"].on,
		function() Workspace.Gravity = orig.gravity * opt("Low gravity", "Gravity") / 100 end,
		function() Workspace.Gravity = orig.gravity end)
	drive("fov", BY.FOV.on and cam ~= nil and not fc.active,
		function() cam.FieldOfView = opt("FOV", "Field of view") end,
		function() if cam then cam.FieldOfView = orig.fov end end)
	drive("zoom", BY["Free zoom"].on,
		function() LP.CameraMaxZoomDistance = opt("Free zoom", "Max distance") end,
		function() LP.CameraMaxZoomDistance = orig.zoom end)
	lightingStep()
end
M.connect(RunService.Heartbeat, step)

local function noclipStep()
	local c = LP.Character
	if BY.Noclip.on and c then
		for _, p in ipairs(c:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then noclipped[p] = true; p.CanCollide = false end
		end
	elseif next(noclipped) then
		if opt("Noclip", "Restore collision") then
			for p in pairs(noclipped) do if p.Parent then p.CanCollide = true end end
		end
		noclipped = {}
	end
end
M.connect(RunService.Stepped, noclipStep)

M.connect(UIS.JumpRequest, function()
	if BY["Infinite jump"].on then
		local h = getHum()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

M.connect(UIS.InputBegan, function(i, gp)
	if i.UserInputType == Enum.UserInputType.MouseButton2 and BY.Freecam.on and not gp then
		fc.look = true
		UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	end
end)
M.connect(UIS.InputEnded, function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton2 and fc.look then
		fc.look = false
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	end
end)
M.connect(UIS.InputChanged, function(i)
	if fc.look and i.UserInputType == Enum.UserInputType.MouseMovement then
		fc.rot = Vector2.new(math.clamp(fc.rot.X - i.Delta.Y * 0.004, -1.5, 1.5), fc.rot.Y - i.Delta.X * 0.004)
	end
end)

local mouse = LP:GetMouse()
M.connect(UIS.InputBegan, function(i, gp)
	if gp or i.UserInputType ~= Enum.UserInputType.MouseButton1 or not BY["Click TP"].on then return end
	if opt("Click TP", "Require Ctrl") and not UIS:IsKeyDown(Enum.KeyCode.LeftControl) then return end
	local r = getRoot()
	if r and mouse.Hit then r.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) end
end)

M.connect(LP.Idled, function()
	if BY["Anti-AFK"].on then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end)

--// public feature api --------------------------------------------------------------------------------------
local Features = {}
M.Features = Features
function Features.apply(ch)
	if ch.n == "Heal" and ch.on then
		local h = getHum()
		if h then h.Health = math.max(h.Health, h.MaxHealth * opt("Heal", "Amount") / 100) end
	elseif ch.n == "Day" and ch.on and BY.Night.on then BY.Night.setState(false)
	elseif ch.n == "Night" and ch.on and BY.Day.on then BY.Day.setState(false) end
end
function Features.set(ch, on)
	if not ch.setState then return end
	ch.setState(on)
	M.click()
	M.notify(ch.n .. (ch.on and " enabled" or " disabled"), ch.on and (ch.acc or M.acc(1)) or "dim")
end
function Features.userToggle(ch) Features.set(ch, not ch.on) end

table.insert(M.cleanups, function()
	for _, ch in ipairs(FLAT) do ch.on = false end
	pcall(step, 0)
	pcall(noclipStep)
	clearFly()
	if fl.part then fl.part:Destroy() end
	pcall(function() CAS:UnbindAction("CM_FC") end)
end)

--// teleport / spectate / waypoints ----------------------------------------------------------------------------
function M.tpTo(cf)
	local r, h = getRoot(), getHum()
	if not r then return end
	task.spawn(function()
		if h and h.SeatPart then h.Sit = false; task.wait(0.1) end
		if S.tween then
			TweenService:Create(r, TweenInfo.new(S.tweenTime, Enum.EasingStyle.Linear), { CFrame = cf }):Play()
		else
			r.CFrame = cf
			r.AssemblyLinearVelocity = Vector3.zero
		end
	end)
end
function M.findPlayer(q)
	if not q then return nil end
	q = q:lower()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then table.insert(list, p) end end
	if q == "random" then return list[math.random(1, math.max(1, #list))] end
	local best
	for _, p in ipairs(list) do
		local n, d = p.Name:lower(), p.DisplayName:lower()
		if n:sub(1, #q) == q or d:sub(1, #q) == q then return p end
		best = best or ((n:find(q, 1, true) or d:find(q, 1, true)) and p)
	end
	return best
end
function M.gotoPlayer(p)
	local r = p and getRoot(p.Character)
	if not r then M.notify("Player has no character", "dim"); return false end
	M.tpTo(r.CFrame * CFrame.new(0, 0, 3))
	M.notify("Teleported to " .. p.DisplayName, M.acc(2))
	return true
end

local viewing, viewConns = nil, {}
function M.getViewing() return viewing end
function M.unview()
	viewing = nil
	for _, c in ipairs(viewConns) do c:Disconnect() end
	viewConns = {}
	local cam, h = Workspace.CurrentCamera, getHum()
	if cam and h and not fc.active then cam.CameraSubject = h end
	if M.refreshPlayers then M.refreshPlayers() end
end
function M.view(p)
	M.unview()
	viewing = p
	local function apply()
		local h, cam = getHum(p.Character), Workspace.CurrentCamera
		if h and cam then cam.CameraSubject = h end
	end
	apply()
	table.insert(viewConns, p.CharacterAdded:Connect(function() task.wait(0.4); apply() end))
	table.insert(viewConns, Players.PlayerRemoving:Connect(function(q) if q == p then M.unview() end end))
	M.notify("Viewing " .. p.DisplayName, M.acc(6))
	if M.refreshPlayers then M.refreshPlayers() end
end
table.insert(M.cleanups, function() pcall(M.unview) end)

function M.addWP(name)
	local r = getRoot()
	if not r then return "No character" end
	local WP = M.saved.waypoints
	name = (name and name ~= "") and name or ("Point " .. (#WP + 1))
	for i = #WP, 1, -1 do if WP[i].n:lower() == name:lower() and WP[i].pid == game.PlaceId then table.remove(WP, i) end end
	local p = r.Position
	table.insert(WP, { n = name, x = math.floor(p.X * 10) / 10, y = math.floor(p.Y * 10) / 10, z = math.floor(p.Z * 10) / 10, pid = game.PlaceId })
	cfg.save()
	if M.refreshPlaces then M.refreshPlaces() end
	return "Saved waypoint " .. name
end
function M.findWP(name)
	for _, w in ipairs(M.saved.waypoints) do
		if w.pid == game.PlaceId and w.n:lower() == name:lower() then return w end
	end
end
