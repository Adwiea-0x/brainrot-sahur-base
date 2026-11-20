-- Config.luau
-- Every tuning number for SAHUR BASE in one place: economy, conveyor, stealing, locks and upgrades.
-- Server and client both read this module; nothing here changes at runtime.

local Config = {
	-- Economy
	StartCash = 100, -- cash a fresh player spawns with (and what a rebirth resets to)
	IncomeTickSeconds = 1, -- how often placed brainrots pay their owners

	-- Bases
	BaseCount = 6,
	PadsPerBase = 8,

	-- Conveyor
	ConveyorMaxAlive = 9, -- brainrots walking the belt at once
	SpawnInterval = 2.6, -- seconds between spawn attempts
	BeltSpeed = 6, -- studs per second along the belt
	BeltStartX = -118,
	BeltEndX = 118,

	-- Stealing
	BaseWalkSpeed = 16,
	CarrySpeed = 11, -- carrying a stolen brainrot slows the thief down
	ClaimRadius = 27, -- how close to your own base centre a carried brainrot becomes yours
	SlapCooldown = 0.8,
	SlapBaseRadius = 8,
	SlapBasePower = 42,

	-- Base lock
	LockDuration = 60, -- seconds of steal protection per lock
	LockCooldown = 20, -- seconds before the base can be locked again

	-- Rebirth: cost grows per rebirth, each rebirth adds a permanent income multiplier step
	RebirthBaseCost = 20000,
	RebirthMultiplierStep = 0.5,

	-- Upgrades, bought at the base shop pads; the level is the index into these lists
	SlapUpgrades = {
		{ Cost = 500, Power = 58, Radius = 9.5 },
		{ Cost = 1500, Power = 74, Radius = 11 },
		{ Cost = 4000, Power = 92, Radius = 12.5 },
		{ Cost = 10000, Power = 115, Radius = 14 },
	},
	SpeedUpgrades = {
		{ Cost = 750, Speed = 18 },
		{ Cost = 2500, Speed = 20 },
		{ Cost = 7500, Speed = 23 },
	},
}

return Config
