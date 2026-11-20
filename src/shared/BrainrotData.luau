-- BrainrotData.luau
-- The cast of SAHUR BASE: ten original brainrot characters on a five-rarity ladder.
-- Each entry carries its shop numbers (Price, Income per second, spawn Weight) and a build recipe:
-- a list of part specs in "ground space" (Pos.y is studs above the character's feet, the character
-- faces +Z). CharacterFactory (server) turns a recipe into a Model; nothing here builds anything.

local BrainrotData = {}

BrainrotData.Rarities = {
	Common = { Color = Color3.fromRGB(168, 175, 186), Order = 1 },
	Rare = { Color = Color3.fromRGB(64, 145, 255), Order = 2 },
	Epic = { Color = Color3.fromRGB(178, 84, 255), Order = 3 },
	Legendary = { Color = Color3.fromRGB(255, 178, 26), Order = 4 },
	Mythic = { Color = Color3.fromRGB(255, 64, 92), Order = 5 },
}

-- Part spec shorthands used below:
--   Shape: "Block" | "Ball" | "Cylinder" | "Wedge"   Size/Pos: Vector3   Rot: Euler degrees (optional)
--   Cylinder parts are measured (height, diameter, diameter) with the height along local X,
--   so Rot = (0, 0, 90) stands one upright like a log.

