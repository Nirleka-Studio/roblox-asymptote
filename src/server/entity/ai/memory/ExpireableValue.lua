--!strict

local ExpireableValue = {}
ExpireableValue.__index = ExpireableValue

export type ExpireableValue<T> = typeof(setmetatable({} :: {
	value: T?,
	timeToLive: number
}, ExpireableValue))

function ExpireableValue.new<T>(value: T, expiresIn: number): ExpireableValue<T>
	return setmetatable({
		value = value,
		timeToLive = expiresIn,
	}, ExpireableValue)
end

function ExpireableValue.getValue<T>(self: ExpireableValue<T>): T?
	return self.value
end

function ExpireableValue.isExpired<T>(self: ExpireableValue<T>): boolean
	return self.timeToLive < 0
end

function ExpireableValue.update<T>(self: ExpireableValue<T>, delta: number): ()
	if self.timeToLive > 0 then
		self.timeToLive -= delta
	end
end

return ExpireableValue