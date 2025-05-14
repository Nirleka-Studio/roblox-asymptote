
-- sus.

type LerpObject = {
	cur_value: number,
	fnl_value: number,
	dur: number,
	elapsed: number,
	p_x: number
}

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

local current_suspicion = 0
local max_suspicion = 1

local suspicion_lerp = nil
local suspicion_state = "idle" -- "rising", "lowering"

local math = math
local workspace = workspace

export type SightConfig = {
	sight_radius: number,				-- maximum distance npc can see
	peripheral_vision_angle: number,	-- how wide the npc can see
	min_glass_trans: number,			-- minimum parts' transparency for npc to see through,
	angle_deg: number,
	num_rays: number
}

export type SightComp = {
	npc_head: BasePart,
	sight_config: SightConfig,
	sight_ray_params: RaycastParams,
	sight_plrs_to_check: { [Player]: true }
}

local sight = {}

local function create_ray_params(npc_head: Instance): RaycastParams
	local ray_params = RaycastParams.new()
	ray_params.FilterDescendantsInstances = { npc_head.Parent } :: { Instance } -- exclude NPC
	ray_params.FilterType = Enum.RaycastFilterType.Exclude
	ray_params.IgnoreWater = true
	return ray_params
end

local function validate_character(player: Player): boolean
	local player_character = player.Character
	if not player_character then
		return false
	end

	local player_root_part = player_character:FindFirstChild("HumanoidRootPart") :: Part?
	if not player_root_part then
		return false
	end

	return true
end

local function is_point_in_radius(point: Vector3, origin: Vector3, radius: number): boolean
	local diff = point - origin
	local dist = diff.Magnitude

	if dist > radius then
		return false
	end

	return true
end

local function is_point_in_angle(point: Vector3, origin: Vector3, forward: Vector3, vision_angle: number)
	local diff = (point - origin)
	local dot = forward:Dot(diff.Unit)

	local cos_half_angle = math.cos(math.rad(vision_angle / 2))
	if dot < cos_half_angle then
		return false
	end

	return true
end

local function sweep_ray(comp: SightComp, player: Player, angle_deg: number, num_rays: number): boolean
	if not validate_character(player) then
		return false
	end

	local npc_head = comp.npc_head

	local char = player.Character :: Model
	local plr_root_part = char:FindFirstChild("HumanoidRootPart") :: Part
	local direction = (plr_root_part.Position - npc_head.Position).Unit

	local axis = Vector3.new(0, 1, 0)

	local half_angle = math.rad(angle_deg / 2)
	local step = (num_rays > 1) and (angle_deg / (num_rays - 1)) or 0
	local step_rad = math.rad(step)

	for i = 0, num_rays - 1 do
		local angle = -half_angle + i * step_rad
		local rotated = CFrame.fromAxisAngle(axis, angle) * direction

		local result = sight.cast_ray(comp, rotated * comp.sight_config.sight_radius)

		if result and result.Instance:IsDescendantOf(player.Character :: Model) then
			return true -- early return
		end
	end

	return false
end

function sight.create_comp(npc_head: BasePart, config: SightConfig): SightComp
	return {
		npc_head = npc_head,
		sight_config = config,
		sight_ray_params = create_ray_params(npc_head),
		sight_plrs_to_check = {}
	} :: SightComp
end

local cur_plr = nil

function sight.proccess(comp: SightComp)
	-- check if its empty
	if next(comp.sight_plrs_to_check) == nil then
		return
	end

	for plr in comp.sight_plrs_to_check do
		if not sight.is_player_within_sight_bounds(comp, plr) then
			continue
		end

		if not sweep_ray(
			comp,
			plr,
			comp.sight_config.angle_deg,
			comp.sight_config.num_rays
			) then
			continue
		end

		--warn("Eyeing on ", plr)
		cur_plr = plr
		return cur_plr
	end
end

