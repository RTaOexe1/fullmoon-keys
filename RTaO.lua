-- RTaO HUB - Backpack Tracker (Fixed Drag + Toggle + Theme + Webhook)

local webhookUrl = "https://discord.com/api/webhooks/your_webhook_here"

--== SERVICES ==--
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
if not request then return warn("❌ Executor ไม่รองรับ http request") end

--== ITEM CLASSIFY ==--
local function classifyItem(name)
    local lower = string.lower(name)
    if string.find(lower, "seed") then return "Seed" end
    if string.find(lower, "sprinkle") then return "Sprinkle" end
    if string.find(lower, "egg") then return "Egg" end
    return nil
end

local categoryNames = {
    Seed = "🌱 Seed",
    Sprinkle = "✨ Sprinkle",
    Egg = "🥚 Egg"
}

--== STORAGE ==--
local knownItems = {}
local itemCounter = {}
local notifyNew, notifyAll = true, true

--== THEMES ==--
local themes = {
    Dark = {
        background = Color3.fromRGB(30, 30, 60),
        topbar = Color3.fromRGB(40, 40, 80),
        button = Color3.fromRGB(60, 60, 100),
        text = Color3.new(1, 1, 1)
    },
    Light = {
        background = Color3.fromRGB(230, 230, 250),
        topbar = Color3.fromRGB(200, 200, 255),
        button = Color3.fromRGB(170, 170, 220),
        text = Color3.fromRGB(0.1, 0.1, 0.2)
    },
    Emerald = {
        background = Color3.fromRGB(22, 40, 35),
        topbar = Color3.fromRGB(30, 60, 50),
        button = Color3.fromRGB(40, 100, 80),
        text = Color3.fromRGB(180, 255, 200)
    }
}
local currentTheme = "Dark"

--== DESTROY OLD GUI ==--
if CoreGui:FindFirstChild("RTaO_HUB_UI") then CoreGui.RTaO_HUB_UI:Destroy() end

--== UI ==--
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "RTaO_HUB_UI"
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 320)
frame.Position = UDim2.new(0.5, -120, 0.4, 0)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Active = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "🌌 RTaO HUB - Status"
title.Font = Enum.Font.GothamBold
title.TextSize = 16

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, 0, 0, 20)
status.Position = UDim2.new(0, 0, 0, 30)
status.Text = "Status = Online 🟢 | " .. player.Name
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.BackgroundTransparency = 1

local summary = Instance.new("TextLabel", frame)
summary.Size = UDim2.new(1, -20, 0, 60)
summary.Position = UDim2.new(0, 10, 0, 50)
summary.BackgroundTransparency = 1
summary.Font = Enum.Font.Gotham
summary.TextSize = 13
summary.TextWrapped = true
summary.TextYAlignment = Enum.TextYAlignment.Top

local function updateSummary()
    local seed, sprinkle, egg = 0, 0, 0
    for name, count in pairs(itemCounter) do
        local cat = classifyItem(name)
        if cat == "Seed" then seed += 1
        elseif cat == "Sprinkle" then sprinkle += 1
        elseif cat == "Egg" then egg += 1 end
    end
    summary.Text = string.format("📦 รายการใน Backpack:\n🌱 Seed: %d\n✨ Sprinkle: %d\n🥚 Egg: %d", seed, sprinkle, egg)
end

local function applyTheme(name)
    local t = themes[name]
    if not t then return end
    frame.BackgroundColor3 = t.background
    title.BackgroundColor3 = t.topbar
    title.TextColor3 = t.text
    status.TextColor3 = t.text
    summary.TextColor3 = t.text
    for _, v in pairs(frame:GetChildren()) do
        if v:IsA("TextButton") then
            v.BackgroundColor3 = t.button
            v.TextColor3 = t.text
        end
    end
end

--== WEBHOOK FUNCTIONS FIRST ==--
function sendAllWebhook(customTitle)
    local fields = { Seed = {}, Sprinkle = {}, Egg = {} }
    for name, count in pairs(itemCounter) do
        local cat = classifyItem(name)
        if cat then table.insert(fields[cat], name .. " x" .. count) end
    end

    local embedFields = {}
    for cat, items in pairs(fields) do
        if #items > 0 then
            table.insert(embedFields, {
                name = categoryNames[cat],
                value = table.concat(items, "\n"),
                inline = false
            })
        end
    end
    if #embedFields == 0 then return end

    local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"

    local data = {
        username = "RTaO HUB",
        avatar_url = avatarUrl,
        embeds = {{
            title = customTitle or "📦 รายการของทั้งหมดใน Backpack",
            color = 3066993,
            fields = embedFields,
            thumbnail = { url = avatarUrl },
            footer = { text = "👤 Roblox: " .. player.Name },
            timestamp = os.date("!%Y-%m-%dT%TZ")
        }}
    }

    request({
        Url = webhookUrl,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(data)
    })
end

--== BUTTONS ==--
local function makeButton(y, label, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.9, 0, 0, 28)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = label
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local btnNew = makeButton(120, "🆕 แจ้งของใหม่: ✅", function()
    notifyNew = not notifyNew
    btnNew.Text = "🆕 แจ้งของใหม่: " .. (notifyNew and "✅" or "❌")
end)

local btnAll = makeButton(150, "📦 แจ้งทุก 20 นาที: ✅", function()
    notifyAll = not notifyAll
    btnAll.Text = "📦 แจ้งทุก 20 นาที: " .. (notifyAll and "✅" or "❌")
end)

makeButton(180, "🚀 ส่งรายงานทันที", function()
    sendAllWebhook("📦 รายงานของทั้งหมด (ส่งทันที)")
end)

makeButton(210, "🎨 เปลี่ยนธีม", function()
    local keys = {}
    for name in pairs(themes) do table.insert(keys, name) end
    local index = 1
    for i, n in ipairs(keys) do if n == currentTheme then index = i break end end
    currentTheme = keys[(index % #keys) + 1]
    applyTheme(currentTheme)
end)

makeButton(270, "❌ ปิด UI", function()
    gui.Enabled = false
end)

--== TOGGLE UI BUTTON ==--
local toggleButton = Instance.new("TextButton", gui)
toggleButton.Size = UDim2.new(0, 80, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0.9, -40)
toggleButton.Text = "🔁 UI"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
toggleButton.MouseButton1Click:Connect(function()
    gui.Enabled = not gui.Enabled
end)

--== DRAG FUNCTION ==--
local dragging, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                   startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--== SCAN ITEMS ==--
for _, item in ipairs(backpack:GetChildren()) do
    local cat = classifyItem(item.Name)
    if cat then
        knownItems[item.Name] = true
        itemCounter[item.Name] = (itemCounter[item.Name] or 0) + 1
    end
end
updateSummary()

backpack.ChildAdded:Connect(function(item)
    local name = item.Name
    local cat = classifyItem(name)
    if not cat then return end
    itemCounter[name] = (itemCounter[name] or 0) + 1
    if notifyNew and not knownItems[name] then
        knownItems[name] = true
        sendAllWebhook("🆕 พบของใหม่ใน Backpack!\n• " .. name .. " x1")
    end
    updateSummary()
end)

--== AUTO LOOP ==--
task.spawn(function()
    while true do
        if notifyAll then sendAllWebhook("📦 รายงานอัตโนมัติทุก 20 นาที") end
        task.wait(1200)
    end
end)

applyTheme(currentTheme)
