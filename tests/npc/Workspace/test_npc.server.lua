--!strict

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local agent = require(game.ServerScriptService.server.character.agent)
local Signal = require(game.ReplicatedStorage.shared.thirdparty.Signal)
local target_nearby_sensor = require(game.ServerScriptService.server.detection.target_nearby_sensor)
local suspicion_level = require(game.ServerScriptService.server.detection.suspicion_level)
local player_sight_sensor = require(game.ServerScriptService.server.detection.player_sight_sensor)
local char_utils = require(game.ServerScriptService.server.character.character_utils)

type EntityDefinition = {
	description: {
		identifier: string,
		tag_name: string
	}
}

local bob = workspace:FindFirstChild("Bob") :: Model
if not bob then
	return
end

local head, root_part = char_utils.get_agent_parts(bob)
if not (head and root_part )then
	return
end

local bob_agent = {
	character = bob,
	head = head,
	primary_part = root_part
}

local bob_hearing_sensor = player_sight_sensor.create(
	bob_agent,
	20,
	90
)

local bob_sus_comp = suspicion_level.create(
	4/5,
	1/5
)

bob_hearing_sensor.on_inside_vision:Connect(function(plr)
	warn(plr, "Just got in!")
	bob_sus_comp:update_suspicion_target(1, plr)
end)

bob_hearing_sensor.on_outside_vision:Connect(function(plr)
	warn(plr, "Just got out!")
	bob_sus_comp:update_suspicion_target(0, plr)
end)

bob_sus_comp.on_suspicion_update:Connect(function(plr)
	--print(plr)
	--print(bob_agent.primary_part.Position)
	game.ReplicatedStorage.remotes.Detection:FireClient(plr, bob_sus_comp.suspicion_level, bob_agent.character, bob_agent.primary_part.Position)
end)

RunService.Heartbeat:Connect(function(delta)
	bob_hearing_sensor:update()
	bob_sus_comp:update(delta)
end)