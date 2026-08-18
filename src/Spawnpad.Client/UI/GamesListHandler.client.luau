local ReplicatedStorage = game:GetService("ReplicatedStorage")
local searchGamesEvent = ReplicatedStorage:WaitForChild("Games"):WaitForChild("Search")
local topPlayingEvent = ReplicatedStorage:WaitForChild("Games"):WaitForChild("TopPlaying")
local player = game:GetService("Players").LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("Games"):WaitForChild("Main")
local searchBox = gui:WaitForChild("SearchBox")
local scrollingFrame = gui:WaitForChild("SearchResults")
local gameResultTemplate = ReplicatedStorage:WaitForChild("Templates"):WaitForChild("Games"):WaitForChild("Game")

local function listGames(games, parent)
	if not parent then
		parent = scrollingFrame
	end
	for _, child in pairs(parent:GetChildren()) do
		if child:IsA("CanvasGroup") then
			child:Destroy()
		end
	end
	for _, gameItem in pairs(games) do
		local clone = gameResultTemplate:Clone()
		clone.Parent = parent
		clone.GameName.Text = gameItem.Name
		clone.Icon.Image = gameItem.Icon
		clone.Ignore.Click.MouseButton1Click:Connect(function()
			ReplicatedStorage:WaitForChild("Games"):WaitForChild("TeleportMe"):FireServer(gameItem.PlaceId)
		end)
	end
end

local function searchGames(searchTerm)
	local games = {}

	local result = searchGamesEvent:InvokeServer(searchTerm)

	for _, gameItem in pairs(result) do
		table.insert(games, gameItem)
	end

	return games
end

local function getTopPlaying()
	local games = {}

	local result = topPlayingEvent:InvokeServer()

	for _, gameItem in pairs(result) do
		table.insert(games, gameItem)
	end

	return games
end

searchBox.FocusLost:Connect(function(enter)
	if enter then
		local searchTerm = searchBox.Text
		local games = searchGames(searchTerm)
		listGames(games)
	end
end)

task.delay(3, function()
	local mostCCU = gui.MainPage.MostCCU

	local topPlaying = getTopPlaying()

	listGames(topPlaying, mostCCU.List)
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local text = searchBox.Text
	if text == "" then
		gui.MainPage.MostCCU.Visible = true
		gui.SearchResults.Visible = false
	else
		gui.MainPage.MostCCU.Visible = false
		gui.SearchResults.Visible = true
	end
end)
