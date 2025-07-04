--!strict

local Players = game:GetService("Players")
local WrappedPlayer = require("../entity/player/WrappedPlayer")

--[=[
	@class Level

	Keeps track of every values relating to the current level, such as
	all players, guards, and alert levels.
]=]
local Level = {}

type WrappedPlayer = WrappedPlayer.WrappedPlayer

local playersInLevel: { [Player]: WrappedPlayer } = {}

function Level.getPlayers(): { WrappedPlayer }
	local players: {any} = table.create(#playersInLevel, true)

	local i = 0
	for _, player in pairs(playersInLevel) do
		i += 1
		players[i] = player
	end

	return players
end

function Level.registerPlayer(player: Player): ()
	if playersInLevel[player] then
		return
	end

	playersInLevel[player] = WrappedPlayer.new(player)
end

function Level.removePlayer(player): ()
	if not playersInLevel[player] then
		return
	end

	playersInLevel[player]:onCharacterRemoving()
end

Players.PlayerAdded:Connect(function(player)
	Level.registerPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	Level.removePlayer(player)
end)

return Level