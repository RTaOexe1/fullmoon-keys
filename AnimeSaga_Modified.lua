-- Anime Saga Script

-- Log control system
local LogSystem = {
    Enabled = true, -- Logs enabled by default
    WarningsEnabled = true -- Warnings enabled by default
}

-- Override print function to control logs
local originalPrint = print
print = function(...)
    if LogSystem.Enabled then
        originalPrint(...)
    end
end

-- Override warn function to control warnings
local originalWarn = warn
warn = function(...)
    if LogSystem.WarningsEnabled then
        originalWarn(...)
    end
end

-- Load Fluent library
local success, err = pcall(function()
    Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/alpha.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

if not success then
    warn("Lỗi khi tải thư viện Fluent: " .. tostring(err))
    -- Try loading from fallback URL
    pcall(function()
        Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/alpha.lua"))()
        SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
        InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    end)
end

if not Fluent then
    error("Không thể tải thư viện Fluent. Vui lòng kiểm tra kết nối internet hoặc executor.")
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
        -- Recently saved, mark for future save
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
        warn("Lưu cấu hình thất bại:", err)
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
        
        -- Cập nhật cài đặt log
        if data.LogsEnabled ~= nil then
            LogSystem.Enabled = data.LogsEnabled
        end
        
        if data.WarningsEnabled ~= nil then
            LogSystem.WarningsEnabled = data.WarningsEnabled
        end
        
        return true
        end
    end
    
    -- Use default config if loading fails
        ConfigSystem.CurrentConfig = table.clone(ConfigSystem.DefaultConfig)
        ConfigSystem.SaveConfig()
        return false
    end

-- Set up a timer to save periodically if there are unsaved changes
spawn(function()
    while wait(5) do
        if ConfigSystem.PendingSave then
            ConfigSystem.SaveConfig()
        end
    end
end)

-- Load configuration on startup
ConfigSystem.LoadConfig()

-- Player info
local playerName = game:GetService("Players").LocalPlayer.Name

-- Tạo Window
local Window = Fluent:CreateWindow({
    Title = "HT Hub | All star tower defense X",
    SubTitle = "",
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
    Icon = "rbxassetid://7734053495" -- Bạn có thể thay icon khác nếu muốn
})

local MacroTab = Window:AddTab({
    Title = "Macro",
    Icon = "rbxassetid://7734053495" -- Change icon if desired
})
-- Add support logo when minimized
repeat task.wait(0.25) until game:IsLoaded()
getgenv().Image = "rbxassetid://90319448802378" -- Logo image asset ID
getgenv().ToggleUI = "LeftControl" -- Key to toggle UI

-- Create logo button to restore UI when minimized
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
            
            -- Clicking the logo will reopen the UI
            ImageButton.MouseButton1Click:Connect(function()
                game:GetService("VirtualInputManager"):SendKeyEvent(true,getgenv().ToggleUI,false,game)
            end)
        end
    end)
    
    if not success then
        warn("Lỗi khi tạo nút Logo UI: " .. tostring(errorMsg))
    end
end)

-- Auto-select Info tab on startup
Window:SelectTab(1) -- Chọn tab đầu tiên (Info)

-- Add info section in Info tab
local InfoSection = InfoTab:AddSection("Thông tin")

InfoSection:AddParagraph({
    Title = "All Star Tower Defense X",
    Content = "Phiên bản: 1.0 Beta\nTrạng thái: Hoạt động"
})

InfoSection:AddParagraph({
    Title = "Người phát triển",
    Content = "Script được phát triển bởi Dương Tuấn và ghjiukliop"
})

-- Add settings section in Settings tab
local SettingsTab = Window:AddTab({
    Title = "Settings",
    Icon = "rbxassetid://6031280882"
})

local SettingsSection = SettingsTab:AddSection("Thiết lập")

-- Dropdown chọn theme
SettingsSection:AddDropdown("ThemeDropdown", {
    Title = "Chọn Theme",
    Values = {"Dark", "Light", "Darker", "Aqua", "Amethyst"},
    Multi = false,
    Default = ConfigSystem.CurrentConfig.UITheme or "Dark",
    Callback = function(Value)
        ConfigSystem.CurrentConfig.UITheme = Value
        ConfigSystem.SaveConfig()
        print("Đã chọn theme: " .. Value)
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

-- Add event listener to save immediately upon value change
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

-- Hook __namecall CHỈ MỘT LẦN
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
MacroSection:AddToggle("MacroRecorderToggle", {
    Title = "🎥 Ghi Macro (Place / Upgrade / Sell)",
    Default = false,
    Tooltip = "Bật để bắt đầu ghi macro. Tắt để stop & save."
}):OnChanged(function(val)
    if val then
        if getgenv().recording then
            warn("🚫 Macro đã đang chạy.")
            return
        end
        getgenv().recording = true
        getgenv().macroSteps = {}
        getgenv().stepIndex = 0
        print("🎬 Macro recording started...")
    else
        if not getgenv().recording then
            warn("⚠️ Macro chưa bật.")
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
            warn("⚠ Executor không hỗ trợ writefile.")
        end
    end
end)


-- === HẾT PHẦN THAY THẾ ===

-- ...existing code...

-- ...existing code...

-- Tích hợp với SaveManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Thay đổi cách lưu cấu hình để sử dụng tên người chơi
InterfaceManager:SetFolder("HTHubAS")
SaveManager:SetFolder("HTHubAS/" .. playerName)

-- Thêm thông tin vào tab Settings
SettingsTab:AddParagraph({
    Title = "Cấu hình tự động",
    Content = "Cấu hình của bạn đang được tự động lưu theo tên nhân vật: " .. playerName
})

SettingsTab:AddParagraph({
    Title = "Phím tắt",
    Content = "Nhấn LeftControl để ẩn/hiện giao diện"
})

-- Thực thi tự động lưu cấu hình
AutoSaveConfig()

-- Thiết lập events
setupSaveEvents()

print("HT Hub | Anime Saga đã được tải thành công!")