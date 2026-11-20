-- Economy.luau (server)
-- Money and progression: leaderstats, the per-second income tick (with the rebirth multiplier),
-- brainrot purchases, the Rebirth itself, and the slap / speed upgrade ladders.
-- BaseManager's buttons and the HUD both end up calling the Do* functions here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local GameState = require(script.Parent.GameState)
local CharacterFactory = require(script.Parent.CharacterFactory)

local Economy = {}

function Economy.Init()
	task.spawn(function()
		while true do
			task.wait(Config.IncomeTickSeconds)
			Economy.tick()
		end
	end)
end

-- leaderstats: the classic Roblox leaderboard trio, mirrored from GameState every change.
function Economy.CreateLeaderstats(player: Player, data)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = data.Cash
	cash.Parent = folder
	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = folder
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = folder
	folder.Parent = player
	data.Leaderstats = folder
end

function Economy.SyncLeaderstats(data)
	local folder = data.Leaderstats
	if not folder then
		return
	end
	folder.Cash.Value = math.floor(data.Cash)
	folder.Income.Value = math.floor(data.IncomePerSec * data.Multiplier)
	folder.Rebirths.Value = data.Rebirths
end

function Economy.AddCash(data, amount: number)
	data.Cash += amount
	Economy.SyncLeaderstats(data)
end

-- Spend if affordable; returns whether the purchase went through.
function Economy.SpendCash(data, amount: number): boolean
	if data.Cash < amount then
		return false
	end
	data.Cash -= amount
	Economy.SyncLeaderstats(data)
	return true
end

-- The conveyor's till: full price, or a friendly refusal.
function Economy.ChargeForBrainrot(player: Player, def): boolean
	local data = GameState.Get(player)
	if not data then
		return false
	end
	if not Economy.SpendCash(data, def.Price) then
		GameState.Notify(player, string.format("Not enough cash! %s costs %s.", def.Name, BrainrotData.FormatCash(def.Price)))
		return false
	end
	return true
end

function Economy.tick()
	for _, player in ipairs(Players:GetPlayers()) do
		local data = GameState.Get(player)
		if data then
			if data.IncomePerSec > 0 then
				Economy.AddCash(data, data.IncomePerSec * data.Multiplier * Config.IncomeTickSeconds)
			else
				Economy.SyncLeaderstats(data)
			end
			Economy.pushHudState(data)
		end
	end
end

-- Everything the HUD cannot read from leaderstats: multiplier, lock countdown, carry state, prices.
function Economy.pushHudState(data)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local hudState = remotes and remotes:FindFirstChild("HudState")
	if not hudState then
		return
	end
	local now = os.clock()
	hudState:FireClient(data.Player, {
		Multiplier = data.Multiplier,
		LockLeft = math.max(0, math.ceil(data.LockUntil - now)),
		LockCooldownLeft = math.max(0, math.ceil(data.LockReadyAt - now)),
		Carrying = data.Carrying ~= nil,
		RebirthCost = Economy.RebirthCost(data),
		SlapLevel = data.SlapLevel,
		SpeedLevel = data.SpeedLevel,
	})
end

-- Walk speed follows the speed upgrades — unless the player is hauling a stolen brainrot.
function Economy.ApplyWalkSpeed(data)
	local character = data.Player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if data.Carrying then
		humanoid.WalkSpeed = Config.CarrySpeed
	else
		local upgrade = Config.SpeedUpgrades[data.SpeedLevel]
		humanoid.WalkSpeed = if upgrade then upgrade.Speed else Config.BaseWalkSpeed
	end
end

function Economy.SlapStats(data): (number, number)
	local upgrade = Config.SlapUpgrades[data.SlapLevel]
	if upgrade then
		return upgrade.Power, upgrade.Radius
	end
	return Config.SlapBasePower, Config.SlapBaseRadius
end

function Economy.RebirthCost(data): number
	return Config.RebirthBaseCost * (data.Rebirths + 1)
end

