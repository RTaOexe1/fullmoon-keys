-- hella unoptimized script cuz this game ahh :pray: steal best fruit is made by @prxmxthzn on discord
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local marketplace_service = game:GetService("MarketplaceService")
local replicated_storage = game:GetService("ReplicatedStorage")
local collection_service = game:GetService("CollectionService")
local user_input_service = game:GetService("UserInputService")
local teleport_service = game:GetService("TeleportService")
local virtual_user = game:GetService("VirtualUser")
local run_service = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local stats = game:GetService("Stats")
local best_fruit = nil

local info = marketplace_service:GetProductInfo(game.PlaceId)
local get_gc = getconnections or get_signal_cons
local local_player = players.LocalPlayer
local backpack = local_player.Backpack
local camera = workspace.CurrentCamera

local farms = workspace:FindFirstChild("Farm")

if not farms then
    return local_player:Kick("Farms folder not found!")
end

local plot = nil

for _, v in farms:GetDescendants() do
    if v.Name == "Owner" and v.Value == local_player.Name then
        plot = v.Parent.Parent
        break
    end
end

if not plot then
    return local_player:Kick("Plot not found!")
end

local plant_physical = plot:FindFirstChild("Plants_Physical")

if not plant_physical then
    return local_player:Kick("Plant folder not found!")
end

local object_physical = plot:FindFirstChild("Objects_Physical")

if not object_physical then
    return local_player:Kick("Object folder not found!")
end

local data = replicated_storage:FindFirstChild("Data")

if not data then
    return local_player:Kick("Data folder not found!")
end

local seed_data = require(data:FindFirstChild("SeedData"))

if not seed_data then
    return local_player:Kick("Seed data not found!")
end

local egg_data = require(data:FindFirstChild("PetEggData"))

if not egg_data then
    return local_player:Kick("Egg data not found!")
end

local gear_data = require(data:FindFirstChild("GearData"))

if not gear_data then
    return local_player:Kick("Gear data not found!")
end

local cosmetic_data = require(data:FindFirstChild("CosmeticItemShopData"))

if not cosmetic_data then
    return local_player:Kick("Cosmetic data not found!")
end

local modules = replicated_storage:FindFirstChild("Modules")

if not modules then
    return local_player:Kick("Modules folder not found!")
end

local caluculate_plant_value = require(modules:FindFirstChild("CalculatePlantValue"))

if not caluculate_plant_value then
    return local_player:Kick("Plant value calculator module not found!")
end

local calculate_pet_value = require(modules:FindFirstChild("CalculatePetValue"))

if not calculate_pet_value then
    return local_player:Kick("Pet value calculator module not found!")
end

local mutation_handler = require(modules:FindFirstChild("MutationHandler"))

if not mutation_handler then
    return local_player:Kick("Mutation handler module not found!")
end

local hatch = getupvalue(getupvalue(getconnections(replicated_storage.GameEvents.PetEggService.OnClientEvent)[1].Function, 1), 2)
local pet_list = getupvalue(hatch, 2)

-- idk if devs will change this soon
local inventory_enums = {
    ["OWNER"]             = "a",
    ["ITEM_TYPE"]         = "b",
    ["ITEM_UUID"]         = "c",
    ["Favorite"]          = "d",
    ["Uses"]              = "e",
    ["ItemName"]          = "f",
    ["Rarity"]            = "g",
    ["EggName"]           = "h",
    ["CrateType"]         = "i",
    ["PotType"]           = "j",
    ["LinkedPlayerID"]    = "k",
    ["SprayType"]         = "l",
    ["SprayMutationName"] = "m",
    ["Type"]              = "n"
}

local item_types = {
    ["Seed Pack"]         = "a",
    ["Trowel"]            = "b",
    ["PetEgg"]            = "c",
    ["Sprinkler"]         = "d",
    ["Night Staff"]       = "e",
    ["Harvest Tool"]      = "f",
    ["Pollen Radar"]      = "g",
    ["Favorite Tool"]     = "h",
    ["Lightning Rod"]     = "i",
    ["Holdable"]          = "j",
    ["Star Caller"]       = "k",
    ["Pet"]               = "l",
    ["FriendshipPot"]     = "m",
    ["Seed"]              = "n",
    ["Watering Can"]      = "o",
    ["Nectar Staff"]      = "p",
    ["Recall Wrench"]     = "q",
    ["CosmeticCrate"]     = "r",
    ["SprayBottle"]       = "s"
}

function calculate_combined_plant_value()
    local total_plant_value = 0
    for _, v in backpack:GetChildren() do
        if v:IsA("Tool") then
            local tool = v
            local item_type = v:GetAttribute(inventory_enums.ITEM_TYPE)
            if item_type == item_types.Holdable then
                local value = caluculate_plant_value(tool)
                total_plant_value += value
            end
        end
    end
    return total_plant_value
end

function calculate_combined_pet_value()
    local total_pet_value = 0
    for _, v in backpack:GetChildren() do
        if v:IsA("Tool") then
            local tool = v
            local item_type = v:GetAttribute(inventory_enums.ITEM_TYPE)
            if item_type == item_types.Pet then
                local value = calculate_pet_value(tool)
                total_pet_value += value
            end
        end
    end
    return total_pet_value
end

function check_staff(v)
    local rank = v:GetRankInGroup(35302026)
    if rank and rank > 2 then
        return true
    end
end

