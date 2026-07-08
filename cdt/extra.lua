local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

local BlockedUsers={[4512510904]=true,[8083594000]=true,[8083636321]=true,[8083664487]=true,[8083667110]=true,}

task.spawn(function()
    while task.wait(5) do
        if #Players:GetPlayers() < 10 then
            TeleportService:Teleport(1554960397, LocalPlayer)
            return
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and BlockedUsers[player.UserId] then
                TeleportService:Teleport(1554960397, LocalPlayer)
                return
            end
        end
    end
end)

setfpscap(20)

if getconnections then
    for _, connection in ipairs(getconnections(LocalPlayer.Idled)) do
        if connection.Disable then
            connection:Disable()
        elseif connection.Disconnect then
            connection:Disconnect()
        end
    end
else
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
