--!strict

local Agent = require("../../Agent")
local Level = require("../../../level/Level")

--[=[
	@class PlayerNearbySensor

	Detects if players is within or outside a specified range.
]=]
local PlayerNearbySensor = {}
PlayerNearbySensor.__index = PlayerNearbySensor

type Agent = Agent.Agent

export type PlayerNearbySensor = typeof(setmetatable({} :: {
	agent: Agent,
	insideRange: number,
	outsideRange: number,
	mustHaveLos: boolean,
	--
	scanRate: number,
	timeToUpdate: number
}, PlayerNearbySensor))

function PlayerNearbySensor.create(
	agent: Agent,
	insideRange: number?,
	outsideRange: number?,
	mustHaveLos: boolean?
): PlayerNearbySensor

	return setmetatable({
		agent = agent,
		insideRange = insideRange or 20,
		outsideRange = outsideRange or 25,
		mustHaveLos = mustHaveLos or true,
		scanRate = 20,
		timeToUpdate = 0
	}, PlayerNearbySensor)
end

function PlayerNearbySensor.update(self: PlayerNearbySensor, delta: number?): ()
	-- FIXME: Not fundementally flawed, but may come as an issue
	-- since all of these will be running on the server, we would assume that the
	-- executions per second will be somewhat stable (x to doubt)
	-- but may come as a problem when that drops or increases.
	self.timeToUpdate -= 1
	if self.timeToUpdate <= 0 then
		self.timeToUpdate = self.scanRate
		self:doUpdate()
	end
end

function PlayerNearbySensor.doUpdate(self: PlayerNearbySensor): ()
	local players = Level.getPlayers()
	local detectedPlayers: {Player} = {}

	for _, player in ipairs(players) do
		local character = player:getCharacter()
		if not character then
			continue
		end

		if (character.primaryPart.Position - self.agent.character.primaryPart.Position).Magnitude <= self.insideRange then
			table.insert(detectedPlayers, player.playerInst)
		end
	end

	print(detectedPlayers)
end

return PlayerNearbySensor