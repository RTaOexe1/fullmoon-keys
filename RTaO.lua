-- RTaO HUB - Backpack Tracker (UI + Webhook)
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
local knownItems, itemCounter = {}, {}
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

--== UI SETUP ==--
if CoreGui:FindFirstChild("RTaO_HUB_UI") then CoreGui.RTaO_HUB_UI:Destroy() end
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "RTaO_HUB_UI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 320)
frame.Position = UDim2.new(0.5, -130, 0.4, 0)
frame.BackgroundColor3 = themes[currentTheme].background
frame.BorderSizePixel = 0
frame.Active, frame.Draggable = true, true

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
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.BackgroundTransparency = 1
status.TextColor3 = themes[currentTheme].text

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
	for name in pairs(itemCounter) do
		local cat = classifyItem(name)
		if cat == "Seed" then seed += 1
		elseif cat == "Sprinkle" then sprinkle += 1
		elseif cat == "Egg" then egg += 1 end
	end
	summary.Text = string.format("📦 รายการใน Backpack:\n🌱 Seed: %d\n✨ Sprinkle: %d\n🥚 Egg: %d", seed, sprinkle, egg)
end

local function makeButton(y, text, callback)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(0.9, 0, 0, 28)
	b.Position = UDim2.new(0.05, 0, 0, y)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.TextColor3 = themes[currentTheme].text
	b.BackgroundColor3 = themes[currentTheme].button
	b.Text = text
	b.MouseButton1Click:Connect(callback)
	return b
end

local btnNew, btnAll

btnNew = makeButton(120, "🆕 แจ้งของใหม่: เปิด ✅", function()
	notifyNew = not notifyNew
	btnNew.Text = "🆕 แจ้งของใหม่: " .. (notifyNew and "เปิด ✅" or "ปิด ❌")
end)

btnAll = makeButton(150, "📦 แจ้งทุก 20 นาที: เปิด ✅", function()
	notifyAll = not notifyAll
	btnAll.Text = "📦 แจ้งทุก 20 นาที: " .. (notifyAll and "เปิด ✅" or "ปิด ❌")
end)

makeButton(180, "🚀 ส่งรายงานทันที", function()
	sendAllWebhook("📦 รายงานของทั้งหมด (ส่งทันที)")
end)

-- ปุ่มแสดง/ซ่อน
local toggleButton = Instance.new("TextButton", gui)
toggleButton.Size = UDim2.new(0, 40, 0, 40)
toggleButton.Position = UDim2.new(0, 20, 0.5, -20)
toggleButton.Text = "📌"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 20
toggleButton.BackgroundColor3 = themes[currentTheme].topbar
toggleButton.TextColor3 = themes[currentTheme].text
toggleButton.Active = true
toggleButton.Draggable = true
local minimized = false
toggleButton.MouseButton1Click:Connect(function()
	minimized = not minimized
	frame.Visible = not minimized
end)

--== WEBHOOK FUNCTIONS ==--
function sendAllWebhook(titleText)
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
	local payload = {
		username = "RTaO HUB",
		avatar_url = avatarUrl,
		embeds = {{
			title = titleText,
			color = 3066993,
			fields = embedFields,
			thumbnail = { url = avatarUrl },
			footer = { text = "👤 Roblox: " .. player.Name },
			timestamp = os.date("!%Y-%m-%dT%TZ")
		}}
	}

	local success, err = pcall(function()
		request({
			Url = webhookUrl,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(payload)
		})
	end)
	if not success then
		warn("❌ Webhook ส่งไม่สำเร็จ:", err)
	end
end

function sendNewItemWebhook(name)
	local cat = classifyItem(name)
	if not cat then return end
	local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
	local payload = {
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
	local success, err = pcall(function()
		request({
			Url = webhookUrl,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(payload)
		})
	end)
	if not success then
		warn("❌ ส่ง Webhook ไม่สำเร็จ:", err)
	end
end

--== BACKPACK TRACKING ==--
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
