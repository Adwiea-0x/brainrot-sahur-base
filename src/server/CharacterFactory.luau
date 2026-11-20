-- CharacterFactory.luau (server)
-- Builds a brainrot character Model out of plain Parts from its BrainrotData recipe, hangs the
-- floating info label (name / rarity / income) over it, and owns the little walk animation every
-- system shares: conveyor strolling, the dash to a buyer's pad and the sad walk home after a drop.
-- Models are anchored ghosts (CanCollide off) moved with PivotTo; players interact via prompts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)

local CharacterFactory = {}

-- The invisible root part's centre rides this far above the character's feet; every Pos in a
-- recipe is measured from the feet, so the factory subtracts the lift when placing parts.
local ROOT_LIFT = 0.5

local function rarityColorHex(rarity: string): string
	local color = BrainrotData.Rarities[rarity].Color
	return string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

local function buildPart(spec, modelCFrame: CFrame): BasePart
	local part: BasePart
	if spec.Shape == "Wedge" then
		part = Instance.new("WedgePart")
	else
		local p = Instance.new("Part")
		if spec.Shape == "Ball" then
			p.Shape = Enum.PartType.Ball
		elseif spec.Shape == "Cylinder" then
			p.Shape = Enum.PartType.Cylinder
		end
		part = p
	end
	part.Name = spec.Name
	part.Size = spec.Size
	part.Color = spec.Color
	part.Material = spec.Material or Enum.Material.SmoothPlastic
	part.Transparency = spec.Transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	local rot = spec.Rot or Vector3.zero
	local localCFrame = CFrame.new(spec.Pos.X, spec.Pos.Y - ROOT_LIFT, spec.Pos.Z)
		* CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
	part.CFrame = modelCFrame * localCFrame
	return part
end

-- Build a fresh brainrot entity (not yet parented anywhere). Call entry.Model.Parent = workspace
-- (or wherever) once built; pose it with SetPose before anyone sees it.
function CharacterFactory.Build(def)
	local model = Instance.new("Model")
	model.Name = def.Name

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 1, 2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.Parent = model

	local origin = CFrame.new(0, ROOT_LIFT, 0)
	root.CFrame = origin
	for _, spec in ipairs(def.Parts) do
		buildPart(spec, origin).Parent = model
	end
	model.PrimaryPart = root

	-- The floating label: name, rarity in its colour, income, plus a context line the
	-- UpdateLabel caller controls (price on the belt, owner's name on a base).
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.Size = UDim2.fromOffset(250, 92)
	gui.StudsOffset = Vector3.new(0, def.Height + 0.9, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 160
	gui.Parent = root

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.RichText = true
	label.Font = Enum.Font.GothamBold
	label.TextSize = 17
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.25
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = gui

	local entry = {
		Model = model,
		Def = def,
		Root = root,
		Label = label,
		Prompt = nil,
		PromptConn = nil,
		State = "idle",
		Owner = nil,
		PadIndex = nil,
		Carrier = nil,
		MoveToken = 0,
		BobPhase = math.random() * math.pi * 2,
	}
	CharacterFactory.UpdateLabel(entry, "")
	return entry
end

-- Rewrite the floating label: title line, rarity line, income line, and a context line
-- ("$750" while it walks the belt, "Mia's" once it stands on a base, "" for none).
function CharacterFactory.UpdateLabel(entry, contextLine: string)
	local def = entry.Def
	local lines = {
		string.format("<b>%s</b>", def.Name),
		string.format('<font color="%s">%s</font>', rarityColorHex(def.Rarity), string.upper(def.Rarity)),
		string.format('<font color="#7DFF8A">+%s/s</font>', BrainrotData.FormatCash(def.Income)),
	}
	if contextLine ~= "" then
		table.insert(lines, string.format('<font color="#FFE066">%s</font>', contextLine))
	end
	entry.Label.Text = table.concat(lines, "\n")
end

-- Attach (or replace) the model's single ProximityPrompt.
function CharacterFactory.SetPrompt(entry, actionText: string, objectText: string, callback)
	CharacterFactory.ClearPrompt(entry)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = entry.Root
	entry.Prompt = prompt
	if callback then
		entry.PromptConn = prompt.Triggered:Connect(callback)
	end
	return prompt
end

function CharacterFactory.ClearPrompt(entry)
	if entry.PromptConn then
		entry.PromptConn:Disconnect()
		entry.PromptConn = nil
	end
	if entry.Prompt then
		entry.Prompt:Destroy()
		entry.Prompt = nil
	end
end

-- Pose the model: feet at feetPos, facing yaw, with a walk-bob height and a side-to-side waddle.
function CharacterFactory.SetPose(entry, feetPos: Vector3, yaw: number, bobY: number, waddle: number)
	local cf = CFrame.new(feetPos.X, feetPos.Y + ROOT_LIFT + bobY, feetPos.Z)
		* CFrame.Angles(0, yaw, waddle)
	entry.Model:PivotTo(cf)
end

function CharacterFactory.GetFeet(entry): Vector3
	local pos = entry.Model:GetPivot().Position
	return Vector3.new(pos.X, pos.Y - ROOT_LIFT, pos.Z)
end

-- Walk the model in a straight line to targetFeet at speed studs/s, bobbing and facing the way it
-- goes. Any newer WalkTo (or StopMoving) cancels this one through the move token. onArrive runs
-- once, only if this walk was still the current one when it arrived.
function CharacterFactory.WalkTo(entry, targetFeet: Vector3, speed: number, onArrive)
	entry.MoveToken += 1
	local token = entry.MoveToken
	task.spawn(function()
		while token == entry.MoveToken do
			local feet = CharacterFactory.GetFeet(entry)
			local flatDelta = Vector3.new(targetFeet.X - feet.X, 0, targetFeet.Z - feet.Z)
			local dist = flatDelta.Magnitude
			if dist < 0.35 and math.abs(targetFeet.Y - feet.Y) < 0.6 then
				CharacterFactory.SetPose(entry, targetFeet, entry.LastYaw or 0, 0, 0)
				if onArrive then
					onArrive()
				end
				return
			end
			local dt = RunService.Heartbeat:Wait()
			if token ~= entry.MoveToken then
				return
			end
			local step = math.min(dist, speed * dt)
			local dir = if dist > 0.001 then flatDelta / dist else Vector3.zero
			local yaw = if dist > 0.001 then math.atan2(dir.X, dir.Z) else (entry.LastYaw or 0)
			entry.LastYaw = yaw
			entry.BobPhase += dt * speed * 1.6
			local bobY = math.abs(math.sin(entry.BobPhase)) * 0.28
			local waddle = math.sin(entry.BobPhase) * 0.07
			local newFeet = feet + dir * step
			newFeet = Vector3.new(newFeet.X, feet.Y + (targetFeet.Y - feet.Y) * math.min(1, dt * 6), newFeet.Z)
			CharacterFactory.SetPose(entry, newFeet, yaw, bobY, waddle)
		end
	end)
end

function CharacterFactory.StopMoving(entry)
	entry.MoveToken += 1
end

function CharacterFactory.Destroy(entry)
	CharacterFactory.StopMoving(entry)
	CharacterFactory.ClearPrompt(entry)
	if entry.Model then
		entry.Model:Destroy()
	end
end

return CharacterFactory
