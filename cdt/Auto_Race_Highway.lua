print("[AutoRace] Script started")

task.wait(10)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RacesGui = LocalPlayer.PlayerGui:WaitForChild("Races")
local RaceData = ReplicatedStorage:WaitForChild("Data"):WaitForChild("Races")

_G.AutoRace = true

local function TeleportToRace(raceName)
    local raceFolder = RaceData:FindFirstChild(raceName)
    if not raceFolder then
        return
    end

    local flagPos = raceFolder:FindFirstChild("FlagPosition")
    if not flagPos then
        return
    end

    local playerCar

    repeat
        for _, car in ipairs(workspace.Cars:GetChildren()) do
            local stats = car:FindFirstChild("Stats")
            local owner = stats and stats:FindFirstChild("Owner")

            if owner and owner.Value == LocalPlayer.Name and car.PrimaryPart then
                playerCar = car
                break
            end
        end

        if not playerCar then
            task.wait(0.2)
        end
    until playerCar or not _G.AutoRace

    if playerCar then
        playerCar:SetPrimaryPartCFrame(CFrame.new(flagPos.Value))
        task.wait(1)
    end
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

local function WaitForVisible(gui)
    repeat
        task.wait(0.1)
    until gui.Visible or not _G.AutoRace
end

local function IsRaceActive()
    return LocalPlayer.PlayerGui.Menu.RaceValues.Racing.Value ~= ""
end

local function AutoCompleteRace()
    local race = workspace.Races:WaitForChild("City")
    local scriptFolder = race:WaitForChild("Script")

    local checkpointRemote = scriptFolder:WaitForChild("Checkpoint")
    local finishRemote = scriptFolder:WaitForChild("Finish")

    local sequence = {
        0,
        0,
        0
    }

    for _, checkpoint in ipairs(sequence) do
        if not _G.AutoRace then return end
        checkpointRemote:FireServer(checkpoint)
        task.wait(1)
    end

    task.wait()
    if not _G.AutoRace then return end
    finishRemote:FireServer()
end

local function StartRace(variantName)
    while _G.AutoRace do
        local raceGui, voteName = FindRaceGuiFromVariant(variantName)

        if not raceGui then
            task.wait(1)
            continue
        end

        local raceName = raceGui.Name

        if IsRaceActive() then
            TeleportToRace(raceName)

            repeat
                task.wait(1)
            until not IsRaceActive() or not _G.AutoRace
        end

        if not _G.AutoRace then break end

        TeleportToRace(raceName)

        local race = workspace.Races:FindFirstChild(raceName)

        if not race then
            task.wait(1)
            continue
        end

        local scriptFolder = race.Script
        local voteRemote = scriptFolder.Vote

        task.wait(1)

        if not scriptFolder.LobbyProgress.Value then
            workspace.Races.RaceHandler.StartLobby:FireServer(raceName)
        end

        WaitForValue(scriptFolder.LobbyProgress, true)

        local lobby = raceGui.Frame.Lobby

        if lobby:FindFirstChild("VoteRace") and lobby.VoteRace.Visible then
            voteRemote:FireServer("5", "VoteRace")
            task.wait(0.2)
        end

        local lapsButton = lobby:WaitForChild(voteName)

        if not lapsButton.Visible then
            WaitForVisible(lapsButton)
        end

        if not _G.AutoRace then return end

        voteRemote:FireServer("5", voteName)

        WaitForValue(scriptFolder.RaceProgress, true)

        AutoCompleteRace()
    end
end

local chooseButton = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Intro"):WaitForChild("ChooseDealership"):WaitForChild("ScrollingFrame"):WaitForChild("Dealership1"):WaitForChild("Choose")
firesignal(chooseButton.Activated)

task.wait(1)

local loadButton = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Intro"):WaitForChild("SelectScreen"):WaitForChild("Claim")
while loadButton.Parent.Visible do
    firesignal(loadButton.Activated)
    task.wait(1)
end

local fiatId = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Menu"):WaitForChild("Inventory"):WaitForChild("Cars"):WaitForChild("Frame"):WaitForChild("Frame"):WaitForChild("Fiat"):GetAttribute("Id")
ReplicatedStorage.Remotes.Spawn:FireServer("Fiat", fiatId, "Desktop")

_G.AutoRace = true
StartRace("Highway")
