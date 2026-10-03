--[[
    =====================================================
         GUI HANDLING MODULE v1.0
         loadstring(game:HttpGet(URL))()
    =====================================================

    Design:
      * Layouts separated cleanly by distinct color values (no 1px barrier divider lines)
      * Topbar, Bottombar, Tab bar (sidebar), and all UI elements have solid bottom shadow lips
      * Selecting a tab highlights it white with dark text and updates the top-left title to the current tab
      * Tactile 2px downward button press animation compressing into bottom lip
      * Smooth symmetrical window open/close and tab transitions
]]

-- =============================================================================
--  SERVICES
-- =============================================================================
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- =============================================================================
--  ANIMATIONS DEPENDENCY
-- =============================================================================
local ANIM_URL = "https://raw.githubusercontent.com/FISHYSHUN/NewRepository/main/Animations.lua"
local Animations
local _ok, _ = pcall(function()
    Animations = loadstring(game:HttpGet(ANIM_URL))()
end)
if not _ok then
    Animations = {}
    local function I(d,s,dir) return TweenInfo.new(d or 0.15, s or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out) end
    function Animations:Tween(inst, props, dur, s, dir)
        local t = TweenService:Create(inst, I(dur, s, dir), props)
        t:Play()
        return t
    end
    function Animations:HoverEnter(inst, hC, dur) return self:Tween(inst, {BackgroundColor3 = hC}, dur or 0.12) end
    function Animations:HoverLeave(inst, nC, dur) return self:Tween(inst, {BackgroundColor3 = nC}, dur or 0.12) end
    function Animations:HoverEffect(inst, hC, nC, dur)
        nC = nC or inst.BackgroundColor3
        inst.MouseEnter:Connect(function() self:Tween(inst, {BackgroundColor3 = hC}, dur or 0.12) end)
        inst.MouseLeave:Connect(function() self:Tween(inst, {BackgroundColor3 = nC}, dur or 0.12) end)
    end
    function Animations:Press(surf, off)
        off = off or 2
        local c = surf.Position
        return self:Tween(surf, {Position = UDim2.new(c.X.Scale, c.X.Offset, 0, off)}, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end
    function Animations:Release(surf)
        local c = surf.Position
        return self:Tween(surf, {Position = UDim2.new(c.X.Scale, c.X.Offset, 0, 0)}, 0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end
    function Animations:PressEffect(trig, surf, off)
        surf = surf or trig
        off  = off  or 2
        trig.MouseButton1Down:Connect(function() self:Press(surf, off) end)
        trig.MouseButton1Up:Connect(function() self:Release(surf) end)
        trig.MouseLeave:Connect(function() self:Release(surf) end)
    end
    function Animations:SwitchTab(o, n, d)
        if o and o ~= n then o.Visible = false end
        if n then
            n.Position = UDim2.new(0, 0, 0, 8)
            n.Visible = true
            self:Tween(n, {Position = UDim2.new(0, 0, 0, 0)}, d or 0.16)
        end
    end
    function Animations:OpenWindow(f, tSz, d)
        d = d or 0.22
        local sSz = UDim2.new(tSz.X.Scale, tSz.X.Offset - 24, tSz.Y.Scale, tSz.Y.Offset - 24)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position    = UDim2.new(0.5, 0, 0.5, 14)
        f.Size        = sSz
        f.Visible     = true
        return self:Tween(f, {Position = UDim2.new(0.5, 0, 0.5, 0), Size = tSz}, d)
    end
    function Animations:CloseWindow(f, d, cb)
        d = d or 0.16
        local cSz = f.Size
        local tSz = UDim2.new(cSz.X.Scale, cSz.X.Offset - 24, cSz.Y.Scale, cSz.Y.Offset - 24)
        local t = self:Tween(f, {Position = UDim2.new(0.5, 0, 0.5, 14), Size = tSz}, d, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        t.Completed:Connect(function()
            f.Visible  = false
            f.Position = UDim2.new(0.5, 0, 0.5, 0)
            f.Size     = cSz
            if cb then cb() end
        end)
        return t
    end
    function Animations:SlideInRight(f, d)
        local o = f.Position
        f.Position = UDim2.new(o.X.Scale, o.X.Offset + f.AbsoluteSize.X + 8, o.Y.Scale, o.Y.Offset)
        f.Visible = true
        return self:Tween(f, {Position = o}, d or 0.16)
    end
    function Animations:SlideOutRight(f, d, cb)
        local o = f.Position
        local t = self:Tween(f, {Position = UDim2.new(o.X.Scale, o.X.Offset + f.AbsoluteSize.X + 8, o.Y.Scale, o.Y.Offset)}, d or 0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        t.Completed:Connect(function()
            f.Visible = false
            f.Position = o
            if cb then cb() end
        end)
        return t
    end
end

-- =============================================================================
--  THEME ENGINE (Separated by Distinct Color Values, No 1px Barrier Lines)
-- =============================================================================
local Themes = {
    Dark = {
        Window       = Color3.fromRGB(24,  24,  30),
        WindowLip    = Color3.fromRGB(14,  14,  18),
        Topbar       = Color3.fromRGB(30,  30,  38),
        TopbarLip    = Color3.fromRGB(18,  18,  24),
        Sidebar      = Color3.fromRGB(35,  35,  44),
        SidebarLip   = Color3.fromRGB(20,  20,  26),
        Content      = Color3.fromRGB(42,  42,  52),
        BottomBar    = Color3.fromRGB(28,  28,  36),
        BottomLip    = Color3.fromRGB(16,  16,  22),
        TabNormal    = Color3.fromRGB(48,  48,  60),
        TabLip       = Color3.fromRGB(30,  30,  38),
        TabHover     = Color3.fromRGB(60,  60,  74),
        BottomBtn    = Color3.fromRGB(44,  44,  56),
        BottomBtnLip = Color3.fromRGB(26,  26,  34),
        BottomBtnHov = Color3.fromRGB(58,  58,  72),
        Text         = Color3.fromRGB(230, 230, 240),
        TextDim      = Color3.fromRGB(140, 140, 155),
        Accent       = Color3.fromRGB(100, 180, 240),
        ScrollBar    = Color3.fromRGB(65,  65,  80),
        Element      = Color3.fromRGB(52,  52,  64),
        ElementLip   = Color3.fromRGB(32,  32,  40),
        ElementHov   = Color3.fromRGB(66,  66,  82),
    },
    Light = {
        Window       = Color3.fromRGB(224, 225, 235),
        WindowLip    = Color3.fromRGB(185, 186, 198),
        Topbar       = Color3.fromRGB(216, 218, 228),
        TopbarLip    = Color3.fromRGB(178, 180, 192),
        Sidebar      = Color3.fromRGB(226, 228, 238),
        SidebarLip   = Color3.fromRGB(186, 188, 200),
        Content      = Color3.fromRGB(242, 243, 250),
        BottomBar    = Color3.fromRGB(216, 218, 228),
        BottomLip    = Color3.fromRGB(178, 180, 192),
        TabNormal    = Color3.fromRGB(205, 207, 218),
        TabLip       = Color3.fromRGB(170, 172, 184),
        TabHover     = Color3.fromRGB(192, 195, 208),
        BottomBtn    = Color3.fromRGB(202, 204, 216),
        BottomBtnLip = Color3.fromRGB(168, 170, 182),
        BottomBtnHov = Color3.fromRGB(185, 188, 202),
        Text         = Color3.fromRGB(30,  30,  42),
        TextDim      = Color3.fromRGB(110, 110, 130),
        Accent       = Color3.fromRGB(60,  120, 210),
        ScrollBar    = Color3.fromRGB(165, 167, 180),
        Element      = Color3.fromRGB(218, 220, 230),
        ElementLip   = Color3.fromRGB(180, 182, 194),
        ElementHov   = Color3.fromRGB(200, 202, 214),
    },
    Midnight = {
        Window       = Color3.fromRGB(10,  10,  15),
        WindowLip    = Color3.fromRGB(5,   5,   8),
        Topbar       = Color3.fromRGB(13,  12,  20),
        TopbarLip    = Color3.fromRGB(7,   6,   11),
        Sidebar      = Color3.fromRGB(17,  16,  26),
        SidebarLip   = Color3.fromRGB(9,   8,   14),
        Content      = Color3.fromRGB(22,  21,  33),
        BottomBar    = Color3.fromRGB(13,  12,  20),
        BottomLip    = Color3.fromRGB(7,   6,   11),
        TabNormal    = Color3.fromRGB(26,  24,  38),
        TabLip       = Color3.fromRGB(14,  13,  22),
        TabHover     = Color3.fromRGB(38,  34,  56),
        BottomBtn    = Color3.fromRGB(26,  24,  40),
        BottomBtnLip = Color3.fromRGB(14,  12,  23),
        BottomBtnHov = Color3.fromRGB(40,  36,  62),
        Text         = Color3.fromRGB(210, 195, 255),
        TextDim      = Color3.fromRGB(120, 110, 165),
        Accent       = Color3.fromRGB(140, 75,  245),
        ScrollBar    = Color3.fromRGB(55,  46,  90),
        Element      = Color3.fromRGB(28,  26,  42),
        ElementLip   = Color3.fromRGB(15,  14,  24),
        ElementHov   = Color3.fromRGB(42,  38,  62),
    },
}

-- =============================================================================
--  CONSTANTS & SIZES
-- =============================================================================
local LIP_H       = 3    -- bottom shadow lip height in pixels
local SIDEBAR_W   = 94   -- sidebar width
local TOPBAR_H    = 34   -- topbar height
local BOTTOMBAR_H = 30   -- bottom bar height
local TAB_H       = 32   -- sidebar tab height
local TAB_GAP     = 5    -- gap between tabs
local ELEM_H      = 34   -- standard content element height

-- =============================================================================
--  UTILITY
-- =============================================================================
local function Make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function Darken(c, factor)
    factor = factor or 0.60
    return Color3.fromRGB(
        math.clamp(math.floor(c.R * 255 * factor), 0, 255),
        math.clamp(math.floor(c.G * 255 * factor), 0, 255),
        math.clamp(math.floor(c.B * 255 * factor), 0, 255)
    )
end

--[[
    MakeBezelBox
    Container with a full-width bottom shadow lip.
]]
local function MakeBezelBox(parent, size, pos, mainColor, lipColor)
    lipColor = lipColor or Darken(mainColor, 0.60)

    local container = Make("Frame", {
        Size             = size,
        Position         = pos or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, parent)

    local lip = Make("Frame", {
        Name             = "ShadowLip",
        Size             = UDim2.new(1, 0, 0, LIP_H),
        Position         = UDim2.new(0, 0, 1, -LIP_H),
        BackgroundColor3 = lipColor,
        BorderSizePixel  = 0,
        ZIndex           = container.ZIndex + 1,
    }, container)

    local body = Make("Frame", {
        Name             = "Body",
        Size             = UDim2.new(1, 0, 1, -LIP_H),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = mainColor,
        BorderSizePixel  = 0,
        ZIndex           = container.ZIndex + 2,
    }, container)

    return container, body, lip
end

--[[
    MakeBezelButton
    Clickable button with bottom shadow lip and tactile 2px downward press animation.
]]
local function MakeBezelButton(parent, size, pos, mainColor, lipColor, hoverColor, text, textColor, font, textSize)
    lipColor   = lipColor   or Darken(mainColor, 0.60)
    hoverColor = hoverColor or Color3.fromRGB(
        math.clamp(math.floor(mainColor.R * 255 * 1.2), 0, 255),
        math.clamp(math.floor(mainColor.G * 255 * 1.2), 0, 255),
        math.clamp(math.floor(mainColor.B * 255 * 1.2), 0, 255)
    )

    local container = Make("Frame", {
        Size             = size,
        Position         = pos or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, parent)

    local lip = Make("Frame", {
        Name             = "ShadowLip",
        Size             = UDim2.new(1, 0, 0, LIP_H),
        Position         = UDim2.new(0, 0, 1, -LIP_H),
        BackgroundColor3 = lipColor,
        BorderSizePixel  = 0,
        ZIndex           = container.ZIndex + 1,
    }, container)

    local btn = Make("TextButton", {
        Name             = "Button",
        Size             = UDim2.new(1, 0, 1, -LIP_H),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = mainColor,
        BorderSizePixel  = 0,
        Text             = text or "",
        TextColor3       = textColor or Color3.fromRGB(215, 215, 225),
        Font             = font or Enum.Font.GothamMedium,
        TextSize         = textSize or 12,
        AutoButtonColor  = false,
        ZIndex           = container.ZIndex + 2,
    }, container)

    Animations:HoverEffect(btn, hoverColor, mainColor)
    Animations:PressEffect(btn, btn, 2)

    return container, btn, lip
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = i.Position
            startPos  = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- =============================================================================
--  KEYBIND SYSTEM
-- =============================================================================
local KeybindSystem = {}
KeybindSystem._binds = {}

function KeybindSystem:Bind(name, key, cb)
    self._binds[name] = {Key = key, Callback = cb}
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

function Tab:_build(sidebarScroll, contentHolder, theme, anims)
    self._theme   = theme
    self._anims   = anims

    local slotSize = UDim2.new(1, 0, 0, TAB_H)
    local _, btn, lip = MakeBezelButton(
        sidebarScroll,
        slotSize,
        nil,
        theme.TabNormal,
        theme.TabLip,
        theme.TabHover,
        self.Name,
        theme.TextDim,
        Enum.Font.GothamMedium,
        12
    )

    self._btn = btn
    self._lip = lip

    -- Hover behavior respecting active selection
    btn.MouseEnter:Connect(function()
        if not self._selected then
            anims:Tween(btn, {BackgroundColor3 = self._theme.TabHover}, 0.12)
        end
    end)
    btn.MouseLeave:Connect(function()
        if not self._selected then
            anims:Tween(btn, {BackgroundColor3 = self._theme.TabNormal}, 0.12)
        end
    end)

    btn.MouseButton1Click:Connect(function()
        if self._window then self._window:_selectTab(self) end
    end)

    -- Tab content ScrollingFrame
    self._frame = Make("ScrollingFrame", {
        Name                 = "Content_"..self.Name,
        Size                 = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        ScrollBarThickness   = 3,
        ScrollBarImageColor3 = theme.ScrollBar,
        Visible              = false,
        AutomaticCanvasSize  = Enum.AutomaticSize.Y,
        CanvasSize           = UDim2.new(0, 0, 0, 0),
        ZIndex               = 3,
    }, contentHolder)

    Make("UIPadding", {
        PaddingTop    = UDim.new(0, 10),
        PaddingLeft   = UDim.new(0, 10),
        PaddingRight  = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
    }, self._frame)

    Make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 6),
    }, self._frame)
end

function Tab:_select(state, theme)
    self._selected = state
    if state then
        -- Highlight solid white with readable dark text and soft light shadow lip
        self._anims:Tween(self._btn, {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            TextColor3       = Color3.fromRGB(20, 20, 26),
        }, 0.14)
        self._anims:Tween(self._lip, {
            BackgroundColor3 = Color3.fromRGB(195, 195, 205),
        }, 0.14)
    else
        self._anims:Tween(self._btn, {
            BackgroundColor3 = theme.TabNormal,
            TextColor3       = theme.TextDim,
        }, 0.12)
        self._anims:Tween(self._lip, {
            BackgroundColor3 = theme.TabLip,
        }, 0.12)
    end
end

-- =============================================================================
--  TAB CONTENT ELEMENT BUILDERS
-- =============================================================================
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
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
    }, self._frame)
    Make("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self._theme.ElementHov,
        BorderSizePixel  = 0,
    }, sep)
    Make("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 0, 1),
        BackgroundColor3 = self._theme.ElementLip,
        BorderSizePixel  = 0,
    }, sep)
    return sep
