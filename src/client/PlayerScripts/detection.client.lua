--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local world_pointer = require(Players.LocalPlayer.PlayerScripts.client.modules.gui.world_pointer)
local rtween = require(ReplicatedStorage.shared.interpolation.rtween)

type MeterObject = {
	comp_pointer: world_pointer.WorldPointer,
	gui_inst: Frame,
	last_sus: number,
	current_rtween: rtween.RTween,
	is_raising: boolean
}

local REMOTE: RemoteEvent = ReplicatedStorage.remotes.Detection
local FRAME_METER_REF = Players.LocalPlayer.PlayerGui:WaitForChild("Detection").SusMeter

local active_meters: { [Model]: MeterObject } = {}

local function clone_meter_frame(): Frame
	local cloned: Frame = FRAME_METER_REF:Clone()
	cloned.Visible = true
	cloned.Parent = script.Parent
	return cloned
end

local function create_meter_object(origin: Vector3): MeterObject
	local new_gui_inst = clone_meter_frame()
	return {
		comp_pointer = world_pointer.create(new_gui_inst, origin),
		gui_inst = new_gui_inst,
		last_sus = 0,
		current_rtween = rtween.create(Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		is_raising = false
	}
end

RunService.RenderStepped:Connect(function()
	for _, meter in pairs(active_meters) do
		world_pointer.update(meter.comp_pointer)
	end
end)

REMOTE.OnClientEvent:Connect(function(sus_value: number, id: Model, origin: Vector3)
	local current_meter = active_meters[id]
	if not current_meter then
		active_meters[id] = create_meter_object(origin)
		current_meter = active_meters[id]
		rtween.set_parallel(current_meter.current_rtween, true)
	end

	current_meter.comp_pointer.target_pos = origin
	current_meter.gui_inst.Frame.CanvasGroup.Size = UDim2.fromScale(sus_value, 1)

	if sus_value > current_meter.last_sus then
		current_meter.gui_inst.Frame.CanvasGroup.A1.ImageColor3 = Color3.new(1, 1, 1)
		current_meter.is_raising = true
	elseif sus_value < current_meter.last_sus then
		current_meter.gui_inst.Frame.CanvasGroup.A1.ImageColor3 = Color3.new(0.509804, 0.509804, 0.509804)
		current_meter.is_raising = false
	end

	local function animate()
		if current_meter.is_raising then
			if not (sus_value < 0.5) then
				return
			end
			local current_rtween: rtween.RTween = current_meter.current_rtween
			if current_rtween.is_playing then
				rtween.kill(current_rtween)
			end
			rtween.tween_instance(current_rtween, current_meter.gui_inst.Frame.CanvasGroup.A1, {ImageTransparency = 0}, .3)
			rtween.tween_instance(current_rtween, current_meter.gui_inst.Frame.A1, {ImageTransparency = 0}, .3)
			rtween.play(current_rtween)
		else
			if not (sus_value < 0.5) then
				return
			end
			local current_rtween: rtween.RTween = current_meter.current_rtween
			if current_rtween.is_playing then
				rtween.kill(current_rtween)
			end
			rtween.tween_instance(current_rtween, current_meter.gui_inst.Frame.CanvasGroup.A1, {ImageTransparency = 1}, .5)
			rtween.tween_instance(current_rtween, current_meter.gui_inst.Frame.A1, {ImageTransparency = 1}, .5)
			rtween.play(current_rtween)
		end
	end
	animate()

	current_meter.last_sus = sus_value
end)