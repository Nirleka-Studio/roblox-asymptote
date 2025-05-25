--!strict

--[=[
	Fully typed version of the GoodSignal module by Mark Langen.
	Now no need to worry what values your signals return.

	```lua
	local new_signal: Signal<number, boolean> = Signal.new()

	new_signal:Connect(function(x: number, y: boolean) -- parameter types recognised
		-- some code
	end)

	new_signal:Fire(function()
		return 3071, true -- even if we return the wrong types,
	                      -- the type solver will complain
	end)
	```
]=]

export type Connection<T...> = {
	_connected: boolean,
	_signal: Signal<T...>,
	_callback: (T...) -> (),
	_next: Connection<T...> | false,
	Disconnect: (self: Connection<T...>) -> (),
}

export type Signal<T...> = {
	_handlerListHead: Connection<T...> | false,
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection<T...>,
	DisconnectAll: (self: Signal<T...>) -> (),
	Fire: (self: Signal<T...>, ...any) -> (),
	Wait: (self: Signal<T...>) -> (),
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection<T...>
}

----------

local freeRunnerThread: thread? = nil

local function acquireRunnerThreadAndCallEventHandler<T...>(callback: (T...) -> (), ...: T...): ()
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	callback(...)
	freeRunnerThread = acquiredRunnerThread
end

local function runEventHandlerInFreeThread(): ()
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

----------

local Connection = {}
Connection.__index = Connection

function Connection.new<T...>(signal: Signal<T...>, callback: (T...) -> ()): Connection<T...>
	return setmetatable({
		_connected = true,
		_signal = signal,
		_callback = callback,
		_next = false,
	}, Connection) :: Connection<T...>
end

function Connection.Disconnect<T...>(self: Connection<T...>): ()
	self._connected = false

	if self._signal._handlerListHead == self then
		self._signal._handlerListHead = self._next
	else
		local prev = self._signal._handlerListHead
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
end

setmetatable(Connection, {
	__index = function(tb, key)
		error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(tb, key, value)
		error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end
})

----------

local Signal = {}
Signal.__index = Signal

function Signal.new(): Signal<...any> -- leave it to type `any` as it will be refined eitherway
	return setmetatable({
		_handlerListHead = false,
	}, Signal) :: Signal<...any>
end

function Signal.Connect<T...>(self: Signal<T...>, callback: (T...) -> ())
	local connection = Connection.new(self, callback)
	if self._handlerListHead then
		connection._next = self._handlerListHead
		self._handlerListHead = connection
	else
		self._handlerListHead = connection :: any -- luau type solver bug. eh.
	end
	return connection
end

function Signal.DisconnectAll<T...>(self: Signal<T...>)
	self._handlerListHead = false
end

function Signal.Fire<T...>(self: Signal<T...>, ...: T...)
	local item = self._handlerListHead
	while item do
		if item._connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
				coroutine.resume(freeRunnerThread :: thread)
			end
			task.spawn(freeRunnerThread :: thread, item._callback, ...)
		end
		item = item._next
	end
end

function Signal.Wait<T...>(self: Signal<T...>)
	local waitingCoroutine = coroutine.running()
	local connection: Connection<T...>
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(waitingCoroutine, ...)
	end)
	return coroutine.yield()
end

function Signal.Once<T...>(self: Signal<T...>, callback: (T...) -> ())
	local cn: Connection<T...>
	cn = self:Connect(function(...)
		if cn._connected then
			cn:Disconnect()
		end
		callback(...)
	end)
	return cn
end

setmetatable(Signal, {
	__index = function(tb, key)
		error(("Attempt to get Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(tb, key, value)
		error(("Attempt to set Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end
})

return Signal :: { -- only exposes constructor
	new: () -> Signal<...any>
}