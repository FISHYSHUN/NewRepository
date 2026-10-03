--[[
    =====================================================
         GUI HANDLING MODULE v1.0
         loadstring(game:HttpGet(URL))()
    =====================================================

    Design: Square aesthetic with offset shadow frames.
    Shadow stays inside ClipsDescendants bounds.

    Usage:
        local GUI = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/FISHYSHUN/NewRepository/main/Gui.lua"
        ))()
        local win = GUI:CreateWindow({ Title="Hub", Keybind=Enum.KeyCode.RightShift })
        local tab = win:AddTab("Home")
        tab:AddButton("Click", function() end)
        win:Open()
]]

-- =============================================================================
--  SERVICES
-- =============================================================================
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- =============================================================================
--  ANIMATIONS DEPENDENCY
-- =============================================================================
local ANIM_URL = "https://raw.githubusercontent.com/FISHYSHUN/NewRepository/main/Animations.lua"
local Animations
local _ok, _err = pcall(function()
    Animations = loadstring(game:HttpGet(ANIM_URL))()
end)
if not _ok then
    Animations = {}
    function Animations:Tween(inst, props, dur, style, dir)
        TweenService:Create(inst,
            TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quart,
                dir or Enum.EasingDirection.Out), props):Play()
    end
    function Animations:HoverEffect(inst, hC, nC, dur)
        nC = nC or inst.BackgroundColor3
        inst.MouseEnter:Connect(function() self:Tween(inst,{BackgroundColor3=hC},dur or 0.12) end)
        inst.MouseLeave:Connect(function() self:Tween(inst,{BackgroundColor3=nC},dur or 0.12) end)
    end
    function Animations:FadeIn(inst, dur)
        inst.BackgroundTransparency = 1; inst.Visible = true
        self:Tween(inst, {BackgroundTransparency=0}, dur or 0.15)
    end
    function Animations:FadeOut(inst, dur, cb)
        local t = TweenService:Create(inst, TweenInfo.new(dur or 0.15),
            {BackgroundTransparency=1})
        t.Completed:Connect(function() inst.Visible=false; if cb then cb() end end)
        t:Play()
    end
    function Animations:Bounce(inst, dur)
        local o = inst.Size
        local b = UDim2.new(o.X.Scale*1.05, o.X.Offset, o.Y.Scale*1.05, o.Y.Offset)
        local t1 = TweenService:Create(inst, TweenInfo.new((dur or 0.12)/2), {Size=b})
        t1.Completed:Connect(function()
            TweenService:Create(inst, TweenInfo.new((dur or 0.12)/2), {Size=o}):Play()
        end)
        t1:Play()
    end
    -- Square ripple (no UICorner)
    function Animations:Ripple(parent, x, y, color)
        color = color or Color3.fromRGB(255,255,255)
        local r = Instance.new("Frame")
        r.AnchorPoint = Vector2.new(0.5, 0.5)
        r.Position = UDim2.new(0, x, 0, y)
        r.Size = UDim2.new(0, 0, 0, 0)
        r.BackgroundColor3 = color
        r.BackgroundTransparency = 0.75
        r.ZIndex = parent.ZIndex + 10
        r.BorderSizePixel = 0
        r.Parent = parent
        local mx = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.2
        TweenService:Create(r, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size=UDim2.new(0,mx,0,mx), BackgroundTransparency=1}):Play()
        game:GetService("Debris"):AddItem(r, 0.5)
    end
end

-- =============================================================================
--  THEME ENGINE
-- =============================================================================
local Themes = {
    Dark = {
        Window       = Color3.fromRGB(28,  28,  33),
        TopbarAccent = Color3.fromRGB(100, 180, 240),
        Topbar       = Color3.fromRGB(18,  18,  22),
        Sidebar      = Color3.fromRGB(22,  22,  27),
        TabNormal    = Color3.fromRGB(38,  38,  46),
        TabHover     = Color3.fromRGB(52,  52,  62),
        TabSelected  = Color3.fromRGB(55,  95,  155),
        Content      = Color3.fromRGB(30,  30,  36),
        BottomBar    = Color3.fromRGB(18,  18,  22),
        BottomBtn    = Color3.fromRGB(44,  44,  54),
        BottomBtnHov = Color3.fromRGB(60,  60,  74),
        Text         = Color3.fromRGB(215, 215, 225),
        TextDim      = Color3.fromRGB(120, 120, 138),
        Accent       = Color3.fromRGB(100, 180, 240),
        Border       = Color3.fromRGB(48,  48,  58),
        ScrollBar    = Color3.fromRGB(58,  58,  72),
        Element      = Color3.fromRGB(40,  40,  50),
        ElementHov   = Color3.fromRGB(56,  56,  68),
    },
    Light = {
        Window       = Color3.fromRGB(235, 235, 242),
        TopbarAccent = Color3.fromRGB(60,  120, 210),
        Topbar       = Color3.fromRGB(215, 216, 226),
        Sidebar      = Color3.fromRGB(220, 221, 230),
        TabNormal    = Color3.fromRGB(200, 202, 215),
        TabHover     = Color3.fromRGB(185, 187, 202),
        TabSelected  = Color3.fromRGB(80,  140, 220),
        Content      = Color3.fromRGB(240, 240, 248),
        BottomBar    = Color3.fromRGB(210, 212, 222),
        BottomBtn    = Color3.fromRGB(190, 192, 208),
        BottomBtnHov = Color3.fromRGB(170, 172, 190),
        Text         = Color3.fromRGB(28,  28,  40),
        TextDim      = Color3.fromRGB(100, 100, 120),
        Accent       = Color3.fromRGB(60,  120, 210),
        Border       = Color3.fromRGB(175, 177, 195),
        ScrollBar    = Color3.fromRGB(155, 157, 175),
        Element      = Color3.fromRGB(195, 196, 210),
        ElementHov   = Color3.fromRGB(178, 180, 196),
    },
    Midnight = {
        Window       = Color3.fromRGB(8,   8,   14),
        TopbarAccent = Color3.fromRGB(130, 70,  230),
        Topbar       = Color3.fromRGB(5,   5,   10),
        Sidebar      = Color3.fromRGB(10,  10,  18),
        TabNormal    = Color3.fromRGB(18,  16,  30),
        TabHover     = Color3.fromRGB(28,  22,  48),
        TabSelected  = Color3.fromRGB(72,  36,  150),
        Content      = Color3.fromRGB(12,  11,  20),
        BottomBar    = Color3.fromRGB(6,   5,   12),
        BottomBtn    = Color3.fromRGB(22,  18,  38),
        BottomBtnHov = Color3.fromRGB(36,  28,  62),
        Text         = Color3.fromRGB(195, 180, 255),
        TextDim      = Color3.fromRGB(100, 90,  148),
        Accent       = Color3.fromRGB(130, 70,  230),
        Border       = Color3.fromRGB(35,  30,  58),
        ScrollBar    = Color3.fromRGB(50,  42,  88),
        Element      = Color3.fromRGB(22,  18,  36),
        ElementHov   = Color3.fromRGB(34,  28,  56),
    },
}

