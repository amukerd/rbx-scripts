local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local BlockedUsers={[4512510904]=true,[8083594000]=true,[8083636321]=true,[8083664487]=true}

task.spawn(function()
    while task.wait(5) do
        if #Players:GetPlayers() < 10 then
            TeleportService:Teleport(1554960397, LocalPlayer)
            return
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and BlockedUsers[player.UserId] then
                TeleportService:Teleport(1554960397, LocalPlayer)
                return
            end
        end
    end
end)

setfpscap(20)

if getconnections then
    for _, connection in ipairs(getconnections(LocalPlayer.Idled)) do
        if connection.Disable then
            connection:Disable()
        elseif connection.Disconnect then
            connection:Disconnect()
        end
    end
else
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local GetOffersRemote = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.GetOffers
local GetRapRemote = ReplicatedStorage.Remotes.Services.RapRemotes.GetRap
local OfferPurchaseRemote = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.OfferPurchase

local WebhookURL = "https://discord.com/api/webhooks/1480676513668923627/c-7JOdimxEYnh3Ol2DNcCuzHyPaCrZ015TTlDnGL3aM7Rg42zRJZhFSAc3qmqNK8t51I"
local MIN_RAP = 10000
local DISCOUNT_THRESHOLD = 0.10
local SCAN_INTERVAL = 0.5

local activeThreads = {}

local function formatNumber(value)
    local formatted = tostring(value)
    while true do  
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function sendWebhook(itemName, price, rapValue, sellerName)
    local headers = {["Content-Type"] = "application/json"}
    
    local message = string.format(
        "🚨 **Deal Found!** 🚨\n**Player:** %s\n**Item:** %s\n**Price:** %s\n**RAP:** %s\n**Seller:** %s",
        Players.LocalPlayer.Name,
        itemName,
        formatNumber(price),
        formatNumber(rapValue),
        sellerName
    )
    
    local data = {["content"] = message}
    
    local requestFunc = http_request or request or HttpPost
    if requestFunc then
        local success, err = pcall(function()
            requestFunc({
                Url = WebhookURL,
                Method = "POST",
                Headers = headers,
                Body = HttpService:JSONEncode(data)
            })
        end)
        if not success then
            warn("[Webhook Error] Failed to send notification: " .. tostring(err))
        end
    end
end

local function scanPlayerStand(targetPlayer)
    if targetPlayer == Players.LocalPlayer then
        return
    end

    local success, offersTable = pcall(function()
        return GetOffersRemote:InvokeServer(targetPlayer)
    end)

    if not success or not offersTable then
        return
    end

    if type(offersTable) ~= "table" then
        return
    end
    
    for _, offer in ipairs(offersTable) do
        if offer.Item and offer.Item.Type == "Car" then
            local itemType = offer.Item.Type
            local itemName = offer.Item.Name
            local price = tonumber(offer.PriceInTokens)

            local rapSuccess, rapResult = pcall(function()
                return GetRapRemote:InvokeServer(itemName)
            end)

            if rapSuccess then
                local rapValue = rapResult

                if rapValue > MIN_RAP then
                    local targetPrice = rapValue * (1 - DISCOUNT_THRESHOLD)

                    if price <= targetPrice then
                        print(string.format(
                            "[BUYING] %s's %s (%s) for %d (RAP: %d)",
                            targetPlayer.Name,
                            itemName,
                            itemType,
                            price,
                            rapValue
                        ))

                        sendWebhook(itemName, price, rapValue, targetPlayer.Name)

                        local purchaseSuccess, purchaseResult = pcall(function()
                            return OfferPurchaseRemote:InvokeServer(targetPlayer, offer)
                        end)

                        if purchaseSuccess then
                            print("Purchase successful:", itemName)
                        else
                            warn("Purchase failed:", purchaseResult)
                        end
                    end
                end
            end

            task.wait(0.05)
        end
    end
end

local function watchPlayer(targetPlayer)
    while true do
        local ok, err = pcall(scanPlayerStand, targetPlayer)
        task.wait(SCAN_INTERVAL)
    end
end

local function startWatching(player)
    if player == Players.LocalPlayer then return end
    if activeThreads[player] then return end
    
    local thread = task.spawn(watchPlayer, player)
    activeThreads[player] = thread
end

local function stopWatching(player)
    local thread = activeThreads[player]
    if thread then
        task.cancel(thread)
        activeThreads[player] = nil
    end
end

Players.PlayerAdded:Connect(startWatching)
Players.PlayerRemoving:Connect(stopWatching)

for _, player in ipairs(Players:GetPlayers()) do
    startWatching(player)
end

print("--- Lobby Monitor Started ---")









local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local GetOffersRemote = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.GetOffers
local GetRapRemote = ReplicatedStorage.Remotes.Services.RapRemotes.GetRap
local OfferPurchaseRemote = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.OfferPurchase

local targetPlayer = Players:FindFirstChild(targetName)

if not targetPlayer then
    warn("Player not found:", targetName)
    return
end

local success, offers = pcall(function()
    return GetOffersRemote:InvokeServer(targetPlayer)
end)

if not success then
    warn(offers)
    return
end

if typeof(offers) == "table" then

    for i, offer in ipairs(offers) do

        if offer.Item then

            local itemName = offer.Item.Name

            local rapSuccess, rapResult = pcall(function()
                return GetRapRemote:InvokeServer(itemName)
            end)

            local purchaseSuccess, purchaseResult = pcall(function()
                return OfferPurchaseRemote:InvokeServer(targetPlayer, offer)
            end)
        end
    end
end
