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
	current_sus: number,
	target_sus: number,
	timeline_sus: timeline.Timeline,
	any_player_visible: boolean,
	focusing_player: Player?
}

local new_config: sight.SightConfig = {
	sight_radius = 50,
	peripheral_vision_angle = 90,
	min_glass_trans = 0.5,
	angle_deg = 10,
	num_rays = 5
}

local active_npcs: { Npc } = {}

local function create_npc(character: Model): Npc
	local head = character:FindFirstChild("Head") :: BasePart
	return {
		character = character,
		character_head = head, -- for the sake of type checker
		comp_sight = sight.create_comp(head, new_config),
		sus_raise_speed = 1/3,
		sus_decay_speed = 1/5,
		current_sus = 0,
		target_sus = 0,
		timeline_sus = timeline.create(0, 0, 1),
		any_player_visible = false,
		focusing_player = nil
	}
end

local function update_suspicion_target(self: Npc, new_target: number)
	if new_target == self.target_sus then
		return -- No change needed
	end

	self.target_sus = new_target
	local suspicion_difference = math.abs(new_target - self.current_sus)

	-- Calculate duration based on whether we're raising or lowering suspicion
	local duration
	if new_target > self.current_sus then
		-- Raising suspicion - use raise speed
		duration = suspicion_difference / self.sus_raise_speed
	else
		-- Lowering suspicion - use decay speed
		duration = suspicion_difference / self.sus_decay_speed
	end

	-- Create a new timeline from current position to target
	self.timeline_sus = timeline.create(self.current_sus, new_target, duration)
	self.timeline_sus.step:Connect(function()
		self.current_sus = self.timeline_sus.current_value
		--print("Suspicion level:", current_suspicion)
		if self.focusing_player then
			REMOTE:FireClient(
				self.focusing_player,
				self.current_sus, self.character,
				self.character_head.Position)
		end
	end)

	self.timeline_sus:play_from_start()
end

for _, npc in ipairs(CollectionService:GetTagged("Test_Npc")) do
	local self = create_npc(npc :: Model)

	self.timeline_sus.step:Connect(function()
		self.current_sus = self.timeline_sus.current_value
	end)


end

RunService.Heartbeat:Connect(function()
	for npc in pairs(active_npcs) do
		local self: Npc = npc -- for some reason npc gets refined to number.
		-- Determine if ANY player is currently visible
		local new_any_player_visible = false

		for plr in pairs(self.comp_sight.sight_plrs_to_check) do
			if sight.is_player_visible(self.comp_sight, plr) then
				new_any_player_visible = true
				self.focusing_player = plr
				break -- No need to check other players once we find one
			end
		end

		-- Only update suspicion when visibility state changes
		if new_any_player_visible ~= self.any_player_visible then
			self.any_player_visible = new_any_player_visible

			if self.any_player_visible then
				update_suspicion_target(self, 1) -- Raise suspicion to maximum
			else
				update_suspicion_target(self, 0) -- Lower suspicion to minimum
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		for npc: Npc in pairs(active_npcs :: {Npc}) do -- SOMEONE TELL ME ON WHAT GOD'S GREEN EARTH WHERE NPC GETS REFINED TO NUMBER?!
			npc.comp_sight.sight_plrs_to_check[plr] = true
		end
	end)
end)

Players.PlayerRemoving:Connect(function(plr)
	for npc: Npc in pairs(active_npcs) do
		npc.comp_sight.sight_plrs_to_check[plr] = nil
	end
end)