--!strict

local Entity = require("./Entity")

export type AgentCharacter = {
	model: Model,
	humanoid: Humanoid,
	primaryPart: BasePart,
}

export type Agent = {
	character: AgentCharacter
} & Entity.Entity

local agent = {}

function agent.agentFromCharacter(character: Model): Agent
	return {
		character = {
			model = character,
			humanoid = character:FindFirstChild("Humanoid") :: Humanoid,
			primaryPart = character.PrimaryPart :: BasePart
		}
	}
end

return nil