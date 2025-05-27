--!strict

local pathfinder = require(game.ServerScriptService.server.pathfinding.pathfinder)
local TEST_DESTINATION = workspace.to.Position

local new_path = pathfinder.create(workspace.Rig, workspace.Rig.Humanoid)
new_path:set_destination(TEST_DESTINATION)
task.wait(3)
new_path:stop()