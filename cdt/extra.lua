local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local rootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart", 5)

rootPart.Anchored = true

if rootPart then
    local platform = Instance.new("Part")
    platform.Name = "Platform"
    platform.Size = Vector3.new(2, 0.5, 2)
    platform.Anchored = true
    platform.Position = rootPart.Position - Vector3.new(0, 3, 0)
    platform.Parent = Workspace
end

local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

game:GetService("RunService"):Set3dRenderingEnabled(true)
setfpscap(15)

task.spawn(function()
    while true do
        for _, object in ipairs(Workspace:GetChildren()) do
            if not object:IsA("Camera") and 
               not object:IsA("Terrain") and 
               object.Name ~= "Platform" then
                
                pcall(function()
                    object:Destroy()
                end)
                
                task.wait(0.1)
            end
        end

        task.wait(1)
    end
end)

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
