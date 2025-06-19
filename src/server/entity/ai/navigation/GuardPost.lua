--!strict

local GuardPost = {}
GuardPost.__index = GuardPost

export type GuardPost = typeof(setmetatable({} :: {
	cframe: CFrame,
	occupied: boolean
}, GuardPost))

function GuardPost.new(cframe: CFrame): GuardPost
	return setmetatable({
		cframe = cframe,
		occupied = false
	}, GuardPost)
end

function GuardPost.fromPart(part: BasePart): GuardPost
	return GuardPost.new(part.CFrame)
end

function GuardPost.isOccupied(self: GuardPost): boolean
	return self.occupied
end

function GuardPost.occupy(self: GuardPost): ()
	self.occupied = true
end

function GuardPost.vacate(self: GuardPost): ()
	self.occupied = false
end

return GuardPost