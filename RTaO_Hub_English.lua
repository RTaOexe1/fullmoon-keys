loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/init.lua"))()

-- Load FluentPlus
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/init.lua"))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerName = player.Name

getgenv().recording = false
getgenv().macroSteps = {}
getgenv().stepIndex = 0
getgenv().selectedSlot = "Slot1"

local function cframeToString(cf)
    local components = {cf:GetComponents()}
    for i, v in ipairs(components) do
        components[i] = tostring(math.round(v * 1000) / 1000)
    end
    return table.concat(components, ",")
end

local Window = Fluent:Window({
    Title = "RTaO Hub | ASTD X",
    SubTitle = "FluentPlus UI",
    TabWidth = 120,
    Size = UDim2.fromOffset(500, 400),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Info Tab
Window:Tab("Info", function(Tab)
    Tab:Section("About")
    Tab:Paragraph("All Star Tower Defense X")
    Tab:Paragraph("Version: 1.0 Beta\\nStatus: Active")
    Tab:Paragraph("Developer: RTaO")
end)

-- Play Tab
Window:Tab("Play", function(Tab)
    Tab:Section("Coming Soon")
    Tab:Label("Future features will be added here.")
end)

-- Macro Tab
Window:Tab("Macro", function(Tab)
    Tab:Section("🎥 Macro Recorder")
    Tab:Toggle("Start Recording", false, function(state)
        getgenv().recording = state
        if state then
            getgenv().macroSteps = {}
            getgenv().stepIndex = 0
            print("🎬 Macro recording started")
        else
            print("🛑 Macro recording stopped")
        end
    end)
    Tab:Dropdown("Save Slot", {"Slot1", "Slot2", "Slot3"}, "Slot1", function(slot)
        getgenv().selectedSlot = slot
    end)
    Tab:Button("💾 Save Macro", function()
        local savePath = "Macro_" .. playerName .. "_" .. getgenv().selectedSlot .. ".json"
        if writefile then
            writefile(savePath, HttpService:JSONEncode(getgenv().macroSteps))
            print("✅ Saved:", savePath)
        else
            warn("❌ writefile unsupported")
        end
    end)
    Tab:Button("📂 Load Macro", function()
        local path = "Macro_" .. playerName .. "_" .. getgenv().selectedSlot .. ".json"
        if isfile and isfile(path) then
            getgenv().macroSteps = HttpService:JSONDecode(readfile(path))
            print("📥 Loaded:", path)
        else
            warn("⚠️ File not found:", path)
        end
    end)
    Tab:Button("▶ Play Macro (Log Only)", function()
        for i, v in pairs(getgenv().macroSteps) do
            if typeof(v) == "table" and v.type then
                print("⏩ Step", i, v.type, v.unit or "", v.money or "")
            end
        end
    end)
end)

-- Settings
Window:Tab("Settings", function(Tab)
    Tab:Section("Preferences")
    Tab:Dropdown("Select Theme", {"Dark", "Light", "Darker", "Aqua", "Amethyst"}, "Dark", function(theme)
        print("🎨 Theme selected:", theme)
    end)
    Tab:Paragraph("Shortcut: Press LeftControl to toggle UI")
end)

-- Macro Hook
local SetEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SetEvent")
local GetFunction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetFunction")

if not getgenv().macroHooked then
    getgenv().macroHooked = true
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        local money = tostring(player:FindFirstChild("Money") and player.Money.Value or 0)

        if getgenv().recording and (self == SetEvent or self == GetFunction) then
            if self == SetEvent and args[1] == "GameStuff" and args[2][1] == "Summon" then
                getgenv().stepIndex += 1
                getgenv().macroSteps[tostring(getgenv().stepIndex)] = {
                    type = "SpawnUnit",
                    unit = args[2][2],
                    cframe = cframeToString(args[2][3]),
                    money = money
                }
                print("📌 Recorded Summon:", args[2][2])
            elseif self == GetFunction and args[1] and args[1].Type == "GameStuff" then
                local action = args[2][1]
                local unit = args[2][2]
                if unit and unit:FindFirstChild("SpawnCFrame") then
                    getgenv().stepIndex += 1
                    getgenv().macroSteps[tostring(getgenv().stepIndex)] = {
                        type = action == "Upgrade" and "UpgradeUnit" or "SellUnit",
                        unit = unit.Name,
                        cframe = cframeToString(unit.SpawnCFrame.Value),
                        money = money
                    }
                    print("📌 Recorded", action, unit.Name)
                end
            end
        end
        return old(self, ...)
    end)
end

print("✅ RTaO Hub FluentPlus Loaded")
