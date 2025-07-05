# AsymptoteEngine
A full overhaul of the original Asymptote Engine.

## Dillema

### Directories

```
entity/
├─ ai/
│  ├─ memory/
│  │  ├─ ExpireableValue.lua
│  │  ├─ MemoryModuleTypes.lua
│  ├─ sensing/
│  ├─ Brain.lua
├─ player/
│  ├─ WrappedPlayer.lua
├─ Agent.lua
```

### Types and Methods

### Agent

This is the backbone for everything.

```lua
export type HumanoidCharacter = {
	model: Model,
	head: BasePart,
	humanoid: Humanoid,
	primaryPart: BasePart
}
```

```lua
export type Agent = {
	character: HumanoidCharacter
}
```

#### WrappedPlayer

```lua
export type WrappedPlayer = {
	new: (player: Player) -> WrappedPlayer,
	getCharacter: (self: WrappedPlayer) -> Agent.HumanoidCharacter?,
	getPrimaryPartPosition: (self: WrappedPlayer) -> Vector3?,
	isAlive: (self: WrappedPlayer) -> boolean,
	isMoving: (self: WrappedPlayer) -> boolean,
	onCharacterAdded: (self: WrappedPlayer, character: Model) -> (),
	onCharacterRemoving: (self: WrappedPlayer) -> (),
	onHumanoidDied: (self: WrappedPlayer) -> (),
	onPlayerRemoving: (self: WrappedPlayer) -> ()
}
```

`WrappedPlayer` is a way to have a consistent and safe
access to Players' properties.

The connections and managing of `WrappedPlayer` is
already taken care of by the `Level.lua` module.

#### ExpireableValue\<T>

```lua
export type ExpireableValue<T> = {
	new: (value: T, timeToLive: number) -> ExpireableValue<T>,
	nonExpiring: (value: T) -> ExpireableValue<T>,
	getValue: (self: ExpireableValue<T>) -> T?,
	getTimeToLive: (self: ExpireableValue<T>) -> number,
	canExpire: (self: ExpireableValue<T>) -> boolean,
	isExpired: (self: ExpireableValue<T>) -> boolean,
	update: (self: ExpireableValue<T>, delta: number) -> ()
}
```

#### MemoryModuleTypes

`MemoryModuleTypes` is a module that contains the
`MemoryModuleType<T>` type and the registered types.

```lua
export type MemoryModuleType<T> = {
	name: string
}
```

Accessing the module will give you a dictionary of the following. Which is currently unfinished.

```lua
export type MemoryModuleTypes = {
	NEAREST_PLAYER: MemoryModuleType<Player>
	-- and so on
}
```

Please note that this file is for *type checking purposes only.* For the ExpireableValue\<T> class. To prevent type discreprancies such as:

```lua
local function setMemory<T>(memoryType: MemoryModuleType<T>, value: T): ()
	-- ...
end

-- will result in a type error as the value is a string and `NEAREST_PLAYER` is a `MemoryModuleType<Player>`
setMemory(MemoryModuleTypes.NEAREST_PLAYER, "this is a string")
```