function sight.cast_ray(comp: SightComp, direction: Vector3): RaycastResult?
	local dir_magnitude = direction.Magnitude
	if dir_magnitude == 0 then return nil end -- pretty rare, but itll fuck us royally if it does happen.

	local unit_dir = direction.Unit
	local cur_origin = comp.npc_head.Position
	local remaining_distance = dir_magnitude
	local final_result: RaycastResult? = nil

	-- ignore transparent parts and pass through.
	-- this shit may be a problem if we wanna be *EXTRA* realistic by automatically handling
	-- stacked tinted parts, but eh.
	while remaining_distance > 0 do
		local ray_vector = unit_dir * remaining_distance
		local result = workspace:Raycast(cur_origin, ray_vector, comp.sight_ray_params)
		if not result then
			break -- full path is clear
		end

		local part = result.Instance :: BasePart
		if part.Transparency >= comp.sight_config.min_glass_trans then
			-- transparent enough to pass through
			comp.sight_ray_params:AddToFilter(part)

			-- slight offset forward to avoid re-hitting the same surface.
			-- as a reminder that my pc freezes without this.
			cur_origin = result.Position + unit_dir * 0.01
			remaining_distance -= (result.Position - cur_origin).Magnitude
		else
			-- opaque enough to block
			final_result = result
			break
		end
	end

	return final_result
end

function sight.is_player_within_sight_bounds(sight_comp: SightComp, player: Player): boolean
	if not validate_character(player) then
		return false
	end

	-- for the sake of the goddamn strict type checker
	local char = player.Character :: Model
	local plr_root_part = char:FindFirstChild("HumanoidRootPart") :: Part
	local pos_plr_root = plr_root_part.Position
	local pos_npc_head = sight_comp.npc_head.Position

	if not is_point_in_radius(
		pos_plr_root,
		pos_npc_head,
		sight_comp.sight_config.sight_radius
		) then
		return false
	end

	if not is_point_in_angle(
		pos_plr_root,
		pos_npc_head,
		sight_comp.npc_head.CFrame.LookVector,
		sight_comp.sight_config.peripheral_vision_angle
		) then
		return false
	end

	return true
end

local sight_config = {} :: SightConfig
sight_config.sight_radius = 30
sight_config.peripheral_vision_angle = 120
sight_config.min_glass_trans = 0.4
sight_config.num_rays = 5
sight_config.angle_deg = 10
local new_comp: SightComp = sight.create_comp(workspace.Rig.Head, sight_config)

local function is_player_visible()
	if sight.proccess(new_comp) then
		return true
	end

	return false
end

game:GetService("Players").PlayerAdded:Connect(function(plr)
	new_comp.sight_plrs_to_check[plr] = true
end)

game:GetService("RunService").Heartbeat:Connect(function(delta)
	local player_visible = is_player_visible()

	if player_visible and suspicion_state ~= "rising" then
		suspicion_lerp = lerper.create(current_suspicion, max_suspicion, 3.0, 2.0)
		suspicion_state = "rising"

	elseif not player_visible and suspicion_state ~= "lowering" then
		suspicion_lerp = lerper.create(current_suspicion, 0.0, 5.0, 1.5)
		suspicion_state = "lowering"
	end

	if suspicion_lerp then
		lerper.step(suspicion_lerp, delta, function(val)
			current_suspicion = val
			current_suspicion = math.clamp(current_suspicion, 0.0, max_suspicion)

			if math.abs(current_suspicion - suspicion_lerp.fnl_value) < 0.01 then
				current_suspicion = suspicion_lerp.fnl_value
				suspicion_state = "idle"
			end
		end)
	end

	print(current_suspicion)

	if cur_plr then
		game.ReplicatedStorage.Detection:FireClient(cur_plr, workspace.Rig, current_suspicion, 1)
	end

	if current_suspicion >= max_suspicion then
		warn("ALERT: player fully spotted.")
	end
end)
