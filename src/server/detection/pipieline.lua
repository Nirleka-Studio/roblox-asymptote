--!strict

local pipeline = {}
pipeline.__index = pipeline

type DetectionStrategy = {
	name: string,
	callback: (any) -> DetectionResult
}

export type DetectionResult = {
	detected: boolean,
	player: Player?,
	method: ("sight" | "hearing")?
}

export type DetectionPipeline = typeof(setmetatable({} :: {
	strategies: { DetectionStrategy }
}, pipeline))

function pipeline.new(): DetectionPipeline
	return setmetatable({ strategies = {} }, pipeline)
end

function pipeline.register(self: DetectionPipeline, method: string, callback: (any) -> DetectionResult)
	self.strategies[#self.strategies + 1] = { name = method, callback = callback }
end

function pipeline.run(self: DetectionPipeline, npc: any): DetectionResult
	for _, strat in ipairs(self.strategies) do
		local result = strat.callback(npc)
		if result.detected then
			return result :: DetectionResult
		end
	end
	return { detected = false }
end

return pipeline :: { new: typeof(pipeline.new)}
