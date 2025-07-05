--!strict

--[=[
	@class MemoryModuleTypes

	For typechecking purposes.
]=]
export type MemoryModuleType<T> = {
	name: string,
	-- Don't store the actual value, just use the type parameter
}

local function createModuleType<T>(name: string): MemoryModuleType<T>
	return {
		name = name,
	}
end

local MemoryModuleTypes = {
	NEAREST_PLAYER = createModuleType("NEAREST_PLAYER") :: MemoryModuleType<Player>,
}

return MemoryModuleTypes