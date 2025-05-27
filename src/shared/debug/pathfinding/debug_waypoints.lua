--!strict

export type PathVisualizer = {
	last_waypoint: PathWaypoint,
	current_waypoint: PathWaypoint
}

local function create_static_part(): Part
	local new_part = Instance.new("Part")
	new_part.TopSurface = Enum.SurfaceType.Smooth
	new_part.BottomSurface = Enum.SurfaceType.Smooth
	new_part.Transparency = 0.5
	new_part.Anchored = true
	new_part.CanCollide = false
	new_part.CanQuery = false
	new_part.CanTouch = false
	new_part.CastShadow = false
	new_part.AudioCanCollide = false
	return new_part
end

local function visualize_waypoint(waypoint: PathWaypoint): Part
	local new_part = create_static_part()
	new_part.BrickColor = BrickColor.new("Lapis")
	new_part.Size = Vector3.new(4, 4, 4)
	new_part.Position = waypoint.Position
	new_part.Parent = workspace.CurrentCamera
	return new_part
end

local function visualize_endpoint(waypoint: PathWaypoint): Part
	local new_part = create_static_part()
	new_part.BrickColor = BrickColor.new("Lime green")
	new_part.Size = Vector3.new(2.5, 2.5, 2.5)
	new_part.Position = waypoint.Position
	new_part.Parent = workspace.CurrentCamera
	return new_part
end

local function visualize_path(path: Path): {Part}
	local waypoints = path:GetWaypoints()
	local waypoints_size = #waypoints
	local waypoint_parts: {Part} = {}

	for i, waypoint in ipairs(waypoints) do
		local part: Part
		if i == 1 or i == waypoints_size then
			part = visualize_endpoint(waypoint)
		else
			part = visualize_waypoint(waypoint)
		end
		table.insert(waypoint_parts, part)
	end

	return waypoint_parts
end

return {
	visualize_endpoint = visualize_endpoint,
	visualize_waypoint = visualize_waypoint,
	visualize_path = visualize_path
}