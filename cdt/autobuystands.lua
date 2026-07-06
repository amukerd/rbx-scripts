local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Define Remote Functions
local GetOffersRemote = ReplicatedStorage:FindFirstChild("GetOffers", true)
local GetRapRemote = ReplicatedStorage:FindFirstChild("GetRap", true)

-- Configuration Constants
local MIN_RAP = 10000
local DISCOUNT_THRESHOLD = 0.35 -- 35% below RAP
local SCAN_INTERVAL = 5 -- seconds between rescans of the same player

if not GetOffersRemote or not GetRapRemote then
    warn("Required remote services could not be found. Please check your paths.")
    return
end

-- Track active threads so we can cancel them when a player leaves
local activeThreads = {}

-- Scans a single player's stand ONCE
local function scanPlayerStand(targetPlayer)
    if targetPlayer == Players.LocalPlayer then return end

    local success, offersTable = pcall(function()
        return GetOffersRemote:InvokeServer(targetPlayer)
    end)

    if not success or not offersTable then
        return -- No active stand, just skip silently (don't spam prints every loop)
    end

    local actualOffers = offersTable[1] or offersTable
    if type(actualOffers) ~= "table" then return end

    for _, offer in ipairs(actualOffers) do
        if offer.Item and offer.Item.Name then
            local itemType = offer.Item.Type or "Unknown"
            local itemName = offer.Item.Name
            local itemCategory = offer.Item.Category
            local price = offer.PriceInTokens

            local rapSuccess, rapResult = pcall(function()
                return GetRapRemote:InvokeServer(itemName)
            end)

            if rapSuccess and rapResult then
                local rapValue = type(rapResult) == "table" and rapResult[1] or rapResult
                rapValue = tonumber(rapValue) or 0

                if rapValue > MIN_RAP then
                    local targetPrice = rapValue * (1 - DISCOUNT_THRESHOLD)

                    if price <= targetPrice then
                        print(string.format("[!!!] DEAL FOUND: %s's %s (%s) is listed for %d (RAP: %d, needed <= %d)",
                            targetPlayer.Name, itemName, itemType, price, rapValue, targetPrice))
                    end
                end
            end

            task.wait(0.2) -- small delay between item checks
        end
    end
end

-- Continuous loop for one player, runs until cancelled
local function watchPlayer(targetPlayer)
    print(string.format("[Monitor] Started watching %s", targetPlayer.Name))

    while true do
        local ok, err = pcall(scanPlayerStand, targetPlayer)
        if not ok then
            warn(string.format("[Monitor] Error scanning %s: %s", targetPlayer.Name, tostring(err)))
        end
        task.wait(SCAN_INTERVAL)
    end
end

-- Start monitoring a player
local function startWatching(player)
    if player == Players.LocalPlayer then return end
    if activeThreads[player] then return end -- already watching

    local thread = task.spawn(watchPlayer, player)
    activeThreads[player] = thread
end

-- Stop monitoring a player
local function stopWatching(player)
    local thread = activeThreads[player]
    if thread then
        task.cancel(thread)
        activeThreads[player] = nil
        print(string.format("[Monitor] Stopped watching %s", player.Name))
    end
end

-- Hook up player join/leave events
Players.PlayerAdded:Connect(startWatching)
Players.PlayerRemoving:Connect(stopWatching)

-- Start watching everyone already in the lobby
for _, player in ipairs(Players:GetPlayers()) do
    startWatching(player)
end

print("--- Live Lobby Monitor Started ---")
