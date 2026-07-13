--// SimpleUI

local UIS = game:GetService("UserInputService")

local Library = {}

function Library:CreateWindow(title)
    
    local existing = game.CoreGui:FindFirstChild("UI")
    if existing then
        existing:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game.CoreGui

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0,300,0,350)
    Main.Position = UDim2.new(0.5,-150,0.5,-175)
    Main.BackgroundColor3 = Color3.fromRGB(35,35,35)
    Main.BorderSizePixel = 0
    Main.Parent = ScreenGui

    local Top = Instance.new("TextLabel")
    Top.Size = UDim2.new(1,0,0,30)
    Top.BackgroundColor3 = Color3.fromRGB(25,25,25)
    Top.Text = title
    Top.TextColor3 = Color3.new(1,1,1)
    Top.Font = Enum.Font.SourceSansBold
    Top.TextSize = 20
    Top.Parent = Main

    local Holder = Instance.new("Frame")
    Holder.BackgroundTransparency = 1
    Holder.Position = UDim2.new(0,5,0,35)
    Holder.Size = UDim2.new(1,-10,1,-40)
    Holder.Parent = Main

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0,5)
    Layout.Parent = Holder

    -- Dragging
    local dragging = false
    local dragStart
    local startPos

    Top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    local Window = {}

    function Window:Label(text)

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1,0,0,25)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.new(1,1,1)
        Label.Font = Enum.Font.SourceSans
        Label.TextSize = 18
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Text = text
        Label.Parent = Holder

        return Label
    end

    function Window:Section(text)

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1,0,0,20)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.fromRGB(0,170,255)
        Label.Font = Enum.Font.SourceSansBold
        Label.TextSize = 20
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Text = text
        Label.Parent = Holder

    end

    function Window:Button(text, callback)

        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1,0,0,30)
        Button.BackgroundColor3 = Color3.fromRGB(50,50,50)
        Button.TextColor3 = Color3.new(1,1,1)
        Button.Text = text
        Button.Font = Enum.Font.SourceSansBold
        Button.TextSize = 18
        Button.Parent = Holder

        Button.MouseButton1Click:Connect(function()
            if callback then
                callback()
            end
        end)

        return Button
    end

    function Window:Toggle(text, default, callback)

        local enabled = default

        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1,0,0,30)
        Button.BackgroundColor3 = Color3.fromRGB(50,50,50)
        Button.TextColor3 = Color3.new(1,1,1)
        Button.Font = Enum.Font.SourceSansBold
        Button.TextSize = 18

        local function Update()
            Button.Text = text.." : "..(enabled and "ON" or "OFF")
        end

        Update()

        Button.MouseButton1Click:Connect(function()
            enabled = not enabled
            Update()

            if callback then
                callback(enabled)
            end
        end)

        Button.Parent = Holder

        return Button
    end

    return Window
end

return Library
