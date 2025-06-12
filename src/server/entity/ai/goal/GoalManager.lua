--!strict

local Goal = require("./Goal")

--[=[
	@class GoalManager

	Manages goals of an Agent.
]=]
local GoalManager = {}
GoalManager.__index = GoalManager

export type GoalManager = typeof(setmetatable({} :: {
	availableGoals: {Goal.Goal},
	activeGoals: {Goal.Goal},
	flagLocks: {any}
}, GoalManager))

function GoalManager.new()
	return setmetatable({
		availableGoals = {},
		activeGoals = {},
		flagLocks = {}
	}, GoalManager)
end

function GoalManager.addGoal(self: GoalManager, goal)
	table.insert(self.availableGoals, goal)
end

local function flagsConflict(a, b)
	for _, flag in ipairs(a) do
		for _, other in ipairs(b) do
			if flag == other then return true end
		end
	end
	return false
end

function GoalManager.update(self: GoalManager, delta: number)
	-- stop goals that can not continue
	for i, goal in ipairs(self.activeGoals) do
		if not goal:canUse() then
			goal:stop()
			table.remove(self.activeGoals, i)
		end
	end

	-- check for new goals to activate
	for _, goal in ipairs(self.availableGoals) do
		if not goal.IsRunning and goal:canUse() then
			local conflict = false
			for _, active in ipairs(self.activeGoals) do
				if flagsConflict(goal:getFlags(), active:getFlags()) and goal.priority > active.priority then
					active:stop()
					active.isGoalRunning = false
				elseif flagsConflict(goal., active:getFlags()) then
					conflict = true
				end
			end

			if not conflict then
				goal:start()
				goal.isGoalRunning = true
				table.insert(self.activeGoals, goal)
			end
		end
	end

	-- Tick active goals
	for _, goal in ipairs(self.activeGoals) do
		if goal:requiresUpdating() then
			goal:update(delta)
		end
	end
end

return GoalManager
