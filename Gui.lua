--[[
    ╔═══════════════════════════════════════════╗
    ║        GUI HANDLING MODULE v1.0           ║
    ║   Connect via: loadstring(...)()          ║
    ╚═══════════════════════════════════════════╝

    Features:
      • Draggable window with topbar
      • Left sidebar tabs system
      • Main content frames per tab
      • Bottom bar: Themes | Keybinds | Settings
      • Theme engine (Dark / Light / custom)
      • Keybind system
      • External module plug-in via :LoadModule()

    Usage:
        local GUI = loadstring(game:HttpGet("RAW_URL_HERE"))()
        local window = GUI:CreateWindow({
            Title   = "My Script",
            Size    = UDim2.new(0, 600, 0, 400),
            Keybind = Enum.KeyCode.RightShift,
        })
        local tab = window:AddTab("Home", "rbxassetid://...")
        tab:AddLabel("Hello World!")
        window:Open()
]]

-- ── Services ─────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ── Animations Dependency ────────────────────────────────────────────────────
-- Swap this URL with your hosted AnimationsModule raw URL, or paste inline
local ANIM_URL = "https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/AnimationsModule.lua"
local Animations
local ok, err = pcall(function()
    Animations = loadstring(game:HttpGet(ANIM_URL))()
end)
if not ok then
    -- Fallback: inline minimal tween helper
    Animations = {}
    function Animations:Tween(inst, props, dur)
        TweenService:Create(inst,
            TweenInfo.new(dur or 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            props):Play()
    end
    function Animations:HoverEffect(inst, hC, nC, dur)
        nC = nC or inst.BackgroundColor3
        inst.MouseEnter:Connect(function() self:Tween(inst,{BackgroundColor3=hC},dur or 0.15) end)
        inst.MouseLeave:Connect(function() self:Tween(inst,{BackgroundColor3=nC},dur or 0.15) end)
    end
    function Animations:Ripple(parent, x, y, color)
        color = color or Color3.fromRGB(255,255,255)
        local r = Instance.new("Frame")
        r.AnchorPoint = Vector2.new(.5,.5)
        r.Position = UDim2.new(0,x,0,y)
        r.Size = UDim2.new(0,0,0,0)
        r.BackgroundColor3 = color
        r.BackgroundTransparency = .7
        r.ZIndex = parent.ZIndex+5
        Instance.new("UICorner",r).CornerRadius=UDim.new(1,0)
        r.Parent = parent
        local mx = math.max(parent.AbsoluteSize.X,parent.AbsoluteSize.Y)*2.5
        TweenService:Create(r,TweenInfo.new(.5),{Size=UDim2.new(0,mx,0,mx),BackgroundTransparency=1}):Play()
        game:GetService("Debris"):AddItem(r,.6)
    end
    function Animations:FadeIn(inst, dur)
        inst.BackgroundTransparency=1; inst.Visible=true
        self:Tween(inst,{BackgroundTransparency=0},dur or .2)
    end
    function Animations:FadeOut(inst, dur, cb)
        local t=TweenService:Create(inst,TweenInfo.new(dur or .2),{BackgroundTransparency=1})
        t.Completed:Connect(function() inst.Visible=false; if cb then cb() end end)
        t:Play()
    end
    function Animations:Bounce(inst, dur)
        local o=inst.Size
        local b=UDim2.new(o.X.Scale*1.07,o.X.Offset,o.Y.Scale*1.07,o.Y.Offset)
        local t1=TweenService:Create(inst,TweenInfo.new((dur or .15)/2),{Size=b})
        t1.Completed:Connect(function()
            TweenService:Create(inst,TweenInfo.new((dur or .15)/2),{Size=o}):Play()
        end)
        t1:Play()
    end
end

-- ════════════════════════════════════════════════════════════════════════════
--  THEME ENGINE
-- ════════════════════════════════════════════════════════════════════════════
local Themes = {
    Dark = {
        Window        = Color3.fromRGB(30,  30,  35),
        Topbar        = Color3.fromRGB(22,  22,  27),
        TopbarAccent  = Color3.fromRGB(100, 180, 240),
        Sidebar       = Color3.fromRGB(25,  25,  30),
        TabNormal     = Color3.fromRGB(35,  35,  42),
        TabHover      = Color3.fromRGB(50,  50,  60),
        TabSelected   = Color3.fromRGB(60,  100, 160),
        Content       = Color3.fromRGB(33,  33,  40),
        BottomBar     = Color3.fromRGB(20,  20,  26),
        BottomBtn     = Color3.fromRGB(40,  40,  50),
        BottomBtnHov  = Color3.fromRGB(60,  60,  80),
        Text          = Color3.fromRGB(220, 220, 230),
        TextDim       = Color3.fromRGB(140, 140, 155),
        Accent        = Color3.fromRGB(100, 180, 240),
        Border        = Color3.fromRGB(55,  55,  65),
        ScrollBar     = Color3.fromRGB(70,  70,  85),
    },
    Light = {
        Window        = Color3.fromRGB(245, 245, 250),
        Topbar        = Color3.fromRGB(230, 232, 240),
        TopbarAccent  = Color3.fromRGB(60,  120, 200),
        Sidebar       = Color3.fromRGB(220, 222, 230),
        TabNormal     = Color3.fromRGB(235, 236, 244),
        TabHover      = Color3.fromRGB(210, 215, 228),
        TabSelected   = Color3.fromRGB(80,  140, 220),
        Content       = Color3.fromRGB(250, 250, 255),
        BottomBar     = Color3.fromRGB(215, 217, 225),
        BottomBtn     = Color3.fromRGB(200, 202, 215),
        BottomBtnHov  = Color3.fromRGB(180, 184, 205),
        Text          = Color3.fromRGB(30,  30,  40),
        TextDim       = Color3.fromRGB(100, 100, 120),
        Accent        = Color3.fromRGB(60,  120, 200),
        Border        = Color3.fromRGB(190, 192, 205),
        ScrollBar     = Color3.fromRGB(160, 162, 180),
    },
    Midnight = {
        Window        = Color3.fromRGB(10,  10,  18),
        Topbar        = Color3.fromRGB(8,   8,   15),
        TopbarAccent  = Color3.fromRGB(140, 80,  240),
        Sidebar       = Color3.fromRGB(12,  12,  22),
        TabNormal     = Color3.fromRGB(18,  18,  30),
        TabHover      = Color3.fromRGB(30,  20,  50),
        TabSelected   = Color3.fromRGB(80,  40,  160),
        Content       = Color3.fromRGB(15,  15,  25),
        BottomBar     = Color3.fromRGB(8,   8,   16),
        BottomBtn     = Color3.fromRGB(22,  22,  38),
        BottomBtnHov  = Color3.fromRGB(40,  30,  70),
        Text          = Color3.fromRGB(200, 185, 255),
        TextDim       = Color3.fromRGB(110, 100, 155),
        Accent        = Color3.fromRGB(140, 80,  240),
        Border        = Color3.fromRGB(40,  35,  65),
        ScrollBar     = Color3.fromRGB(60,  50,  100),
    },
}

-- ════════════════════════════════════════════════════════════════════════════
--  UTILITY
-- ════════════════════════════════════════════════════════════════════════════
local function Make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function Corner(obj, radius)
    Make("UICorner", {CornerRadius = UDim.new(0, radius or 6)}, obj)
    return obj
end

local function Stroke(obj, color, thickness)
    Make("UIStroke", {
        Color     = color or Color3.fromRGB(60,60,70),
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
    return obj
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
--  KEYBIND SYSTEM
-- ════════════════════════════════════════════════════════════════════════════
local KeybindSystem = {}
KeybindSystem._binds = {}

function KeybindSystem:Bind(name, key, callback)
    self._binds[name] = {Key = key, Callback = callback}
end

function KeybindSystem:Unbind(name)
    self._binds[name] = nil
end

function KeybindSystem:Init()
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        for _, bind in pairs(self._binds) do
            if input.KeyCode == bind.Key then
                bind.Callback()
            end
        end
    end)
end

KeybindSystem:Init()

-- ════════════════════════════════════════════════════════════════════════════
--  TAB OBJECT
-- ════════════════════════════════════════════════════════════════════════════
local Tab = {}
Tab.__index = Tab

function Tab:_build(sidebar, contentHolder, theme, anims)
    self._theme   = theme
    self._anims   = anims
    self._content = contentHolder
    self._items   = {}

    -- Sidebar button
    self._btn = Make("TextButton", {
        Name              = "Tab_"..self.Name,
        Size              = UDim2.new(1, 0, 0, 38),
        BackgroundColor3  = theme.TabNormal,
        Text              = "",
        AutoButtonColor   = false,
        BorderSizePixel   = 0,
    }, sidebar)
    Corner(self._btn, 5)

    -- Icon (optional)
    if self.Icon and self.Icon ~= "" then
        Make("ImageLabel", {
            Size              = UDim2.new(0,20,0,20),
            Position          = UDim2.new(0,10,0.5,0),
            AnchorPoint       = Vector2.new(0,0.5),
            BackgroundTransparency = 1,
            Image             = self.Icon,
            ImageColor3       = theme.Text,
        }, self._btn)
    end

    -- Label
    self._label = Make("TextLabel", {
        Size              = UDim2.new(1,-40,1,0),
        Position          = UDim2.new(0,36,0,0),
        BackgroundTransparency = 1,
        Text              = self.Name,
        TextColor3        = theme.TextDim,
        Font              = Enum.Font.GothamMedium,
        TextSize          = 13,
        TextXAlignment    = Enum.TextXAlignment.Left,
    }, self._btn)

    -- Left accent bar (hidden by default)
    self._accent = Make("Frame", {
        Size             = UDim2.new(0, 3, 0.6, 0),
        Position         = UDim2.new(0, 0, 0.2, 0),
        BackgroundColor3 = theme.Accent,
        Visible          = false,
        BorderSizePixel  = 0,
    }, self._btn)
    Corner(self._accent, 2)

    -- Content frame
    self._frame = Make("ScrollingFrame", {
        Name              = "Content_"..self.Name,
        Size              = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        BorderSizePixel   = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.ScrollBar,
        Visible           = false,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize        = UDim2.new(0,0,0,0),
    }, contentHolder)
    Make("UIPadding",{
        PaddingTop    = UDim.new(0,10),
        PaddingLeft   = UDim.new(0,12),
        PaddingRight  = UDim.new(0,12),
        PaddingBottom = UDim.new(0,10),
    }, self._frame)
    Make("UIListLayout",{
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0,6),
    }, self._frame)

    -- Hover / click
    anims:HoverEffect(self._btn, theme.TabHover, theme.TabNormal)
    self._btn.MouseButton1Click:Connect(function()
        local mx = Mouse.X - self._btn.AbsolutePosition.X
        local my = Mouse.Y - self._btn.AbsolutePosition.Y
        anims:Ripple(self._btn, mx, my, theme.Accent)
        if self._window then
            self._window:_selectTab(self)
        end
    end)
end

function Tab:_select(state, theme)
    if state then
        self._btn.BackgroundColor3  = theme.TabSelected
        self._label.TextColor3      = theme.Text
        self._accent.Visible        = true
        self._frame.Visible         = true
    else
        self._btn.BackgroundColor3  = theme.TabNormal
        self._label.TextColor3      = theme.TextDim
        self._accent.Visible        = false
        self._frame.Visible         = false
    end
end

-- ─── Element Builders ────────────────────────────────────────────────────────
function Tab:AddLabel(text, color)
    local lbl = Make("TextLabel", {
        Size              = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text              = text,
        TextColor3        = color or self._theme.Text,
        Font              = Enum.Font.Gotham,
        TextSize          = 13,
        TextXAlignment    = Enum.TextXAlignment.Left,
    }, self._frame)
    return lbl
end

function Tab:AddSeparator()
    local sep = Make("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = self._theme.Border,
        BorderSizePixel  = 0,
    }, self._frame)
    return sep
