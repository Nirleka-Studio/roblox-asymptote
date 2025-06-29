--!strict

local player_sight_sensor = require("../../detection/player_sight_sensor")
local suspicion_level = require("../../detection/suspicion_level")
local Agent = require("../Agent")
local GoalManager = require("../ai/goal/GoalManager")

local REMOTE_DETECTION = require(game.ReplicatedStorage.shared.network.TypedDetectionRemote)

local Guard = {}
Guard.__index = Guard

export type Guard = typeof(setmetatable({} :: {
	character: Agent.AgentCharacter,
	suspicionLevel: suspicion_level.SuspicionLevel,
	playerSightSensor: player_sight_sensor.PlayerSightSensor,
	goalManager: GoalManager.GoalManager
}, Guard))

function Guard.create(character: Model): Guard
	local agentCharacter = Agent.agentFromCharacter(character).character
	local self = setmetatable({
		character = agentCharacter,
		suspicionLevel = suspicion_level.create(
			4.7/5,
			2/5
		),
		playerSightSensor = player_sight_sensor.create(
			{
				character = character,
				head = agentCharacter.head,
				primary_part = agentCharacter.primaryPart,
			},
			20,
			180
		),
		goalManager = GoalManager.new()
	}, Guard)
	

	self.playerSightSensor.on_inside_vision:Connect(function(player)
		self:onDetectedPlayer(player)
	end)

	self.playerSightSensor.on_outside_vision:Connect(function(player)
		self:onLosePlayer(player)
	end)

	self.suspicionLevel.on_suspicion_update:Connect(function(player)
		REMOTE_DETECTION:FireClient(
			player,
			self.suspicionLevel.suspicion_level,
			self.character.model,
			self.character.primaryPart.Position
		)
	end)

	return self
end

function Guard.onDetectedPlayer(self: Guard, player: Player): ()
	self.suspicionLevel:update_suspicion_target(1, player)
end

function Guard.onLosePlayer(self: Guard, player: Player): ()
	self.suspicionLevel:update_suspicion_target(0, player)
end

function Guard.update(self: Guard, delta: number): ()
	self.suspicionLevel:update(delta)
	self.playerSightSensor:update()
end

return Guard