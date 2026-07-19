--[[
Game : https://www.roblox.com/games/1554960397
Coded by : Amukerd and most AI's
]]--

task.wait(5)

--- global variables ---
aVars = {}
aVars.Players = game:GetService("Players")
aVars.LocalPlayer = aVars.Players.LocalPlayer
aVars.ReplicatedStorage = game:GetService("ReplicatedStorage")
aVars.HttpService = game:GetService("HttpService")
aVars.RunService = game:GetService("RunService")
aVars.VirtualUser = game:GetService("VirtualUser")
aVars.TeleportService = game:GetService("TeleportService")
aVars.SoundService = game:GetService("SoundService")
aVars.Lighting = game:GetService("Lighting")
aVars.Workspace = game:GetService("Workspace")
aVars.WebhookURL = "https://discord.com/api/webhooks/1480676513668923627/c-7JOdimxEYnh3Ol2DNcCuzHyPaCrZ015TTlDnGL3aM7Rg42zRJZhFSAc3qmqNK8t51I"
aVars.CheckInWebhookURL = "https://discord.com/api/webhooks/1524550847269310494/i8Y0VpiV3caDcLSMOBBGtBpF6RB2RjorTIAXBnn9_MRsZDf40vvbTF0ER5itdEUFfUBT"
aVars.requestFunc = http_request or request or (http and http.request) or HttpPost
aVars.ScriptStartTime = os.time()

--- game variables ---
aVars.GetOffersRemote = aVars.ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.GetOffers
aVars.GetOwnedCarsRemote = aVars.ReplicatedStorage.Remotes.Services.CarServiceRemotes.GetOwnedCars
aVars.GetRapRemote = aVars.ReplicatedStorage.Remotes.Services.RapRemotes.GetRap
aVars.OfferPurchaseRemote = aVars.ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.OfferPurchase
aVars.OfferAddRemote = aVars.ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.OfferAdd
aVars.BoothClaimRemote = aVars.ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.BoothClaim

aVars.OnOfferAddedEvent = aVars.ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.OnOfferAdded
aVars.OnOfferRemovedEvent = aVars.ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.OnOfferRemoved

aVars.PlayerBooths = aVars.Workspace:WaitForChild("Map"):WaitForChild("PlayerBooths")
aVars.TradingUtil = require(aVars.ReplicatedStorage.Util.TradingUtil)

--- script variables ---
aVars.AutoBuy = {}
aVars.AutoBuy.RapPercentAbove = 0.80
aVars.AutoBuy.RapValueTop = 25000
aVars.AutoBuy.RapPercentBelow = 0.50
aVars.AutoBuy.RapValueBottom = 10000

aVars.AutoSell = {}
aVars.AutoSell.MinRap = 0
aVars.AutoSell.MaxRap = 250000
aVars.AutoSell.RefreshingListingsTime = 300

aVars.CheckIn = {}
aVars.CheckIn.SendPlayerCheckInTime = 1800

aVars.FirstUnclaimed = nil

--- tables ---
aVars.IconModule = aVars.HttpService:JSONDecode(aVars.requestFunc({Url="https://amukerd.github.io/rbx-scripts/cdt/Icons/Icon_Module.json",Method="GET"}).Body)
aVars.BoughtItems = {}
aVars.PendingBuys = {}
aVars.ProcessedBuyOffers = {}
aVars.ListedOffers = {}

--- antiafk ---
aVars.LocalPlayer.Idled:Connect(function()
    aVars.VirtualUser:CaptureController()
    aVars.VirtualUser:ClickButton2(Vector2.new())
end)

--- webhook number formatting
local function formatNumber(value)
    return tostring(value):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

--- buttons library ---
loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/cdt/Buttons.lua"))()

--- boothclaiming ---
for _, booth in ipairs(aVars.PlayerBooths:GetChildren()) do
    if not booth:GetAttribute("OwnerId") then
        aVars.FirstUnclaimed = booth
        aVars.BoothId = tonumber(booth.Name:match("PlayerBooth(%d+)"))
        print("Claimed Booth", booth.Name)
        aVars.BoothClaimRemote:FireServer(aVars.BoothId)
        break
    end
end
task.wait(1)

--- fps boosting ---
aVars.SoundService:ClearAllChildren()
aVars.Lighting:ClearAllChildren()
aVars.Lighting.GlobalShadows = false
aVars.RunService:Set3dRenderingEnabled(false)
setfpscap(10)