-- =============================================================================
--  CONSTANTS
-- =============================================================================
local SHADOW     = 4    -- shadow offset in pixels (right + down)
local SIDEBAR_W  = 90   -- sidebar width
local TOPBAR_H   = 30   -- topbar height
local BOTTOMBAR_H= 30   -- bottom bar height
local TAB_H      = 32   -- sidebar tab height
local TAB_GAP    = 4    -- gap between tabs
local ELEM_H     = 34   -- default element height in content area

-- =============================================================================
--  UTILITY
-- =============================================================================
local function Make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

-- Darken a color by a multiplier (0 = black, 1 = same)
local function Darken(color, factor)
    factor = factor or 0.5
    return Color3.fromRGB(
        math.clamp(math.floor(color.R * 255 * factor), 0, 255),
        math.clamp(math.floor(color.G * 255 * factor), 0, 255),
        math.clamp(math.floor(color.B * 255 * factor), 0, 255)
    )
end

--[[
    MakeShadowBox
    Creates a ClipsDescendants wrapper of `size` placed at `pos` inside `parent`.
    Inside it:
      - Shadow frame: same visual size as button, shifted SHADOW px right+down
      - Surface frame: same visual size, at 0,0 (covers top-left, shadow peeks bottom-right)
    Returns: wrapper, surface
    The surface is what you parent children to / style as the "button face".
]]
local function MakeShadowBox(parent, mainColor, size, pos)
    local shadowColor = Darken(mainColor, 0.48)

    -- Outer wrapper -- clips everything inside it
    local wrap = Make("Frame", {
        Size             = size,
        Position         = pos or UDim2.new(0,0,0,0),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, parent)

    -- Shadow layer (shifted right+down, same visual size as surface)
    Make("Frame", {
        Size             = UDim2.new(1, -SHADOW, 1, -SHADOW),
        Position         = UDim2.new(0, SHADOW, 0, SHADOW),
        BackgroundColor3 = shadowColor,
        BorderSizePixel  = 0,
        ZIndex           = wrap.ZIndex,
    }, wrap)

    -- Surface (sits on top of shadow at 0,0)
    local surface = Make("Frame", {
        Size             = UDim2.new(1, -SHADOW, 1, -SHADOW),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = mainColor,
        BorderSizePixel  = 0,
        ZIndex           = wrap.ZIndex + 1,
    }, wrap)

    return wrap, surface
end

-- MakeShadowButton: shadow box whose surface is a TextButton
local function MakeShadowButton(parent, mainColor, size, pos, text, textColor, font, textSize)
    local shadowColor = Darken(mainColor, 0.48)

    local wrap = Make("Frame", {
        Size             = size,
        Position         = pos or UDim2.new(0,0,0,0),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, parent)

    Make("Frame", {
        Size             = UDim2.new(1, -SHADOW, 1, -SHADOW),
        Position         = UDim2.new(0, SHADOW, 0, SHADOW),
        BackgroundColor3 = shadowColor,
        BorderSizePixel  = 0,
        ZIndex           = wrap.ZIndex,
    }, wrap)

    local btn = Make("TextButton", {
        Size             = UDim2.new(1, -SHADOW, 1, -SHADOW),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = mainColor,
        BorderSizePixel  = 0,
        Text             = text or "",
        TextColor3       = textColor or Color3.fromRGB(215,215,225),
        Font             = font or Enum.Font.GothamMedium,
        TextSize         = textSize or 13,
        AutoButtonColor  = false,
        ZIndex           = wrap.ZIndex + 1,
    }, wrap)

    return wrap, btn
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = i.Position
            startPos  = frame.Position
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            local d = dragInput.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- =============================================================================
--  KEYBIND SYSTEM
-- =============================================================================
local KeybindSystem = {}
KeybindSystem._binds = {}

function KeybindSystem:Bind(name, key, cb)
    self._binds[name] = {Key=key, Callback=cb}
end
function KeybindSystem:Unbind(name)
    self._binds[name] = nil
end
function KeybindSystem:Init()
    UserInputService.InputBegan:Connect(function(i, gpe)
        if gpe then return end
        for _, b in pairs(self._binds) do
            if i.KeyCode == b.Key then b.Callback() end
        end
    end)
end
KeybindSystem:Init()

-- =============================================================================
--  TAB OBJECT
-- =============================================================================
local Tab = {}
Tab.__index = Tab

function Tab:_build(sidebar, contentHolder, theme, anims)
    self._theme   = theme
    self._anims   = anims

    -- ---- Sidebar tab slot (shadow box) -----
    -- Each slot is (SIDEBAR_W x TAB_H+SHADOW) to fit the shadow
    local slotH  = TAB_H + SHADOW
    local _, surface = MakeShadowBox(
        sidebar,
        theme.TabNormal,
        UDim2.new(1, 0, 0, slotH),
        nil  -- UIListLayout controls Y
    )
    self._surface = surface

    -- Tab label (no icon in square style, just text)
    self._label = Make("TextLabel", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text             = self.Name,
        TextColor3       = theme.TextDim,
        Font             = Enum.Font.GothamMedium,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Center,
        ZIndex           = surface.ZIndex + 1,
    }, surface)

    -- Left accent strip (hidden by default, shown when selected)
    self._accent = Make("Frame", {
        Size             = UDim2.new(0, 2, 1, 0),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel  = 0,
        Visible          = false,
        ZIndex           = surface.ZIndex + 2,
    }, surface)

    -- Invisible click button covering the surface
    self._btn = Make("TextButton", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text             = "",
        ZIndex           = surface.ZIndex + 3,
    }, surface)

    -- Hover: shift tab surface color
    self._btn.MouseEnter:Connect(function()
        if not self._selected then
            anims:HoverEnter(surface, theme.TabHover)
        end
    end)
    self._btn.MouseLeave:Connect(function()
        if not self._selected then
            anims:HoverLeave(surface, theme.TabNormal)
        end
    end)

    -- Press/release: surface nudges toward shadow on click
    anims:PressEffect(self._btn, surface, 2)

    self._btn.MouseButton1Click:Connect(function()
        if self._window then self._window:_selectTab(self) end
    end)

    -- ---- Content ScrollingFrame ----
    self._frame = Make("ScrollingFrame", {
        Name                 = "Content_"..self.Name,
        Size                 = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        ScrollBarThickness   = 3,
        ScrollBarImageColor3 = theme.ScrollBar,
        Visible              = false,
        AutomaticCanvasSize  = Enum.AutomaticSize.Y,
        CanvasSize           = UDim2.new(0,0,0,0),
        ZIndex               = 2,
    }, contentHolder)
    Make("UIPadding", {
        PaddingTop    = UDim.new(0, 10),
        PaddingLeft   = UDim.new(0, 10),
        PaddingRight  = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
    }, self._frame)
    Make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, SHADOW + 3),  -- gap accounts for shadow
    }, self._frame)
