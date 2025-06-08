--!strict
local RunService = game:GetService("RunService")

local target_nearby_sensor = require(game.ServerScriptService.server.detection.target_nearby_sensor)
--local player_sight_sensor = require(game.ServerScriptService.server.detection.player_sight_sensor)
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

local bob_hearing_sensor = target_nearby_sensor.create(
	bob_agent,
	20,
	25,
	true
)

bob_hearing_sensor.on_inside_range:Connect(function(plr)
	warn(plr, "Just got in!")
end)

bob_hearing_sensor.on_outside_range:Connect(function(plr)
	warn(plr, "Just got out!")
end)

RunService.Heartbeat:Connect(function()
	bob_hearing_sensor:update()
end)