BrainrotData.Cast = {
	{
		Id = "Patapim",
		Name = "Brr Brr Patapim",
		Rarity = "Common",
		Price = 100,
		Income = 1,
		Weight = 30,
		Height = 5.0,
		Parts = {
			{ Name = "Trunk", Shape = "Cylinder", Size = Vector3.new(3, 2, 2), Pos = Vector3.new(0, 1.8, 0), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(122, 82, 48), Material = Enum.Material.Wood },
			{ Name = "Canopy", Shape = "Ball", Size = Vector3.new(2.8, 2.6, 2.8), Pos = Vector3.new(0, 4.1, 0), Color = Color3.fromRGB(58, 148, 62), Material = Enum.Material.Grass },
			{ Name = "Nose", Shape = "Block", Size = Vector3.new(0.35, 0.35, 1.7), Pos = Vector3.new(0, 3.8, 1.1), Color = Color3.fromRGB(140, 96, 56), Material = Enum.Material.Wood },
			{ Name = "EyeL", Shape = "Ball", Size = Vector3.new(0.38, 0.38, 0.38), Pos = Vector3.new(-0.45, 4.25, 1.15), Color = Color3.fromRGB(255, 255, 255) },
			{ Name = "EyeR", Shape = "Ball", Size = Vector3.new(0.38, 0.38, 0.38), Pos = Vector3.new(0.45, 4.25, 1.15), Color = Color3.fromRGB(255, 255, 255) },
			{ Name = "ArmL", Shape = "Block", Size = Vector3.new(0.3, 1.6, 0.3), Pos = Vector3.new(-1.15, 2.2, 0), Rot = Vector3.new(0, 0, 35), Color = Color3.fromRGB(122, 82, 48), Material = Enum.Material.Wood },
			{ Name = "ArmR", Shape = "Block", Size = Vector3.new(0.3, 1.6, 0.3), Pos = Vector3.new(1.15, 2.2, 0), Rot = Vector3.new(0, 0, -35), Color = Color3.fromRGB(122, 82, 48), Material = Enum.Material.Wood },
			{ Name = "FootL", Shape = "Block", Size = Vector3.new(0.7, 0.3, 1.15), Pos = Vector3.new(-0.5, 0.15, 0.12), Color = Color3.fromRGB(96, 64, 38), Material = Enum.Material.Wood },
			{ Name = "FootR", Shape = "Block", Size = Vector3.new(0.7, 0.3, 1.15), Pos = Vector3.new(0.5, 0.15, 0.12), Color = Color3.fromRGB(96, 64, 38), Material = Enum.Material.Wood },
		},
	},
	{
		Id = "Lirili",
		Name = "Lirili Larila",
		Rarity = "Common",
		Price = 250,
		Income = 3,
		Weight = 26,
		Height = 4.4,
		Parts = {
			{ Name = "CactusBody", Shape = "Cylinder", Size = Vector3.new(2.6, 2.2, 2.2), Pos = Vector3.new(0, 1.65, 0), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(52, 168, 84), Material = Enum.Material.Grass },
			{ Name = "CactusArmL", Shape = "Cylinder", Size = Vector3.new(1.1, 0.55, 0.55), Pos = Vector3.new(-1.35, 2.1, 0), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(52, 168, 84), Material = Enum.Material.Grass },
			{ Name = "CactusArmR", Shape = "Cylinder", Size = Vector3.new(1.1, 0.55, 0.55), Pos = Vector3.new(1.35, 2.1, 0), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(52, 168, 84), Material = Enum.Material.Grass },
			{ Name = "Head", Shape = "Ball", Size = Vector3.new(1.6, 1.5, 1.6), Pos = Vector3.new(0, 3.55, 0.25), Color = Color3.fromRGB(158, 163, 176) },
			{ Name = "Trunk", Shape = "Block", Size = Vector3.new(0.42, 1.5, 0.42), Pos = Vector3.new(0, 2.8, 1.0), Color = Color3.fromRGB(138, 143, 156) },
			{ Name = "EarL", Shape = "Block", Size = Vector3.new(0.18, 1.1, 0.9), Pos = Vector3.new(-0.9, 3.65, 0.15), Color = Color3.fromRGB(148, 153, 166) },
			{ Name = "EarR", Shape = "Block", Size = Vector3.new(0.18, 1.1, 0.9), Pos = Vector3.new(0.9, 3.65, 0.15), Color = Color3.fromRGB(148, 153, 166) },
			{ Name = "LegFL", Shape = "Cylinder", Size = Vector3.new(0.7, 0.5, 0.5), Pos = Vector3.new(-0.65, 0.35, 0.6), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(148, 153, 166) },
			{ Name = "LegFR", Shape = "Cylinder", Size = Vector3.new(0.7, 0.5, 0.5), Pos = Vector3.new(0.65, 0.35, 0.6), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(148, 153, 166) },
			{ Name = "LegBL", Shape = "Cylinder", Size = Vector3.new(0.7, 0.5, 0.5), Pos = Vector3.new(-0.65, 0.35, -0.6), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(148, 153, 166) },
			{ Name = "LegBR", Shape = "Cylinder", Size = Vector3.new(0.7, 0.5, 0.5), Pos = Vector3.new(0.65, 0.35, -0.6), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(148, 153, 166) },
			{ Name = "SandalL", Shape = "Block", Size = Vector3.new(0.6, 0.16, 0.95), Pos = Vector3.new(-0.65, 0.08, 0.68), Color = Color3.fromRGB(255, 140, 40) },
			{ Name = "SandalR", Shape = "Block", Size = Vector3.new(0.6, 0.16, 0.95), Pos = Vector3.new(0.65, 0.08, 0.68), Color = Color3.fromRGB(255, 140, 40) },
		},
	},
	{
		Id = "Tralalero",
		Name = "Tralalero Tralala",
		Rarity = "Rare",
		Price = 750,
		Income = 9,
		Weight = 16,
		Height = 4.1,
		Parts = {
			{ Name = "Body", Shape = "Ball", Size = Vector3.new(3.5, 2.0, 2.1), Pos = Vector3.new(0, 2.25, 0), Color = Color3.fromRGB(64, 142, 214) },
			{ Name = "Belly", Shape = "Ball", Size = Vector3.new(2.6, 1.35, 1.7), Pos = Vector3.new(0, 1.95, 0.4), Color = Color3.fromRGB(226, 240, 250) },
			{ Name = "Snout", Shape = "Ball", Size = Vector3.new(1.7, 1.1, 1.3), Pos = Vector3.new(0, 2.2, 1.35), Color = Color3.fromRGB(84, 158, 224) },
			{ Name = "Teeth", Shape = "Block", Size = Vector3.new(1.3, 0.28, 0.3), Pos = Vector3.new(0, 1.78, 1.85), Color = Color3.fromRGB(255, 255, 255) },
			{ Name = "DorsalFin", Shape = "Block", Size = Vector3.new(0.22, 1.05, 1.0), Pos = Vector3.new(0, 3.45, -0.25), Rot = Vector3.new(22, 0, 0), Color = Color3.fromRGB(48, 118, 186) },
			{ Name = "TailFin", Shape = "Block", Size = Vector3.new(0.22, 1.3, 1.1), Pos = Vector3.new(0, 2.7, -1.95), Rot = Vector3.new(-32, 0, 0), Color = Color3.fromRGB(48, 118, 186) },
			{ Name = "EyeL", Shape = "Ball", Size = Vector3.new(0.4, 0.4, 0.4), Pos = Vector3.new(-0.62, 2.75, 1.35), Color = Color3.fromRGB(255, 255, 255) },
			{ Name = "EyeR", Shape = "Ball", Size = Vector3.new(0.4, 0.4, 0.4), Pos = Vector3.new(0.62, 2.75, 1.35), Color = Color3.fromRGB(255, 255, 255) },
			{ Name = "LegL", Shape = "Cylinder", Size = Vector3.new(1.1, 0.42, 0.42), Pos = Vector3.new(-0.95, 0.72, 0.25), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(64, 142, 214) },
			{ Name = "LegR", Shape = "Cylinder", Size = Vector3.new(1.1, 0.42, 0.42), Pos = Vector3.new(0.95, 0.72, 0.25), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(64, 142, 214) },
			{ Name = "LegB", Shape = "Cylinder", Size = Vector3.new(1.1, 0.42, 0.42), Pos = Vector3.new(0, 0.72, -0.95), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(64, 142, 214) },
			{ Name = "ShoeL", Shape = "Block", Size = Vector3.new(0.58, 0.34, 1.05), Pos = Vector3.new(-0.95, 0.17, 0.42), Color = Color3.fromRGB(232, 52, 52) },
			{ Name = "ShoeR", Shape = "Block", Size = Vector3.new(0.58, 0.34, 1.05), Pos = Vector3.new(0.95, 0.17, 0.42), Color = Color3.fromRGB(232, 52, 52) },
			{ Name = "ShoeB", Shape = "Block", Size = Vector3.new(0.58, 0.34, 1.05), Pos = Vector3.new(0, 0.17, -0.78), Color = Color3.fromRGB(232, 52, 52) },
		},
	},
	{
		Id = "Chimpanzini",
		Name = "Chimpanzini Bananini",
		Rarity = "Rare",
		Price = 1500,
		Income = 20,
		Weight = 12,
		Height = 4.5,
		Parts = {
			{ Name = "BananaBody", Shape = "Ball", Size = Vector3.new(2.2, 3.1, 1.9), Pos = Vector3.new(0, 1.75, 0), Color = Color3.fromRGB(250, 208, 52) },
			{ Name = "PeelL", Shape = "Block", Size = Vector3.new(0.55, 1.3, 0.16), Pos = Vector3.new(-0.85, 3.15, 0), Rot = Vector3.new(0, 0, 48), Color = Color3.fromRGB(255, 224, 92) },
			{ Name = "PeelR", Shape = "Block", Size = Vector3.new(0.55, 1.3, 0.16), Pos = Vector3.new(0.85, 3.15, 0), Rot = Vector3.new(0, 0, -48), Color = Color3.fromRGB(255, 224, 92) },
			{ Name = "PeelF", Shape = "Block", Size = Vector3.new(0.55, 1.3, 0.16), Pos = Vector3.new(0, 3.15, 0.8), Rot = Vector3.new(-48, 0, 0), Color = Color3.fromRGB(255, 224, 92) },
			{ Name = "Head", Shape = "Ball", Size = Vector3.new(1.35, 1.3, 1.3), Pos = Vector3.new(0, 3.6, 0.1), Color = Color3.fromRGB(112, 74, 44) },
			{ Name = "Face", Shape = "Ball", Size = Vector3.new(0.98, 0.85, 0.6), Pos = Vector3.new(0, 3.5, 0.62), Color = Color3.fromRGB(222, 184, 138) },
			{ Name = "EarL", Shape = "Ball", Size = Vector3.new(0.46, 0.46, 0.3), Pos = Vector3.new(-0.72, 3.65, 0.1), Color = Color3.fromRGB(222, 184, 138) },
			{ Name = "EarR", Shape = "Ball", Size = Vector3.new(0.46, 0.46, 0.3), Pos = Vector3.new(0.72, 3.65, 0.1), Color = Color3.fromRGB(222, 184, 138) },
			{ Name = "ArmL", Shape = "Block", Size = Vector3.new(0.32, 1.5, 0.32), Pos = Vector3.new(-1.15, 1.9, 0.1), Rot = Vector3.new(0, 0, 18), Color = Color3.fromRGB(112, 74, 44) },
			{ Name = "ArmR", Shape = "Block", Size = Vector3.new(0.32, 1.5, 0.32), Pos = Vector3.new(1.15, 1.9, 0.1), Rot = Vector3.new(0, 0, -18), Color = Color3.fromRGB(112, 74, 44) },
			{ Name = "FootL", Shape = "Block", Size = Vector3.new(0.55, 0.3, 0.95), Pos = Vector3.new(-0.5, 0.15, 0.25), Color = Color3.fromRGB(112, 74, 44) },
			{ Name = "FootR", Shape = "Block", Size = Vector3.new(0.55, 0.3, 0.95), Pos = Vector3.new(0.5, 0.15, 0.25), Color = Color3.fromRGB(112, 74, 44) },
		},
	},
	{
		Id = "Ballerina",
		Name = "Ballerina Cappuccina",
		Rarity = "Epic",
		Price = 4000,
		Income = 55,
		Weight = 7,
		Height = 4.3,
		Parts = {
			{ Name = "Cup", Shape = "Cylinder", Size = Vector3.new(2.1, 2.35, 2.35), Pos = Vector3.new(0, 2.45, 0), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(250, 247, 242) },
			{ Name = "Coffee", Shape = "Cylinder", Size = Vector3.new(0.22, 2.1, 2.1), Pos = Vector3.new(0, 3.55, 0), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(112, 66, 34) },
			{ Name = "Handle", Shape = "Block", Size = Vector3.new(0.22, 0.95, 0.7), Pos = Vector3.new(1.32, 2.5, 0), Color = Color3.fromRGB(240, 236, 228) },
			{ Name = "EyeL", Shape = "Ball", Size = Vector3.new(0.3, 0.42, 0.2), Pos = Vector3.new(-0.45, 2.6, 1.14), Color = Color3.fromRGB(28, 24, 24) },
			{ Name = "EyeR", Shape = "Ball", Size = Vector3.new(0.3, 0.42, 0.2), Pos = Vector3.new(0.45, 2.6, 1.14), Color = Color3.fromRGB(28, 24, 24) },
			{ Name = "BowL", Shape = "Ball", Size = Vector3.new(0.5, 0.34, 0.3), Pos = Vector3.new(-0.3, 3.78, 0.55), Color = Color3.fromRGB(255, 120, 178) },
			{ Name = "BowR", Shape = "Ball", Size = Vector3.new(0.5, 0.34, 0.3), Pos = Vector3.new(0.3, 3.78, 0.55), Color = Color3.fromRGB(255, 120, 178) },
			{ Name = "Tutu", Shape = "Ball", Size = Vector3.new(3.3, 0.95, 3.3), Pos = Vector3.new(0, 1.28, 0), Color = Color3.fromRGB(255, 158, 205) },
			{ Name = "ArmL", Shape = "Block", Size = Vector3.new(0.26, 1.45, 0.26), Pos = Vector3.new(-1.15, 2.45, 0), Rot = Vector3.new(0, 0, -52), Color = Color3.fromRGB(250, 247, 242) },
			{ Name = "ArmR", Shape = "Block", Size = Vector3.new(0.26, 1.45, 0.26), Pos = Vector3.new(1.15, 2.45, 0), Rot = Vector3.new(0, 0, 52), Color = Color3.fromRGB(250, 247, 242) },
			{ Name = "LegL", Shape = "Block", Size = Vector3.new(0.3, 1.0, 0.3), Pos = Vector3.new(-0.42, 0.55, 0), Color = Color3.fromRGB(250, 247, 242) },
			{ Name = "LegR", Shape = "Block", Size = Vector3.new(0.3, 1.0, 0.3), Pos = Vector3.new(0.42, 0.55, 0), Color = Color3.fromRGB(250, 247, 242) },
			{ Name = "ShoeL", Shape = "Block", Size = Vector3.new(0.36, 0.2, 0.72), Pos = Vector3.new(-0.42, 0.1, 0.16), Color = Color3.fromRGB(255, 120, 178) },
			{ Name = "ShoeR", Shape = "Block", Size = Vector3.new(0.36, 0.2, 0.72), Pos = Vector3.new(0.42, 0.1, 0.16), Color = Color3.fromRGB(255, 120, 178) },
		},
	},
	{
		Id = "Assassino",
		Name = "Cappuccino Assassino",
		Rarity = "Epic",
		Price = 7500,
		Income = 110,
		Weight = 5,
		Height = 4.3,
		Parts = {
			{ Name = "Cup", Shape = "Cylinder", Size = Vector3.new(2.1, 2.35, 2.35), Pos = Vector3.new(0, 2.45, 0), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(74, 78, 92) },
			{ Name = "Coffee", Shape = "Cylinder", Size = Vector3.new(0.22, 2.1, 2.1), Pos = Vector3.new(0, 3.55, 0), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(52, 32, 18) },
			{ Name = "Headband", Shape = "Cylinder", Size = Vector3.new(0.52, 2.5, 2.5), Pos = Vector3.new(0, 3.12, 0), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(214, 40, 48) },
			{ Name = "BandTailL", Shape = "Block", Size = Vector3.new(0.3, 0.95, 0.14), Pos = Vector3.new(-0.35, 2.6, -1.25), Rot = Vector3.new(24, 0, 10), Color = Color3.fromRGB(214, 40, 48) },
			{ Name = "BandTailR", Shape = "Block", Size = Vector3.new(0.3, 0.95, 0.14), Pos = Vector3.new(0.35, 2.6, -1.25), Rot = Vector3.new(24, 0, -10), Color = Color3.fromRGB(214, 40, 48) },
			{ Name = "EyeL", Shape = "Block", Size = Vector3.new(0.44, 0.14, 0.12), Pos = Vector3.new(-0.46, 2.62, 1.16), Rot = Vector3.new(0, 0, -18), Color = Color3.fromRGB(16, 16, 20) },
			{ Name = "EyeR", Shape = "Block", Size = Vector3.new(0.44, 0.14, 0.12), Pos = Vector3.new(0.46, 2.62, 1.16), Rot = Vector3.new(0, 0, 18), Color = Color3.fromRGB(16, 16, 20) },
			{ Name = "KatanaBlade", Shape = "Block", Size = Vector3.new(0.1, 2.7, 0.3), Pos = Vector3.new(0.75, 2.6, -1.15), Rot = Vector3.new(0, 0, 42), Color = Color3.fromRGB(205, 214, 224) },
			{ Name = "KatanaGrip", Shape = "Block", Size = Vector3.new(0.16, 0.8, 0.36), Pos = Vector3.new(0.08, 1.72, -1.15), Rot = Vector3.new(0, 0, 42), Color = Color3.fromRGB(22, 22, 28) },
			{ Name = "ArmL", Shape = "Block", Size = Vector3.new(0.26, 1.3, 0.26), Pos = Vector3.new(-1.2, 2.2, 0), Rot = Vector3.new(0, 0, 24), Color = Color3.fromRGB(60, 63, 76) },
			{ Name = "ArmR", Shape = "Block", Size = Vector3.new(0.26, 1.3, 0.26), Pos = Vector3.new(1.2, 2.2, 0), Rot = Vector3.new(0, 0, -24), Color = Color3.fromRGB(60, 63, 76) },
			{ Name = "LegL", Shape = "Block", Size = Vector3.new(0.32, 1.05, 0.32), Pos = Vector3.new(-0.45, 0.55, 0), Color = Color3.fromRGB(52, 55, 66) },
			{ Name = "LegR", Shape = "Block", Size = Vector3.new(0.32, 1.05, 0.32), Pos = Vector3.new(0.45, 0.55, 0), Color = Color3.fromRGB(52, 55, 66) },
			{ Name = "ShoeL", Shape = "Block", Size = Vector3.new(0.4, 0.2, 0.75), Pos = Vector3.new(-0.45, 0.1, 0.15), Color = Color3.fromRGB(22, 22, 28) },
			{ Name = "ShoeR", Shape = "Block", Size = Vector3.new(0.4, 0.2, 0.75), Pos = Vector3.new(0.45, 0.1, 0.15), Color = Color3.fromRGB(22, 22, 28) },
		},
	},
	{
		Id = "TungTung",
		Name = "Tung Tung Sahur",
		Rarity = "Legendary",
		Price = 15000,
		Income = 240,
		Weight = 2.5,
		Height = 4.1,
		Parts = {
			{ Name = "LogBody", Shape = "Cylinder", Size = Vector3.new(3.1, 2.3, 2.3), Pos = Vector3.new(0, 1.85, 0), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(146, 100, 56), Material = Enum.Material.Wood },
			{ Name = "TopRing", Shape = "Cylinder", Size = Vector3.new(0.18, 2.05, 2.05), Pos = Vector3.new(0, 3.42, 0), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(196, 152, 96), Material = Enum.Material.Wood },
			{ Name = "EyeL", Shape = "Ball", Size = Vector3.new(0.42, 0.42, 0.3), Pos = Vector3.new(-0.48, 2.45, 1.08), Color = Color3.fromRGB(255, 255, 255) },
			{ Name = "EyeR", Shape = "Ball", Size = Vector3.new(0.42, 0.42, 0.3), Pos = Vector3.new(0.48, 2.45, 1.08), Color = Color3.fromRGB(255, 255, 255) },
			{ Name = "PupilL", Shape = "Ball", Size = Vector3.new(0.2, 0.2, 0.14), Pos = Vector3.new(-0.48, 2.45, 1.24), Color = Color3.fromRGB(20, 16, 12) },
			{ Name = "PupilR", Shape = "Ball", Size = Vector3.new(0.2, 0.2, 0.14), Pos = Vector3.new(0.48, 2.45, 1.24), Color = Color3.fromRGB(20, 16, 12) },
			{ Name = "Mouth", Shape = "Block", Size = Vector3.new(0.85, 0.16, 0.12), Pos = Vector3.new(0, 1.85, 1.16), Color = Color3.fromRGB(70, 44, 22) },
			{ Name = "ArmL", Shape = "Cylinder", Size = Vector3.new(1.5, 0.34, 0.34), Pos = Vector3.new(-1.3, 2.1, 0), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(146, 100, 56), Material = Enum.Material.Wood },
			{ Name = "ArmR", Shape = "Cylinder", Size = Vector3.new(1.5, 0.34, 0.34), Pos = Vector3.new(1.3, 2.3, 0.2), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(146, 100, 56), Material = Enum.Material.Wood },
			{ Name = "Bat", Shape = "Cylinder", Size = Vector3.new(2.7, 0.4, 0.4), Pos = Vector3.new(1.62, 3.35, 0.35), Rot = Vector3.new(0, 0, -38), Color = Color3.fromRGB(214, 172, 106), Material = Enum.Material.Wood },
			{ Name = "LegL", Shape = "Block", Size = Vector3.new(0.45, 0.55, 0.45), Pos = Vector3.new(-0.55, 0.28, 0), Color = Color3.fromRGB(128, 86, 48), Material = Enum.Material.Wood },
			{ Name = "LegR", Shape = "Block", Size = Vector3.new(0.45, 0.55, 0.45), Pos = Vector3.new(0.55, 0.28, 0), Color = Color3.fromRGB(128, 86, 48), Material = Enum.Material.Wood },
		},
	},
	{
		Id = "FrigoCamelo",
		Name = "Frigo Camelo",
		Rarity = "Legendary",
		Price = 30000,
		Income = 500,
		Weight = 1.5,
		Height = 5.5,
		Parts = {
			{ Name = "FridgeBody", Shape = "Block", Size = Vector3.new(2.6, 3.4, 1.8), Pos = Vector3.new(0, 2.15, 0), Color = Color3.fromRGB(238, 242, 246) },
			{ Name = "FreezerLine", Shape = "Block", Size = Vector3.new(2.64, 0.1, 1.84), Pos = Vector3.new(0, 3.15, 0), Color = Color3.fromRGB(168, 178, 190) },
			{ Name = "DoorHandle", Shape = "Block", Size = Vector3.new(0.14, 0.9, 0.14), Pos = Vector3.new(1.05, 2.5, 0.97), Color = Color3.fromRGB(140, 150, 164) },
			{ Name = "ColdMist", Shape = "Block", Size = Vector3.new(1.9, 0.5, 0.3), Pos = Vector3.new(0, 0.85, 1.0), Color = Color3.fromRGB(170, 225, 255), Transparency = 0.45 },
			{ Name = "Neck", Shape = "Block", Size = Vector3.new(0.52, 1.7, 0.52), Pos = Vector3.new(0, 4.05, 0.95), Rot = Vector3.new(28, 0, 0), Color = Color3.fromRGB(198, 152, 96) },
			{ Name = "Head", Shape = "Block", Size = Vector3.new(0.95, 0.72, 1.25), Pos = Vector3.new(0, 4.85, 1.45), Color = Color3.fromRGB(206, 162, 104) },
			{ Name = "Snout", Shape = "Block", Size = Vector3.new(0.7, 0.5, 0.55), Pos = Vector3.new(0, 4.68, 2.2), Color = Color3.fromRGB(222, 184, 128) },
			{ Name = "EarL", Shape = "Ball", Size = Vector3.new(0.34, 0.3, 0.2), Pos = Vector3.new(-0.55, 5.15, 1.2), Color = Color3.fromRGB(198, 152, 96) },
			{ Name = "EarR", Shape = "Ball", Size = Vector3.new(0.34, 0.3, 0.2), Pos = Vector3.new(0.55, 5.15, 1.2), Color = Color3.fromRGB(198, 152, 96) },
			{ Name = "EyeL", Shape = "Ball", Size = Vector3.new(0.2, 0.2, 0.14), Pos = Vector3.new(-0.3, 4.98, 2.05), Color = Color3.fromRGB(24, 20, 16) },
			{ Name = "EyeR", Shape = "Ball", Size = Vector3.new(0.2, 0.2, 0.14), Pos = Vector3.new(0.3, 4.98, 2.05), Color = Color3.fromRGB(24, 20, 16) },
			{ Name = "LegFL", Shape = "Block", Size = Vector3.new(0.42, 1.0, 0.42), Pos = Vector3.new(-0.95, 0.5, 0.6), Color = Color3.fromRGB(198, 152, 96) },
			{ Name = "LegFR", Shape = "Block", Size = Vector3.new(0.42, 1.0, 0.42), Pos = Vector3.new(0.95, 0.5, 0.6), Color = Color3.fromRGB(198, 152, 96) },
			{ Name = "LegBL", Shape = "Block", Size = Vector3.new(0.42, 1.0, 0.42), Pos = Vector3.new(-0.95, 0.5, -0.6), Color = Color3.fromRGB(198, 152, 96) },
			{ Name = "LegBR", Shape = "Block", Size = Vector3.new(0.42, 1.0, 0.42), Pos = Vector3.new(0.95, 0.5, -0.6), Color = Color3.fromRGB(198, 152, 96) },
		},
	},
	{
		Id = "Bombardiro",
		Name = "Bombardiro Crocodilo",
		Rarity = "Mythic",
		Price = 75000,
		Income = 1400,
		Weight = 0.7,
		Height = 3.7,
		Parts = {
			{ Name = "Body", Shape = "Ball", Size = Vector3.new(2.3, 1.9, 4.3), Pos = Vector3.new(0, 1.95, 0), Color = Color3.fromRGB(74, 148, 66) },
			{ Name = "Snout", Shape = "Block", Size = Vector3.new(1.55, 0.75, 1.5), Pos = Vector3.new(0, 1.7, 2.6), Color = Color3.fromRGB(84, 160, 76) },
			{ Name = "Teeth", Shape = "Block", Size = Vector3.new(1.4, 0.22, 0.25), Pos = Vector3.new(0, 1.38, 3.25), Color = Color3.fromRGB(255, 255, 255) },
			{ Name = "EyeL", Shape = "Ball", Size = Vector3.new(0.42, 0.42, 0.42), Pos = Vector3.new(-0.55, 2.85, 1.7), Color = Color3.fromRGB(255, 235, 120) },
			{ Name = "EyeR", Shape = "Ball", Size = Vector3.new(0.42, 0.42, 0.42), Pos = Vector3.new(0.55, 2.85, 1.7), Color = Color3.fromRGB(255, 235, 120) },
			{ Name = "Tail", Shape = "Wedge", Size = Vector3.new(1.5, 1.0, 2.2), Pos = Vector3.new(0, 1.7, -3.0), Rot = Vector3.new(0, 180, 0), Color = Color3.fromRGB(64, 134, 58) },
			{ Name = "WingL", Shape = "Block", Size = Vector3.new(2.8, 0.16, 1.15), Pos = Vector3.new(-2.3, 2.55, 0.1), Color = Color3.fromRGB(148, 158, 170) },
			{ Name = "WingR", Shape = "Block", Size = Vector3.new(2.8, 0.16, 1.15), Pos = Vector3.new(2.3, 2.55, 0.1), Color = Color3.fromRGB(148, 158, 170) },
			{ Name = "EngineL", Shape = "Cylinder", Size = Vector3.new(0.9, 0.55, 0.55), Pos = Vector3.new(-2.3, 2.2, 0.55), Rot = Vector3.new(90, 0, 0), Color = Color3.fromRGB(96, 104, 116) },
			{ Name = "EngineR", Shape = "Cylinder", Size = Vector3.new(0.9, 0.55, 0.55), Pos = Vector3.new(2.3, 2.2, 0.55), Rot = Vector3.new(90, 0, 0), Color = Color3.fromRGB(96, 104, 116) },
			{ Name = "PropL", Shape = "Block", Size = Vector3.new(0.14, 1.5, 0.3), Pos = Vector3.new(-2.3, 2.2, 1.1), Color = Color3.fromRGB(30, 30, 34) },
			{ Name = "PropR", Shape = "Block", Size = Vector3.new(0.14, 1.5, 0.3), Pos = Vector3.new(2.3, 2.2, 1.1), Color = Color3.fromRGB(30, 30, 34) },
			{ Name = "BombL", Shape = "Ball", Size = Vector3.new(0.75, 0.95, 0.75), Pos = Vector3.new(-0.85, 0.75, 0.5), Color = Color3.fromRGB(34, 36, 42) },
			{ Name = "BombR", Shape = "Ball", Size = Vector3.new(0.75, 0.95, 0.75), Pos = Vector3.new(0.85, 0.75, 0.5), Color = Color3.fromRGB(34, 36, 42) },
			{ Name = "LegFL", Shape = "Cylinder", Size = Vector3.new(0.65, 0.4, 0.4), Pos = Vector3.new(-0.7, 0.33, 1.2), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(64, 134, 58) },
			{ Name = "LegFR", Shape = "Cylinder", Size = Vector3.new(0.65, 0.4, 0.4), Pos = Vector3.new(0.7, 0.33, 1.2), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(64, 134, 58) },
			{ Name = "LegBL", Shape = "Cylinder", Size = Vector3.new(0.65, 0.4, 0.4), Pos = Vector3.new(-0.7, 0.33, -1.2), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(64, 134, 58) },
			{ Name = "LegBR", Shape = "Cylinder", Size = Vector3.new(0.65, 0.4, 0.4), Pos = Vector3.new(0.7, 0.33, -1.2), Rot = Vector3.new(0, 0, 90), Color = Color3.fromRGB(64, 134, 58) },
		},
	},
	{
		Id = "VacaSaturno",
		Name = "La Vaca Saturno Saturnita",
		Rarity = "Mythic",
		Price = 150000,
		Income = 3000,
		Weight = 0.3,
		Height = 3.9,
		Parts = {
			{ Name = "Body", Shape = "Ball", Size = Vector3.new(2.5, 2.3, 3.5), Pos = Vector3.new(0, 2.0, 0), Color = Color3.fromRGB(246, 246, 248) },
			{ Name = "SpotL", Shape = "Ball", Size = Vector3.new(0.25, 0.9, 1.2), Pos = Vector3.new(-1.22, 2.3, -0.4), Color = Color3.fromRGB(38, 36, 40) },
			{ Name = "SpotR", Shape = "Ball", Size = Vector3.new(0.25, 0.8, 1.0), Pos = Vector3.new(1.22, 1.8, 0.6), Color = Color3.fromRGB(38, 36, 40) },
			{ Name = "SpotTop", Shape = "Ball", Size = Vector3.new(1.0, 0.3, 0.9), Pos = Vector3.new(0.3, 3.1, -0.9), Color = Color3.fromRGB(38, 36, 40) },
			{ Name = "Ring", Shape = "Cylinder", Size = Vector3.new(0.16, 6.4, 6.4), Pos = Vector3.new(0, 2.0, 0), Rot = Vector3.new(18, 0, 90), Color = Color3.fromRGB(255, 196, 110), Transparency = 0.2 },
			{ Name = "Head", Shape = "Block", Size = Vector3.new(1.3, 1.1, 1.1), Pos = Vector3.new(0, 2.65, 2.05), Color = Color3.fromRGB(246, 246, 248) },
			{ Name = "Snout", Shape = "Block", Size = Vector3.new(1.05, 0.62, 0.5), Pos = Vector3.new(0, 2.42, 2.75), Color = Color3.fromRGB(248, 168, 190) },
			{ Name = "HornL", Shape = "Block", Size = Vector3.new(0.18, 0.5, 0.18), Pos = Vector3.new(-0.5, 3.4, 1.95), Rot = Vector3.new(0, 0, 28), Color = Color3.fromRGB(226, 198, 150) },
			{ Name = "HornR", Shape = "Block", Size = Vector3.new(0.18, 0.5, 0.18), Pos = Vector3.new(0.5, 3.4, 1.95), Rot = Vector3.new(0, 0, -28), Color = Color3.fromRGB(226, 198, 150) },
			{ Name = "EarL", Shape = "Block", Size = Vector3.new(0.55, 0.24, 0.4), Pos = Vector3.new(-0.82, 3.05, 2.0), Color = Color3.fromRGB(248, 168, 190) },
			{ Name = "EarR", Shape = "Block", Size = Vector3.new(0.55, 0.24, 0.4), Pos = Vector3.new(0.82, 3.05, 2.0), Color = Color3.fromRGB(248, 168, 190) },
			{ Name = "EyeL", Shape = "Ball", Size = Vector3.new(0.2, 0.2, 0.14), Pos = Vector3.new(-0.32, 2.85, 2.58), Color = Color3.fromRGB(22, 20, 20) },
			{ Name = "EyeR", Shape = "Ball", Size = Vector3.new(0.2, 0.2, 0.14), Pos = Vector3.new(0.32, 2.85, 2.58), Color = Color3.fromRGB(22, 20, 20) },
			{ Name = "Udder", Shape = "Ball", Size = Vector3.new(1.0, 0.7, 1.0), Pos = Vector3.new(0, 0.85, -0.7), Color = Color3.fromRGB(248, 168, 190) },
			{ Name = "LegFL", Shape = "Block", Size = Vector3.new(0.4, 1.0, 0.4), Pos = Vector3.new(-0.75, 0.5, 0.95), Color = Color3.fromRGB(240, 240, 244) },
			{ Name = "LegFR", Shape = "Block", Size = Vector3.new(0.4, 1.0, 0.4), Pos = Vector3.new(0.75, 0.5, 0.95), Color = Color3.fromRGB(240, 240, 244) },
			{ Name = "LegBL", Shape = "Block", Size = Vector3.new(0.4, 1.0, 0.4), Pos = Vector3.new(-0.75, 0.5, -0.95), Color = Color3.fromRGB(240, 240, 244) },
			{ Name = "LegBR", Shape = "Block", Size = Vector3.new(0.4, 1.0, 0.4), Pos = Vector3.new(0.75, 0.5, -0.95), Color = Color3.fromRGB(240, 240, 244) },
		},
	},
}

BrainrotData.ById = {}
for _, def in ipairs(BrainrotData.Cast) do
	BrainrotData.ById[def.Id] = def
end

-- Pick a random cast member, weighted so commons flood the belt and mythics stay precious.
function BrainrotData.RollSpawn(rng: Random)
	local total = 0
	for _, def in ipairs(BrainrotData.Cast) do
		total += def.Weight
	end
	local roll = rng:NextNumber(0, total)
	for _, def in ipairs(BrainrotData.Cast) do
		roll -= def.Weight
		if roll <= 0 then
			return def
		end
	end
	return BrainrotData.Cast[1]
end

-- "$1,500" style formatting shared by labels, prompts and the HUD.
function BrainrotData.FormatCash(amount: number): string
	local negative = amount < 0
	local digits = tostring(math.floor(math.abs(amount)))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return (negative and "-$" or "$") .. grouped
end

return BrainrotData