end

function Tab:AddButton(text, callback)
    local btn = Make("TextButton", {
        Size             = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = self._theme.TabNormal,
        Text             = text,
        TextColor3       = self._theme.Text,
        Font             = Enum.Font.GothamMedium,
        TextSize         = 13,
        AutoButtonColor  = false,
        BorderSizePixel  = 0,
    }, self._frame)
    Corner(btn, 5)
    self._anims:HoverEffect(btn, self._theme.TabHover, self._theme.TabNormal)
    btn.MouseButton1Click:Connect(function()
        local mx = Mouse.X - btn.AbsolutePosition.X
        local my = Mouse.Y - btn.AbsolutePosition.Y
        self._anims:Ripple(btn, mx, my, self._theme.Accent)
        self._anims:Bounce(btn)
        if callback then task.spawn(callback) end
    end)
    return btn
end

function Tab:AddToggle(text, default, callback)
    local state = default or false
    local row = Make("Frame", {
        Size             = UDim2.new(1,0,0,34),
        BackgroundTransparency=1,
    }, self._frame)
    Make("TextLabel",{
        Size             = UDim2.new(1,-54,1,0),
        BackgroundTransparency=1,
        Text             = text,
        TextColor3       = self._theme.Text,
        Font             = Enum.Font.Gotham,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, row)
    local track = Make("Frame",{
        Size             = UDim2.new(0,44,0,22),
        Position         = UDim2.new(1,-44,0.5,0),
        AnchorPoint      = Vector2.new(1,0.5),
        BackgroundColor3 = self._theme.TabNormal,
        BorderSizePixel  = 0,
    }, row)
    Corner(track, 11)
    Stroke(track, self._theme.Border)
    local knob = Make("Frame",{
        Size             = UDim2.new(0,16,0,16),
        Position         = UDim2.new(0,3,0.5,0),
        AnchorPoint      = Vector2.new(0,0.5),
        BackgroundColor3 = self._theme.TextDim,
        BorderSizePixel  = 0,
    }, track)
    Corner(knob, 8)

    local function set(v)
        state = v
        self._anims:Tween(knob,{
            Position         = v and UDim2.new(1,-19,0.5,0) or UDim2.new(0,3,0.5,0),
            BackgroundColor3 = v and self._theme.Accent or self._theme.TextDim,
        })
        self._anims:Tween(track,{
            BackgroundColor3 = v and Color3.fromRGB(
                math.clamp(self._theme.Accent.R*255*0.4,0,255),
                math.clamp(self._theme.Accent.G*255*0.4,0,255),
                math.clamp(self._theme.Accent.B*255*0.4,0,255)
            ) or self._theme.TabNormal,
        })
        if callback then task.spawn(callback, state) end
    end
    set(state)

    local btn = Make("TextButton",{
        Size             = UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text             = "",
    }, row)
    btn.MouseButton1Click:Connect(function() set(not state) end)
    return {Set=set, Get=function() return state end}
end

function Tab:AddSlider(text, min, max, default, callback)
    min, max = min or 0, max or 100
    local val = math.clamp(default or min, min, max)

    local wrap = Make("Frame",{Size=UDim2.new(1,0,0,52),BackgroundTransparency=1}, self._frame)
    Make("TextLabel",{
        Size=UDim2.new(1,0,0,20), BackgroundTransparency=1,
        Text=text, TextColor3=self._theme.Text,
        Font=Enum.Font.Gotham, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
    }, wrap)
    local valLbl = Make("TextLabel",{
        Size=UDim2.new(0,40,0,20), Position=UDim2.new(1,-40,0,0),
        BackgroundTransparency=1,
        Text=tostring(val), TextColor3=self._theme.Accent,
        Font=Enum.Font.GothamMedium, TextSize=13, TextXAlignment=Enum.TextXAlignment.Right,
    }, wrap)
    local track = Make("Frame",{
        Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,0,32),
        BackgroundColor3=self._theme.TabNormal, BorderSizePixel=0,
    }, wrap)
    Corner(track, 3)
    local fill = Make("Frame",{
        Size=UDim2.new((val-min)/(max-min),0,1,0),
        BackgroundColor3=self._theme.Accent, BorderSizePixel=0,
    }, track)
    Corner(fill, 3)
    local knob = Make("Frame",{
        Size=UDim2.new(0,14,0,14),
        Position=UDim2.new((val-min)/(max-min),0,0.5,0),
        AnchorPoint=Vector2.new(0.5,0.5),
        BackgroundColor3=self._theme.Text, BorderSizePixel=0,
    }, track)
    Corner(knob, 7)

    local sliding = false
    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
        val = math.floor(min + rel*(max-min)+0.5)
        valLbl.Text = tostring(val)
        fill.Size = UDim2.new(rel,0,1,0)
        knob.Position = UDim2.new(rel,0,0.5,0)
        if callback then task.spawn(callback, val) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            sliding=true; update(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end
    end)
    return {Get=function() return val end, Set=function(v) update(track.AbsolutePosition.X+((v-min)/(max-min))*track.AbsoluteSize.X) end}
