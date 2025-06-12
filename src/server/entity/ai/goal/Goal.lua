--!strict

local Goal = {}
Goal.__index = Goal

export type Goal = typeof(setmetatable({} :: {
	name: string,
	priority: number,
	flags: {any},
	isGoalRunning: boolean
}, Goal))

function Goal.new(name: string, priority: number, flags: {any}): Goal
	return setmetatable({
		name = name,
		priority = priority or 0,
		flags = flags or {},
		isGoalRunning = false,
	}, Goal)
end

function Goal.canUse(self: Goal): boolean
	return false
end

function Goal.isRunning(self: Goal): boolean
	return self.isGoalRunning
end

function Goal.getFlags(self: Goal): {Flag}
	return self.flags
end

function Goal.start(self: Goal): ()
end

function Goal.stop(self: Goal): ()
end

function Goal.update(self: Goal, delta: number?): ()
end

function Goal.requiresUpdating(self: Goal): boolean
	return false
end

return Goal
