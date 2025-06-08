--!strict
local Players = game:GetService("Players")

local Signal = require("../../shared/thirdparty/Signal")
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

	return setmetatable({
		agent = agent,
		inside_range = inside_range,
		outside_range = outside_range,
		must_see = must_see,
		see_method = sensor.default_see_method,
		filter_method = sensor.default_filter_method,
		plrs_in_inside_range = {},

		on_inside_range = Signal.new(),
		on_outside_range = Signal.new()
	}, sensor)
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
				passes_sight = self.see_method(self, plr)
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

function sensor.default_filter_method(self: TargetNearbySensor, player: Player): boolean
	-- for simplicity, check if a player is moving if their velocity magnitude is above zero.
	-- of course, this wont check if a player actually moves physically.
	local humanoid = ((player.Character :: Model):FindFirstChild("Humanoid") :: Humanoid) -- istg.
	local velocity = humanoid:GetMoveVelocity().Magnitude > 0
	if not velocity then
		return false
	end
	return true
end

function sensor.default_see_method(self: TargetNearbySensor, player: Player): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {self.agent.character} :: {Instance}

	-- magic.
	return (function()
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
	end)()
end

return sensor