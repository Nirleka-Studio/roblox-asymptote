--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local timeline = require(ReplicatedStorage.shared.interpolation.timeline)
local Signal = require(ReplicatedStorage.shared.thirdparty.Signal)

type Timeline = timeline.Timeline
type Connection<T...> = Signal.Connection<T...>

export type SuspicionComp = {
	raise_speed: number,
	lower_speed: number,
	current_sus: number,
	target_sus: number,
	timeline: Timeline,
	_connection: typeof(
		Signal.new():Connect(function()
			return
		end)
	)?
}

local suscomp = {}

function suscomp.create(raise_speed: number, lower_speed: number): SuspicionComp
	return {
		raise_speed = raise_speed,
		lower_speed = lower_speed,
		current_sus = 0,
		target_sus = 0,
		timeline = timeline.create(0, 0, 0), -- useless.
		_connection = nil
	}
end

function suscomp.update_suspicion_target(self: SuspicionComp, new_target: number, on_step_func: (number) -> ()?): ()
	if new_target == self.target_sus then
		return
	end
	self.target_sus = new_target
	local suspicion_difference = math.abs(new_target - self.current_sus)
	local duration
	if new_target > self.current_sus then
		duration = suspicion_difference / self.raise_speed
	else
		duration = suspicion_difference / self.lower_speed
	end
	-- this should've been handled by the timeline itself but fuck it at this point.
	self.timeline = timeline.create(self.current_sus, new_target, duration)
	self._connection = self.timeline.step:Connect(function()
		local cur_val = self.timeline.current_value
		self.current_sus = cur_val
		if on_step_func then
			on_step_func(cur_val)
		end
	end)
	self.timeline:play_from_start()
end

return suscomp