function closest_plant()
    local plant = nil
    local dist = 9e99
    for _, v in plant_physical:GetDescendants() do
        if v:IsA("ProximityPrompt") and v.Parent then
            local distance = (v.Parent.Parent:GetPivot().Position - local_player.Character:GetPivot().Position).Magnitude
            if distance < dist then
                dist = distance
                plant = v.Parent.Parent
            end
        end
    end
    return plant
end

function get_tool()
    return local_player.Character:FindFirstChildOfClass("Tool")
end

function is_full()
    return #backpack:GetChildren() > 200
end

local auto_favorite_selected_mutations = {}
local selected_cosmetic = {}
local stored_players = {}
local selected_seeds = {}
local cosmetic_names = {}
local mutation_names = {}
local selected_gear = {}
local selected_eggs = {}
local gear_names = {}
local seed_names = {}
local egg_names = {}

function get_players()
    for _, v in players:GetPlayers() do
        if v ~= local_player then
            table.insert(stored_players, v)
        end
    end
end

for _, v in cosmetic_data do
    table.insert(cosmetic_names, v.CosmeticName)
end

for _, v in gear_data do
    if v.StockChance > 0 then
        table.insert(gear_names, v.GearName)
    end
end

for _, v in egg_data do
    if v.StockChance > 0 then
        table.insert(egg_names, v.EggName)
    end
end

for i, v in seed_data do
    if v.StockChance > 0 then -- or if v.DisplayInShop then
        table.insert(seed_names, i)
    end
end

for i, _ in mutation_handler.MutationNames do
    table.insert(mutation_names, i)
end

table.insert(mutation_names, "Gold")
table.insert(mutation_names, "Rainbow")

local auto_buy_cosmetics = false
local auto_plant_seeds = false
local auto_place_eggs = false
local auto_buy_seeds = false
local auto_buy_gears = false
local auto_buy_eggs = false
local auto_favorite = false
local egg_predictor = false
local harvest_aura = false
local hatch_aura = false
local auto_sell = false
local inf_jump = false
local anti_afk = false

local selected_server_make_method = "" -- long name cuz idk what to call it
local selected_auto_sell_method = ""
local plant_seed_method = ""
local place_egg_method = ""

local selected_position_plant = nil
local selected_positon_hatch = nil

local auto_buy_cosmetic_delay = 1
local min_pickup_harvest_aura = 0.1
local min_favorite_favorite = 0.1
local auto_buy_seed_delay = 1
local auto_buy_gear_delay = 1
local auto_buy_egg_delay = 1
local favorite_delay = 0.1
local harvest_delay = 0.1
local hatch_delay = 0.1
local sell_delay = 1

function update()
    if #object_physical:GetChildren() > 0 and egg_predictor then
        for _, v in object_physical:GetChildren() do

            if (not v:GetAttribute("TimeToHatch") == 0) then
                continue
            end
            local screen_position, on_screen = camera:WorldToViewportPoint(v:GetPivot().Position)

            if (not on_screen) then
                continue
            end

            local uuid = v:GetAttribute("OBJECT_UUID")
            local egg_name = v:GetAttribute("EggName") or "Unknown Egg"
            local pet = pet_list[uuid] or "Unknown Pet"

            local text = Drawing.new("Text")
            text.Visible = true
            text.Text = egg_name.." | "..pet
            text.Size = 18
            text.Position = Vector2.new(screen_position.X, screen_position.Y)
            text.Color = Color3.new(1, 1, 1)
            text.Outline = true
            text.OutlineColor = Color3.new(0, 0, 0)
            text.Center = true
            text.Font = 2
        end
    end
end

local_player.Idled:Connect(function()
    if anti_afk then
        virtual_user:CaptureController()
        virtual_user:ClickButton2(Vector2.new())
    end
end)

user_input_service.JumpRequest:Connect(function()
    if inf_jump and not tweek_cmon_dont_do_it_unblock_me_faggot then
        tweek_cmon_dont_do_it_unblock_me_faggot = true
        local_player.Character.Humanoid:ChangeState("Jumping")
        wait()
        tweek_cmon_dont_do_it_unblock_me_faggot = false
    end
end)

local repo = 'https://raw.githubusercontent.com/KINGHUB01/Gui/main/'
local better_drawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/dementiaenjoyer/Better-Drawing/refs/heads/main/Main.lua"))()

local library = loadstring(game:HttpGet(repo .. 'Gui%20Lib%20%5BLibrary%5D'))()
local theme_manager = loadstring(game:HttpGet(repo .. 'Gui%20Lib%20%5BThemeManager%5D'))()
local save_manager = loadstring(game:HttpGet(repo .. 'Gui%20Lib%20%5BSaveManager%5D'))()

better_drawing:Init(update)

local window = library:CreateWindow({
    Title = "@23899348291 (Tweeks) Unblock Me Cmon | Made By @kylosilly On Discord",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.4
})

local tabs = {
    main = window:AddTab("Main"),
    inventory = window:AddTab("Inventory"),
    shop = window:AddTab("Shop"),
    misc = window:AddTab("Misc"),
    ["ui settings"] = window:AddTab("UI Settings")
}

