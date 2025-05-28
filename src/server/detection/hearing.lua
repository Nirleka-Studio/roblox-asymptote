--!strict
local Debris = game:GetService("Debris")

local Draw = require(game.ReplicatedStorage.shared.thirdparty.Draw)

local EPSILON = 0.001
local Hearing_Players_Last_Pos: { [Player]: Vector3 } = {}

export type HearingComp = {
	agent: {
		character: Model,
		head: BasePart
	},
	hearing_radius: number,
	hearing_plrs_to_check: { [Player]: true }
}

local function are_equal(a: number, b: number): boolean
	return math.abs(a - b) < EPSILON
end

local function vectors_are_equal(v1: Vector3, v2: Vector3): boolean
	return are_equal(v1.X, v2.X) and are_equal(v1.Y, v2.Y) and are_equal(v1.Z, v2.Z)
end


local hearing = {}

function hearing.create(agent: {
	character: Model,
	head: BasePart,
}, hearing_radius: number): HearingComp
	return {
		agent = agent,
		hearing_radius = hearing_radius,
		hearing_plrs_to_check = {}
	}
end

function hearing.is_player_in_hearing_radius(self: HearingComp, player: Player): boolean
	-- stupid checks for the sake of the typechecker.
	if not player.Character then
		return false
	end
	local root_part = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not root_part then
		return false
	end

	local distance = (self.agent.head.Position - root_part.Position).Magnitude
	return distance <= self.hearing_radius
end

function hearing.is_player_moving(player: Player): boolean
	if not player.Character or not player.Character.PrimaryPart then
		return false
	end

	local humanoid = player.Character.Humanoid :: Humanoid -- istg.
	local velocity = humanoid:GetMoveVelocity().Magnitude > 0
	if not velocity then
		return false
	end

	if not Hearing_Players_Last_Pos[player] then
		Hearing_Players_Last_Pos[player] = player.Character.HumanoidRootPart.Position
		return true
	end

	if vectors_are_equal(player.Character.HumanoidRootPart.Position :: Vector3, Hearing_Players_Last_Pos[player]) then
		return false
	end

	Hearing_Players_Last_Pos[player] = player.Character.HumanoidRootPart.Position

	return true
end

function hearing.is_player_hearable(self: HearingComp, player: Player): boolean
	if not hearing.is_player_in_hearing_radius(self, player) then
		return false
	end

	if not hearing.is_player_moving(player) then
		return false
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {self.agent.character}
	local ray_result = workspace:Raycast(
		self.agent.head.Position,
		(player.Character.HumanoidRootPart.Position :: Vector3 - self.agent.head.Position).Unit * self.hearing_radius,
		params
	)

	if ray_result then
		Debris:AddItem(Draw.line(self.agent.head.Position, ray_result.Position), 0.1)
	end

	if not ray_result or ray_result.Instance ~= player.Character.HumanoidRootPart then
		return false
	end

	return true
end

return hearing