loadstring(game:HttpGet("https://raw.githubusercontent.com/amukerd/rbx-scripts/refs/heads/main/cdt/extra.lua"))()

local CarsDatabase = require(ReplicatedStorage:WaitForChild("Databases"):WaitForChild("Cars"))
local CustomizationDatabase = require(ReplicatedStorage:WaitForChild("Databases"):WaitForChild("Customization") or ReplicatedStorage:WaitForChild("Databases"):WaitForChild("Icons"):WaitForChild("Common"))

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local GetOffersRemote = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.GetOffers
local GetRapRemote = ReplicatedStorage.Remotes.Services.RapRemotes.GetRap
local OfferPurchaseRemote = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.OfferPurchase

local WebhookURL = "https://discord.com/api/webhooks/1480676513668923627/c-7JOdimxEYnh3Ol2DNcCuzHyPaCrZ015TTlDnGL3aM7Rg42zRJZhFSAc3qmqNK8t51I"

local RAP_PERCENT = 0.85
local SCAN_INTERVAL = 1

local activeThreads = {}
local boughtItems = {}

local function formatNumber(value)
    local formatted = tostring(value)

    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")

        if k == 0 then
            break
        end
    end

    return formatted
end

local function sendWebhook(itemName, price, rapValue, sellerName)
    local requestFunc = http_request or request or (http and http.request) or HttpPost

    local itemData = CarsDatabase[itemName] or CustomizationDatabase[itemName]
    local imageUrl = ""

    if itemData and itemData.Image then
        local assetId = string.match(itemData.Image, "%d+")
        
        if assetId then
            local thumbApiUrl = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&returnPolicy=PlaceHolder&size=420x420&format=png"
            
            pcall(function()
                local res = requestFunc({
                    Url = thumbApiUrl,
                    Method = "GET"
                })
                if res and res.Body then
                    local data = HttpService:JSONDecode(res.Body)
                    if data and data.data and data.data[1] then
                        imageUrl = data.data[1].imageUrl or ""
                    end
                end
            end)
        end
    end

    local embedData = {
        title = "Item Bought",
        color = 16711680,
        fields = {
            { name = "Item Name:", value = tostring(itemName), inline = true },
            { name = "Price:", value = tostring(formatNumber(price)), inline = true },
            { name = "RAP:", value = tostring(formatNumber(rapValue)), inline = true },
            { name = "Seller:", value = tostring(sellerName), inline = false }
        }
    }

    if imageUrl ~= "" then
        embedData.thumbnail = {
            url = imageUrl
        }
    end

    pcall(function()
        requestFunc({
            Url = WebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                embeds = { embedData }
            })
        })
    end)
end

local function scanPlayerStand(targetPlayer)
    local success, offers =
        pcall(
        function()
            return GetOffersRemote:InvokeServer(targetPlayer)
        end
    )

    if not success or typeof(offers) ~= "table" then
        return
    end

    for _, offer in ipairs(offers) do
        
        if offer.Item and (offer.Item.Type == "Car" or offer.Item.Type == "Customization") then
            
            local offerId = offer.OfferId
            local itemName = offer.Item.Name
            local rapName = itemName
            
            if offer.Item.Type == "Customization" then
                rapName = offer.Item.Category .. "-" .. itemName
            end
            local price = offer.PriceInTokens

            if price and not boughtItems[offerId] then

                task.wait(0.1)

                local rapSuccess, rapValue =
                    pcall(
                    function()
                        return GetRapRemote:InvokeServer(rapName)
                    end
                )

                if rapSuccess and rapValue then
                    if rapValue >= 15000 and price <= (rapValue * RAP_PERCENT) then
                        boughtItems[offerId] = true

                        local buySuccess, result =
                            pcall(
                            function()
                                return OfferPurchaseRemote:InvokeServer(targetPlayer, offer)
                            end
                        )

                        if buySuccess and result then
                            print("Purchase Response:", buySuccess, result)

                            sendWebhook(itemName, price, rapValue, targetPlayer.Name)
                        else
                            boughtItems[offerId] = nil
                        
                            warn("Purchase failed:", itemName, result)
                        end
                    end
                end
            end
        end
    end
end

local function watchPlayer(targetPlayer)
    while targetPlayer.Parent do
        pcall(
            function()
                scanPlayerStand(targetPlayer)
            end
        )

        task.wait(SCAN_INTERVAL)
    end
end

local function startWatching(player)
    if player == LocalPlayer then
        return
    end

    if activeThreads[player] then
        return
    end

    activeThreads[player] =
        task.spawn(
        function()
            watchPlayer(player)
        end
    )
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
