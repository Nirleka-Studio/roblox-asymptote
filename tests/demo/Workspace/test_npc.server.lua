--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local pipieline = require(game.ServerScriptService.server.detection.pipieline)
local hearing = require(game.ServerScriptService.server.detection.hearing)
local suspicion = require(game.ServerScriptService.server.detection.suspicion)
local sight = require(game.ServerScriptService.server.detection.sight)

local NPC_TAG_NAME = "Test_Npc"
local REMOTE = game.ReplicatedStorage.remotes.Detection

type Npc = {
	character: Model,
	character_head: BasePart,
	comp_sight: sight.SightComp,
	comp_sus: suspicion.SuspicionComp,
	comp_hearing: hearing.HearingComp,
	comp_pipeline: pipieline.DetectionPipeline,
	focusing_player: Player?,
	any_player_detected: boolean
}

local new_config: sight.SightConfig = {
	sight_radius = 50,
	peripheral_vision_angle = 90,
	min_glass_trans = 0.5,
	angle_deg = 10,
	num_rays = 5
}

local active_npcs: { [ Model ]: Npc } = {}

local function create_npc(character: Model): Npc
	local head = character:FindFirstChild("Head") :: BasePart
	return {
		character = character,
		character_head = head, -- for the sake of type checker
		comp_sight = sight.create_comp(head, new_config),
		comp_sus = suspicion.create(1/3, 1/5),
		comp_hearing = hearing.create(head.Position, 15),
		comp_pipeline = pipieline.new(),
		focusing_player = nil,
		any_player_detected = false
	}
end

local function init_npc(character: Model)
	local self = create_npc(character)
	active_npcs[character] = self

	local pipeline = self.comp_pipeline
	-- ISTG WTF ARE THESE TYPE ERRORS?!?!!!!!!!!!!!!!!
	pipeline:register("sight", function(npc)
		for plr in pairs(npc.comp_sight.sight_plrs_to_check) do
			if sight.is_player_visible(npc.comp_sight, plr) then
				return { detected = true, player = plr, method = "sight" }
			end
		end
		return { detected = false } :: pipieline.DetectionResult
	end)

	pipeline:register("hearing", function(npc)
		for plr in pairs(npc.comp_sight.sight_plrs_to_check) do
			if hearing.is_player_hearable(npc.comp_hearing, plr) then
				return { detected = true, player = plr, method = "hearing" }
			end
		end
		return { detected = false } :: pipieline.DetectionResult
	end)
end

local function send_sus_value_to_plrs(self: Npc, sus_value: number)
	if self.focusing_player then
		REMOTE:FireClient(
			self.focusing_player,
			sus_value, self.character,
			self.character_head.Position)
	end
end

for _, npc in ipairs(CollectionService:GetTagged(NPC_TAG_NAME)) do
	init_npc(npc :: Model)
end

CollectionService:GetInstanceAddedSignal(NPC_TAG_NAME):Connect(function(npc)
	init_npc(npc :: Model)
end)

RunService.Heartbeat:Connect(function()
	for _, npc in pairs(active_npcs) do
		local self: Npc = npc

		local detection = self.comp_pipeline:run(npc)

		-- only update suspicion when detection state changes
		if detection.detected ~= self.any_player_detected then
			self.any_player_detected = detection.detected

			if detection.detected then
				-- the hearing logic is causing a fuck up. we'll fix later.
				--warn("detected by", detection.method)
				self.focusing_player = detection.player

				--print("raising")
				suspicion.update_suspicion_target(self.comp_sus, 1, function(v)
					send_sus_value_to_plrs(self, v)
				end)
			else
				--print("lowering")
				suspicion.update_suspicion_target(self.comp_sus, 0, function(v)
					send_sus_value_to_plrs(self, v)
				end)
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		for _, npc: Npc in pairs(active_npcs) do
			npc.comp_sight.sight_plrs_to_check[plr] = true
		end
	end)
end)

Players.PlayerRemoving:Connect(function(plr)
	for _, npc: Npc in pairs(active_npcs) do
		npc.comp_sight.sight_plrs_to_check[plr] = nil
	end
end)