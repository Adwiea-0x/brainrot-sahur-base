-- StealSystem.luau (server)
-- The tension of SAHUR BASE: walk up to someone's base, grab their brainrot, and haul it home
-- on your head while the whole server watches. The owner defends with the slap hand: one good
-- bonk knocks the catch loose and it walks itself home. Locked bases cannot be touched.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local GameState = require(script.Parent.GameState)
local CharacterFactory = require(script.Parent.CharacterFactory)
local BaseManager = require(script.Parent.BaseManager)
local Economy = require(script.Parent.Economy)

local StealSystem = {}

function StealSystem.Init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("Slap").OnServerEvent:Connect(function(player)
		StealSystem.TrySlap(player)
	end)
	task.spawn(StealSystem.carryLoop)
end

-- Every placed brainrot wears a Steal prompt; the callback sorts out whose it is.
function StealSystem.AttachStealPrompt(entry)
	CharacterFactory.SetPrompt(entry, "Steal", entry.Def.Name, function(player)
		StealSystem.TrySteal(player, entry)
	end)
end

function StealSystem.TrySteal(thief: Player, entry)
	if entry.State ~= "placed" then
		return
	end
	local owner = entry.Owner
	if not owner then
		return
	end
	if thief == owner then
		GameState.Notify(thief, "That's your own brainrot!")
		return
	end
	local thiefData = GameState.Get(thief)
	if not thiefData or not thiefData.BaseIndex then
		GameState.Notify(thief, "You need a base to steal to!")
		return
	end
	if thiefData.Carrying then
		GameState.Notify(thief, "You're already carrying a brainrot!")
		return
	end
	local ownerData = GameState.Get(owner)
	if ownerData and BaseManager.IsLocked(ownerData) then
		GameState.Notify(thief, string.format("%s's base is LOCKED (%ds left)!", owner.DisplayName, BaseManager.LockSecondsLeft(ownerData)))
		return
	end

	BaseManager.RemoveFromPad(entry)
	entry.State = "carried"
	entry.Carrier = thief
	entry.OriginalOwner = owner
	thiefData.Carrying = entry
	CharacterFactory.ClearPrompt(entry)
	CharacterFactory.UpdateLabel(entry, "STOLEN!")
	Economy.ApplyWalkSpeed(thiefData)
	GameState.Notify(thief, string.format("You stole %s! RUN it back to your base!", entry.Def.Name))
	GameState.Notify(owner, string.format("%s STOLE your %s! Slap them to knock it loose!", thief.DisplayName, entry.Def.Name))
end

-- The carried brainrot rides on the thief's head; reaching home claims it.
function StealSystem.carryLoop()
	while true do
		task.wait()
		for _, player in ipairs(Players:GetPlayers()) do
			local data = GameState.Get(player)
			if data and data.Carrying then
				StealSystem.updateCarried(player, data, data.Carrying)
			end
		end
	end
end

function StealSystem.updateCarried(thief: Player, data, entry)
	local character = thief.Character
	local head = character and character:FindFirstChild("Head")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not head or not rootPart then
		return
	end
	local look = rootPart.CFrame.LookVector
	local yaw = math.atan2(look.X, look.Z)
	entry.BobPhase += 0.12
	local bobY = math.sin(entry.BobPhase) * 0.12
	local headFeet = head.Position + Vector3.new(0, head.Size.Y / 2 + 0.15, 0)
	CharacterFactory.SetPose(entry, headFeet, yaw, bobY, math.sin(entry.BobPhase) * 0.05)
	entry.LastYaw = yaw

	-- Home turf? Then it's a claim, if a pad is free
	local base = GameState.World.Bases[data.BaseIndex]
	local flat = Vector3.new(rootPart.Position.X - base.Center.X, 0, rootPart.Position.Z - base.Center.Z)
	if flat.Magnitude <= Config.ClaimRadius then
		local padIndex = GameState.FreePadIndex(data)
		if padIndex == nil then
			if os.clock() - data.FullBaseWarnedAt > 4 then
				data.FullBaseWarnedAt = os.clock()
				GameState.Notify(thief, "Your base is FULL — this catch has nowhere to stand!")
			end
			return
		end
		local victim = entry.OriginalOwner
		data.Carrying = nil
		entry.Carrier = nil
		entry.OriginalOwner = nil
		BaseManager.PlaceOnPad(data, entry, padIndex)
		StealSystem.AttachStealPrompt(entry)
		Economy.ApplyWalkSpeed(data)
		GameState.Notify(thief, string.format("%s claimed! It now earns for YOU.", entry.Def.Name))
		if victim and victim ~= thief then
			GameState.Notify(victim, string.format("%s is gone — %s claimed it!", entry.Def.Name, thief.DisplayName))
		end
	end
end

-- Knock a carried brainrot loose: it walks home to its original owner by itself.
function StealSystem.DropCarried(carrierData, entry)
	if carrierData then
		carrierData.Carrying = nil
		Economy.ApplyWalkSpeed(carrierData)
	end
	entry.Carrier = nil
	StealSystem.ReturnHome(entry)
