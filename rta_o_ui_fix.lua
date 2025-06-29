--== CONFIG ==--
local webhookUrl = "https://discord.com/api/webhooks/1388880050824417280/OOshdBuNNWg5yewhkm1lpeUzV5CiR2ziq-WVo0rpRWWOHuYl_q9K7_pDQf2HpaLKtCbe" -- ใส่ webhook ของคุณ
local themes = {
    Default = {
        background = Color3.fromRGB(30, 30, 60),
        header = Color3.fromRGB(40, 40, 80),
        button = Color3.fromRGB(50, 120, 200),
        text = Color3.new(1, 1, 1),
        accent = Color3.fromRGB(0, 255, 200),
    },
    RoseGold = {
        background = Color3.fromRGB(70, 50, 60),
        header = Color3.fromRGB(100, 60, 80),
        button = Color3.fromRGB(180, 120, 130),
        text = Color3.new(1, 0.9, 0.9),
        accent = Color3.fromRGB(255, 190, 200),
    }
}

local theme = themes.Default

--== SERVICES ==--
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")
local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")

local request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
if not request then return warn("❌ Executor ไม่รองรับ http request") end

--== STATE ==--
local knownItems, itemCounter = {}, {}
local notifyNew, notifyAll = true, true
local uiVisible = true

--== CATEGORY ==--
local function classifyItem(name)
    local lower = string.lower(name)
    if string.find(lower, "seed") then return "Seed" end
    if string.find(lower, "sprinkle") then return "Sprinkle" end
    if string.find(lower, "egg") then return "Egg" end
    if string.find(lower, "gear") then return "Gear" end
end

local categoryNames = {
    Seed = "🌱 Seed",
    Sprinkle = "✨ Sprinkle",
    Egg = "🥚 Egg",
    Gear = "🛠 Gear"
}

--== UI SETUP ==--
if CoreGui:FindFirstChild("RT_UI_MAIN") then CoreGui.RT_UI_MAIN:Destroy() end
local mainGui = Instance.new("ScreenGui", CoreGui)
mainGui.Name = "RT_UI_MAIN"
mainGui.ResetOnSpawn = false

--== UI FRAME ==--
local frame = Instance.new("Frame", mainGui)
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 250, 0, 400)
frame.Position = UDim2.new(0.5, -125, 0.4, 0)
frame.BackgroundColor3 = theme.background
frame.Visible = true
frame.Active = true
frame.Draggable = true

local header = Instance.new("TextLabel", frame)
header.Size = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = theme.header
header.TextColor3 = theme.accent
header.Font = Enum.Font.GothamBold
header.TextSize = 16
header.Text = "🌌 RTaO HOOKS"
header.BorderSizePixel = 0

local status = Instance.new("TextLabel", frame)
status.Position = UDim2.new(0, 0, 0, 30)
status.Size = UDim2.new(1, 0, 0, 20)
status.BackgroundTransparency = 1
status.TextColor3 = theme.text
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.Text = "Status: 🟢 Online | " .. player.Name

--== 📦 DISPLAY ITEM SUMMARY ==--
local itemSummary = Instance.new("TextLabel", frame)
itemSummary.Position = UDim2.new(0.05, 0, 0, 55)
itemSummary.Size = UDim2.new(0.9, 0, 0, 60)
itemSummary.TextColor3 = theme.text
itemSummary.Font = Enum.Font.Gotham
itemSummary.TextSize = 12
itemSummary.BackgroundTransparency = 1
itemSummary.TextWrapped = true
itemSummary.TextYAlignment = Enum.TextYAlignment.Top
itemSummary.Text = "📦 รอข้อมูล..."

local function updateItemSummary()
    local seed, sprinkle, egg, gear = 0, 0, 0, 0
    for name, count in pairs(itemCounter) do
        local cat = classifyItem(name)
        if cat == "Seed" then seed += 1
        elseif cat == "Sprinkle" then sprinkle += 1
        elseif cat == "Egg" then egg += 1
        elseif cat == "Gear" then gear += 1
        end
    end
    itemSummary.Text = string.format("📦 ของทั้งหมด:\n🌱 Seed: %d ชนิด\n✨ Sprinkle: %d ชนิด\n🥚 Egg: %d ชนิด\n🛠 Gear: %d ชนิด", seed, sprinkle, egg, gear)
end

--== UPDATE SUMMARY WHEN ITEM ADDED ==--
backpack.ChildAdded:Connect(function(item)
    local name = item.Name
    local cat = classifyItem(name)
    if not cat then return end

    itemCounter[name] = (itemCounter[name] or 0) + 1
    if notifyNew and not knownItems[name] then
        knownItems[name] = true
    end

    updateItemSummary()
end)

updateItemSummary()

--== ปุ่มแสดง popup รายการทั้งหมด ย้ายขึ้นเหนือ summary ==--
local function makeButton(y, text, color, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.Size = UDim2.new(0.9, 0, 0, 28)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = text
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local btnPopup = makeButton(5, "📋 รายการของทั้งหมด", theme.button, function()
    popup.Visible = true
    updatePopup()
end)

--== POPUP แสดงของทั้งหมด ==--
local popup = Instance.new("Frame", mainGui)
popup.Size = UDim2.new(0, 280, 0, 250)
popup.Position = UDim2.new(0.5, -140, 0.5, -125)
popup.BackgroundColor3 = theme.background
popup.Visible = false
popup.Active = true
popup.Draggable = true
popup.BorderSizePixel = 0

local popupHeader = Instance.new("TextLabel", popup)
popupHeader.Size = UDim2.new(1, 0, 0, 30)
popupHeader.BackgroundColor3 = theme.header
popupHeader.TextColor3 = theme.accent
popupHeader.Font = Enum.Font.GothamBold
popupHeader.TextSize = 16
popupHeader.Text = "📋 รายการของทั้งหมด"
popupHeader.BorderSizePixel = 0

local closeBtn = Instance.new("TextButton", popup)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.Text = "❌"
closeBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 60)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.MouseButton1Click:Connect(function()
    popup.Visible = false
end)

local popupContent = Instance.new("TextLabel", popup)
popupContent.Position = UDim2.new(0, 10, 0, 35)
popupContent.Size = UDim2.new(1, -20, 1, -45)
popupContent.BackgroundTransparency = 1
popupContent.TextColor3 = theme.text
popupContent.Font = Enum.Font.Gotham
popupContent.TextSize = 13
popupContent.TextWrapped = true
popupContent.TextYAlignment = Enum.TextYAlignment.Top
popupContent.TextXAlignment = Enum.TextXAlignment.Left
popupContent.Text = "📦 กำลังโหลด..."

function updatePopup()
    local lines = {}
    local categorized = { Seed = {}, Sprinkle = {}, Egg = {}, Gear = {} }

    for name, count in pairs(itemCounter) do
        local cat = classifyItem(name)
        if cat then
            local realCount = name:match("%[X(%d+)%]")
            local cleanName = name:gsub("%[X%d+%]", ""):gsub("^%s*(.-)%s*$", "%1")
            local finalLine = cleanName .. " x" .. (realCount or count)
            table.insert(categorized[cat], finalLine)
        end
    end

    for _, cat in ipairs({"Seed", "Sprinkle", "Egg", "Gear"}) do
        if #categorized[cat] > 0 then
            table.insert(lines, categoryNames[cat])
            for _, item in ipairs(categorized[cat]) do
                table.insert(lines, "- " .. item)
            end
            table.insert(lines, "")
        end
    end

    popupContent.Text = #lines > 0 and table.concat(lines, "\n") or "📦 ยังไม่มีของใน Backpack"
end
