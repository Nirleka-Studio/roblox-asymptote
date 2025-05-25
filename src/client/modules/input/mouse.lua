--!strict

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local get_core = require("../core/get_core")

local mouse = {}

local mouse_default_locked: boolean = true
local mouse_locked: boolean = mouse_default_locked
local mouse_default_icon_enabled: boolean = false
local mouse_icon_enabled: boolean = mouse_default_icon_enabled

function mouse._process(): ()
	-- basically `game.StarterGui:GetCore("DevConsoleVisible")`
	-- safely calls it as sometimes during the start, it is not registered yet.
	local _, is_console_visible = get_core.call("StarterGui", "GetCore", "DevConsoleVisible")
	if is_console_visible then
		mouse_icon_enabled = true
		mouse_locked = false
	else
		mouse_icon_enabled = mouse_default_icon_enabled
		mouse_locked = mouse_default_locked
	end

	if mouse_locked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	if mouse_icon_enabled then
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseIconEnabled = false
	end
end

function mouse.set_lock_enabled(locked: boolean): ()
	mouse_default_locked = locked
	mouse_locked = locked
end

function mouse.set_icon_enabled(enabled: boolean): ()
	mouse_default_icon_enabled = enabled
	mouse_icon_enabled = enabled
end

-- we'll take care of this later.
RunService.RenderStepped:Connect(mouse._process)

return mouse