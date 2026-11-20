-- WorldBuilder.luau (server)
-- Builds the SAHUR BASE world at server start and, separately, dresses it up afterwards.
--
-- Build() is 100% procedural and must NEVER fail or yield: a safety baseplate, ground, plaza,
-- our own conveyor belt, six player bases (pads, shop stands, signs, lock walls), gate, arch,
-- code lamps and trees, plus a neutral plaza SpawnLocation. It makes no InsertService calls —
-- in v12 the asset loads lived inline here, and AssetLibrary.GroundPivot threw mid-build
-- (Model has no PivotOffset), leaving a lone ground/plaza slab and no bases at all.
--
-- DressUp() runs later, in the background, and only adds decoration: the real conveyor model
-- tiled over our (invisible, still collidable) belt surface, the "Steal A Brainrot Base"
-- platform as a display shelf behind each base's pads, store foliage, lamps, neon signs and
-- wooden walls. Every step is pcall-wrapped and purely visual — loaded assets are sanitized
-- non-collidable scenery, and on any doubt the procedural look simply stays.
-- Returns the layout table every other system navigates by (pad positions, buttons, signs).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local AssetLibrary = require(script.Parent.AssetLibrary)

local WorldBuilder = {}

local GROUND_TOP = 0
local SLAB_TOP = 0.4
local BELT_TOP = 0.9
local PLATFORM_TOP = 2.0
local PAD_TOP = 2.35

-- Owner-owned Creator Store assets (DressUp only; the place owner owns them all).
local BASE_PLATFORM_ID = 107398504693015 -- "Steal A Brainrot Base" display platform
local CONVEYOR_ID = 7063606146 -- "Conveyor Belt" segment
local FOLIAGE_ID = 7990107300 -- "Foliage Pack (Realistic)"
local LAMP_ID = 14212653287 -- "Street Lamp"
local NEON_ID = 11666458445 -- "Neon Signs"
local WALLS_ID = 1408960132 -- "Wooden Walls"

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

-- One shop/action stand on the plaza in front of a base: a coloured post on a base plate with
-- the neon prompt pad on top. The four stands of a base stand eleven studs apart, so their
-- floating captions never overlap the way the old on-platform buttons did.
local function buildStand(parent, name, x, z, color, caption, actionText, objectText)
	local stand = Instance.new("Folder")
	stand.Name = name .. "Stand"
	stand.Parent = parent
	part(stand, "StandBase", Vector3.new(4.6, 0.3, 4.6), CFrame.new(x, SLAB_TOP + 0.15, z), Color3.fromRGB(38, 38, 46))
	part(stand, "StandPost", Vector3.new(0.9, 2.3, 0.9), CFrame.new(x, SLAB_TOP + 1.45, z), color)
	local pad = part(stand, name, Vector3.new(3.2, 0.5, 3.2), CFrame.new(x, SLAB_TOP + 2.85, z), color, Enum.Material.Neon)
	billboardLabel(pad, caption, 2.6)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad
	return { Part = pad, Prompt = prompt }
end

-- The usable units inside a loaded pack: Models and loose Parts, looking through plain Folders.
local function topLevelUnits(pack)
	local units = {}
	local function walk(inst)
		for _, child in ipairs(inst:GetChildren()) do
			if child:IsA("Model") or child:IsA("BasePart") then
				table.insert(units, child)
			elseif child:IsA("Folder") then
				walk(child)
			end
		end
	end
	walk(pack)
	return units
end

