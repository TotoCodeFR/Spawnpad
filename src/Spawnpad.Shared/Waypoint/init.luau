local HttpService = game:GetService("HttpService")
local DataTypeLoader = require("./Waypoint/DataTypeLoader")
local Waypoint = {}
Waypoint.__index = Waypoint

local SPAWNPAD_WAYPOINT_URL_EXISTS, SPAWNPAD_WAYPOINT_URL = pcall(function(...)
	return HttpService:GetSecret("SPAWNPAD_WAYPOINT_URL")
end)
local SPAWNPAD_WAYPOINT_INSECURE_EXISTS, SPAWNPAD_WAYPOINT_INSECURE = pcall(function(...)
	return HttpService:GetSecret("SPAWNPAD_WAYPOINT_INSECURE")
end)

Waypoint.BASE_URL = ((SPAWNPAD_WAYPOINT_URL_EXISTS and SPAWNPAD_WAYPOINT_URL) or "localhost:3000")
Waypoint.API_URL = ((SPAWNPAD_WAYPOINT_INSECURE_EXISTS) and "http://" or "https://" ) .. Waypoint.BASE_URL
Waypoint.WS_URL = ((SPAWNPAD_WAYPOINT_INSECURE_EXISTS) and "ws://" or "wss://") .. Waypoint.BASE_URL

DataTypeLoader:LoadDataTypes()

function Waypoint.new(userId: number)
	local self = setmetatable({}, Waypoint)
	self.userId = userId

	local tokenSuccess, token = pcall(function()
		return HttpService:RequestAsync({
			Url = Waypoint.API_URL .. "/api/v1/auth/roblox",
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = HttpService:JSONEncode({
				userId = userId,
			}),
		})
	end)

	if not tokenSuccess then
		error(token)
		return token
	end

	local tokenData = HttpService:JSONDecode(token.Body)

	self.token = tokenData.token

	self.wsError = false

	self.ws = HttpService:CreateWebStreamClient(Enum.WebStreamClientType.WebSocket, {
		Url = Waypoint.WS_URL .. "/api/v1/ws/ws",
		Headers = {
			["Authorization"] = "Bearer " .. self.token,
		},
	})

	self.ws.Error:Connect(function(code: number, message: string)
		self.wsError = true
		error("WS Error: " .. tostring(code) .. ": " .. message)
	end)

	self.ws.Closed:Connect(function()
	    if self.wsError then
			return
		end
		error("WS Connection closed.")
	end)

	self.ws.MessageReceived:Connect(function(message: string)
		local dataTable = HttpService:JSONDecode(message)
		local data, type = dataTable.data, dataTable.type

		DataTypeLoader:CallDataType(type, data)
	end)

	self.ws:Send(HttpService:JSONEncode({
		type = "whoami",
	}))

	return self
end

return Waypoint
