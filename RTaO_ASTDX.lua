-- Log Control System
local LogSystem = {
    Enabled = true,
    WarningsEnabled = true
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

-- Load FluentPlus (alpha)
local success, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/main/alpha.lua"))()
end)

if not success or not Fluent then
    error("❌ ไม่สามารถโหลด FluentPlus alpha ได้ กรุณาตรวจสอบ URL หรือตัว Executor ของคุณ")
end

-- Configuration storage system
local ConfigSystem = {}
ConfigSystem.FileName = "AnimeSagaConfig_" .. game:GetService("Players").LocalPlayer.Name .. ".json"
ConfigSystem.DefaultConfig = {
    UITheme = "Amethyst",
    LogsEnabled = true,
    WarningsEnabled = true
}
ConfigSystem.CurrentConfig = {}
ConfigSystem.LastSaveTime = 0
ConfigSystem.SaveCooldown = 2
ConfigSystem.PendingSave = false

ConfigSystem.SaveConfig = function()
    local currentTime = os.time()
    if currentTime - ConfigSystem.LastSaveTime < ConfigSystem.SaveCooldown then
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
            for key, value in pairs(ConfigSystem.DefaultConfig) do
                if data[key] == nil then
                    data[key] = value
                end
            end
            ConfigSystem.CurrentConfig = data
            LogSystem.Enabled = data.LogsEnabled
            LogSystem.WarningsEnabled = data.WarningsEnabled
            return true
        end
    end

    ConfigSystem.CurrentConfig = table.clone(ConfigSystem.DefaultConfig)
    ConfigSystem.SaveConfig()
    return false
end

spawn(function()
    while wait(5) do
        if ConfigSystem.PendingSave then
            ConfigSystem.SaveConfig()
        end
    end
end)

ConfigSystem.LoadConfig()

local player = game:GetService("Players").LocalPlayer
local playerName = player.Name

local Window = Fluent:CreateWindow({
    Title = "RTaO Hub | ASTD X",
    SubTitle = "By RTaO",
    TabWidth = 140,
    Size = UDim2.fromOffset(450, 350),
    Acrylic = true,
    Theme = ConfigSystem.CurrentConfig.UITheme or "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local InfoTab = Window:AddTab({ Title = "Info", Icon = "rbxassetid://7733964719" })
local PlayTab = Window:AddTab({ Title = "Play", Icon = "rbxassetid://7734053495" })
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

local MacroTab = Window:AddTab({ Title = "Macro", Icon = "rbxassetid://7734053495" })

-- (ส่วนอื่น ๆ ของสคริปต์ เช่น macro recorder, settings tab, UI logo button ฯลฯ สามารถนำมาต่อในสคริปต์นี้ได้ต่อเนื่อง)

print("✅ RTaO Hub | Script loaded with FluentPlus alpha")