end

function Tab:AddButton(text, callback)
    local _, btn, _ = MakeBezelButton(
        self._frame,
        UDim2.new(1, 0, 0, ELEM_H),
        nil,
        self._theme.Element,
        self._theme.ElementLip,
        self._theme.ElementHov,
        text,
        self._theme.Text,
        Enum.Font.GothamMedium,
        13
    )

    btn.MouseButton1Click:Connect(function()
        if callback then task.spawn(callback) end
    end)
    return btn
end

function Tab:AddToggle(text, default, callback)
    local state = default or false

    local _, row, _ = MakeBezelBox(
        self._frame,
        UDim2.new(1, 0, 0, ELEM_H),
        nil,
        self._theme.Element,
        self._theme.ElementLip
    )

    Make("TextLabel", {
        Size             = UDim2.new(1, -54, 1, 0),
        Position         = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text             = text,
        TextColor3       = self._theme.Text,
        Font             = Enum.Font.Gotham,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = row.ZIndex + 1,
    }, row)

    local trackW, trackH = 34, 16
    local trackContainer, trackBody, _ = MakeBezelBox(
        row,
        UDim2.new(0, trackW, 0, trackH),
        UDim2.new(1, -(trackW + 10), 0.5, -trackH / 2),
        self._theme.TabNormal,
        self._theme.ElementLip
    )
    trackContainer.ZIndex = row.ZIndex + 2
    trackBody.ZIndex      = row.ZIndex + 3

    local knobSz = trackH - LIP_H - 2
    local knob = Make("Frame", {
        Size             = UDim2.new(0, knobSz, 0, knobSz),
        Position         = UDim2.new(0, 1, 0.5, -knobSz / 2),
        BackgroundColor3 = self._theme.TextDim,
        BorderSizePixel  = 0,
        ZIndex           = trackBody.ZIndex + 1,
    }, trackBody)

    local function setToggle(v)
        state = v
        self._anims:Tween(knob, {
            Position         = v and UDim2.new(1, -(knobSz + 1), 0.5, -knobSz / 2)
                                  or  UDim2.new(0, 1, 0.5, -knobSz / 2),
            BackgroundColor3 = v and self._theme.Accent or self._theme.TextDim,
        }, 0.14)
        self._anims:Tween(trackBody, {
            BackgroundColor3 = v and Darken(self._theme.Accent, 0.40) or self._theme.TabNormal,
        }, 0.14)
        if callback then task.spawn(callback, state) end
    end
    setToggle(state)

    local clickBtn = Make("TextButton", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "",
        ZIndex                 = row.ZIndex + 10,
    }, row)

    self._anims:HoverEffect(row, self._theme.ElementHov, self._theme.Element)
    self._anims:PressEffect(clickBtn, row, 2)
    clickBtn.MouseButton1Click:Connect(function() setToggle(not state) end)

    return {Set = setToggle, Get = function() return state end}
