loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/cdt/FPS_Antiafk.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local GetOffersRemote = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.GetOffers
local GetRapRemote = ReplicatedStorage.Remotes.Services.RapRemotes.GetRap
local OfferPurchaseRemote = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.OfferPurchase
local OnOfferAddedEvent = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.OnOfferAdded

local WebhookURL = "https://discord.com/api/webhooks/1480676513668923627/c-7JOdimxEYnh3Ol2DNcCuzHyPaCrZ015TTlDnGL3aM7Rg42zRJZhFSAc3qmqNK8t51I"

local IconModule = {}
pcall(function()
    local requestFunc = http_request or request or (http and http.request) or HttpPost
    if requestFunc then
        local res = requestFunc({ Url = "https://amukerd.github.io/rbx-scripts/cdt/Icon_Module.json", Method = "GET" })
        if res and res.Body then
            IconModule = HttpService:JSONDecode(res.Body)
        end
    end
end)

local RAP_PERCENT = 0.80
local RAP_PERCENT_UNDER = 0.50

local boughtItems = {}
local processedOffers = {}

local function formatNumber(value)
    return tostring(value):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

local function sendWebhook(itemName, price, rapValue, sellerName)
    local requestFunc = http_request or request or (http and http.request) or HttpPost
    if not requestFunc then return end

    task.spawn(function()
        local imageUrl = ""
        local displayName = itemName

        local itemData = IconModule[itemName]
        local assetId = nil

        if itemData and typeof(itemData) == "table" then
            displayName = itemData.Name or itemName
            assetId = itemData.Id
        end

        if assetId then
            local thumbApiUrl = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. tostring(assetId) .. "&returnPolicy=PlaceHolder&size=420x420&format=png"
            
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

        local embedData = {
            title = LocalPlayer.Name .. " Bought Offer",
            color = 16711680,
            fields = {
                { name = "Item Name", value = tostring(displayName), inline = true },
                { name = "Price", value = tostring(formatNumber(price)), inline = true },
                { name = "RAP", value = tostring(formatNumber(rapValue)), inline = true },
                { name = "Seller", value = tostring(sellerName), inline = false }
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
    end)
end

local function getRap(targetPlayer, offer)
    local offerId = offer.OfferId
    if not offerId or processedOffers[offerId] then return end
    processedOffers[offerId] = true

    if offer.Item and (offer.Item.Type == "Car" or offer.Item.Type == "Customization") then
        local itemName = offer.Item.Name
        local rapName = itemName

        if offer.Item.Type == "Customization" then
            rapName = offer.Item.Category .. "-" .. itemName
        end

        local price = offer.PriceInTokens
        if price and not boughtItems[offerId] then
            task.wait(0.01)
            local rapSuccess, rapValue = pcall(function()
                return GetRapRemote:InvokeServer(rapName)
            end)

            if rapSuccess and rapValue then
                
                print(string.format("[RAP RESULT] %s RAP: %s | Price: %s", rapName, tostring(rapValue), tostring(price)))
                
                if (rapValue >= 25000 and price <= (rapValue * RAP_PERCENT)) or (rapValue >= 10000 and rapValue < 25000 and price <= (rapValue * RAP_PERCENT_UNDER)) then
                    boughtItems[offerId] = true
                    local buySuccess, result = pcall(function()
                        return OfferPurchaseRemote:InvokeServer(targetPlayer, offer)
                    end)

                    if buySuccess and result then
                        print("Purchase Successful:", itemName, "from", targetPlayer.Name)
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

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        local success, offers = pcall(function()
            return GetOffersRemote:InvokeServer(player)
        end)

        if success and typeof(offers) == "table" then
            for _, offer in ipairs(offers) do
                task.spawn(getRap, player, offer)
            end
        end
    end
end

OnOfferAddedEvent.OnClientEvent:Connect(function(targetPlayer, offerTable)
    if not targetPlayer or typeof(offerTable) ~= "table" or targetPlayer == LocalPlayer then 
        return 
    end
    
    task.spawn(getRap, targetPlayer, offerTable)
end)

print("Auto_Buy Executed")

loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/cdt/Check_In.lua"))()
loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/cdt/Auto_Sell.lua"))()
