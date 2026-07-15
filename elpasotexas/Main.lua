--[[
Game : https://www.roblox.com/games/109872214376771
Coded by : Amukerd and most AI's
]]--

loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/General/adonis.lua"))()
loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/General/antiafk.lua"))()

--- global variables ---
aVars = {}
aVars.Players = game:GetService("Players")
aVars.LocalPlayer = aVars.Players.LocalPlayer
aVars.RunService = game:GetService("RunService")
aVars.TeleportService = game:GetService("TeleportService")
aVars.Workspace = game:GetService("Workspace")

--- script variables ---
aVars.PlaceId = game.PlaceId
aVars.Character = aVars.LocalPlayer.Character or aVars.LocalPlayer.CharacterAdded:Wait()
aVars.HumanoidRootPart = aVars.Character:WaitForChild("HumanoidRootPart")

aVars.LastCF = nil
aVars.Stop = false
aVars.HeartbeatConnection = nil
aVars.CfConnection = nil
aVars.Enabled = false

aVars.BuyTP = Vector3.new(-1837, -6, 0)
aVars.SellTP = Vector3.new(3147, -6, -184)
aVars.WashTP = Vector3.new(-1834, -6, -15)
aVars.ContainerTP = Vector3.new(3488, -6, -631)

local Platform = Instance.new("Part")
Platform.Size = Vector3.new(10, 1, 10)
Platform.Anchored = true
Platform.Transparency = 1
Platform.CanCollide = true
Platform.Parent = aVars.Workspace

--- anti moderator ---
task.spawn(function()
	if game.CreatorType ~= Enum.CreatorType.Group then
		return
	end

	local groupId = game.CreatorId

	local function checkPlayer(player)
		if player == aVars.LocalPlayer then
			return
		end

		local rank = player:GetRankInGroup(groupId)

		if rank >= 2 then
			local role = player:GetRoleInGroup(groupId)

			aVars.LocalPlayer:Kick(
				"Staff Detected\n" ..
				"User: " .. player.Name .. "\n" ..
				"UserId: " .. player.UserId .. "\n" ..
				"Rank: " .. rank .. "\n" ..
				"Role: " .. role
			)
		end
	end

	for _, player in ipairs(aVars.Players:GetPlayers()) do
		checkPlayer(player)
	end

	aVars.Players.PlayerAdded:Connect(checkPlayer)
end)

--- anti-anti-teleport ---
local function cleanup()
	if aVars.HeartbeatConnection then aVars.HeartbeatConnection:Disconnect() aVars.HeartbeatConnection = nil end
	if aVars.CfConnection then aVars.CfConnection:Disconnect() aVars.CfConnection = nil end
end

local function start()
	if not aVars.LocalPlayer.Character or not aVars.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') or not aVars.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').RootPart then return end
	cleanup()
	aVars.HeartbeatConnection = aVars.RunService.Heartbeat:Connect(function()
		if aVars.Stop or not aVars.Enabled then return end
		aVars.LastCF = aVars.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').RootPart.CFrame
	end)
	aVars.CfConnection = aVars.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').RootPart:GetPropertyChangedSignal('CFrame'):Connect(function()
		if not aVars.Enabled then return end
		aVars.Stop = true
		aVars.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').RootPart.CFrame = aVars.LastCF
		aVars.RunService.Heartbeat:Wait()
		aVars.Stop = false
	end)
	aVars.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').Died:Connect(function()
		cleanup()
	end)
end

local function enableAntiTeleport()
	aVars.Enabled = true
end

local function disableAntiTeleport()
	aVars.Enabled = false
	aVars.Stop = false
end

aVars.LocalPlayer.CharacterAdded:Connect(function(character)
	repeat aVars.RunService.Heartbeat:Wait() until character:FindFirstChildOfClass('Humanoid')
	repeat aVars.RunService.Heartbeat:Wait() until character:FindFirstChildOfClass('Humanoid').RootPart
	start()
end)

aVars.LocalPlayer.CharacterRemoving:Connect(function()
	cleanup()
end)

enableAntiTeleport()
start()

local function teleportTo(position)
	disableAntiTeleport()
	aVars.RunService.Heartbeat:Wait()
	Platform.Position = position - Vector3.new(0, 3.5, 0)
	aVars.RunService.Heartbeat:Wait()
	aVars.Character.HumanoidRootPart.CFrame = CFrame.new(position)
	aVars.RunService.Heartbeat:Wait()
	enableAntiTeleport()
end

--- main functions ---
local function countInBackpack(itemName)
	local count = 0

	for _, item in ipairs(aVars.LocalPlayer.Backpack:GetChildren()) do
		if item.Name == itemName then
			count += 1
		end
	end

	if aVars.LocalPlayer.Character then
		for _, item in ipairs(aVars.LocalPlayer.Character:GetChildren()) do
			if item:IsA("Tool") and item.Name == itemName then
				count += 1
			end
		end
	end

	return count
