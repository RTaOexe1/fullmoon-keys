-- RTaO HUB - Backpack Tracker (Real-time UI + Webhook)

local webhookUrl = "https://discord.com/api/webhooks/1388880050824417280/OOshdBuNNWg5yewhkm1lpeUzV5CiR2ziq-WVo0rpRWWOHuYl_q9K7_pDQf2HpaLKtCbe" -- ใส่ Webhook ของคุณ

--== SERVICES ==--
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")
local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local UIS = game:GetService("UserInputService")

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
local notifyNew = true
local notifyAll = true

--== THEME SYSTEM ==--
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

--== UI หลัก ==--
if CoreGui:FindFirstChild("RTaO_HUB_UI") then CoreGui.RTaO_HUB_UI:Destroy() end
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "RTaO_HUB_UI"
gui.ResetOnSpawn = false
gui.Enabled = true

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 320) -- ขยายสูงขึ้นจาก 290
frame.Position = UDim2.new(0.5, -120, 0.4, 0)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Active = true
frame.ClipsDescendants = false -- เพิ่มเผื่อป้องกันตัด UI เวลากดลาก

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
summary.TextColor3 = themes[currentTheme].text
summary.Font = Enum.Font.Gotham
summary.TextSize = 13
summary.TextWrapped = true
summary.TextYAlignment = Enum.TextYAlignment.Top
summary.Text = "📦 รอข้อมูล..."

local function updateSummary()
  local seed, sprinkle, egg = 0, 0, 0
  for name, count in pairs(itemCounter) do
    local cat = classifyItem(name)
    if cat == "Seed" then seed += 1
    elseif cat == "Sprinkle" then sprinkle += 1
    elseif cat == "Egg" then egg += 1 end
  end
  summary.Text = string.format("📦 รายการใน Backpack:\n🌱 Seed: %d ชนิด\n✨ Sprinkle: %d ชนิด\n🥚 Egg: %d ชนิด", seed, sprinkle, egg)
end

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

makeButton(210, "📋 ดูรายละเอียดทั้งหมด", function()
  local popup = Instance.new("Frame", gui)
  popup.Size = UDim2.new(0, 300, 0, 280)
  popup.Position = UDim2.new(0.5, -150, 0.5, -140)
  popup.BackgroundColor3 = themes[currentTheme].background
  popup.BorderSizePixel = 0

  local title = Instance.new("TextLabel", popup)
  title.Size = UDim2.new(1, 0, 0, 30)
  title.Text = "📋 รายละเอียดไอเทม"
  title.BackgroundColor3 = themes[currentTheme].topbar
  title.TextColor3 = themes[currentTheme].text
  title.Font = Enum.Font.GothamBold
  title.TextSize = 14

  local scroll = Instance.new("ScrollingFrame", popup)
  scroll.Size = UDim2.new(1, -10, 1, -40)
  scroll.Position = UDim2.new(0, 5, 0, 35)
  scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
  scroll.ScrollBarThickness = 6
  scroll.BackgroundTransparency = 1

  local layout = Instance.new("UIListLayout", scroll)
  layout.Padding = UDim.new(0, 4)
  layout.SortOrder = Enum.SortOrder.Name

  -- เคลียร์ของเก่า ถ้ามี (กันปัญหาเปิดหลายครั้ง)
  for _, child in pairs(scroll:GetChildren()) do
    if child:IsA("TextLabel") then child:Destroy() end
  end

  local order = {"Seed", "Sprinkle", "Egg"}
  for _, category in ipairs(order) do
    local items = {}
    for name, count in pairs(itemCounter) do
      if classifyItem(name) == category then
        table.insert(items, {name = name, count = count})
      end
    end
    table.sort(items, function(a,b) return a.name < b.name end)
    for _, item in ipairs(items) do
      local label = Instance.new("TextLabel", scroll)
      label.Size = UDim2.new(1, -10, 0, 20)
      label.BackgroundTransparency = 1
      label.TextColor3 = themes[currentTheme].text
      label.Font = Enum.Font.Gotham
      label.TextSize = 13
      label.Text = string.format("• %s x%d", item.name, item.count)
    end
  end

  -- อัพเดต CanvasSize ให้พอดีรายการ
  task.wait() -- รอ UIListLayout คำนวณขนาดก่อน
  scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)

  local close = Instance.new("TextButton", popup)
  close.Size = UDim2.new(0, 80, 0, 25)
  close.Position = UDim2.new(1, -85, 0, 5)
  close.Text = "❌ ปิด"
  close.Font = Enum.Font.GothamBold
  close.TextSize = 12
  close.TextColor3 = Color3.new(1,1,1)
  close.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
  close.MouseButton1Click:Connect(function()
    popup:Destroy()
  end)
end)

makeButton(240, "🎨 เปลี่ยนธีม", function()
  local themeNames = {}
  for name in pairs(themes) do table.insert(themeNames, name) end
  local index = table.find(themeNames, currentTheme) or 1
  local nextIndex = (index % #themeNames) + 1
  currentTheme = themeNames[nextIndex]
  applyTheme(currentTheme)
end)

makeButton(270, "❌ ปิด UI", function()
  gui.Enabled = false
end)

--== ปุ่ม Toggle UI แยก GUI ==
if CoreGui:FindFirstChild("RTaO_HUB_Toggle") then CoreGui.RTaO_HUB_Toggle:Destroy() end
local toggleGui = Instance.new("ScreenGui", CoreGui)
toggleGui.Name = "RTaO_HUB_Toggle"
toggleGui.ResetOnSpawn = false
toggleGui.Enabled = true

local toggleButton = Instance.new("TextButton", toggleGui)
toggleButton.Size = UDim2.new(0, 80, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0.9, -40)
toggleButton.Text = "🔁 UI"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
toggleButton.Active = true
toggleButton.Draggable = true -- ปุ่มเลื่อนเองได้

toggleButton.MouseButton1Click:Connect(function()
  gui.Enabled = not gui.Enabled
end)

--== Drag UI System (ลาก UI หลัก) ==
local dragging, dragInput, dragStart, startPos

frame.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 then
    dragging = true
    dragStart = input.Position
    startPos = frame.Position
    input.Changed:Connect(function()
      if input.UserInputState == Enum.UserInputState.End then
        dragging = false
      end
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

--== WEBHOOK SYSTEM ==--
function sendAllWebhook(customTitle)
  local fields = { Seed = {}, Sprinkle = {}, Egg = {} }
  for name, count in pairs(itemCounter) do
    local cat = classifyItem(name)
    if cat then
      table.insert(fields[cat], name .. " x" .. count)
    end
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

local function sendNewItemWebhook(name)
  local cat = classifyItem(name)
  if not cat then return end

  local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"

  local data = {
    username = "RTaO HUB",
    avatar_url = avatarUrl,
    embeds = {{
      title = "🆕 พบของใหม่ใน Backpack!",
      color = 16753920,
      fields = {{
        name = categoryNames[cat],
        value = "**" .. name .. "** x1",
        inline = false
      }},
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

--== INITIAL SCAN ==--
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
    sendNewItemWebhook(name)
  end
  updateSummary()
end)

--== AUTO SEND ==--
task.spawn(function()
  while true do
    if notifyAll then
      sendAllWebhook("📦 รายงานอัตโนมัติทุก 20 นาที")
    end
    task.wait(1200)
  end
end)

applyTheme(currentTheme)
