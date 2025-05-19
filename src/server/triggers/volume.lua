--!strict

local volume = {}

function volume.get_bounds_from_box(cframe: CFrame, size: Vector3): (Vector3, Vector3)
	-- https://devforum.roblox.com/t/part-to-region3-help/251348/5
	local abs = math.abs
	local sx, sy, sz = size.X, size.Y, size.Z
	local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cframe:GetComponents()

	-- https://zeuxcg.org/2010/10/17/aabb-from-obb-with-component-wise-abs/
	local wsx = 0.5 * (abs(R00) * sx + abs(R01) * sy + abs(R02) * sz)
	local wsy = 0.5 * (abs(R10) * sx + abs(R11) * sy + abs(R12) * sz)
	local wsz = 0.5 * (abs(R20) * sx + abs(R21) * sy + abs(R22) * sz)

	local minx = x - wsx
	local miny = y - wsy
	local minz = z - wsz

	local maxx = x + wsx
	local maxy = y + wsy
	local maxz = z + wsz

	local minv, maxv = Vector3.new(minx, miny, minz), Vector3.new(maxx, maxy, maxz)
	return minv, maxv
end

function volume.get_bounds_from_part(part: BasePart): (Vector3, Vector3)
	return volume.get_bounds_from_box(part.CFrame, part.Size)
end

function volume.normalize_bounds(min: Vector3, max: Vector3): (Vector3, Vector3)
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

function volume.is_bounds_within_bounds(
	min_a: Vector3, max_a: Vector3,
	min_b: Vector3, max_b: Vector3
)
	return (min_a.X >= min_b.X and max_a.X <= max_b.X) and
	       (min_a.Y >= min_b.Y and max_a.Y <= max_b.Y) and
	       (min_a.Z >= min_b.Z and max_a.Z <= max_b.Z)
end

return volume