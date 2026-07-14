local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RaceData = ReplicatedStorage:WaitForChild("Data"):WaitForChild("Races")

local function GetRaceLocations()
    local races = {}

    for _, raceFolder in ipairs(RaceData:GetChildren()) do
        local flagPos = raceFolder:FindFirstChild("FlagPosition")

        if flagPos and flagPos.Value then
            table.insert(races, {
                Name = raceFolder.Name,
                Position = flagPos.Value,
            })
        end
    end

    return races
end

local raceLocations = GetRaceLocations()

for _, race in ipairs(raceLocations) do
    print(race.Name, race.Position)
end









local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScript = require(ReplicatedStorage:WaitForChild("ModuleScript"))

local LocalPlayer = Players.LocalPlayer
local RaceData = ReplicatedStorage:WaitForChild("Data"):WaitForChild("Races")

local RACE_NAME = "YourRaceName"

local function TeleportToRace(raceName)
    local raceFolder = RaceData:FindFirstChild(raceName)

    if not raceFolder then
        warn(("Race '%s' not found."):format(raceName))
        return false
    end

    local flagPos = raceFolder:FindFirstChild("FlagPosition")

    if not flagPos or not flagPos.Value then
        warn(("Race '%s' has no FlagPosition."):format(raceName))
        return false
    end

    ModuleScript.resetGravity()
    ModuleScript.teleportPlayerToPosition(LocalPlayer, CFrame.new(flagPos.Value))

    return true
end

TeleportToRace(RACE_NAME)
