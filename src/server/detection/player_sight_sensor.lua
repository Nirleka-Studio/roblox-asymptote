--!strict

local Players = game:GetService("Players")
local agent = require("../character/agent")
local Signal = require(game.ReplicatedStorage.shared.thirdparty.Signal)
local CharUtils = require(game.ServerScriptService.server.character.character_utils)

local sensor = {}
sensor.__index = sensor

type Agent = agent.Agent

export type PlayerSightSensor = typeof(setmetatable({} :: {
	agent: Agent,
	ray_caster: (self: PlayerSightSensor, direction: Vector3) -> RaycastResult?,
	ray_strategy: (self: PlayerSightSensor, player: Player) -> boolean,
	ray_params: RaycastParams,
	sight_radius: number,
	sight_periph_angle: number,
	plrs_in_vision: {[Player] : true},

	on_inside_vision: Signal.Signal<Player>,
	on_outside_vision: Signal.Signal<Player>
}, sensor))

local function create_ray_params(agent: Agent): RaycastParams
	local ray_params = RaycastParams.new()
	ray_params.FilterDescendantsInstances = { agent.character } :: { Instance } -- exclude NPC
	ray_params.FilterType = Enum.RaycastFilterType.Exclude
	ray_params.IgnoreWater = true
	return ray_params
end

function sensor.create(agent: Agent, sight_radius: number, periph_angle: number): PlayerSightSensor
	return setmetatable({
		agent = agent,
		ray_caster = sensor.ray_cast_glass,
		ray_strategy = sensor.ray_sweep,
		ray_params = create_ray_params(agent),
		sight_radius = sight_radius,
		sight_periph_angle = periph_angle,
		plrs_in_vision = {},
		on_inside_vision = Signal.new(),
		on_outside_vision = Signal.new()
	}, sensor)
end

function sensor.update(self: PlayerSightSensor): ()
	-- oh. roblox already have a GetPlayers function? neat.
	local players = Players:GetPlayers()
	local current_visible_plrs: {[Player]: true} = {}

	for _, player in ipairs(players) do
		if self:is_in_vision(player) then
			current_visible_plrs[player] = true -- hash sets, as it's faster
		end
	end

	local prev_visible = self.plrs_in_vision
	self.plrs_in_vision = {} -- reset it now

	for player in pairs(prev_visible) do
		if not current_visible_plrs[player] then
			self.on_outside_vision:Fire(player)
		end
	end

	for player in pairs(current_visible_plrs) do
		self.plrs_in_vision[player] = true
		if not prev_visible[player] then
			self.on_inside_vision:Fire(player)
		end
	end
end

function sensor.is_in_vision(self: PlayerSightSensor, player: Player): boolean
	local plr_root_part = CharUtils.get_plr_root_part(player)
	if not plr_root_part then
		return false
	end

	local diff = plr_root_part.Position - self.agent.primary_part.Position
	local dist = diff.Magnitude

	if dist > self.sight_radius then
		return false
	end

	local dot = self.agent.head.CFrame.LookVector:Dot(diff.Unit)

	local cos_half_angle = math.cos(math.rad(self.sight_periph_angle / 2))
	if dot < cos_half_angle then
		return false
	end

	if not self:ray_strategy(player) then
		return false
	end

	return true
end

function sensor.ray_cast_glass(self: PlayerSightSensor, direction: Vector3): RaycastResult?
	local dir_magnitude = direction.Magnitude
	if dir_magnitude == 0 then return nil end -- pretty rare, but itll fuck us royally if it does happen.

	local unit_dir = direction.Unit
	local cur_origin = self.agent.head.Position
	local remaining_distance = dir_magnitude
	local final_result: RaycastResult? = nil

	-- ignore transparent parts and pass through.
	-- this shit may be a problem if we wanna be *EXTRA* realistic by automatically handling
	-- stacked tinted parts, but eh.
	while remaining_distance > 0 do
		local ray_vector = unit_dir * remaining_distance
		local result = workspace:Raycast(cur_origin, ray_vector, self.ray_params)
		if not result then
			break -- full path is clear
		end

		local part = result.Instance :: BasePart
		if part.Transparency >= 0.5 then
			-- transparent enough to pass through
			self.ray_params:AddToFilter(part)

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

function sensor.ray_sweep(self: PlayerSightSensor, player: Player): boolean
	local plr_root_part = CharUtils.get_plr_root_part(player)
	if not plr_root_part then
		return false
	end
	local angle_deg = 10
	local num_rays = 5
	local direction = (plr_root_part.Position - self.agent.head.Position).Unit

	local axis = Vector3.new(0, 1, 0)

	local half_angle = math.rad(angle_deg / 2)
	local step = (num_rays > 1) and (angle_deg / (num_rays - 1)) or 0
	local step_rad = math.rad(step)

	for i = 0, num_rays - 1 do
		local angle = -half_angle + i * step_rad
		local rotated = CFrame.fromAxisAngle(axis, angle) * direction

		local result = self.ray_caster(self, rotated * self.sight_radius)

		if result and result.Instance:IsDescendantOf(player.Character :: Model) then
			return true -- early return
		end
	end

	return false
end

return sensor :: typeof(sensor)