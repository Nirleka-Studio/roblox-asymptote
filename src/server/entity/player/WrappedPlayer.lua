--!strict

local Maid = require("../../../shared/thirdparty/Maid")
local Agent = require("../Agent")

local WrappedPlayer = {}
WrappedPlayer.__index = WrappedPlayer

export type WrappedPlayer = typeof(setmetatable({} :: {
	playerInst: Player,
	character: Agent.HumanoidCharacter?,
	humanoidAlive: boolean,
	_maid: typeof(Maid.new())
}, WrappedPlayer))

function WrappedPlayer.new(player: Player): WrappedPlayer
	local self = {
		playerInst = player,
		character = nil :: Agent.HumanoidCharacter?, -- istg the devs needs to fix this
		humanoidAlive = true,
		_maid = Maid.new()
	}
	setmetatable(self, WrappedPlayer)

	local playerCharacter = player.Character
	if playerCharacter then
		self:onCharacterAdded(playerCharacter)
	end

	self._maid["onCharacterAdded"] = player.CharacterAdded:Connect(function(character)
		self:onCharacterAdded(character)
	end)

	self._maid["onCharacterRemoving"] = player.CharacterRemoving:Connect(function()
		self:onCharacterRemoving()
	end)

	return self
end

function WrappedPlayer.getCharacter(self: WrappedPlayer): Agent.HumanoidCharacter?
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

function WrappedPlayer.isMoving(self: WrappedPlayer): boolean
	if not self:isAlive() or not self.character then
		return false
	end

	if self.character.humanoid.WalkSpeed <= 0 then
		return false
	end

	return self.character.humanoid.MoveDirection.Magnitude > 0
end

function WrappedPlayer.onCharacterAdded(self: WrappedPlayer, character: Model): ()
	self.character = Agent.HumanoidCharacterFromCharacter(character)
	self.humanoidAlive = true
	self._maid["onHumanoidDied"] = (self.character :: Agent.HumanoidCharacter).humanoid.Died:Once(function()
		self:onHumanoidDied()
	end)
end

function WrappedPlayer.onCharacterRemoving(self: WrappedPlayer): ()
	self.humanoidAlive = false
	self.character = nil
end

function WrappedPlayer.onHumanoidDied(self: WrappedPlayer): ()
	self.humanoidAlive = false
end

function WrappedPlayer.onPlayerRemoving(self: WrappedPlayer): ()
	self._maid:DoCleaning()
end

return WrappedPlayer