end

function Tab:_select(state, theme)
    self._selected = state
    if state then
        -- Animate surface and label color in
        self._anims:Tween(self._surface, {BackgroundColor3 = theme.TabSelected}, 0.15)
        self._anims:Tween(self._label,   {TextColor3       = theme.Text},        0.15)
        -- Show accent strip
        self._accent.BackgroundTransparency = 1
        self._accent.Visible = true
        self._anims:Tween(self._accent, {BackgroundTransparency = 0}, 0.15)
        -- Reveal content
        self._frame.BackgroundTransparency = 1
        self._frame.Visible = true
        self._anims:Tween(self._frame, {BackgroundTransparency = 0}, 0.15)
    else
        -- Animate surface and label color out
        self._anims:Tween(self._surface, {BackgroundColor3 = theme.TabNormal}, 0.12)
        self._anims:Tween(self._label,   {TextColor3       = theme.TextDim},   0.12)
        -- Hide accent strip
        local t = self._anims:Tween(self._accent, {BackgroundTransparency = 1}, 0.10)
        t.Completed:Connect(function(s)
            if s == Enum.PlaybackState.Completed then
                self._accent.Visible = false
                self._accent.BackgroundTransparency = 0
            end
        end)
        self._frame.Visible = false
    end
end

-- =============================================================================
--  TAB ELEMENT BUILDERS
-- =============================================================================

-- Each element is wrapped in a slot frame (with padding for shadow)
-- The slot is managed by UIListLayout in _frame
-- Inside: MakeShadowBox or MakeShadowButton creates the shadowed element

function Tab:_slot(h)
    -- The slot height = element height + SHADOW so shadow fits inside
    local slot = Make("Frame", {
        Size             = UDim2.new(1, 0, 0, h + SHADOW),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, self._frame)
    return slot
end

function Tab:AddLabel(text, color)
    local lbl = Make("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text             = text,
        TextColor3       = color or self._theme.TextDim,
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
    }, self._frame)
    return lbl
end

