local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("Main"):WaitForChild("Frame"):WaitForChild("Social"):WaitForChild("Grid"):WaitForChild("NowPlaying")
local playerTemplate = ReplicatedStorage:WaitForChild("Templates"):WaitForChild("Social"):WaitForChild("Player")

local LocationType = {
	MobileWebsite = 0,
	MobileInGame = 1,
	Website = 2,
	Studio = 3,
	InGame = 4,
	XBoxApp = 5,
	TeamCreate = 6,
}

local function getOnlineFriends()
	local success, onlineFriends = pcall(function()
		return player:GetFriendsOnlineAsync(3)
	end)

	return success and onlineFriends or {}
end

local function listFriends()
	local onlineFriends = getOnlineFriends()

	for _, child in gui.PlayerList:GetChildren() do
		if child:IsA("Frame") and onlineFriends[child.Name] == nil then
			child:Destroy()
		end
	end

	for _, friend in onlineFriends do
		local frame = gui:FindFirstChild(friend.UserName) or playerTemplate:Clone()
		frame.Parent = gui:WaitForChild("PlayerList")
		frame.Visible = true
		frame.Name = friend.UserName
		frame.Icon.Image = Players:GetUserThumbnailAsync(friend.VisitorId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		frame.DisplayName.Text = friend.DisplayName
		if friend.LocationType == LocationType.InGame or friend.LocationType == LocationType.MobileInGame then
			frame.GameName.Text = friend.LastLocation or "In a game"
		elseif friend.LocationType == LocationType.Website or friend.LocationType == LocationType.MobileWebsite or friend.LocationType == LocationType.XBoxApp then
			frame.GameName.Text = "Online"
		elseif friend.LocationType == LocationType.Studio or friend.LocationType == LocationType.TeamCreate then
			frame.GameName.Text = "In Studio"
		else
			frame.GameName.Text = "Offline"
		end
	end
end

listFriends()

task.spawn(function()
	while true do
		task.wait(30)
		listFriends()
	end
end)
