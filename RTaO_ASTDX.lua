-- Log Control System
local LogSystem = {
    Enabled = true, -- Controls general logging
    WarningsEnabled = true -- Controls warning messages
}

local originalPrint = print
print = function(...)
    if LogSystem.Enabled then
        originalPrint(...)
    end
end

local originalWarn = warn
warn = function(...)
    if LogSystem.WarningsEnabled then
        originalWarn(...)
    end
end

local success, err = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

if not success then
    warn("Error loading Fluent library: " .. tostring(err))

    pcall(function()
        Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua"))()
        SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
        InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    end)
end

if not Fluent then
    error("Unable to load Fluent library. Please check your internet connection or executor.")
    return
end

-- Configuration storage system
local ConfigSystem = {}
ConfigSystem.FileName = "AnimeSagaConfig_" .. game:GetService("Players").LocalPlayer.Name .. ".json"
ConfigSystem.DefaultConfig = {
    -- Default settings
    UITheme = "Amethyst",

    -- Log settings
    LogsEnabled = true,
    WarningsEnabled = true,

    -- Other settings will be added later
}
ConfigSystem.CurrentConfig = {}

-- Cache for ConfigSystem to reduce I/O
ConfigSystem.LastSaveTime = 0
ConfigSystem.SaveCooldown = 2 -- 2 seconds between saves
ConfigSystem.PendingSave = false

-- Function to save configuration
ConfigSystem.SaveConfig = function()
    -- Check time since last save
    local currentTime = os.time()
    if currentTime - ConfigSystem.LastSaveTime < ConfigSystem.SaveCooldown then
        -- Saved recently, mark to save later
        ConfigSystem.PendingSave = true
        return
    end

    local success, err = pcall(function()
        local HttpService = game:GetService("HttpService")
        writefile(ConfigSystem.FileName, HttpService:JSONEncode(ConfigSystem.CurrentConfig))
    end)

    if success then
        ConfigSystem.LastSaveTime = currentTime
        ConfigSystem.PendingSave = false
    else
        warn("Failed to save configuration:", err)
    end
end

-- Function to load configuration
ConfigSystem.LoadConfig = function()
    local success, content = pcall(function()
        if isfile(ConfigSystem.FileName) then
            return readfile(ConfigSystem.FileName)
        end
        return nil
    end)

    if success and content then
        local success2, data = pcall(function()
            local HttpService = game:GetService("HttpService")
            return HttpService:JSONDecode(content)
        end)

        if success2 and data then
            -- Merge with default config to ensure all settings exist
            for key, value in pairs(ConfigSystem.DefaultConfig) do
                if data[key] == nil then
                    data[key] = value
                end
            end

            ConfigSystem.CurrentConfig = data

            -- Update log settings
            if data.LogsEnabled ~= nil then
                LogSystem.Enabled = data.LogsEnabled
            end

            if data.WarningsEnabled ~= nil then
                LogSystem.WarningsEnabled = data.WarningsEnabled
            end

            return true
        end
    end

    -- If loading fails, use default configuration
    ConfigSystem.CurrentConfig = table.clone(ConfigSystem.DefaultConfig)
    ConfigSystem.SaveConfig()
    return false
end

-- Set up timer to periodically save if there are unsaved changes
spawn(function()
    while wait(5) do
        if ConfigSystem.PendingSave then
            ConfigSystem.SaveConfig()
        end
    end
end)

-- Load configuration on startup
ConfigSystem.LoadConfig()

-- Player information
local playerName = game:GetService("Players").LocalPlayer.Name

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "RTaO Hub | ASTD X",
    SubTitle = "By RTaO",
    TabWidth = 140,
    Size = UDim2.fromOffset(450, 350),
    Acrylic = true,
    Theme = ConfigSystem.CurrentConfig.UITheme or "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Create Info tab
local InfoTab = Window:AddTab({
    Title = "Info",
    Icon = "rbxassetid://7733964719"
})

-- Add Play tab
local PlayTab = Window:AddTab({
    Title = "Play",
    Icon = "rbxassetid://7734053495" -- You can change the icon if you want
})

-- Add content to Play tab
local GameplaySection = PlayTab:AddSection("Gameplay Features")

GameplaySection:AddToggle("AutoPlay", {
    Title = "Auto Play",
    Description = "Automatically play the game",
    Default = false,
    Callback = function(Value)
        print("Auto Play:", Value)
    end
})

GameplaySection:AddButton({
    Title = "Skip Wave",
    Description = "Skip to next wave",
    Callback = function()
        print("Skipping wave...")
    end
})

GameplaySection:AddButton({
    Title = "Auto Upgrade All",
    Description = "Upgrade all units automatically",
    Callback = function()
        print("Auto upgrading all units...")
    end
})

