local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local rootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart", 5)

rootPart.Anchored = true

local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

game:GetService("RunService"):Set3dRenderingEnabled(false)
setfpscap(15)

--[[
local playerCharacters = {}
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        playerCharacters[player.Character] = true
    end
end

for _, object in ipairs(Workspace:GetChildren()) do
    if object ~= Workspace.CurrentCamera and object:IsA("Terrain") == false and playerCharacters[object] == nil then
        pcall(function()
            object:Destroy()
        end)
    end
end
]]--

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
