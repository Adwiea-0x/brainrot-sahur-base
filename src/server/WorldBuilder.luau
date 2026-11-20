-- WorldBuilder.luau (server)
-- Builds the SAHUR BASE world at server start: a plaza, the conveyor road down the middle, and
-- six player bases (three a side) with pads, shop stands, signs and lock walls.
-- The structure is code-built Parts, but the dressing is the real thing: each base stands on the
-- owner's "Steal A Brainrot Base" platform model, the belt is tiled from a real conveyor model,
-- and the plaza is decorated with store foliage, lamps, neon signs and wooden walls — all loaded
-- and sanitized by AssetLibrary, all with code-built fallbacks if a load fails.
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

-- Owner-owned Creator Store assets (loaded at runtime; the place owner owns them all).
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

-- Hunt a placed base-platform model for its display slots: flat pads near the top surface,
-- either named like slots or just sitting where a slot would sit. The big slab itself (the
-- largest part by volume) is never a slot. Returns world-space top-centre points, row by row.
local function detectSlots(platformModel)
	local pivot = platformModel:GetPivot()
	local _, psize = platformModel:GetBoundingBox()
	local topY = pivot.Position.Y + psize.Y
	local largest, largestVolume = nil, -1
	for _, descendant in ipairs(platformModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local volume = descendant.Size.X * descendant.Size.Y * descendant.Size.Z
			if volume > largestVolume then
				largestVolume = volume
				largest = descendant
			end
		end
	end
	local slots = {}
	for _, descendant in ipairs(platformModel:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant ~= largest then
			local lname = string.lower(descendant.Name)
			local namedSlot = lname:find("slot", 1, true)
				or lname:find("pad", 1, true)
				or lname:find("display", 1, true)
				or lname:find("stand", 1, true)
			local top = descendant.Position.Y + descendant.Size.Y / 2
			local flatEnough = descendant.Size.X >= 1.6 and descendant.Size.X <= 8
				and descendant.Size.Z >= 1.6 and descendant.Size.Z <= 8
				and descendant.Size.Y <= 1.6
			if flatEnough and (namedSlot or top >= topY - 1.1) then
				table.insert(slots, Vector3.new(descendant.Position.X, top, descendant.Position.Z))
			end
		end
	end
	table.sort(slots, function(a, b)
		if math.abs(a.Z - b.Z) > 2 then
			return a.Z < b.Z
		end
		return a.X < b.X
	end)
	return slots
end

local function buildBase(parent, index, centerX, centerZ, facing, platformTemplate)
	local baseColor = BASE_COLORS[index]
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. index
	folder.Parent = parent

	-- Skirt + platform. The platform's top surface is exactly PLATFORM_TOP: every pad, sign,
	-- button and spawn height in the game is measured from that constant.
	part(folder, "Skirt", Vector3.new(45, 0.5, 33), CFrame.new(centerX, SLAB_TOP + 0.25, centerZ), baseColor)
	part(folder, "Platform", Vector3.new(42, 1.6, 30), CFrame.new(centerX, PLATFORM_TOP - 0.8, centerZ), Color3.fromRGB(238, 234, 228))

	-- Eight brainrot pads in two rows (our own neon discs; they may move onto the asset's slots)
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

	-- The real base platform stands on our platform, nudged away from the belt so the shop
	-- stands stay clear of it. If it has display slots we can detect, our pads move onto them;
	-- otherwise our pads ride on the asset's top surface instead of our platform's.
	if platformTemplate then
		local plat = platformTemplate:Clone()
		plat.Name = "AssetPlatform"
		local yaw = if facing > 0 then 0 else math.pi
		plat:PivotTo(CFrame.new(centerX, PLATFORM_TOP, centerZ - facing * 2.5) * CFrame.Angles(0, yaw, 0))
		plat.Parent = folder
		local _, psize = plat:GetBoundingBox()
		local assetTopY = PLATFORM_TOP + psize.Y
		local function gridPoint(i)
			local col = ((i - 1) % 4) + 1
			local row = math.floor((i - 1) / 4) + 1
			return centerX + padXs[col], centerZ + padZs[row]
		end
		local function padOnto(i, x, topSurfaceY, z)
			padFeet[i] = Vector3.new(x, topSurfaceY + 0.35, z)
			pads[i].CFrame = CFrame.new(x, topSurfaceY + 0.35 - 0.175, z) * CFrame.Angles(0, 0, math.rad(90))
		end
		local slots = detectSlots(plat)
		if #slots >= 6 then
			for i = 1, math.min(#slots, 8) do
				padOnto(i, slots[i].X, slots[i].Y, slots[i].Z)
			end
			for i = #slots + 1, 8 do
				local gx, gz = gridPoint(i)
				padOnto(i, gx, assetTopY, gz)
			end
		else
			for i = 1, 8 do
				local gx, gz = gridPoint(i)
				padOnto(i, gx, assetTopY, gz)
			end
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

	-- The conveyor road. First choice: tile the real Conveyor Belt model along the road and let
	-- the characters walk on its actual top surface. Fallback: our own belt, restyled dark with
	-- low glowing rails and scrolling chevron stripes (the old tall yellow rails read as slabs).
	local belt = Instance.new("Folder")
	belt.Name = "Conveyor"
	belt.Parent = world
	local beltTopY = BELT_TOP
	local tiled = false
	local segTemplate = AssetLibrary.LoadModel(CONVEYOR_ID)
	if segTemplate then
		local ssize = AssetLibrary.GroundPivot(segTemplate)
		local alongZ = ssize.Z > ssize.X
		local segLen = if alongZ then ssize.Z else ssize.X
		local segWidth = if alongZ then ssize.X else ssize.Z
		if segLen >= 4 and segLen <= 60 and ssize.Y >= 0.2 and ssize.Y <= 3.5 and segWidth <= 30 then
			local count = math.ceil(252 / segLen)
			for i = 0, count - 1 do
				local seg = segTemplate:Clone()
				local x = -126 + segLen * (i + 0.5)
				local cf = CFrame.new(x, SLAB_TOP, 0)
				if alongZ then
					cf = cf * CFrame.Angles(0, math.pi / 2, 0)
				end
				seg:PivotTo(cf)
				seg.Parent = belt
			end
			beltTopY = SLAB_TOP + ssize.Y
			tiled = true
		end
	end
	if not tiled then
		part(belt, "Belt", Vector3.new(252, 0.5, 16), CFrame.new(0, SLAB_TOP + 0.25, 0), Color3.fromRGB(30, 30, 38), Enum.Material.DiamondPlate)
		part(belt, "RailNear", Vector3.new(252, 0.18, 0.45), CFrame.new(0, BELT_TOP + 0.09, -8.2), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
		part(belt, "RailFar", Vector3.new(252, 0.18, 0.45), CFrame.new(0, BELT_TOP + 0.09, 8.2), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
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
	end

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

	-- A real neon sign on each face of the arch board, if the pack has a usable board model
	local neonPack = AssetLibrary.LoadPack(NEON_ID)
	if neonPack then
		local signUnit = nil
		for _, unit in ipairs(topLevelUnits(neonPack)) do
			if unit:IsA("Model") then
				signUnit = unit
				break
			end
		end
		if signUnit then
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
		end
	end

	-- Street lamps along the belt: the real lamp model if it loaded, else our code lamps
	local lampTemplate = AssetLibrary.LoadModel(LAMP_ID)
	if lampTemplate then
		AssetLibrary.GroundPivot(lampTemplate)
		for _, spot in ipairs({ { -90, -15 }, { 0, -15 }, { 90, -15 }, { -90, 15 }, { 0, 15 }, { 90, 15 } }) do
			local lamp = lampTemplate:Clone()
			lamp:PivotTo(CFrame.new(spot[1], SLAB_TOP, spot[2]))
			lamp.Parent = world
		end
	else
		for _, lx in ipairs({ -100, -34, 34, 100 }) do
			for _, lz in ipairs({ -20, 20 }) do
				part(world, "LampPole", Vector3.new(0.45, 7, 0.45), CFrame.new(lx, SLAB_TOP + 3.5, lz), Color3.fromRGB(52, 52, 64))
				local head = part(world, "LampHead", Vector3.new(1.1, 1.1, 1.1), CFrame.new(lx, SLAB_TOP + 7.3, lz), Color3.fromRGB(255, 226, 150), Enum.Material.Neon)
				head.Shape = Enum.PartType.Ball
			end
		end
	end

	-- Code trees at the plaza corners (always), plus the realistic foliage pack scattered
	-- around the grass ring outside the plaza
	for _, spot in ipairs({ { -150, -95 }, { 150, -95 }, { -150, 95 }, { 150, 95 }, { -150, 0 }, { 150, 0 } }) do
		local tx, tz = spot[1], spot[2]
		local trunk = part(world, "TreeTrunk", Vector3.new(1.1, 4.5, 1.1), CFrame.new(tx, GROUND_TOP + 2.25, tz), Color3.fromRGB(110, 76, 44), Enum.Material.Wood)
		trunk.Shape = Enum.PartType.Cylinder
		local leaves = part(world, "TreeTop", Vector3.new(6, 5.5, 6), CFrame.new(tx, GROUND_TOP + 6.8, tz), Color3.fromRGB(56, 142, 60), Enum.Material.Grass)
		leaves.Shape = Enum.PartType.Ball
	end
	local foliagePack = AssetLibrary.LoadPack(FOLIAGE_ID)
	if foliagePack then
		local units = topLevelUnits(foliagePack)
		if #units > 0 then
			local spots = {
				{ -162, -90 }, { -162, -45 }, { -162, 0 }, { -162, 45 }, { -162, 90 },
				{ 162, -90 }, { 162, -45 }, { 162, 0 }, { 162, 45 }, { 162, 90 },
				{ -80, -112 }, { 0, -112 }, { 80, -112 }, { -80, 112 }, { 0, 112 }, { 80, 112 },
			}
			for i, spot in ipairs(spots) do
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
			end
		end
	end

	-- The base platform template: scaled once so it covers the pad grid without overflowing
	-- the base, pivot grounded, then cloned per base inside buildBase.
	local platformTemplate = AssetLibrary.LoadModel(BASE_PLATFORM_ID)
	if platformTemplate then
		local _, bsize = platformTemplate:GetBoundingBox()
		if bsize.X <= 0.1 or bsize.Z <= 0.1 or bsize.Y <= 0.05 then
			platformTemplate:Destroy()
			platformTemplate = nil
		else
			local factor = math.max(33 / bsize.X, 19 / bsize.Z)
			factor = math.min(factor, 40 / bsize.X, 28 / bsize.Z)
			factor = math.clamp(factor, 0.3, 2.5)
			if math.abs(factor - 1) > 0.02 then
				platformTemplate:ScaleTo(platformTemplate:GetScale() * factor)
			end
			AssetLibrary.GroundPivot(platformTemplate)
		end
	end

	-- Six bases: three on the north side facing +Z, three on the south facing -Z
	local bases = {}
	local baseSpots = {}
	local xs = { -76, 0, 76 }
	for i, bx in ipairs(xs) do
		bases[i] = buildBase(world, i, bx, -58, 1, platformTemplate)
		table.insert(baseSpots, { X = bx, Z = -58, Facing = 1 })
	end
	for i, bx in ipairs(xs) do
		bases[i + 3] = buildBase(world, i + 3, bx, 58, -1, platformTemplate)
		table.insert(baseSpots, { X = bx, Z = 58, Facing = -1 })
	end

	-- Wooden wall segments as a partial perimeter behind each base
	local wallPack = AssetLibrary.LoadPack(WALLS_ID)
	if wallPack then
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
		if wallUnit then
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
			if segLen >= 2 and segLen <= 20 and protoSize.Y >= 1 then
				local count = math.min(8, math.floor(38 / segLen))
				for _, spot in ipairs(baseSpots) do
					local wallZ = spot.Z - spot.Facing * 17.5
					local startX = spot.X - (count * segLen) / 2 + segLen / 2
					for i = 0, count - 1 do
						local seg = wallUnit:Clone()
						local x = startX + i * segLen
						if seg:IsA("Model") then
							AssetLibrary.GroundPivot(seg)
							seg:PivotTo(CFrame.new(x, SLAB_TOP, wallZ) * CFrame.Angles(0, segYaw, 0))
						else
							seg.CFrame = CFrame.new(x, SLAB_TOP + seg.Size.Y / 2, wallZ) * CFrame.Angles(0, segYaw, 0)
						end
						seg.Parent = world
					end
				end
			end
		end
	end

	return {
		BeltTopY = beltTopY,
		BeltZ = 0,
		PlatformTopY = PLATFORM_TOP,
		Bases = bases,
	}
end

return WorldBuilder