end

-- Send an entry back to its original owner's base (after a drop, or when its carrier leaves).
function StealSystem.ReturnHome(entry)
	local owner = entry.OriginalOwner or entry.Owner
	entry.OriginalOwner = nil
	local ownerData = owner and GameState.Get(owner)
	if not ownerData or not ownerData.BaseIndex then
		GameState.UnregisterBrainrot(entry)
		CharacterFactory.Destroy(entry)
		return
	end
	local padIndex = GameState.FreePadIndex(ownerData)
	if padIndex == nil then
		-- Nowhere for it to stand: it melts into a half-price refund for the owner
		local refund = math.floor(entry.Def.Price / 2)
		Economy.AddCash(ownerData, refund)
		GameState.Notify(owner, string.format("Your base was full, so %s cashed out for %s.", entry.Def.Name, BrainrotData.FormatCash(refund)))
		GameState.UnregisterBrainrot(entry)
		CharacterFactory.Destroy(entry)
		return
	end
	entry.State = "returning"
	entry.Owner = owner
	entry.PadIndex = padIndex
	ownerData.PadEntries[padIndex] = entry
	CharacterFactory.ClearPrompt(entry)
	CharacterFactory.UpdateLabel(entry, "")
	local base = GameState.World.Bases[ownerData.BaseIndex]
	CharacterFactory.WalkTo(entry, base.PadFeet[padIndex], 10, function()
		local currentData = GameState.Get(owner)
		if not currentData or entry.State ~= "returning" then
			return
		end
		BaseManager.PlaceOnPad(currentData, entry, padIndex)
		StealSystem.AttachStealPrompt(entry)
		GameState.Notify(owner, string.format("%s made it back home!", entry.Def.Name))
	end)
end

-- The slap: a short-range bonk. Carriers drop their catch; everyone else just gets shoved.
function StealSystem.TrySlap(player: Player)
	local data = GameState.Get(player)
	if not data then
		return
	end
	local now = os.clock()
	if now - data.LastSlapAt < Config.SlapCooldown then
		return
	end
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then
		return
	end
	data.LastSlapAt = now
	local power, radius = Economy.SlapStats(data)
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local delta = otherRoot.Position - myRoot.Position
				local flat = Vector3.new(delta.X, 0, delta.Z)
				if flat.Magnitude <= radius and math.abs(delta.Y) < 6 then
					local dir = if flat.Magnitude > 0.01 then flat / flat.Magnitude else Vector3.new(0, 0, 1)
					otherRoot.AssemblyLinearVelocity = Vector3.new(dir.X * power, 13, dir.Z * power)
					local otherData = GameState.Get(other)
					if otherData and otherData.Carrying then
						local dropped = otherData.Carrying
						StealSystem.DropCarried(otherData, dropped)
						GameState.Notify(player, string.format("BONK! You knocked %s loose!", dropped.Def.Name))
						GameState.Notify(other, "You got SLAPPED and dropped the brainrot!")
					end
				end
			end
		end
	end
end

-- The slap hand itself: a chunky white glove built from parts, handed out on every spawn.
function StealSystem.GiveSlapTool(player: Player)
	local backpack = player:WaitForChild("Backpack", 5)
	if not backpack then
		return
	end
	if backpack:FindFirstChild("SlapHand") or (player.Character and player.Character:FindFirstChild("SlapHand")) then
		return
	end
	local tool = Instance.new("Tool")
	tool.Name = "SlapHand"
	tool.ToolTip = "Slap a thief to knock their stolen brainrot loose!"
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1.25, 1.5, 0.45)
	handle.Color = Color3.fromRGB(250, 250, 250)
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local fingerOffsets = { -0.48, -0.16, 0.16, 0.48 }
	for i, fx in ipairs(fingerOffsets) do
		local finger = Instance.new("Part")
		finger.Name = "Finger" .. i
		finger.Size = Vector3.new(0.26, 0.62, 0.4)
		finger.Color = Color3.fromRGB(250, 250, 250)
		finger.CanCollide = false
		finger.Massless = true
		finger.CFrame = handle.CFrame * CFrame.new(fx, 1.05, 0)
		finger.Parent = tool
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = finger
		weld.Parent = finger
	end
	local thumb = Instance.new("Part")
	thumb.Name = "Thumb"
	thumb.Size = Vector3.new(0.55, 0.28, 0.4)
	thumb.Color = Color3.fromRGB(250, 250, 250)
	thumb.CanCollide = false
	thumb.Massless = true
	thumb.CFrame = handle.CFrame * CFrame.new(0.85, -0.1, 0) * CFrame.Angles(0, 0, math.rad(-30))
	thumb.Parent = tool
	local thumbWeld = Instance.new("WeldConstraint")
	thumbWeld.Part0 = handle
	thumbWeld.Part1 = thumb
	thumbWeld.Parent = thumb

	tool.Parent = backpack
end

return StealSystem
