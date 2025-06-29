--!strict

local PathfindingService = game:GetService("PathfindingService")
local Agent = require("../../Agent")

local PathNavigation = {}
PathNavigation.__index = PathNavigation

export type AgentParameters = {
	AgentRadius: number, -- these 2 values are useful so the agent wont get stuck in tight corners
	AgentHeight: number,
	AgentCanJump: boolean, -- due to the nature of our games, these 2 values are not necessary, leave them as false
	AgentCanClimb: boolean,
	WaypointSpacing: number,
	Costs: {any}
}

export type PathNavigation = typeof(setmetatable({} :: {
	agent: Agent.Agent,
	path: Path?,
	pathAgentParams: AgentParameters?,
	waypoints: { PathWaypoint },
	currentWaypointIndex: number,
	humanoidMoveToFinishedConnection: RBXScriptConnection?
}, PathNavigation))

function PathNavigation.new(agent: Agent.Agent)
	return setmetatable({
		agent = agent,
		path = nil,
		pathAgentParams = nil,
		waypoints = {},
		currentWaypointIndex = 1,
		humanoidMoveToFinishedConnection = nil
	}, PathNavigation)
end

function PathNavigation.createPath(self: PathNavigation, toPos: Vector3): Path
	-- pathfinding service in roblox is very weird.
	-- a "path" is just a configured class that we use to compute and also
	-- get the waypoints.
	
	local path = PathfindingService:CreatePath(self.pathAgentParams)
	path:ComputeAsync(self.agent.character.primaryPart.Position, toPos)
	local waypoints = path:GetWaypoints()

	self.path = path
	self.waypoints = waypoints

	return path
end

function PathNavigation.disconnectMoveToConnection(self: PathNavigation): ()
	local connection = self.humanoidMoveToFinishedConnection
	if connection then
		connection:Disconnect()
		self.humanoidMoveToFinishedConnection = nil
	end
end

function PathNavigation.moveTo(self: PathNavigation, toPos: Vector3): ()
	-- reset for good measure (remove if causing performance problems)
	-- for now, we dont implement a blocked or stuck handling
	self:createPath(toPos)
	self:disconnectMoveToConnection()
	self.humanoidMoveToFinishedConnection = self.agent.character.humanoid.MoveToFinished:Connect(function()
		self:onMoveToFinished()
	end)

	self.agent.character.humanoid:MoveTo(self.waypoints[1].Position)
end

function PathNavigation.onMoveToFinished(self: PathNavigation): ()
	local currentWaypointIndex = self.currentWaypointIndex
	local waypoints = self.waypoints
	if currentWaypointIndex >= #waypoints then
		self:disconnectMoveToConnection()
		return
	end

	self.currentWaypointIndex += 1
	self.agent.character.humanoid:MoveTo(waypoints[currentWaypointIndex].Position)
end

function PathNavigation.stop(self: PathNavigation)
	self.path = nil
	self:disconnectMoveToConnection()

	-- move to its current position to stop moving
	self.agent.character.humanoid:MoveTo(self.agent.character.primaryPart.Position)
end

return PathNavigation