end

function Tab:AddSlider(text, min, max, default, callback)
    min, max = min or 0, max or 100
    local val = math.clamp(default or min, min, max)
    local cardH = ELEM_H + 18

    local _, surface, _ = MakeBezelBox(
        self._frame,
        UDim2.new(1, 0, 0, cardH),
        nil,
        self._theme.Element,
        self._theme.ElementLip
    )

    Make("TextLabel", {
        Size             = UDim2.new(1, -50, 0, 18),
        Position         = UDim2.new(0, 10, 0, 4),
        BackgroundTransparency = 1,
        Text             = text,
        TextColor3       = self._theme.Text,
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = surface.ZIndex + 1,
    }, surface)

    local valLbl = Make("TextLabel", {
        Size             = UDim2.new(0, 44, 0, 18),
        Position         = UDim2.new(1, -54, 0, 4),
        BackgroundTransparency = 1,
        Text             = tostring(val),
        TextColor3       = self._theme.Accent,
        Font             = Enum.Font.GothamMedium,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Right,
        ZIndex           = surface.ZIndex + 1,
    }, surface)

    local trackH = 8
    local _, trackBody, _ = MakeBezelBox(
        surface,
        UDim2.new(1, -20, 0, trackH),
        UDim2.new(0, 10, 0, 26),
        self._theme.TabNormal,
        self._theme.ElementLip
    )

    local fill = Make("Frame", {
        Size             = UDim2.new((val - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = self._theme.Accent,
        BorderSizePixel  = 0,
        ZIndex           = trackBody.ZIndex + 1,
    }, trackBody)

    local knobSz = trackH + 4
    local knob = Make("Frame", {
        Size             = UDim2.new(0, knobSz, 0, knobSz),
        Position         = UDim2.new((val - min) / (max - min), 0, 0.5, -knobSz / 2),
        AnchorPoint      = Vector2.new(0.5, 0),
        BackgroundColor3 = self._theme.Text,
        BorderSizePixel  = 0,
        ZIndex           = trackBody.ZIndex + 2,
    }, trackBody)

    local sliding = false
    local function update(x)
        local rel = math.clamp((x - trackBody.AbsolutePosition.X) / trackBody.AbsoluteSize.X, 0, 1)
        val = math.floor(min + rel * (max - min) + 0.5)
        valLbl.Text   = tostring(val)
        fill.Size     = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, -knobSz / 2)
        if callback then task.spawn(callback, val) end
    end

    trackBody.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            update(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)

    return {
        Get = function() return val end,
        Set = function(v)
            update(trackBody.AbsolutePosition.X + ((v - min) / (max - min)) * trackBody.AbsoluteSize.X)
        end
    }
end

function Tab:AddTextbox(placeholder, callback)
    local _, body, _ = MakeBezelBox(
        self._frame,
        UDim2.new(1, 0, 0, ELEM_H),
        nil,
        self._theme.Element,
        self._theme.ElementLip
    )

    local box = Make("TextBox", {
        Size                   = UDim2.new(1, 0, 1, 0),
        Position               = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Text                   = "",
        PlaceholderText        = placeholder or "Type here...",
        TextColor3             = self._theme.Text,
        PlaceholderColor3      = self._theme.TextDim,
        Font                   = Enum.Font.Gotham,
        TextSize               = 13,
        ClearTextOnFocus       = false,
        ZIndex                 = body.ZIndex + 1,
    }, body)
    Make("UIPadding", {PaddingLeft = UDim.new(0, 10)}, box)

    self._anims:HoverEffect(body, self._theme.ElementHov, self._theme.Element)
    box.Focused:Connect(function()
        self._anims:Tween(body, {BackgroundColor3 = self._theme.ElementHov}, 0.12)
    end)
    box.FocusLost:Connect(function(enter)
        self._anims:Tween(body, {BackgroundColor3 = self._theme.Element}, 0.12)
        if callback then task.spawn(callback, box.Text, enter) end
    end)
    return box
end

function Tab:AddDropdown(text, options, default, callback)
    local selected = default or options[1]
    local open     = false
    local ITEM_H   = 28

    local dropWrap = Make("Frame", {
        Size                   = UDim2.new(1, 0, 0, ELEM_H),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ClipsDescendants       = false,
    }, self._frame)

    local _, mainBtn, _ = MakeBezelButton(
        dropWrap,
        UDim2.new(1, 0, 0, ELEM_H),
        UDim2.new(0, 0, 0, 0),
        self._theme.Element,
        self._theme.ElementLip,
        self._theme.ElementHov,
        "",
        self._theme.Text,
        Enum.Font.Gotham,
        12
    )

    local lbl = Make("TextLabel", {
        Size             = UDim2.new(1, -28, 1, 0),
        Position         = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text             = text..": "..tostring(selected),
        TextColor3       = self._theme.Text,
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = mainBtn.ZIndex + 1,
    }, mainBtn)

    local arrow = Make("TextLabel", {
        Size             = UDim2.new(0, 16, 0, 16),
        Position         = UDim2.new(1, -22, 0.5, -8),
        BackgroundTransparency = 1,
        Text             = "v",
        TextColor3       = self._theme.TextDim,
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        ZIndex           = mainBtn.ZIndex + 1,
    }, mainBtn)

    local listH = #options * ITEM_H + LIP_H
    local listContainer, listBody, _ = MakeBezelBox(
        dropWrap,
        UDim2.new(1, 0, 0, listH),
        UDim2.new(0, 0, 0, ELEM_H + 2),
        self._theme.Sidebar,
        self._theme.ElementLip
    )
    listContainer.Visible = false
    listContainer.ZIndex  = 20
    listBody.ZIndex       = 21

    Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, listBody)

    for _, opt in ipairs(options) do
        local ob = Make("TextButton", {
            Size             = UDim2.new(1, 0, 0, ITEM_H),
            BackgroundColor3 = self._theme.Element,
            Text             = tostring(opt),
            TextColor3       = self._theme.TextDim,
            Font             = Enum.Font.Gotham,
            TextSize         = 12,
            AutoButtonColor  = false,
            BorderSizePixel  = 0,
            ZIndex           = 22,
        }, listBody)

        self._anims:HoverEffect(ob, self._theme.ElementHov, self._theme.Element)
        ob.MouseButton1Click:Connect(function()
            selected = opt
            lbl.Text = text..": "..tostring(opt)
            if callback then task.spawn(callback, opt) end
            open = false
            listContainer.Visible = false
            self._anims:Tween(arrow, {Rotation = 0}, 0.12)
        end)
    end

    mainBtn.MouseButton1Click:Connect(function()
        open = not open
        listContainer.Visible = open
        self._anims:Tween(arrow, {Rotation = open and 180 or 0}, 0.12)
    end)

    return {Get = function() return selected end}
