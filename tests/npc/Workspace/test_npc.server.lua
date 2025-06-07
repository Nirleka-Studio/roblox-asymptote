--!strict
local RunService = game:GetService("RunService")

local player_sight_sensor = require(game.ServerScriptService.server.detection.player_sight_sensor)

local bob = workspace:FindFirstChild("Bob") :: Model
if not bob then
	return
end

local bob_agent = {
	character = bob,
	head = bob.Head,
	primary_part = bob.HumanoidRootPart
}

local bob_sight_sensor = player_sight_sensor.create(
	bob_agent,
	20,
	90
)

bob_sight_sensor.on_inside_vision:Connect(function(player)
	warn("WTF IS GOING ON HERE?!")
	warn(`{player} just got in!`)
end)

bob_sight_sensor.on_outside_vision:Connect(function(player)
	warn(`{player} just got out!`)
end)

RunService.Heartbeat:Connect(function()
	bob_sight_sensor:update()
end)

local test_signal = require(game.ReplicatedStorage.shared.thirdparty.Signal).new()
test_signal:Connect(function(...)
	print(...)
end)