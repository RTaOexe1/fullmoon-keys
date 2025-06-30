--== CONFIG ==--
local webhookUrl = "https://discord.com/api/webhooks/1388880050824417280/OOshdBuNNWg5yewhkm1lpeUzV5CiR2ziq-WVo0rpRWWOHuYl_q9K7_pDQf2HpaLKtCbe"
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
end

local categoryNames = {
    Seed = "🌱 Seed",
    Sprinkle = "✨ Sprinkle",
    Egg = "🥚 Egg"
}

--== UI SETUP ==--
if CoreGui:FindFirstChild("RT_UI_MAIN") then CoreGui.RT_UI_MAIN:Destroy() end
local mainGui = Instance.new("ScreenGui", CoreGui)
mainGui.Name = "RT_UI_MAIN"
mainGui.ResetOnSpawn = false

-- UI หลัก
local frame = Instance.new("Frame", mainGui)
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 250, 0, 275)
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
header.Text = "🌌 RTaO_RS"
header.BorderSizePixel = 0

local status = Instance.new("TextLabel", frame)
status.Position = UDim2.new(0, 0, 0, 30)
status.Size = UDim2.new(1, 0, 0, 20)
status.BackgroundTransparency = 1
status.TextColor3 = theme.text
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.Text = "Status: 🟢 Online | " .. player.Name

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

local btnNew, btnAll, btnSend, btnTheme
local contentButtons = {}

btnNew = makeButton(60, "🆕 แจ้งของใหม่: ✅ เปิด", theme.button, function()
    notifyNew = not notifyNew
    btnNew.Text = "🆕 แจ้งของใหม่: " .. (notifyNew and "✅ เปิด" or "❌ ปิด")
end)
table.insert(contentButtons, btnNew)

btnAll = makeButton(95, "📦 ส่งทุก 20 นาที: ✅ เปิด", theme.button, function()
    notifyAll = not notifyAll
    btnAll.Text = "📦 ส่งทุก 20 นาที: " .. (notifyAll and "✅ เปิด" or "❌ ปิด")
end)
table.insert(contentButtons, btnAll)

btnSend = makeButton(130, "🚀 ส่งรายงานทันที", theme.button, function()
    sendAllWebhook("📦 รายงานทั้งหมด (ทันที)")
end)
table.insert(contentButtons, btnSend)

btnTheme = makeButton(165, "🎨 เปลี่ยนธีม", theme.button, function()
    theme = (theme == themes.Default and themes.RoseGold) or themes.Default
    frame.BackgroundColor3 = theme.background
    header.BackgroundColor3 = theme.header
    header.TextColor3 = theme.accent
    status.TextColor3 = theme.text
    for _, btn in ipairs(frame:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.BackgroundColor3 = theme.button
        end
    end
end)
table.insert(contentButtons, btnTheme)

local btnClose = makeButton(200, "❌ ปิด UI", Color3.fromRGB(160, 60, 60), function()
    frame.Visible = false
    toggleSmallBtn.Visible = true
end)
table.insert(contentButtons, btnClose)

--== ปุ่มเล็กแยกสำหรับเปิด-ปิด UI ==
local toggleSmallBtn = Instance.new("TextButton", CoreGui)
toggleSmallBtn.Name = "ToggleSmallBtn"
toggleSmallBtn.Text = "🗂 เปิด/ปิด UI"
toggleSmallBtn.Size = UDim2.new(0, 80, 0, 30)
toggleSmallBtn.Position = UDim2.new(0, 20, 0.6, 0)
toggleSmallBtn.BackgroundColor3 = theme.button
toggleSmallBtn.TextColor3 = Color3.new(1,1,1)
toggleSmallBtn.Font = Enum.Font.GothamBold
toggleSmallBtn.TextSize = 14
toggleSmallBtn.Visible = false

toggleSmallBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    frame.Visible = uiVisible
    toggleSmallBtn.Visible = not uiVisible
end)

--== WEBHOOK HELPERS ==--
local function cleanItemName(name)
    name = name:gsub(" x%d+$", "")
    name = name:gsub(" %[X%d+%]", "")
    return name
end

local function sendWebhook(fields, title)
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

    local data = {
        username = "RTaO_RS",
        embeds = {{
            title = title,
            color = 3066993,
            fields = embedFields,
            footer = { text = "👤 Roblox: " .. player.Name },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    request({
        Url = webhookUrl,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(data)
    })
end

function sendAllWebhook(customTitle)
    local fields = { Seed = {}, Sprinkle = {}, Egg = {} }
    for name, count in pairs(itemCounter) do
        local cat = classifyItem(name)
        if cat then
            local cleanedName = cleanItemName(name)
            table.insert(fields[cat], cleanedName .. " x" .. count)
        end
    end
    sendWebhook(fields, customTitle or "📦 รายการของทั้งหมดใน Backpack")
end

local function sendNewItemWebhook(name)
    local cat = classifyItem(name)
    if not cat then return end
    local data = {
        username = "RTaO_RS",
        embeds = {{
            title = "🆕 พบของใหม่ใน Backpack!",
            color = 16753920,
            fields = {{
                name = categoryNames[cat],
                value = "**" .. cleanItemName(name) .. "**",
                inline = false
            }},
            footer = { text = "👤 Roblox: " .. player.Name },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }
    request({
        Url = webhookUrl,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(data)
    })
end

--== INIT DATA ==--
for _, item in ipairs(backpack:GetChildren()) do
    local cat = classifyItem(item.Name)
    if cat then
        knownItems[item.Name] = true
        itemCounter[item.Name] = (itemCounter[item.Name] or 0) + 1
    end
end

backpack.ChildAdded:Connect(function(item)
    local name = item.Name
    local cat = classifyItem(name)
    if not cat then return end
    itemCounter[name] = (itemCounter[name] or 0) + 1
    if notifyNew and not knownItems[name] then
        knownItems[name] = true
        sendNewItemWebhook(name)
    end
end)

task.spawn(function()
    while true do
        if notifyAll then
            sendAllWebhook("📦 รายงานอัตโนมัติทุก 20 นาที")
        end
        task.wait(1200)
    end
end)
