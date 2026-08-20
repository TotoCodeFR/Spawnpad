local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")

local PartyManager = {}
PartyManager.__index = PartyManager

local PARTY_STORE = DataStoreService:GetDataStore("Parties")
local PLAYER_STORE = DataStoreService:GetDataStore("Parties:Players")

local partyCache = {}
local playerCache = {}
local saveQueue = {}

local function serialize(party)
	return {
		id = party.id,
		ownerId = party.ownerId,
		members = party.members,
		createdAt = party.createdAt,
		updatedAt = os.time(),
	}
end

local function queueSave(partyId, data)
	saveQueue[partyId] = data
end

local function processSaveQueue()
	while true do
		for partyId, data in saveQueue do
			saveQueue[partyId] = nil
			local ok, err = pcall(PARTY_STORE.SetAsync, PARTY_STORE, partyId, data)
			if not ok then
				warn("[PartyManager] Save failed:", err)
				saveQueue[partyId] = data
			end
		end
		task.wait(1)
	end
end

local function savePlayerMapping(playerId, partyId)
	pcall(PLAYER_STORE.SetAsync, PLAYER_STORE, tostring(playerId), partyId)
end

local function loadPlayerMapping(playerId)
	local ok, result = pcall(PLAYER_STORE.GetAsync, PLAYER_STORE, tostring(playerId))
	return ok and result or nil
end

local function broadcast(partyId, action)
	pcall(MessagingService.PublishAsync, MessagingService, "PartySync", {
		action = action,
		partyId = partyId,
	})
end

local function refreshFromStore(partyId)
	local ok, data = pcall(PARTY_STORE.GetAsync, PARTY_STORE, partyId)
	if ok and data then
		local self = setmetatable({
			id = data.id,
			ownerId = data.ownerId,
			members = data.members or {},
			createdAt = data.createdAt,
			onJoin = nil :: ((party: any, playerId: number) -> ()) | nil,
			onLeave = nil :: ((party: any, playerId: number) -> ()) | nil,
		}, PartyManager)

		partyCache[partyId] = self
		for memberId in self.members do
			playerCache[memberId] = partyId
		end
	else
		partyCache[partyId] = nil
	end
end

local function onMessage(message)
	local payload = message.Data
	local partyId = payload.partyId

	if payload.action == "disband" then
		local party = partyCache[partyId]
		if party then
			for memberId in party.members do
				playerCache[memberId] = nil
			end
		end
		partyCache[partyId] = nil
	elseif payload.action == "update" then
		refreshFromStore(partyId)
	end
end

pcall(MessagingService.SubscribeAsync, MessagingService, "PartySync", onMessage)
task.spawn(processSaveQueue)

function PartyManager.new(ownerId: number)
	local self = setmetatable({
		id = HttpService:GenerateGUID(false),
		ownerId = ownerId,
		members = { [ownerId] = true },
		createdAt = os.time(),
		onJoin = nil :: ((party: any, playerId: number) -> ()) | nil,
		onLeave = nil :: ((party: any, playerId: number) -> ()) | nil,
	}, PartyManager)

	partyCache[self.id] = self
	playerCache[ownerId] = self.id

	queueSave(self.id, serialize(self))
	savePlayerMapping(ownerId, self.id)
	broadcast(self.id, "update")

	return self
end

function PartyManager.get(_self, player)
	local playerId = if typeof(player) == "Player" then player.UserId else player :: number

	local partyId = playerCache[playerId]
	if partyId and partyCache[partyId] then
		return partyId
	end

	partyId = loadPlayerMapping(playerId)
	if partyId then
		refreshFromStore(partyId)
		return partyId
	end

	return nil
end

function PartyManager:getParty(player)
	local playerId = if typeof(player) == "Player" then player.UserId else player :: number

	local partyId = playerCache[playerId]
	if not partyId or not partyCache[partyId] then
		partyId = loadPlayerMapping(playerId)
		if partyId then
			refreshFromStore(partyId)
		end
	end

	return partyId and partyCache[partyId]
end

function PartyManager:add(player)
	local playerId = if typeof(player) == "Player" then player.UserId else player :: number

	if self.members[playerId] then
		return self
	end

	self.members[playerId] = true
	partyCache[self.id] = self
	playerCache[playerId] = self.id

	queueSave(self.id, serialize(self))
	savePlayerMapping(playerId, self.id)
	broadcast(self.id, "update")

	if self.onJoin then
		self.onJoin(self, playerId)
	end

	return self
end

function PartyManager:remove(player)
	local playerId = if typeof(player) == "Player" then player.UserId else player :: number

	if not self.members[playerId] then
		return self
	end

	self.members[playerId] = nil
	partyCache[self.id] = self
	playerCache[playerId] = nil

	queueSave(self.id, serialize(self))
	savePlayerMapping(playerId, nil)
	broadcast(self.id, "update")

	if self.onLeave then
		self.onLeave(self, playerId)
	end

	return self
end

function PartyManager:disband()
	pcall(PARTY_STORE.RemoveAsync, PARTY_STORE, self.id)

	for memberId in self.members do
		savePlayerMapping(memberId, nil)
		playerCache[memberId] = nil
	end

	partyCache[self.id] = nil
	broadcast(self.id, "disband")

	return nil
end

return PartyManager
