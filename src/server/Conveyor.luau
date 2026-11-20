-- Conveyor.luau (server)
-- The Brainrot Express: rolls a weighted-random cast member onto the start of the belt every few
-- seconds, walks it down the road, and despawns it at the far end if nobody buys it.
-- Buying is the heart of the game loop: charge the player, reserve a pad on their base, and the
-- brainrot hops off the belt and walks home to its new pad, where income starts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local GameState = require(script.Parent.GameState)
local CharacterFactory = require(script.Parent.CharacterFactory)
local BaseManager = require(script.Parent.BaseManager)
local Economy = require(script.Parent.Economy)
local StealSystem = require(script.Parent.StealSystem)

local Conveyor = {}

local rng = Random.new()
local beltEntries = {} -- entries currently walking the belt, in spawn order
local modelFolder = nil

function Conveyor.Init(world)
	modelFolder = Instance.new("Folder")
	modelFolder.Name = "Brainrots"
	modelFolder.Parent = Workspace
	task.spawn(Conveyor.spawnLoop)
	task.spawn(Conveyor.moveLoop)
end

function Conveyor.AliveCount(): number
	return #beltEntries
end

function Conveyor.spawnLoop()
	while true do
		task.wait(Config.SpawnInterval)
		if #beltEntries < Config.ConveyorMaxAlive then
			Conveyor.SpawnOne()
		end
	end
end

function Conveyor.SpawnOne()
	local world = GameState.World
	local def = BrainrotData.RollSpawn(rng)
	local entry = CharacterFactory.Build(def)
	entry.Model.Parent = modelFolder
	entry.State = "conveyor"
	local startFeet = Vector3.new(Config.BeltStartX, world.BeltTopY, world.BeltZ)
	CharacterFactory.SetPose(entry, startFeet, math.pi / 2, 0, 0)
	entry.LastYaw = math.pi / 2
	CharacterFactory.UpdateLabel(entry, BrainrotData.FormatCash(def.Price))
	CharacterFactory.SetPrompt(entry, "Buy", string.format("%s — %s", def.Name, BrainrotData.FormatCash(def.Price)), function(player)
		Conveyor.TryBuy(player, entry)
	end)
	GameState.RegisterBrainrot(entry)
	table.insert(beltEntries, entry)
end

function Conveyor.moveLoop()
	while true do
		local dt = task.wait()
		for i = #beltEntries, 1, -1 do
			local entry = beltEntries[i]
			if entry.State ~= "conveyor" then
				table.remove(beltEntries, i)
			else
				local feet = CharacterFactory.GetFeet(entry)
				local newX = feet.X + Config.BeltSpeed * dt
				if newX >= Config.BeltEndX then
					table.remove(beltEntries, i)
					GameState.UnregisterBrainrot(entry)
					CharacterFactory.Destroy(entry)
				else
					entry.BobPhase += dt * Config.BeltSpeed * 1.6
					local bobY = math.abs(math.sin(entry.BobPhase)) * 0.28
					local waddle = math.sin(entry.BobPhase) * 0.07
					CharacterFactory.SetPose(entry, Vector3.new(newX, feet.Y, feet.Z), math.pi / 2, bobY, waddle)
				end
			end
		end
	end
end

-- A player pressed Buy on a belt brainrot.
function Conveyor.TryBuy(player: Player, entry)
	if entry.State ~= "conveyor" then
		return
	end
	local data = GameState.Get(player)
	if not data or not data.BaseIndex then
		GameState.Notify(player, "You don't have a base to put it on!")
		return
	end
	local padIndex = GameState.FreePadIndex(data)
	if padIndex == nil then
		GameState.Notify(player, "Your base is FULL (8 brainrots)! Rebirth to start a bigger empire.")
		return
	end
	if not Economy.ChargeForBrainrot(player, entry.Def) then
		return
	end

	-- Reserve the pad, hop off the belt and walk home
	for i, beltEntry in ipairs(beltEntries) do
		if beltEntry == entry then
			table.remove(beltEntries, i)
			break
		end
	end
	entry.State = "walking"
	entry.Owner = player
	entry.PadIndex = padIndex
	data.PadEntries[padIndex] = entry
	CharacterFactory.ClearPrompt(entry)
	CharacterFactory.UpdateLabel(entry, "")
	GameState.Notify(player, string.format("%s is yours! It's walking to your base.", entry.Def.Name))

	local base = GameState.World.Bases[data.BaseIndex]
	local targetFeet = base.PadFeet[padIndex]
	CharacterFactory.WalkTo(entry, targetFeet, 11, function()
		local currentData = GameState.Get(player)
		if not currentData or entry.State ~= "walking" then
			return -- owner left, or the walk was superseded; cleanup owns the model now
		end
		BaseManager.PlaceOnPad(currentData, entry, padIndex)
		StealSystem.AttachStealPrompt(entry)
	end)
end

return Conveyor