local MacroTab = Window:AddTab({
    Title = "Macro",
    Icon = "rbxassetid://7734053495" -- Change the icon if you want
})
-- Add Logo support when minimized
repeat task.wait(0.25) until game:IsLoaded()
getgenv().Image = "rbxassetid://90319448802378" -- Image resource ID for the logo
getgenv().ToggleUI = "LeftControl" -- Key to toggle UI visibility

-- Create logo to reopen UI when minimized
task.spawn(function()
    local success, errorMsg = pcall(function()
        if not getgenv().LoadedMobileUI == true then
            getgenv().LoadedMobileUI = true
            local OpenUI = Instance.new("ScreenGui")
            local ImageButton = Instance.new("ImageButton")
            local UICorner = Instance.new("UICorner")

            -- Check environment
            if syn and syn.protect_gui then
                syn.protect_gui(OpenUI)
                OpenUI.Parent = game:GetService("CoreGui")
            elseif gethui then
                OpenUI.Parent = gethui()
            else
                OpenUI.Parent = game:GetService("CoreGui")
            end

            OpenUI.Name = "OpenUI"
            OpenUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

            ImageButton.Parent = OpenUI
            ImageButton.BackgroundColor3 = Color3.fromRGB(105,105,105)
            ImageButton.BackgroundTransparency = 0.8
            ImageButton.Position = UDim2.new(0.9,0,0.1,0)
            ImageButton.Size = UDim2.new(0,50,0,50)
            ImageButton.Image = getgenv().Image
            ImageButton.Draggable = true
            ImageButton.Transparency = 0.2

            UICorner.CornerRadius = UDim.new(0,200)
            UICorner.Parent = ImageButton

            -- When clicking the logo, reopen the UI
            ImageButton.MouseButton1Click:Connect(function()
                game:GetService("VirtualInputManager"):SendKeyEvent(true,getgenv().ToggleUI,false,game)
            end)
        end
    end)

    if not success then
        warn("Error creating Logo UI button: " .. tostring(errorMsg))
    end
end)

-- Automatically select Info tab on startup
Window:SelectTab(1) -- Select the first tab (Info)

-- Add info section in Info tab
local InfoSection = InfoTab:AddSection("Information")

InfoSection:AddParagraph({
    Title = "All Star Tower Defense X",
    Content = "Version: 1.0 Beta\nStatus: Active"
})

InfoSection:AddParagraph({
    Title = "Developers",
    Content = "Script developed RTaO"
})

-- Add settings section in Settings tab
local SettingsTab = Window:AddTab({
    Title = "Settings",
    Icon = "rbxassetid://6031280882"
})

local SettingsSection = SettingsTab:AddSection("Settings")

-- Dropdown to select theme
SettingsSection:AddDropdown("ThemeDropdown", {
    Title = "Select Theme",
    Values = {"Dark", "Light", "Darker", "Aqua", "Amethyst"},
    Multi = false,
    Default = ConfigSystem.CurrentConfig.UITheme or "Dark",
    Callback = function(Value)
        ConfigSystem.CurrentConfig.UITheme = Value
        ConfigSystem.SaveConfig()
        print("Theme selected: " .. Value)
    end
})

-- Auto Save Config
local function AutoSaveConfig()
    spawn(function()
        while wait(5) do -- Save every 5 seconds
            pcall(function()
                ConfigSystem.SaveConfig()
            end)
        end
    end)
end

-- Add event listener to save immediately when a value changes
local function setupSaveEvents()
    for _, tab in pairs({InfoTab, SettingsTab}) do
        if tab and tab._components then
            for _, element in pairs(tab._components) do
                if element and element.OnChanged then
                    element.OnChanged:Connect(function()
                        pcall(function()
                            ConfigSystem.SaveConfig()
                        end)
                    end)
                end
            end
        end
    end
end

-- ...existing code...
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerName = player.Name

local SetEvent = ReplicatedStorage.Remotes.SetEvent
local GetFunction = ReplicatedStorage.Remotes.GetFunction

-- Global vars
getgenv().recording = false
getgenv().macroSteps = {}
getgenv().stepIndex = 0

-- Convert CFrame to string
local function cframeToString(cf)
    local components = {cf:GetComponents()}
    for i, v in ipairs(components) do
        components[i] = tostring(math.round(v * 1000) / 1000)
    end
    return table.concat(components, ",")
end

