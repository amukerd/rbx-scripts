task.wait(10)

print("[AutoRace] Script started")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RacesGui = LocalPlayer.PlayerGui:WaitForChild("Races")
local RaceData = ReplicatedStorage:WaitForChild("Data"):WaitForChild("Races")

_G.AutoRace = true
print("[AutoRace] Enabled")

local function TeleportToRace(raceName)
    print("[Teleport] Requested:", raceName)

    local raceFolder = RaceData:FindFirstChild(raceName)
    if not raceFolder then
        print("[Teleport] Race folder not found")
        return
    end

    local flagPos = raceFolder:FindFirstChild("FlagPosition")
    if not flagPos then
        print("[Teleport] FlagPosition not found")
        return
    end

    local playerCar

    repeat
        print("[Teleport] Looking for player car...")

        for _, car in ipairs(workspace.Cars:GetChildren()) do
            local stats = car:FindFirstChild("Stats")
            local owner = stats and stats:FindFirstChild("Owner")

            if owner and owner.Value == LocalPlayer.Name and car.PrimaryPart then
                playerCar = car
                print("[Teleport] Found car:", car.Name)
                break
            end
        end

        if not playerCar then
            task.wait(0.2)
        end
    until playerCar or not _G.AutoRace

    if playerCar then
        print("[Teleport] Teleporting")
        playerCar:SetPrimaryPartCFrame(CFrame.new(flagPos.Value))
        task.wait(1)
    end
end

local function FindRaceGuiFromVariant(variantName)
    print("[FindRaceGui] Searching:", variantName)

    for _, raceGui in ipairs(RacesGui:GetChildren()) do
        if raceGui:IsA("BillboardGui") then
            local lobby = raceGui:FindFirstChild("Frame") and raceGui.Frame:FindFirstChild("Lobby")

            if lobby and lobby:FindFirstChild("VoteLaps" .. variantName) then
                print("[FindRaceGui] Found:", raceGui.Name)
                return raceGui, "VoteLaps" .. variantName
            end
        end
    end

    if RacesGui:FindFirstChild(variantName) then
        print("[FindRaceGui] Found direct:", variantName)
        return RacesGui[variantName], "Vote"
    end

    print("[FindRaceGui] Not found")
end

local function WaitForValue(value, expected)
    print("[WaitForValue]", value.Name, value.Value, "->", expected)

    repeat
        task.wait(0.1)
    until value.Value == expected or not _G.AutoRace

    print("[WaitForValue] Done:", value.Name, value.Value)
end

local function WaitForVisible(gui)
    print("[WaitForVisible]", gui.Name)

    repeat
        task.wait(0.1)
    until gui.Visible or not _G.AutoRace

    print("[WaitForVisible] Visible:", gui.Name)
end

local function IsRaceActive()
    return LocalPlayer.PlayerGui.Menu.RaceValues.Racing.Value ~= ""
end

local function AutoCompleteRace()
    print("[AutoComplete] Waiting for race")

    local RaceValues = LocalPlayer.PlayerGui.Menu.RaceValues

    repeat
        task.wait(0.1)
    until RaceValues.Racing.Value ~= "" or not _G.AutoRace

    if not _G.AutoRace then return end

    local raceName = RaceValues.Racing.Value
    print("[AutoComplete] Race:", raceName)

    local activeRace

    for _, race in ipairs(workspace.Races:GetChildren()) do
        if race.Name == raceName or race:FindFirstChild(raceName) then
            activeRace = race
            break
        end
    end

    if not activeRace then
        print("[AutoComplete] Active race not found")
        return
    end

    local scriptFolder = activeRace.Script
    local checkpointRemote = scriptFolder.Checkpoint
    local finishRemote = scriptFolder.Finish

    local checkpoints = activeRace:FindFirstChild("Checkpoints")

    if not checkpoints then
        local variant = activeRace:FindFirstChild(raceName)

        if variant then
            checkpoints = variant:FindFirstChild("Checkpoints")
        end
    end

    if not checkpoints then
        print("[AutoComplete] No checkpoints")
        return
    end

    local checkpointCount = #checkpoints:GetChildren()

    print("[AutoComplete] Checkpoints:", checkpointCount)
    print("[AutoComplete] Laps:", scriptFolder.Laps.Value)

    for i = 1, checkpointCount do
        if not _G.AutoRace then return end

        print("[AutoComplete] Checkpoint", i)
        checkpointRemote:FireServer(i)
        task.wait(0.1)
    end

    for lap = 2, scriptFolder.Laps.Value do
        checkpointRemote:FireServer(0)
        task.wait(0.1)

        for i = 1, checkpointCount do
            checkpointRemote:FireServer(i)
            task.wait(0.1)
        end
    end

    print("[AutoComplete] Finish")
    finishRemote:FireServer()
