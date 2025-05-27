--!strict

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local path = PathfindingService:CreatePath({
	AgentRadius = 5
})

local npc = script.Parent.Rig
local humanoid: Humanoid = npc.Humanoid

local TEST_DESTINATION = workspace.to.Position

local waypoints
local nextWaypointIndex
local reachedConnection
local blockedConnection

local function visualize_waypoint(waypoint: PathWaypoint, color: BrickColor?): Part
	local new_part = Instance.new("Part")
	new_part.TopSurface = Enum.SurfaceType.Smooth
	new_part.BottomSurface = Enum.SurfaceType.Smooth
	new_part.BrickColor = color or BrickColor.new("Lapis")
	new_part.Transparency = 0.5
	new_part.Anchored = true
	new_part.CanCollide = false
	new_part.CanQuery = false
	new_part.CanTouch = false
	new_part.CastShadow = false
	new_part.AudioCanCollide = false
	new_part.Size = Vector3.new(1, 1, 1)
	--
	new_part.Position = waypoint.Position
	new_part.Parent = workspace
	return new_part
end

local function visualize_path(path: Path): {Part}
	local waypoints = path:GetWaypoints()
	local waypoints_size = #waypoints
	local waypoint_parts: {Part} = {}

	for i, waypoint in ipairs(waypoints) do
		local part: Part
		if i == 1 or i == waypoints_size then
			part = visualize_waypoint(waypoint, BrickColor.new("Lime green"))
		else
			part = visualize_waypoint(waypoint)
		end
		table.insert(waypoint_parts, part)
	end

	return waypoint_parts
end

local function followPath(destination)
	-- Compute the path
	local success, errorMessage = pcall(function()
		path:ComputeAsync(npc.PrimaryPart.Position, destination)
	end)

	local parts = visualize_path(path)

	if success and path.Status == Enum.PathStatus.Success then
		-- Get the path waypoints
		waypoints = path:GetWaypoints()

		-- Detect if path becomes blocked
		blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
			-- Check if the obstacle is further down the path
			if blockedWaypointIndex >= nextWaypointIndex then
				-- Stop detecting path blockage until path is re-computed
				blockedConnection:Disconnect()
				-- Call function to re-compute new path
				followPath(destination)
			end
		end)

		-- Detect when movement to next waypoint is complete
		if not reachedConnection then
			reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
				if reached and nextWaypointIndex < #waypoints then
					-- Increase waypoint index and move to next waypoint
					parts[nextWaypointIndex].BrickColor = BrickColor.new("Lapis")
					nextWaypointIndex += 1
					humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
					if nextWaypointIndex ~= #parts then
						parts[nextWaypointIndex].BrickColor = BrickColor.Red()
					end
				else
					reachedConnection:Disconnect()
					blockedConnection:Disconnect()
				end
			end)
		end

		-- Initially move to second waypoint (first waypoint is path start; skip it)
		nextWaypointIndex = 1
		humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
	else
		warn("Path not computed!", errorMessage)
	end
end

followPath(TEST_DESTINATION)
