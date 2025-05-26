-- array.lua
-- NirlekaDev
-- April 26, 2025

--!strict

local error = error
local table = table
local clear = table.clear
local create = table.create
local find = table.find
local remove = table.remove
local string = string
local format = string.format
local math = math
local floor = math.floor

--[=[
	@class array
]=]
local array = {}

--[=[
	@within array
	An array is a 1-based indexed data structure.
]=]
export type Array<T> = {
	_data: { [number]: T },
	_size: number
}

--[=[
	@within array
	Returns an empty array.
]=]
function array.create(): Array<any>
	local new_array: Array<any> = {
		_data = {},
		_size = 0
	}

	return new_array
end

--[=[
	@within array
	Returns a new array populated with many instances of the specified value.
]=]
function array.filled<T>(count: number, value: T): Array<T>
	local new_array: Array<T> = {
		_data = create(count, value),
		_size = count
	}

	return new_array
end

--[=[
	@within array
	Reference an existing table to be an array
]=]
function array.from<T>(from: { T }): Array<T>
	local new_array: Array<T> = {
		_data = from,
		_size = #from
	}

	return new_array
end

--[=[
	@within array
	Adds the elements of from `fruits` to the end of `basket`
]=]
function array.append_array(basket: Array<any>, fruits: Array<any>)
	for _, fruit in ipairs(fruits._data) do
		array.push_back(basket, fruit)
	end
end

--[=[
	@within array
	Removes all element from the array.
]=]
function array.clear(arr: Array<any>)
	clear(arr._data)
	arr._size = 0
end

--[=[
	@within array
	Removes the first occurence of index assosicated with `value`
]=]
function array.erase(arr: Array<any>, value: any)
	local index = array.find(arr, value)
	if not index then
		return
	end

	remove(arr._data, index)
	arr._size -= 1
end

--[=[
	@within array
	Returns a shallow copy of `arr`
]=]
function array.duplicate(arr: Array<any>): Array<any>
	return array.create(table.clone(arr._data))
end

--[=[
	@within array
	Returns a new array filled with the entries that the `predicate` function returned true.
]=]
function array.filter<T>(arr: Array<T>, predicate: (value: T) -> boolean): Array<T>
	local new_arr: Array<T> = array.create()
	for i, v in ipairs(arr._data) do
		if not predicate(v) then
			continue
		end
		array.push_back(new_arr, v)
	end
	return new_arr
end

--[=[
	@within array
	Returns the index of the first occurence of `value`
]=]
function array.find(arr: Array<any>, value: any, from: number?): number?
	return find(arr._data, value, from)
end

--[=[
	@within array
	Returns the value of `index`
	Shorthand for array._data[index]
]=]
function array.get<T>(arr: Array<T>, index: number): T
	return arr._data[index]
end

--[=[
	@within array
	Returns true if the array contains `value`
]=]
function array.has(arr: Array<any>, value: any): boolean
	return array.find(arr, value) ~= nil
end

--[=[
	@within array
	Returns true if the array is empty, meaning no entries.
]=]
function array.is_empty(arr: Array<any>): boolean
	return #arr._data == 0
end

--[=[
	@within array
	Returns the function ipairs() on arr._data returns.
]=]
function array.iter<T>(arr: Array<T>): (({T}, number) -> (number?, T), {T}, number)
	return ipairs(arr._data)
end

--[=[
	@within array
	Returns a new array with each element set to the value returned by the `mapper` function.
]=]
function array.map<T, U>(arr: Array<U>, mapper: (value: U) -> T): Array<T>
	-- idk why, but filling up an already filled table is faster.
	local new_arr: Array<T> = array.filled(arr._size, true)
	for i, v in ipairs(arr._data) do
		array.set(new_arr, i, mapper(v))
	end
	-- omg, no type errors? :o shocking, i know, im a genius.
	-- now ignore the rest of my code.
	return new_arr
end

--[=[
	@within array
	Inserts a new index with `value` at the end of the array.
]=]
function array.push_back(arr: Array<any>, value: any)
	arr._data[ #arr._data + 1 ] = value
	arr._size += 1
end

--[=[
	@within array
	Removes an existing index from the array.
	Maintains the order of the array.
]=]
function array.remove_at(arr: Array<any>, index: number)
	if index < arr._size then
		arr._size -= 1
	end
	return remove(arr._data, index)
end

--[=[
	@within array
	Sets the value of `index` to `value`
]=]
function array.set(arr: Array<any>, index: number, value: any)
	if type(index) ~= "number" then
		error(format("Cannot index Array with type %s", typeof(index)), 4)
	end

	local size = #arr._data

	if index ~= floor(index) then
		error("Array indices must be integers", 4)
	end

	if index > size or index < 0 then
		error("Index is out of bounds", 4)
	end

	if value == nil then
		remove(arr._data, index)
		-- no need to know if the index exists or not
		-- since this function will throw an error if the index
		-- is out of bounds anyway.
		arr._size -= 1
		return
	end

	arr._data[index] = value
end

--[=[
	@within array
	Returns the size of the array.
	Sizes of arrays and cached in the `_size` field.
]=]
function array.size(arr: Array<any>): number
	return arr._size
end

--[=[
	@within array
	Returns a new array containing elements from `start` to `end` (inclusive).
]=]
function array.slice<T>(arr: Array<T>, start: number, end_: number): Array<T>
	local newArr = array.create()
	local len = arr._size

	start = math.max(1, math.min(start, len))
	end_ = math.max(1, math.min(end_, len))

	for i = start, end_ do
		array.push_back(newArr, arr._data[i])
	end

	return newArr
end

return array