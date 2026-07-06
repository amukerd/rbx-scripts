local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- remtoes
local GetOffersRemote = ReplicatedStorage:FindFirstChild("GetOffers", true)
local GetRapRemote = ReplicatedStorage:FindFirstChild("GetRap", true)

-- constants
local WebhookURL = "YOUR_DISCORD_WEBHOOK_URL_HERE"
local MIN_RAP = 10000
local DISCOUNT_THRESHOLD = 0.35 -- percent below rap
local SCAN_INTERVAL = 0.5 -- seconds between stand scans

if not GetOffersRemote or not GetRapRemote then
    warn("Required remote services could not be found. Please check your paths.")
    return
end

-- track stand scan threads
local activeThreads = {}

-- number formatting
local function formatNumber(value)
    local formatted = tostring(value)
    while true do  
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- send webhook
local function sendWebhook(itemName, price, rapValue, sellerName)
    local headers = {["Content-Type"] = "application/json"}
    
    -- formatting
    local message = string.format(
        "🚨 **Deal Found!** 🚨\n**Item:** %s\n**Price:** %s\n**RAP:** %s\n**Seller:** %s",
        itemName,
        formatNumber(price),
        formatNumber(rapValue),
        sellerName
    )
    
    local data = {["content"] = message}
    
    -- request environment
    local requestFunc = http_request or request or HttpPost
    if requestFunc then
        local success, err = pcall(function()
            requestFunc({
                Url = WebhookURL,
                Method = "POST",
                Headers = headers,
                Body = HttpService:JSONEncode(data)
            })
        end)
        if not success then
            warn("[Webhook Error] Failed to send notification: " .. tostring(err))
        end
    else
        warn("[Webhook Error] No valid HTTP request function found in this environment.")
    end
end

-- scan a players stand
local function scanPlayerStand(targetPlayer)
    if targetPlayer == Players.LocalPlayer then return end
    
    local success, offersTable = pcall(function()
        return GetOffersRemote:InvokeServer(targetPlayer)
    end)
    
    if not success or not offersTable then
        return -- no active stand, skip
    end
    
    local actualOffers = offersTable[1] or offersTable
    if type(actualOffers) ~= "table" then return end
    
    for _, offer in ipairs(actualOffers) do
        if offer.Item and offer.Item.Name then
            local itemType = offer.Item.Type or "Unknown"
            local itemName = offer.Item.Name
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
                        
                        -- trigger webhook
                        sendWebhook(itemName, price, rapValue, targetPlayer.Name)
                    end
                end
            end
            task.wait(0.05) -- delay between stand item comparisons
        end
    end
end

-- player scan loop
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

-- start
local function startWatching(player)
    if player == Players.LocalPlayer then return end
    if activeThreads[player] then return end -- already watching
    
    local thread = task.spawn(watchPlayer, player)
    activeThreads[player] = thread
end

-- stop
local function stopWatching(player)
    local thread = activeThreads[player]
    if thread then
        task.cancel(thread)
        activeThreads[player] = nil
        print(string.format("[Monitor] Stopped watching %s", player.Name))
    end
end

-- player join/leave events
Players.PlayerAdded:Connect(startWatching)
Players.PlayerRemoving:Connect(stopWatching)

-- start watching everyone in the lobby
for _, player in ipairs(Players:GetPlayers()) do
    startWatching(player)
end

print("--- Live Lobby Monitor Started ---")
