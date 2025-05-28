--!strict

local EPSILON = 0.001
local Hearing_Players_Last_Pos: { [Player]: Vector3 } = {}

export type HearingComp = {
	hearing_listener_pos: Vector3,
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

function hearing.create(listener_pos: Vector3, hearing_radius: number): HearingComp
	return {
		hearing_listener_pos = listener_pos,
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

	local distance = (self.hearing_listener_pos - root_part.Position).Magnitude
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

	print("velocity: player velocity above")

	if not Hearing_Players_Last_Pos[player] then
		print("not present, setting, returning true")
		Hearing_Players_Last_Pos[player] = player.Character.HumanoidRootPart.Position
		return true
	end

	if vectors_are_equal(player.Character.HumanoidRootPart.Position :: Vector3, Hearing_Players_Last_Pos[player]) then
		print("player is not actually moving.")
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

	return true
end

return hearing