task.spawn(function()
    while true do
        for _, player in ipairs(aVars.Players:GetPlayers()) do
            if player.Character then
                player.Character:Destroy()
            end
        end
        for _, object in ipairs(workspace:GetChildren()) do
            if not object:IsA("Camera") 
               and not object:IsA("Terrain") then
                object:Destroy()
            end
        end
        task.wait(5)
    end
end)

--- check in ---
local function sendCheckIn()
    local PlayerName = aVars.LocalPlayer.Name    
    local Ping = math.round(aVars.LocalPlayer:GetNetworkPing() * 1000)
    
    local PlayerSessionMins = math.floor((os.time() - aVars.ScriptStartTime) / 60)

    local PlayerCount = #aVars.Players:GetPlayers()
    local JobId = game.JobId ~= "" and game.JobId

    local embedData = {
        title = aVars.LocalPlayer.Name .. " Check In",
        color = 2067276,
        fields = {
            {
                name = "Player Info",
                value = string.format("**Username:** %s", PlayerName),
                inline = true
            },
            {
                name = "Performance Data",
                value = string.format("**Ping:** %d ms", Ping),
                inline = true
            },
            {
                name = "Session & Server Time",
                value = string.format("**Session Duration:** %d mins", PlayerSessionMins),
                inline = false
            },
            {
                name = "Server Environment",
                value = string.format("**Players in Server:** %d\n**Job ID:** `%s`", PlayerCount, JobId),
                inline = false
            }
        },
        timestamp = DateTime.now():ToIsoDate()
    }

    pcall(function()
        aVars.requestFunc({Url=aVars.CheckInWebhookURL,Method="POST",Headers={["Content-Type"]="application/json"},Body=aVars.HttpService:JSONEncode({embeds={embedData}})})
    end)
end

task.spawn(function()
    sendCheckIn()
    while true do
        task.wait(1800)
        print("Check In Sent")
        sendCheckIn()
    end
end)

--- auto buy/sell webhook ---
local function sendWebhook(itemName, price, rapValue, sellerName, action)
    task.spawn(function()
        local displayName = aVars.IconModule[itemName] or itemName
        local imageKey = tostring(itemName):gsub("/", "_")
        local imageUrl = "https://amukerd.github.io/rbx-scripts/cdt/Icons/" .. imageKey .. ".png"

        local embedData = {
            title = aVars.LocalPlayer.Name .. " " .. action .. " Offer",
            color = action == "Sold" and 255 or 16711680,
            fields = {
                {
                    name = "Item Name",
                    value = tostring(displayName),
                    inline = true
                },
                {
                    name = "Price",
                    value = tostring(formatNumber(price)),
                    inline = true
                },
                {
                    name = "RAP",
                    value = tostring(formatNumber(rapValue)),
                    inline = true
                }
            }
        }

        if sellerName then
            table.insert(embedData.fields, {
                name = "Seller",
                value = tostring(sellerName),
                inline = false
            })
        end

        embedData.thumbnail = {
            url = imageUrl
        }

        pcall(function()
            aVars.requestFunc({
                Url = aVars.WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = aVars.HttpService:JSONEncode({
                    embeds = {embedData}
                })
            })
        end)
    end)
end

--- auto buy function ---
local function getRap(targetPlayer, offer)
    local offerId = offer.OfferId
    if not offerId then return end

    if aVars.BoughtItems[offerId] or aVars.PendingBuys[offerId] then
        return
    end

    if offer.Item and (offer.Item.Type == "Car" or offer.Item.Type == "Customization") then
        local itemName = offer.Item.Name
        local rapName = itemName

        if offer.Item.Type == "Customization" then
            rapName = offer.Item.Category .. "-" .. itemName
        end

        local price = offer.PriceInTokens

        if price then
            task.wait(0.01)

            local rapSuccess, rapValue = pcall(function()
                return aVars.GetRapRemote:InvokeServer(rapName)
            end)

            if rapSuccess and rapValue then
                if (rapValue >= aVars.AutoBuy.RapValueTop and price <= (rapValue * aVars.AutoBuy.RapPercentAbove)) 
                or (rapValue >= aVars.AutoBuy.RapValueBottom and rapValue < aVars.AutoBuy.RapValueTop and price <= (rapValue * aVars.AutoBuy.RapPercentBelow)) then
                    
                    aVars.PendingBuys[offerId] = true

                    local buySuccess, result = pcall(function()
                        return aVars.OfferPurchaseRemote:InvokeServer(targetPlayer, offer)
                    end)

                    aVars.PendingBuys[offerId] = nil

                    if buySuccess and result then
                        aVars.BoughtItems[offerId] = true

                        print("Purchase Successful:", itemName, "from", targetPlayer.Name)

                        sendWebhook(
                            itemName,
                            price,
                            rapValue,
                            targetPlayer.Name,
                            "Bought"
                        )
                    else
                        warn("Purchase failed:", itemName, result)
                    end
                end
            end
        end
    end