end

function Tab:AddTextbox(placeholder, callback)
    local box = Make("TextBox",{
        Size=UDim2.new(1,0,0,34),
        BackgroundColor3=self._theme.TabNormal,
        Text="", PlaceholderText=placeholder or "Type here...",
        TextColor3=self._theme.Text, PlaceholderColor3=self._theme.TextDim,
        Font=Enum.Font.Gotham, TextSize=13, BorderSizePixel=0,
        ClearTextOnFocus=false,
    }, self._frame)
    Corner(box, 5)
    Stroke(box, self._theme.Border)
    Make("UIPadding",{PaddingLeft=UDim.new(0,10)}, box)
    box.FocusLost:Connect(function(enter)
        if callback then task.spawn(callback, box.Text, enter) end
    end)
    return box
end

function Tab:AddDropdown(text, options, default, callback)
    local selected = default or options[1]
    local open = false

    local wrap = Make("Frame",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,ClipsDescendants=false}, self._frame)

    local main = Make("TextButton",{
        Size=UDim2.new(1,0,0,34),
        BackgroundColor3=self._theme.TabNormal,
        Text="", AutoButtonColor=false, BorderSizePixel=0,
    }, wrap)
    Corner(main, 5)
    Stroke(main, self._theme.Border)

    Make("TextLabel",{
        Size=UDim2.new(1,-30,1,0), Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1, Text=text..":  "..tostring(selected),
        TextColor3=self._theme.Text, Font=Enum.Font.Gotham, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
    }, main)
    local arrow = Make("TextLabel",{
        Size=UDim2.new(0,20,0,20), Position=UDim2.new(1,-26,0.5,0),
        AnchorPoint=Vector2.new(0,0.5), BackgroundTransparency=1,
        Text="▾", TextColor3=self._theme.TextDim, Font=Enum.Font.GothamBold, TextSize=14,
    }, main)

    local dropFrame = Make("Frame",{
        Size=UDim2.new(1,0,0,#options*34),
        Position=UDim2.new(0,0,0,38),
        BackgroundColor3=self._theme.TabNormal,
        Visible=false, BorderSizePixel=0, ZIndex=20,
    }, wrap)
    Corner(dropFrame, 5)
    Stroke(dropFrame, self._theme.Border)
    Make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder}, dropFrame)

    for _, opt in ipairs(options) do
        local ob = Make("TextButton",{
            Size=UDim2.new(1,0,0,34),
            BackgroundColor3=self._theme.TabNormal, Text=tostring(opt),
            TextColor3=self._theme.TextDim, Font=Enum.Font.Gotham, TextSize=13,
            AutoButtonColor=false, BorderSizePixel=0, ZIndex=21,
        }, dropFrame)
        self._anims:HoverEffect(ob, self._theme.TabHover, self._theme.TabNormal)
        ob.MouseButton1Click:Connect(function()
            selected=opt
            main:FindFirstChildWhichIsA("TextLabel").Text = text..":  "..tostring(opt)
            if callback then task.spawn(callback,opt) end
            open=false; dropFrame.Visible=false
            Animations:Tween(arrow,{Rotation=0})
        end)
    end

    main.MouseButton1Click:Connect(function()
        open=not open
        dropFrame.Visible=open
        Animations:Tween(arrow,{Rotation=open and 180 or 0})
    end)
    return {Get=function() return selected end}
