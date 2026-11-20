-- BaseManager.luau (server)
-- Owns the six bases: who holds which, which brainrot stands on which pad, the 60-second base
-- lock (with its energy walls, sign countdown and cooldown), and the base sign boards.
-- The shop buttons (rebirth / upgrades) are wired here too but handed to Economy's actions.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local GameState = require(script.Parent.GameState)
local CharacterFactory = require(script.Parent.CharacterFactory)

local BaseManager = {}

local takenBy = {} -- [baseIndex] = Player

function BaseManager.Init(world, actions)
	for _, base in ipairs(world.Bases) do
		base.Buttons.Lock.Prompt.Triggered:Connect(function(player)
			if takenBy[base.Index] == player then
				BaseManager.TryLock(player)
			else
				GameState.Notify(player, "This is not your base!")
			end
		end)
		base.Buttons.Rebirth.Prompt.Triggered:Connect(function(player)
			if takenBy[base.Index] == player then
				actions.OnRebirth(player)
			else
				GameState.Notify(player, "This is not your base!")
			end
		end)
		base.Buttons.Slap.Prompt.Triggered:Connect(function(player)
			if takenBy[base.Index] == player then
				actions.OnUpgradeSlap(player)
			else
				GameState.Notify(player, "This is not your base!")
			end
		end)
		base.Buttons.Speed.Prompt.Triggered:Connect(function(player)
			if takenBy[base.Index] == player then
				actions.OnUpgradeSpeed(player)
			else
				GameState.Notify(player, "This is not your base!")
			end
		end)
		BaseManager.RefreshSign(base.Index)
	end
	task.spawn(BaseManager.lockLoop)
end

-- Give the player the lowest-numbered free base. Returns the base index, or nil when full.
function BaseManager.AssignBase(player: Player)
	for index = 1, Config.BaseCount do
		if takenBy[index] == nil then
			takenBy[index] = player
			local data = GameState.Get(player)
			if data then
				data.BaseIndex = index
			end
			BaseManager.RefreshSign(index)
			return index
		end
	end
	return nil
end

function BaseManager.ReleaseBase(player: Player)
	local data = GameState.Get(player)
	if data and data.BaseIndex then
		takenBy[data.BaseIndex] = nil
		BaseManager.RefreshSign(data.BaseIndex)
		data.BaseIndex = nil
	end
end

function BaseManager.OwnerOf(baseIndex: number)
	return takenBy[baseIndex]
end

-- Stand an entry on one of the owner's pads (a chosen pad, or the first free one).
-- Registers it for income and swaps its label to show the owner's name.
function BaseManager.PlaceOnPad(data, entry, padIndex)
	padIndex = padIndex or GameState.FreePadIndex(data)
	if padIndex == nil then
		return false
	end
	local base = GameState.World.Bases[data.BaseIndex]
	local feet = base.PadFeet[padIndex]
	CharacterFactory.StopMoving(entry)
	CharacterFactory.SetPose(entry, feet, if base.Facing > 0 then 0 else math.pi, 0, 0)
	entry.LastYaw = if base.Facing > 0 then 0 else math.pi
	entry.State = "placed"
	entry.Owner = data.Player
	entry.PadIndex = padIndex
	data.PadEntries[padIndex] = entry
	CharacterFactory.UpdateLabel(entry, data.Player.DisplayName .. "'s")
	GameState.RecountIncome(data)
	return true
end

-- Lift an entry off its pad (bought-out steals and rebirths go through here).
function BaseManager.RemoveFromPad(entry)
	local owner = entry.Owner
	if owner then
		local data = GameState.Get(owner)
		if data and entry.PadIndex and data.PadEntries[entry.PadIndex] == entry then
			data.PadEntries[entry.PadIndex] = nil
			GameState.RecountIncome(data)
		end
	end
	entry.Owner = nil
	entry.PadIndex = nil
end

function BaseManager.IsLocked(data): boolean
	return os.clock() < data.LockUntil
end

function BaseManager.LockSecondsLeft(data): number
	return math.max(0, math.ceil(data.LockUntil - os.clock()))
end

-- The Lock button (and the HUD button, which routes to the same call).
function BaseManager.TryLock(player: Player)
	local data = GameState.Get(player)
	if not data or not data.BaseIndex then
		return
	end
	local now = os.clock()
	if BaseManager.IsLocked(data) then
		GameState.Notify(player, string.format("Base already locked (%ds left)", BaseManager.LockSecondsLeft(data)))
		return
	end
	if now < data.LockReadyAt then
		GameState.Notify(player, string.format("Lock recharging (%ds)", math.ceil(data.LockReadyAt - now)))
		return
	end
	data.LockUntil = now + Config.LockDuration
	data.LockReadyAt = data.LockUntil + Config.LockCooldown
	GameState.Notify(player, "Base LOCKED for 60 seconds. Nobody can steal from you!")
	BaseManager.RefreshSign(data.BaseIndex)
end

function BaseManager.RefreshSign(baseIndex: number)
	local base = GameState.World.Bases[baseIndex]
	local owner = takenBy[baseIndex]
	local lines = { "BASE " .. baseIndex }
	if owner then
		table.insert(lines, owner.DisplayName)
		local data = GameState.Get(owner)
		if data and BaseManager.IsLocked(data) then
			table.insert(lines, "LOCKED " .. BaseManager.LockSecondsLeft(data) .. "s")
		else
			table.insert(lines, "OPEN")
		end
	else
		table.insert(lines, "VACANT")
	end
	base.SignLabel.Text = table.concat(lines, "\n")
	-- Energy walls follow the lock
	local locked = false
	if owner then
		local data = GameState.Get(owner)
		locked = data ~= nil and BaseManager.IsLocked(data)
	end
	for _, wall in ipairs(base.LockWalls) do
		wall.Transparency = if locked then 0.35 else 1
	end
	-- The lock prompt narrates its own state for the owner walking up to it
	local prompt = base.Buttons.Lock.Prompt
	if owner then
		local data = GameState.Get(owner)
		if data and BaseManager.IsLocked(data) then
			prompt.ObjectText = "Locked: " .. BaseManager.LockSecondsLeft(data) .. "s left"
		elseif data and os.clock() < data.LockReadyAt then
			prompt.ObjectText = "Recharging: " .. math.ceil(data.LockReadyAt - os.clock()) .. "s"
		else
			prompt.ObjectText = "60s steal protection"
		end
	end
end

-- Keeps signs, walls and lock prompts counting down while anyone is locked.
function BaseManager.lockLoop()
	while true do
		task.wait(0.5)
		for index = 1, Config.BaseCount do
			if takenBy[index] then
				BaseManager.RefreshSign(index)
			end
		end
	end
end

return BaseManager
