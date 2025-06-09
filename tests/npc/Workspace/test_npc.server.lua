--!strict

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local agent = require(game.ServerScriptService.server.character.agent)
local Signal = require(game.ReplicatedStorage.shared.thirdparty.Signal)
local target_nearby_sensor = require(game.ServerScriptService.server.detection.target_nearby_sensor)
local suspicion_level = require(game.ServerScriptService.server.detection.suspicion_level)
local player_sight_sensor = require(game.ServerScriptService.server.detection.player_sight_sensor)
local char_utils = require(game.ServerScriptService.server.character.character_utils)

-- Example
type Component<T> = {
	constructor: (agent.Agent, ...any) -> T,
	params: {any},
	connections_callback: (componentInstance: T) -> {Signal.Connection<any>}
}

type EntityDefinition = {
	description: {
		identifier: string,
		tag_name: string
	},
	components: { [string]: Component<any> }
}

local NpcDefinition = {
	description = {
		identifier = "entity:npc",
		tag_name = "Test_Npc"
	},
	components = {
		sight_sensor = {
			constructor = player_sight_sensor.create, -- returns PlayerSightSensor, Agent is automatically passed
			params = {
				20,
				90
			},
			connections_callback = function(sensor: player_sight_sensor.PlayerSightSensor): {Signal.Connection<Player>}
				local connections = {}

				table.insert(connections, sensor.on_inside_vision:Connect(function(player)
					warn("A player has entered POV:", player)
				end))

				table.insert(connections, sensor.on_outside_vision:Connect(function(player)
					warn("A player has left POV:", player)
				end))

				return connections
			end
		},
		hearing_sensor = {
			constructor = target_nearby_sensor.create,
			params = {
				20,
				25,
				true
			},
			connections_callback = function(sensor: target_nearby_sensor.TargetNearbySensor): {Signal.Connection<Player>}
				local connections = {}

				table.insert(connections, sensor.on_inside_range:Connect(function(player)
					warn("A player has entered hearing range:", player)
				end))

				table.insert(connections, sensor.on_outside_range:Connect(function(player)
					warn("A player has left hearing range:", player)
				end))

				return connections
			end
		}
	}
}

--local entityInstanceRegistry: { [Instance]: any } = {}

local function initializeEntity(entityDefinition: EntityDefinition, entityInstance: Instance)
	local newAgent: agent.Agent = {
		character = entityInstance :: Model,
		head = entityInstance:FindFirstChild("Head") :: BasePart,
		primary_part = entityInstance:FindFirstChild("HumanoidRootPart") :: BasePart
	}

	for componentName, component in pairs(entityDefinition.components) do
		local constructed = component.constructor(newAgent, table.unpack(component.params))
		component.connections_callback(constructed)
		if constructed.update then
			RunService.Heartbeat:Connect(function(delta)
				constructed:update(delta)
			end)
		end
	end
end

local function registerEntityDefinition(entityDefinition: EntityDefinition): ()
	for _, entityInstance in ipairs(CollectionService:GetTagged(entityDefinition.description.tag_name)) do
		initializeEntity(entityDefinition, entityInstance)
	end

	CollectionService:GetInstanceAddedSignal(entityDefinition.description.tag_name):Connect(function(entityInstance)
		initializeEntity(entityDefinition, entityInstance)
	end)
end

registerEntityDefinition(NpcDefinition)