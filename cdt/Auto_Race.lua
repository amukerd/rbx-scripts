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
















local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RacesGui = LocalPlayer.PlayerGui:WaitForChild("Races")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RaceData = ReplicatedStorage:WaitForChild("Data"):WaitForChild("Races")

_G.AutoRace = _G.AutoRace or false

local Running = false

local function TeleportToRace(raceName)
    local raceFolder = RaceData:FindFirstChild(raceName)

    if not raceFolder then
        return
    end

    local flagPos = raceFolder:FindFirstChild("FlagPosition")

    if not flagPos or not flagPos.Value then
        return
    end

    local playerCar

    for _, v in pairs(workspace.Cars:GetChildren()) do
        if v:FindFirstChild("Stats") and v.Stats:FindFirstChild("Owner") then
            if v.Stats.Owner.Value == LocalPlayer.Name then
                playerCar = v
                break
            end
        end
    end

    print(flagPos.Value)

    if playerCar and playerCar.PrimaryPart then
        playerCar:SetPrimaryPartCFrame(CFrame.new(flagPos.Value))
    end

    task.wait(1)
end

local function FindRaceGuiFromVariant(variantName)
    for _, raceGui in ipairs(RacesGui:GetChildren()) do
        if raceGui:IsA("BillboardGui") then
            local lobby = raceGui:FindFirstChild("Frame") and raceGui.Frame:FindFirstChild("Lobby")

            if lobby and lobby:FindFirstChild("VoteLaps" .. variantName) then
                return raceGui, "VoteLaps" .. variantName
            end
        end
    end

    if RacesGui:FindFirstChild(variantName) then
        return RacesGui[variantName], "Vote"
    end
end

local function WaitForValue(value, expected)
    repeat
        task.wait(0.1)
    until value.Value == expected or not _G.AutoRace
end

local function WaitForVisible(guiObject)
    repeat
        task.wait(0.1)
    until guiObject.Visible or not _G.AutoRace
end

local function IsRaceActive()
    local RaceValues = LocalPlayer.PlayerGui.Menu.RaceValues

    return RaceValues.Racing.Value ~= ""
end

local function AutoCompleteRace()
    local RaceValues = LocalPlayer.PlayerGui.Menu.RaceValues

    local activeRaceName = RaceValues.Racing.Value

    repeat
        task.wait(0.1)
        activeRaceName = RaceValues.Racing.Value
    until activeRaceName ~= "" or not _G.AutoRace

    if not _G.AutoRace then
        return
    end

    local activeRace

    for _, race in ipairs(workspace.Races:GetChildren()) do
        if race.Name == activeRaceName then
            activeRace = race
            break
        end

        if race:FindFirstChild(activeRaceName) then
            activeRace = race
            break
        end
    end

    if not activeRace then
        return
    end

    local scriptFolder = activeRace:WaitForChild("Script")

    local checkpointRemote = scriptFolder:WaitForChild("Checkpoint")
    local finishRemote = scriptFolder:WaitForChild("Finish")

    local checkpointsFolder = activeRace:FindFirstChild("Checkpoints")

    if not checkpointsFolder then
        local variantFolder = activeRace:FindFirstChild(activeRaceName)

        if variantFolder then
            checkpointsFolder = variantFolder:FindFirstChild("Checkpoints")
        end
    end

    if not checkpointsFolder then
        return
    end

    local checkpointCount = #checkpointsFolder:GetChildren()
    local laps = scriptFolder.Laps.Value

    for checkpoint = 1, checkpointCount do
        if not _G.AutoRace then
            return
        end

        checkpointRemote:FireServer(checkpoint)

        print(checkpoint)

        task.wait(0.1)
    end

    for lap = 2, laps do
        if not _G.AutoRace then
            return
        end

        checkpointRemote:FireServer(0)

        print("0")

        task.wait(0.1)

        for checkpoint = 1, checkpointCount do
            if not _G.AutoRace then
                return
            end

            checkpointRemote:FireServer(checkpoint)

            print(checkpoint)

            task.wait(0.1)
        end
    end

    finishRemote:FireServer()

    print("finish")
end

local function StartRace(variantName)
    local raceGui, voteLapsName = FindRaceGuiFromVariant(variantName)

    if not raceGui then
        return
    end

    local raceName = raceGui.Name

    if IsRaceActive() then

        TeleportToRace(raceName)

        repeat
            task.wait(1)
        until not IsRaceActive() or not _G.AutoRace

    end

    if not _G.AutoRace then
        return
    end

    TeleportToRace(raceName)

    local race = workspace.Races:FindFirstChild(raceName)

    if not race then
        return
    end

    local scriptFolder = race:WaitForChild("Script")
    local voteRemote = scriptFolder:WaitForChild("Vote")

    local raceHandler = workspace.Races.RaceHandler

    if scriptFolder.LobbyProgress.Value == false then
        raceHandler.StartLobby:FireServer(raceName)
    end

    WaitForValue(scriptFolder:WaitForChild("LobbyProgress"), true)

    local lobby = raceGui.Frame.Lobby

    local voteRace = lobby:FindFirstChild("VoteRace")

    if voteRace and voteRace.Visible then
        voteRemote:FireServer("5", "VoteRace")

        task.wait(0.2)
    end

    local lapsButton = lobby:WaitForChild(voteLapsName)

    if not lapsButton.Visible then
        WaitForVisible(lapsButton)
    end

    if not _G.AutoRace then
        return
    end

    voteRemote:FireServer("5", voteLapsName)

    WaitForValue(scriptFolder:WaitForChild("RaceProgress"), true)

    if _G.AutoRace then
        AutoCompleteRace()
    end
end

local function Loop()
    if Running then
        return
    end

    Running = true

    while _G.AutoRace do
        StartRace("Highway")

        task.wait(2)
    end

    Running = false
end

_G.StartAutoRace = function()
    _G.AutoRace = true

    Loop()
end

_G.StopAutoRace = function()
    _G.AutoRace = false
end

_G.StartAutoRace()
