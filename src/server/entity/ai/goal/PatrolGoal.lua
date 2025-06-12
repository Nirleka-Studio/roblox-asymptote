--!strict

local Goal = require("./Goal")

local PatrolGoal = Goal.new({"PatrolGoal"})

function PatrolGoal.update(self: Goal.Goal, delta: number?): ()
    print("updated, comign from patrol goal")
end

function PatrolGoal.canUse(self: Goal.Goal, delta: number?): boolean
    return true
end

function Goal.requiresUpdating(self: Goal.Goal): boolean
	return true
end

function Goal.getFlags(self)
    return {"TEST FLAG"}
end

return PatrolGoal