end

local function StartRace(variantName)
    while _G.AutoRace do
        print("[StartRace] New loop")

        local raceGui, voteName = FindRaceGuiFromVariant(variantName)

        if not raceGui then
            print("[StartRace] No race GUI")
            task.wait(1)
            continue
        end

        local raceName = raceGui.Name
        print("[StartRace] Race:", raceName)

        if IsRaceActive() then
            print("[StartRace] Already racing")

            TeleportToRace(raceName)

            repeat
                task.wait(1)
            until not IsRaceActive() or not _G.AutoRace

            print("[StartRace] Previous race finished")
        end

        if not _G.AutoRace then break end

        TeleportToRace(raceName)

        local race = workspace.Races:FindFirstChild(raceName)

        if not race then
            print("[StartRace] Workspace race missing")
            task.wait(1)
            continue
        end

        print("[StartRace] Race found")

        local scriptFolder = race.Script
        local voteRemote = scriptFolder.Vote

        task.wait(1)

        print("[StartRace] LobbyProgress:", scriptFolder.LobbyProgress.Value)

        if not scriptFolder.LobbyProgress.Value then
            print("[StartRace] Starting lobby")
            workspace.Races.RaceHandler.StartLobby:FireServer(raceName)
        end

        WaitForValue(scriptFolder.LobbyProgress, true)

        local lobby = raceGui.Frame.Lobby

        if lobby:FindFirstChild("VoteRace") and lobby.VoteRace.Visible then
            print("[StartRace] Voting race")
            voteRemote:FireServer("5", "VoteRace")
            task.wait(0.2)
        end

        local lapsButton = lobby:WaitForChild(voteName)

        if not lapsButton.Visible then
            WaitForVisible(lapsButton)
        end

        if not _G.AutoRace then return end

        print("[StartRace] Voting laps")
        voteRemote:FireServer("5", voteName)

        print("[StartRace] Waiting for race start")
        WaitForValue(scriptFolder.RaceProgress, true)

        print("[StartRace] Race started")

        AutoCompleteRace()

        print("[StartRace] Race finished")
    end
end

print("[Intro] Choosing dealership")
local chooseButton = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Intro"):WaitForChild("ChooseDealership"):WaitForChild("ScrollingFrame"):WaitForChild("Dealership1"):WaitForChild("Choose")
firesignal(chooseButton.Activated)

task.wait(1)

print("[Intro] Waiting for load")
local loadButton = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Intro"):WaitForChild("SelectScreen"):WaitForChild("Claim")

while loadButton.Parent.Visible do
    print("[Intro] Clicking Claim")
    firesignal(loadButton.Activated)
    task.wait(1)
end

print("[Intro] Loaded")

print("[Spawn] Getting Fiat ID")
local fiatId = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Menu"):WaitForChild("Inventory"):WaitForChild("Cars"):WaitForChild("Frame"):WaitForChild("Frame"):WaitForChild("Fiat"):GetAttribute("Id")

print("[Spawn] Fiat ID:", fiatId)
print("[Spawn] Spawning Fiat")

ReplicatedStorage.Remotes.Spawn:FireServer("Fiat", fiatId, "Desktop")

print("[AutoRace] Starting")

_G.AutoRace = true
StartRace("Highway")
