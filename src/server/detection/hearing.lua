--!strict

export type HearingComp = {
	hearing_listener_pos: Vector3,
	hearing_radius: number,
	hearing_plrs_to_check: { [Player]: true }
}

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
	local root_part = player.Character.PrimaryPart :: BasePart
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
	return humanoid:GetMoveVelocity().Magnitude > 0
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