--!strict

export type HumanoidEntity = {
	character: HumanoidCharacter

}

export type HumanoidCharacter = {
	model: Model,
	head: BasePart,
	primaryPart: BasePart
}

return nil