-- Hook __namecall ONLY ONCE
if not getgenv().macroHooked then
    getgenv().macroHooked = true

    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        local money = tostring(player:FindFirstChild("Money") and player.Money.Value or 0)

        if getgenv().recording and (self == SetEvent or self == GetFunction) then
            if self == SetEvent and args[1] == "GameStuff" and args[2][1] == "Summon" then
                getgenv().stepIndex = getgenv().stepIndex + 1
                getgenv().macroSteps[tostring(getgenv().stepIndex)] = {
                    type = "SpawnUnit",
                    unit = args[2][2],
                    cframe = cframeToString(args[2][3]),
                    money = money
                }
                print("📌 Recorded Place:", args[2][2])

            elseif self == GetFunction and args[1] and args[1].Type == "GameStuff" and args[2][1] == "Upgrade" then
                local unit = args[2][2]
                if unit and unit:FindFirstChild("SpawnCFrame") then
                    getgenv().stepIndex = getgenv().stepIndex + 1
                    getgenv().macroSteps[tostring(getgenv().stepIndex)] = {
                        type = "UpgradeUnit",
                        unit = unit.Name,
                        cframe = cframeToString(unit.SpawnCFrame.Value),
                        money = money
                    }
                    print("📌 Recorded Upgrade:", unit.Name)
                end

            elseif self == GetFunction and args[1] and args[1].Type == "GameStuff" and args[2][1] == "Sell" then
                local unit = args[2][2]
                if unit and unit:FindFirstChild("SpawnCFrame") then
                    getgenv().stepIndex = getgenv().stepIndex + 1
                    getgenv().macroSteps[tostring(getgenv().stepIndex)] = {
                        type = "SellUnit",
                        unit = unit.Name,
                        cframe = cframeToString(unit.SpawnCFrame.Value),
                        money = money
                    }
                    print("📌 Recorded Sell:", unit.Name)
                end
            end
        end
        return oldNamecall(self, unpack(args))
    end)
end

-- GUI Toggle
local MacroSection = MacroTab:AddSection("🎥 Macro Recorder")

local MacroRecorderToggle = MacroSection:AddToggle("MacroRecorderToggle", {
    Title = "🎥 Record Macro (Place / Upgrade / Sell)",
    Default = false,
    Description = "Enable to start recording macro. Disable to stop & save."
})

MacroRecorderToggle:OnChanged(function(val)
    if val then
        if getgenv().recording then
            warn("🚫 Macro is already running.")
            return
        end
        getgenv().recording = true
        getgenv().macroSteps = {}
        getgenv().stepIndex = 0
        print("🎬 Macro recording started...")
    else
        if not getgenv().recording then
            warn("⚠️ Macro is not enabled.")
            return
        end
        getgenv().recording = false
        print("🛑 Macro stopped.")

        -- Save file
        local saveData = getgenv().macroSteps
        saveData["Data"] = {
            Map = "UnknownMap",
            RecordMode = "Money",
            Units = {}
        }

        if writefile then
            local fileName = "Macro_" .. playerName .. ".json"
            writefile(fileName, HttpService:JSONEncode(saveData))
            print("💾 Macro saved to", fileName)
        else
            warn("⚠ Executor does not support writefile.")
        end
    end
end)

-- Add macro playback functionality
MacroSection:AddButton({
    Title = "📂 Load Macro",
    Description = "Load a saved macro file",
    Callback = function()
        local fileName = "Macro_" .. playerName .. ".json"
        if isfile(fileName) then
            local success, content = pcall(function()
                return readfile(fileName)
            end)
            
            if success and content then
                local success2, data = pcall(function()
                    return HttpService:JSONDecode(content)
                end)
                
                if success2 and data then
                    print("📂 Macro loaded successfully!")
                    print("Steps found:", #data)
                else
                    warn("❌ Failed to parse macro file")
                end
            else
                warn("❌ Failed to read macro file")
            end
        else
            warn("❌ No macro file found: " .. fileName)
        end
    end
})

MacroSection:AddButton({
    Title = "🗑️ Clear Macro",
    Description = "Clear current macro data",
    Callback = function()
        getgenv().macroSteps = {}
        getgenv().stepIndex = 0
        print("🗑️ Macro data cleared")
    end
})

-- === END OF REPLACED SECTION ===

-- ...existing code...

-- ...existing code...

-- Integrate with SaveManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Change how configuration is saved to use player name
InterfaceManager:SetFolder("HTHubAS")
SaveManager:SetFolder("HTHubAS/" .. playerName)

-- Add information to the Settings tab
SettingsTab:AddParagraph({
    Title = "Auto Configuration",
    Content = "Your configuration is automatically saved by character name: " .. playerName
})

SettingsTab:AddParagraph({
    Title = "Hotkey",
    Content = "Press LeftControl to hide/show the interface"
})

-- Execute auto-save configuration
AutoSaveConfig()

-- Set up events
setupSaveEvents()

print("RTaO Hub | Script loaded successfully!")essfully!")
