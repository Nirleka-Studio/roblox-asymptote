--!strict

--[=[
	@class Lerper

	A simple tool for linear interpolation.
]=]
local lerper = {}
lerper.__index = lerper

export type LerpObject = typeof(setmetatable({} :: {
	current_value: number,
	start_value: number,
	final_value: number,
	duration: number,
	elapsed: number
}, lerper))

function lerper.create(from: number, to: number, duration: number): LerpObject
	return setmetatable({
		current_value = from,
		start_value = from,
		final_value = to,
		duration = duration,
		elapsed = 0
	}, lerper)
end

--[=[
	Returns true if its done, false if not.
]=]
function lerper.step(self: LerpObject, delta: number): boolean
	if self.current_value == self.final_value then
		return true
	end

	self.elapsed += delta

	-- keeps c between 0 and 1.
	local c = math.clamp(self.elapsed / self.duration, 0.0, 1.0)
	self.current_value = math.lerp(self.start_value, self.final_value, c)
	return false
end

return lerper