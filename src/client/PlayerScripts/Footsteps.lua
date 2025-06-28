
local localPlayer = game.Players.LocalPlayer
local playerInst = game:GetService("Players"):FindFirstChild(localPlayer.Name) :: Player
local footstepSounds = game.SoundService.FootstepSounds
local currentFootstepSound = script.Parent.R6ProceduralAnimations.FootStepSound

local humanoidConnection: RBXScriptConnection

local function onCharacterAdded(character)
	local humanoid: Humanoid = character:FindFirstChild("Humanoid")
	humanoidConnection = humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
		if humanoid.FloorMaterial == Enum.Material.Air then
			--print("it was fucking air")
			return
		end
		local materialName = humanoid.FloorMaterial.Name
		--print("current humanoid floor material:", materialName)
		if materialName == "SmoothPlastic" then
			materialName = "Plastic"
		end
		local sound = footstepSounds:FindFirstChild(materialName)
		--print("finding child of footstepsound:", sound)
		currentFootstepSound.Value = sound
		--print(sound)
	end)
end

if playerInst.Character then
	onCharacterAdded(playerInst.Character)
end

playerInst.CharacterAdded:Connect(onCharacterAdded)

playerInst.CharacterRemoving:Connect(function()
	humanoidConnection:Disconnect()
end)
