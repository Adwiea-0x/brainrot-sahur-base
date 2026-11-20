-- GameState.luau (server)
-- The one home for all runtime state: per-player data and the registry of live brainrot entities.
-- Everything is in memory only — SAHUR BASE never touches DataStore; a server restart is a fresh game.
--
-- A brainrot "entry" is a plain table:
--   { Model, Def, Root, Label, Prompt, State, Owner, PadIndex, Carrier, MoveToken, BobPhase }
--   State: "conveyor" | "walking" | "placed" | "carried" | "returning"
-- A player "data" table mirrors the leaderstats values and holds base, lock, upgrade and carry state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local GameState = {}

GameState.Players = {} -- [Player] = data
GameState.Brainrots = {} -- [entry] = true, every live brainrot entity
GameState.World = nil -- filled by the bootstrap with WorldBuilder's result

function GameState.NewPlayerData(player: Player)
	local data = {
		Player = player,
		Cash = Config.StartCash,
		IncomePerSec = 0,
		Rebirths = 0,
		Multiplier = 1,
		BaseIndex = nil, -- nil while every base is taken
		PadEntries = {}, -- [padIndex] = entry standing on that pad
		LockUntil = 0,
		LockReadyAt = 0,
		SlapLevel = 0,
		SpeedLevel = 0,
		LastSlapAt = 0,
		Carrying = nil, -- entry being carried after a steal
		FullBaseWarnedAt = 0,
	}
	GameState.Players[player] = data
	return data
end

function GameState.Get(player: Player)
	return GameState.Players[player]
end

function GameState.DropPlayer(player: Player)
	GameState.Players[player] = nil
end

function GameState.RegisterBrainrot(entry)
	GameState.Brainrots[entry] = true
end

function GameState.UnregisterBrainrot(entry)
	GameState.Brainrots[entry] = nil
end

-- Server -> client one-off message (the HUD shows it as a toast).
function GameState.Notify(player: Player, text: string)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local notify = remotes and remotes:FindFirstChild("Notify")
	if notify then
		notify:FireClient(player, text)
	end
end

function GameState.NotifyAll(text: string)
	for _, player in ipairs(Players:GetPlayers()) do
		GameState.Notify(player, text)
	end
end

-- Recompute a player's income per second from the brainrots standing on their pads.
-- A pad can be reserved by a brainrot still walking to it; only "placed" ones pay.
function GameState.RecountIncome(data)
	local total = 0
	for _, entry in pairs(data.PadEntries) do
		if entry.State == "placed" then
			total += entry.Def.Income
		end
	end
	data.IncomePerSec = total
end

-- A pad is free when nobody's brainrot stands on it; returns the first free pad index or nil.
function GameState.FreePadIndex(data)
	for padIndex = 1, Config.PadsPerBase do
		if data.PadEntries[padIndex] == nil then
			return padIndex
		end
	end
	return nil
end

return GameState