local function buildBase(parent, index, centerX, centerZ, facing)
	local baseColor = BASE_COLORS[index]
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. index
	folder.Parent = parent

	-- Skirt + platform. The platform's top surface is exactly PLATFORM_TOP: every pad, sign,
	-- button and spawn height in the game is measured from that constant.
	part(folder, "Skirt", Vector3.new(45, 0.5, 33), CFrame.new(centerX, SLAB_TOP + 0.25, centerZ), baseColor)
	part(folder, "Platform", Vector3.new(42, 1.6, 30), CFrame.new(centerX, PLATFORM_TOP - 0.8, centerZ), Color3.fromRGB(238, 234, 228))

	-- Eight brainrot pads in two rows (our own neon discs on our own platform — they never
	-- move, no matter what decoration DressUp adds later).
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

	-- Shop / action stands on the plaza in front of the base, spaced well apart
	local frontZ = centerZ + facing * 20.5
	local buttons = {
		Lock = buildStand(folder, "LockButton", centerX - 16.5, frontZ, Color3.fromRGB(38, 198, 218), "LOCK", "Lock Base", "60s protection"),
		Rebirth = buildStand(folder, "RebirthButton", centerX - 5.5, frontZ, Color3.fromRGB(255, 92, 168), "REBIRTH", "Rebirth", ""),
		Slap = buildStand(folder, "SlapButton", centerX + 5.5, frontZ, Color3.fromRGB(255, 140, 40), "SLAP +", "Upgrade Slap", ""),
		Speed = buildStand(folder, "SpeedButton", centerX + 16.5, frontZ, Color3.fromRGB(92, 220, 110), "SPEED +", "Upgrade Speed", ""),
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
		Folder = folder,
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

	-- Safety baseplate first: a solid collidable slab under the whole play area, its top a
	-- hair below the ground's top. Even if every later step somehow failed, a player would
	-- land on this instead of falling through the sky.
	part(world, "SafetyBaseplate", Vector3.new(440, 1, 440), CFrame.new(0, GROUND_TOP - 0.55, 0), Color3.fromRGB(120, 120, 125), Enum.Material.Concrete)

	-- Ground and plaza slab
	part(world, "Ground", Vector3.new(400, 2, 300), CFrame.new(0, GROUND_TOP - 1, 0), Color3.fromRGB(96, 176, 88), Enum.Material.Grass)
	part(world, "Plaza", Vector3.new(300, 0.4, 200), CFrame.new(0, SLAB_TOP - 0.2, 0), Color3.fromRGB(206, 201, 192))

	-- The conveyor road is ours: a dark belt with low glowing rails and scrolling chevron
	-- stripes. The Belt part is the guaranteed walking surface — if DressUp later tiles the
	-- real conveyor model over it, the tiles sit a hair lower and this part just turns
	-- invisible; it never stops being the collider.
	local belt = Instance.new("Folder")
	belt.Name = "Conveyor"
	belt.Parent = world
	local beltSurface = part(belt, "Belt", Vector3.new(252, 0.5, 16), CFrame.new(0, SLAB_TOP + 0.25, 0), Color3.fromRGB(30, 30, 38), Enum.Material.DiamondPlate)
	local railNear = part(belt, "RailNear", Vector3.new(252, 0.18, 0.45), CFrame.new(0, BELT_TOP + 0.09, -8.2), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
	local railFar = part(belt, "RailFar", Vector3.new(252, 0.18, 0.45), CFrame.new(0, BELT_TOP + 0.09, 8.2), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
	railNear.CanCollide = false
	railFar.CanCollide = false
	local stripesFolder = Instance.new("Folder")
	stripesFolder.Name = "Stripes"
	stripesFolder.Parent = belt
	local stripes = {}
	for i = 0, 30 do
		local stripe = part(stripesFolder, "Stripe", Vector3.new(0.9, 0.08, 13), CFrame.new(-124 + i * 8.3, BELT_TOP + 0.03, 0), Color3.fromRGB(84, 84, 100))
		stripe.CanCollide = false
		table.insert(stripes, stripe)
	end
	task.spawn(function()
		while belt.Parent do
			local dt = task.wait()
			for _, stripe in ipairs(stripes) do
				if not stripe.Parent then
					return -- DressUp replaced the belt visuals; stop scrolling
				end
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

	-- Code street lamps along the belt (DressUp may add the real lamp model alongside)
	for _, lx in ipairs({ -100, -34, 34, 100 }) do
		for _, lz in ipairs({ -20, 20 }) do
			part(world, "LampPole", Vector3.new(0.45, 7, 0.45), CFrame.new(lx, SLAB_TOP + 3.5, lz), Color3.fromRGB(52, 52, 64))
			local head = part(world, "LampHead", Vector3.new(1.1, 1.1, 1.1), CFrame.new(lx, SLAB_TOP + 7.3, lz), Color3.fromRGB(255, 226, 150), Enum.Material.Neon)
			head.Shape = Enum.PartType.Ball
			head.CanCollide = false
		end
	end

	-- Code trees at the plaza corners and along the grass ring
	for _, spot in ipairs({ { -150, -95 }, { 150, -95 }, { -150, 95 }, { 150, 95 }, { -150, 0 }, { 150, 0 } }) do
		local tx, tz = spot[1], spot[2]
		local trunk = part(world, "TreeTrunk", Vector3.new(1.1, 4.5, 1.1), CFrame.new(tx, GROUND_TOP + 2.25, tz), Color3.fromRGB(110, 76, 44), Enum.Material.Wood)
		trunk.Shape = Enum.PartType.Cylinder
		local leaves = part(world, "TreeTop", Vector3.new(6, 5.5, 6), CFrame.new(tx, GROUND_TOP + 6.8, tz), Color3.fromRGB(56, 142, 60), Enum.Material.Grass)
		leaves.Shape = Enum.PartType.Ball
		leaves.CanCollide = false
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

	-- A neutral SpawnLocation on the plaza: CharacterAutoLoads is on and the project defines
	-- no spawn, so without this a player whose base teleport has not run yet (or whose base
	-- assignment was delayed) would drop out of the sky. The base teleport still wins the
	-- moment it runs; this is only the guaranteed landing pad underneath everything.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlazaSpawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.lookAt(Vector3.new(0, SLAB_TOP + 0.5, 30), Vector3.new(0, SLAB_TOP + 0.5, 0))
	spawn.Color = Color3.fromRGB(38, 198, 218)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.35
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Parent = world

	-- Spawn safety self-check: every base spawn point must have solid ground under it.
	for _, base in ipairs(bases) do
		local origin = base.SpawnPos + Vector3.new(0, 6, 0)
		local hit = Workspace:Raycast(origin, Vector3.new(0, -12, 0))
		if hit then
			print(string.format("[SahurBase] Spawn check base %d: OK (%s at Y=%.2f)", base.Index, hit.Instance.Name, hit.Position.Y))
		else
			warn(string.format("[SahurBase] Spawn check base %d: NO GROUND under spawn — plaza spawn + safety baseplate remain as fallback", base.Index))
		end
	end

	print("[SahurBase] World built (procedural): safety baseplate, 6 bases, belt, plaza spawn.")

	return {
		Folder = world,
		BeltTopY = BELT_TOP,
		BeltZ = 0,
		PlatformTopY = PLATFORM_TOP,
		Bases = bases,
		BeltFolder = belt,
		BeltSurface = beltSurface,
		BeltRails = { railNear, railFar },
		StripesFolder = stripesFolder,
	}
end

-- DressUp: background decoration with the owner's Creator Store models. Called from init in
-- a task.spawn AFTER the world and every system are live. Each step loads its asset inside
-- its own pcall; a failed or surprising asset leaves the procedural look untouched. Nothing
-- here moves a pad, a spawn, or any gameplay surface: loaded models are sanitized scenery
-- (anchored, non-collidable), and the belt keeps our own invisible collidable surface.
function WorldBuilder.DressUp(layout)
	local world = layout.Folder
	if not world or not world.Parent then
		return
	end

	-- The real conveyor model tiled along the road, its top a hair below BELT_TOP; our Belt
	-- part then turns invisible but STAYS collidable, so the walking surface is guaranteed
	-- no matter how the imported segments behave.
	local function dressConveyor()
		local segTemplate = AssetLibrary.LoadModel(CONVEYOR_ID)
		if not segTemplate then
			return "conveyor asset did not load; procedural belt stays"
		end
		local ssize = AssetLibrary.GroundPivot(segTemplate)
		local alongZ = ssize.Z > ssize.X
		local segLen = if alongZ then ssize.Z else ssize.X
		local segWidth = if alongZ then ssize.X else ssize.Z
		if not (segLen >= 4 and segLen <= 60 and ssize.Y >= 0.2 and ssize.Y <= 3.5 and segWidth <= 30) then
			segTemplate:Destroy()
			return "conveyor asset failed sanity checks; procedural belt stays"
		end
		local count = math.ceil(252 / segLen)
		for i = 0, count - 1 do
			local seg = segTemplate:Clone()
			local x = -126 + segLen * (i + 0.5)
			local cf = CFrame.new(x, BELT_TOP - 0.02 - ssize.Y, 0)
			if alongZ then
				cf = cf * CFrame.Angles(0, math.pi / 2, 0)
			end
			seg:PivotTo(cf)
			seg.Parent = layout.BeltFolder
		end
		layout.BeltSurface.Transparency = 1
		for _, rail in ipairs(layout.BeltRails) do
			rail.Transparency = 1
			rail.CanCollide = false
		end
		if layout.StripesFolder then
			layout.StripesFolder:Destroy()
		end
		return string.format("conveyor tiled from asset (%d segments)", count)
	end

	-- The real base platform as a display shelf at the back of each base, behind the pads:
	-- pure decoration — pads, spawns and the platform itself stay exactly where Build put them.
	local function dressBaseShelves()
		local template = AssetLibrary.LoadModel(BASE_PLATFORM_ID)
		if not template then
			return "base platform asset did not load; skipped"
		end
		local _, bsize = template:GetBoundingBox()
		if bsize.X <= 0.1 or bsize.Z <= 0.1 or bsize.Y <= 0.05 then
			template:Destroy()
			return "base platform asset empty; skipped"
		end
		local factor = math.min(22 / bsize.X, 6 / bsize.Z)
		if bsize.Y * factor > 3 then
			factor = 3 / bsize.Y
		end
		factor = math.clamp(factor, 0.05, 1.5)
		if math.abs(factor - 1) > 0.02 then
			template:ScaleTo(template:GetScale() * factor)
		end
		AssetLibrary.GroundPivot(template)
		for _, base in ipairs(layout.Bases) do
			local shelf = template:Clone()
			shelf.Name = "AssetShelf"
			local yaw = if base.Facing > 0 then 0 else math.pi
			shelf:PivotTo(CFrame.new(base.Center.X, PLATFORM_TOP, base.Center.Z - base.Facing * 10.8) * CFrame.Angles(0, yaw, 0))
			shelf.Parent = base.Folder
		end
		return "base display shelves placed (decorative, behind the pads)"
	end

	-- A real neon sign on each face of the arch board, if the pack has a usable board model
	local function dressNeon()
		local neonPack = AssetLibrary.LoadPack(NEON_ID)
		if not neonPack then
			return "neon pack did not load; skipped"
		end
		local signUnit = nil
		for _, unit in ipairs(topLevelUnits(neonPack)) do
			if unit:IsA("Model") then
				signUnit = unit
				break
			end
		end
		if not signUnit then
			return "neon pack has no model; skipped"
		end
		for _, side in ipairs({ 1, -1 }) do
			local sign = signUnit:Clone()
			local _, ssize = sign:GetBoundingBox()
			if ssize.Y > 0.05 then
				local factor = math.min(20 / math.max(ssize.X, ssize.Z), 5 / ssize.Y)
				if factor < 1 then
					sign:ScaleTo(sign:GetScale() * factor)
				end
				AssetLibrary.CenterPlace(sign, CFrame.new(side * 0.85, SLAB_TOP + 11.6, 0) * CFrame.Angles(0, side * math.pi / 2, 0))
				sign.Parent = world
			end
		end
		return "neon signs placed on the arch"
	end

	-- The real street lamp model along the belt (the code lamps stay as the base layer)
	local function dressLamps()
		local lampTemplate = AssetLibrary.LoadModel(LAMP_ID)
		if not lampTemplate then
			return "lamp asset did not load; code lamps stay"
		end
		AssetLibrary.GroundPivot(lampTemplate)
		for _, spot in ipairs({ { -90, -15 }, { 0, -15 }, { 90, -15 }, { -90, 15 }, { 0, 15 }, { 90, 15 } }) do
			local lamp = lampTemplate:Clone()
			lamp:PivotTo(CFrame.new(spot[1], SLAB_TOP, spot[2]))
			lamp.Parent = world
		end
		return "asset street lamps placed"
	end

	-- The realistic foliage pack scattered around the grass ring outside the plaza
	local function dressFoliage()
		local foliagePack = AssetLibrary.LoadPack(FOLIAGE_ID)
		if not foliagePack then
			return "foliage pack did not load; code trees stay"
		end
		local units = topLevelUnits(foliagePack)
		if #units == 0 then
			return "foliage pack empty; code trees stay"
		end
		local spots = {
			{ -162, -90 }, { -162, -45 }, { -162, 0 }, { -162, 45 }, { -162, 90 },
			{ 162, -90 }, { 162, -45 }, { 162, 0 }, { 162, 45 }, { 162, 90 },
			{ -80, -112 }, { 0, -112 }, { 80, -112 }, { -80, 112 }, { 0, 112 }, { 80, 112 },
		}
		local placed = 0
		for i, spot in ipairs(spots) do
			local ok = pcall(function()
				local unit = units[((i - 1) % #units) + 1]:Clone()
				if unit:IsA("Model") then
					local _, usize = unit:GetBoundingBox()
					if usize.Y > 13 then
						AssetLibrary.ScaleToHeight(unit, 11)
					end
					AssetLibrary.GroundPivot(unit)
					unit:PivotTo(CFrame.new(spot[1], GROUND_TOP, spot[2]) * CFrame.Angles(0, (i * 1.93) % (math.pi * 2), 0))
				elseif unit:IsA("BasePart") then
					unit.CFrame = CFrame.new(spot[1], GROUND_TOP + unit.Size.Y / 2, spot[2])
				end
				unit.Parent = world
				placed += 1
			end)
			if not ok then
				print("[SahurBase] DressUp foliage: one unit failed to place, continuing")
			end
		end
		return string.format("foliage placed (%d units)", placed)
	end

	-- Wooden wall segments as a partial perimeter behind each base
	local function dressWalls()
		local wallPack = AssetLibrary.LoadPack(WALLS_ID)
		if not wallPack then
			return "wall pack did not load; skipped"
		end
		local wallUnit = nil
		for _, unit in ipairs(topLevelUnits(wallPack)) do
			if unit:IsA("Model") then
				wallUnit = unit
				break
			end
		end
		if not wallUnit then
			local units = topLevelUnits(wallPack)
			if #units > 0 then
				wallUnit = units[1]
			end
		end
		if not wallUnit then
			return "wall pack has no usable unit; skipped"
		end
		local protoSize
		if wallUnit:IsA("Model") then
			local _, wsize = wallUnit:GetBoundingBox()
			protoSize = wsize
		else
			protoSize = wallUnit.Size
		end
		local alongZ = protoSize.Z > protoSize.X
		local segLen = if alongZ then protoSize.Z else protoSize.X
		local segYaw = if alongZ then math.pi / 2 else 0
		if not (segLen >= 2 and segLen <= 20 and protoSize.Y >= 1) then
			return "wall unit failed sanity checks; skipped"
		end
		local count = math.min(8, math.floor(38 / segLen))
		for _, base in ipairs(layout.Bases) do
			local wallZ = base.Center.Z - base.Facing * 17.5
			local startX = base.Center.X - (count * segLen) / 2 + segLen / 2
			for i = 0, count - 1 do
				pcall(function()
					local seg = wallUnit:Clone()
					local x = startX + i * segLen
					if seg:IsA("Model") then
						AssetLibrary.GroundPivot(seg)
						seg:PivotTo(CFrame.new(x, SLAB_TOP, wallZ) * CFrame.Angles(0, segYaw, 0))
					else
						seg.CFrame = CFrame.new(x, SLAB_TOP + seg.Size.Y / 2, wallZ) * CFrame.Angles(0, segYaw, 0)
					end
					seg.Parent = world
				end)
			end
		end
		return "wooden base perimeters placed"
	end

	print("[SahurBase] DressUp started (background decoration; procedural world already live)")
	local steps = {
		{ "conveyor", dressConveyor },
		{ "base shelves", dressBaseShelves },
		{ "neon", dressNeon },
		{ "lamps", dressLamps },
		{ "foliage", dressFoliage },
		{ "walls", dressWalls },
	}
	for _, step in ipairs(steps) do
		local ok, result = pcall(step[2])
		if ok then
			print("[SahurBase] DressUp " .. step[1] .. ": " .. tostring(result))
		else
			print("[SahurBase] DressUp " .. step[1] .. " FAILED (procedural fallback stays): " .. tostring(result))
		end
	end
	print("[SahurBase] DressUp finished")
end

return WorldBuilder
