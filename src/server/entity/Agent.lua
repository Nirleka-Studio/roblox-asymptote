--!strict

local Entity = require("./Entity")
local Brain = require("./ai/Brain")

export type HumanoidCharacter = {
	model: Model,
	head: BasePart,
	humanoid: Humanoid,
	primaryPart: BasePart
}

export type Agent = {
	character: HumanoidCharacter,
	brain: Brain.Brain
} & Entity.Entity

local Agent = {}
Agent.__index = Agent

function Agent.new()

function agent.HumanoidCharacterFromCharacter(character: Model): HumanoidCharacter
	return {
		model = character,
		head = character:FindFirstChild("Head") :: BasePart,
		humanoid = character:FindFirstChild("Humanoid") :: Humanoid,
		primaryPart = character.PrimaryPart :: BasePart
	}
end

return Agent