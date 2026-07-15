local Players = game:GetService("Players")
local player = Players.LocalPlayer
local rerollButton = player:WaitForChild("PlayerGui"):WaitForChild("hud"):WaitForChild("traitFrame"):WaitForChild("rerollButton")
local currenTraitsUI = player.PlayerGui.hud.traitFrame.main.container:WaitForChild("currentTraits")

local wantedTraits = {
    "Awakened",
    "Ghostly",
    "Overclocked X",
    "Overclocked IX",
    "Tiny X",
    "Tiny IX",
    "Tiny VIII",
    "Titanic IX",
    "Titanic X"
}

local wantedLookup = {}
for _, trait in ipairs(wantedTraits) do
    wantedLookup[trait] = true
end

local function getCurrentTraits()
    local traits = {}

    for _, child in ipairs(currenTraitsUI:GetChildren()) do
        table.insert(traits, child.Name)
    end

    return traits
end

local function hasWantedTrait()
    local current = getCurrentTraits()

    for _, trait in ipairs(current) do
        if wantedLookup[trait] then
            return true, trait
        end
    end

    return false
end

local running = true

while running do
    local found, trait = hasWantedTrait()

    if found then
        running = false
        break
    end

    firesignal(rerollButton.Activated)
    task.wait(0.25)
end