local plant_group = tabs.main:AddLeftGroupbox("Plant Settings")
local pet_group = tabs.main:AddRightGroupbox("Pet/Egg Settings")
local exploit_group = tabs.main:AddRightGroupbox("Exploit Settings")
local steal_group = tabs.main:AddLeftGroupbox("Steal Settings")
local favorite_group = tabs.inventory:AddRightGroupbox("Favorite Settings")
local sell_group = tabs.inventory:AddLeftGroupbox("Sell Settings")
local seed_group = tabs.shop:AddLeftGroupbox("Seed Shop Settings")
local egg_group = tabs.shop:AddRightGroupbox("Egg Shop Settings")
local cosmetic_group = tabs.shop:AddLeftGroupbox("Cosmetic Shop Settings")
local gear_group = tabs.shop:AddRightGroupbox("Gear Shop Settings")
local player_group = tabs.misc:AddLeftGroupbox("Local Player Settings")
local server_group = tabs.misc:AddRightGroupbox("Server Settings")
local menu_group = tabs["ui settings"]:AddLeftGroupbox("Menu Settings")

plant_group:AddDivider()

plant_group:AddToggle('harvest_aura', {
    Text = 'Harvest Aura',
    Default = harvest_aura,
    Tooltip = 'Harvest nearby plants',
    Callback = function(Value)
        harvest_aura = Value
        if Value then
            repeat
                if not is_full() then
                    for _, v in plant_physical:GetDescendants() do
                        if v:IsA("ProximityPrompt") and v.Parent and v.Parent.Parent:FindFirstChild("Weight") and v.Parent.Parent:FindFirstChild("Variant") then -- ill add variant check someday fr....
                            if v.Parent.Parent.Weight.Value >= tonumber(min_pickup_harvest_aura) and (v.Parent.Parent:GetPivot().Position - local_player.Character:GetPivot().Position).Magnitude < v.MaxActivationDistance * 2 then
                                fireproximityprompt(v)
                                task.wait(harvest_delay)
                            end
                        end
                    end 
                end
                task.wait()
            until not harvest_aura
        end
    end
})

plant_group:AddSlider('harvest_delay', {
    Text = 'Harvest Delay:',
    Default = harvest_delay,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        harvest_delay = Value
        if Value == 0 then
            library:Notify("Delay at 0 is not recommended as it may cause lag")
        end
    end
})

plant_group:AddInput('MyTextbox', {
    Default = min_pickup_harvest_aura,
    Numeric = true,
    Finished = true,

    Text = 'Auto Harvest If Weight Above:',
    Tooltip = 'Auto harvest at choosen weight',

    Placeholder = min_pickup_harvest_aura,

    Callback = function(Value)
        min_pickup_harvest_aura = Value
    end
})

plant_group:AddDivider()

plant_group:AddToggle('auto_plant_seeds', {
    Text = 'Auto Plant Seeds',
    Default = auto_plant_seeds,
    Tooltip = 'Plants seeds with selected method from dropdown',
    Callback = function(Value)
        auto_plant_seeds = Value
        if Value then
            repeat
                if plant_seed_method == "Selected Position" and not selected_position then
                    return library:Notify("You need to set a position first")
                end
                if plant_seed_method == "" then
                    return library:Notify("You need to select a method first")
                end
                for _, v in backpack:GetChildren() do
                    if v:IsA("Tool") and v:GetAttribute(inventory_enums.ITEM_TYPE) == item_types.Seed then
                        local_player.Character.Humanoid:EquipTool(v)
                        local tool = get_tool()
                        if tool and tool:GetAttribute("Seed") and tool:GetAttribute("Quantity") then
                            for i = 1, tool:GetAttribute("Quantity") do
                                if plant_seed_method == "Player Position" then
                                    replicated_storage:WaitForChild("GameEvents"):WaitForChild("Plant_RE"):FireServer(local_player.Character:GetPivot().Position, tool:GetAttribute("Seed"))
                                    task.wait(.25)
                                elseif plant_seed_method == "Selected Position" then
                                    replicated_storage:WaitForChild("GameEvents"):WaitForChild("Plant_RE"):FireServer(selected_position, tool:GetAttribute("Seed"))
                                    task.wait(.25)
                                end
                            end
                        end
                    end
                end
                task.wait()
            until not auto_plant_seeds
        end
    end
})

plant_group:AddDropdown('plant_seed_method', {
    Values = { 'Player Position', 'Selected Position' },
    Default = plant_seed_method,
    Multi = false,
    Text = 'Select Auto Plant Method:',
    Tooltip = 'Auto plants with selected method',
    Callback = function(Value)
        plant_seed_method = Value
    end
})

local selected_position_seed_group = plant_group:AddDependencyBox()

selected_position_seed_group:AddButton({
    Text = 'Set Position',
    Func = function()
        if local_player.Character then
            selected_position_plant = local_player.Character:GetPivot().Position
            library:Notify("Set player position!")
        end
    end,
    DoubleClick = false,
    Tooltip = 'Sets player position to use for auto plant'
})

selected_position_seed_group:SetupDependencies({
    { Options.plant_seed_method, "Selected Position" }
})

pet_group:AddDivider()

pet_group:AddToggle('hatch_aura', {
    Text = 'Hatch Aura',
    Default = hatch_aura,
    Tooltip = 'Hatches nearby avaible eggs',
    Callback = function(Value)
        hatch_aura = Value
        if Value then
            repeat
                for _, v in object_physical:GetDescendants() do
                    if v.Name == "ProximityPrompt" and v.Parent.Parent:GetAttribute("TimeToHatch") == 0 then
                        if (v.Parent.Parent:GetPivot().Position - local_player.Character:GetPivot().Position).Magnitude < v.MaxActivationDistance * 2 then
                            fireproximityprompt(v)
                            task.wait(hatch_delay)
                        end
                    end 
                end
                task.wait()
            until not hatch_aura
        end
    end
})

