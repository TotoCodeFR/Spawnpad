local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("Main"):WaitForChild("Main")
local gamesGui = playerGui:WaitForChild("Games"):WaitForChild("Main")
-- don't use that, doesn't exist yet
-- local viewportFrame = script.Parent.ViewportFrame:WaitForChild("ViewportFrame")
-- local model = viewportFrame:WaitForChild("controller")

script.Parent.MouseButton1Click:Connect(function()
	gamesGui.Visible = true
	mainGui.Visible = false
end)
