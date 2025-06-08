--!strict

local function get_plr_root_part(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end

	local root_part = character:FindFirstChild("HumanoidRootPart")
	if not root_part then
		return nil
	end

	return root_part :: BasePart
end

local function get_agent_parts(agent: Instance?): (BasePart?, BasePart?)
	if not agent then
		return nil, nil
	end

	local root_part = agent:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root_part then
		return nil, nil
	end

	local head = agent:FindFirstChild("Head") :: BasePart?
	if not head then
		return nil, nil
	end

	return head, root_part
end

return {
	get_plr_root_part = get_plr_root_part,
	get_agent_parts = get_agent_parts
}