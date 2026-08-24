local Orbit = {}

export type OrbitButton = "TextButton" | "ImageButton"
export type OrbitLabel = "TextLabel" | "ImageLabel"
export type OrbitInput = "TextBox"

export type OrbitInstances = OrbitButton | OrbitLabel | OrbitInput

type OrbitObject = {
	_instance: Instance,
	_props: { [string]: any },
}

local OrbitMetatable = {}

function OrbitMetatable.__index(self: OrbitObject, key: string): any
	local method = Orbit[key]

	if method ~= nil then
		return method
	end

	local props = self._props
	if props[key] ~= nil then
		return props[key]
	end

	return (self._instance :: any)[key]
end

function OrbitMetatable.__newindex(
	self: OrbitObject,
	key: string,
	value: any
)
	local instance = self._instance :: any

	local success = pcall(function()
		instance[key] = value
	end)

	if success then
		return
	end

	self._props[key] = value
end

function Orbit.new(
	className: OrbitInstances,
	props: { [string]: any }
): OrbitObject
	local instance = Instance.new(className)

	local self = {
		_instance = instance,
		_props = {},
	}

	setmetatable(self, OrbitMetatable)

	local object = self :: any

	for key, value in props do
		object[key] = value
	end

	return object
end

function Orbit.template(self: OrbitObject, props: { [string]: any })
	for key, value in props do
		self[key] = value
	end
end

function Orbit.getInstance(self: OrbitObject): Instance
	return self._instance
end

return Orbit
