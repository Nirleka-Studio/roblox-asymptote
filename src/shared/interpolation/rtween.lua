-- rtween.lua
-- NirlekaDev
-- April 27, 2025

--!strict

local TweenService = game:GetService("TweenService")
local array = require("../standard/array")

--[=[
	@class rtween

	The R stands for Roblox. It is a wrapper around TweenService,
	so it can be implemented in a way similar to Godot's Tween.
	Unlike the `src/modules/animation/tween` which uses an entirely custom
	implemention for tweening.

	Due to being part of the Dasar Standard Library, RTween will take the
	functional programming approach. Standing on the philosphy that everything
	must be explicit.
]=]
local rtween = {}

export type RTween = {
	tweens: array.Array<Tween>,
	stack: array.Array<array.Array<Tween>>,
	connections: array.Array<RBXScriptConnection>,
	easing_style: Enum.EasingStyle,
	easing_direction: Enum.EasingDirection,
	parallel_enabled: boolean,
	default_parallel: boolean,
	is_playing: boolean,
	is_paused: boolean,
	current_step: number
}

export type PropertyParam = {
	[ string ] : any
}

local function append_tweens(rtween_inst: RTween, tweens_arr: array.Array<Tween>)
	local stack = rtween_inst.stack
	local tweens = rtween_inst.tweens
	local current_step_index = 0

	local stack_size = array.size(stack)
	if rtween_inst.parallel_enabled then
		current_step_index = math.max(1, stack_size)
	else
		current_step_index = stack_size + 1
	end

	rtween_inst.parallel_enabled = rtween_inst.default_parallel

	if not array.get(stack, current_step_index) then
		array.push_back(stack, array.create())
	end

	local current_step = array.get(stack, current_step_index)

	for _, tween in array.iter(tweens_arr) do
		array.push_back(current_step, tween)
		array.push_back(tweens, tween)
	end
end

local function play_step(rtween_inst: RTween, step_index: number)
	if step_index > array.size(rtween_inst.stack) then
		-- all steps completed
		rtween_inst.current_step = 1
		rtween_inst.is_playing = false
		return
	end

	rtween_inst.current_step = step_index
	rtween_inst.is_playing = true

	local step = array.get(rtween_inst.stack, step_index)
	local step_size = array.size(step)
	local completed_tweens = 0

	for _, tween in array.iter(step) do
		tween:Play()

		local connection
		connection = tween.Completed:Once(function()
			completed_tweens += 1
			if completed_tweens == step_size then
				-- all tweens in this step are done
				if connection then
					local connection = connection :: RBXScriptConnection -- ANOTHER BLOCKED BUG AGAIN!!!!!!!
					connection:Disconnect()
				end

				play_step(rtween_inst, step_index + 1) -- move to next step
			end
		end)

		array.push_back(rtween_inst.connections, connection)
	end
end

function rtween.create(
	easing_style: Enum.EasingStyle,
	easing_direction: Enum.EasingDirection
): RTween
	local new_rtween: RTween = {
		tweens = array.create() :: array.Array<Tween>, -- these will make the type checker stfu
		stack = array.create() :: array.Array<array.Array<Tween>>,
		connections = array.create() :: array.Array<RBXScriptConnection>,
		easing_style = easing_style or Enum.EasingStyle.Linear,
		easing_direction = easing_direction or Enum.EasingDirection.InOut,
		parallel_enabled = false,
		default_parallel = false,
		is_playing = false,
		is_paused = false,
		current_step = 1
	}

	return new_rtween
end

function rtween.play(rtween_inst: RTween)

	-- I should probably tell you how the Stack works.
	-- The Stack holds references to the tweens table,
	-- The Stack contains 'steps' which itself contains the actual tweens.
	-- In each step, all tweens inside will play at the same time.
	-- In order to advance to the next step, all tweens in the current step
	-- has to be completed.

	-- this is meant to fix the "cannot convert true to false" bullshit.
	-- yes. this is apprently a bug:
	-- https://devforum.roblox.com/t/type-true-could-not-be-converted-into-false/3553568/3?u=nirlekaplay
	-- how retarded.
	local is_playing: boolean = rtween_inst.is_playing

	if is_playing and not rtween_inst.is_paused then
		return
	end

	local connections = rtween_inst.connections

	for k, connection in array.iter(connections) do
		connection:Disconnect()
		array.set(connections, k, nil)
	end

	rtween_inst.is_paused = false -- YEAH, TAKE THAT

	play_step(rtween_inst, rtween_inst.is_paused and rtween_inst.current_step or 1)
end

function rtween.kill(rtween_inst: RTween)
	for k, tween in array.iter(rtween_inst.tweens) do
		tween:Cancel()
		tween:Destroy()
		array.set(rtween_inst.tweens, k, nil)
	end

	for k, step in array.iter(rtween_inst.stack) do
		for j, _ in array.iter(step) do
			array.set(step, j , nil)
		end
		array.set(rtween_inst.stack, k, nil)
	end

	for k, connection: RBXScriptConnection in array.iter(rtween_inst.connections) do
		connection:Disconnect()
		array.set(rtween_inst.connections, k, nil)
	end

	rtween_inst.current_step = 1
	rtween_inst.is_playing = false
	rtween_inst.is_paused = false
end

function rtween.parallel(rtween_inst: RTween)
	rtween_inst.parallel_enabled = true
end

function rtween.pause(rtween_inst: RTween)
	rtween_inst.is_paused = true

	local tweens = rtween_inst.tweens
	for k, tween in array.iter(tweens) do
		tween:Pause()
	end
end

function rtween.set_parallel(rtween_inst: RTween, parallel: boolean)
	rtween_inst.default_parallel = true
	rtween_inst.parallel_enabled = true
end

function rtween.tween_instance(
	rtween_inst: RTween,
	inst: Instance,
	properties: PropertyParam,
	dur: number,
	delay: number?,
	easing_style: Enum.EasingStyle?,
	easing_direction: Enum.EasingDirection?
)
	local tween_info = TweenInfo.new(
		dur,
		easing_style or rtween_inst.easing_style,
		easing_direction or rtween_inst.easing_direction,
		0,
		false,
		delay or 0
	)
	local tweens_arr = array.create() :: array.Array<Tween>

	for prop_name, prop_fnl_val in pairs(properties) do
		local tween_inst = TweenService:Create(
			inst,
			tween_info,
			{ [prop_name] = prop_fnl_val }
		)

		array.push_back(tweens_arr, tween_inst)
	end

	append_tweens(rtween_inst, tweens_arr)
end

return rtween