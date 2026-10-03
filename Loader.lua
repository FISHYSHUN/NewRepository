--[[
    ╔═════════════════════════════════════════════════════════╗
    ║               MAIN LOADER  (paste this in executor)    ║
    ╚═════════════════════════════════════════════════════════╝

    1. Upload GuiHandler.lua      → get RAW url → paste below
    2. Upload AnimationsModule.lua→ get RAW url → paste in GuiHandler.lua's ANIM_URL
    3. Upload any extra modules   → load with window:LoadModule(url)
]]

-- ── Step 1: Load the GUI Handler (which internally loads Animations) ─────────
local GUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/GuiHandler.lua"
))()

-- ── Step 2: Create a window ──────────────────────────────────────────────────
local window = GUI:CreateWindow({
    Title   = "My Script Hub",           -- Window title shown in topbar
    Size    = UDim2.new(0, 620, 0, 430), -- Width x Height
    Keybind = Enum.KeyCode.RightShift,   -- Toggle keybind
    Theme   = "Dark",                    -- "Dark" | "Light" | "Midnight"
})

-- ── Step 3: Add tabs ─────────────────────────────────────────────────────────
local homeTab = window:AddTab("🏠  Home")
homeTab:AddLabel("Welcome to My Script Hub!")
homeTab:AddSeparator()
homeTab:AddButton("Do Something", function()
    print("Button pressed!")
end)
homeTab:AddToggle("Auto-Farm", false, function(state)
    print("Auto-Farm:", state)
end)
homeTab:AddSlider("Walk Speed", 16, 200, 16, function(val)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
end)

local exploitTab = window:AddTab("⚔  Exploit")
exploitTab:AddLabel("Exploit tools here")
exploitTab:AddButton("Kill All NPCs", function()
    -- your logic
end)
exploitTab:AddDropdown("Target", {"All","Enemies","Friends"}, "All", function(v)
    print("Target:", v)
end)

local utilTab = window:AddTab("🔧  Utilities")
utilTab:AddLabel("Utility functions")
utilTab:AddTextbox("Custom Command", function(text, enter)
    if enter then print("Command:", text) end
end)

-- ── Step 4: Load external modules ────────────────────────────────────────────
-- Each module receives (window, Animations, Themes) and returns its own API
local exampleMod = window:LoadModule(
    "https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/ExampleExternalModule.lua",
    { TabName = "📦  Plugin", Icon = "" }  -- optional opts passed to the module
)

-- You can interact with the returned module API:
-- exampleMod:AddCustomElement("New Button", function() print("hi") end)

-- ── Step 5: Open the window ───────────────────────────────────────────────────
window:Open()

-- ── Optional: change theme at runtime ────────────────────────────────────────
-- window:ApplyTheme("Midnight")

-- ── Optional: change keybind at runtime ──────────────────────────────────────
-- window:SetKeybind(Enum.KeyCode.RightControl)