end

--- initial search loop ---

for _, player in ipairs(aVars.Players:GetPlayers()) do
    if player ~= aVars.LocalPlayer then
        local success, offers = pcall(function()
            return aVars.GetOffersRemote:InvokeServer(player)
        end)

        if success and typeof(offers) == "table" then
            for _, offer in ipairs(offers) do
                task.spawn(getRap, player, offer)
            end
        end
    end
end

--- auto buy main loop ---

aVars.OnOfferAddedEvent.OnClientEvent:Connect(function(targetPlayer, offerTable)
    if not targetPlayer or typeof(offerTable) ~= "table" or targetPlayer == aVars.LocalPlayer then
        return
    end

    task.spawn(getRap, targetPlayer, offerTable)
end)

--- auto sell function ---
local function listCars()
    local ownedCars = aVars.GetOwnedCarsRemote:InvokeServer()

    for _, car in ipairs(ownedCars) do
        if aVars.TradingUtil.CanTradeCar(aVars.LocalPlayer, car) then
            local success, rap = pcall(function()
                return aVars.GetRapRemote:InvokeServer(car.Name)
            end)

            if success and rap then
                rap = tonumber(rap) or 0

                if rap > aVars.AutoSell.MinRap and rap < aVars.AutoSell.MaxRap then
                    local listed, err = pcall(function()
                        return aVars.OfferAddRemote:InvokeServer({
                            Type = "Car",
                            Name = car.Name,
                            Id = car.Id
                        }, rap)
                    end)
                    if listed then
                        print("Listed", car.Name)
                    end
                end
            end
        end
    end
end

--- auto sell client events ---

aVars.OnOfferAddedEvent.OnClientEvent:Connect(function(player, offerData)
    if player ~= aVars.LocalPlayer then
        return
    end

    if offerData.Item.Type ~= "Car" then
        return
    end

    aVars.ListedOffers[offerData.OfferId] = {
        ItemName = offerData.Item.Name,
        Price = offerData.PriceInTokens,
    }
end)

aVars.OnOfferRemovedEvent.OnClientEvent:Connect(function(player, offerId)
    if player ~= aVars.LocalPlayer then
        return
    end

    local data = aVars.ListedOffers[offerId]
    if not data then
        return
    end

    local currentRap = 0

    local success, rap = pcall(function()
        return aVars.GetRapRemote:InvokeServer(data.ItemName)
    end)

    if success and rap then
        currentRap = tonumber(rap) or currentRap
    end

    print("Sold " .. data.ItemName)
        
    sendWebhook(data.ItemName, data.Price, currentRap, nil, "Sold")

    aVars.ListedOffers[offerId] = nil
end)

--- auto sell main loop ---

task.spawn(function()
    listCars()

    while true do
        task.wait(aVars.AutoSell.RefreshingListingsTime)
        print("Refreshing cars")
        listCars()
    end
end)

--- maybe later ---
--[[
local TradingUtil = require(ReplicatedStorage.Util.TradingUtil)
local TradingHubServiceRemotes = require(ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes)
local CustomizationItemsRemotes = require(ReplicatedStorage.Remotes.Services.CustomizationItemsRemotes)

local allItems = CustomizationItemsRemotes.GetAll:InvokeServer()
for category, items in pairs(allItems) do
    for name, amount in pairs(items) do
        if amount > 0 and TradingUtil.CanTradeCustomizationItem(player, category, name) then
            local ok, err = TradingHubServiceRemotes.OfferAdd:InvokeServer({
                Type = "Customization",
                Category = category,
                Name = name
            }, PRICE)
        end
    end
end
]]--

print("Script Initialized")
