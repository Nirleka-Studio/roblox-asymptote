--!strict

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

function sight.create_comp(npc_head: BasePart, config: SightConfig): SightComp
	return {
		npc_head = npc_head,
		sight_config = config,
		sight_ray_params = create_ray_params(npc_head),
		sight_plrs_to_check = {},
		sight_plrs_in_view = {}
	} :: SightComp
end

function sight.is_point_in_radius(point: Vector3, origin: Vector3, radius: number): boolean
	local diff = point - origin
	local dist = diff.Magnitude

	if dist > radius then
		return false
	end

	return true
end

function sight.is_point_in_angle(point: Vector3, origin: Vector3, forward: Vector3, vision_angle: number)
	local diff = (point - origin)
	local dot = forward:Dot(diff.Unit)

	local cos_half_angle = math.cos(math.rad(vision_angle / 2))
	if dot < cos_half_angle then
		return false
	end

	return true
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

	if not sight.is_point_in_radius(
		pos_plr_root,
		pos_npc_head,
		sight_comp.sight_config.sight_radius
	) then
		return false
	end

	if not sight.is_point_in_angle(
		pos_plr_root,
		pos_npc_head,
		sight_comp.npc_head.CFrame.LookVector,
		sight_comp.sight_config.peripheral_vision_angle
	) then
		return false
	end

	return true
end

function sight.ray_sweep(comp: SightComp, player: Player, angle_deg: number, num_rays: number): boolean
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

		local result = sight.ray_cast(comp, rotated * comp.sight_config.sight_radius)

		if result and result.Instance:IsDescendantOf(player.Character :: Model) then
			return true -- early return
		end
	end

	return false
end

function sight.ray_cast(comp: SightComp, direction: Vector3): RaycastResult?
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

function sight.is_player_visible(sight_comp: SightComp, player: Player): boolean
	if not sight.is_player_within_sight_bounds(sight_comp, player) then
		return false
	end

	if not sight.ray_sweep(
		sight_comp,
		player,
		sight_comp.sight_config.angle_deg,
		sight_comp.sight_config.num_rays
	) then
		return false
	end

	return true
end

return sight