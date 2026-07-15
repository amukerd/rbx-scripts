local ImGui = loadstring(game:HttpGet('https://github.com/depthso/Roblox-ImGUI/raw/main/ImGui.lua'))()

local Window = ImGui:CreateWindow({
    Title = "Dingus",
    Size = UDim2.fromOffset(182, 150), 
    Position = UDim2.new(0, 0, 0, 200),
    BackgroundTransparency = 0, 
})

local Tab = Window:CreateTab({
    Name = "Actions",
    Visible = true,
})

Tab:Button({
    Text = "Kill NPCs",
    Callback = function(self)
        for _, c in ipairs(workspace:GetChildren()) do
            if c.Name == "PlayerCharacter" then
                c:Destroy()
            end
        end
    end,
    BackgroundTransparency = 0,
})

Tab:Button({
    Text = "Kill Players",
    Callback = function(self)
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            local args = {p.Character}
            game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("TypedRemotes"):WaitForChild("22"):InvokeServer(unpack(args))
        end
    end,
    BackgroundTransparency = 0,
})

Tab:Button({
    Text = "ESP (Kinda Sucks)",
    Callback = function(self)
        local localPlayerName = game.Players.LocalPlayer.Name
    
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            local playerName = player.Name
            if playerName ~= localPlayerName then
                for _, item in pairs(workspace:GetDescendants()) do
                    if item:IsA("Model") and item.Name == playerName then
                        local ghost = item:FindFirstChild("Ghost")
                        local rig = item:FindFirstChild("Rig")
                        local revolver = rig and rig:FindFirstChild("Revolver")
    
                        if not ghost and not revolver then
                            local highlight = Instance.new("Highlight")
                            highlight.Name = "PlayerHighlight"
                            highlight.Adornee = item
                            highlight.FillColor = Color3.fromRGB(255, 0, 0)
                            highlight.FillTransparency = 0.5
                            highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                            highlight.OutlineTransparency = 0
                            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            highlight.Parent = item
                        end
                    end
                end
            end
        end
    end,
    BackgroundTransparency = 0,
})

Tab:Button({
    Text = "Do Tasks (Also Sucks)",
    Callback = function(self)
        for _, d in pairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local a = d.Parent
                if a and a:IsA("Attachment") then
                    local b = a.Parent
                    if b and b:IsA("BasePart") then
                        local l = b:FindFirstChild("LightContainer")
                        if l then
                            local p = l:FindFirstChildOfClass("PointLight")
                            if p then
                                local rb = math.round(p.Brightness * 10^2) / 10^2
                                if rb == 0.28 and p.Color ~= Color3.fromRGB(137, 255, 111) then
                                    local targetPosition = b.Position + Vector3.new(0, 2.5, 0)
                                    game.Players.LocalPlayer.Character:PivotTo(CFrame.new(targetPosition))
                                    wait(0.5)
                                    local pp = d
                                    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                    wait(pp.HoldDuration or 2)
                                    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                    wait(1)
                                end
                            end
                        end
                    end
                end
            end
        end
    end,
    BackgroundTransparency = 0,
})