function Tab:AddSeparator()
    local sep = Make("Frame", {
        Size             = UDim2.new(1, 0, 0, 1 + SHADOW),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, self._frame)
    Make("Frame", {
        Size             = UDim2.new(1, -SHADOW, 0, 1),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self._theme.Border,
        BorderSizePixel  = 0,
    }, sep)
    -- Shadow line below
    Make("Frame", {
        Size             = UDim2.new(1, -SHADOW, 0, 1),
        Position         = UDim2.new(0, SHADOW, 0, SHADOW),
        BackgroundColor3 = Darken(self._theme.Border, 0.45),
        BorderSizePixel  = 0,
    }, sep)
    return sep
end

function Tab:AddButton(text, callback)
    local slot = self:_slot(ELEM_H)
    local shadowColor = Darken(self._theme.Element, 0.48)

    -- Shadow
    Make("Frame", {
        Size             = UDim2.new(1, -SHADOW, 0, ELEM_H),
        Position         = UDim2.new(0, SHADOW, 0, SHADOW),
        BackgroundColor3 = shadowColor,
        BorderSizePixel  = 0,
    }, slot)

    -- Button surface
    local btn = Make("TextButton", {
        Size             = UDim2.new(1, -SHADOW, 0, ELEM_H),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self._theme.Element,
        BorderSizePixel  = 0,
        Text             = text,
        TextColor3       = self._theme.Text,
        Font             = Enum.Font.GothamMedium,
        TextSize         = 13,
        AutoButtonColor  = false,
        ZIndex           = 3,
    }, slot)

    -- Hover + press/release via Animations module
    self._anims:HoverEffect(btn, self._theme.ElementHov, self._theme.Element)
    self._anims:PressEffect(btn, btn, 2)

    btn.MouseButton1Click:Connect(function()
        if callback then task.spawn(callback) end
    end)
    return btn
end

function Tab:AddToggle(text, default, callback)
    local state = default or false
    local slot  = self:_slot(ELEM_H)

    -- Shadow
    Make("Frame", {
        Size             = UDim2.new(1, -SHADOW, 0, ELEM_H),
        Position         = UDim2.new(0, SHADOW, 0, SHADOW),
        BackgroundColor3 = Darken(self._theme.Element, 0.48),
        BorderSizePixel  = 0,
    }, slot)

    -- Row surface
    local row = Make("Frame", {
        Size             = UDim2.new(1, -SHADOW, 0, ELEM_H),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self._theme.Element,
        BorderSizePixel  = 0,
        ZIndex           = 3,
    }, slot)

    Make("TextLabel", {
        Size             = UDim2.new(1, -50, 1, 0),
        Position         = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text             = text,
        TextColor3       = self._theme.Text,
        Font             = Enum.Font.Gotham,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 4,
    }, row)

    -- Square toggle track
    local trackW, trackH = 34, 16
    local trackShadow = Make("Frame", {
        Size             = UDim2.new(0, trackW, 0, trackH),
        Position         = UDim2.new(1, -(trackW+8+2), 0.5, -trackH/2 + 2),
        BackgroundColor3 = Darken(self._theme.Element, 0.4),
        BorderSizePixel  = 0,
        ZIndex           = 4,
    }, row)
    local track = Make("Frame", {
        Size             = UDim2.new(0, trackW, 0, trackH),
        Position         = UDim2.new(1, -(trackW+8+2), 0.5, -trackH/2),
        BackgroundColor3 = self._theme.Border,
        BorderSizePixel  = 0,
        ZIndex           = 5,
        ClipsDescendants = true,
    }, row)

    -- Square knob
    local knobSize = trackH - 4
    local knob = Make("Frame", {
        Size             = UDim2.new(0, knobSize, 0, knobSize),
        Position         = UDim2.new(0, 2, 0.5, -knobSize/2),
        BackgroundColor3 = self._theme.TextDim,
        BorderSizePixel  = 0,
        ZIndex           = 6,
    }, track)

    local function setToggle(v)
        state = v
        self._anims:Tween(knob, {
            Position         = v and UDim2.new(1, -(knobSize+2), 0.5, -knobSize/2)
                                  or  UDim2.new(0, 2, 0.5, -knobSize/2),
            BackgroundColor3 = v and self._theme.Accent or self._theme.TextDim,
        }, 0.15)
        self._anims:Tween(track, {
            BackgroundColor3 = v and Darken(self._theme.Accent, 0.35) or self._theme.Border,
        }, 0.15)
        if callback then task.spawn(callback, state) end
    end
    setToggle(state)

    local clickBtn = Make("TextButton", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=7,
    }, row)
    self._anims:HoverEffect(row, self._theme.ElementHov, self._theme.Element)
    self._anims:PressEffect(clickBtn, row, 2)
    clickBtn.MouseButton1Click:Connect(function() setToggle(not state) end)
    return {Set=setToggle, Get=function() return state end}
end

