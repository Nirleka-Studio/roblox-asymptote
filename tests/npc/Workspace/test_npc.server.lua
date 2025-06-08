--!strict
local RunService = game:GetService("RunService")

local player_sight_sensor = require(game.ServerScriptService.server.detection.player_sight_sensor)
local char_utils = require(game.ServerScriptService.server.character.character_utils)

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

local bob_sight_sensor = player_sight_sensor.create(
	bob_agent,
	20,
	90
)

bob_sight_sensor.on_inside_vision:Connect(function(player)
	warn(`{player} just got in!`)
end)

bob_sight_sensor.on_outside_vision:Connect(function(player)
	warn(`{player} just got out!`)
end)

RunService.Heartbeat:Connect(function()
	bob_sight_sensor:update()
end)