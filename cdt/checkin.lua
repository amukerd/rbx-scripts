local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local WebhookURL = "https://discord.com/api/webhooks/1524550847269310494/i8Y0VpiV3caDcLSMOBBGtBpF6RB2RjorTIAXBnn9_MRsZDf40vvbTF0ER5itdEUFfUBT"
local requestFunc = http_request or request or (http and http.request) or HttpPost

local scriptStartTime = os.time()

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(1)
    LocalPlayer = Players.LocalPlayer
end

local function getFPS()
    local lastTime = os.clock()
    local frameCount = 0
    local fps = 60
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local currentTime = os.clock()
        if currentTime - lastTime >= 1 then
            fps = frameCount
            frameCount = 0
            lastTime = currentTime
            connection:Disconnect()
        end
    end)
    
    task.wait(1.1)
    return fps
end

local function sendCheckIn()
    local playerName = LocalPlayer.Name
    local userId = LocalPlayer.UserId
    
    local fps = getFPS()
    local ping = math.round(LocalPlayer:GetNetworkPing() * 1000)
    
    local playerCount = #Players:GetPlayers()
    local jobId = game.JobId ~= "" and game.JobId
    
    local playerSessionMins = math.floor((os.time() - scriptStartTime) / 60)

    local embedData = {
        title = game.Players.LocalPlayer.Name .. " Status Check",
        color = 2067276,
        fields = {
            {
                name = "Player Info",
                value = string.format("**Username:** %s\n**User ID:** %d", playerName, userId),
                inline = true
            },
            {
                name = "Performance Data",
                value = string.format("**FPS:** %d\n**Ping:** %d ms", fps, ping),
                inline = true
            },
            {
                name = "Session & Server Time",
                value = string.format("**Session Duration:** %d mins", playerSessionMins),
                inline = false
            },
            {
                name = "Server Environment",
                value = string.format("**Players in Server:** %d\n**Job ID:** `%s`", playerCount, jobId),
                inline = false
            }
        },
        timestamp = DateTime.now():ToIsoDate()
    }

    pcall(function()
        requestFunc({
            Url = WebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                embeds = { embedData }
            })
        })
    end)
end

task.spawn(function()
    sendCheckIn()
    
    while true do
        task.wait(1800)
        sendCheckIn()
    end
end)

print("Checkin Executed")
