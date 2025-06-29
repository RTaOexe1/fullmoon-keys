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

-- DRAGGABLE TOGGLE BUTTON
local toggleIcon = Instance.new("ImageButton", mainGui)
toggleIcon.Name = "ToggleButton"
toggleIcon.Image = "rbxassetid://160515991"
toggleIcon.Size = UDim2.new(0, 40, 0, 40)
toggleIcon.Position = UDim2.new(0, 20, 0.5, -20)
toggleIcon.BackgroundTransparency = 1
toggleIcon.Active = true
toggleIcon.Draggable = true

--== UI FRAME ==--
local frame = Instance.new("Frame", mainGui)
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 250, 0, 420)
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

--== BUTTON FACTORY ==--
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

local btnNew = makeButton(60, "🆕 แจ้งของใหม่: ✅ เปิด", theme.button, function()
    notifyNew = not notifyNew
    btnNew.Text = "🆕 แจ้งของใหม่: " .. (notifyNew and "✅ เปิด" or "❌ ปิด")
end)

local btnAll = makeButton(95, "📦 ส่งทุก 20 นาที: ✅ เปิด", theme.button, function()
    notifyAll = not notifyAll
    btnAll.Text = "📦 ส่งทุก 20 นาที: " .. (notifyAll and "✅ เปิด" or "❌ ปิด")
end)

local btnSend = makeButton(130, "🚀 ส่งรายงานทันที", theme.button, function()
    sendAllWebhook("📦 รายงานทั้งหมด (ทันที)")
end)

local btnTheme = makeButton(165, "🎨 เปลี่ยนธีม", theme.button, function()
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

--== TOGGLE UI ==--
toggleIcon.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    frame.Visible = uiVisible
end)

--== ITEM SUMMARY ==--
local itemSummary = Instance.new("TextLabel", frame)
itemSummary.Position = UDim2.new(0.05, 0, 0, 205)
itemSummary.Size = UDim2.new(0.9, 0, 0, 50)
itemSummary.TextColor3 = theme.text
itemSummary.Font = Enum.Font.Gotham
itemSummary.TextSize = 12
itemSummary.BackgroundTransparency = 1
itemSummary.TextWrapped = true
itemSummary.TextYAlignment = Enum.TextYAlignment.Top
itemSummary.Text = "📦 รอข้อมูล..."

local function updateItemSummary()
    local seed, sprinkle, egg = 0, 0, 0
    for name, _ in pairs(itemCounter) do
        local cat = classifyItem(name)
        if cat == "Seed" then seed += 1
        elseif cat == "Sprinkle" then sprinkle += 1
        elseif cat == "Egg" then egg += 1 end
    end
    itemSummary.Text = string.format("📦 ของทั้งหมด:\n🌱 Seed: %d ชนิด\n✨ Sprinkle: %d ชนิด\n🥚 Egg: %d ชนิด", seed, sprinkle, egg)
end

--== WEBHOOK HELPERS ==--
local function cleanNameAndCount(name, fallbackCount)
    local real = name:match("%[X(%d+)%]")
    local clean = name:gsub("%[X%d+%]", ""):gsub("^%s*(.-)%s*$", "%1")
    return clean, tonumber(real) or fallbackCount
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

    request({
        Url = webhookUrl,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
            username = "RTaO HUB",
            embeds = {{
                title = title,
                color = 3066993,
                fields = embedFields,
                footer = { text = "👤 Roblox: " .. player.Name },
                timestamp = DateTime.now():ToIsoDate()
            }}
        })
    })
end

function sendAllWebhook(title)
    local fields = { Seed = {}, Sprinkle = {}, Egg = {} }
    for name, count in pairs(itemCounter) do
        local cat = classifyItem(name)
        if cat then
            local clean, actual = cleanNameAndCount(name, count)
            table.insert(fields[cat], clean .. " x" .. actual)
        end
    end
    sendWebhook(fields, title)
end

local function sendNewItemWebhook(name)
    local cat = classifyItem(name)
    if not cat then return end
    local clean, actual = cleanNameAndCount(name, 1)
    request({
        Url = webhookUrl,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
            username = "RTaO HUB",
            embeds = {{
                title = "🆕 พบของใหม่ใน Backpack!",
                color = 16753920,
                fields = {{
                    name = categoryNames[cat],
                    value = "**" .. clean .. "** x" .. actual,
                    inline = false
                }},
                footer = { text = "👤 Roblox: " .. player.Name },
                timestamp = DateTime.now():ToIsoDate()
            }}
        })
    })
end

--== TRACK ITEMS ==--
for _, item in ipairs(backpack:GetChildren()) do
    local name = item.Name
    local cat = classifyItem(name)
    if cat then
        knownItems[name] = true
        itemCounter[name] = (itemCounter[name] or 0) + 1
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
    updateItemSummary()
    updatePopup()
end)

--== AUTO WEBHOOK LOOP ==--
task.spawn(function()
    while true do
        if notifyAll then
            sendAllWebhook("📦 รายงานอัตโนมัติทุก 20 นาที")
        end
        task.wait(1200)
    end
end)

--== POPUP รายการของทั้งหมด ==--
local popup = Instance.new("Frame", mainGui)
popup.Size = UDim2.new(0, 280, 0, 200)
popup.Position = UDim2.new(0.5, -140, 0.5, -100)
popup.BackgroundColor3 = theme.background
popup.Visible = false
popup.Active = true
popup.Draggable = true
popup.Name = "ItemPopup"

local popupHeader = Instance.new("TextLabel", popup)
popupHeader.Size = UDim2.new(1, 0, 0, 30)
popupHeader.BackgroundColor3 = theme.header
popupHeader.TextColor3 = theme.accent
popupHeader.Font = Enum.Font.GothamBold
popupHeader.TextSize = 16
popupHeader.Text = "📋 รายการของทั้งหมด"

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
    local categorized = { Seed = {}, Sprinkle = {}, Egg = {} }

    for name, count in pairs(itemCounter) do
        local cat = classifyItem(name)
        if cat then
            local clean, actual = cleanNameAndCount(name, count)
            table.insert(categorized[cat], clean .. " x" .. actual)
        end
    end

    for _, cat in ipairs({ "Seed", "Sprinkle", "Egg" }) do
        if #categorized[cat] > 0 then
            table.insert(lines, categoryNames[cat])
            for _, item in ipairs(categorized[cat]) do
                table.insert(lines, "- " .. item)
            end
            table.insert(lines, "")
        end
    end

    popupContent.Text = #lines == 0 and "📦 ยังไม่มีของใน Backpack" or table.concat(lines, "\n")
end

makeButton(310, "📋 รายการของทั้งหมด", theme.button, function()
    updatePopup()
    popup.Visible = true
end)

--== ปุ่ม 🔃 UI Toggle ==--
local toggleUIBtn = Instance.new("TextButton", mainGui)
toggleUIBtn.Name = "ToggleUI"
toggleUIBtn.Size = UDim2.new(0, 80, 0, 30)
toggleUIBtn.Position = UDim2.new(0, 20, 1, -50)
toggleUIBtn.BackgroundColor3 = theme.button
toggleUIBtn.TextColor3 = theme.text
toggleUIBtn.Font = Enum.Font.GothamBold
toggleUIBtn.TextSize = 14
toggleUIBtn.Text = "🔃 UI"
toggleUIBtn.TextStrokeTransparency = 0.5
toggleUIBtn.Active = true
toggleUIBtn.Draggable = true
toggleUIBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    frame.Visible = uiVisible
end)
