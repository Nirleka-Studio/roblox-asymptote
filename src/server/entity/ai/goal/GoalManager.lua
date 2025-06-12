--!strict

local WrappedGoal = require("./WrappedGoal")

--[=[
	@class GoalManager

	Manages goals of an Agent.
]=]
local GoalManager = {}
GoalManager.__index = GoalManager

type WrappedGoal = WrappedGoal.WrappedGoal

export type GoalManager = typeof(setmetatable({} :: {
	availableGoals: {WrappedGoal},
	disabledFlags: {[any]: boolean},
	flagLocks: {[any]: WrappedGoal}
}, GoalManager))

function GoalManager.new()
	return setmetatable({
		availableGoals = {},
		disabledFlags = {},
		flagLocks = {} -- [flag] = goal
	}, GoalManager)
end

function GoalManager.addGoal(self: GoalManager, goal: WrappedGoal)
	table.insert(self.availableGoals, goal)
end

function GoalManager.disableFlag(self: GoalManager, flag: any)
	self.disabledFlags[flag] = true
end

function GoalManager.enableFlag(self: GoalManager, flag: any)
	self.disabledFlags[flag] = nil
end

local function goalContainsAnyFlags(goal: WrappedGoal, disabledFlags: {[any]: boolean}): boolean
	for _, flag in ipairs(goal.goal:getFlags()) do
		if disabledFlags[flag] then
			return true
		end
	end
	return false
end

local function goalCanBeReplacedForAllFlags(goal: WrappedGoal, flagLocks: {[any]: WrappedGoal}): boolean
	for _, flag in ipairs(goal.goal:getFlags()) do
		local current = flagLocks[flag]
		if current and not current:canBeReplacedBy(goal) then
			return false
		end
	end
	return true
end

function GoalManager.update(self: GoalManager, delta: number)
	-- Cleanup phase
	for _, goal in ipairs(self.availableGoals) do
		if goal:isRunning() and (goalContainsAnyFlags(goal, self.disabledFlags) or not goal.goal:canContinueToUse()) then
			goal:stop()
		end
	end

	-- Remove non-running owners from flagLocks
	for flag, goal in pairs(self.flagLocks) do
		if not goal:isRunning() then
			self.flagLocks[flag] = nil
		end
	end

	-- Update phase: start new goals if valid
	for _, goal in ipairs(self.availableGoals) do
		if not goal:isRunning()
			and not goalContainsAnyFlags(goal, self.disabledFlags)
			and goalCanBeReplacedForAllFlags(goal, self.flagLocks)
			and goal:canUse() then

			-- Steal ownership of all required flags
			for _, flag in ipairs(goal.goal:getFlags()) do
				local prev = self.flagLocks[flag]
				if prev then
					prev:stop()
				end
				self.flagLocks[flag] = goal
			end

			goal:start()
		end
	end

	-- Tick running goals
	for _, goal in ipairs(self.availableGoals) do
		if goal:isRunning() and goal.goal:requiresUpdating() then
			goal.goal:update(delta)
		end
	end
end

return GoalManager