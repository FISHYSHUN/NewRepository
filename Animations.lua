--[[
    ╔═══════════════════════════════════════════╗
    ║         ANIMATIONS MODULE v1.0            ║
    ║   Connect via: loadstring(...)()          ║
    ╚═══════════════════════════════════════════╝

    Usage:
        local Animations = loadstring(game:HttpGet("RAW_URL_HERE"))()
        Animations:Tween(frame, {Size = UDim2.new(...)}, 0.3)
]]

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local Animations = {}
Animations.__index = Animations

-- ── Default easing ─────────────────────────────────────────────────────────
local DEFAULT_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- ── Core Tween ──────────────────────────────────────────────────────────────
function Animations:Tween(instance, props, duration, style, direction)
    local info = TweenInfo.new(
        duration  or 0.25,
        style     or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

-- ── Fade In ─────────────────────────────────────────────────────────────────
function Animations:FadeIn(instance, duration)
    instance.BackgroundTransparency = 1
    instance.Visible = true
    return self:Tween(instance, {BackgroundTransparency = 0}, duration or 0.2)
end

-- ── Fade Out ────────────────────────────────────────────────────────────────
function Animations:FadeOut(instance, duration, callback)
    local t = self:Tween(instance, {BackgroundTransparency = 1}, duration or 0.2)
    t.Completed:Connect(function()
        instance.Visible = false
        if callback then callback() end
    end)
    return t
end

-- ── Slide In (from direction) ────────────────────────────────────────────────
-- direction: "left" | "right" | "top" | "bottom"
function Animations:SlideIn(instance, direction, duration)
    local orig = instance.Position
    local offX, offY = 0, 0
    if direction == "left"   then offX = -instance.AbsoluteSize.X - 10 end
    if direction == "right"  then offX =  instance.AbsoluteSize.X + 10 end
    if direction == "top"    then offY = -instance.AbsoluteSize.Y - 10 end
    if direction == "bottom" then offY =  instance.AbsoluteSize.Y + 10 end

    instance.Position = UDim2.new(
        orig.X.Scale, orig.X.Offset + offX,
        orig.Y.Scale, orig.Y.Offset + offY
    )
    instance.Visible = true
    return self:Tween(instance, {Position = orig}, duration or 0.3)
end

-- ── Slide Out ────────────────────────────────────────────────────────────────
function Animations:SlideOut(instance, direction, duration, callback)
    local orig = instance.Position
    local offX, offY = 0, 0
    if direction == "left"   then offX = -instance.AbsoluteSize.X - 10 end
    if direction == "right"  then offX =  instance.AbsoluteSize.X + 10 end
    if direction == "top"    then offY = -instance.AbsoluteSize.Y - 10 end
    if direction == "bottom" then offY =  instance.AbsoluteSize.Y + 10 end

    local target = UDim2.new(
        orig.X.Scale, orig.X.Offset + offX,
        orig.Y.Scale, orig.Y.Offset + offY
    )
    local t = self:Tween(instance, {Position = target}, duration or 0.3)
    t.Completed:Connect(function()
        instance.Visible = false
        instance.Position = orig -- reset for next use
        if callback then callback() end
    end)
    return t
end

-- ── Scale Bounce ─────────────────────────────────────────────────────────────
function Animations:Bounce(instance, duration)
    local orig = instance.Size
    local big  = UDim2.new(
        orig.X.Scale * 1.08, orig.X.Offset,
        orig.Y.Scale * 1.08, orig.Y.Offset
    )
    self:Tween(instance, {Size = big}, (duration or 0.15) / 2,
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out).Completed:Connect(function()
        self:Tween(instance, {Size = orig}, (duration or 0.15) / 2,
            Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    end)
end

-- ── Hover Highlight ──────────────────────────────────────────────────────────
-- Call once; automatically manages MouseEnter / MouseLeave
function Animations:HoverEffect(instance, hoverColor, normalColor, duration)
    normalColor = normalColor or instance.BackgroundColor3
    duration    = duration or 0.15

    instance.MouseEnter:Connect(function()
        self:Tween(instance, {BackgroundColor3 = hoverColor}, duration)
    end)
    instance.MouseLeave:Connect(function()
        self:Tween(instance, {BackgroundColor3 = normalColor}, duration)
    end)
end

-- ── Tab Switch ───────────────────────────────────────────────────────────────
-- Fades out old content, fades in new
function Animations:SwitchTab(oldFrame, newFrame, duration)
    if oldFrame == newFrame then return end
    duration = duration or 0.18
    self:FadeOut(oldFrame, duration, function()
        self:FadeIn(newFrame, duration)
    end)
end

-- ── Window Open / Close ──────────────────────────────────────────────────────
function Animations:OpenWindow(windowFrame, duration)
    windowFrame.Size = UDim2.new(0, 0, 0, 0)
    windowFrame.Visible = true
    local target = windowFrame:GetAttribute("OriginalSize") or windowFrame.Size
    self:Tween(windowFrame, {Size = target}, duration or 0.3,
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function Animations:CloseWindow(windowFrame, duration, callback)
    local t = self:Tween(windowFrame, {Size = UDim2.new(0,0,0,0)}, duration or 0.25,
        Enum.EasingStyle.Back, Enum.EasingDirection.In)
    t.Completed:Connect(function()
        windowFrame.Visible = false
        if callback then callback() end
    end)
    return t
end

-- ── Typewriter text ──────────────────────────────────────────────────────────
function Animations:Typewriter(label, text, speed)
    speed = speed or 0.04
    label.Text = ""
    task.spawn(function()
        for i = 1, #text do
            label.Text = string.sub(text, 1, i)
            task.wait(speed)
        end
    end)
end

-- ── Ripple effect (click feedback) ──────────────────────────────────────────
function Animations:Ripple(parent, x, y, color)
    color = color or Color3.fromRGB(255,255,255)
    local ripple = Instance.new("Frame")
    ripple.AnchorPoint  = Vector2.new(0.5, 0.5)
    ripple.Position     = UDim2.new(0, x, 0, y)
    ripple.Size         = UDim2.new(0, 0, 0, 0)
    ripple.BackgroundColor3 = color
    ripple.BackgroundTransparency = 0.6
    ripple.ZIndex       = parent.ZIndex + 5
    ripple.ClipsDescendants = false
    local corner = Instance.new("UICorner", ripple)
    corner.CornerRadius = UDim.new(1, 0)
    ripple.Parent = parent

    local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.5
    TweenService:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    }):Play()
    game:GetService("Debris"):AddItem(ripple, 0.6)
end

return Animations
