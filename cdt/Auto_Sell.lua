local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local WebhookURL = "https://discord.com/api/webhooks/1480676513668923627/c-7JOdimxEYnh3Ol2DNcCuzHyPaCrZ015TTlDnGL3aM7Rg42zRJZhFSAc3qmqNK8t51I"
local requestFunc = http_request or request or (http and http.request) or HttpPost

local TradingUtil = require(ReplicatedStorage.Util.TradingUtil)
local TradingService = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes

local GetOwnedCars = ReplicatedStorage.Remotes.Services.CarServiceRemotes.GetOwnedCars
local GetRap = ReplicatedStorage.Remotes.Services.RapRemotes.GetRap
local OfferAdd = TradingService.OfferAdd
local OnOfferAdded = TradingService.OnOfferAdded
local OnOfferRemoved = TradingService.OnOfferRemoved

local ListedOffers = {}
local IconModule = {}

pcall(function()
    if requestFunc then
        local res = requestFunc({
            Url = "https://amukerd.github.io/rbx-scripts/cdt/Icons/Icon_Module.json",
            Method = "GET"
        })

        if res and res.Body then
            IconModule = HttpService:JSONDecode(res.Body)
        end
    end
end)

local function formatNumber(num)
    num = tonumber(num) or 0
    return tostring(num):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function sendWebhook(itemName, price, rapValue)
	task.spawn(function()
	    local displayName = IconModule[itemName] or itemName
		local imageKey = tostring(itemName):gsub("/", "_")
		local imageUrl = "https://amukerd.github.io/rbx-scripts/cdt/Icons/" .. imageKey .. ".png"
	
	    local embedData = {
	        title = LocalPlayer.Name .. " Sold Offer",
	        color = 255,
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
	
	    embedData.thumbnail = {
	        url = imageUrl
	    }
	
	    requestFunc({
	        Url = WebhookURL,
	        Method = "POST",
	        Headers = {
	            ["Content-Type"] = "application/json"
	        },
	        Body = HttpService:JSONEncode(
	            {
	                embeds = {
	                    embedData
	                }
	            }
	        )
	    })
	end)
end

OnOfferAdded.OnClientEvent:Connect(function(player, offerData)
    if player ~= LocalPlayer then
        return
    end

    if offerData.Item.Type ~= "Car" then
        return
    end

    ListedOffers[offerData.OfferId] = {
        Name = offerData.Item.Name,
        Price = offerData.PriceInTokens,
        RAP = offerData.PriceInTokens
    }
end)

local function listCars()
    local ownedCars = GetOwnedCars:InvokeServer()

    for _, car in ipairs(ownedCars) do
        if TradingUtil.CanTradeCar(LocalPlayer, car) then
            local success, rap =
                pcall(function()
                    return GetRap:InvokeServer(car.Name)
                end)

            if success and rap then
                rap = tonumber(rap) or 0

                if rap > 0 and rap < 250000 then
                    local listed, err = OfferAdd:InvokeServer({
                        Type = "Car",
                        Name = car.Name,
                        Id = car.Id
                    },
                    rap)
                end
            end
        end
    end
end

listCars()

task.spawn(function()
    while true do
        task.wait(300)
        print("Refreshing cars")
        listCars()
    end
end)

OnOfferRemoved.OnClientEvent:Connect(function(player, offerId)
    if player ~= LocalPlayer then
        return
    end

    local data = ListedOffers[offerId]
    local currentRap = data.RAP

    local success, rap = pcall(function()
        return GetRap:InvokeServer(data.Name)
    end)

    if success and rap then
        currentRap = tonumber(rap) or currentRap
    end

    sendWebhook(data.Name, data.Price, currentRap)
    ListedOffers[offerId] = nil
end)

print("Auto_Sell Executed")
