local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local dataStore = DataStoreService:GetDataStore("Core:AlreadyPlayed")

Players.PlayerAdded:Connect(function(player: Player)
	local success, result = pcall(function()
		return dataStore:GetAsync(player.UserId)
	end)
	if success then
		if result then
			player:SetAttribute("FirstTime", false)
		else
			player:SetAttribute("FirstTime", true)
			dataStore:SetAsync(player.UserId, true)
		end
	else
		warn("Failed to load first time data for " .. player.Name .. ": " .. result)
	end
end)
