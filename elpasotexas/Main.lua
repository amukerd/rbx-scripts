loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/General/adonis.lua"))()
loadstring(game:HttpGet("https://amukerd.github.io/rbx-scripts/General/antiafk.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lplr = Players.LocalPlayer
local placeId = game.PlaceId
local TeleportService = game:GetService("TeleportService")
local char = lplr.Character or lplr.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local lastCF, stop, heartbeatConnection, cfConnection
local enabled = false

local buytp = Vector3.new(-1837, -6, 0)
local selltp = CFrame.new(3147, -6, -184)
local washtp = CFrame.new(-1834, -6, -15)
local continertp = CFrame.new(3488, -6, -631)

-- anti moderator --
task.spawn(function()
	if game.CreatorType ~= Enum.CreatorType.Group then
		return
	end

	local groupId = game.CreatorId

	local function checkPlayer(player)
		if player == lplr then
			return
		end

		local rank = player:GetRankInGroup(groupId)

		if rank >= 2 then
			local role = player:GetRoleInGroup(groupId)

			lplr:Kick(
				"Staff Detected\n" ..
				"User: " .. player.Name .. "\n" ..
				"UserId: " .. player.UserId .. "\n" ..
				"Rank: " .. rank .. "\n" ..
				"Role: " .. role
			)
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		checkPlayer(player)
	end

	Players.PlayerAdded:Connect(checkPlayer)
end)

-- anti-anti-teleport --
local function cleanup()
    if heartbeatConnection then heartbeatConnection:Disconnect() heartbeatConnection = nil end
    if cfConnection then cfConnection:Disconnect() cfConnection = nil end
end

local function start()
    if not lplr.Character or not lplr.Character:FindFirstChildOfClass('Humanoid') or not lplr.Character:FindFirstChildOfClass('Humanoid').RootPart then return end
    cleanup()
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if stop or not enabled then return end
        lastCF = lplr.Character:FindFirstChildOfClass('Humanoid').RootPart.CFrame
    end)
    cfConnection = lplr.Character:FindFirstChildOfClass('Humanoid').RootPart:GetPropertyChangedSignal('CFrame'):Connect(function()
        if not enabled then return end
        stop = true
        lplr.Character:FindFirstChildOfClass('Humanoid').RootPart.CFrame = lastCF
        runService.Heartbeat:Wait()
        stop = false
    end)
    lplr.Character:FindFirstChildOfClass('Humanoid').Died:Connect(function()
        cleanup()
    end)
end

local function enableAntiTeleport()
    enabled = true
end

local function disableAntiTeleport()
    enabled = false
    stop = false
end

lplr.CharacterAdded:Connect(function(character)
    repeat RunService.Heartbeat:Wait() until character:FindFirstChildOfClass('Humanoid')
    repeat RunService.Heartbeat:Wait() until character:FindFirstChildOfClass('Humanoid').RootPart
    start()
end)

lplr.CharacterRemoving:Connect(function()
    cleanup()
end)

enableAntiTeleport()
start()

local function teleportTo(position)
    disableAntiTeleport()
    RunService.Heartbeat:Wait()
    lplr.Character:FindFirstChildOfClass('Humanoid').RootPart.CFrame = CFrame.new(position)
    RunService.Heartbeat:Wait()
    enableAntiTeleport()
end

-- main script start --
local function countInBackpack(itemName)
    local count = 0

    for _, item in ipairs(lplr.Backpack:GetChildren()) do
        if item.Name == itemName then
            count += 1
        end
    end

    if lplr.Character then
        for _, item in ipairs(lplr.Character:GetChildren()) do
            if item:IsA("Tool") and item.Name == itemName then
                count += 1
            end
        end
    end

    return count
end

local function getMoney()
	local text = game.Players.LocalPlayer.leaderstats.Cash.Value
	return tonumber(text) or 0
end

local watch = workspace.Smuggling.Items["Fake Watch"].Main.PromptAtt.SmugglePurchasePrompt
local bag = workspace.Smuggling.Items["Fake Designer Bag"].Main.PromptAtt.SmugglePurchasePrompt
local sar = workspace.Smuggling.Items.Sarsaparilla.Main.PromptAtt.SmugglePurchasePrompt
local taco = workspace.Smuggling.Items.Taco.Main.PromptAtt.SmugglePurchasePrompt

watch.HoldDuration = 0
bag.HoldDuration = 0
sar.HoldDuration = 0

while true do
	char.HumanoidRootPart.Anchored = true
	
	if getMoney() >= 5000 then
	    teleportTo(buytp)
		
	    repeat
			watch.RequiresLineOfSight = false
	        fireproximityprompt(watch)
	        RunService.Heartbeat:Wait()
	    until countInBackpack("Fake Watch") >= 3
	    
	    repeat
			bag.RequiresLineOfSight = false
	        fireproximityprompt(bag)
	        RunService.Heartbeat:Wait()
	    until countInBackpack("Fake Designer Bag") >= 3
	    
	    repeat
			sar.RequiresLineOfSight = false
	        fireproximityprompt(sar)
	        RunService.Heartbeat:Wait()
	    until countInBackpack("Sarsaparilla") >= 4

	    teleportTo(selltp)
				
	    repeat
			local sell = workspace:WaitForChild("Smuggling"):WaitForChild("Sell"):WaitForChild("Prompt"):WaitForChild("SmuggleSellPrompt")
			sell.RequiresLineOfSight = false
			sell.HoldDuration = 0
	        fireproximityprompt(sell)
	        RunService.Heartbeat:Wait()
	    until countInBackpack("Briefcase") >= 1

	    teleportTo(washtp)
		
		repeat
	        local laundering = workspace:WaitForChild("Smuggling"):WaitForChild("Laundering")
			local fourthChild
			repeat
				task.wait()
				fourthChild = laundering:GetChildren()[4]
			until fourthChild
			local wash = fourthChild:WaitForChild("SmuggleLaundryPrompt")
	        wash.HoldDuration = 0

			wash.RequiresLineOfSight = false
			
	        fireproximityprompt(wash)
	        RunService.Heartbeat:Wait()
	    until countInBackpack("Briefcase") <= 0

		if getMoney() >= 90000 then
			local startTime = nil
			teleportTo(containertp)
			
			repeat
				local prompt = workspace:WaitForChild("GContaienrs"):WaitForChild("Prueba"):WaitForChild("Attachment1"):WaitForChild("Open")

				prompt.RequiresLineOfSight = false
				
				fireproximityprompt(prompt)
	     	    RunService.Heartbeat:Wait()

				if getMoney() <= 90000 and not startTime then
					startTime = tick()
				end
			until getMoney() <= 90000 and (tick() - startTime) >= 4
		end
	end
	
	if getMoney() <= 5000 then
		local amount = math.min(8, math.floor(getMoney() / 35))

	    teleportTo(buytp)
			
		repeat
			taco.RequiresLineOfSight = false
	        fireproximityprompt(taco)
	        RunService.Heartbeat:Wait()
	    until countInBackpack("Taco") >= amount

		teleportTo(seltp)
		
	    repeat
	        local sell = workspace:WaitForChild("Smuggling"):WaitForChild("Sell"):WaitForChild("Prompt"):WaitForChild("SmuggleSellPrompt")
	        sell.HoldDuration = 0

			sell.RequiresLineOfSight = false
			
	        fireproximityprompt(sell)
	        RunService.Heartbeat:Wait()
	    until countInBackpack("Briefcase") >= 1

		teleportTo(washtp)

	    repeat
	        local laundering = workspace:WaitForChild("Smuggling"):WaitForChild("Laundering")
			local fourthChild
			repeat
				task.wait()
				fourthChild = laundering:GetChildren()[4]
			until fourthChild
			local wash = fourthChild:WaitForChild("SmuggleLaundryPrompt")
	        wash.HoldDuration = 0

			wash.RequiresLineOfSight = false
			
	        fireproximityprompt(wash)
	        RunService.Heartbeat:Wait()
	    until countInBackpack("Briefcase") <= 0
	end
end
