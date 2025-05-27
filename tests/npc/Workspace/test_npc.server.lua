--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local hearing = require(game.ServerScriptService.server.detection.hearing)
local suspicion = require(game.ServerScriptService.server.detection.suspicion)
local sight = require(game.ServerScriptService.server.detection.sight)

local REMOTE = game.ReplicatedStorage.remotes.Detection

type Npc = {
	character: Model,
	character_head: BasePart,
	comp_sight: sight.SightComp,
	comp_sus: suspicion.SuspicionComp,
	comp_hearing: hearing.HearingComp,
	detection_type: string | "none" | "hearing" | "sight",
	any_player_detected: boolean,
	focusing_player: Player?,
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
		detection_type = "none",
		any_player_detected = false,
		focusing_player = nil,
	}
end

local function get_detection_state(self: Npc)
	local sight_detected = false
	local hearing_detected = false
	local detected_player = nil

	-- check sight first
	for plr in pairs(self.comp_sight.sight_plrs_to_check) do
		if sight.is_player_visible(self.comp_sight, plr) then
			sight_detected = true
			detected_player = plr
			break
		end
	end

	-- if no sight detection, use hearing
	if not sight_detected then
		for plr in pairs(self.comp_sight.sight_plrs_to_check) do -- or use a separate hearing list
			if hearing.is_player_hearable(self.comp_hearing, plr) then
				hearing_detected = true
				detected_player = plr
				break
			end
		end
	end

	return {
		detected = sight_detected or hearing_detected,
		by_sight = sight_detected,
		by_hearing = hearing_detected,
		player = detected_player
	}
end

local function send_sus_value_to_plrs(self: Npc, sus_value: number)
	if self.focusing_player then
		REMOTE:FireClient(
			self.focusing_player,
			sus_value, self.character,
			self.character_head.Position)
	end
end

for _, npc in ipairs(CollectionService:GetTagged("Test_Npc")) do
	local self = create_npc(npc :: Model)
	active_npcs[npc :: Model] = self
end

RunService.Heartbeat:Connect(function()
	for _, npc in pairs(active_npcs) do
		local self: Npc = npc

		local detection = get_detection_state(self)

		-- only update suspicion when detection state changes
		if detection.detected ~= self.any_player_detected then
			self.any_player_detected = detection.detected

			if detection.detected then
				self.focusing_player = detection.player

				-- useful for debug later.
				if detection.by_sight then
					self.detection_type = "sight"
				elseif detection.by_hearing then
					self.detection_type = "hearing"
				end

				suspicion.update_suspicion_target(self.comp_sus, 1, function(v)
					send_sus_value_to_plrs(self, v)
				end)
			else
				self.detection_type = "none"
				suspicion.update_suspicion_target(self.comp_sus, 0, function(v)
					send_sus_value_to_plrs(self, v)
				end)
			end
		end

		-- handle transitions between sight and hearing
		-- maintains the same suspicion level but updates the detection method
		if detection.detected then
			local new_type = if detection.by_sight then "sight" else "hearing"
			if new_type ~= self.detection_type then
				self.detection_type = new_type
				self.focusing_player = detection.player
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