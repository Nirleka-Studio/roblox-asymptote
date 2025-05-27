--!strict

export type PathVisualizer = {
	last_waypoint: PathWaypoint,
	current_waypoint: PathWaypoint
}

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

