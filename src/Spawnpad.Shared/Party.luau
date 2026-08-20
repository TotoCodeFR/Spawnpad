local MessagingService = game:GetService("MessagingService")
local PartyManager = require(script.Parent.PartyManager)

local Party = {}
Party.__index = Party

local INVITE_TOPIC = "Party:InvitePlayer"
local INVITE_ACCEPTED_TOPIC = "Party:InviteAccepted"

function Party.new(owner)
	local self = setmetatable({
		manager = PartyManager.new(owner),
		ready = {},
		invited = {},
	}, Party)

	return self
end

function Party:invite(player)
	MessagingService:PublishAsync(INVITE_TOPIC, {
		player = player,
		partyId = self.manager.id,
	})

	table.insert(self.invited, player)
	local inviteAcceptedMessage
	inviteAcceptedMessage = MessagingService:SubscribeAsync(INVITE_ACCEPTED_TOPIC, function(message)
		local data = message.Data
		local player2, partyId = data.player, data.partyId
		if player2 == player and partyId == self.manager.id then
			if self.manager.members[player] then
				return
			end
			if not table.find(self.invited, player) then
				return
			end
			self.manager:add(player)
			table.remove(self.invited, table.find(self.invited, player))
			if inviteAcceptedMessage then
				inviteAcceptedMessage:Disconnect()
			end
		end
	end)

	task.delay(2 * 60, function()
		if inviteAcceptedMessage then
			inviteAcceptedMessage:Disconnect()
			local index = table.find(self.invited, player)
			if index then
				table.remove(self.invited, index)
			end
		end
	end)

	return true
end

function Party:leave(player)
	self.manager:remove(player)
	self.ready[player] = nil
end

return Party
