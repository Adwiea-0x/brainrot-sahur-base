-- init.server.luau (server bootstrap) — "GameServer" in ServerScriptService
-- SAHUR BASE — Steal a Brainrot. Builds the world, wires the systems together, and runs the
-- player lifecycle: join (data, leaderstats, a base, a slap hand), spawn (teleport home),
-- leave (collection destroyed, stolen catch sent home, base freed).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameState = require(script.GameState)
local WorldBuilder = require(script.WorldBuilder)
local CharacterFactory = require(script.CharacterFactory)
local BaseManager = require(script.BaseManager)
local Economy = require(script.Economy)
local Conveyor = require(script.Conveyor)
local StealSystem = require(script.StealSystem)

-- The world comes first: every system navigates by its layout table
local world = WorldBuilder.Build()
GameState.World = world

-- Load the real Creator Store character models (sanitized + normalized) before the
-- conveyor starts spawning; anything that fails keeps its part-built recipe.
CharacterFactory.Prepare()

BaseManager.Init(world, {
	OnRebirth = Economy.DoRebirth,
	OnUpgradeSlap = Economy.DoUpgradeSlap,
	OnUpgradeSpeed = Economy.DoUpgradeSpeed,
})
Economy.Init()
Conveyor.Init(world)
StealSystem.Init()

-- HUD buttons route to the same server calls as the physical base pads
local hudAction = ReplicatedStorage.Remotes.HudAction
hudAction.OnServerEvent:Connect(function(player, action)
	if action == "lock" then
		BaseManager.TryLock(player)
	elseif action == "rebirth" then
		Economy.DoRebirth(player)
	end
end)

local function onCharacterAdded(player: Player, character: Model)
	local data = GameState.Get(player)
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if rootPart and data and data.BaseIndex then
		local base = world.Bases[data.BaseIndex]
		local spawnPos = base.SpawnPos + Vector3.new(0, 3.2, 0)
		rootPart.CFrame = CFrame.lookAt(spawnPos, spawnPos + Vector3.new(0, 0, base.Facing))
	end
	if data then
		Economy.ApplyWalkSpeed(data)
	end
	StealSystem.GiveSlapTool(player)
end

local function onPlayerAdded(player: Player)
	local data = GameState.NewPlayerData(player)
	Economy.CreateLeaderstats(player, data)
	local baseIndex = BaseManager.AssignBase(player)
	if baseIndex then
		Economy.RefreshShopPrompts(data)
		GameState.Notify(player, string.format("Welcome to SAHUR BASE! You own BASE %d. Buy brainrots from the belt!", baseIndex))
	else
		GameState.Notify(player, "All 6 bases are taken in this server — hang around, slap some thieves!")
	end
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player: Player)
	local data = GameState.Get(player)
	if not data then
		return
	end
	-- A stolen brainrot they were carrying goes home to its owner
	if data.Carrying then
		local entry = data.Carrying
		data.Carrying = nil
		entry.Carrier = nil
		StealSystem.ReturnHome(entry)
	end
	-- Their whole collection (standing, walking or returning) leaves with them
	local owned = {}
	for _, entry in pairs(data.PadEntries) do
		table.insert(owned, entry)
	end
	data.PadEntries = {}
	for _, entry in ipairs(owned) do
		GameState.UnregisterBrainrot(entry)
		CharacterFactory.Destroy(entry)
	end
	BaseManager.ReleaseBase(player)
	GameState.DropPlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("[SahurBase] SAHUR BASE — Steal a Brainrot is live: 6 bases, conveyor running.")
