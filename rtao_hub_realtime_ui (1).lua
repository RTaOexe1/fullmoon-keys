-- RTaO HUB - Backpack Tracker (Real-time UI + Webhook, Fixed Version)

local webhookUrl = "https://discord.com/api/webhooks/1388880050824417280/OOshdBuNNWg5yewhkm1lpeUzV5CiR2ziq-WVo0rpRWWOHuYl_q9K7_pDQf2HpaLKtCbe" -- ใส่ Webhook ของคุณ

--== SERVICES ==--
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")
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

--== UI ==--
if CoreGui:FindFirstChild("RTaO_HUB_UI") then CoreGui.RTaO_HUB_UI:Destroy() end
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "RTaO_HUB_UI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 290)
frame.Position = UDim2.new(0.5, -120, 0.4, 0)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Name = "MainFrame"

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
	print("notifyNew:", notifyNew)
end)

local btnAll = makeButton(150, "📦 แจ้งทุก 20 นาที: ✅", function()
	notifyAll = not notifyAll
	btnAll.Text = "📦 แจ้งทุก 20 นาที: " .. (notifyAll and "✅" or "❌")
	print("notifyAll:", notifyAll)
end)

-- ปุ่ม toggle UI ใหม่แบบไม่หาย
local toggleButton = Instance.new("TextButton", gui)
toggleButton.Size = UDim2.new(0, 80, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0.9, -40)
toggleButton.Text = "🔁 UI"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
toggleButton.MouseButton1Click:Connect(function()
	local mainFrame = gui:FindFirstChild("MainFrame")
	if mainFrame then
		mainFrame.Visible = not mainFrame.Visible
	end
end)

-- (ส่วนที่เหลือเหมือนเดิม, ไม่เปลี่ยนเพื่อความย่อ)
-- อย่าลืมตรวจสอบว่า webhookUrl ถูกตั้งค่าเป็นของจริงแล้วด้วย!
