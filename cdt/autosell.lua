local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local WebhookURL = "YOUR_WEBHOOK_HERE"

local CarService = ReplicatedStorage.Remotes.Services.CarServiceRemotes
local TradingService = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes
local RapService = ReplicatedStorage.Remotes.Services.RapRemotes

local BoothClaim = TradingService.BoothClaim
local GetOwnedCars = CarService.GetOwnedCars
local OfferAdd = TradingService.OfferAdd
local GetRap = RapService.GetRap
local OnCarsRemoved = CarService.OnCarsRemoved

local ListedCars = {}

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
            local embedData = {
                title = itemName .. " Sold",
                color = 255,
                fields = {
                    {
                        name = "Car Name",
                        value = tostring(itemName),
                        inline = true
                    },
                    {
                        name = "Sold Price",
                        value = tostring(formatNumber(price)),
                        inline = true
                    },
                    {
                        name = "RAP",
                        value = tostring(formatNumber(rapValue)),
                        inline = true
                    },
                    {
                        name = "Seller",
                        value = tostring(sellerName),
                        inline = false
                    }
                }
            }

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

for i = 1, 32 do
    task.spawn(function()
        BoothClaim:FireServer(
            i,
            "Invalid booth name"
        )
    end)
end
task.wait(1)

local ownedCars = GetOwnedCars:InvokeServer()

if ownedCars and ownedCars[1] then
    for _, car in ipairs(ownedCars[1]) do
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

                    ListedCars[carId] = {
                        Name = carName,
                        RAP = rap,
                        Price = rap
                    }

                    task.wait(.1)

                    OfferAdd:InvokeServer(
                        {
                            Id = carId,
                            Type = "Car",
                            Name = carName
                        },
                        rap
                    )

                    print("Listed:", carName, "for", rap)
                end
            end
        )
    end
end

OnCarsRemoved.OnClientEvent:Connect(
    function(removedCars)
        for _, car in ipairs(removedCars) do
            if car.Id and ListedCars[car.Id] then
                local data = ListedCars[car.Id]

                sendWebhook(data.Name, data.Price, data.RAP, LocalPlayer.Name)

                ListedCars[car.Id] = nil
            end
        end
    end
)
