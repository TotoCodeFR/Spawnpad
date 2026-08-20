local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local eventsFolder = ReplicatedStorage:WaitForChild("Parties")

local _AcceptInvite = eventsFolder:WaitForChild("AcceptInvite")
local GetParty = eventsFolder:WaitForChild("GetParty")
local _CreateParty = eventsFolder:WaitForChild("CreateParty")
local _LeaveParty = eventsFolder:WaitForChild("LeaveParty")
local _InviteToParty = eventsFolder:WaitForChild("InviteToParty")
local _DisbandParty = eventsFolder:WaitForChild("DisbandParty")
local MemberAdded = eventsFolder:WaitForChild("MemberAdded")
local MemberRemoved = eventsFolder:WaitForChild("MemberRemoved")

local gui = player:WaitForChild("PlayerGui"):WaitForChild("Party"):WaitForChild("Main")
local memberList = gui:WaitForChild("Members"):WaitForChild("MemberList")
local playerTemplate = ReplicatedStorage:WaitForChild("Parties"):WaitForChild("PlayerTemplate")

local memberFrames = {}

local function addMemberFrame(memberId)
	if memberFrames[memberId] then
		return
	end

	local frame = playerTemplate:Clone()
	frame.Name = tostring(memberId)
	frame.Parent = memberList
	frame.Visible = true

	local userInfo =
		Players:GetUserThumbnailAsync(memberId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	frame.Icon.Image = userInfo

	local success, displayName = pcall(function()
		return Players:GetNameFromUserIdAsync(memberId)
	end)
	frame.DisplayName.Text = success and displayName or "Unknown"

	memberFrames[memberId] = frame
end

local function removeMemberFrame(memberId)
	local frame = memberFrames[memberId]
	if frame then
		frame:Destroy()
		memberFrames[memberId] = nil
	end
end

local function clearMemberList()
	for memberId, frame in memberFrames do
		frame:Destroy()
		memberFrames[memberId] = nil
	end
end

local function refreshParty()
	clearMemberList()

	local party = GetParty:InvokeServer()
	if not party then
		return
	end

	for memberId in party.members do
		addMemberFrame(memberId)
	end
end

MemberAdded.OnClientEvent:Connect(function(memberId)
	addMemberFrame(memberId)
end)

MemberRemoved.OnClientEvent:Connect(function(memberId)
	removeMemberFrame(memberId)
end)

refreshParty()
