--!strict

local PathfindingService = game:GetService("PathfindingService")
local debug_waypoints = require(game.ReplicatedStorage.shared.debug.pathfinding.debug_waypoints)

local DEBUG_MODE = true

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
	main_destination: Vector3?,
	is_moving: boolean,
	connection_blocked: RBXScriptConnection?,
	connection_reached: RBXScriptConnection?,
	_debug_parts: {Part}
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
		main_destination = nil,
		waypoints = {},
		waypoints_current_index = 0,
		is_moving = false,
		connection_blocked = nil,
		connection_reached = nil,
		_debug_parts = {}
	}, pathfinder)

	return self :: Pathfinder
end

function pathfinder._on_path_blocked(self: Pathfinder, blocked_waypoint_index): ()
	if blocked_waypoint_index > self.waypoints_current_index then
		(self.connection_blocked :: RBXScriptConnection ):Disconnect()
		self:compute_path((self.agent.character.PrimaryPart :: BasePart).Position, self.main_destination)
		self.connection_blocked = self.path.Blocked:Connect(function(blocked_waypoint_index)
			self:_on_path_blocked(blocked_waypoint_index)
		end)
	end
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

	if DEBUG_MODE then
		for _, part in ipairs(self._debug_parts) do
			part:Destroy()
		end

		self._debug_parts = debug_waypoints.visualize_path(self.path)
	end

	return true
end

function pathfinder.set_destination(self: Pathfinder, to: Vector3): ()
	if self.is_moving then
		self.connection_blocked:Disconnect()
		self.connection_reached:Disconnect()

		if DEBUG_MODE then
			for _, part in ipairs(self._debug_parts) do
				part:Destroy()
			end
		end
	end
	local is_computed = self:compute_path((self.agent.character.PrimaryPart :: BasePart).Position, to)
	if not is_computed then
		self.is_moving = false
		self.main_destination = nil
		return
	end

	self.main_destination = to
	self.is_moving = true

	self.connection_blocked = self.path.Blocked:Connect(function(blocked_waypoint_index)
		self:_on_path_blocked(blocked_waypoint_index)
	end)

	self.connection_reached = self.agent.humanoid.MoveToFinished:Connect(function(reached)
		if reached and self.waypoints_current_index < #self.waypoints then
			self.waypoints_current_index += 1
			self.agent.humanoid:MoveTo(self.waypoints[self.waypoints_current_index].Position)
		else
			self.is_moving = false
			self.main_destination = nil
			if self.connection_reached then
				self.connection_reached:Disconnect()
			end
			(self.connection_blocked :: RBXScriptConnection):Disconnect()
		end
	end)

	self.agent.humanoid:MoveTo(self.waypoints[self.waypoints_current_index].Position)
end

function pathfinder.stop(self: Pathfinder): ()
	if self.is_moving then
		self.agent.humanoid:MoveTo((self.agent.character.PrimaryPart :: BasePart).Position)
		self.connection_blocked:Disconnect()
		self.connection_reached:Disconnect()
	end
end

return pathfinder :: {
	create: typeof(pathfinder.create)
}