-- Rebirth: cash and the whole collection go, the permanent multiplier stays (and grows).
function Economy.DoRebirth(player: Player)
	local data = GameState.Get(player)
	if not data or not data.BaseIndex then
		GameState.Notify(player, "You need a base to rebirth!")
		return
	end
	local cost = Economy.RebirthCost(data)
	if data.Cash < cost then
		GameState.Notify(player, string.format("Rebirth needs %s — you have %s.", BrainrotData.FormatCash(cost), BrainrotData.FormatCash(data.Cash)))
		return
	end
	-- Clear every placed brainrot
	local placed = {}
	for padIndex, entry in pairs(data.PadEntries) do
		placed[padIndex] = entry
	end
	for _, entry in pairs(placed) do
		GameState.UnregisterBrainrot(entry)
		CharacterFactory.Destroy(entry)
	end
	data.PadEntries = {}
	data.Rebirths += 1
	data.Multiplier = 1 + Config.RebirthMultiplierStep * data.Rebirths
	data.Cash = Config.StartCash
	GameState.RecountIncome(data)
	Economy.SyncLeaderstats(data)
	Economy.RefreshShopPrompts(data)
	Economy.pushHudState(data)
	GameState.Notify(player, string.format("REBIRTH! Income multiplier is now x%.1f — rebuild your empire!", data.Multiplier))
	GameState.NotifyAll(string.format("%s just rebirthed (x%.1f income)!", player.DisplayName, data.Multiplier))
end

function Economy.DoUpgradeSlap(player: Player)
	local data = GameState.Get(player)
	if not data then
		return
	end
	local nextLevel = data.SlapLevel + 1
	local upgrade = Config.SlapUpgrades[nextLevel]
	if not upgrade then
		GameState.Notify(player, "Slap is already MAX level!")
		return
	end
	if not Economy.SpendCash(data, upgrade.Cost) then
		GameState.Notify(player, string.format("Slap level %d costs %s.", nextLevel, BrainrotData.FormatCash(upgrade.Cost)))
		return
	end
	data.SlapLevel = nextLevel
	Economy.RefreshShopPrompts(data)
	Economy.pushHudState(data)
	GameState.Notify(player, string.format("Slap upgraded to level %d! Bigger radius, harder bonk.", nextLevel))
end

function Economy.DoUpgradeSpeed(player: Player)
	local data = GameState.Get(player)
	if not data then
		return
	end
	local nextLevel = data.SpeedLevel + 1
	local upgrade = Config.SpeedUpgrades[nextLevel]
	if not upgrade then
		GameState.Notify(player, "Speed is already MAX level!")
		return
	end
	if not Economy.SpendCash(data, upgrade.Cost) then
		GameState.Notify(player, string.format("Speed level %d costs %s.", nextLevel, BrainrotData.FormatCash(upgrade.Cost)))
		return
	end
	data.SpeedLevel = nextLevel
	Economy.ApplyWalkSpeed(data)
	Economy.RefreshShopPrompts(data)
	Economy.pushHudState(data)
	GameState.Notify(player, string.format("Speed upgraded to level %d (%d studs/s)!", nextLevel, upgrade.Speed))
end

-- Keep the base shop pads honest about what the next level costs.
function Economy.RefreshShopPrompts(data)
	if not data.BaseIndex then
		return
	end
	local base = GameState.World.Bases[data.BaseIndex]
	base.Buttons.Rebirth.Prompt.ObjectText = "Costs " .. BrainrotData.FormatCash(Economy.RebirthCost(data))
	local slapNext = Config.SlapUpgrades[data.SlapLevel + 1]
	base.Buttons.Slap.Prompt.ObjectText = if slapNext
		then string.format("Lv %d — %s", data.SlapLevel + 1, BrainrotData.FormatCash(slapNext.Cost))
		else "MAX level"
	local speedNext = Config.SpeedUpgrades[data.SpeedLevel + 1]
	base.Buttons.Speed.Prompt.ObjectText = if speedNext
		then string.format("Lv %d — %s", data.SpeedLevel + 1, BrainrotData.FormatCash(speedNext.Cost))
		else "MAX level"
end

return Economy
