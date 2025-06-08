--!strict

local Signal = require(game.ReplicatedStorage.shared.thirdparty.Signal)

local suspicion = {}
suspicion.__index = suspicion

export type SuspicionLevel = typeof(setmetatable({} :: {
	current_sus: number,
	start_sus: number,
	lower_speed: number,
	raise_speed: number,
	target_sus: number,
	_dur: number,
	_elapsed: number,
	finished: boolean,
	focusing_player: Player?,
	playing: boolean,

	on_suspicion_update: Signal.Signal<Player>,
	on_suspicion_max: Signal.Signal<Player>
}, suspicion))

function suspicion.create(raise_speed: number, lower_speed: number): SuspicionLevel
	return setmetatable({
		current_sus = 0,
		start_sus = 0,
		lower_speed = lower_speed,
		raise_speed = raise_speed,
		target_sus = 0,
		_dur = 0,
		_elapsed = 0,
		finished = false,
		focusing_player = nil :: Player?, -- WHY.
		playing = false,

		on_suspicion_update = Signal.new(),
		on_suspicion_max = Signal.new()
	}, suspicion)
end

function suspicion.update(self: SuspicionLevel, delta: number): ()
	if not self.playing then
		return
	end
	if self.finished then
		return
	end
	if self.current_sus == self.target_sus then
		--print("the same")
		if not self.finished and self.playing then
			--print("not finished")
			self.finished = true -- "Type 'true' could not be converted into 'false'" LUAU FIX YOUR BULLSHIT.
			self.on_suspicion_max:Fire(self.focusing_player :: Player)
			return
		end
	end

	--print("passed")

	self._elapsed += delta

	local c = math.clamp(self._elapsed / self._dur, 0.0, 1.0)
	self.current_sus = math.lerp(self.start_sus, self.target_sus, c)
	self.on_suspicion_update:Fire(self.focusing_player)
end

function suspicion.update_suspicion_target(self: SuspicionLevel, new_target: number, plr: Player): ()
	print("new target:", new_target)
	--new_target = math.clamp(new_target, 0, 1)

	if new_target == self.target_sus then
		self.playing = false
		return
	end

	self.playing = true
	self.finished = false -- CRUCIAL FIX
	self._elapsed = 0 -- CRUCIAL FIX
	self.focusing_player = plr
	self.target_sus = new_target
	self.start_sus = self.current_sus

	local suspicion_difference = math.abs(new_target - self.current_sus)
	local duration
	if new_target > self.current_sus then
		duration = suspicion_difference / self.raise_speed
	else
		duration = suspicion_difference / self.lower_speed
	end

	self._dur = duration
end

return suspicion