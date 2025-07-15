-- Carregar a biblioteca Fluent UI 
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Criar a janela principal do script
local window = Fluent:CreateWindow({
    Title = "Blue Lock: Rivals Hub",
    SubTitle = "by Grok",
    TabWidth = 160,
    Size = UDim2.new(0, 580, 0, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Serviços do Roblox
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")

-- Variáveis do jogador
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local ball = Workspace:FindFirstChild("Ball") -- Ajustar nome do objeto da bola
local staminaService = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("StaminaService"):WaitForChild("RE"):WaitForChild("DecreaseStamina")

-- Variáveis de controle
local autoGoalActive = false
local autoDribbleActive = false
local autoFarmActive = false
local autoSlideActive = false
local espActive = false
local aimbotActive = false
local noClipActive = false
local autoStealActive = false
local autoKickActive = false
local infiniteStaminaActive = false
local infiniteSpinsActive = false
local infiniteMoneyActive = false

-- Função para encontrar o gol do oponente
local function findOpponentGoal()
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Name:lower():find("goal") then
            return part.Position
        end
    end
    return Vector3.new(0, 0, 0) -- Fallback
end

-- Função para Auto Goal
local function autoGoal()
    autoGoalActive = true
    while autoGoalActive and ball and ball:IsA("BasePart") do
        if (humanoidRootPart.Position - ball.Position).Magnitude < 10 then
            local goalPosition = findOpponentGoal()
            local direction = (goalPosition - ball.Position).Unit
            ball.Velocity = direction * 60 -- Chutar a bola em direção ao gol
            -- Simular evento de chute (ajustar conforme o jogo)
            local kickEvent = ReplicatedStorage:FindFirstChild("KickEvent") -- Ajustar nome
            if kickEvent then
                kickEvent:FireServer(direction)
            end
        end
        RunService.Heartbeat:Wait()
    end
end

-- Função para Auto Dribble
local function autoDribble()
    autoDribbleActive = true
    while autoDribbleActive do
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                local otherRootPart = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                if otherRootPart and (humanoidRootPart.Position - otherRootPart.Position).Magnitude < 8 then
                    -- Simular dribble (ajustar conforme o jogo)
                    humanoid:Move(Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)))
                    local dribbleEvent = ReplicatedStorage:FindFirstChild("DribbleEvent") -- Ajustar nome
                    if dribbleEvent then
                        dribbleEvent:FireServer()
                    end
                end
            end
        end
        RunService.Heartbeat:Wait()
    end
end

-- Função para Auto Slide
local function autoSlide()
    autoSlideActive = true
    while autoSlideActive do
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                local otherRootPart = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                if otherRootPart and (humanoidRootPart.Position - otherRootPart.Position).Magnitude < 10 then
                    -- Simular slide (ajustar conforme o jogo)
                    local slideEvent = ReplicatedStorage:FindFirstChild("SlideEvent") -- Ajustar nome
                    if slideEvent then
                        slideEvent:FireServer(otherRootPart.Position)
                    end
                end
            end
        end
        RunService.Heartbeat:Wait()
    end
end

-- Função para Auto Steal
local function autoSteal()
    autoStealActive = true
    while autoStealActive and ball and ball:IsA("BasePart") do
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                local otherRootPart = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                if otherRootPart and (otherRootPart.Position - ball.Position).Magnitude < 5 then
                    ball.CFrame = humanoidRootPart.CFrame * CFrame.new(0, 0, -2)
                    local stealEvent = ReplicatedStorage:FindFirstChild("StealEvent") -- Ajustar nome
                    if stealEvent then
                        stealEvent:FireServer(otherPlayer)
                    end
                end
            end
        end
        RunService.Heartbeat:Wait()
    end
end

-- Função para Auto Kick Fast
local function autoKickFast()
    autoKickActive = true
    while autoKickActive and ball and ball:IsA("BasePart") do
        if (humanoidRootPart.Position - ball.Position).Magnitude < 5 then
            local goalPosition = findOpponentGoal()
            local direction = (goalPosition - ball.Position).Unit
            ball.Velocity = direction * 100 -- Chute rápido
            local kickEvent = ReplicatedStorage:FindFirstChild("KickEvent") -- Ajustar nome
            if kickEvent then
                kickEvent:FireServer(direction, true) -- true para chute rápido
            end
        end
        RunService.Heartbeat:Wait()
    end
end

-- Função para Teleport Ball
local function teleportBall()
    if ball and ball:IsA("BasePart") then
        ball.CFrame = humanoidRootPart.CFrame * CFrame.new(0, 0, -2)
        local controlEvent = ReplicatedStorage:FindFirstChild("ControlBallEvent") -- Ajustar nome
        if controlEvent then
            controlEvent:FireServer(humanoidRootPart.Position)
        end
    end
end

-- Função para Infinite Stamina
local function infiniteStamina()
    infiniteStaminaActive = true
    while infiniteStaminaActive do
        staminaService:FireServer(0/0) -- Impede diminuição de stamina
        wait(0.1)
    end
end

-- Função para Infinite Spins
local function infiniteSpins()
    infiniteSpinsActive = true
    while infiniteSpinsActive do
        local spinEvent = ReplicatedStorage:FindFirstChild("SpinEvent") -- Ajustar nome
        if spinEvent then
            spinEvent:FireServer() -- Simula um spin
        end
        wait(0.5)
    end
end

-- Função para Infinite Money
local function infiniteMoney()
    infiniteMoneyActive = true
    while infiniteMoneyActive do
        local moneyEvent = ReplicatedStorage:FindFirstChild("AddMoneyEvent") -- Ajustar nome
        if moneyEvent then
            moneyEvent:FireServer(1000) -- Adiciona 1000 de moeda (ajustar valor)
        end
        wait(1)
    end
end

-- Função para Auto Farm
local function autoFarm()
    autoFarmActive = true
    while autoFarmActive do
        -- Simular coleta de recompensas (ajustar conforme o jogo)
        local rewardEvent = ReplicatedStorage:FindFirstChild("RewardEvent") -- Ajustar nome
        if rewardEvent then
            rewardEvent:FireServer()
        end
        wait(2)
    end
end

-- Função para ESP
local function enableESP()
    espActive = true
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local highlight = Instance.new("Highlight")
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.Parent = otherPlayer.Character
        end
    end
    if ball then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(0, 255, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Parent = ball
    end
end

local function disableESP()
    espActive = false
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            for _, child in ipairs(otherPlayer.Character:GetChildren()) do
                if child:IsA("Highlight") then
                    child:Destroy()
                end
            end
        end
    end
    if ball then
        for _, child in ipairs(ball:GetChildren()) do
            if child:IsA("Highlight") then
                child:Destroy()
            end
        end
    end
end

-- Função para Aimbot
local function aimbot()
    aimbotActive = true
    while aimbotActive do
        local camera = Workspace.CurrentCamera
        local goalPosition = findOpponentGoal()
        if goalPosition ~= Vector3.new(0, 0, 0) then
            camera.CFrame = CFrame.new(camera.CFrame.Position, goalPosition)
        end
        RunService.RenderStepped:Wait()
    end
end

-- Função para No Clip
local function noClip()
    noClipActive = true
    while noClipActive do
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        RunService.Stepped:Wait()
    end
end

-- Função para desativar No Clip
local function disableNoClip()
    noClipActive = false
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

-- Função para Unlock Igaguri Style
local function unlockIgaguriStyle()
    local styleEvent = ReplicatedStorage:FindFirstChild("StyleEvent") -- Ajustar nome
    if styleEvent then
        styleEvent:FireServer("Igaguri")
    end
end

-- Função para Unlock Kaiser Style
local function unlockKaiserStyle()
    local styleEvent = ReplicatedStorage:FindFirstChild("StyleEvent") -- Ajustar nome
    if styleEvent then
        styleEvent:FireServer("Kaiser")
    end
end

-- Função para Get All Effects
local function getAllEffects()
    local effectEvent = ReplicatedStorage:FindFirstChild("EffectEvent") -- Ajustar nome
    if effectEvent then
        effectEvent:FireServer("AllEffects")
    end
end

-- Criar abas e botões na interface Fluent
local autoTab = window:Tab({
    Title = "Auto Features",
    Icon = "rbxassetid://4483345998"
})

autoTab:Toggle({
    Title = "Auto Goal",
    Description = "Chuta automaticamente para o gol",
    Default = false,
    Callback = function(state)
        autoGoalActive = state
        if state then
            spawn(autoGoal)
        end
    end
})

autoTab:Toggle({
    Title = "Auto Dribble",
    Description = "Dribla automaticamente perto de oponentes",
    Default = false,
    Callback = function(state)
        autoDribbleActive = state
        if state then
            spawn(autoDribble)
        end
    end
})

autoTab:Toggle({
    Title = "Auto Slide",
    Description = "Realiza slides automaticamente",
    Default = false,
    Callback = function(state)
        autoSlideActive = state
        if state then
            spawn(autoSlide)
        end
    end
})

autoTab:Toggle({
    Title = "Auto Steal",
    Description = "Rouba a bola automaticamente",
    Default = false,
    Callback = function(state)
        autoStealActive = state
        if state then
            spawn(autoSteal)
        end
    end
})

autoTab:Toggle({
    Title = "Auto Kick Fast",
    Description = "Chuta rapidamente com precisão",
    Default = false,
    Callback = function(state)
        autoKickActive = state
        if state then
            spawn(autoKickFast)
        end
    end
})

autoTab:Toggle({
    Title = "Auto Farm",
    Description = "Coletar recompensas automaticamente",
    Default = false,
    Callback = function(state)
        autoFarmActive = state
        if state then
            spawn(autoFarm)
        end
    end
})

local espTab = window:Tab({
    Title = "ESP",
    Icon = "rbxassetid://4483345998"
})

espTab:Toggle({
    Title = "Enable ESP",
    Description = "Destaca jogadores e bola",
    Default = false,
    Callback = function(state)
        if state then
            enableESP()
        else
            disableESP()
        end
    end
})

local teleportTab = window:Tab({
    Title = "Teleport",
    Icon = "rbxassetid://4483345998"
})

teleportTab:Button({
    Title = "Teleport Ball",
    Description = "Teleporta a bola para o jogador",
    Callback = function()
        teleportBall()
    end
})

local combatTab = window:Tab({
    Title = "Combat",
    Icon = "rbxassetid://4483345998"
})

combatTab:Toggle({
    Title = "Aimbot",
    Description = "Mira automaticamente no gol",
    Default = false,
    Callback = function(state)
        aimbotActive = state
        if state then
            spawn(aimbot)
        end
    end
})

local otherTab = window:Tab({
    Title = "Other Features",
    Icon = "rbxassetid://4483345998"
})

otherTab:Toggle({
    Title = "No Clip",
    Description = "Atravessa paredes",
    Default = false,
    Callback = function(state)
        if state then
            spawn(noClip)
        else
            disableNoClip()
        end
    end
})

otherTab:Toggle({
    Title = "Infinite Stamina",
    Description = "Nunca fica sem stamina",
    Default = false,
    Callback = function(state)
        infiniteStaminaActive = state
        if state then
            spawn(infiniteStamina)
        end
    end
})

otherTab:Toggle({
    Title = "Infinite Spins",
    Description = "Spins ilimitados",
    Default = false,
    Callback = function(state)
        infiniteSpinsActive = state
        if state then
            spawn(infiniteSpins)
        end
    end
})

otherTab:Toggle({
    Title = "Infinite Money",
    Description = "Moeda ilimitada",
    Default = false,
    Callback = function(state)
        infiniteMoneyActive = state
        if state then
            spawn(infiniteMoney)
        end
    end
})

local styleTab = window:Tab({
    Title = "Styles & Effects",
    Icon = "rbxassetid://4483345998"
})

styleTab:Button({
    Title = "Unlock Igaguri Style",
    Description = "Desbloqueia o estilo Igaguri",
    Callback = function()
        unlockIgaguriStyle()
    end
})

styleTab:Button({
    Title = "Unlock Kaiser Style",
    Description = "Desbloqueia o estilo Kaiser",
    Callback = function()
        unlockKaiserStyle()
    end
})

styleTab:Button({
    Title = "Get All Effects",
    Description = "Desbloqueia todos os efeitos visuais",
    Callback = function()
        getAllEffects()
    end
})

-- Lidar com respawn do personagem
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    autoGoalActive = false
    autoDribbleActive = false
    autoFarmActive = false
    autoSlideActive = false
    autoStealActive = false
    autoKickActive = false
    aimbotActive = false
    noClipActive = false
    infiniteStaminaActive = false
    infiniteSpinsActive = false
    infiniteMoneyActive = false
    if espActive then
        enableESP()
    end
end)

-- Atualizar referência da bola
RunService.Heartbeat:Connect(function()
    ball = Workspace:FindFirstChild("Ball") -- Atualiza a referência da bola
end)

-- Finalizar configuração da janela
window:SelectTab(1)
