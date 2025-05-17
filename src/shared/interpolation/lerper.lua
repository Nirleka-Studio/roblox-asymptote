export type LerpObject = {
	cur_value: number,
	fnl_value: number,
	dur: number,
	elapsed: number,
	easing_func: (number) -> number
}

local lerper = {}

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

function lerper.create(
	start_value: number,
	final_value: number,
	dur: number,
	easing_func: ((number) -> number)?
): LerpObject
	return {
		cur_value = start_value,
		fnl_value = final_value,
		dur = dur,
		elapsed = 0,
		easing_func = easing_func
	} :: LerpObject
end

function lerper.step(obj: LerpObject, delta: number, step_func: (cur_value: number) -> ()?)
	if obj.cur_value == obj.fnl_value then
		return
	end

	obj.elapsed += delta

	local c = math.clamp(obj.elapsed / obj.dur, 0.0, 1.0)
	if obj.easing_func then
		c = obj.easing_func(c, obj.p_x)
	end
	obj.cur_value = math.lerp(obj.cur_value, obj.fnl_value, c) -- omg the luau team added math.lerp???? since when????

	if step_func then
		step_func(obj.cur_value)
	end
end

return lerper