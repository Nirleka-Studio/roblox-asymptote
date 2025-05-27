--!strict

local controller = {}
controller.__index = controller

export type CharacterController = typeof(setmetatable({} :: {
	read character: Model,
	_process_funcs: { [string]: () -> () }
}, controller))

function controller.create(character: Model): CharacterController
	return setmetatable({
		character = character,
		_process_funcs = {}
	}, controller)
end

function controller.face_at(self: CharacterController, at_dir: Vector3, speed: number): ()
	local root_part = self.character:FindFirstChild("HumanoidRootPart") :: Part
	if not root_part then
		return
	end

	local new_cframe = CFrame.new(root_part.Position) * CFrame.Angles(0, math.atan2(at_dir.X, at_dir.Z), 0)

	self._process_funcs.FaceTo = function()
		root_part.CFrame = root_part.CFrame:Lerp(new_cframe, speed / 2)
	end
end

function controller.stop_all_lerp(self: CharacterController): ()
	self._process_funcs.FaceTo = nil
end

function controller.reset_head_orientation(self: CharacterController): ()

end

local Head = self.Character.Head
	local Torso = self.Character.Torso
	local Neck = Torso.Neck

	local TorsoLV = Torso.CFrame.lookVector
	local HeadPos = Head.CFrame.p

	local Dist = (Head.CFrame.p - position).magnitude
	local Diff = Head.CFrame.Y - position.Y

	local originalC0CFrame = CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0)

	Neck.C0 = Neck.C0:lerp(originalC0CFrame * CFrame.Angles(math.asin(Diff / Dist) * 0.6, 0, (((HeadPos - position).Unit):Cross(TorsoLV)).Y * 1), self._headTurnUpdateSpeed / 2)

return controller