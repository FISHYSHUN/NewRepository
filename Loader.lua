--[[
    =====================================================
         MAIN LOADER  --  paste this into your executor
    =====================================================

    Files in FISHYSHUN/NewRepository (main branch):
      Gui.lua        -> GUI Handling Module
      Animations.lua -> Animations Module
      Loader.lua     -> This file

    Features Included:
      * Anti-Player Fling (disables collisions and rogue trajectory velocity)
      * Translucent Mode Toggle (click top-left text)
      * Full Movement Suite (Speed, Jump, Infinite Jump, Noclip, Fly)
      * Visual Suite (Player ESP / Chams, Fullbright, Fog Removal)
      * Server Tools (Rejoin, Server Hop, Anti-AFK)
      * Combat & Utility Tools (Click-to-Teleport, SpinBot, FPS Unlocker)
]]

-- -- Services ------------------------------------------------------------------
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- -- Step 1: Load the GUI Handler (auto-fetches Animations internally) ---------
local GUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/FISHYSHUN/NewRepository/main/Gui.lua",
    true  -- bypass cache
))()

-- -- Step 2: Create the window -------------------------------------------------
local window = GUI:CreateWindow({
    Title   = "Hub",
    Size    = UDim2.new(0, 620, 0, 430),
    Keybind = Enum.KeyCode.RightShift,
    Theme   = "Dark",
})

-- =============================================================================
--  FEATURE TAB 1: HOME
-- =============================================================================
local homeTab = window:AddTab("Home")
homeTab:AddLabel("Welcome to Hub!")
homeTab:AddLabel("Tip: Click the top-left tab title to toggle Translucent Mode.")
homeTab:AddSeparator()

-- Anti-AFK
local antiAfkConn = nil
homeTab:AddToggle("Anti-AFK (Prevents 20-min kick)", false, function(state)
    if state then
        antiAfkConn = LocalPlayer.Idled:Connect(function()
            local vu = game:GetService("VirtualUser")
            if vu then
                vu:CaptureController()
                vu:ClickButton2(Vector2.zero)
            end
        end)
    else
        if antiAfkConn then
            antiAfkConn:Disconnect()
            antiAfkConn = nil
        end
    end
end)

-- Rejoin Server
homeTab:AddButton("Rejoin Current Server", function()
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\n[Hub] Rejoining...")
        task.wait(0.5)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end)

-- Server Hop
homeTab:AddButton("Server Hop", function()
    local placeId = game.PlaceId
    local serversApi = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
    local success, body = pcall(function()
        return game:HttpGet(serversApi)
    end)
    if success and body then
        local data = HttpService:JSONDecode(body)
        if data and data.data then
            for _, s in ipairs(data.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(placeId, s.id, LocalPlayer)
                    break
                end
            end
        end
    end
end)

-- =============================================================================
--  FEATURE TAB 2: MOVEMENT
-- =============================================================================
local moveTab = window:AddTab("Movement")
moveTab:AddLabel("Character Movement Enhancements")
moveTab:AddSeparator()

-- WalkSpeed
moveTab:AddSlider("Walk Speed", 16, 250, 16, function(val)
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = val
    end
end)

-- JumpPower
moveTab:AddSlider("Jump Power", 50, 300, 50, function(val)
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").UseJumpPower = true
        char:FindFirstChildOfClass("Humanoid").JumpPower = val
    end
end)

-- Infinite Jump
local infJumpConn = nil
moveTab:AddToggle("Infinite Jump", false, function(state)
    if state then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if infJumpConn then
            infJumpConn:Disconnect()
            infJumpConn = nil
        end
    end
end)

-- Noclip
local noclipConn = nil
moveTab:AddToggle("Noclip (Walk through walls)", false, function(state)
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end
    end
end)

-- Fly
local flying = false
local flySpeed = 50
local flyBodyPos, flyBodyGyro = nil, nil
local flyConn = nil

moveTab:AddToggle("Fly", false, function(state)
    flying = state
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if flying then
        flyBodyPos = Instance.new("BodyPosition")
        flyBodyPos.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        flyBodyPos.Position = root.Position
        flyBodyPos.Parent = root

        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        flyBodyGyro.CFrame = root.CFrame
        flyBodyGyro.Parent = root

        flyConn = RunService.RenderStepped:Connect(function()
            if not flying or not root or not flyBodyPos then return end
            local cam = workspace.CurrentCamera
            local moveVec = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec = moveVec + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec = moveVec - Vector3.new(0, 1, 0) end

            flyBodyPos.Position = flyBodyPos.Position + (moveVec * (flySpeed / 60))
            flyBodyGyro.CFrame = cam.CFrame
        end)
    else
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if flyBodyPos then flyBodyPos:Destroy(); flyBodyPos = nil end
        if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    end
end)

moveTab:AddSlider("Fly Speed", 20, 200, 50, function(val)
    flySpeed = val
end)

-- =============================================================================
--  FEATURE TAB 3: COMBAT & DEFENSE
-- =============================================================================
local combatTab = window:AddTab("Defense")
combatTab:AddLabel("Protection & Physics Defense")
combatTab:AddSeparator()

-- Anti-Player Fling
combatTab:AddToggle("Anti-Player Fling (Disables Fling Physics)", false, function(state)
    GUI.AntiFling:SetEnabled(state)
end)

-- Click to Teleport
local clickTpActive = false
local clickTpConn = nil
combatTab:AddToggle("Click-To-Teleport (Ctrl + Click)", false, function(state)
    clickTpActive = state
    if state then
        clickTpConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") and Mouse.Hit then
                    char.HumanoidRootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
                end
            end
        end)
    else
        if clickTpConn then
            clickTpConn:Disconnect()
            clickTpConn = nil
        end
    end
end)

