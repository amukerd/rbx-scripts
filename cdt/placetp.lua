print("Executed")

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local LOBBY_ID = 1554960397
local GAME_ID = 135202704953082

local ws = WebSocket.connect("ws://127.0.0.1:8080")

local function send(data)
    ws:Send(HttpService:JSONEncode(data))
end

send(
    {
        type = "hello",
        player = LocalPlayer.Name,
        jobId = game.JobId,
        players = #Players:GetPlayers()
    }
)

ws.OnMessage:Connect(
    function(msg)
        local data = HttpService:JSONDecode(msg)

        if data.type == "serverResponse" then
            print("Teleporting to", data.jobId)

            TeleportService:TeleportToPlaceInstance(GAME_ID, data.jobId, LocalPlayer)
        end
    end
)

if game.PlaceId == LOBBY_ID then
    task.wait(2)

    send(
        {
            type = "requestServer",
            player = LocalPlayer.Name,
            jobId = game.JobId,
            reason = "initial_join"
        }
    )
end

if game.PlaceId == GAME_ID then
    task.spawn(
        function()
            while task.wait(5) do
                if #Players:GetPlayers() < 20 then
                    send(
                        {
                            type = "requestServer",
                            player = LocalPlayer.Name,
                            jobId = game.JobId,
                            reason = "low_population"
                        }
                    )

                    break
                end
            end
        end
    )

    loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/cdt/autobuystands.lua"))()
end