function Tab:AddSlider(text, min, max, default, callback)
    min, max = min or 0, max or 100
    local val = math.clamp(default or min, min, max)
    local slotH = ELEM_H + 18
    local slot  = self:_slot(slotH)

    Make("Frame", {
        Size             = UDim2.new(1, -SHADOW, 0, slotH),
        Position         = UDim2.new(0, SHADOW, 0, SHADOW),
        BackgroundColor3 = Darken(self._theme.Element, 0.48),
        BorderSizePixel  = 0,
    }, slot)

    local surface = Make("Frame", {
        Size             = UDim2.new(1, -SHADOW, 0, slotH),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self._theme.Element,
        BorderSizePixel  = 0,
        ZIndex           = 3,
    }, slot)

    Make("TextLabel", {
        Size=UDim2.new(1,-44,0,18), Position=UDim2.new(0,8,0,4),
        BackgroundTransparency=1, Text=text,
        TextColor3=self._theme.Text, Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4,
    }, surface)

    local valLbl = Make("TextLabel", {
        Size=UDim2.new(0,40,0,18), Position=UDim2.new(1,-48,0,4),
        BackgroundTransparency=1, Text=tostring(val),
        TextColor3=self._theme.Accent, Font=Enum.Font.GothamMedium, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Right, ZIndex=4,
    }, surface)

    -- Track container with shadow
    local trackH_px = 6
    local trackY    = 26
    local trackShadow = Make("Frame", {
        Size=UDim2.new(1,-8-SHADOW, 0, trackH_px),
        Position=UDim2.new(0, 8+SHADOW, 0, trackY+SHADOW),
        BackgroundColor3=Darken(self._theme.Border, 0.45),
        BorderSizePixel=0, ZIndex=4,
    }, surface)
    local track = Make("Frame", {
        Size=UDim2.new(1,-8-SHADOW, 0, trackH_px),
        Position=UDim2.new(0, 8, 0, trackY),
        BackgroundColor3=self._theme.Border,
        BorderSizePixel=0, ZIndex=5,
        ClipsDescendants=true,
    }, surface)
    local fill = Make("Frame", {
        Size=UDim2.new((val-min)/(max-min),0,1,0),
        BackgroundColor3=self._theme.Accent, BorderSizePixel=0, ZIndex=6,
    }, track)
    -- Square knob on track
    local knobSz = 12
    local knob = Make("Frame", {
        Size=UDim2.new(0,knobSz,0,knobSz),
        Position=UDim2.new((val-min)/(max-min),0,0.5,-knobSz/2),
        AnchorPoint=Vector2.new(0.5,0),
        BackgroundColor3=self._theme.Text,
        BorderSizePixel=0, ZIndex=7,
    }, track)

    local sliding = false
    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
        val = math.floor(min + rel*(max-min)+0.5)
        valLbl.Text = tostring(val)
        fill.Size = UDim2.new(rel,0,1,0)
        knob.Position = UDim2.new(rel,0,0.5,-knobSz/2)
        if callback then task.spawn(callback, val) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true; update(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end
    end)
    return {Get=function() return val end, Set=function(v) update(track.AbsolutePosition.X+((v-min)/(max-min))*track.AbsoluteSize.X) end}
end

function Tab:AddTextbox(placeholder, callback)
    local slot = self:_slot(ELEM_H)
    Make("Frame", {
        Size=UDim2.new(1,-SHADOW,0,ELEM_H), Position=UDim2.new(0,SHADOW,0,SHADOW),
        BackgroundColor3=Darken(self._theme.Element,0.48), BorderSizePixel=0,
    }, slot)
    local box = Make("TextBox", {
        Size=UDim2.new(1,-SHADOW,0,ELEM_H), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=self._theme.Element,
        BorderSizePixel=0,
        Text="", PlaceholderText=placeholder or "Type here...",
        TextColor3=self._theme.Text, PlaceholderColor3=self._theme.TextDim,
        Font=Enum.Font.Gotham, TextSize=13,
        ClearTextOnFocus=false, ZIndex=3,
    }, slot)
    Make("UIPadding",{PaddingLeft=UDim.new(0,8)}, box)
    self._anims:HoverEffect(box, self._theme.ElementHov, self._theme.Element)
    box.Focused:Connect(function()
        self._anims:Tween(box, {BackgroundColor3 = self._theme.ElementHov}, 0.12)
    end)
    box.FocusLost:Connect(function(enter)
        self._anims:Tween(box, {BackgroundColor3 = self._theme.Element}, 0.12)
        if callback then task.spawn(callback, box.Text, enter) end
    end)
    return box
end

