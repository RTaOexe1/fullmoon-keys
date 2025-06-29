local webhookUrl = "https://discord.com/api/webhooks/1388880050824417280/OOshdBuNNWg5yewhkm1lpeUzV5CiR2ziq-WVo0rpRWWOHuYl_q9K7_pDQf2HpaLKtCbe"

-- SERVICES --
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")
local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
if not request then return warn("❌ Executor ไม่รองรับ http request") end

-- ITEM CLASSIFY --
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

-- STORAGE --
local knownItems = {}
local itemCounter = {}
local notifyNew = true
local notifyAll = true

-- THEME SYSTEM --
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

-- UI --
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
title.Text = "🌌 RTaO_RS - Status"
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
		elseif cat == "Egg" then egg += 1
		end
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

local function updateButtonState(button, state)
	if state then
		button.TextColor3 = Color3.fromRGB(0, 255, 0) -- เขียว
		button.Text = button.Text:gsub("[❌✅]", "✅")
	else
		button.TextColor3 = Color3.fromRGB(255, 0, 0) -- แดง
		button.Text = button.Text:gsub("[❌✅]", "❌")
	end
end

local btnNew = makeButton(120, "🆕 แจ้งของใหม่: ✅", function()
	notifyNew = not notifyNew
	updateButtonState(btnNew, notifyNew)
	print("notifyNew:", notifyNew)
	updateStatusText()
end)

local btnAll = makeButton(150, "📦 แจ้งทุก 20 นาที: ✅", function()
	notifyAll = not notifyAll
	updateButtonState(btnAll, notifyAll)
	print("notifyAll:", notifyAll)
	updateStatusText()
end)

local statusDetail = Instance.new("TextLabel", frame)
statusDetail.Size = UDim2.new(1, -20, 0, 20)
statusDetail.Position = UDim2.new(0, 10, 0, 260)
statusDetail.BackgroundTransparency = 1
statusDetail.TextColor3 = themes[currentTheme].text
statusDetail.Font = Enum.Font.Gotham
statusDetail.TextSize = 12
statusDetail.Text = ""

local function updateStatusText()
	statusDetail.Text = string.format("🆕 แจ้งของใหม่: %s | 📦 แจ้งทุก 20 นาที: %s",
		notifyNew and "✅ เปิด" or "❌ ปิด",
		notifyAll and "✅ เปิด" or "❌ ปิด")
end

updateButtonState(btnNew, notifyNew)
updateButtonState(btnAll, notifyAll)
updateStatusText()

-- ฟังก์ชันส่ง webhook (เพิ่ม pcall และ print debug)
local function sendWebhook(data)
	local success, err = pcall(function()
		request({
			Url = webhookUrl,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(data)
		})
	end)
	if success then
		print("ส่ง webhook สำเร็จ")
	else
		warn("ส่ง webhook ล้มเหลว: ".. tostring(err))
	end
end

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
	print("ส่ง webhook รายงานทั้งหมด")
	sendWebhook(data)
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
	print("ส่ง webhook รายงานของใหม่:", name)
	sendWebhook(data)
end

makeButton(180, "🚀 ส่งรายงานทันที", function()
	sendAllWebhook("📦 รายงานของทั้งหมด (ส่งทันที)")
end)

-- Rest of your UI code here, including toggle UI, theme, etc.

-- INITIAL SCAN
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

-- AUTO SEND
task.spawn(function()
	while true do
		if notifyAll then
			sendAllWebhook("📦 รายงานอัตโนมัติทุก 20 นาที")
		end
		task.wait(1200)
	end
end)
