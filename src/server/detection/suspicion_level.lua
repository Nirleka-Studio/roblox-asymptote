--!strict

local lerper = require(game.ReplicatedStorage.shared.interpolation.lerper)
local Signal = require(game.ReplicatedStorage.shared.thirdparty.Signal)

local suspicion = {}
suspicion.__index = suspicion

export type SuspicionLevel = typeof(setmetatable({} :: {
	suspicion_level: number,
	suspicion_decrement_speed: number,
	suspicion_increment_speed: number,
	curiosity_threshold: number,
	calm_threshold: number,
	alerted: boolean,
	target_player: Player?,
	_lerper: lerper.LerpObject,

	on_suspicion_update: Signal.Signal<Player>,
	on_alerted: Signal.Signal<Player>
}, suspicion))

function suspicion.create(raise_speed: number, lower_speed: number): SuspicionLevel
	return setmetatable({
		suspicion_level = 0,
		suspicion_decrement_speed = lower_speed,
		suspicion_increment_speed = raise_speed,
		curiosity_threshold = 0,
		calm_threshold = 0,
		alerted = false,
		target_player = nil :: Player?, -- jesus fucking christ, why.
		_lerper = lerper.create(0, 0, 0), -- dummy

		on_suspicion_update = Signal.new(),
		on_alerted = Signal.new()
	}, suspicion)
end

function suspicion.update(self: SuspicionLevel, delta: number): ()
	-- suspicion has reached 1
	local alerted = self.alerted -- this wont fool the typechecker when it gets smarter... oh well.
	if alerted then
		print("alerted")
		return
	end

	local target_player = self.target_player
	if not target_player then
		print("no target player")
		return -- this shouldnt even happen but its for the sake of the typechecker.
	end

	-- the lerper.step function returns true if finished and false if doesnt
	local finished = self._lerper:step(delta)
	self.suspicion_level = self._lerper.current_value
	self.on_suspicion_update:Fire(target_player)

	if finished then
		if self._lerper.final_value == 1 then
			self.alerted = true
			self.on_alerted:Fire(target_player)
		end
	end
end

function suspicion.update_suspicion_target(self: SuspicionLevel, new_target: number, plr: Player): ()
	local suspicion_difference = math.abs(new_target - self.suspicion_level)
	local duration
	if new_target > self.suspicion_level then
		duration = suspicion_difference / self.suspicion_increment_speed
	else
		duration = suspicion_difference / self.suspicion_decrement_speed
	end

	self._lerper:reset(self.suspicion_level, new_target, duration)
	self.target_player = plr
end

return suspicion