local TeleportService = game:GetService("TeleportService")
local Players = game.Players
local u = Players.LocalPlayer

local ID1 = 1554960397
local ID2 = 135202704953082

if game.PlaceId == ID2 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/amukerd/rbx-scripts/refs/heads/main/cdt/autobuystands.lua"))()
    return
end

if game.PlaceId == ID1 then
    pcall(function()
        TeleportService:Teleport(ID2, u)
    end)
end

local BlockedUsers = {
    [4512510904] = true,
    [8083594000] = true,
    [8083636321] = true,
    [8083664487] = true,
}

task.spawn(function()
    while task.wait(5) do
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= u and BlockedUsers[player.UserId] then
                TeleportService:Teleport(ID1, u)
                return
            end
        end
    end
end)
