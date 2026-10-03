--[[
    =====================================================
         ANIMATIONS MODULE v1.0
         loadstring(game:HttpGet(URL))()
    =====================================================

    Simple, clean transition animations:
      * Hover enter and leave (smooth color transition)
      * Click press and release (tactile downward displacement)
      * Symmetrical window open and close transitions
      * Smooth tab switch transition
      * Overlay slide in and slide out
]]

local TweenService = game:GetService("TweenService")

local Animations = {}
Animations.__index = Animations

-- =============================================================================
--  CONSTANTS & TIMINGS
-- =============================================================================
local T_HOVER = 0.12
local T_PRESS = 0.08
local T_TAB   = 0.16
local T_OPEN  = 0.22
local T_CLOSE = 0.16

local function Info(dur, style, dir)
    return TweenInfo.new(
        dur   or 0.15,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out
    )
end

-- =============================================================================
--  CORE TWEEN
-- =============================================================================
function Animations:Tween(instance, props, duration, style, direction)
    local t = TweenService:Create(instance, Info(duration, style, direction), props)
    t:Play()
    return t
end

-- =============================================================================
--  HOVER ANIMATIONS
-- =============================================================================
function Animations:HoverEnter(instance, hoverColor, duration)
    return self:Tween(instance, {BackgroundColor3 = hoverColor}, duration or T_HOVER)
end

function Animations:HoverLeave(instance, normalColor, duration)
    return self:Tween(instance, {BackgroundColor3 = normalColor}, duration or T_HOVER)
end

function Animations:HoverEffect(instance, hoverColor, normalColor, duration)
    normalColor = normalColor or instance.BackgroundColor3
    duration    = duration    or T_HOVER

    instance.MouseEnter:Connect(function()
        self:Tween(instance, {BackgroundColor3 = hoverColor}, duration)
    end)
    instance.MouseLeave:Connect(function()
        self:Tween(instance, {BackgroundColor3 = normalColor}, duration)
    end)
end

-- =============================================================================
--  TACTILE PRESS / RELEASE (moves straight down into bottom shadow lip)
-- =============================================================================
function Animations:Press(surface, offset)
    offset = offset or 2
    local cur = surface.Position
    return self:Tween(surface, {
        Position = UDim2.new(cur.X.Scale, cur.X.Offset, 0, offset),
    }, T_PRESS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Animations:Release(surface)
    local cur = surface.Position
    return self:Tween(surface, {
        Position = UDim2.new(cur.X.Scale, cur.X.Offset, 0, 0),
    }, T_PRESS + 0.02, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Animations:PressEffect(trigger, surface, offset)
    surface = surface or trigger
    offset  = offset  or 2

    trigger.MouseButton1Down:Connect(function()
        self:Press(surface, offset)
    end)
    trigger.MouseButton1Up:Connect(function()
        self:Release(surface)
    end)
    trigger.MouseLeave:Connect(function()
        self:Release(surface)
    end)
end

-- =============================================================================
--  TAB SWITCH (smooth vertical slide-in)
-- =============================================================================
function Animations:SwitchTab(oldFrame, newFrame, duration)
    duration = duration or T_TAB
    if oldFrame and oldFrame ~= newFrame then
        oldFrame.Visible = false
    end
    if newFrame then
        newFrame.Position = UDim2.new(0, 0, 0, 8)
        newFrame.Visible = true
        self:Tween(newFrame, {Position = UDim2.new(0, 0, 0, 0)}, duration,
            Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end
end

-- =============================================================================
--  WINDOW OPEN / CLOSE (smooth slight scale & slide from center)
-- =============================================================================
function Animations:OpenWindow(frame, targetSize, duration)
    duration = duration or T_OPEN
    local targetPos = UDim2.new(0.5, 0, 0.5, 0)
    local startPos  = UDim2.new(0.5, 0, 0.5, 14)
    local startSize = UDim2.new(
        targetSize.X.Scale, targetSize.X.Offset - 24,
        targetSize.Y.Scale, targetSize.Y.Offset - 24
    )

    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position    = startPos
    frame.Size        = startSize
    frame.Visible     = true

    return self:Tween(frame, {
        Position = targetPos,
        Size     = targetSize,
    }, duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

function Animations:CloseWindow(frame, duration, callback)
    duration = duration or T_CLOSE
    local curSize = frame.Size
    local targetPos = UDim2.new(0.5, 0, 0.5, 14)
    local targetSize = UDim2.new(
        curSize.X.Scale, curSize.X.Offset - 24,
        curSize.Y.Scale, curSize.Y.Offset - 24
    )

    local t = self:Tween(frame, {
        Position = targetPos,
        Size     = targetSize,
    }, duration, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

    t.Completed:Connect(function()
        frame.Visible  = false
        frame.Position = UDim2.new(0.5, 0, 0.5, 0)
        frame.Size     = curSize
        if callback then callback() end
    end)
    return t
end

-- =============================================================================
--  OVERLAY SLIDE IN / OUT
-- =============================================================================
function Animations:SlideInRight(frame, duration)
    duration = duration or T_TAB
    local orig = frame.Position
    frame.Position = UDim2.new(orig.X.Scale, orig.X.Offset + frame.AbsoluteSize.X + 8, orig.Y.Scale, orig.Y.Offset)
    frame.Visible = true
    return self:Tween(frame, {Position = orig}, duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

function Animations:SlideOutRight(frame, duration, callback)
    duration = duration or (T_CLOSE)
    local orig = frame.Position
    local target = UDim2.new(orig.X.Scale, orig.X.Offset + frame.AbsoluteSize.X + 8, orig.Y.Scale, orig.Y.Offset)
    local t = self:Tween(frame, {Position = target}, duration, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    t.Completed:Connect(function()
        frame.Visible = false
        frame.Position = orig
        if callback then callback() end
    end)
    return t
end

return Animations
