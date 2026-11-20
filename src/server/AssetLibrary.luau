-- AssetLibrary.luau (server)
-- The bridge to the owner's Creator Store inventory. Every visual that is not built from parts
-- (brainrot character models, the base platform, the conveyor, decor) is loaded at server start
-- with InsertService:LoadAsset — which only works because the place owner owns these assets —
-- then sanitized and normalized before anything clones it.
--
-- Sanitizing is not optional: store models routinely carry scripts, prompts, remotes, humanoids
-- and looping sounds. All of that is stripped here, and every part is anchored and made
-- non-collidable, so a loaded model is pure scenery that our own code moves around.

local InsertService = game:GetService("InsertService")

local AssetLibrary = {}

-- Raw LoadAsset, pcall-wrapped. Returns the container instance LoadAsset hands back, or nil.
function AssetLibrary.LoadRaw(assetId: number)
	local ok, container = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if ok and container then
		return container
	end
	return nil
end

-- Strip everything executable or interactive out of a loaded asset, and freeze its parts.
-- Scripts (Script / LocalScript / ModuleScript are all LuaSourceContainers), prompts, remotes,
-- bindables, humanoids and sounds are destroyed; parts become anchored ghost geometry.
function AssetLibrary.Sanitize(root: Instance)
	local doomed = {}
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("LuaSourceContainer")
			or descendant:IsA("ProximityPrompt")
			or descendant:IsA("RemoteEvent")
			or descendant:IsA("RemoteFunction")
			or descendant:IsA("BindableEvent")
			or descendant:IsA("BindableFunction")
			or descendant:IsA("Humanoid")
			or descendant:IsA("Sound")
		then
			table.insert(doomed, descendant)
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
		end
	end
	-- Destroy children before parents so nothing is orphaned mid-strip.
	for i = #doomed, 1, -1 do
		doomed[i]:Destroy()
	end
	if root:IsA("BasePart") then
		root.Anchored = true
		root.CanCollide = false
		root.CanQuery = false
		root.CanTouch = false
		root.Massless = true
	end
end

local function hasParts(inst: Instance): boolean
	for _, descendant in ipairs(inst:GetDescendants()) do
		if descendant:IsA("BasePart") then
			return true
		end
	end
	return false
end

-- LoadAsset hands back a container: sometimes the model itself, sometimes a wrapper holding the
-- real model as a child. Pull the usable Model out (detaching it before the wrapper dies).
function AssetLibrary.ExtractModel(container: Instance): Model?
	if not container then
		return nil
	end
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Model") and hasParts(child) then
			child.Parent = nil
			if container ~= child then
				container:Destroy()
			end
			return child
		end
	end
	if hasParts(container) then
		if container:IsA("Model") then
			return container
		end
		local wrapper = Instance.new("Model")
		wrapper.Name = container.Name
		for _, child in ipairs(container:GetChildren()) do
			child.Parent = wrapper
		end
		container:Destroy()
		return wrapper
	end
	container:Destroy()
	return nil
end

-- Load one asset as a single sanitized Model (characters, base platform, conveyor, lamp).
function AssetLibrary.LoadModel(assetId: number): Model?
	local container = AssetLibrary.LoadRaw(assetId)
	if not container then
		return nil
	end
	local model = AssetLibrary.ExtractModel(container)
	if not model then
		return nil
	end
	AssetLibrary.Sanitize(model)
	model.Archivable = true
	return model
end

-- Load one asset as a sanitized pack: the whole container, unextracted, so callers can pick
-- sub-models out of it (foliage, neon signs, wooden walls).
function AssetLibrary.LoadPack(assetId: number): Model?
	local container = AssetLibrary.LoadRaw(assetId)
	if not container then
		return nil
	end
	local pack: Model
	if container:IsA("Model") then
		pack = container
	else
		pack = Instance.new("Model")
		pack.Name = container.Name
		for _, child in ipairs(container:GetChildren()) do
			child.Parent = pack
		end
		container:Destroy()
	end
	AssetLibrary.Sanitize(pack)
	pack.Archivable = true
	return pack
end

-- Re-pivot a model so its pivot sits at the bottom centre of its bounding box: after this,
-- PivotTo(feetCFrame) puts the model's lowest point exactly on feetCFrame's origin.
-- Returns the bounding box size measured before re-pivoting.
function AssetLibrary.GroundPivot(model: Model): Vector3
	local cf, size = model:GetBoundingBox()
	if size.Y <= 0 then
		return size
	end
	local bottomCentre = CFrame.new(cf.Position.X, cf.Position.Y - size.Y / 2, cf.Position.Z)
	model.PivotOffset = model:GetPivot():ToObjectSpace(bottomCentre)
	return size
end

-- Uniformly scale a model so its bounding box is targetHeight tall; if maxFootprint is given,
-- the horizontal extent is capped too (very wide models shrink further). Returns success.
function AssetLibrary.ScaleToHeight(model: Model, targetHeight: number, maxFootprint: number?): boolean
	local _, size = model:GetBoundingBox()
	if size.Y <= 0.05 then
		return false
	end
	local factor = targetHeight / size.Y
	if maxFootprint then
		local footprint = math.max(size.X, size.Z)
		if footprint * factor > maxFootprint then
			factor = maxFootprint / footprint
		end
	end
	if factor <= 0 then
		return false
	end
	model:ScaleTo(model:GetScale() * factor)
	return true
end

-- Normalize a character model: about five studs tall, footprint capped, pivot grounded.
function AssetLibrary.NormalizeCharacter(model: Model): boolean
	if not AssetLibrary.ScaleToHeight(model, 5, 9) then
		return false
	end
	AssetLibrary.GroundPivot(model)
	local _, size = model:GetBoundingBox()
	return size.Y > 0.5
end

-- Place a model so its bounding-box centre lands exactly on the given CFrame (rotation included).
function AssetLibrary.CenterPlace(model: Model, cf: CFrame)
	local bboxCf, _ = model:GetBoundingBox()
	local pivot = model:GetPivot()
	local centreInPivotSpace = pivot:ToObjectSpace(bboxCf)
	model:PivotTo(cf * centreInPivotSpace:Inverse())
end

return AssetLibrary
