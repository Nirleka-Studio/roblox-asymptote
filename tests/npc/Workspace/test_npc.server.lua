--!strict

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local GuardClass = require(game.ServerScriptService.server.entity.npcs.Guard)

local TAG_NAME = "Test_Npc"

local function initGuard(guardInst: Instance): ()
	local newGuard = GuardClass.create(guardInst :: Model)
	local run_connection = RunService.PreSimulation:Connect(function(delta)
		newGuard:update(delta)
	end)

	local alerted_connection = newGuard.suspicionLevel.on_alerted:Connect(function(player)
		task.wait(1.5)
		newGuard.suspicionLevel:reset()
		player.Character:PivotTo(workspace.SpawnLocation.CFrame + Vector3.new(0,5,0))
	end)
	
	guardInst.Destroying:Connect(function()
		run_connection:Disconnect()
		alerted_connection:Disconnect()
		setmetatable(newGuard, nil)
		newGuard = nil
	end)
end

for _, guardInst in ipairs(CollectionService:GetTagged("Test_Npc")) do
	initGuard(guardInst)
end

CollectionService:GetInstanceAddedSignal("Test_Npc"):Connect(function(guardInst)
	initGuard(guardInst)
end)
