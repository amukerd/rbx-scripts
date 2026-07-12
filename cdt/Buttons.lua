local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BoothButtonGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100

local button = Instance.new("TextButton")
button.Name = "BoothButton"
button.Size = UDim2.new(0, 54, 0, 54)
button.Position = UDim2.new(0, 2, 0.5, 2)
button.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
button.BackgroundTransparency = 0
button.Text = "BUI"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextSize = 16
button.Font = Enum.Font.GothamBold
button.AutoButtonColor = true
button.BorderSizePixel = 0
button.ZIndex = 10

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.3, 0)
corner.Parent = button

button.Parent = screenGui
screenGui.Parent = playerGui

local TradingHubController = require(ReplicatedStorage.Controllers.TradingHubController)
button.Activated:Connect(function()
    TradingHubController:OpenOfferSell()
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BoothButtonGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100

local button = Instance.new("TextButton")
button.Name = "BoothButton"
button.Size = UDim2.new(0, 54, 0, 54)
button.Position = UDim2.new(0, 2, 0.5, 2)
button.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
button.BackgroundTransparency = 0
button.Text = "BUI"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextSize = 16
button.Font = Enum.Font.GothamBold
button.AutoButtonColor = true
button.BorderSizePixel = 0
button.ZIndex = 10

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.3, 0)
corner.Parent = button

button.Parent = screenGui

local TradingHubController = require(ReplicatedStorage.Controllers.TradingHubController)
button.Activated:Connect(function()
    TradingHubController:OpenOfferSell()
end)

local unclaim = Instance.new("TextButton")
unclaim.Name = "UnclaimButton"
unclaim.Size = UDim2.new(0, 54, 0, 54)
unclaim.Position = UDim2.new(0, 2, 0.5, 60)
unclaim.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
unclaim.BackgroundTransparency = 0
unclaim.Text = "UNC"
unclaim.TextColor3 = Color3.fromRGB(255, 255, 255)
unclaim.TextSize = 16
unclaim.Font = Enum.Font.GothamBold
unclaim.AutoButtonColor = true
unclaim.BorderSizePixel = 0
unclaim.ZIndex = 10

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0.3, 0)
corner2.Parent = unclaim

unclaim.Parent = screenGui

local remotes = require(ReplicatedStorage.Remotes.Services.TradingHubServiceRemotes)
unclaim.Activated:Connect(function()
    remotes.BoothUnclaim:FireServer()
end)

screenGui.Parent = playerGui