function Tab:AddDropdown(text, options, default, callback)
    local selected = default or options[1]
    local open     = false
    local ITEM_H   = 28
    local slotH    = ELEM_H

    local slot = self:_slot(slotH)
    slot.ClipsDescendants = false  -- we need the dropdown to overflow

    Make("Frame", {
        Size=UDim2.new(1,-SHADOW,0,ELEM_H), Position=UDim2.new(0,SHADOW,0,SHADOW),
        BackgroundColor3=Darken(self._theme.Element,0.48), BorderSizePixel=0,
    }, slot)

    local main = Make("TextButton", {
        Size=UDim2.new(1,-SHADOW,0,ELEM_H), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=self._theme.Element, BorderSizePixel=0,
        Text="", AutoButtonColor=false, ZIndex=3,
    }, slot)

    local lbl = Make("TextLabel", {
        Size=UDim2.new(1,-26,1,0), Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1,
        Text=text..": "..tostring(selected),
        TextColor3=self._theme.Text, Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4,
    }, main)

    local arrow = Make("TextLabel", {
        Size=UDim2.new(0,16,0,16), Position=UDim2.new(1,-20,0.5,-8),
        BackgroundTransparency=1, Text="v",
        TextColor3=self._theme.TextDim, Font=Enum.Font.GothamBold, TextSize=11, ZIndex=4,
    }, main)

    -- Dropdown list (square shadow box)
    local listH = #options * ITEM_H + SHADOW
    local dropWrap = Make("Frame", {
        Size=UDim2.new(1,-SHADOW,0,listH),
        Position=UDim2.new(0,0,0,ELEM_H+2),
        BackgroundTransparency=1, BorderSizePixel=0,
        ClipsDescendants=true, Visible=false, ZIndex=10,
    }, slot)
    Make("Frame", {
        Size=UDim2.new(1,-SHADOW,1,-SHADOW), Position=UDim2.new(0,SHADOW,0,SHADOW),
        BackgroundColor3=Darken(self._theme.Element,0.45), BorderSizePixel=0, ZIndex=10,
    }, dropWrap)
    local list = Make("Frame", {
        Size=UDim2.new(1,-SHADOW,1,-SHADOW), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=self._theme.Border, BorderSizePixel=0, ZIndex=11,
    }, dropWrap)
    Make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder}, list)

    for _, opt in ipairs(options) do
        local ob = Make("TextButton", {
            Size=UDim2.new(1,0,0,ITEM_H),
            BackgroundColor3=self._theme.Element,
            Text=tostring(opt), TextColor3=self._theme.TextDim,
            Font=Enum.Font.Gotham, TextSize=12,
            AutoButtonColor=false, BorderSizePixel=0, ZIndex=12,
        }, list)
        Animations:HoverEffect(ob, self._theme.ElementHov, self._theme.Element)
        ob.MouseButton1Click:Connect(function()
            selected=opt; lbl.Text=text..": "..tostring(opt)
            if callback then task.spawn(callback,opt) end
            open=false; dropWrap.Visible=false
            Animations:Tween(arrow,{Rotation=0},0.12)
        end)
    end

    Animations:HoverEffect(main, self._theme.ElementHov, self._theme.Element)
    Animations:PressEffect(main, main, 2)
    main.MouseButton1Click:Connect(function()
        open = not open
        dropWrap.Visible = open
        Animations:Tween(arrow,{Rotation=open and 180 or 0},0.12)
    end)
    return {Get=function() return selected end}
end

-- =============================================================================
--  WINDOW OBJECT
-- =============================================================================
local Window = {}
Window.__index = Window

