--!strict

local pipeline = {}
pipeline.__index = pipeline

type DetectionStrategy<T> = {
	name: string,
	callback: (T) -> DetectionResult
}

export type DetectionResult = {
	detected: boolean,
	player: Player | nil,
	method: ("sight" | "hearing") | nil
}

export type DetectionPipeline<T> = typeof(setmetatable({} :: {
	strategies: { DetectionStrategy<T> }
}, pipeline))

function pipeline.create(): DetectionPipeline<any>
	return setmetatable({ strategies = {} }, pipeline)
end

function pipeline.register<T>(self: DetectionPipeline<T>, method: string, callback: (T) -> DetectionResult)
	self.strategies[#self.strategies + 1] = { name = method, callback = callback }
end

function pipeline.run<T>(self: DetectionPipeline<T>, npc: any): DetectionResult
	for _, strat in ipairs(self.strategies) do
		local result = strat.callback(npc)
		if result.detected then
			return result :: DetectionResult
		end
	end
	return { detected = false }
end

return pipeline :: { create: typeof(pipeline.create)}
