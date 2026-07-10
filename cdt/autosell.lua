local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local WebhookURL = "https://discord.com/api/webhooks/1480676513668923627/c-7JOdimxEYnh3Ol2DNcCuzHyPaCrZ015TTlDnGL3aM7Rg42zRJZhFSAc3qmqNK8t51I"

local CarService = ReplicatedStorage.Remotes.Services.CarServiceRemotes
local TradingService = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes
local RapService = ReplicatedStorage.Remotes.Services.RapRemotes

local BoothClaim = TradingService.BoothClaim
local GetOwnedCars = CarService.GetOwnedCars
local OfferAdd = TradingService.OfferAdd
local GetRap = RapService.GetRap
local OnCarsRemoved = CarService.OnCarsRemoved

local ListedCars = {}

local IconModule = {}
pcall(
    function()
        local requestFunc = http_request or request or (http and http.request) or HttpPost
        if requestFunc then
            local res =
                requestFunc({Url = "https://amukerd.github.io/rbx-scripts/cdt/icon_module.json", Method = "GET"})
            if res and res.Body then
                IconModule = HttpService:JSONDecode(res.Body)
            end
        end
    end
)

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
            local imageUrl = ""
            local displayName = itemName
            local assetId = nil

            local itemData = IconModule[itemName]

            if itemData and typeof(itemData) == "table" then
                displayName = itemData.Name or itemName
                assetId = itemData.Id
            end

            if assetId then
                local thumbApiUrl =
                    "https://thumbnails.roblox.com/v1/assets?assetIds=" ..
                    tostring(assetId) .. "&returnPolicy=PlaceHolder&size=420x420&format=png"

                pcall(
                    function()
                        local res =
                            requestFunc(
                            {
                                Url = thumbApiUrl,
                                Method = "GET"
                            }
                        )

                        if res and res.Body then
                            local data = HttpService:JSONDecode(res.Body)

                            if data and data.data and data.data[1] then
                                imageUrl = data.data[1].imageUrl or ""
                            end
                        end
                    end
                )
            end

            local embedData = {
                title = "Sold " .. displayName,
                color = 255,
                fields = {
                    {
                        name = "Car Name",
                        value = tostring(displayName),
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

for i = 1, 32 do
    task.spawn(
        function()
            BoothClaim:FireServer(i, "Invalid booth name")
            task.wait(0.1)
        end
    )
end
task.wait(5)

local function listInventoryCars()
    local ownedCars = GetOwnedCars:InvokeServer()

    if ownedCars then
        print("Cars found:", #ownedCars)

        for _, car in ipairs(ownedCars) do
            print("Processing:", car.Name, car.Id)

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

                    print("RAP:", carName, rap)

                    if success and rap then
                        rap = tonumber(rap) or 0

                        ListedCars[carId] = {
                            Name = carName,
                            RAP = rap,
                            Price = rap
                        }

                        OfferAdd:InvokeServer(
                            {
                                Id = carId,
                                Type = "Car",
                                Name = carName
                            },
                            rap
                        )

                        print("Listed:", carName, rap)
                    end
                end
            )
        end
    end
end

listInventoryCars()

task.spawn(
    function()
        while true do
            task.wait(300)

            print("Refreshing booth listings...")

            listInventoryCars()
        end
    end
)

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
