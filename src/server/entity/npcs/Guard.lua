--!strict

local player_sight_sensor = require("../../detection/player_sight_sensor")
local suspicion_level = require("../../detection/suspicion_level")
local HumanoidEntity = require("../humanoid/HumanoidEntity")

local REMOTE_DETECTION = require(game.ReplicatedStorage.shared.network.TypedDetectionRemote)

local Guard = {}
Guard.__index = Guard

export type Guard = typeof(setmetatable({} :: {
	character: HumanoidEntity.HumanoidCharacter,
	suspicionLevel: suspicion_level.SuspicionLevel,
	playerSightSensor: player_sight_sensor.PlayerSightSensor
}, Guard))

function Guard.create(character: Model): Guard
	local self = setmetatable({
		character = {
			head = character:FindFirstChild("Head") :: BasePart,
			model = character,
			primaryPart = character.PrimaryPart :: BasePart
		},
		suspicionLevel = suspicion_level.create(
			1/5,
			2/5
		),
		playerSightSensor = player_sight_sensor.create(
			{
				character = character,
				head = character:FindFirstChild("Head") :: BasePart,
				primary_part = character.PrimaryPart :: BasePart,
			},
			20,
			90
		)
	}, Guard)
	

	self.playerSightSensor.on_inside_vision:Connect(function(player)
		self:onDetectedPlayer(player)
	end)

	self.playerSightSensor.on_outside_vision:Connect(function(player)
		self:onLosePlayer(player)
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
	if self.suspicionLevel.target_player then
		REMOTE_DETECTION:FireClient(
			self.suspicionLevel.target_player,
			self.suspicionLevel.suspicion_level,
			self.character.model,
			self.character.primaryPart.Position
		)
	end
end

return Guard