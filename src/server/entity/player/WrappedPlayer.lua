--!strict

local Agent = require("../Agent")

local WrappedPlayer = {}
WrappedPlayer.__index = WrappedPlayer

export type WrappedPlayer = typeof(setmetatable({} :: {
	playerInst: Player,
	character: Agent.AgentCharacter?,
	humanoidAlive: boolean
}, WrappedPlayer))

function WrappedPlayer.new(player: Player, characterModel: Model?): WrappedPlayer
	return setmetatable({
		playerInst = player,
		character = if characterModel then Agent.agentFromCharacter(characterModel) else nil,
		humanoidAlive = true
	}, WrappedPlayer) :: any -- to make the typechecker stfu
end

function WrappedPlayer.getCharacter(self: WrappedPlayer): Agent.AgentCharacter?
	if not self.humanoidAlive then
		return nil
	end

	return self.character
end

function WrappedPlayer.getPrimaryPartPosition(self: WrappedPlayer): Vector3?
	if not self.humanoidAlive or self.character == nil then
		return nil
	end

	return self.character.primaryPart.Position
end

function WrappedPlayer.isAlive(self: WrappedPlayer): boolean
	return self.humanoidAlive
end

function WrappedPlayer.onCharacterAdded(self: WrappedPlayer, character: Model): ()
	self.character = Agent.agentCharacterFromCharacter(character)
	self.humanoidAlive = true
end

function WrappedPlayer.onCharacterRemoving(self: WrappedPlayer): ()
	self.humanoidAlive = false
	self.character = nil
end

function WrappedPlayer.onHumanoidDied(self: WrappedPlayer): ()
	self.humanoidAlive = false
end

return WrappedPlayer