--[[
    =====================================================
         ANIMATIONS MODULE v1.0
         loadstring(game:HttpGet(URL))()
    =====================================================

    Simple, clean transition animations only.
    No flashy effects -- just subtle, fast tweens.

    All durations are short (0.1 - 0.25s).
    EasingStyle: Quart (smooth) or Quad (snappy).
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Animations = {}
Animations.__index = Animations

-- =============================================================================
--  CONSTANTS
-- =============================================================================
local FAST   = 0.12   -- hover, press, release
local NORMAL = 0.20   -- fade, tab switch
local OPEN   = 0.25   -- window open
local CLOSE  = 0.18   -- window close

local function Info(dur, style, dir)
    return TweenInfo.new(
        dur   or NORMAL,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out
    )
end

-- =============================================================================
--  CORE TWEEN
-- =============================================================================

-- Base tween -- returns the Tween object
function Animations:Tween(instance, props, duration, style, direction)
    local t = TweenService:Create(instance, Info(duration, style, direction), props)
    t:Play()
    return t
end

-- =============================================================================
--  HOVER ANIMATIONS
-- =============================================================================

-- Call on MouseEnter -- shifts background to hoverColor
function Animations:HoverEnter(instance, hoverColor)
    self:Tween(instance, {BackgroundColor3 = hoverColor}, FAST)
end

-- Call on MouseLeave -- restores background to normalColor
function Animations:HoverLeave(instance, normalColor)
    self:Tween(instance, {BackgroundColor3 = normalColor}, FAST)
end

-- Auto-wires MouseEnter + MouseLeave on an instance
-- normalColor defaults to instance.BackgroundColor3 at call time
function Animations:HoverEffect(instance, hoverColor, normalColor, duration)
    normalColor = normalColor or instance.BackgroundColor3
    duration    = duration    or FAST

    instance.MouseEnter:Connect(function()
        self:Tween(instance, {BackgroundColor3 = hoverColor}, duration)
    end)
    instance.MouseLeave:Connect(function()
        self:Tween(instance, {BackgroundColor3 = normalColor}, duration)
    end)
end

-- TextColor hover variant (for labels / text buttons)
function Animations:HoverTextColor(instance, hoverColor, normalColor)
    normalColor = normalColor or instance.TextColor3
    instance.MouseEnter:Connect(function()
        self:Tween(instance, {TextColor3 = hoverColor}, FAST)
    end)
    instance.MouseLeave:Connect(function()
        self:Tween(instance, {TextColor3 = normalColor}, FAST)
    end)
end

-- =============================================================================
--  PRESS / RELEASE  (physical button feel)
-- =============================================================================
-- Shifts a surface frame slightly toward its shadow (down+right by `offset` px)
-- giving the illusion the button is being depressed.
-- Call Press on InputBegan, Release on InputEnded.

function Animations:Press(surface, offset)
    offset = offset or 2
    self:Tween(surface, {
        Position = UDim2.new(0, offset, 0, offset),
    }, FAST, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Animations:Release(surface)
    self:Tween(surface, {
        Position = UDim2.new(0, 0, 0, 0),
    }, FAST, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

-- Auto-wires InputBegan / InputEnded press animation on a TextButton surface
-- `surface` is the Frame that moves; `trigger` is the TextButton receiving input
-- (they may be the same object or different)
function Animations:PressEffect(trigger, surface, offset)
    surface = surface or trigger
    offset  = offset  or 2
    trigger.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            self:Press(surface, offset)
        end
    end)
    trigger.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            self:Release(surface)
        end
    end)
    -- Also release if mouse leaves while held
    trigger.MouseLeave:Connect(function()
        self:Release(surface)
    end)
end

-- =============================================================================
--  FADE IN / OUT
-- =============================================================================

-- Fade an instance in from fully transparent to fully opaque
function Animations:FadeIn(instance, duration)
    instance.BackgroundTransparency = 1
    instance.Visible = true
    return self:Tween(instance, {BackgroundTransparency = 0}, duration or NORMAL)
end

-- Fade an instance out, then hide it. Optional callback when done.
function Animations:FadeOut(instance, duration, callback)
    local t = self:Tween(instance, {BackgroundTransparency = 1}, duration or NORMAL)
    t.Completed:Connect(function(state)
        if state == Enum.PlaybackState.Completed then
            instance.Visible = false
            if callback then callback() end
        end
    end)
    return t
end

-- =============================================================================
--  TAB SWITCH
-- =============================================================================
-- Cross-fades between two content frames.
-- Fades old out, then fades new in.
function Animations:SwitchTab(oldFrame, newFrame, duration)
    if oldFrame == newFrame then return end
    duration = duration or NORMAL
    if oldFrame and oldFrame.Visible then
        -- Fade old out quickly, then reveal new
        local t = self:Tween(oldFrame, {BackgroundTransparency = 1}, duration * 0.5,
            Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        t.Completed:Connect(function(state)
            if state == Enum.PlaybackState.Completed then
                oldFrame.Visible = false
                oldFrame.BackgroundTransparency = 0
                if newFrame then
                    newFrame.BackgroundTransparency = 1
                    newFrame.Visible = true
                    self:Tween(newFrame, {BackgroundTransparency = 0}, duration * 0.5,
                        Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                end
            end
        end)
    else
        if newFrame then
            newFrame.BackgroundTransparency = 1
            newFrame.Visible = true
            self:Tween(newFrame, {BackgroundTransparency = 0}, duration,
                Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end
end

-- =============================================================================
--  WINDOW OPEN / CLOSE
-- =============================================================================
-- Opens a window frame by scaling it from (0,0) to its target size.
-- Stores the target size on the frame before calling.
function Animations:OpenWindow(frame, targetSize, duration)
    frame.Size    = UDim2.new(0, 0, 0, 0)
    frame.Visible = true
    return self:Tween(frame, {Size = targetSize}, duration or OPEN,
        Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

-- Closes a window frame by shrinking it to (0,0), then hides it.
function Animations:CloseWindow(frame, duration, callback)
    local t = self:Tween(frame, {Size = UDim2.new(0, 0, 0, 0)}, duration or CLOSE,
        Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    t.Completed:Connect(function(state)
        if state == Enum.PlaybackState.Completed then
            frame.Visible = false
            if callback then callback() end
        end
    end)
    return t
end

-- =============================================================================
--  ACCENT LINE SLIDE  (topbar underline reveal)
-- =============================================================================
-- Slides an accent line from width 0 to full width on a frame.
-- Used for the topbar accent reveal on window open.
function Animations:RevealAccent(line, duration)
    line.Size = UDim2.new(0, 0, line.Size.Y.Scale, line.Size.Y.Offset)
    return self:Tween(line, {Size = UDim2.new(1, 0, line.Size.Y.Scale, line.Size.Y.Offset)},
        duration or OPEN, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

-- =============================================================================
--  SIDEBAR TAB ACCENT  (left accent bar fade in/out)
-- =============================================================================
function Animations:ShowAccent(accent, theme)
    accent.Visible = true
    self:Tween(accent, {BackgroundTransparency = 0}, FAST)
end

function Animations:HideAccent(accent)
    local t = self:Tween(accent, {BackgroundTransparency = 1}, FAST)
    t.Completed:Connect(function(state)
        if state == Enum.PlaybackState.Completed then
            accent.Visible = false
            accent.BackgroundTransparency = 0
        end
    end)
end

-- =============================================================================
--  OVERLAY SLIDE IN / OUT  (for Themes, Keybinds, Settings panels)
-- =============================================================================
-- Slides a panel in from the right edge
function Animations:SlideInRight(frame, duration)
    local orig = frame.Position
    frame.Position = UDim2.new(orig.X.Scale, orig.X.Offset + frame.AbsoluteSize.X + 10,
        orig.Y.Scale, orig.Y.Offset)
    frame.Visible = true
    return self:Tween(frame, {Position = orig}, duration or OPEN,
        Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

function Animations:SlideOutRight(frame, duration, callback)
    local t = self:Tween(frame,
        {Position = UDim2.new(frame.Position.X.Scale, frame.AbsoluteSize.X + 10,
            frame.Position.Y.Scale, frame.Position.Y.Offset)},
        duration or CLOSE, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    t.Completed:Connect(function(state)
        if state == Enum.PlaybackState.Completed then
            frame.Visible = false
            if callback then callback() end
        end
    end)
    return t
end

-- =============================================================================
--  SQUARE RIPPLE  (click feedback, no rounded corners)
-- =============================================================================
function Animations:Ripple(parent, x, y, color)
    color = color or Color3.fromRGB(255, 255, 255)
    local r = Instance.new("Frame")
    r.AnchorPoint         = Vector2.new(0.5, 0.5)
    r.Position            = UDim2.new(0, x, 0, y)
    r.Size                = UDim2.new(0, 0, 0, 0)
    r.BackgroundColor3    = color
    r.BackgroundTransparency = 0.78
    r.BorderSizePixel     = 0
    r.ZIndex              = parent.ZIndex + 8
    r.Parent              = parent

    local maxS = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
    TweenService:Create(r, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size                 = UDim2.new(0, maxS, 0, maxS),
        BackgroundTransparency = 1,
    }):Play()
    game:GetService("Debris"):AddItem(r, 0.4)
end

-- =============================================================================
--  COLOR PULSE  (brief flash to accent color then restore -- for feedback)
-- =============================================================================
function Animations:Pulse(instance, pulseColor, normalColor, duration)
    normalColor = normalColor or instance.BackgroundColor3
    duration    = duration    or FAST
    self:Tween(instance, {BackgroundColor3 = pulseColor}, duration * 0.4,
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out).Completed:Connect(function(s)
        if s == Enum.PlaybackState.Completed then
            self:Tween(instance, {BackgroundColor3 = normalColor}, duration * 0.6,
                Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        end
    end)
end

return Animations
