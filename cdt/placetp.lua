if game.PlaceId == 135202704953082 then
    loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/cdt/autobuystands.lua"))()
    return
end

if game.PlaceId == 1554960397 then
    game:GetService("TeleportService"):Teleport(135202704953082, game.Players.LocalPlayer)
end
