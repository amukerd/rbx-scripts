if game.PlaceId == 1554960397 then
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    
    local JobId = game.JobId
    
    local playerRanks = {
        ["NeonVelocity739"] = 1,
        ["bawasCDT1"] = 2,
        ["bawasCDT2"] = 3,
        ["bawasCDT3"] = 4,
        ["bawasCDT4"] = 5,
    }
    
    local localPlayer = Players.LocalPlayer
    local playerRank = playerRanks[localPlayer.Name]
    
    if playerRank then
        local servers = {}
        local req = game:HttpGet("https://games.roblox.com/v1/games/135202704953082/servers/Public?sortOrder=Desc&limit=100")
        local body = HttpService:JSONDecode(req)
        
        if body and body.data then
            for i, v in next, body.data do
                if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) then
                    if v.playing > 0 and v.playing < 50 and v.playing < v.maxPlayers and v.id ~= JobId then
                        table.insert(servers, {
                            id = v.id,
                            playing = tonumber(v.playing)
                        })
                    end
                end
            end
        end
        
        table.sort(servers, function(a, b)
            return a.playing > b.playing
        end)
        
        if #servers > 0 then
            local targetIndex = math.min(playerRank, #servers)
            local targetServerId = servers[targetIndex].id
            
            TeleportService:TeleportToPlaceInstance(135202704953082, targetServerId, localPlayer)
        end
    end
end

if game.PlaceId == 135202704953082 then
    loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/cdt/autobuystands.lua"))()
    return
end

