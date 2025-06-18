--!strict

local PathfindingService = game:GetService("PathfindingService")

local PathNavigation = {}
PathNavigation.__index = PathNavigation

export type PathNavigation = typeof(setmetatable({} :: {
	targetPos: Vector3,
	path: Path,
	waypoints: { PathWaypoint }
}, PathNavigation))

return PathNavigation