pet_group:AddSlider('hatch_delay', {
    Text = 'Hatch Delay:',
    Default = hatch_delay,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        hatch_delay = Value
        if Value == 0 then
            library:Notify("Delay at 0 is not recommended as it may cause lag!")
        end
    end
})

pet_group:AddDivider()

pet_group:AddToggle('auto_place_eggs', {
    Text = 'Auto Place Eggs',
    Default = auto_place_eggs,
    Tooltip = 'Places eggs with selected method from dropdown',
    Callback = function(Value)
        auto_place_eggs = Value
        if Value then
            if place_egg_method == "" then
                return library:Notify("You need to select a method first!")
            end
            if place_egg_method == "Selected Position" and not selected_position_egg then
                return library:Notify("You need to set a position first!")
            end
            repeat
                if #object_physical:GetChildren() < 3 then
                    for _, v in backpack:GetChildren() do
                        if v:IsA("Tool") and v:GetAttribute(inventory_enums.ITEM_TYPE) == item_types.PetEgg then
                            local_player.Character.Humanoid:EquipTool(v)
                            local tool = get_tool()
                            if tool and tool:GetAttribute(inventory_enums.Uses) then
                                for i = 1, tool:GetAttribute(inventory_enums.Uses) do
                                    if place_egg_method == "Player Position" then
                                        replicated_storage:WaitForChild("GameEvents"):WaitForChild("PetEggService"):FireServer("CreateEgg", local_player.Character:GetPivot().Position)
                                        task.wait(.25)
                                    elseif place_egg_method == "Selected Position" then
                                        replicated_storage:WaitForChild("GameEvents"):WaitForChild("PetEggService"):FireServer("CreateEgg", selected_position_egg)
                                        task.wait(.25)
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait()
            until not auto_place_eggs
        end
    end
})

pet_group:AddDropdown('place_egg_method', {
    Values = { 'Player Position', 'Selected Position' },
    Default = place_egg_method,
    Multi = false,
    Text = 'Select Auto Place Egg Method:',
    Tooltip = 'Auto places eggs with selected method',
    Callback = function(Value)
        place_egg_method = Value
    end
})

local selected_position_egg_group = pet_group:AddDependencyBox()

selected_position_egg_group:AddButton({
    Text = 'Set Position',
    Func = function()
        if local_player.Character then
            selected_position_egg = local_player.Character:GetPivot().Position
            library:Notify("Set player position!")
        end
    end,
    DoubleClick = false,
    Tooltip = 'Sets player position to use for auto place eggs'
})

selected_position_egg_group:SetupDependencies({
    { Options.place_egg_method, "Selected Position" }
})

exploit_group:AddDivider()

exploit_group:AddLabel("Egg predictor predicts eggs pets when thier times are up", true)

exploit_group:AddDivider()

exploit_group:AddToggle('egg_predictor', {
    Text = 'Predict Egg Hatch',
    Default = egg_predictor,
    Tooltip = 'Predicts what a egg will hatch',
    Callback = function(Value)
        egg_predictor = Value
    end
})

steal_group:AddDivider()

steal_group:AddLabel("To steal a plant you need 37 robux!", true)

steal_group:AddDivider()

local label = steal_group:AddLabel("Player: N/A\nFruit: N/A\nValue: N/A", true)

