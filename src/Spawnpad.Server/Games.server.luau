local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local searchGamesEvent = ReplicatedStorage:WaitForChild("Games"):WaitForChild("Search")
local teleportMeEvent = ReplicatedStorage:WaitForChild("Games"):WaitForChild("TeleportMe")
local topPlayingEvent = ReplicatedStorage:WaitForChild("Games"):WaitForChild("TopPlaying")

local gameCache = {}
local failedCache = {}

local playerCooldowns = {}
local lastGameApiRequest = 0

local PLAYER_COOLDOWN = 1
local GAME_API_COOLDOWN = 0.25
local MAX_RETRIES = 3

local topPlayingCache = nil
local topPlayingCacheTime = 0
local TOP_PLAYING_CACHE_DURATION = 300

local function request(url)
	for attempt = 1, MAX_RETRIES do
		local now = os.clock()
		local waitTime = GAME_API_COOLDOWN - (now - lastGameApiRequest)

		if waitTime > 0 then
			task.wait(waitTime)
		end

		lastGameApiRequest = os.clock()

		local success, result = pcall(function()
			return HttpService:GetAsync(url)
		end)

		if success then
			return result
		end

		-- Roblox rate limit response
		if tostring(result):find("429") then
			task.wait(attempt * 2)
		else
			warn("HTTP request failed:", result)
			break
		end
	end

	return nil
end

local function getGameFromPlaceId(placeId)
	if gameCache[placeId] then
		return gameCache[placeId]
	end

	if failedCache[placeId] then
		return nil
	end

	-- Place ID -> Universe ID
	local universeResult = request(("https://apis.roproxy.com/universes/v1/places/%d/universe"):format(placeId))

	if not universeResult then
		failedCache[placeId] = true
		return nil
	end

	local universeData = HttpService:JSONDecode(universeResult)

	if not universeData.universeId then
		failedCache[placeId] = true
		return nil
	end

	local universeId = universeData.universeId

	-- Universe ID -> Game info
	local gameResult = request(("https://games.roproxy.com/v1/games?universeIds=%d"):format(universeId))

	if not gameResult then
		failedCache[placeId] = true
		return nil
	end

	local gameData = HttpService:JSONDecode(gameResult)

	if not gameData.data or #gameData.data == 0 then
		failedCache[placeId] = true
		return nil
	end

	local game = gameData.data[1]

	local result = {
		Name = game.name,
		UniverseId = universeId,
		PlaceId = placeId,
		Icon = ("rbxthumb://type=GameIcon&id=%d&w=150&h=150"):format(universeId),
		Playing = game.playing,
		Visits = game.visits,
		Creator = game.creator,
	}

	gameCache[placeId] = result

	return result
end

-- don't know when that can be used, but if it will, better to keep here
local function _getGamesFromUniverseIds(universeIds)
	if #universeIds == 0 then
		return {}
	end

	local result = request(("https://games.roproxy.com/v1/games?universeIds=%s"):format(table.concat(universeIds, ",")))

	if not result then
		return {}
	end

	local data = HttpService:JSONDecode(result)

	local gamesById = {}

	for _, game in ipairs(data.data) do
		gamesById[game.id] = {
			Name = game.name,
			UniverseId = game.id,
			PlaceId = game.rootPlaceId,
			Icon = ("rbxthumb://type=GameIcon&id=%d&w=150&h=150"):format(game.id),
			Playing = game.playing,
			Visits = game.visits,
			Creator = game.creator,
		}
	end

	local games = {}

	-- Preserve the original order
	for _, universeId in ipairs(universeIds) do
		if gamesById[universeId] then
			table.insert(games, gamesById[universeId])
		end
	end

	return games
end

searchGamesEvent.OnServerInvoke = function(player, term)
	local now = os.clock()

	if playerCooldowns[player] and now - playerCooldowns[player] < PLAYER_COOLDOWN then
		return {}
	end

	playerCooldowns[player] = now

	local placeId = tonumber(term)

	if placeId then
		local game = getGameFromPlaceId(placeId)

		if game then
			return { game }
		end
	end

	local result = request(
		("https://apis.roproxy.com/search-api/omni-search?searchQuery=%s&pageToken=&sessionId=e27be281-6266-492b-becd-02e54616594c&pageType=all"):format(
			HttpService:UrlEncode(term)
		)
	)

	if not result then
		return {}
	end

	local data = HttpService:JSONDecode(result)
	local games = {}

	for _, item in ipairs(data.searchResults) do
		if item.contents and item.contents[1] then
			local game = item.contents[1]
			local universeId = game.universeId

			table.insert(games, {
				Name = game.name,
				UniverseId = universeId,
				PlaceId = game.rootPlaceId,
				Icon = ("rbxthumb://type=GameIcon&id=%d&w=150&h=150"):format(universeId),
			})
		end
	end

	return games
end

teleportMeEvent.OnServerEvent:Connect(function(player, placeId)
	local TeleportService = game:GetService("TeleportService")
	TeleportService:TeleportAsync(placeId, { player })
end)

topPlayingEvent.OnServerInvoke = function()
	local success, result = pcall(function()
		local now = os.clock()

		if topPlayingCache and now - topPlayingCacheTime < TOP_PLAYING_CACHE_DURATION then
			return topPlayingCache
		end

		local result2 =
			request("https://apis.roproxy.com/explore-api/v1/get-sorts?sessionId=eca8b6ef-a152-4b67-bb1d-89ad27afd9f6")

		if not result2 then
			-- Return old cache if Roblox is temporarily unavailable
			if topPlayingCache then
				return topPlayingCache
			end

			return {}
		end

		local data = HttpService:JSONDecode(result2)

		local topPlayingSort

		for _, sort in ipairs(data.sorts) do
			if sort.sortId == "top-playing-now" then
				topPlayingSort = sort
				break
			end
		end

		if not topPlayingSort then
			warn("top-playing-now sort not found")

			if topPlayingCache then
				return topPlayingCache
			end

			return {}
		end

		local games = {}

		for i, game in ipairs(topPlayingSort.games) do
			if i > 9 then
				break
			end

			table.insert(games, {
				Name = game.name,
				UniverseId = game.universeId,
				PlaceId = game.rootPlaceId,
				Icon = ("rbxthumb://type=GameIcon&id=%d&w=150&h=150"):format(game.universeId),
			})
		end

		return games
	end)

	if not success then
		warn("TopPlaying failed:", result)
		return {}
	end

	return result
end

game.Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player] = nil
end)