end

local function getMoney()
	local text = aVars.LocalPlayer.leaderstats.Cash.Value
	return tonumber(text) or 0
end

--- main loop ---
while true do	
	if getMoney() >= 5000 then
		teleportTo(aVars.BuyTP)
		
		repeat
			aVars.Watch = aVars.Workspace.Smuggling.Items["Fake Watch"].Main.PromptAtt.SmugglePurchasePrompt
			aVars.Watch.HoldDuration = 0
			aVars.Watch.RequiresLineOfSight = false
			fireproximityprompt(aVars.Watch)
			aVars.RunService.Heartbeat:Wait()
		until countInBackpack("Fake Watch") >= 3
		
		repeat
			aVars.Bag = aVars.Workspace.Smuggling.Items["Fake Designer Bag"].Main.PromptAtt.SmugglePurchasePrompt
			aVars.Bag.HoldDuration = 0
			aVars.Bag.RequiresLineOfSight = false
			fireproximityprompt(aVars.Bag)
			aVars.RunService.Heartbeat:Wait()
		until countInBackpack("Fake Designer Bag") >= 3
		
		repeat
			aVars.Sar = aVars.Workspace.Smuggling.Items.Sarsaparilla.Main.PromptAtt.SmugglePurchasePrompt
			aVars.Sar.HoldDuration = 0
			aVars.Sar.RequiresLineOfSight = false
			fireproximityprompt(aVars.Sar)
			aVars.RunService.Heartbeat:Wait()
		until countInBackpack("Sarsaparilla") >= 4

		teleportTo(aVars.SellTP)
				
		repeat
			aVars.Sell = aVars.Workspace:WaitForChild("Smuggling"):WaitForChild("Sell"):WaitForChild("Prompt"):WaitForChild("SmuggleSellPrompt")
			aVars.Sell.HoldDuration = 0
			aVars.Sell.RequiresLineOfSight = false
			fireproximityprompt(aVars.Sell)
			aVars.RunService.Heartbeat:Wait()
		until countInBackpack("Briefcase") >= 1

		teleportTo(aVars.WashTP)
		
		repeat
			aVars.Laundering = aVars.Workspace:WaitForChild("Smuggling"):WaitForChild("Laundering"):GetChildren()[4]:WaitForChild("SmuggleLaundryPrompt")
			aVars.Laundering.HoldDuration = 0
			aVars.Laundering.RequiresLineOfSight = false
			fireproximityprompt(aVars.Laundering)
			aVars.RunService.Heartbeat:Wait()
		until countInBackpack("Briefcase") <= 0

		if getMoney() >= 90000 then
			teleportTo(aVars.ContainerTP)
			
			repeat
				aVars.Containers = aVars.Workspace:WaitForChild("GContaienrs"):WaitForChild("Prueba"):WaitForChild("Attachment1"):WaitForChild("Open")
				aVars.Containers.HoldDuration = 0
				aVars.Containers.RequiresLineOfSight = false
				fireproximityprompt(aVars.Containers)
				aVars.RunService.Heartbeat:Wait()
			until getMoney() <= 90000
		end
	end
	
	if getMoney() <= 5000 then
		local amount = math.min(8, math.floor(getMoney() / 35))

		teleportTo(aVars.BuyTP)
			
		repeat
			aVars.Taco = aVars.Workspace.Smuggling.Items.Taco.Main.PromptAtt.SmugglePurchasePrompt
			aVars.Taco.HoldDuration = 0
			aVars.Taco.RequiresLineOfSight = false
			fireproximityprompt(aVars.Taco)
			aVars.RunService.Heartbeat:Wait()
		until countInBackpack("Taco") >= amount

		teleportTo(aVars.SellTP)
		
		repeat
			aVars.Sell = aVars.Workspace:WaitForChild("Smuggling"):WaitForChild("Sell"):WaitForChild("Prompt"):WaitForChild("SmuggleSellPrompt")
			aVars.Sell.HoldDuration = 0
			aVars.Sell.RequiresLineOfSight = false
			fireproximityprompt(aVars.Sell)
			aVars.RunService.Heartbeat:Wait()
		until countInBackpack("Briefcase") >= 1

		teleportTo(aVars.WashTP)

		repeat
			aVars.Laundering = aVars.Workspace:WaitForChild("Smuggling"):WaitForChild("Laundering"):GetChildren()[4]:WaitForChild("SmuggleLaundryPrompt")
			aVars.Laundering.HoldDuration = 0
			aVars.Laundering.RequiresLineOfSight = false
			fireproximityprompt(aVars.Laundering)
			aVars.RunService.Heartbeat:Wait()
		until countInBackpack("Briefcase") <= 0
	end
end

print("Script Initialized")
