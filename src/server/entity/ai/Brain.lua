--!strict

local ExpireableValue = require("./memory/ExpireableValue")
local MemoryModuleTypes = require("./memory/MemoryModuleTypes")

--[=[
	@class Brain

	
]=]
local Brain = {}
Brain.__index = Brain

export type Brain = typeof(setmetatable({} :: {
	memories: { [MemoryModuleTypes.MemoryModuleType<any>]: ExpireableValue.ExpireableValue<any> },
	sensors: {},
	behaviours: {},
	activities: {}
}, Brain))

type ExpireableValue<T> = ExpireableValue.ExpireableValue<T>
type MemoryModuleType<T> = MemoryModuleTypes.MemoryModuleType<T>

function Brain.new()
	
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

function Brain.eraseMemory<T>(self: Brain, memoryType: MemoryModuleType<T>): ()
	if self.memories[memoryType] then
		self.memories[memoryType] = nil
	end
end

function Brain.setMemory<T>(self: Brain, memoryType: MemoryModuleType<T>, value: T?): ()
	if self.memories[memoryType] then
		self.memories[memoryType].value = value
	end
end

function Brain.hasMemory<T>(self: Brain, memoryType: MemoryModuleType<T>, value: T?): boolean
	-- cant we just compare it with nil and thats it?
	-- no. because the typechecker will complain like a bitch.
	if self.memories[memoryType] then
		return true
	else 
		return false
	end
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

function Brain.update(self: Brain, delta: number): ()
	self:updateSensors(delta)
end

function Brain.forgetExpiredMemories(self: Brain, delta: number): ()
	for k, memory in pairs(self.memories) do
		memory:update(delta)
		if memory:isExpired() then
			self.memories[k] = nil
		end
	end
end

function Brain.updateSensors(self: Brain, delta: number): ()
	for _, sensor in pairs(self.sensors) do
		sensor:update(delta, self)
	end
end

return Brain