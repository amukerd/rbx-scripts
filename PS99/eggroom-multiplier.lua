local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local generatedBackrooms = workspace.__THINGS.__INSTANCE_CONTAINER.Active.Backrooms.GeneratedBackrooms

for _, room in ipairs(generatedBackrooms:GetChildren()) do
    if room.Name == "FreeEggRoom" then
        local textLabel = room:FindFirstChild("Sign")
            and room.Sign:FindFirstChild("SurfaceGui")
            and room.Sign.SurfaceGui:FindFirstChild("TextLabel")

        if textLabel then
            print(room.Name .. ": " .. textLabel.Text)
        else
            print(room.Name .. ": No TextLabel found, teleporting in 3 seconds...")
            task.spawn(function()
                task.wait(3)
                hrp.CFrame = room.CFrame
            end)
        end
    end
end