end

-- =============================================================================
--  WINDOW OBJECT
-- =============================================================================
local Window = {}
Window.__index = Window

function Window:_build()
    local T = self._theme

    local sg = Make("ScreenGui", {
        Name           = self.Title.."_GUI",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    local ok2 = pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not ok2 then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- ---- Main Window (pure color surfaces, no 1px outline barriers) ----------
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

    -- Window bottom shadow lip
    local winLip = Make("Frame", {
        Name             = "WindowShadowLip",
        Size             = UDim2.new(1, 0, 0, 4),
        Position         = UDim2.new(0, 0, 1, -4),
        BackgroundColor3 = T.WindowLip,
        BorderSizePixel  = 0,
        ZIndex           = 25,
    }, win)

    self._sg     = sg
    self._win    = win
    self._winLip = winLip

    -- ---- Topbar (distinct color value + bottom shadow lip) -------------------
    local topbar = Make("Frame", {
        Name             = "Topbar",
        Size             = UDim2.new(1, 0, 0, TOPBAR_H),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = T.Topbar,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, win)

    -- Topbar bottom shadow lip
    local topbarLip = Make("Frame", {
        Name             = "TopbarLip",
        Size             = UDim2.new(1, 0, 0, LIP_H),
        Position         = UDim2.new(0, 0, 1, -LIP_H),
        BackgroundColor3 = T.TopbarLip,
        BorderSizePixel  = 0,
        ZIndex           = 3,
    }, topbar)

    -- Top-left title label (dynamically updates to current tab)
    local titleLabel = Make("TextLabel", {
        Name             = "TitleLabel",
        Size             = UDim2.new(1, -90, 1, -LIP_H),
        Position         = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text             = self.Title,
        TextColor3       = T.Text,
        Font             = Enum.Font.GothamBold,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 4,
    }, topbar)

    -- Close [X] Button (with bottom lip)
    local _, closeBtn, _ = MakeBezelButton(
        topbar,
        UDim2.new(0, 24, 0, 20),
        UDim2.new(1, -30, 0.5, -10),
        Color3.fromRGB(180, 50, 50),
        Color3.fromRGB(120, 30, 30),
        Color3.fromRGB(215, 65, 65),
        "X",
        Color3.fromRGB(255, 255, 255),
        Enum.Font.GothamBold,
        11
    )
    closeBtn.MouseButton1Click:Connect(function() self:Close() end)

    -- Minimize [-] Button (with bottom lip)
    local _, minBtn, _ = MakeBezelButton(
        topbar,
        UDim2.new(0, 24, 0, 20),
        UDim2.new(1, -58, 0.5, -10),
        Color3.fromRGB(180, 135, 30),
        Color3.fromRGB(120, 90, 20),
        Color3.fromRGB(215, 160, 40),
        "-",
        Color3.fromRGB(255, 255, 255),
        Enum.Font.GothamBold,
        14
    )

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Animations:Tween(win, {
            Size = minimized
                and UDim2.new(0, self.Size.X.Offset, 0, TOPBAR_H)
                or  self.Size
        }, 0.18)
    end)

    MakeDraggable(win, topbar)

    -- ---- Sidebar / Tab Bar (distinct color value + bottom shadow lip) --------
    local sidebar = Make("Frame", {
        Name             = "Sidebar",
        Size             = UDim2.new(0, SIDEBAR_W, 1, -(TOPBAR_H + BOTTOMBAR_H)),
        Position         = UDim2.new(0, 0, 0, TOPBAR_H),
        BackgroundColor3 = T.Sidebar,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        ZIndex           = 2,
    }, win)

    -- Scrolling container for tabs (leaving room for bottom lip)
    local sidebarScroll = Make("ScrollingFrame", {
        Name                 = "TabList",
        Size                 = UDim2.new(1, 0, 1, -LIP_H),
        Position             = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        ScrollBarThickness   = 2,
        ScrollBarImageColor3 = T.ScrollBar,
        AutomaticCanvasSize  = Enum.AutomaticSize.Y,
        CanvasSize           = UDim2.new(0, 0, 0, 0),
        ZIndex               = 3,
    }, sidebar)

    Make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, TAB_GAP),
    }, sidebarScroll)

    Make("UIPadding", {
        PaddingTop    = UDim.new(0, 6),
        PaddingLeft   = UDim.new(0, 6),
        PaddingRight  = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
    }, sidebarScroll)

    -- Bottom of tab bar shadow lip
    local sidebarLip = Make("Frame", {
        Name             = "SidebarShadowLip",
        Size             = UDim2.new(1, 0, 0, LIP_H),
        Position         = UDim2.new(0, 0, 1, -LIP_H),
        BackgroundColor3 = T.SidebarLip,
        BorderSizePixel  = 0,
        ZIndex           = 4,
    }, sidebar)

    -- ---- Content Area (distinct color value, no barrier lines) ---------------
    local contentHolder = Make("Frame", {
        Name             = "ContentHolder",
        Size             = UDim2.new(1, -SIDEBAR_W, 1, -(TOPBAR_H + BOTTOMBAR_H)),
        Position         = UDim2.new(0, SIDEBAR_W, 0, TOPBAR_H),
        BackgroundColor3 = T.Content,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        ZIndex           = 2,
    }, win)

    -- ---- Bottombar (distinct color value + bottom shadow lip) ----------------
    local bottomBar = Make("Frame", {
        Name             = "BottomBar",
        Size             = UDim2.new(1, 0, 0, BOTTOMBAR_H),
        Position         = UDim2.new(0, 0, 1, -BOTTOMBAR_H),
        BackgroundColor3 = T.BottomBar,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, win)

    -- Bottombar shadow lip
    local bottomLip = Make("Frame", {
        Name             = "BottomLip",
        Size             = UDim2.new(1, 0, 0, LIP_H),
        Position         = UDim2.new(0, 0, 1, -LIP_H),
        BackgroundColor3 = T.BottomLip,
        BorderSizePixel  = 0,
        ZIndex           = 3,
    }, bottomBar)

    local btnW = 68
    local function BottomBtn(text, xOff, cb)
        local _, btn, _ = MakeBezelButton(
            bottomBar,
            UDim2.new(0, btnW, 0, 20),
            UDim2.new(1, xOff, 0.5, -10),
            T.BottomBtn,
            T.BottomBtnLip,
            T.BottomBtnHov,
            text,
            T.TextDim,
            Enum.Font.Gotham,
            11
        )
        if cb then
            btn.MouseButton1Click:Connect(function() task.spawn(cb) end)
        end
        return btn
    end

    BottomBtn("Themes",   -(btnW * 3 + 12), function() self:_openOverlay("Themes") end)
    BottomBtn("Keybinds", -(btnW * 2 + 8),  function() self:_openOverlay("Keybinds") end)
    BottomBtn("Settings", -(btnW * 1 + 4),  function() self:_openOverlay("Settings") end)

    self._topbar        = topbar
    self._topbarLip     = topbarLip
    self._titleLabel    = titleLabel
    self._sidebar       = sidebar
    self._sidebarScroll = sidebarScroll
    self._sidebarLip    = sidebarLip
    self._contentHolder = contentHolder
    self._bottomBar     = bottomBar
    self._bottomLip     = bottomLip
    self._tabs          = {}
    self._activeTab     = nil

    -- ---- Overlay Panel (Themes, Keybinds, Settings) --------------------------
    self._overlay = Make("Frame", {
        Size             = UDim2.new(1, -SIDEBAR_W, 1, -(TOPBAR_H + BOTTOMBAR_H)),
        Position         = UDim2.new(0, SIDEBAR_W, 0, TOPBAR_H),
        BackgroundColor3 = T.Topbar,
        BorderSizePixel  = 0,
        Visible          = false,
        ClipsDescendants = true,
        ZIndex           = 15,
    }, win)

    local _, ovClose, _ = MakeBezelButton(
        self._overlay,
        UDim2.new(0, 22, 0, 18),
        UDim2.new(1, -28, 0, 6),
        Color3.fromRGB(180, 50, 50),
        Color3.fromRGB(120, 30, 30),
        Color3.fromRGB(215, 65, 65),
        "X",
        Color3.fromRGB(255, 255, 255),
        Enum.Font.GothamBold,
        10
    )
    ovClose.MouseButton1Click:Connect(function()
        Animations:SlideOutRight(self._overlay, 0.14)
    end)

    self._overlayTitle = Make("TextLabel", {
        Size             = UDim2.new(1, -50, 0, 28),
        Position         = UDim2.new(0, 12, 0, 4),
        BackgroundTransparency = 1,
        Text             = "",
        TextColor3       = T.Text,
        Font             = Enum.Font.GothamBold,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 16,
    }, self._overlay)

    self._overlayScroll = Make("ScrollingFrame", {
        Size                 = UDim2.new(1, -12, 1, -38),
        Position             = UDim2.new(0, 6, 0, 34),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        ScrollBarThickness   = 3,
        ScrollBarImageColor3 = T.ScrollBar,
        AutomaticCanvasSize  = Enum.AutomaticSize.Y,
        CanvasSize           = UDim2.new(0, 0, 0, 0),
        ZIndex               = 16,
    }, self._overlay)

    Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)}, self._overlayScroll)
    Make("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 4)}, self._overlayScroll)
end

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
        for k in pairs(Themes) do table.insert(names, k) end
        table.sort(names)
        for _, name in ipairs(names) do
            local _, btn, _ = MakeBezelButton(
                self._overlayScroll,
                UDim2.new(1, 0, 0, 30),
                nil,
                T.Element,
                T.ElementLip,
                T.ElementHov,
                name,
                T.Text,
                Enum.Font.GothamMedium,
                12
            )
            btn.MouseButton1Click:Connect(function()
                self:ApplyTheme(name)
                Animations:SlideOutRight(self._overlay, 0.14)
            end)
        end

    elseif mode == "Keybinds" then
        self._overlayTitle.Text = "-- Keybinds"
        Make("TextLabel", {
            Size             = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text             = "Toggle Key: "..tostring(self.Keybind),
            TextColor3       = T.TextDim,
            Font             = Enum.Font.Gotham,
            TextSize         = 12,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 17,
        }, self._overlayScroll)
        for name, bind in pairs(KeybindSystem._binds) do
            Make("TextLabel", {
                Size             = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Text             = ">> "..name.." -> "..tostring(bind.Key),
                TextColor3       = T.Text,
                Font             = Enum.Font.Gotham,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 17,
            }, self._overlayScroll)
        end

    elseif mode == "Settings" then
        self._overlayTitle.Text = "-- Settings"
        Make("TextLabel", {
            Size             = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text             = "Version: 1.0   Modules: "..tostring(#self._externalModules),
            TextColor3       = T.TextDim,
            Font             = Enum.Font.Gotham,
            TextSize         = 12,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 17,
        }, self._overlayScroll)
    end

    self._overlay.Visible = false
    Animations:SlideInRight(self._overlay, 0.16)
end

function Window:_selectTab(tab)
    local oldFrame = self._activeTab and self._activeTab._frame or nil
    for _, t in ipairs(self._tabs) do
        t:_select(t == tab, self._theme)
    end
    self._activeTab = tab

    -- Update the top-left title to the current selected tab
    if self._titleLabel then
        self._titleLabel.Text = tab.Name
    end

    Animations:SwitchTab(oldFrame, tab._frame, 0.16)
end

-- =============================================================================
--  PUBLIC WINDOW API
-- =============================================================================
function Window:AddTab(name, icon)
    local tab = setmetatable({Name = name, Icon = icon or "", _window = self}, Tab)
    tab:_build(self._sidebarScroll, self._contentHolder, self._theme, Animations)
    table.insert(self._tabs, tab)
    if #self._tabs == 1 then self:_selectTab(tab) end
    return tab
end

function Window:ApplyTheme(name)
    local t = Themes[name]
    if not t then warn("Theme '"..name.."' not found.") return end
    self._theme = t

    Animations:Tween(self._win,           {BackgroundColor3 = t.Window})
    Animations:Tween(self._winLip,        {BackgroundColor3 = t.WindowLip})
    Animations:Tween(self._topbar,        {BackgroundColor3 = t.Topbar})
    Animations:Tween(self._topbarLip,     {BackgroundColor3 = t.TopbarLip})
    Animations:Tween(self._sidebar,       {BackgroundColor3 = t.Sidebar})
    Animations:Tween(self._sidebarLip,    {BackgroundColor3 = t.SidebarLip})
    Animations:Tween(self._contentHolder, {BackgroundColor3 = t.Content})
    Animations:Tween(self._bottomBar,     {BackgroundColor3 = t.BottomBar})
    Animations:Tween(self._bottomLip,     {BackgroundColor3 = t.BottomLip})

    for _, tab in ipairs(self._tabs) do
        tab:_select(tab == self._activeTab, t)
    end
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
    table.insert(self._externalModules, {url = url, module = result})
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
