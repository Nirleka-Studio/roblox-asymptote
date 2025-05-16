--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local sight = require("../../src/server/detection/sight")

export type Npc = {
	character: Model
}

type LerpObject = {
	cur_value: number,
	fnl_value: number,
	dur: number,
	elapsed: number,
	p_x: number
}

local npc = {}

-- keep this here for now.
-- i dont want to get to dependency hell.
local lerper = {} do
	local function ease(p_x: number, p_c: number): number
		if p_x < 0 then
			p_x = 0
		elseif (p_x > 1.0) then
			p_x = 1.0
		end
		if p_c > 0 then
			if (p_c < 1.0) then
				return 1.0 - math.pow(1.0 - p_x, 1.0 / p_c);
			else
				return math.pow(p_x, p_c);
			end
		elseif (p_c < 0) then
			if p_x < 0.5 then
				return math.pow(p_x * 2.0, -p_c) * 0.5;
			else
				return (1.0 - math.pow(1.0 - (p_x - 0.5) * 2.0, -p_c)) * 0.5 + 0.5;
			end
		else
			return 0
		end
	end

	function lerper.create(start_value: number, final_value: number, dur: number, p_x: number): LerpObject
		return {
			cur_value = start_value,
			fnl_value = final_value,
			dur = dur,
			elapsed = 0,
			p_x = p_x
		} :: LerpObject
	end

	function lerper.step(obj: LerpObject, delta: number, step_func: (cur_value: number) -> ()?)
		if obj.cur_value == obj.fnl_value then
			return
		end

		obj.elapsed += delta

		local c = math.clamp(obj.elapsed / obj.dur, 0.0, 1.0)
		c = ease(c, obj.p_x)
		obj.cur_value = math.lerp(obj.cur_value, obj.fnl_value, c) -- omg the luau team added math.lerp???? since when????

		if step_func then
			step_func(obj.cur_value)
		end
	end
end

function npc.create(character: Model): Npc
	local new_config: sight.SightConfig = {
		sight_radius = 50,
		peripheral_vision_angle = 90,
		min_glass_trans = 0.5,
		angle_deg = 10,
		num_rays = 5
	}
	local new_npc = {}

	new_npc.suspicion = 0
	new_npc.suspicion_priority_plr = nil :: Player?
	new_npc._comp_suspicion = {
		state = "idle" :: "idle" | "rising" | "lowering",
		comp_lerp = nil :: LerpObject?
	}
	new_npc.character = character
	new_npc._comp_sight = sight.create_comp(character:FindFirstChild("Head") :: BasePart, new_config)
	new_npc._process = function(delta: number)
		if next(new_npc._comp_sight.sight_plrs_to_check) == nil then
			new_npc.suspicion_priority_plr = nil
		end

		for plr in pairs(new_npc._comp_sight.sight_plrs_to_check) do
			local visible = sight.is_player_visible(new_npc._comp_sight, plr)

			if visible then
				new_npc.suspicion_priority_plr = plr

				-- Only create lerp if target is different
				if not new_npc._comp_suspicion.comp_lerp or new_npc._comp_suspicion.comp_lerp.fnl_value ~= 1.0 then
					new_npc._comp_suspicion.comp_lerp = lerper.create(new_npc.suspicion, 1.0, 3.0, 2.0)
					new_npc._comp_suspicion.state = "rising"
				end
			else
				-- not visible
				new_npc.suspicion_priority_plr = nil

				if not new_npc._comp_suspicion.comp_lerp or new_npc._comp_suspicion.comp_lerp.fnl_value ~= 0.0 then
					new_npc._comp_suspicion.comp_lerp = lerper.create(new_npc.suspicion, 0.0, 5.0, 1.5)
					new_npc._comp_suspicion.state = "lowering"
				end
			end
		end

		-- Process lerp
		local lerp = new_npc._comp_suspicion.comp_lerp
		if lerp then
			lerper.step(lerp, delta, function(val)
				new_npc.suspicion = math.clamp(val, 0.0, 1.0)

				if math.abs(new_npc.suspicion - lerp.fnl_value) < 0.01 then
					new_npc.suspicion = lerp.fnl_value
					new_npc._comp_suspicion.state = "idle"
					new_npc._comp_suspicion.comp_lerp = nil
				end
			end)
		end

		print(new_npc.suspicion)
	end

	Players.PlayerAdded:Connect(function(plr)
		new_npc._comp_sight.sight_plrs_to_check[plr] = true
	end)
	Players.PlayerRemoving:Connect(function(plr)
		new_npc._comp_sight.sight_plrs_to_check[plr] = nil
	end)
	RunService.Heartbeat:Connect(new_npc._process)

	return new_npc
end

npc.create(workspace.Rig)