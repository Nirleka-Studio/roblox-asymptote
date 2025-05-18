--!strict

local volume = {}
volume.__index = volume

type VolumeData = {
	_region3: Region3,
	_overlap_params: OverlapParams
}

export type Volume = typeof(setmetatable({} :: VolumeData, volume))

local function create_overlap_params(): OverlapParams
	local new_params = OverlapParams.new()
	new_params.RespectCanCollide = true
	new_params.BruteForceAllSlow = false
	new_params.FilterType = Enum.RaycastFilterType.Include
	return new_params
end

local function get_parts_bounds(part: BasePart): (Vector3, Vector3)
	local min = part.Position + Vector3.new(part.Size.X/2,part.Size.Y/2,part.Size.Z/2)
	local max = part.Position + (Vector3.new(part.Size.X/2,part.Size.Y/2,part.Size.Z/2)*-1)

	return min, max
end

local function normalize_bounds(min: Vector3, max: Vector3): (Vector3, Vector3)
	return Vector3.new(
		math.min(min.X, max.X),
		math.min(min.Y, max.Y),
		math.min(min.Z, max.Z)
	), Vector3.new(
		math.max(min.X, max.X),
		math.max(min.Y, max.Y),
		math.max(min.Z, max.Z)
	)
end

function volume.create(min: Vector3, max: Vector3): Volume
	return setmetatable({
		_region3 = Region3.new(min, max),
		_overlap_params = create_overlap_params()
	}, volume)
end

function volume.from_part(part: BasePart): Volume
	local min, max = normalize_bounds(get_parts_bounds(part))
	return volume.create(min, max)
end

function volume.is_parts_within_zone(self: Volume, parts: BasePart | { BasePart }): boolean
	local parts_list: { BasePart }
	if type(parts) == "table" then
		parts_list = parts
	else
		parts_list = { parts }
	end

	return workspace:ArePartsTouchingOthers(parts_list, 2)
end

function volume.get_parts_within_zone(self: Volume): { BasePart? }
	local parts = {}
	local overlapping_parts = workspace:GetPartBoundsInBox(self._region3.CFrame, self._region3.Size)

	for _, part in ipairs(overlapping_parts) do
		-- another fucking typechecker bug AGAINNN
		-- FYM UNKNOWN?!?! COULD BE NIL?! MY ASS.
		-- IF I PUT THIS SHIT OUTSIDE THE LOOP, ITS FINE NOW IS IT!??!
		-- HOW FUCKING RETARDED.
		--if not self:get_parts_within_zone(part) then
		--	continue
		--end

		-- OHHH, BUT THIS WORKS?!??!?!
		-- WTF IS WRONG WITH YOU
		local its_shit = self:get_parts_within_zone(part)
		if not its_shit then
			continue
		end

		table.insert(parts, part)
	end

	return parts
end

return volume :: {
	create: (min: Vector3, max: Vector3) -> Volume,
	from_part: (part: BasePart) -> Volume
}