end

-- ════════════════════════════════════════════════════════════════════════════
--  WINDOW OBJECT
-- ════════════════════════════════════════════════════════════════════════════
local Window = {}
Window.__index = Window

function Window:_build()
    local theme = self._theme
    local sg = Make("ScreenGui",{
        Name           = self.Title.."_GUI",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })

    -- Try to parent to CoreGui, fallback to PlayerGui
    local ok2 = pcall(function()
        sg.Parent = game:GetService("CoreGui")
    end)
    if not ok2 then
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- ── Outer Window ────────────────────────────────────────────────────────
    local win = Make("Frame",{
        Name             = "Window",
        Size             = self.Size,
        Position         = UDim2.new(0.5,-self.Size.X.Offset/2,0.5,-self.Size.Y.Offset/2),
        BackgroundColor3 = theme.Window,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Visible          = false,
    }, sg)
    Corner(win, 8)
    Stroke(win, theme.Border, 1)
    Make("UIGradient",{
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(45,45,55)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(25,25,33)),
        }),
        Rotation=90,
    }, win)

    self._sg  = sg
    self._win = win

    -- ── Topbar ──────────────────────────────────────────────────────────────
    local topbar = Make("Frame",{
        Name             = "Topbar",
        Size             = UDim2.new(1,0,0,36),
        BackgroundColor3 = theme.Topbar,
        BorderSizePixel  = 0,
    }, win)
    Make("Frame",{   -- accent line
        Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2),
        BackgroundColor3=theme.TopbarAccent, BorderSizePixel=0,
    }, topbar)

    -- Title
    Make("TextLabel",{
        Size=UDim2.new(1,-90,1,0), Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1,
        Text=self.Title, TextColor3=theme.Text,
        Font=Enum.Font.GothamBold, TextSize=14,
        TextXAlignment=Enum.TextXAlignment.Left,
    }, topbar)

    -- Close button
    local closeBtn = Make("TextButton",{
        Size=UDim2.new(0,28,0,24),
        Position=UDim2.new(1,-34,0.5,0), AnchorPoint=Vector2.new(0,0.5),
        BackgroundColor3=Color3.fromRGB(200,60,60),
        Text="✕", TextColor3=Color3.fromRGB(255,255,255),
        Font=Enum.Font.GothamBold, TextSize=12,
        AutoButtonColor=false, BorderSizePixel=0,
    }, topbar)
    Corner(closeBtn, 5)
    Animations:HoverEffect(closeBtn, Color3.fromRGB(230,80,80), Color3.fromRGB(200,60,60))
    closeBtn.MouseButton1Click:Connect(function() self:Close() end)

    -- Minimize button
    local minBtn = Make("TextButton",{
        Size=UDim2.new(0,28,0,24),
        Position=UDim2.new(1,-66,0.5,0), AnchorPoint=Vector2.new(0,0.5),
        BackgroundColor3=Color3.fromRGB(200,150,30),
        Text="─", TextColor3=Color3.fromRGB(255,255,255),
        Font=Enum.Font.GothamBold, TextSize=12,
        AutoButtonColor=false, BorderSizePixel=0,
    }, topbar)
    Corner(minBtn, 5)
    Animations:HoverEffect(minBtn, Color3.fromRGB(230,175,50), Color3.fromRGB(200,150,30))

    local minimized = false
    local fullH = self.Size.Y.Offset
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Animations:Tween(win, {
            Size = minimized
                and UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 36)
                or  self.Size
        }, 0.25)
    end)

    MakeDraggable(win, topbar)

    -- ── Sidebar ─────────────────────────────────────────────────────────────
    local sidebar = Make("Frame",{
        Name="Sidebar",
        Size=UDim2.new(0,160,1,-36-32),  -- leave room for topbar and bottombar
        Position=UDim2.new(0,0,0,36),
        BackgroundColor3=theme.Sidebar,
        BorderSizePixel=0,
    }, win)
    Make("UIListLayout",{
        SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,3),
    }, sidebar)
    Make("UIPadding",{
        PaddingTop=UDim.new(0,8), PaddingLeft=UDim.new(0,6),
        PaddingRight=UDim.new(0,6),
    }, sidebar)

    -- Sidebar separator line
    Make("Frame",{
        Size=UDim2.new(0,1,1,-36-32), Position=UDim2.new(0,160,0,36),
        BackgroundColor3=theme.Border, BorderSizePixel=0,
    }, win)

    -- ── Content area ─────────────────────────────────────────────────────────
    local contentHolder = Make("Frame",{
        Name="ContentHolder",
        Size=UDim2.new(1,-162,1,-36-32),
        Position=UDim2.new(0,162,0,36),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ClipsDescendants=true,
    }, win)

    -- ── Bottom bar ───────────────────────────────────────────────────────────
    local bottomBar = Make("Frame",{
        Name="BottomBar",
        Size=UDim2.new(1,0,0,32),
        Position=UDim2.new(0,0,1,-32),
        BackgroundColor3=theme.BottomBar,
        BorderSizePixel=0,
    }, win)
    -- top line
    Make("Frame",{
        Size=UDim2.new(1,0,0,1), BackgroundColor3=theme.Border, BorderSizePixel=0,
    }, bottomBar)

    local function BottomBtn(text, pos, callback)
        local b = Make("TextButton",{
            Size=UDim2.new(0,88,0,22),
            Position=pos,
            AnchorPoint=Vector2.new(0,0.5),
            BackgroundColor3=theme.BottomBtn,
            Text=text, TextColor3=theme.TextDim,
            Font=Enum.Font.Gotham, TextSize=11,
            AutoButtonColor=false, BorderSizePixel=0,
        }, bottomBar)
        Corner(b, 5)
        Animations:HoverEffect(b, theme.BottomBtnHov, theme.BottomBtn)
        if callback then
            b.MouseButton1Click:Connect(function()
                Animations:Ripple(b, Mouse.X-b.AbsolutePosition.X, Mouse.Y-b.AbsolutePosition.Y, theme.Accent)
                task.spawn(callback)
            end)
        end
        return b
    end

    BottomBtn("🎨  Themes",   UDim2.new(0,8,0.5,0),  function() self:_openThemePanel() end)
    BottomBtn("⌨  Keybinds", UDim2.new(0,104,0.5,0), function() self:_openKeybindPanel() end)
    BottomBtn("⚙  Settings", UDim2.new(0,200,0.5,0), function() self:_openSettingsPanel() end)

    self._sidebar      = sidebar
    self._contentHolder= contentHolder
    self._bottomBar    = bottomBar
    self._tabs         = {}
    self._activeTab    = nil

    -- ── Overlay panel (for themes/keybinds/settings) ─────────────────────────
    self._overlay = Make("Frame",{
        Size=UDim2.new(1,-162,1,-36-32),
        Position=UDim2.new(0,162,0,36),
        BackgroundColor3=theme.Content,
        BorderSizePixel=0,
        Visible=false, ZIndex=15,
    }, win)
    Corner(self._overlay, 0)

    local overlayClose = Make("TextButton",{
        Size=UDim2.new(0,24,0,24), Position=UDim2.new(1,-30,0,6),
        BackgroundColor3=Color3.fromRGB(200,60,60),
        Text="✕", TextColor3=Color3.fromRGB(255,255,255),
        Font=Enum.Font.GothamBold, TextSize=12,
        AutoButtonColor=false, BorderSizePixel=0, ZIndex=16,
    }, self._overlay)
    Corner(overlayClose, 5)
    overlayClose.MouseButton1Click:Connect(function()
        Animations:FadeOut(self._overlay, 0.15)
    end)

    self._overlayContent = Make("ScrollingFrame",{
        Size=UDim2.new(1,0,1,-36), Position=UDim2.new(0,0,0,36),
        BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=4, ScrollBarImageColor3=theme.ScrollBar,
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.new(0,0,0,0), ZIndex=16,
    }, self._overlay)
    Make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)}, self._overlayContent)
    Make("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingTop=UDim.new(0,10),PaddingRight=UDim.new(0,14)}, self._overlayContent)
    self._overlayTitle = Make("TextLabel",{
        Size=UDim2.new(1,0,0,26), Position=UDim2.new(0,14,0,6),
        BackgroundTransparency=1, Text="", TextColor3=theme.Text,
        Font=Enum.Font.GothamBold, TextSize=15,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=16,
    }, self._overlay)
end

function Window:_clearOverlay()
    for _, c in ipairs(self._overlayContent:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
end

function Window:_showOverlay(title)
    self:_clearOverlay()
    self._overlayTitle.Text = title
    Animations:FadeIn(self._overlay, 0.15)
end

function Window:_openThemePanel()
    self:_showOverlay("🎨  Themes")
    local names = {}
    for k in pairs(Themes) do table.insert(names, k) end
    table.sort(names)
    for _, name in ipairs(names) do
        local btn = Make("TextButton",{
            Size=UDim2.new(1,0,0,36),
            BackgroundColor3=self._theme.TabNormal,
            Text=name, TextColor3=self._theme.Text,
            Font=Enum.Font.GothamMedium, TextSize=13,
            AutoButtonColor=false, BorderSizePixel=0, ZIndex=17,
        }, self._overlayContent)
        Corner(btn, 5)
        Animations:HoverEffect(btn, self._theme.TabHover, self._theme.TabNormal)
        btn.MouseButton1Click:Connect(function()
            self:ApplyTheme(name)
            Animations:FadeOut(self._overlay, 0.15)
        end)
    end
end

function Window:_openKeybindPanel()
    self:_showOverlay("⌨  Keybinds")
    local info = Make("TextLabel",{
        Size=UDim2.new(1,0,0,60),
        BackgroundTransparency=1,
        Text="Toggle GUI: "..tostring(self.Keybind)..
             "\n\nTo change, update the Keybind property\nand re-call :SetKeybind(key).",
        TextColor3=self._theme.TextDim,
        Font=Enum.Font.Gotham, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextWrapped=true, ZIndex=17,
    }, self._overlayContent)
    -- List all registered binds
    for name, bind in pairs(KeybindSystem._binds) do
        Make("TextLabel",{
            Size=UDim2.new(1,0,0,28),
            BackgroundTransparency=1,
            Text="• "..name.." → "..tostring(bind.Key),
            TextColor3=self._theme.Text,
            Font=Enum.Font.Gotham, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17,
        }, self._overlayContent)
    end
end

function Window:_openSettingsPanel()
    self:_showOverlay("⚙  Settings")
    -- Placeholder: expose flag to toggle notifications, etc.
    Make("TextLabel",{
        Size=UDim2.new(1,0,0,30),
        BackgroundTransparency=1,
        Text="GUI Version: 1.0  |  External modules: "..tostring(#self._externalModules),
        TextColor3=self._theme.TextDim,
        Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17,
    }, self._overlayContent)

    -- Toggle: show topbar title
    local titleToggle = Make("Frame",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,ZIndex=17},self._overlayContent)
    Make("TextLabel",{
        Size=UDim2.new(1,-54,1,0), BackgroundTransparency=1,
        Text="Show Title", TextColor3=self._theme.Text,
        Font=Enum.Font.Gotham, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17,
    }, titleToggle)
end

function Window:_selectTab(tab)
    for _, t in ipairs(self._tabs) do
        t:_select(t == tab, self._theme)
    end
    self._activeTab = tab
end

-- ─── Public API ──────────────────────────────────────────────────────────────
function Window:AddTab(name, icon)
    local tab = setmetatable({
        Name     = name,
        Icon     = icon or "",
        _window  = self,
    }, Tab)
    tab:_build(self._sidebar, self._contentHolder, self._theme, Animations)
    table.insert(self._tabs, tab)
    if #self._tabs == 1 then
        self:_selectTab(tab)
    end
    return tab
end

function Window:ApplyTheme(name)
    local t = Themes[name]
    if not t then warn("Theme '"..name.."' not found.") return end
    self._theme = t
    -- Rebuild colors across the GUI
    -- (Re-building every element individually would be complex;
    --  simplest robust approach is store refs or recreate.
    --  For now we tween the main containers.)
    Animations:Tween(self._win, {BackgroundColor3 = t.Window})
    Animations:Tween(self._sidebar, {BackgroundColor3 = t.Sidebar})
    Animations:Tween(self._bottomBar, {BackgroundColor3 = t.BottomBar})
end

function Window:SetKeybind(key)
    self.Keybind = key
    KeybindSystem:Bind(self.Title.."_Toggle", key, function()
        if self._win.Visible then self:Close() else self:Open() end
    end)
end

function Window:Open()
    self._win.Size = UDim2.new(0,0,0,0)
    self._win.Visible = true
    Animations:Tween(self._win, {Size = self.Size}, 0.3,
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function Window:Close()
    Animations:Tween(self._win, {Size = UDim2.new(0,0,0,0)}, 0.25,
        Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.delay(0.3, function() self._win.Visible = false end)
end

function Window:Toggle()
    if self._win.Visible then self:Close() else self:Open() end
end

function Window:Destroy()
    self._sg:Destroy()
end

-- ────────────────────────────────────────────────────────────────────────────
--  External Module Loader
-- ────────────────────────────────────────────────────────────────────────────
function Window:LoadModule(url, ...)
    local ok3, result = pcall(function(...)
        return loadstring(game:HttpGet(url))(self, Animations, Themes, ...)
    end, ...)
    if not ok3 then
        warn("[GUI] Failed to load external module from: "..url.."\n"..tostring(result))
        return nil
    end
    table.insert(self._externalModules, {url=url, module=result})
    return result
end

-- ════════════════════════════════════════════════════════════════════════════
--  GUI HANDLER  (public factory)
-- ════════════════════════════════════════════════════════════════════════════
local GuiHandler = {}
GuiHandler.__index = GuiHandler

function GuiHandler:CreateWindow(opts)
    opts = opts or {}
    local win = setmetatable({
        Title           = opts.Title   or "GUI",
        Size            = opts.Size    or UDim2.new(0,600,0,420),
        Keybind         = opts.Keybind or Enum.KeyCode.RightShift,
        _theme          = Themes[opts.Theme or "Dark"],
        _externalModules= {},
    }, Window)
    win:_build()
    win:SetKeybind(win.Keybind)
    return win
end

-- Expose sub-systems so external modules can use them
GuiHandler.Themes       = Themes
GuiHandler.Keybinds     = KeybindSystem
GuiHandler.Animations   = Animations

return GuiHandler
