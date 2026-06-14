local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

if getgenv().SeedFarmEnabled == nil then
    getgenv().SeedFarmEnabled = true
end

local seedPackFolder = workspace.Map:WaitForChild("SeedPackSpawnServerLocations")

while true do
    if not getgenv().SeedFarmEnabled then
        task.wait(0.5)
        continue
    end

    while #seedPackFolder:GetChildren() == 0 do
        task.wait(0.1)
    end

    for _, child in ipairs(seedPackFolder:GetChildren()) do
        if not getgenv().SeedFarmEnabled then break end

        local prompt = child:FindFirstChild("ProximityPrompt")
        if prompt and prompt:IsA("ProximityPrompt") then
            repeat
                hrp.CFrame = child.CFrame
                fireproximityprompt(prompt, 1, true)
                task.wait(0.1)
            until not prompt.Parent
        end

        task.wait(0.1)
    end

    task.wait(0.1)
end
