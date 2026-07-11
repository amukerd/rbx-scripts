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
                        else
                            print("Skipped:", carName, rap)
                        end
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

--[[
local args = {
	{
		Type = "Customization",
		Name = "MazdaOfficial10/LegendaryUnderglow",
		Category = "UnderglowTexture"
	},
	1000
}
game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Services"):WaitForChild("TradingHubServiceRemotes"):WaitForChild("OfferAdd"):InvokeServer(unpack(args))
]]--

OnCarsRemoved.OnClientEvent:Connect(function(removedCars)
    for _, car in ipairs(removedCars) do
        if car.Id and ListedCars[car.Id] then
            local data = ListedCars[car.Id]
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

            ListedCars[car.Id] = nil
        end
    end
end)

print("Auto_Sell Executed")

