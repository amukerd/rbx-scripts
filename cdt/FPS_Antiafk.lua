local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BoothClaim = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Services"):WaitForChild("TradingHubServiceRemotes"):WaitForChild("BoothClaim")
local boothsFolder = Workspace.Map.PlayerBooths
local firstUnclaimed = nil

for _, booth in ipairs(boothsFolder:GetChildren()) do
    if booth:GetAttribute("OwnerId") == nil then
        firstUnclaimed = booth
        break
    end
end

if firstUnclaimed then
    local boothId = tonumber(string.match(firstUnclaimed.Name, "PlayerBooth(%d+)"))
    print("Claiming booth:", firstUnclaimed.Name, "ID:", boothId)
    BoothClaim:FireServer(boothId)
end

task.wait(1)

game:GetService("SoundService"):ClearAllChildren()
game.Lighting:ClearAllChildren()
game.Lighting.GlobalShadows = false

game:GetService("RunService"):Set3dRenderingEnabled(false)
setfpscap(15)

task.spawn(function()
    while true do
        for _, object in ipairs(workspace:GetChildren()) do
            if not object:IsA("Camera") 
               and not object:IsA("Terrain") 
               and object.Name ~= "Map" then
                pcall(function()
                    object:Destroy()
                end)
            end
        end
        if workspace:FindFirstChild("Map") then
            for _, mapObject in ipairs(workspace.Map:GetChildren()) do
                if mapObject.Name ~= "Structure" then
                    pcall(function()
                        mapObject:Destroy()
                    end)
                end
            end
            if workspace.Map:FindFirstChild("Structure") then
                for _, subObject in ipairs(workspace.Map.Structure:GetChildren()) do
                    if subObject.Name ~= "CylPart" then
                        pcall(function()
                            subObject:Destroy()
                        end)
                    end
                end
            end
        end
        task.wait(5)
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

print("FPS_Antiafk Executed")
