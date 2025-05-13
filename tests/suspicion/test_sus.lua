
-- sus.

local function ease(p_x, p_c)
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

local function lerp(a, b, t)
	return a + (b - a) * t
end

local cur_value = 0.1
local fur_value = 1
local dur = 10
local elapsed = 0
local function test(dt)
	elapsed += dt

	local c = math.clamp(elapsed / dur, 0.0, 1.0)
	c = ease(c, 1)
	cur_value = lerp(cur_value, fur_value, c)
end

game:GetService("RunService").Heartbeat:Connect(function(dt)
	if cur_value == fur_value then
		return
	end
	script.Parent.SusMeter.Frame.CanvasGroup.Size = UDim2.fromScale(cur_value, 1)
	warn(cur_value)
	test(dt)
end)
