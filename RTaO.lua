-- RTaO HUB - Backpack Tracker (Full UI Functionality + Drag Fix)

local webhookUrl = "https://discord.com/api/webhooks/xxxxxxxxxx" -- ใส่ Webhook ของคุณ

--== SERVICES ==--
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
if not request then return warn("❌ Executor ไม่รองรับ http request") end

--== CLASSIFY ==--
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

--== THEME ==--
local themes = {
  Dark = {
    background = Color3.fromRGB(30, 30, 60),
    topbar = Color3.fromRGB(40, 40, 80),
    button = Color3.fromRGB(60, 60, 100),
    text = Color3.new(1, 1, 1)
  }
}
local currentTheme = "Dark"

--== CLEANUP ==--
if CoreGui:FindFirstChild("RTaO_HUB_UI") then CoreGui.RTaO_HUB_UI:Destroy() end

--== UI SETUP ==--
local gui = Instance.new("ScreenGui")
gui.Name = "RTaO_HUB_UI"
gui.Parent = CoreGui
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 340)
frame.Position = UDim2.new(0.5, -130, 0.4, 0)
frame.BackgroundColor3 = themes[currentTheme].background
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = false

--== DRAG SUPPORT ==--
local dragging, dragStart, startPos

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
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
  end
end)

--== TITLE BAR ==--
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "🌌 RTaO HUB - Status"
title.BackgroundColor3 = themes[currentTheme].topbar
title.TextColor3 = themes[currentTheme].text
title.Font = Enum.Font.GothamBold
title.TextSize = 16

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, 0, 0, 20)
status.Position = UDim2.new(0, 0, 0, 30)
status.Text = "Status = Online 🟢 | " .. player.Name
status.BackgroundTransparency = 1
status.TextColor3 = themes[currentTheme].text
status.Font = Enum.Font.Gotham
status.TextSize = 14

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

--== BUTTON ==--
local function makeButton(y, text, callback)
  local btn = Instance.new("TextButton", frame)
  btn.Size = UDim2.new(0.9, 0, 0, 28)
  btn.Position = UDim2.new(0.05, 0, 0, y)
  btn.Font = Enum.Font.GothamBold
  btn.TextSize = 14
  btn.BackgroundColor3 = themes[currentTheme].button
  btn.TextColor3 = themes[currentTheme].text
  btn.Text = text
  btn.MouseButton1Click:Connect(callback)
  return btn
end

--== BUTTON LIST ==--
local btnNew = makeButton(120, "🆕 แจ้งของใหม่: ✅", function()
  notifyNew = not notifyNew
  btnNew.Text = "🆕 แจ้งของใหม่: " .. (notifyNew and "✅" or "❌")
end)

local btnAll = makeButton(150, "📦 แจ้งทุก 20 นาที: ✅", function()
  notifyAll = not notifyAll
  btnAll.Text = "📦 แจ้งทุก 20 นาที: " .. (notifyAll and "✅" or "❌")
end)

makeButton(180, "🚀 ส่งรายงานทันที", function()
  sendAllWebhook()
end)

makeButton(210, "❌ ปิด UI", function()
  frame.Visible = false
end)

--== TOGGLE UI BUTTON ==--
local toggleButton = Instance.new("TextButton", gui)
toggleButton.Size = UDim2.new(0, 80, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0.9, -40)
toggleButton.Text = "🔁 UI"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.MouseButton1Click:Connect(function()
  frame.Visible = not frame.Visible
end)

--== SUMMARY UPDATE ==--
local function updateSummary()
  local seed, sprinkle, egg = 0, 0, 0
  for name, _ in pairs(itemCounter) do
    local cat = classifyItem(name)
    if cat == "Seed" then seed += 1
    elseif cat == "Sprinkle" then sprinkle += 1
    elseif cat == "Egg" then egg += 1 end
  end
  summary.Text = string.format("📦 รายการใน Backpack:\n🌱 Seed: %d ชนิด\n✨ Sprinkle: %d ชนิด\n🥚 Egg: %d ชนิด", seed, sprinkle, egg)
end

--== WEBHOOK SEND ==--
function sendAllWebhook()
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

  local data = {
    username = "RTaO HUB",
    embeds = {{
      title = "📦 รายการของทั้งหมดใน Backpack",
      color = 3066993,
      fields = embedFields,
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

--== INITIAL BACKPACK SCAN ==--
for _, item in ipairs(backpack:GetChildren()) do
  local cat = classifyItem(item.Name)
  if cat then
    knownItems[item.Name] = true
    itemCounter[item.Name] = (itemCounter[item.Name] or 0) + 1
  end
end
updateSummary()

--== BACKPACK LISTENER ==--
backpack.ChildAdded:Connect(function(item)
  local name = item.Name
  local cat = classifyItem(name)
  if not cat then return end
  itemCounter[name] = (itemCounter[name] or 0) + 1
  if notifyNew and not knownItems[name] then
    knownItems[name] = true
  end
  updateSummary()
end)

--== AUTO LOOP ==--
task.spawn(function()
  while true do
    if notifyAll then
      sendAllWebhook()
    end
    task.wait(1200)
  end
end)
