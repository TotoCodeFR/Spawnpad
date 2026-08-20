local Notifications = {}
Notifications.__index = Notifications

type Notification = {
	notification: CanvasGroup,
}

local notificationTemplate =
	game:GetService("ReplicatedStorage"):WaitForChild("Notifications"):WaitForChild("Notification")

function Notifications.new(body: string, image: number)
	local notification: CanvasGroup = notificationTemplate:Clone()
	local bodyLabel = notification:WaitForChild("Body") :: TextLabel
	bodyLabel.Text = body
	if image then
		game:GetService("ContentProvider"):PreloadAsync({ "rbxassetid://" .. image })
		local icon = notification:WaitForChild("Icon") :: ImageLabel
		icon.Image = "rbxassetid://" .. image
	end
	notification.Parent = game.Players.LocalPlayer.PlayerGui.Notifications.LandZone
	local self = {
		notification = notification,
	}
	setmetatable(self, Notifications)
	return self
end

function Notifications.show(self: Notification)
	local height = 0
	local notifCount = 0
	local parent = self.notification.Parent
	if parent then
		for _, notification in pairs(parent:GetChildren()) do
			if
				notification:IsA("CanvasGroup")
				and notification.Name == "Notification"
				and notification ~= self.notification
			then
				height = height + notification.AbsoluteSize.Y
				notifCount += 1
			end
		end
	end

	height += notifCount * 8

	self.notification.Position = UDim2.new(1.2, 0, 0, height)
	self.notification.Visible = true
	local tween = game:GetService("TweenService"):Create(
		self.notification,
		TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
		{ Position = UDim2.fromOffset(0, height), GroupTransparency = 0 }
	)
	tween:Play()
	local tween2 = game:GetService("TweenService"):Create(
		self.notification:WaitForChild("Flash"),
		TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	tween2:Play()
end

return Notifications
