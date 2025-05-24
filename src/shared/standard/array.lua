--!strict

export type Array<T> = {
	_data: { T },
	size: number,
	map: (self: Array<T>, (T) -> any) -> Array<any>, -- I DECLARE THIS A MOTHERFUCKING BUG. OH DO I NEED A FUCKING 80 PAGE DOCUMENT ON THE MANY SHIT I TRIED TO WORK AROUND OVER THIS?!?! LUAU, FIX YOUR SHITTY TYPE SOLVER. TO FUTURE MAINTAINERS, "TypeError: Recursive type being used with different parameters" STFU. THAT MEANS JACKSHIT. AND EFFECTS JACKSHIT. THE RETARDED SOLVER'S COMPLAINT SHALL BE FUCKING IGNORED. EXISTENCE DISREGARDED. EXCUSED.
	push: (self: Array<T>, value: T) -> ()
}

local array = {}
array.__index = array

function array.ref<T>(from: {T}): Array<T>
	local self = {
		_data = from,
		size = #from,
	} :: Array<T>
	return setmetatable(self, array) :: Array<T>
end

function array.filled<T>(count: number, value: T): Array<T>
	local self = {
		_data = table.create(count, value),
		size = if value :: any ~= nil then count else 0,
	} :: Array<T>
	return setmetatable(self, array) :: Array<T>
end

function array.map<T>(self: Array<T>, mapper: (T) -> any): Array<any>
	local new_table = {}
	local i = 0

	for _, v in ipairs(self._data) do
		local mapped = mapper(v)
		if mapped ~= nil then
			i += 1
			new_table[i] = mapped
		end
	end

	return array.ref(new_table) :: Array<any>
end

function array.push<T>(self: Array<T>, value: T): ()
	self.size += 1
	self._data[self.size] = value
end

return array :: {
	ref: typeof(array.ref),
	filled: typeof(array.filled)
}