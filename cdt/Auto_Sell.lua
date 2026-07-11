local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local WebhookURL = "https://discord.com/api/webhooks/1480676513668923627/c-7JOdimxEYnh3Ol2DNcCuzHyPaCrZ015TTlDnGL3aM7Rg42zRJZhFSAc3qmqNK8t51I"

local CarService = ReplicatedStorage.Remotes.Services.CarServiceRemotes
local TradingService = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes
local RapService = ReplicatedStorage.Remotes.Services.RapRemotes
local CustomizationItemsRemotes = require(ReplicatedStorage.Remotes.Services.CustomizationItemsRemotes)
local CarCustomization = require(ReplicatedStorage.Databases.CarCustomization)

local BoothClaim = TradingService.BoothClaim
local GetOwnedCars = CarService.GetOwnedCars
local OfferAdd = TradingService.OfferAdd
local GetRap = RapService.GetRap
local OnOfferAdded = TradingService.OnOfferAdded
local OnOfferRemoved = TradingService.OnOfferRemoved

local ListedOffers = {}

local IconModule = {}
pcall(function()
    local requestFunc = http_request or request or (http and http.request) or HttpPost
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

local function sendWebhook(itemName, price, rapValue, sellerName)
    local requestFunc = http_request or request or (http and http.request) or HttpPost
    if not requestFunc then
        return
    end

    task.spawn(
        function()
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

            if imageUrl ~= "" then
                embedData.thumbnail = {
                    url = imageUrl
                }
            end

            pcall(
                function()
                    requestFunc(
                        {
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
                        }
                    )
                end
            )
        end
    )
end

OnOfferAdded.OnClientEvent:Connect(function(player, offerData)
    if player ~= LocalPlayer then
        return
    end

    local offerId = offerData.OfferId
    local item = offerData.Item

    if item.Type == "Car" then

        ListedOffers[offerId] = {
            Name = item.Name,
            RAP = offerData.PriceInTokens,
            Price = offerData.PriceInTokens
        }

    elseif item.Type == "Customization" then
        local key = item.Category .. "-" .. item.Name

        ListedOffers[offerId] = {
            Name = key,
            RAP = offerData.PriceInTokens,
            Price = offerData.PriceInTokens
        }

    end

    print(
        "Tracking offer:",
        offerId,
        ListedOffers[offerId].Name
    )
end)

for i = 1, 32 do
    TradingService.BoothClaim:FireServer(i)
    task.wait(2)
end

local function listInventoryCars()
    local ownedCars = GetOwnedCars:InvokeServer()

    if ownedCars then
        for _, car in ipairs(ownedCars) do
            task.spawn(
                function()
                    local carName = car.Name
                    local carId = car.Id

                    local success, rap =
                        pcall(
                        function()
                            return GetRap:InvokeServer(carName)
                        end
                    )

                    if success and rap then
                        rap = tonumber(rap) or 0
                    
                        if rap > 10000 and rap < 250000 then
                            OfferAdd:InvokeServer(
                                {
                                    Id = carId,
                                    Type = "Car",
                                    Name = carName
                                },
                                rap
                            )
                    
                            print("Listed:", carName, rap)
                        else
                            print("Skipped:", carName, rap)
                        end
                    end
                end
            )
        end
    end
end

local function listCustomizationItems()

    local items = CustomizationItemsRemotes.GetAll:InvokeServer()

    for category, catItems in pairs(items) do
        for name in pairs(catItems) do

            if category == "Wrap" and name:match("OG") then
                continue
            end

            local itemData = CarCustomization.GetItemData(category, name)
            if itemData and itemData.Untradeable then
                continue
            end

            local rapSuccess, rap = pcall(function()
                return GetRap:InvokeServer(category .. "-" .. name)
            end)

            if rapSuccess and rap then
                rap = tonumber(rap) or 0

                if rap > 10000 and rap < 250000 then

                    local key = category .. "-" .. name

                    local success, err = OfferAdd:InvokeServer(
                        {
                            Type = "Customization",
                            Category = category,
                            Name = name
                        },
                        rap
                    )

                    if success then
                        print("Listed customization:", key, rap)
                    else
                        warn("Failed:", key, err)
                    end
                end
            end

            task.wait(.05)
        end
    end
end

listInventoryCars()
listCustomizationItems()

task.spawn(
    function()
        while true do
            task.wait(300)

            print("Refreshing booth listings...")

            listInventoryCars()
			listCustomizationItems()
        end
    end
)

OnOfferRemoved.OnClientEvent:Connect(function(player, offerId)
    if player ~= LocalPlayer then
        return
    end

    local data = ListedOffers[offerId]
    if not data then
        return
    end

    local currentRap = data.RAP

    local success, rap = pcall(function()
        return GetRap:InvokeServer(data.Name)
    end)

    if success and rap then
        currentRap = tonumber(rap) or currentRap
    end

    sendWebhook(
        data.Name,
        data.Price,
        currentRap,
        LocalPlayer.Name
    )

    ListedOffers[offerId] = nil

    print(
        "Sold:",
        data.Name
    )
end)

print("Auto_Sell Executed")

