local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local WebhookURL = "https://discord.com/api/webhooks/1480676513668923627/c-7JOdimxEYnh3Ol2DNcCuzHyPaCrZ015TTlDnGL3aM7Rg42zRJZhFSAc3qmqNK8t51I"

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local components = workspace:WaitForChild("Components")
local crateListPath = components:WaitForChild("ControlPoints"):WaitForChild("Center"):WaitForChild("capturePointUI"):WaitForChild("main"):WaitForChild("rewardFrame"):WaitForChild("crateList")
local premiumCrate = crateListPath:WaitForChild("premiumCrate")
local notificationPath = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("notificationPopup"):WaitForChild("itemNotification")

--game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Resources"):WaitForChild("LootCrateResources"):WaitForChild("Remotes"):WaitForChild("ToggleTenOpen"):FireServer()
--local openRemote = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Resources"):WaitForChild("LootCrateResources"):WaitForChild("Remotes"):WaitForChild("OpenLootCrate")
--
--task.spawn(function()
--    while not premiumCrate.Visible do
--        openRemote:FireServer("Elite")
--        task.wait(0.5)
--    end
--end)

local structuresFolder = workspace:WaitForChild("Plots"):WaitForChild(LocalPlayer.Name .. "'s plot"):WaitForChild("baseplate"):WaitForChild("Structures")
local collectRemote = game.ReplicatedStorage.Shared.Resources.PlotResources.Remotes.Collect

for _, structure in pairs(structuresFolder:GetChildren()) do
    collectRemote:FireServer(structure)
    task.wait() 
end

local function sendWebhook(message)
    local headers = {["Content-Type"] = "application/json"}
    local data = {["content"] = message}
    
    local requestFunc = http_request or request or HttpPost
    if requestFunc then
        requestFunc({
            Url = WebhookURL,
            Method = "POST",
            Headers = headers,
            Body = HttpService:JSONEncode(data)
        })
    end
end

local function rejoin()
    task.wait(1)
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\nRejoining...")
        task.wait() 
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        LocalPlayer:Kick("\nServer not empty. Disconnecting.")
    end
end

if premiumCrate.Visible then
    sendWebhook("Premium Crate")

    local newChild = notificationPath.ChildAdded:Wait()

    if newChild.Name == "TEMPLATE" then
        local main = newChild:WaitForChild("main", 5)
        local itemNameLabel = main and main:WaitForChild("itemName", 5)
        
        if itemNameLabel then
            task.wait(0.1) 
            sendWebhook(itemNameLabel.Text)
        end
    end
end

rejoin()
