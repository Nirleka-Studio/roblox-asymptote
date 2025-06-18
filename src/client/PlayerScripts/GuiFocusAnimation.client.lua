--!strict

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RTween = require(ReplicatedStorage.shared.interpolation.rtween)

local currentCamera = workspace.CurrentCamera
local mainRtween = RTween.create(Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
mainRtween:set_parallel(true)

local window_focused = true
local menu_open = false

type RTweenAnimation = {
	instance: Instance,
	properties: RTween.PropertyParam,
	duration: number
}

local function instantiate(instanceName: string, parent: Instance, properties: { [string]: any }?): Instance
	local inst = Instance.new(instanceName) :: any
	if properties then
		for propertyName, propertyValue in pairs(properties) do
			inst[propertyName] = propertyValue
		end
	end
	inst.Parent = parent
	return inst
end

local EFFECTS_OBJECTS = {
	Blur = instantiate("BlurEffect", currentCamera, {Size = 0}),
	CC = instantiate("ColorCorrectionEffect", currentCamera),
	CCOcclude = instantiate("ColorCorrectionEffect", currentCamera)
}

local FOCUS_CHANGE_ANIMATIONS = {
	FOCUS_ACQUIRED = {
		{
			instance = EFFECTS_OBJECTS.Blur,
			properties = { Size = 0 },
			duration = .5
		},
		{
			instance = EFFECTS_OBJECTS.CC,
			properties = { Contrast = 0, Saturation = 0 },
			duration = .5
		},
		{
			instance = currentCamera,
			properties = { FieldOfView = 70 }, -- TODO: MAKE THIS DYNAMICALLY GO TO THE PREVIOUS FOV VALUE
			duration = 1
		},
	} :: {RTweenAnimation},
	FOCUS_RELEASED = {
		{
			instance = EFFECTS_OBJECTS.Blur,
			properties = { Size = 16 },
			duration = .5
		},
		{
			instance = EFFECTS_OBJECTS.CC,
			properties = { Contrast = 1, Saturation = -1 },
			duration = .5
		},
		{
			instance = currentCamera,
			properties = { FieldOfView = 60 }, -- TODO: MAKE THIS DYNAMICALLY GO TO THE PREVIOUS FOV VALUE
			duration = 1
		},
	} :: {RTweenAnimation}
}

local function animate(animations: { RTweenAnimation }): ()
	local isPlaying = mainRtween.is_playing -- fuck you typechecker
	if isPlaying then
		mainRtween:kill()
	end

	for _, animation in ipairs(animations) do
		mainRtween:tween_instance(animation.instance, animation.properties, animation.duration)
	end
	mainRtween:play()
end

local function onFocusChange(): ()
	local animation
	if not menu_open and window_focused then
		animation = FOCUS_CHANGE_ANIMATIONS.FOCUS_ACQUIRED
	else
		animation = FOCUS_CHANGE_ANIMATIONS.FOCUS_RELEASED
	end

	animate(animation)
end

if GuiService.MenuIsOpen then
	menu_open = true
	onFocusChange()
end

GuiService.MenuOpened:Connect(function()
	menu_open = true
	onFocusChange()
end)

GuiService.MenuClosed:Connect(function()
	menu_open = false
	onFocusChange()
end)

UserInputService.WindowFocused:Connect(function()
	window_focused = true
	onFocusChange()
end)

UserInputService.WindowFocusReleased:Connect(function()
	window_focused = false
	onFocusChange()
end)