local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lplr = Players.LocalPlayer
local placeId = game.PlaceId
local TeleportService = game:GetService("TeleportService")
local char = lplr.Character or lplr.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

task.spawn(function()
		task.wait(60)
		local servers = {}
	
		local req = game:HttpGet(
			"https://games.roblox.com/v1/games/"
			.. game.PlaceId ..
			"/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
		)
	
		local body = game:GetService("HttpService"):JSONDecode(req)
	
		if body and body.data then
			for _, v in next, body.data do
				if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
					table.insert(servers, v.id)
				end
			end
		end
	
		if #servers > 0 then
			local server = servers[math.random(1, #servers)]
	
			TeleportService:TeleportToPlaceInstance(
				game.PlaceId,
				server,
				lplr
			)
		end
	end)

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
	local label = lplr.PlayerGui:WaitForChild("HUD"):WaitForChild("Money"):WaitForChild("MoneyLabel")

	while label.Text == "Loading..." do
		task.wait()
	end

	local text = label.Text
	text = text:gsub("%$", ""):gsub(",", "")

	return tonumber(text) or 0
end

local watch = workspace.Smuggling.Items["Fake Watch"].Main.PromptAtt.SmugglePurchasePrompt
local bag = workspace.Smuggling.Items["Fake Designer Bag"].Main.PromptAtt.SmugglePurchasePrompt
local sar = workspace.Smuggling.Items.Sarsaparilla.Main.PromptAtt.SmugglePurchasePrompt
local taco = workspace.Smuggling.Items.Taco.Main.PromptAtt.SmugglePurchasePrompt

watch.HoldDuration = 0
bag.HoldDuration = 0
sar.HoldDuration = 0
local loopCount = 0

while true do
	if getMoney() >= 5000 then
		root.CFrame = CFrame.new(-1837, -6, 0)
	    
	    repeat
	        fireproximityprompt(watch)
	        RunService.Heartbeat:Wait()
	
	        local target = Vector3.new(-1837, -6, 0)
	        root.CFrame = CFrame.new(target)
	    until countInBackpack("Fake Watch") >= 3
	    
	    repeat
	        fireproximityprompt(bag)
	        RunService.Heartbeat:Wait()
	
	        local target = Vector3.new(-1837, -6, 0)
	        root.CFrame = CFrame.new(target)
	    until countInBackpack("Fake Designer Bag") >= 3
	    
	    repeat
	        fireproximityprompt(sar)
	        RunService.Heartbeat:Wait()
	
	        local target = Vector3.new(-1837, -6, 0)
	        root.CFrame = CFrame.new(target)
	    until countInBackpack("Sarsaparilla") >= 4
				
	    repeat
	        root.CFrame = CFrame.new(3147, -6, -184)
			local sell = workspace:WaitForChild("Smuggling"):WaitForChild("Sell"):WaitForChild("Prompt"):WaitForChild("SmuggleSellPrompt")
			sell.HoldDuration = 0
	        fireproximityprompt(sell)
	        RunService.Heartbeat:Wait()
	    until countInBackpack("Briefcase") >= 1
	
	    repeat
	        root.CFrame = CFrame.new(-1834, -6, -15)
	        local laundering = workspace:WaitForChild("Smuggling"):WaitForChild("Laundering")
			local fourthChild
			repeat
				task.wait()
				fourthChild = laundering:GetChildren()[4]
			until fourthChild
			local wash = fourthChild:WaitForChild("SmuggleLaundryPrompt")
	        wash.HoldDuration = 0
	        fireproximityprompt(wash)
	        RunService.Heartbeat:Wait()
	    until countInBackpack("Briefcase") <= 0

		loopCount += 1

		--[[
		if getMoney() >= 90000 then
			local startTime = nil
			
			repeat
				root.CFrame = CFrame.new(3488, -6, -631)
				local prompt = workspace:WaitForChild("GContaienrs"):WaitForChild("Prueba"):WaitForChild("Attachment1"):WaitForChild("Open")
				fireproximityprompt(prompt)
	     	    RunService.Heartbeat:Wait()

				if getMoney() <= 90000 and not startTime then
					startTime = tick()
				end
			until getMoney() <= 90000 and (tick() - startTime) >= 4
		end
		]]--
	
		if loopCount >= 3 then
			local servers = {}
		
			local req = game:HttpGet(
				"https://games.roblox.com/v1/games/"
				.. game.PlaceId ..
				"/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
			)
		
			local body = game:GetService("HttpService"):JSONDecode(req)
		
			if body and body.data then
				for _, v in next, body.data do
					if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
						table.insert(servers, v.id)
					end
				end
			end
		
			if #servers > 0 then
				local server = servers[math.random(1, #servers)]
		
				TeleportService:TeleportToPlaceInstance(
					game.PlaceId,
					server,
					lplr
				)
			end
		
			break
		end
	end
	if getMoney() <= 5000 then
		local amount = math.min(8, math.floor(getMoney() / 35))
			
		repeat
	        fireproximityprompt(taco)
	        RunService.Heartbeat:Wait()
	
	        local target = Vector3.new(-1837, -6, 0)
	        root.CFrame = CFrame.new(target)
	    until countInBackpack("Taco") >= amount
	    
	    repeat
	        root.CFrame = CFrame.new(3147, -6, -184)
	        local sell = workspace:WaitForChild("Smuggling"):WaitForChild("Sell"):WaitForChild("Prompt"):WaitForChild("SmuggleSellPrompt")
	        sell.HoldDuration = 0
	        fireproximityprompt(sell)
	        RunService.Heartbeat:Wait()
	    until countInBackpack("Briefcase") >= 1
	
	    repeat
	        root.CFrame = CFrame.new(-1834, -6, -15)
	        local laundering = workspace:WaitForChild("Smuggling"):WaitForChild("Laundering")
			local fourthChild
			repeat
				task.wait()
				fourthChild = laundering:GetChildren()[4]
			until fourthChild
			local wash = fourthChild:WaitForChild("SmuggleLaundryPrompt")
	        wash.HoldDuration = 0
	        fireproximityprompt(wash)
	        RunService.Heartbeat:Wait()
	    until countInBackpack("Briefcase") <= 0
	end
end
