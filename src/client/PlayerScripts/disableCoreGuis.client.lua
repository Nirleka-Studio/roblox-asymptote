--!strict

--[=[
	Disables some Roblox's CoreGui.
]=]

local get_core = require("./modules/core/get_core")

--[=[
	safely calls
	```lua
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	```
]=]
get_core.call("StarterGui", "SetCoreGuiEnabled", Enum.CoreGuiType.All, false)