-- SpinBot
local spinConn = nil
local spinSpeed = 30
combatTab:AddToggle("SpinBot", false, function(state)
    if state then
        spinConn = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
            end
        end)
    else
        if spinConn then
            spinConn:Disconnect()
            spinConn = nil
        end
    end
end)

combatTab:AddSlider("Spin Speed", 5, 100, 30, function(val)
    spinSpeed = val
end)

-- Reset Character
combatTab:AddButton("Reset Character", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
    end
end)

-- =============================================================================
--  FEATURE TAB 4: VISUALS
-- =============================================================================
local visualTab = window:AddTab("Visuals")
visualTab:AddLabel("ESP & Environment Controls")
visualTab:AddSeparator()

-- Player ESP / Chams
local espActive = false
local espHighlights = {}

local function applyEsp(player)
    if player == LocalPlayer then return end
    local function addHighlight(char)
        if not char then return end
        if espHighlights[player] then espHighlights[player]:Destroy() end
        local hl = Instance.new("Highlight")
        hl.Name = "Hub_ESP"
        hl.FillColor = Color3.fromRGB(100, 180, 240)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = char
        hl.Parent = char
        espHighlights[player] = hl
    end

    if player.Character then addHighlight(player.Character) end
    player.CharacterAdded:Connect(function(c)
        if espActive then
            task.wait(0.2)
            addHighlight(c)
        end
    end)
end

visualTab:AddToggle("Player ESP (Chams)", false, function(state)
    espActive = state
    if state then
        for _, p in ipairs(Players:GetPlayers()) do
            applyEsp(p)
        end
        Players.PlayerAdded:Connect(function(p)
            if espActive then applyEsp(p) end
        end)
    else
        for _, hl in pairs(espHighlights) do
            if hl and hl.Parent then hl:Destroy() end
        end
        espHighlights = {}
    end
end)

-- Fullbright
local fullbrightActive = false
local origBrightness = Lighting.Brightness
local origClock = Lighting.ClockTime
local origShadows = Lighting.GlobalShadows

visualTab:AddToggle("Fullbright", false, function(state)
    fullbrightActive = state
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = origBrightness
        Lighting.ClockTime = origClock
        Lighting.GlobalShadows = origShadows
    end
end)

-- Remove Fog
visualTab:AddButton("Remove Fog", function()
    Lighting.FogEnd = 1e10
    Lighting.FogStart = 1e10
    for _, v in ipairs(Lighting:GetDescendants()) do
        if v:IsA("Atmosphere") then
            v.Density = 0
        end
    end
end)

-- =============================================================================
--  FEATURE TAB 5: UTILITIES
-- =============================================================================
local utilTab = window:AddTab("Utilities")
utilTab:AddLabel("Client Tools & Information")
utilTab:AddSeparator()

-- Copy Position
utilTab:AddButton("Copy Current Position", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local pos = char.HumanoidRootPart.Position
        local str = string.format("Vector3.new(%.2f, %.2f, %.2f)", pos.X, pos.Y, pos.Z)
        if setclipboard then
            setclipboard(str)
            print("[Hub] Position copied to clipboard:", str)
        else
            print("[Hub] Position:", str)
        end
    end
end)

-- FPS Cap
utilTab:AddDropdown("Target FPS", {"60", "120", "144", "240"}, "60", function(val)
    if setfpscap then
        setfpscap(tonumber(val) or 60)
    end
end)

-- Destroy GUI
utilTab:AddButton("Destroy GUI", function()
    window:Destroy()
end)

-- -- Step 3: Open the window ---------------------------------------------------
window:Open()
