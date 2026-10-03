--[[
    =====================================================
         MAIN LOADER  --  paste this into your executor
    =====================================================

    Files in FISHYSHUN/NewRepository (main branch):
      Gui.lua        -> GUI Handling Module
      Animations.lua -> Animations Module
      Loader.lua     -> This file

    Gui.lua automatically fetches Animations.lua.
    Add extra modules with window:LoadModule(url).
]]

-- -- Step 1: Load the GUI Handler (auto-fetches Animations internally) ---------
local GUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/FISHYSHUN/NewRepository/main/Gui.lua",
    true  -- bypass cache
))()

-- -- Step 2: Create a window ---------------------------------------------------
local window = GUI:CreateWindow({
    Title   = "My Script Hub",           -- topbar title
    Size    = UDim2.new(0, 620, 0, 430), -- window size
    Keybind = Enum.KeyCode.RightShift,   -- toggle keybind
    Theme   = "Dark",                    -- "Dark" | "Light" | "Midnight"
})

-- -- Step 3: Add tabs ----------------------------------------------------------
local homeTab = window:AddTab("Home")
homeTab:AddLabel("Welcome to My Script Hub!")
homeTab:AddSeparator()
homeTab:AddButton("Do Something", function()
    print("Button pressed!")
end)
homeTab:AddToggle("Auto-Farm", false, function(state)
    print("Auto-Farm:", state)
end)
homeTab:AddSlider("Walk Speed", 16, 200, 16, function(val)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = val
    end
end)
--
local exploitTab = window:AddTab("Exploit")
exploitTab:AddLabel("Exploit tools")
exploitTab:AddButton("Kill All NPCs", function()
    -- your logic here
end)
exploitTab:AddDropdown("Target", {"All","Enemies","Friends"}, "All", function(v)
    print("Target:", v)
end)

local utilTab = window:AddTab("Utilities")
utilTab:AddLabel("Utility functions")
utilTab:AddTextbox("Custom Command", function(text, enter)
    if enter then print("Command:", text) end
end)

-- -- Step 4: Load external modules (optional) ----------------------------------
-- Each module gets (window, Animations, Themes, opts) and returns its own API.
-- Uncomment and replace URL to use:
--
-- local myPlugin = window:LoadModule(
--     "https://raw.githubusercontent.com/FISHYSHUN/NewRepository/main/ExampleExternalModule.lua",
--     { TabName = "Plugin" }
-- )

-- -- Step 5: Open the window ---------------------------------------------------
window:Open()

-- -- Optional: switch theme at runtime ----------------------------------------
-- window:ApplyTheme("Midnight")

-- -- Optional: change keybind at runtime --------------------------------------
-- window:SetKeybind(Enum.KeyCode.RightControl)
