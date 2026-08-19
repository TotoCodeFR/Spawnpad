-- local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")

local Party = {}
Party.__index = Party

local INVITE_TOPIC = "Party:InvitePlayer"
local INVITE_ACCEPTED_TOPIC = "Party:InviteAccepted"

function Party.new(owner: number)
	local partyId = "Party_" .. game:GetService("HttpService"):GenerateGUID(false)
	local self = {
		owner = owner,
		players = { owner },
		ready = {},
		partyId = partyId,
		invited = {},
	}
	setmetatable(self, Party)

	return self
end

function Party:invite(player: number)
	MessagingService:PublishAsync(INVITE_TOPIC, {
		player = player,
		partyId = self.partyId,
	})

	table.insert(self.invited, player)
	local inviteAcceptedMessage: RBXScriptConnection | nil
	inviteAcceptedMessage = MessagingService:SubscribeAsync(INVITE_ACCEPTED_TOPIC, function(message)
		local data = message.Data
		local player2, partyId = data.player, data.partyId
		if player2 == player and partyId == self.partyId then
			if table.find(self.players, player) then
				return
			end
			if not table.find(self.invited, player) then
				return
			end
			table.insert(self.players, player)
			table.remove(self.invited, table.find(self.invited, player))
			if inviteAcceptedMessage then
				inviteAcceptedMessage:Disconnect()
			end
			inviteAcceptedMessage = nil
		end
	end)

	task.delay(2 * 60, function()
		if inviteAcceptedMessage then
			inviteAcceptedMessage:Disconnect()
			inviteAcceptedMessage = nil
			local index = table.find(self.invited, player)
			if index then
				table.remove(self.invited, index)
			end
		end
	end)

	return true
end

function Party:leave(player: number)
	local index = table.find(self.players, player)
	if index then
		table.remove(self.players, index)
		self.ready[player] = nil
	end
end

return Party
