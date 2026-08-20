local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local PartyManager = require(ReplicatedStorage.Spawnpad.PartyManager)

local Parties = ReplicatedStorage:WaitForChild("Parties")

local GetParty = Parties:WaitForChild("GetParty")
local CreateParty = Parties:WaitForChild("CreateParty")
local InviteToParty = Parties:WaitForChild("InviteToParty")
local LeaveParty = Parties:WaitForChild("LeaveParty")
local DisbandParty = Parties:WaitForChild("DisbandParty")
local AcceptInvite = Parties:WaitForChild("AcceptInvite")
local DeclineInvite = Parties:WaitForChild("DeclineInvite")
local MemberAdded = Parties:WaitForChild("MemberAdded")
local MemberRemoved = Parties:WaitForChild("MemberRemoved")

local INVITE_TOPIC = "Party:InvitePlayer"
local INVITE_ACCEPTED_TOPIC = "Party:InviteAccepted"

local invites = {}

GetParty.OnServerInvoke = function(player)
	local result

	local manager = PartyManager:getParty(player)
	if manager then
		result = {
			id = manager.id,
			ownerId = manager.ownerId,
			members = manager.members,
		}
	end

	return result
end

CreateParty.OnServerInvoke = function(player)
	local result, err

	if PartyManager.get(PartyManager, player) then
		err = "Already in a party"
	else
		local manager = PartyManager.new(player.UserId)
		manager.onJoin = function(party, memberId)
			for memberId2 in party.members do
				local member = game.Players:GetPlayerByUserId(memberId2)
				if member then
					MemberAdded:FireClient(member, memberId)
				end
			end
		end
		manager.onLeave = function(party, memberId)
			for memberId2 in party.members do
				local member = game.Players:GetPlayerByUserId(memberId2)
				if member then
					MemberRemoved:FireClient(member, memberId)
				end
			end
		end
		result = {
			id = manager.id,
			ownerId = manager.ownerId,
			members = manager.members,
		}
	end

	return result, err
end

InviteToParty.OnServerEvent:Connect(function(player, invitedPlayerId)
	local manager = PartyManager:getParty(player)
	if not manager then
		return
	end

	if manager.ownerId ~= player.UserId then
		return
	end

	if manager.members[invitedPlayerId] then
		return
	end

	MessagingService:PublishAsync(INVITE_TOPIC, {
		player = invitedPlayerId,
		partyId = manager.id,
	})

	invites[invitedPlayerId] = manager.id

	local connection
	connection = MessagingService:SubscribeAsync(INVITE_ACCEPTED_TOPIC, function(message)
		local data = message.Data
		if data.player == invitedPlayerId and data.partyId == manager.id then
			if manager.members[invitedPlayerId] then
				return
			end

			manager:add(invitedPlayerId)
			invites[invitedPlayerId] = nil

			if connection then
				connection:Disconnect()
			end
		end
	end)

	task.delay(2 * 60, function()
		if connection then
			connection:Disconnect()
			invites[invitedPlayerId] = nil
		end
	end)
end)

LeaveParty.OnServerEvent:Connect(function(player)
	local manager = PartyManager:getParty(player)
	if not manager then
		return
	end

	manager:remove(player.UserId)

	if not next(manager.members) then
		manager:disband()
	elseif manager.ownerId == player.UserId then
		for memberId in manager.members do
			manager.ownerId = memberId
			break
		end
	end
end)

DisbandParty.OnServerEvent:Connect(function(player)
	local manager = PartyManager:getParty(player)
	if not manager then
		return
	end

	if manager.ownerId ~= player.UserId then
		return
	end

	manager:disband()
end)

AcceptInvite.OnServerInvoke = function(player)
	local result, err

	if PartyManager.get(PartyManager, player) then
		err = "Already in a party"
	else
		local partyId = invites[player.UserId]
		if not partyId then
			err = "No invite"
		else
			MessagingService:PublishAsync(INVITE_ACCEPTED_TOPIC, {
				player = player.UserId,
				partyId = partyId,
			})

			local manager = PartyManager:getParty(player)
			if manager then
				result = {
					id = manager.id,
					ownerId = manager.ownerId,
					members = manager.members,
				}
			else
				err = "Party not found"
			end
		end
	end

	return result, err
end

DeclineInvite.OnServerEvent:Connect(function(player)
	invites[player.UserId] = nil
end)
