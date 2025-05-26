--!strict

local RunService = game:GetService("RunService")
local Signal = require("../thirdparty/Signal")
local lerper = require("./lerper")

local EPSILON = 1e-6

local timeline = {}
timeline.__index = timeline

type Signal<T...> = Signal.Signal<T...>

type TimelineData = {
	duration: number,
	comp_lerper: lerper.LerpObject,
	current_value: number,
	start_value: number,
	final_value: number,
	direction: "forward" | "reverse",
	is_playing: boolean,
	is_finished: boolean,

	step: Signal<...any>, -- Signal with no arguments
	finished: Signal<...any>, -- Signal with no arguments
	_step_connection: RBXScriptConnection?
}

export type Timeline = typeof(setmetatable({} :: TimelineData, timeline))

-- float bullshit.
local function are_equal(a: number, b: number): boolean
	return math.abs(a - b) < EPSILON
end

function timeline.create(start_value: number, final_value: number, duration: number): Timeline
	return setmetatable({
		current_value = start_value,
		start_value = start_value,
		final_value = final_value,
		duration = duration,
		direction = "forward",
		is_playing = false,
		is_finished = false,
		comp_lerper = lerper.create(start_value, final_value, duration, nil),
		step = Signal.new(),
		finished = Signal.new(),
		_step_connection = nil :: RBXScriptConnection? -- fuck you
	}, timeline)
end

function timeline._finish(self: Timeline): ()
	if self._step_connection then -- fucking typechecker.
		self._step_connection:Disconnect()
	end
	self.is_playing = false
	self.is_finished = true
	self.finished:Fire()
end

function timeline._start_transition(
	self: Timeline,
	start_value: number,
	end_value: number,
	duration: number,
	direction: "forward" | "reverse"
)
	if self.is_playing and self.direction == direction then
		return
	end

	if self.is_finished and self.direction == direction then
		return
	end

	if self._step_connection then
		self._step_connection:Disconnect()
	end

	self.direction = direction
	self.is_playing = true
	self.is_finished = false

	self.comp_lerper = lerper.create(start_value, end_value, duration)

	self._step_connection = RunService.Heartbeat:Connect(function(delta)
		lerper.step(self.comp_lerper, delta)
		self.current_value = self.comp_lerper.cur_value
		self.step:Fire()

		-- FUTURE: Remove all of this shit altogether when
		-- luau type solver isnt being a piece of shit.
		local is_reverse = self.direction == "reverse"
		local is_reverse_equal = are_equal(self.current_value, self.start_value)

		if self.direction == "forward" and are_equal(self.current_value, self.final_value) then
			self:_finish()
			return
		elseif is_reverse and is_reverse_equal then
			self:_finish()
		end
	end)
end

function timeline.play(self: Timeline)
	local elapsed = self.comp_lerper.elapsed
	self:_start_transition(self.current_value, self.final_value, self.duration - elapsed, "forward")
end

function timeline.play_from_start(self: Timeline)
	self:_start_transition(self.start_value, self.final_value, self.duration, "forward")
end

function timeline.reverse(self: Timeline)
	local elapsed = self.comp_lerper.elapsed
	self:_start_transition(self.current_value, self.start_value, elapsed, "reverse")
end

function timeline.reverse_from_end(self: Timeline)
	self:_start_transition(self.final_value, self.start_value, self.duration, "reverse")
end

return timeline :: { create: (start_value: number, final_value: number, duration: number) -> Timeline }