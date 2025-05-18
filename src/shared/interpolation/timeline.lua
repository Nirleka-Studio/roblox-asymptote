--!strict

local RunService = game:GetService("RunService")
local Signal = require("../../shared/thirdparty/Signal")
local lerper = require("./lerper")

local timeline = {}
timeline.__index = timeline

type Signal = Signal.Signal

type TimelineData = {
	duration: number,
	comp_lerper: lerper.LerpObject,
	current_value: number,
	start_value: number,
	final_value: number,
	direction: "forward" | "reverse",
	playing: boolean,

	step: Signal,
	finished: Signal,
	_step_connection: RBXScriptConnection?
}

export type Timeline = typeof(setmetatable({} :: TimelineData, timeline))

function timeline.create(start_value: number, final_value: number, duration: number): Timeline
	return setmetatable({
		current_value = start_value,
		start_value = start_value,
		final_value = final_value,
		duration = duration,
		direction = "forward",
		playing = false,
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
	self.playing = false
	self.finished:Fire()
end

function timeline._start_transition(
	self: Timeline,
	start_value: number,
	end_value: number,
	duration: number,
	direction: "forward" | "reverse"
)
	if self.playing and self.direction == direction then
		return
	end

	if self._step_connection then
		self._step_connection:Disconnect()
	end

	self.direction = direction

	self.comp_lerper = lerper.create(start_value, end_value, duration)

	self._step_connection = RunService.Heartbeat:Connect(function(delta)
		lerper.step(self.comp_lerper, delta)
		self.current_value = self.comp_lerper.cur_value
		self.step:Fire()

		if self.direction == "forward" and (self.current_value == self.final_value) then
			self:_finish()
			return
		end

		-- another goddamn type checker blocked bug again.
		-- luau. wtf.
		if self.direction == "reverse" and (self.current_value == self.final_value) then
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