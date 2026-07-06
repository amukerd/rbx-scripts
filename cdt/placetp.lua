local TeleportService = game:GetService("TeleportService")
local player = game:GetService("Players").Players.LocalPlayer

local ID1 = 1554960397
local ID2 = 135202704953082

if game.PlaceId == ID2 then
    -- Already in the stands place, do nothing.
    return
end

while game.PlaceId == ID1 do
    pcall(function()
        TeleportService:Teleport(ID2, player)
    end)
    task.wait(5)
end