function Window:_build()
    local T = self._theme  -- shorthand

    -- ScreenGui
    local sg = Make("ScreenGui", {
        Name           = self.Title.."_GUI",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    local ok2 = pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not ok2 then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- ---- Outer window --------------------------------------------------------
    local win = Make("Frame", {
        Name             = "Window",
        Size             = self.Size,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = T.Window,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Visible          = false,
    }, sg)

    -- 1px accent border on all sides (rendered as 4 thin frames)
    local function Border(s,p) Make("Frame",{Size=s,Position=p,BackgroundColor3=T.TopbarAccent,BorderSizePixel=0,ZIndex=20},win) end
    Border(UDim2.new(1,0,0,1), UDim2.new(0,0,0,0))              -- top
    Border(UDim2.new(1,0,0,1), UDim2.new(0,0,1,-1))             -- bottom
    Border(UDim2.new(0,1,1,0), UDim2.new(0,0,0,0))              -- left
    Border(UDim2.new(0,1,1,0), UDim2.new(1,-1,0,0))             -- right

    self._sg  = sg
    self._win = win

    -- ---- Topbar --------------------------------------------------------------
    local topbar = Make("Frame", {
        Name             = "Topbar",
        Size             = UDim2.new(1, 0, 0, TOPBAR_H),
        BackgroundColor3 = T.Topbar,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, win)
    -- Accent underline on topbar
    Make("Frame", {
        Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2),
        BackgroundColor3=T.TopbarAccent, BorderSizePixel=0, ZIndex=3,
    }, topbar)

    -- Title label
    Make("TextLabel", {
        Size=UDim2.new(1,-90,1,0), Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1,
        Text=self.Title, TextColor3=T.Text,
        Font=Enum.Font.GothamBold, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3,
    }, topbar)

    -- Close button [x] -- square shadow button
    local closeSz = UDim2.new(0, 26+SHADOW, 0, 20+SHADOW)
    local closePos = UDim2.new(1, -(26+SHADOW+4), 0.5, -(20+SHADOW)/2)
    local _, closeBtn = MakeShadowButton(topbar,
        Color3.fromRGB(185,55,55), closeSz, closePos,
        "X", Color3.fromRGB(255,255,255), Enum.Font.GothamBold, 11)
    closeBtn.ZIndex = 4
    Animations:HoverEffect(closeBtn, Color3.fromRGB(220,70,70), Color3.fromRGB(185,55,55))
    Animations:PressEffect(closeBtn, closeBtn, 2)
    closeBtn.MouseButton1Click:Connect(function() self:Close() end)

    -- Minimize button [-]
    local minSz  = UDim2.new(0, 26+SHADOW, 0, 20+SHADOW)
    local minPos = UDim2.new(1, -(26+SHADOW+4)-(26+SHADOW+4), 0.5, -(20+SHADOW)/2)
    local _, minBtn = MakeShadowButton(topbar,
        Color3.fromRGB(185,140,30), minSz, minPos,
        "-", Color3.fromRGB(255,255,255), Enum.Font.GothamBold, 14)
    minBtn.ZIndex = 4
    Animations:HoverEffect(minBtn, Color3.fromRGB(215,165,45), Color3.fromRGB(185,140,30))
    Animations:PressEffect(minBtn, minBtn, 2)
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Animations:Tween(win, {
            Size = minimized
                and UDim2.new(0, self.Size.X.Offset, 0, TOPBAR_H+2)
                or  self.Size
        }, 0.20)
    end)

    MakeDraggable(win, topbar)

    -- ---- Sidebar -------------------------------------------------------------
    local sidebarX = 1   -- offset from left border
    local sidebar = Make("Frame", {
        Name             = "Sidebar",
        Size             = UDim2.new(0, SIDEBAR_W, 1, -(TOPBAR_H + BOTTOMBAR_H)),
        Position         = UDim2.new(0, sidebarX, 0, TOPBAR_H),
        BackgroundColor3 = T.Sidebar,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        ZIndex           = 2,
    }, win)
    Make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, TAB_GAP),
    }, sidebar)
    Make("UIPadding", {
        PaddingTop   = UDim.new(0, 6),
        PaddingLeft  = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
    }, sidebar)

    -- 1px divider between sidebar and content
    Make("Frame", {
        Size=UDim2.new(0,1,1,-(TOPBAR_H+BOTTOMBAR_H)),
        Position=UDim2.new(0,sidebarX+SIDEBAR_W,0,TOPBAR_H),
        BackgroundColor3=T.Border, BorderSizePixel=0, ZIndex=2,
    }, win)

    -- ---- Content area --------------------------------------------------------
    local contentX = sidebarX + SIDEBAR_W + 1
    local contentHolder = Make("Frame", {
        Name             = "ContentHolder",
        Size             = UDim2.new(1, -(contentX+1), 1, -(TOPBAR_H+BOTTOMBAR_H)),
        Position         = UDim2.new(0, contentX, 0, TOPBAR_H),
        BackgroundColor3 = T.Content,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        ZIndex           = 2,
    }, win)

    -- ---- Bottom bar ----------------------------------------------------------
    local bottomBar = Make("Frame", {
        Name             = "BottomBar",
        Size             = UDim2.new(1, 0, 0, BOTTOMBAR_H),
        Position         = UDim2.new(0, 0, 1, -BOTTOMBAR_H),
        BackgroundColor3 = T.BottomBar,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, win)
    Make("Frame", {
        Size=UDim2.new(1,0,0,1), BackgroundColor3=T.Border, BorderSizePixel=0, ZIndex=3,
    }, bottomBar)

    local btnW = 72
    local function BottomBtn(text, xOff, cb)
        local btnSz = UDim2.new(0, btnW, 0, 20 + SHADOW)
        local btnPos = UDim2.new(1, xOff, 0.5, -(20 + SHADOW)/2)
        local _, btn = MakeShadowButton(bottomBar, T.BottomBtn, btnSz, btnPos, text, T.TextDim, Enum.Font.Gotham, 11)
        btn.ZIndex = 4
        Animations:HoverEffect(btn, T.BottomBtnHov, T.BottomBtn)
        Animations:PressEffect(btn, btn, 2)
        if cb then
            btn.MouseButton1Click:Connect(function()
                task.spawn(cb)
            end)
        end
        return btn
    end

    -- 3 bottom buttons (right-aligned)
    BottomBtn("Themes",   -(btnW*3 + 12), function() self:_openOverlay("Themes") end)
    BottomBtn("Keybinds", -(btnW*2 + 8),  function() self:_openOverlay("Keybinds") end)
    BottomBtn("Settings", -(btnW*1 + 4),  function() self:_openOverlay("Settings") end)

    self._sidebar       = sidebar
    self._contentHolder = contentHolder
    self._bottomBar     = bottomBar
    self._tabs          = {}
    self._activeTab     = nil

    -- ---- Overlay panel -------------------------------------------------------
    self._overlay = Make("Frame", {
        Size=UDim2.new(1,-contentX-1,1,-(TOPBAR_H+BOTTOMBAR_H)),
        Position=UDim2.new(0,contentX,0,TOPBAR_H),
        BackgroundColor3=T.Topbar,
        BorderSizePixel=0, Visible=false, ZIndex=15,
    }, win)
    Make("Frame", {
        Size=UDim2.new(1,0,0,1), BackgroundColor3=T.Border, BorderSizePixel=0, ZIndex=16,
    }, self._overlay)

    -- Overlay close button [x]
    local ovCloseW = UDim2.new(0, 22+SHADOW, 0, 16+SHADOW)
    local ovCloseP = UDim2.new(1, -(22+SHADOW+6), 0, 6)
    local _, ovClose = MakeShadowButton(self._overlay,
        Color3.fromRGB(185,55,55), ovCloseW, ovCloseP,
        "X", Color3.fromRGB(255,255,255), Enum.Font.GothamBold, 10)
    ovClose.ZIndex = 17
    Animations:HoverEffect(ovClose, Color3.fromRGB(220,70,70), Color3.fromRGB(185,55,55))
    Animations:PressEffect(ovClose, ovClose, 2)
    ovClose.MouseButton1Click:Connect(function() Animations:SlideOutRight(self._overlay, 0.15) end)

    self._overlayTitle = Make("TextLabel", {
        Size=UDim2.new(1,-50,0,28), Position=UDim2.new(0,10,0,4),
        BackgroundTransparency=1, Text="",
        TextColor3=T.Text, Font=Enum.Font.GothamBold, TextSize=14,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=16,
    }, self._overlay)

    self._overlayScroll = Make("ScrollingFrame", {
        Size=UDim2.new(1,-8,1,-36), Position=UDim2.new(0,4,0,34),
        BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=T.ScrollBar,
        AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0),
        ZIndex=16,
    }, self._overlay)
    Make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,SHADOW+3)},self._overlayScroll)
    Make("UIPadding",{PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6),PaddingTop=UDim.new(0,6)},self._overlayScroll)
