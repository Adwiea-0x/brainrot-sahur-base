-- CharacterFactory.luau (server)
-- Builds a brainrot character Model, hangs the floating info label (name / rarity / income) over
-- it, and owns the little walk animation every system shares: conveyor strolling, the dash to a
-- buyer's pad and the sad walk home after a drop.
--
-- The look comes from the real thing: Prepare() loads the owner's Creator Store character
-- models with InsertService (via AssetLibrary, which strips their scripts) in the background,
-- scales each one to about five studs and re-pivots it so its feet are its pivot. The conveyor
-- never waits for it: characters spawn part-built and swap to the real models as templates
-- arrive. If a model cannot be loaded, the character keeps the original part-built recipe.
--
-- GROUNDING: posing never assumes where a model's pivot sits. Every entry measures its own
-- GroundOffset — the height of the model's pivot above its bounding-box bottom — at build time,
-- and SetPose/GetFeet work in that measured offset. Feet land exactly on the belt or the pad no
-- matter how the model was authored. (The old code assumed the pivot was always the invisible
-- Root part's centre, half a stud above the feet; Model:PivotTo works in PivotOffset space,
-- which does not promise that, and characters hovered.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local AssetLibrary = require(script.Parent.AssetLibrary)

local CharacterFactory = {}

-- The invisible Root part (prompt + label anchor) rides this far above the character's feet.
local ROOT_LIFT = 0.5

-- Owner-owned Creator Store models for the cast, by BrainrotData id.
local ASSET_IDS = {
	TungTung = 138151705692565,
	Tralalero = 111854862176457,
	Ballerina = 81269930750607,
	Assassino = 88011361629493,
	Bombardiro = 111138597903728,
	Patapim = 121724230281477,
	Lirili = 77231614368559,
	Chimpanzini = 83732984780551,
	FrigoCamelo = 136392638607318,
	VacaSaturno = 76127116347738,
}
-- Fallback source if an individual model fails: a big brainrot pack, searched by name tokens.
local PACK_ID = 137461628889541
local PACK_TOKENS = {
	TungTung = { "tung" },
	Tralalero = { "tralalero" },
	Ballerina = { "ballerina", "cappuccina" },
	Assassino = { "assassino" },
	Bombardiro = { "bombardiro" },
	Patapim = { "patapim" },
	Lirili = { "lirili" },
	Chimpanzini = { "chimpanzini" },
	FrigoCamelo = { "frigo", "camelo" },
	VacaSaturno = { "vaca", "saturno" },
}

local templates = {} -- [defId] = sanitized, normalized Model waiting in ServerStorage
local prepared = false

-- Lazily load the fallback pack once and fish a named character model out of it.
local packContainer = nil
local function packModelFor(def): Model?
	if packContainer == nil then
		packContainer = AssetLibrary.LoadRaw(PACK_ID) or false
	end
	if not packContainer then
		return nil
	end
	local tokens = PACK_TOKENS[def.Id] or { string.lower(def.Name) }
	for _, descendant in ipairs(packContainer:GetDescendants()) do
		if descendant:IsA("Model") then
			local lname = string.lower(descendant.Name)
			for _, token in ipairs(tokens) do
				if string.find(lname, token, 1, true) then
					local usable = false
					for _, inner in ipairs(descendant:GetDescendants()) do
						if inner:IsA("BasePart") then
							usable = true
							break
						end
					end
					if usable then
						local clone = descendant:Clone()
						AssetLibrary.Sanitize(clone)
						return clone
					end
				end
			end
		end
	end
	return nil
end

-- Load every cast member's real model into ServerStorage — in the BACKGROUND. Prepare()
-- returns immediately; the conveyor starts at once with part-built characters and Build()
-- picks up each template the moment it lands. Loading can yield (InsertService) and, in v12,
-- could even throw (GroundPivot), so the whole body runs in a pcall'd task.spawn and every
-- single character's load is pcall'd on its own: no character, and no load failure, can ever
-- stall or kill the game. Anything that fails keeps its part-built recipe.
function CharacterFactory.Prepare()
	if prepared then
		return
	end
	prepared = true
	task.spawn(function()
		local ok, err = pcall(function()
			local folder = Instance.new("Folder")
			folder.Name = "BrainrotTemplates"
			folder.Parent = ServerStorage

			local loaded, fellBack = {}, {}
			for _, def in ipairs(BrainrotData.Cast) do
				local charOk, model = pcall(function()
					local m = nil
					local assetId = ASSET_IDS[def.Id]
					if assetId then
						m = AssetLibrary.LoadModel(assetId)
					end
					if not m then
						m = packModelFor(def)
					end
					if m and AssetLibrary.NormalizeCharacter(m) then
						return m
					end
					if m then
						m:Destroy()
					end
					return nil
				end)
				if charOk and model then
					model.Name = def.Id
					model.Archivable = true
					model.Parent = folder
					templates[def.Id] = model
					table.insert(loaded, def.Name)
				else
					if not charOk then
						print("[SahurBase] Character load errored for " .. def.Name .. " (part-built fallback): " .. tostring(model))
					end
					table.insert(fellBack, def.Name)
				end
			end
			print("[SahurBase] Creator Store character models loaded: " .. table.concat(loaded, ", "))
			if #fellBack > 0 then
				print("[SahurBase] Part-built fallback characters: " .. table.concat(fellBack, ", "))
			end
		end)
		if not ok then
			print("[SahurBase] Character prepare FAILED (whole cast stays part-built): " .. tostring(err))
		end
	end)
end

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

-- The original look: a character assembled from its BrainrotData part recipe, feet at y=0.
local function buildPartModel(def): Model
	local model = Instance.new("Model")
	model.Name = def.Name
	local origin = CFrame.new(0, ROOT_LIFT, 0)
	for _, spec in ipairs(def.Parts) do
		buildPart(spec, origin).Parent = model
	end
	return model
end

-- Build a fresh brainrot entity (not yet parented anywhere). Call entry.Model.Parent = workspace
-- (or wherever) once built; pose it with SetPose before anyone sees it.
function CharacterFactory.Build(def)
	local model: Model
	local fromTemplate = templates[def.Id] ~= nil
	if fromTemplate then
		model = templates[def.Id]:Clone()
		model.Name = def.Name
	else
		model = buildPartModel(def)
	end

	-- The invisible Root part anchors the prompt and the label; it rides just above the feet and
	-- moves rigidly with the model wherever PivotTo takes it.
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 1, 2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Parent = model
	if fromTemplate then
		-- Template pivots are grounded (pivot == feet), so the Root sits ROOT_LIFT above it.
		root.CFrame = model:GetPivot() * CFrame.new(0, ROOT_LIFT, 0)
	else
		root.CFrame = CFrame.new(0, ROOT_LIFT, 0)
	end
	model.PrimaryPart = root

	-- Measure, don't assume: how far the model's pivot floats above its lowest point.
	local pivot = model:GetPivot()
	local bboxCf, bboxSize = model:GetBoundingBox()
	local groundOffset = pivot.Position.Y - (bboxCf.Position.Y - bboxSize.Y / 2)
	local height = bboxSize.Y

	-- The floating label: name, rarity in its colour, income, plus a context line the
	-- UpdateLabel caller controls (price on the belt, owner's name on a base).
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.Size = UDim2.fromOffset(250, 92)
	gui.StudsOffset = Vector3.new(0, height + 0.9, 0)
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
		GroundOffset = groundOffset,
		Height = height,
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

-- Pose the model: its lowest point rests exactly at feetPos (plus the walk-bob), facing yaw,
-- with a side-to-side waddle. GroundOffset does the grounding; the bob rides on top of it.
function CharacterFactory.SetPose(entry, feetPos: Vector3, yaw: number, bobY: number, waddle: number)
	local cf = CFrame.new(feetPos.X, feetPos.Y + entry.GroundOffset + bobY, feetPos.Z)
		* CFrame.Angles(0, yaw, waddle)
	entry.Model:PivotTo(cf)
end

function CharacterFactory.GetFeet(entry): Vector3
	local pos = entry.Model:GetPivot().Position
	return Vector3.new(pos.X, pos.Y - entry.GroundOffset, pos.Z)
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
