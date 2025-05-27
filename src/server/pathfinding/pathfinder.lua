--!strict

local PathfindingService = game:GetService("PathfindingService")

local pathfinder = {}
pathfinder.__index = pathfinder

export type AgentParameters = {
	AgentRadius: number?,
	AgentHeight: number?,
	AgentCanJump: boolean?,
	AgentCanClimb: boolean?,
	WaypointSpacing: number?,
	Costs: { [any]: any }?
}

export type Pathfinder = typeof(setmetatable({} :: {
	path: Path,
	agent: {
		character: Model,
		humanoid: Humanoid
	},
	waypoints: {PathWaypoint},
	waypoints_current_index: number,
	is_moving: boolean,
	connection_blocked: RBXScriptConnection?,
	connection_reached: RBXScriptConnection?
}, pathfinder))

local DEFAULT_AGENT_PARAMS: AgentParameters = {
	AgentRadius = 5
}

function pathfinder.create(character: Model, humanoid: Humanoid, agent_params: AgentParameters?): Pathfinder
	local self = setmetatable({
		path = PathfindingService:CreatePath(
			agent_params :: { [any]: any }? or
			DEFAULT_AGENT_PARAMS :: { [any]: any }?
		),
		agent = {
			character = character,
			humanoid = humanoid
		},
		waypoints = {},
		waypoints_current_index = 0,
		is_moving = false,
		connection_blocked = nil,
		connection_reached = nil
	}, pathfinder)

	return self :: Pathfinder
end

function pathfinder.compute_path(self: Pathfinder, from: Vector3, to: Vector3): boolean
	local success, err = pcall(function()
		return self.path:ComputeAsync(from, to)
	end)

	if not success or self.path.Status ~= Enum.PathStatus.Success then
		warn("Path not computed!", err)
		return false
	end

	self.waypoints = self.path:GetWaypoints()
	self.waypoints_current_index = 1

	return true
end

function pathfinder.set_destination(self: Pathfinder, to: Vector3): ()
	local is_computed = self:compute_path((self.agent.character.PrimaryPart :: BasePart).Position, to)
	if not is_computed then
		return
	end

	self.connection_blocked = self.path.Blocked:Connect(function(blocked_waypoint_index)
		if blocked_waypoint_index > self.waypoints_current_index then
			self.connection_blocked:Disconnect()
			self:compute_path((self.agent.character.PrimaryPart :: BasePart).Position, to)
		end
	end)

	if not self.connection_reached then -- "TypeError: Type 'RBXScriptConnection' could not be converted into 'nil'" WELL NO SHIT THATS WHY WE'RE GONNA SET IT TO SOMETHING THAT IS NOT NIL. WTF IS WRONG WITH YOU.
		self.connection_reached = self.agent.humanoid.MoveToFinished:Connect(function(reached)
			if reached and self.waypoints_current_index < #self.waypoints then
				self.waypoints_current_index += 1
				self.agent.humanoid:MoveTo(self.waypoints[self.waypoints_current_index].Position)
			else
				self.connection_reached:Disconnect()
				self.connection_blocked:Disconnect()
			end
		end)
	end

	self.agent.humanoid:MoveTo(self.waypoints[self.waypoints_current_index].Position)
end

return pathfinder