end

-- ---- Overlay helpers --------------------------------------------------------
function Window:_clearOverlay()
    for _, c in ipairs(self._overlayScroll:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
end

function Window:_openOverlay(mode)
    self:_clearOverlay()
    local T = self._theme

    if mode == "Themes" then
        self._overlayTitle.Text = "-- Themes"
        local names = {}
        for k in pairs(Themes) do table.insert(names,k) end
        table.sort(names)
        for _, name in ipairs(names) do
            local slotH = 30
            local slot = Make("Frame",{Size=UDim2.new(1,0,0,slotH+SHADOW),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,ZIndex=17},self._overlayScroll)
            Make("Frame",{Size=UDim2.new(1,-SHADOW,0,slotH),Position=UDim2.new(0,SHADOW,0,SHADOW),BackgroundColor3=Darken(T.Element,0.48),BorderSizePixel=0,ZIndex=17},slot)
            local btn=Make("TextButton",{Size=UDim2.new(1,-SHADOW,0,slotH),Position=UDim2.new(0,0,0,0),BackgroundColor3=T.Element,Text=name,TextColor3=T.Text,Font=Enum.Font.GothamMedium,TextSize=12,AutoButtonColor=false,BorderSizePixel=0,ZIndex=18},slot)
            Animations:HoverEffect(btn, T.ElementHov, T.Element)
            Animations:PressEffect(btn, btn, 2)
            btn.MouseButton1Click:Connect(function() self:ApplyTheme(name); Animations:SlideOutRight(self._overlay, 0.15) end)
        end

    elseif mode == "Keybinds" then
        self._overlayTitle.Text = "-- Keybinds"
        Make("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text="Toggle: "..tostring(self.Keybind),TextColor3=T.TextDim,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},self._overlayScroll)
        for name, bind in pairs(KeybindSystem._binds) do
            Make("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=">> "..name.." -> "..tostring(bind.Key),TextColor3=T.Text,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},self._overlayScroll)
        end

    elseif mode == "Settings" then
        self._overlayTitle.Text = "-- Settings"
        Make("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text="Version: 1.0   Modules: "..tostring(#self._externalModules),TextColor3=T.TextDim,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},self._overlayScroll)
    end

    self._overlay.Visible = false
    Animations:SlideInRight(self._overlay, 0.20)
end

function Window:_selectTab(tab)
    for _, t in ipairs(self._tabs) do
        t:_select(t == tab, self._theme)
    end
    self._activeTab = tab
end

-- ---- Public API -------------------------------------------------------------
function Window:AddTab(name, icon)
    local tab = setmetatable({Name=name, Icon=icon or "", _window=self}, Tab)
    tab:_build(self._sidebar, self._contentHolder, self._theme, Animations)
    table.insert(self._tabs, tab)
    if #self._tabs == 1 then self:_selectTab(tab) end
    return tab
end

function Window:ApplyTheme(name)
    local t = Themes[name]
    if not t then warn("Theme '"..name.."' not found.") return end
    self._theme = t
    Animations:Tween(self._win,      {BackgroundColor3=t.Window})
    Animations:Tween(self._sidebar,  {BackgroundColor3=t.Sidebar})
    Animations:Tween(self._contentHolder, {BackgroundColor3=t.Content})
    Animations:Tween(self._bottomBar,{BackgroundColor3=t.BottomBar})
end

function Window:SetKeybind(key)
    self.Keybind = key
    KeybindSystem:Bind(self.Title.."_Toggle", key, function() self:Toggle() end)
end

function Window:Open()
    Animations:OpenWindow(self._win, self.Size)
end

function Window:Close()
    Animations:CloseWindow(self._win)
end

function Window:Toggle()
    if self._win.Visible then self:Close() else self:Open() end
end

function Window:Destroy()
    self._sg:Destroy()
end

function Window:LoadModule(url, ...)
    local ok3, result = pcall(function(...)
        return loadstring(game:HttpGet(url))(self, Animations, Themes, ...)
    end, ...)
    if not ok3 then
        warn("[GUI] Module load failed: "..url.."\n"..tostring(result))
        return nil
    end
    table.insert(self._externalModules, {url=url, module=result})
    return result
end

-- =============================================================================
--  PUBLIC FACTORY
-- =============================================================================
local GuiHandler = {}
GuiHandler.__index = GuiHandler

function GuiHandler:CreateWindow(opts)
    opts = opts or {}
    local win = setmetatable({
        Title            = opts.Title   or "GUI",
        Size             = opts.Size    or UDim2.new(0, 600, 0, 420),
        Keybind          = opts.Keybind or Enum.KeyCode.RightShift,
        _theme           = Themes[opts.Theme or "Dark"],
        _externalModules = {},
    }, Window)
    win:_build()
    win:SetKeybind(win.Keybind)
    return win
end

GuiHandler.Themes     = Themes
GuiHandler.Keybinds   = KeybindSystem
GuiHandler.Animations = Animations

return GuiHandler
