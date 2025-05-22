--!strict

local array = {}
array.__index = array

type ArrayData<T> = {
	_data: { T },
	size: number
}

export type Array<T> = typeof(setmetatable({} :: ArrayData<T>, array))

function array.create<T>(): Array<any>
	return setmetatable({
		_data = {},
		size = 0
	}, array)
end

function array.filled<T>(count: number, value: T): Array<T>
	return setmetatable({
		_data = table.create(count, value),
		size = 0
	}, array)
end

function array.push<T>(self: Array<T>, value: T): ()
	self.size += 1
	self._data[self.size] = value
end

function array.get<T>(self: Array<T>, index: number): T?
	return self._data[index]
end

return array :: {
	create: () -> Array<any>,
	filled: <T>(count: number, value: T) -> Array<T>
}