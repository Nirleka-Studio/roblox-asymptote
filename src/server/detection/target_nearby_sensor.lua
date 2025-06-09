--!strict
local Players = game:GetService("Players")

local Signal = require(game.ReplicatedStorage.shared.thirdparty.Signal)
local agent = require("../character/agent")
local character_utils = require("../character/character_utils")

local sensor = {}
sensor.__index = sensor

export type TargetNearbySensor = typeof(setmetatable({} :: {
	agent: agent.Agent,
	inside_range: number,
	outside_range: number,
	must_see: boolean,
	see_method: ((TargetNearbySensor, Player) -> boolean),
	filter_method: ((TargetNearbySensor, Player) -> boolean),
	plrs_in_inside_range: { [Player] : true },

	on_inside_range: Signal.Signal<Player>,
	on_outside_range: Signal.Signal<Player>
}, sensor))

function sensor.create(
	agent: agent.Agent,
	inside_range: number,
	outside_range: number,
	must_see: boolean
): TargetNearbySensor

	local self = {
		agent = agent,
		inside_range = inside_range,
		outside_range = outside_range,
		must_see = must_see,
		see_method = sensor.default_see_method(agent.character),
		filter_method = sensor.default_filter_method,
		plrs_in_inside_range = {},

		on_inside_range = Signal.new(),
		on_outside_range = Signal.new()
	}

	return setmetatable(self, sensor)
end

function sensor.update(self: TargetNearbySensor): ()
	local players = Players:GetPlayers()
	local cur_plrs_in_range: { [Player] : true } = {}

	for _, plr in ipairs(players) do
		local root_part = character_utils.get_plr_root_part(plr)
		if not root_part then continue end
	
		local distance = (root_part.Position - self.agent.primary_part.Position).Magnitude
		if distance < self.inside_range then
			-- if must_see is true, see_method must pass
			local passes_sight = true
			if self.must_see then
				local shit = self :: any -- TODO: remove this shit when the luau devs evantually fix this issue.
				passes_sight = self.see_method(shit, plr)
			end

			if passes_sight and self.filter_method(self, plr) then
				cur_plrs_in_range[plr] = true
			end
		end
	end	

	local prev_plrs = self.plrs_in_inside_range
	self.plrs_in_inside_range = {}

	for player in pairs(prev_plrs) do
		if not cur_plrs_in_range[player] then
			self.on_outside_range:Fire(player)
		end
	end

	for player in pairs(cur_plrs_in_range) do
		self.plrs_in_inside_range[player] = true
		if not prev_plrs[player] then
			self.on_inside_range:Fire(player)
		end
	end
end

local MOVEMENT_THRESHOLD = 0.1
local players_last_pos: { [Player]: Vector3 } = {}
function sensor.default_filter_method(self: TargetNearbySensor, player: Player): boolean
	local root_part = character_utils.get_plr_root_part(player)
	if not root_part then
		return false
	end
	local current_pos = root_part.Position
	local humanoid = ((player.Character :: Model):FindFirstChild("Humanoid") :: Humanoid) -- istg.
	local velocity = humanoid:GetMoveVelocity().Magnitude > 0
	
	if not velocity then
		return false
	end

	local last_pos = players_last_pos[player]
	if not last_pos then
		players_last_pos[player] = current_pos
		return false
	end

	local magnitude = (current_pos - last_pos).Magnitude
	if not (magnitude > MOVEMENT_THRESHOLD) then
		return false
	end

	players_last_pos[player] = current_pos

	return true
end

function sensor.default_see_method(character: Model): (self: TargetNearbySensor, player: Player) -> boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character} :: {Instance}

	-- magic.
	return function(self: TargetNearbySensor, player: Player)
		local agent_head_pos = self.agent.head.Position
		-- no need to check shit cuz this function wont get called if player doesnt have a character or
		-- root part anyway.
		local plr_character = player.Character :: Model
		local root_part = plr_character:FindFirstChild("HumanoidRootPart") :: Part
		local root_part_pos = root_part.Position :: Vector3

		local ray_result = workspace:Raycast(
			self.agent.head.Position,
			(root_part_pos:: Vector3 - agent_head_pos).Unit * self.inside_range,
			params
		)

		if not ray_result or not ray_result.Instance:IsDescendantOf(plr_character :: Model) then
			return false
		end

		return true
	end
end

return sensor