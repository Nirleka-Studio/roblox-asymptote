--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local sight = require(game.ServerScriptService.server.detection.sight)
local timeline = require(game.ReplicatedStorage.shared.interpolation.timeline)

local REMOTE = game.ReplicatedStorage.remotes.Detection

type Npc = {
	character: Model,
	character_head: BasePart,
	comp_sight: sight.SightComp,
	sus_raise_speed: number,
	sus_decay_speed: number,
	hearing_radius: number,
	detection_type: string | "none" | "hearing" | "sight",
	current_sus: number,
	target_sus: number,
	timeline_sus: timeline.Timeline,
	any_player_detected: boolean,
	focusing_player: Player?
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
		sus_raise_speed = 1/3,
		sus_decay_speed = 1/5,
		hearing_radius = 15,
		detection_type = "none",
		current_sus = 0,
		target_sus = 0,
		timeline_sus = timeline.create(0, 0, 1),
		any_player_detected = false,
		focusing_player = nil
	}
end

local function update_suspicion_target(self: Npc, new_target: number)
	if new_target == self.target_sus then
		return
	end
	self.target_sus = new_target
	local suspicion_difference = math.abs(new_target - self.current_sus)
	local duration
	if new_target > self.current_sus then
		duration = suspicion_difference / self.sus_raise_speed
	else
		duration = suspicion_difference / self.sus_decay_speed
	end
	-- this should've been handled by the timeline itself but fuck it at this point.
	self.timeline_sus = timeline.create(self.current_sus, new_target, duration)
	self.timeline_sus.step:Connect(function()
		self.current_sus = self.timeline_sus.current_value
		if self.focusing_player then
			REMOTE:FireClient(
				self.focusing_player,
				self.current_sus, self.character,
				self.character_head.Position)
		end
	end)
	self.timeline_sus:play_from_start()
end

local function is_player_in_hearing_range(self: Npc, player: Player)
	-- stupid checks for the sake of the typechecker.
	if not player.Character then
		return false
	end
	local root_part = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not root_part then
		return false
	end

	local distance = (self.character_head.Position - root_part.Position).Magnitude
	return distance <= self.hearing_radius -- You'll need to define this property
end

local function is_player_hearable(player: Player)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return false
	end

	local humanoid = player.Character:FindFirstChild("Humanoid") :: Humanoid -- istg.
	return humanoid:GetMoveVelocity().Magnitude > 0
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
			if is_player_in_hearing_range(self, plr) and is_player_hearable(plr) then
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

for _, npc in ipairs(CollectionService:GetTagged("Test_Npc")) do
	local self = create_npc(npc :: Model)
	active_npcs[npc :: Model] = self

	self.timeline_sus.step:Connect(function()
		self.current_sus = self.timeline_sus.current_value
	end)
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

				update_suspicion_target(self, 1)
			else
				self.detection_type = "none"
				update_suspicion_target(self, 0)
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