task.spawn(function()
    while true do
        local farms = workspace.Farm:GetChildren()
        table.sort(farms, function(a, b)
            return a.Name < b.Name
        end)

        best_fruit = nil
        local best_value = 0
        local fruit_owner = nil

        for _, farm in ipairs(farms) do
            local important = farm:FindFirstChild("Important")
            local data = important and important:FindFirstChild("Data")
            local owner = data and data:FindFirstChild("Owner")
            local owner_name = owner and owner.Value or "Unknown"

            if owner_name == local_player.Name then
                continue
            end

            local plants = important and important:FindFirstChild("Plants_Physical")
            if not plants then
                continue
            end

            for _, fruit_model in ipairs(plants:GetDescendants()) do
                local variant = fruit_model:FindFirstChild("Variant")
                local weight = fruit_model:FindFirstChild("Weight")

                if not (fruit_model:IsA("Model") and variant and weight) then
                    continue
                end

                local Arguments = {
                    ["FindFirstChild"] = function(_, name)
                        if name == "Item_String" then
                            return { Value = fruit_model.Name }
                        elseif name == "Variant" then
                            return { Value = variant.Value }
                        elseif name == "Weight" then
                            return { Value = weight.Value }
                        end
                    end,
                    ["GetAttribute"] = function(_, attr)
                        return fruit_model:GetAttribute(attr)
                    end
                }

                local current_value = caluculate_plant_value(Arguments)

                if current_value > best_value then
                    best_fruit = fruit_model
                    best_value = current_value
                    fruit_owner = owner_name
                end
            end
        end

        if best_fruit and best_value > 0 then
            local raw = tostring(math.floor(best_value)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
            label:SetText("Player: " .. fruit_owner .. "\nFruit: " .. best_fruit.Name .. "\nValue: " .. raw)
        else
            label:SetText("Player: N/A\nFruit: N/A\nValue: N/A")
        end

        task.wait(1)
    end
end)

steal_group:AddButton({
    Text = "Steal Best Value",
    Func = function()
        if not best_fruit then
            return
        end

        local root = local_player.Character and local_player.Character:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end

        local original_pos = root.CFrame

        for _, prompt in ipairs(best_fruit:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local target = prompt.Parent:IsA("BasePart") and prompt.Parent or best_fruit:FindFirstChildWhichIsA("BasePart")
                if target then
                    root.CFrame = target.CFrame + Vector3.new(0, 3, 0)
                    task.wait(.2)
                    fireproximityprompt(prompt)
                    task.wait(.2)
                    root.CFrame = original_pos
                end
                break
            end
        end
    end,
    DoubleClick = false,
    Tooltip = "Steals the best value fruit"
})

favorite_group:AddDivider()

favorite_group:AddToggle('auto_favorite', {
    Text = 'Auto Favorite',
    Default = auto_favorite,
    Tooltip = 'Auto favorites fruits/pets',

    Callback = function(Value)
        auto_favorite = Value
        if Value then
            repeat
                for _, v in backpack:GetChildren() do
                    for v2 in auto_favorite_selected_mutations do
                        if v:IsA("Tool") and v:FindFirstChild("Weight") and v.Weight.Value >= tonumber(min_favorite_favorite) and not v:GetAttribute(inventory_enums.Favorite) then
                            replicated_storage:WaitForChild("GameEvents"):WaitForChild("Favorite_Item"):FireServer(v)
                        elseif v:IsA("Tool") and v.Name:find(v2) and not v:GetAttribute(inventory_enums.Favorite) then
                            replicated_storage:WaitForChild("GameEvents"):WaitForChild("Favorite_Item"):FireServer(v)
                        end
                    end
                end
                local tool = get_tool()
                if tool and tool:FindFirstChild("Weight") and tool.Weight.Value >= tonumber(min_favorite_favorite) and not tool:GetAttribute(inventory_enums.Favorite) then
                    replicated_storage:WaitForChild("GameEvents"):WaitForChild("Favorite_Item"):FireServer(tool)
                end
                task.wait(favorite_delay)
            until not auto_favorite
        end
    end
})

favorite_group:AddSlider('favorite_delay', {
    Text = 'Select Favorite Delay:',
    Default = favorite_delay,
    Min = 0,
    Max = 60,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        favorite_delay = Value
    end
})

favorite_group:AddDropdown('auto_favorite_selected_mutations', {
    Values = mutation_names,
    Default = auto_favorite_selected_mutations,
    Multi = true,

    Text = 'Select Mutation:',
    Tooltip = 'Will favorite above the min weight or selected mutation',

    Callback = function(Value)
        auto_favorite_selected_mutations = Value
    end
})

favorite_group:AddInput('favorite_weight', {
    Default = min_favorite_favorite,
    Numeric = true,
    Finished = true,

    Text = 'Select Favorite Weight:',
    Tooltip = 'Will favorite above the min weight',

    Placeholder = min_favorite_favorite,

    Callback = function(Value)
        min_favorite_favorite = Value
    end
})

favorite_group:AddDivider()

favorite_group:AddButton({
    Text = 'Unfavorite All',
    Func = function()
        for _, v in backpack:GetChildren() do
            if v:IsA("Tool") and v:GetAttribute(inventory_enums.Favorite) then
                replicated_storage:WaitForChild("GameEvents"):WaitForChild("Favorite_Item"):FireServer(v)
            end
        end
        local tool = get_tool()
        if tool and tool:GetAttribute(inventory_enums.Favorite) then
            replicated_storage:WaitForChild("GameEvents"):WaitForChild("Favorite_Item"):FireServer(tool)
        end
        library:Notify("Unfavorited all")
    end,
    DoubleClick = false,
    Tooltip = 'Unfavorites all plants/pets'
})

sell_group:AddDivider()

sell_group:AddToggle('auto_sell', {
    Text = 'Auto Sell',
    Default = auto_sell,
    Tooltip = 'Automatically sells all plants for you',
    Callback = function(Value)
        auto_sell = Value
        if Value then
            if selected_auto_sell_method == "" then
                library:Notify("You need to select a method first")
                auto_sell = false
                return
            end
            repeat
                if local_player.Character then
                    if selected_auto_sell_method == "When Full" and is_full() then
                        local old = local_player.Character:GetPivot().Position
                        local_player.Character:MoveTo(workspace:FindFirstChild("Tutorial_Points"):FindFirstChild("Tutorial_Point_2").Position)
                        task.wait(.2)
                        replicated_storage:WaitForChild("GameEvents"):WaitForChild("Sell_Inventory"):FireServer()
                        task.wait(.2)
                        local_player.Character:MoveTo(old)
                    elseif selected_auto_sell_method == "Custom Delay" then
                        local old = local_player.Character:GetPivot().Position
                        local_player.Character:MoveTo(workspace:FindFirstChild("Tutorial_Points"):FindFirstChild("Tutorial_Point_2").Position)
                        task.wait(.2)
                        replicated_storage:WaitForChild("GameEvents"):WaitForChild("Sell_Inventory"):FireServer()
                        task.wait(.2)
                        local_player.Character:MoveTo(old)
                        task.wait(sell_delay)
                    end
                end
                task.wait()
            until not auto_sell
        end
    end
})

sell_group:AddDropdown('selected_auto_sell_method', {
    Values = { 'Custom Delay', 'When Full' },
    Default = selected_auto_sell_method,
    Multi = false,
    Text = 'Select Auto Sell Method:',
    Tooltip = 'Auto sells with selected method',
    Callback = function(Value)
        selected_auto_sell_method = Value
    end
})

local custom_delay_settings = sell_group:AddDependencyBox()

custom_delay_settings:AddSlider('sell_delay', {
    Text = 'Sell Delay:',
    Default = sell_delay,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        sell_delay = Value
    end
})

custom_delay_settings:SetupDependencies({
    { Options.selected_auto_sell_method, "Custom Delay" }
})

seed_group:AddDivider()

seed_group:AddDropdown('selected_seeds', {
    Values = seed_names,
    Default = selected_seeds,
    Multi = true,
    Text = 'Select Seeds To Auto Buy:',
    Tooltip = 'Buys selected seeds',
    Callback = function(Value)
        selected_seeds = Value
    end
})

seed_group:AddToggle('auto_buy_seeds', {
    Text = 'Auto Buy Seeds',
    Default = auto_buy_seeds,
    Tooltip = 'Automatically buys selected seeds from dropdown',

    Callback = function(Value)
        auto_buy_seeds = Value
        if Value then
            repeat
                for v in selected_seeds do
                    for _, v2 in local_player.PlayerGui:FindFirstChild("Seed_Shop"):FindFirstChild("Frame"):FindFirstChild("ScrollingFrame"):GetChildren() do
                        if v2.Name == v then
                            local stock = tonumber(v2:FindFirstChild("Main_Frame"):FindFirstChild("Stock_Text").Text:match("%d+"))
                            if stock > 0 then
                                for i = 1, stock do
                                    replicated_storage:WaitForChild("GameEvents"):WaitForChild("BuySeedStock"):FireServer(v2.Name)
                                    task.wait(.1)
                                end
                            end
                        end
                    end
                end
                task.wait(auto_buy_seed_delay)
            until not auto_buy_seeds
        end
    end            
})

seed_group:AddSlider('auto_buy_seed_delay', {
    Text = 'Auto Buy Seed Delay:',
    Default = auto_buy_seed_delay,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        auto_buy_seed_delay = Value
    end
})

seed_group:AddDivider()

seed_group:AddButton({
    Text = 'Buy Selected Seeds',
    Func = function()
        for v in selected_seeds do
            for _, v2 in local_player.PlayerGui:FindFirstChild("Seed_Shop"):FindFirstChild("Frame"):FindFirstChild("ScrollingFrame"):GetChildren() do
                if v2.Name == v then
                    local stock = tonumber(v2:FindFirstChild("Main_Frame"):FindFirstChild("Stock_Text").Text:match("%d+"))
                    if stock > 0 then
                        for i = 1, stock do
                            replicated_storage:WaitForChild("GameEvents"):WaitForChild("BuySeedStock"):FireServer(v2.Name)
                            task.wait(.1)
                        end
                    end
                end
            end
        end
    end,
    DoubleClick = false,
    Tooltip = 'Buys selected seeds from dropdown once'
})

egg_group:AddDivider()

egg_group:AddDropdown('selected_eggs', {
    Values = egg_names,
    Default = selected_eggs,
    Multi = true,
    Text = 'Select Eggs To Auto Buy:',
    Tooltip = 'Buys selected eggs',
    Callback = function(Value)
        selected_eggs = Value
    end
})

egg_group:AddToggle('auto_buy_eggs', {
    Text = 'Auto Buy Eggs',
    Default = auto_buy_eggs,
    Tooltip = 'Automatically buys selected eggs from dropdown',

    Callback = function(Value)
        auto_buy_eggs = Value
        if Value then
            repeat
                for v in selected_eggs do
                    for i, v2 in workspace:FindFirstChild("NPCS"):FindFirstChild("Pet Stand"):FindFirstChild("EggLocations"):GetChildren() do
                        if v2.Name == v and not v2:GetAttribute("RobuxEggOnly") then
                            replicated_storage:WaitForChild("GameEvents"):WaitForChild("BuyPetEgg"):FireServer(i - 3)
                        end
                    end
                end
                task.wait(auto_buy_egg_delay)
            until not auto_buy_eggs
        end
    end            
})

egg_group:AddSlider('auto_buy_egg_delay', {
    Text = 'Auto Buy Egg Delay:',
    Default = auto_buy_egg_delay,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        auto_buy_egg_delay = Value
    end
})

egg_group:AddDivider()

egg_group:AddButton({
    Text = 'Buy Selected Eggs',
    Func = function()
        for v in selected_eggs do
            for i, v2 in workspace:FindFirstChild("NPCS"):FindFirstChild("Pet Stand"):FindFirstChild("EggLocations"):GetChildren() do
                if v2.Name == v and not v2:GetAttribute("RobuxEggOnly") then
                    replicated_storage:WaitForChild("GameEvents"):WaitForChild("BuyPetEgg"):FireServer(i - 3)
                end
            end
        end
    end,
    DoubleClick = false,
    Tooltip = 'Buys selected eggs from dropdown once'
})

cosmetic_group:AddDivider()

cosmetic_group:AddDropdown('selected_cosmetic', {
    Values = cosmetic_names,
    Default = selected_cosmetic,
    Multi = true,
    Text = 'Select Cosmetic:',
    Tooltip = 'Select cosmetic to buy',
    Callback = function(Value)
        selected_cosmetic = Value
    end
})

cosmetic_group:AddToggle('auto_buy_cosmetic', {
    Text = 'Auto Buy Cosmetic',
    Default = auto_buy_cosmetics,
    Tooltip = 'Automatically buys selected cosmetic from dropdown',

    Callback = function(Value)
        auto_buy_cosmetics = Value
        if Value then
            repeat
                for v in selected_cosmetic do
                    for _, v2 in local_player.PlayerGui:FindFirstChild("CosmeticShop_UI"):FindFirstChild("CosmeticShop"):FindFirstChild("Main"):FindFirstChild("Holder"):FindFirstChild("Shop"):FindFirstChild("ContentFrame"):GetDescendants() do
                        if v2.Name == v then
                            local stock = tonumber(v2:FindFirstChild("Main"):FindFirstChild("Stock"):FindFirstChild("STOCK_TEXT").Text:match("%d+"))
                            if stock > 0 then
                                for i = 1, stock do
                                    if v2.Parent.Name == "BottomSegment" then
                                        replicated_storage:WaitForChild("GameEvents"):WaitForChild("BuyCosmeticItem"):FireServer(v2.Name)
                                    elseif v2.Parent.Name == "TopSegment" then
                                        replicated_storage:WaitForChild("GameEvents"):WaitForChild("BuyComseticCrate"):FireServer(v2.Name)
                                    end
                                    task.wait(.1)
                                end
                            end
                        end
                    end
                end
                task.wait(auto_buy_cosmetic_delay)
            until not auto_buy_cosmetics
        end
    end            
})

cosmetic_group:AddSlider('auto_buy_cosmetic_delay', {
    Text = 'Auto Buy Cosmetic Delay:',
    Default = auto_buy_cosmetic_delay,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        auto_buy_cosmetic_delay = Value
    end
})

cosmetic_group:AddDivider()

cosmetic_group:AddButton({
    Text = 'Buy Selected Cosmetic',
    Func = function()
        for v in selected_cosmetic do
            for _, v2 in local_player.PlayerGui:FindFirstChild("CosmeticShop_UI"):FindFirstChild("CosmeticShop"):FindFirstChild("Main"):FindFirstChild("Holder"):FindFirstChild("Shop"):FindFirstChild("ContentFrame"):GetDescendants() do
                if v2.Name == v then
                    local stock = tonumber(v2:FindFirstChild("Main"):FindFirstChild("Stock"):FindFirstChild("STOCK_TEXT").Text:match("%d+"))
                    if stock > 0 then
                        for i = 1, stock do
                            if v2.Parent.Name == "BottomSegment" then
                                replicated_storage:WaitForChild("GameEvents"):WaitForChild("BuyCosmeticItem"):FireServer(v2.Name)
                            elseif v2.Parent.Name == "TopSegment" then
                                replicated_storage:WaitForChild("GameEvents"):WaitForChild("BuyComseticCrate"):FireServer(v2.Name)
                            end
                            task.wait(.1)
                        end
                    end
                end
            end
        end
    end,
    DoubleClick = false,
    Tooltip = 'Buys selected cosmetic from dropdown once'
})

gear_group:AddDivider()

gear_group:AddDropdown('selected_gear', {
    Values = gear_names,
    Default = selected_gear,
    Multi = true,
    Text = 'Select Gear:',
    Tooltip = 'Select gear to buy',
    Callback = function(Value)
        selected_gear = Value
    end
})

gear_group:AddToggle('auto_buy_gears', {
    Text = 'Auto Buy Gear',
    Default = auto_buy_gears,
    Tooltip = 'Automatically buys selected gear from dropdown',

    Callback = function(Value)
        auto_buy_gears = Value
        if Value then
            repeat
                for v, _ in selected_gear do
                    for _, v2 in local_player.PlayerGui:FindFirstChild("Gear_Shop"):FindFirstChild("Frame"):FindFirstChild("ScrollingFrame"):GetChildren() do
                        if v2.Name == v then
                            local stock = tonumber(v2:FindFirstChild("Main_Frame"):FindFirstChild("Stock_Text").Text:match("%d+"))
                            if stock > 0 then
                                for i = 1, stock do
                                    replicated_storage:WaitForChild("GameEvents"):WaitForChild("BuyGearStock"):FireServer(v2.Name)
                                    task.wait(.1)
                                end
                            end
                        end
                    end
                end
                task.wait(auto_buy_gear_delay)
            until not auto_buy_gears
        end
    end            
})

gear_group:AddSlider('auto_buy_gear_delay', {
    Text = 'Auto Buy Gear Delay:',
    Default = auto_buy_gear_delay,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        auto_buy_gear_delay = Value
    end
})

gear_group:AddDivider()

gear_group:AddButton({
    Text = 'Buy Selected Gear',
    Func = function()
        for _, v2 in local_player.PlayerGui:FindFirstChild("Gear_Shop"):FindFirstChild("Frame"):FindFirstChild("ScrollingFrame"):GetChildren() do
            if v2.Name == selected_gear then
                local stock = tonumber(v2:FindFirstChild("Main_Frame"):FindFirstChild("Stock_Text").Text:match("%d+"))
                if stock > 0 then
                    for i = 1, stock do
                        replicated_storage:WaitForChild("GameEvents"):WaitForChild("BuyGearStock"):FireServer(v2.Name)
                        task.wait(.1)
                    end
                end
            end
        end
    end,
    DoubleClick = false,
    Tooltip = 'Buys selected gear from dropdown once'
})

sell_group:AddDivider()

sell_group:AddButton({
    Text = 'Sell All',
    Func = function()
        if local_player.Character then
            local old = local_player.Character:GetPivot().Position
            local_player.Character:MoveTo(workspace:FindFirstChild("Tutorial_Points"):FindFirstChild("Tutorial_Point_2").Position)
            task.wait(.2)
            replicated_storage:WaitForChild("GameEvents"):WaitForChild("Sell_Inventory"):FireServer()
            task.wait(.2)
            local_player.Character:MoveTo(old)
        end
    end,
    DoubleClick = false,
    Tooltip = 'Sells all plants'
})

sell_group:AddButton({
    Text = 'Sell Held Item',
    Func = function()
        local tool = get_tool()
        if not tool then
            return library:Notify("Not holding a tool")
        end
        if tool and (tool:GetAttribute(inventory_enums.ITEM_TYPE) == item_types.Holdable or tool:GetAttribute(inventory_enums.ITEM_TYPE) == item_types.Pet) then
            local old = local_player.Character:GetPivot().Position
            local_player.Character:MoveTo(workspace:FindFirstChild("Tutorial_Points"):FindFirstChild("Tutorial_Point_2").Position)
            task.wait(.2)
            replicated_storage:WaitForChild("GameEvents"):WaitForChild("Sell_Item"):FireServer()
            task.wait(.2)
            local_player.Character:MoveTo(old)
            library:Notify("Sold "..tool.Name)
        end
    end,
    DoubleClick = false,
    Tooltip = 'Sells all plants'
})

player_group:AddDivider()

player_group:AddToggle('inf_jump', {
    Text = 'Inf Jump',
    Default = inf_jump,
    Tooltip = 'Lets you jump forever',
    Callback = function(Value)
        inf_jump = Value
    end
})

player_group:AddToggle('anti_afk', {
    Text = 'Anti Afk',
    Default = anti_afk,
    Tooltip = 'Prevents you from getting disconnected',
    Callback = function(Value)
        anti_afk = Value
    end
})

server_group:AddDivider()

server_group:AddButton({
    Text = 'Copy Job Id',
    Func = function()
        setclipboard(game.JobId)
        library:Notify("Copied Job Id To Clipboard")
    end,
    DoubleClick = false,
    Tooltip = 'Copies the current job id to clipboard'
})

server_group:AddButton({
    Text = 'Rejoin Server',
    Func = function()
        teleport_service:TeleportToPlaceInstance(game.PlaceId, game.JobId)
        library:Notify("Rejoining server...")
    end,
    DoubleClick = false,
    Tooltip = 'Rejoins the current server'
})

server_group:AddDivider()

server_group:AddDropdown('selected_server_make_method', {
    Values = { 'Inf Yield', 'Website', 'Javascript', 'Lua' },
    Default = selected_server_make_method,
    Multi = false,
    Text = 'Select Server Make Method:',
    Tooltip = 'Makes server with selected method for example script will be teleporttoinstance with job and place id',
    Callback = function(Value)
        selected_server_make_method = Value
    end
})

server_group:AddButton({
    Text = 'Create Join Link',
    Func = function()
        if selected_server_make_method == "" then
            library:Notify("You need to select a method first")
            return
        end
        if selected_server_make_method == "Inf Yield" then
            setclipboard("roblox://placeId="..game.PlaceId.."&gameInstanceId="..game.JobId)
        elseif selected_server_make_method == "Website" then
            setclipboard("roblox://experiences/start?placeId="..game.PlaceId.."&gameInstanceId="..game.JobId)
        elseif selected_server_make_method == "Javascript" then
            setclipboard("Roblox.GameLauncher.joinGameInstance("..game.PlaceId..", "..game.JobId..")")
        elseif selected_server_make_method == "Lua" then
            setclipboard("game:GetService('TeleportService'):TeleportToPlaceInstance("..game.PlaceId..", "..game.JobId..")")
        end
        library:Notify("Copied join link to clipboard")
    end,
    DoubleClick = false,
    Tooltip = 'Makes join link for your current job id'
})

local frame_timer = tick()
local frame_counter = 0;
local fps = 60;

local watermark_connection = run_service.RenderStepped:Connect(function()
    frame_counter += 1
    if (tick() - frame_timer) >= 1 then
        fps = frame_counter;
        frame_timer = tick();
        frame_counter = 0;
    end

    library:SetWatermark(('%s fps | %s ms | game: '..info.Name..''):format(
        math.floor(fps),
        math.floor(stats.Network.ServerStatsItem['Data Ping']:GetValue())
    ))
end)

menu_group:AddButton('Unload', function()
    auto_buy_cosmetics = false
    auto_plant_seeds = false
    auto_place_eggs = false
    auto_buy_seeds = false
    auto_buy_gears = false
    auto_buy_eggs = false
    auto_favorite = false
    egg_predictor = false
    harvest_aura = false
    hatch_aura = false
    auto_sell = false
    inf_jump = false
    anti_afk = false
    watermark_connection:Disconnect()
    library:Unload()
end)

menu_group:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })
library.ToggleKeybind = Options.MenuKeybind
theme_manager:SetLibrary(library)
save_manager:SetLibrary(library)
save_manager:IgnoreThemeSettings()
save_manager:SetIgnoreIndexes({ 'MenuKeybind' })
theme_manager:SetFolder('Tweeks Do It')
save_manager:SetFolder('Tweeks Do It/Grow A Garden')
save_manager:BuildConfigSection(tabs['ui settings'])
theme_manager:ApplyToTab(tabs['ui settings'])
save_manager:LoadAutoloadConfig()
