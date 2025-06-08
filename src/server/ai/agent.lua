--!strict

export type AgentCharacter = {
	model: Model,
	head: BasePart,
	primary_part: BasePart
}

export type AgentComponent = {
	update: <T>(self: T, delta: number?) -> ()
}

export type Agent = {
	character: AgentCharacter,
	components: {AgentComponent}
}

return nil