local function formatNumberWithCommas(n)
	n = tostring(n)
	return n:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local GetRapRemote = game:GetService("ReplicatedStorage").Remotes.Services.RapRemotes.GetRap
local GetOwnedCarsRemote = game:GetService("ReplicatedStorage").Remotes.Services.CarServiceRemotes.GetOwnedCars

local ownedCars = GetOwnedCarsRemote:InvokeServer()
local totalRAP = 0

for _, car in ipairs(ownedCars) do
	local carName = car.Name
	if carName then
		local rap = GetRapRemote:InvokeServer(carName)
		if type(rap) == "number" then
			totalRAP = totalRAP + rap
		end
	end
end

local username = game:GetService("Players").LocalPlayer.Name
local formattedRAP = formatNumberWithCommas(totalRAP)

local payload = {
	embeds = {
		{
			title = username .. " Inventory Value",
			description = formattedRAP,
			color = 3447003
		}
	}
}

local requestFunc = (syn and syn.request) or (http and http.request) or (http_request) or (request)
if requestFunc then
	requestFunc({
		Url = "https://discord.com/api/webhooks/1524550847269310494/i8Y0VpiV3caDcLSMOBBGtBpF6RB2RjorTIAXBnn9_MRsZDf40vvbTF0ER5itdEUFfUBT",
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = game:GetService("HttpService"):JSONEncode(payload)
	})
end
