--!strict

local lerper = {}
lerper.__index = lerper

export type LerpObject = typeof(setmetatable({} :: {
	cur_value: number,
	fnl_value: number,
	str_value: number,
	dur: number,
	elapsed: number,
	easing_func: ((number) -> number)?
}, lerper))

function lerper.ease(p_x: number, p_c: number)
	if p_x < 0 then
		p_x = 0
	elseif (p_x > 1.0) then
		p_x = 1.0
	end
	if p_c > 0 then
		if (p_c < 1.0) then
			return 1.0 - math.pow(1.0 - p_x, 1.0 / p_c);
		else
			return math.pow(p_x, p_c);
		end
	elseif (p_c < 0) then
		if p_x < 0.5 then
			return math.pow(p_x * 2.0, -p_c) * 0.5;
		else
			return (1.0 - math.pow(1.0 - (p_x - 0.5) * 2.0, -p_c)) * 0.5 + 0.5;
		end
	else
		return 0
	end
end

function lerper.smoothstep(from: number, to: number, t: number): number
	t = math.clamp(t, 0.0, 1.0)
	t = -2.0 * t * t * t + 3.0 * t * t
	return to * t + from * (1 - t)
end

function lerper.create(from: number, to: number, dur: number, easing_func: ((number) -> number)?): LerpObject
	return setmetatable({
		cur_value = from,
		fnl_value = to,
		str_value = from,
		dur = dur,
		elapsed = 0,
		easing_func = easing_func
	}, lerper)
end

function lerper.step(obj: LerpObject, delta: number)
	if obj.cur_value == obj.fnl_value then
		return
	end

	obj.elapsed += delta

	-- keeps c between 0 and 1.
	local c = math.clamp(obj.elapsed / obj.dur, 0.0, 1.0)
	if obj.easing_func ~= nil then
		c = obj.easing_func(c)
	end
	obj.cur_value = math.lerp(obj.str_value, obj.fnl_value, c)
end

return lerper :: {
	create: typeof(lerper.create),
	ease: typeof(lerper.ease),
	smoothstep: typeof(lerper.smoothstep)
}