-- WorldBuilder.luau (server)
-- Builds the whole SAHUR BASE world out of plain Parts at server start: a plaza, a glowing
-- conveyor road down the middle, and six player bases (three a side) with pads, shop buttons,
-- signs and lock walls. No external assets — if it stands in the world, it is a Part made here.
-- Returns the layout table every other system navigates by (pad positions, buttons, signs).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local WorldBuilder = {}

local GROUND_TOP = 0
local SLAB_TOP = 0.4
local BELT_TOP = 0.9
local PLATFORM_TOP = 2.0
local PAD_TOP = 2.35

local BASE_COLORS = {
	Color3.fromRGB(239, 83, 80),
	Color3.fromRGB(66, 165, 245),
	Color3.fromRGB(102, 187, 106),
	Color3.fromRGB(255, 190, 40),
	Color3.fromRGB(171, 71, 188),
	Color3.fromRGB(38, 198, 218),
}

local function part(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.Parent = parent
	return p
end

local function billboardLabel(parentPart, text, offsetY, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(170, 40)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	gui.Parent = parentPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	return label
end

local function buildButton(parent, name, pos, color, caption, actionText, objectText)
	local button = part(parent, name, Vector3.new(3.2, 0.5, 3.2), CFrame.new(pos), color, Enum.Material.Neon)
	billboardLabel(button, caption, 2.1)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = button
	return { Part = button, Prompt = prompt }
end

local function buildBase(parent, index, centerX, centerZ, facing)
	local baseColor = BASE_COLORS[index]
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. index
	folder.Parent = parent

	-- Skirt + platform
	part(folder, "Skirt", Vector3.new(45, 0.5, 33), CFrame.new(centerX, SLAB_TOP + 0.25, centerZ), baseColor)
	part(folder, "Platform", Vector3.new(42, 1.6, 30), CFrame.new(centerX, SLAB_TOP + 0.8 + 0.5, centerZ), Color3.fromRGB(238, 234, 228))

	-- Eight brainrot pads in two rows
	local pads = {}
	local padFeet = {}
	local padXs = { -13.5, -4.5, 4.5, 13.5 }
	local padZs = { -6.5, 6.5 }
	local n = 0
	for _, lz in ipairs(padZs) do
		for _, lx in ipairs(padXs) do
			n += 1
			local px, pz = centerX + lx, centerZ + lz
			local pad = Instance.new("Part")
			pad.Name = "Pad" .. n
			pad.Shape = Enum.PartType.Cylinder
			pad.Size = Vector3.new(0.35, 4.3, 4.3)
			pad.CFrame = CFrame.new(px, PLATFORM_TOP + 0.175, pz) * CFrame.Angles(0, 0, math.rad(90))
			pad.Color = baseColor
			pad.Material = Enum.Material.Neon
			pad.Anchored = true
			pad.Parent = folder
			pads[n] = pad
			padFeet[n] = Vector3.new(px, PAD_TOP, pz)
		end
	end

	-- Sign board at the back, facing the belt, with a SurfaceGui the BaseManager writes on
	local backZ = centerZ - facing * 14.6
	local boardYaw = if facing > 0 then 0 else math.pi
	local board = part(folder, "Sign", Vector3.new(17, 5.5, 0.6), CFrame.new(centerX, PLATFORM_TOP + 3.6, backZ) * CFrame.Angles(0, boardYaw, 0), Color3.fromRGB(30, 30, 38))
	part(folder, "SignPostL", Vector3.new(0.5, 3.4, 0.5), CFrame.new(centerX - 7.5, PLATFORM_TOP + 1.7, backZ), Color3.fromRGB(30, 30, 38))
	part(folder, "SignPostR", Vector3.new(0.5, 3.4, 0.5), CFrame.new(centerX + 7.5, PLATFORM_TOP + 1.7, backZ), Color3.fromRGB(30, 30, 38))
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = board
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.BackgroundTransparency = 1
	signLabel.Font = Enum.Font.GothamBold
	signLabel.TextScaled = true
	signLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	signLabel.TextStrokeTransparency = 0.4
	signLabel.Text = "BASE " .. index
	signLabel.Parent = signGui

	-- Shop / action buttons along the front edge, nearest the belt
	local frontZ = centerZ + facing * 12.6
	local buttonY = PLATFORM_TOP + 0.25
	local buttons = {
		Lock = buildButton(folder, "LockButton", Vector3.new(centerX - 13.5, buttonY, frontZ), Color3.fromRGB(38, 198, 218), "LOCK", "Lock Base", "60s protection"),
		Rebirth = buildButton(folder, "RebirthButton", Vector3.new(centerX - 4.5, buttonY, frontZ), Color3.fromRGB(255, 92, 168), "REBIRTH", "Rebirth", ""),
		Slap = buildButton(folder, "SlapButton", Vector3.new(centerX + 4.5, buttonY, frontZ), Color3.fromRGB(255, 140, 40), "SLAP +", "Upgrade Slap", ""),
		Speed = buildButton(folder, "SpeedButton", Vector3.new(centerX + 13.5, buttonY, frontZ), Color3.fromRGB(92, 220, 110), "SPEED +", "Upgrade Speed", ""),
	}

	-- Lock walls: an energy shell around the platform, invisible until the base locks
	local walls = {}
	local wallSpecs = {
		{ Vector3.new(43.2, 5, 0.6), Vector3.new(centerX, PLATFORM_TOP + 2.5, centerZ - 15.3) },
		{ Vector3.new(43.2, 5, 0.6), Vector3.new(centerX, PLATFORM_TOP + 2.5, centerZ + 15.3) },
		{ Vector3.new(0.6, 5, 31.2), Vector3.new(centerX - 21.3, PLATFORM_TOP + 2.5, centerZ) },
		{ Vector3.new(0.6, 5, 31.2), Vector3.new(centerX + 21.3, PLATFORM_TOP + 2.5, centerZ) },
	}
	for i, spec in ipairs(wallSpecs) do
		local wall = part(folder, "LockWall" .. i, spec[1], CFrame.new(spec[2]), baseColor, Enum.Material.ForceField)
		wall.Transparency = 1
		wall.CanCollide = false
		table.insert(walls, wall)
	end

	return {
		Index = index,
		Center = Vector3.new(centerX, PLATFORM_TOP, centerZ),
		Facing = facing,
		Color = baseColor,
		Pads = pads,
		PadFeet = padFeet,
		SpawnPos = Vector3.new(centerX, PLATFORM_TOP, centerZ + facing * 10),
		SignLabel = signLabel,
		Buttons = buttons,
		LockWalls = walls,
	}
end

function WorldBuilder.Build()
	local old = Workspace:FindFirstChild("SahurWorld")
	if old then
		old:Destroy()
	end
	local world = Instance.new("Folder")
	world.Name = "SahurWorld"
	world.Parent = Workspace

	-- Ground and plaza slab
	part(world, "Ground", Vector3.new(400, 2, 300), CFrame.new(0, GROUND_TOP - 1, 0), Color3.fromRGB(96, 176, 88), Enum.Material.Grass)
	part(world, "Plaza", Vector3.new(300, 0.4, 200), CFrame.new(0, SLAB_TOP - 0.2, 0), Color3.fromRGB(206, 201, 192))

	-- The conveyor road: dark belt, neon rails, and chevron stripes that scroll toward +X
	local belt = Instance.new("Folder")
	belt.Name = "Conveyor"
	belt.Parent = world
	part(belt, "Belt", Vector3.new(252, 0.5, 16), CFrame.new(0, SLAB_TOP + 0.25, 0), Color3.fromRGB(38, 38, 46))
	part(belt, "RailNear", Vector3.new(252, 0.35, 0.5), CFrame.new(0, BELT_TOP + 0.1, -8.2), Color3.fromRGB(255, 209, 26), Enum.Material.Neon)
	part(belt, "RailFar", Vector3.new(252, 0.35, 0.5), CFrame.new(0, BELT_TOP + 0.1, 8.2), Color3.fromRGB(255, 209, 26), Enum.Material.Neon)
	local stripes = {}
	for i = 0, 30 do
		local stripe = part(belt, "Stripe", Vector3.new(0.9, 0.08, 13), CFrame.new(-124 + i * 8.3, BELT_TOP + 0.03, 0), Color3.fromRGB(84, 84, 100))
		table.insert(stripes, stripe)
	end
	task.spawn(function()
		while belt.Parent do
			local dt = task.wait()
			for _, stripe in ipairs(stripes) do
				local x = stripe.Position.X + Config.BeltSpeed * dt
				if x > 126 then
					x -= 252
				end
				stripe.Position = Vector3.new(x, stripe.Position.Y, 0)
			end
		end
	end)

	-- Spawn gate where brainrots enter, and the big centre sign over the belt
	part(world, "GatePostL", Vector3.new(1, 10, 1), CFrame.new(Config.BeltStartX - 4, SLAB_TOP + 5, -9.5), Color3.fromRGB(52, 52, 64))
	part(world, "GatePostR", Vector3.new(1, 10, 1), CFrame.new(Config.BeltStartX - 4, SLAB_TOP + 5, 9.5), Color3.fromRGB(52, 52, 64))
	local gateBoard = part(world, "GateBoard", Vector3.new(0.7, 3.4, 20), CFrame.new(Config.BeltStartX - 4, SLAB_TOP + 10.4, 0), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
	billboardLabel(gateBoard, "BRAINROT EXPRESS", 3.4, Color3.fromRGB(255, 190, 80))

	local archL = part(world, "ArchL", Vector3.new(1.2, 11, 1.2), CFrame.new(0, SLAB_TOP + 5.5, -11), Color3.fromRGB(52, 52, 64))
	local archR = part(world, "ArchR", Vector3.new(1.2, 11, 1.2), CFrame.new(0, SLAB_TOP + 5.5, 11), Color3.fromRGB(52, 52, 64))
	archL.CanCollide = false
	archR.CanCollide = false
	local archBoard = part(world, "ArchBoard", Vector3.new(1.2, 5, 23.2), CFrame.new(0, SLAB_TOP + 11.6, 0), Color3.fromRGB(24, 24, 32))
	for _, face in ipairs({ Enum.NormalId.Right, Enum.NormalId.Left }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.Parent = archBoard
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 209, 26)
		label.TextStrokeTransparency = 0.35
		label.Text = "SAHUR BASE\nSTEAL A BRAINROT"
		label.Parent = gui
	end

	-- Lamps and trees for a bit of plaza life
	for _, lx in ipairs({ -100, -34, 34, 100 }) do
		for _, lz in ipairs({ -20, 20 }) do
			part(world, "LampPole", Vector3.new(0.45, 7, 0.45), CFrame.new(lx, SLAB_TOP + 3.5, lz), Color3.fromRGB(52, 52, 64))
			local head = part(world, "LampHead", Vector3.new(1.1, 1.1, 1.1), CFrame.new(lx, SLAB_TOP + 7.3, lz), Color3.fromRGB(255, 226, 150), Enum.Material.Neon)
			head.Shape = Enum.PartType.Ball
		end
	end
	for _, spot in ipairs({ { -150, -95 }, { 150, -95 }, { -150, 95 }, { 150, 95 }, { -150, 0 }, { 150, 0 } }) do
		local tx, tz = spot[1], spot[2]
		local trunk = part(world, "TreeTrunk", Vector3.new(1.1, 4.5, 1.1), CFrame.new(tx, GROUND_TOP + 2.25, tz), Color3.fromRGB(110, 76, 44), Enum.Material.Wood)
		trunk.Shape = Enum.PartType.Cylinder
		local leaves = part(world, "TreeTop", Vector3.new(6, 5.5, 6), CFrame.new(tx, GROUND_TOP + 6.8, tz), Color3.fromRGB(56, 142, 60), Enum.Material.Grass)
		leaves.Shape = Enum.PartType.Ball
	end

	-- Six bases: three on the north side facing +Z, three on the south facing -Z
	local bases = {}
	local xs = { -76, 0, 76 }
	for i, bx in ipairs(xs) do
		bases[i] = buildBase(world, i, bx, -58, 1)
	end
	for i, bx in ipairs(xs) do
		bases[i + 3] = buildBase(world, i + 3, bx, 58, -1)
	end

	return {
		BeltTopY = BELT_TOP,
		BeltZ = 0,
		PlatformTopY = PLATFORM_TOP,
		Bases = bases,
	}
end

return WorldBuilder
