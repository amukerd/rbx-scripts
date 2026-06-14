local breakables = workspace.__THINGS.Breakables

local targetPositions = {
    Vector3.new(-1854.77942, 1612.48584, -1227.54736),
    Vector3.new(-1854.77942, 1612.48584, -1351.54736),
    Vector3.new(-1975.77942, 1612.48584, -1351.54736),
    Vector3.new(-1975.77942, 1612.48584, -1227.54736),
}

local threshold = 5

for _, model in ipairs(breakables:GetChildren()) do
    -- check the 4 cframe based hitboxes
    local hitbox = model:FindFirstChild("1") and model["1"]:FindFirstChild("Hitbox")
    if hitbox then
        for _, targetPos in ipairs(targetPositions) do
            if (hitbox.Position - targetPos).Magnitude <= threshold then
                print("Found CFrame hitbox in model: " .. model.Name .. " at " .. tostring(hitbox.Position))
            end
        end
    end

    -- check pet hitbox by attribute
    if model:GetAttribute("BreakableID") == "Daydream Mimic Boss" then
        print("Found Pet hitbox in model: " .. model.Name)
        print("WorldPivot: " .. tostring(model:GetPivot().Position))
    end
end
