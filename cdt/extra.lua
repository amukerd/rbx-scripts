local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

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

task.spawn(function()
    while task.wait(5) do
        if #Players:GetPlayers() < 10 then
            TeleportService:Teleport(1554960397, LocalPlayer)
            return
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

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FullScreenResetGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 100000
ScreenGui.Parent = PlayerGui

local Button = Instance.new("TextButton")
Button.Name = "ResetButton"
Button.Size = UDim2.new(1, 0, 1, 0)
Button.Position = UDim2.new(0, 0, 0, 0)
Button.Text = "reset"
Button.TextSize = 32
Button.Font = Enum.Font.SourceSansBold
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Button.Parent = ScreenGui

Button.MouseButton1Click:Connect(function()
    Button.Text = "Teleporting..."
    Button.Active = false
    TeleportService:Teleport(1554960397, LocalPlayer)
end)
