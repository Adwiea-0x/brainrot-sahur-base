# SAHUR BASE — Steal a Brainrot

A 3D Steal-a-Brainrot game for Roblox. The world structure, economy and every system are Luau
code, and the world builds 100% procedurally — a safety baseplate, the plaza, the belt and all
six bases stand before any asset is touched, and a neutral plaza spawn guarantees a landing
point. The characters and the key set dressing are real Creator Store models owned by the place
owner, loaded in the background with `InsertService:LoadAsset`, sanitized (all scripts, prompts
and remotes stripped) and normalized by the game code — every load is pcall-wrapped, so a model
that fails or misbehaves degrades to the part-built lookalike and can never break the world.
Entry for make.fun's **roblox-brainrot-01** bounty, "Make the best AI Roblox brainrot game".

**Play it:** https://www.roblox.com/games/107649210185098

## How to play

- You spawn at one of **six bases** around a plaza. Down the middle runs the **Brainrot Express**,
  a conveyor belt carrying absurd characters past your base, each with a price tag.
- **Buy** one (walk up, use the prompt) and it hops off the belt and walks to a pad on your base,
  where it earns you cash every second. Rarer brainrots cost more and pay far more.
- **Steal**: any brainrot standing on a rival's base can be grabbed. It rides on your head while
  you run — slower than usual — and becomes yours the moment you reach your own base.
- **Defend**: you carry a **slap hand**. Bonk a thief and their catch drops and walks home.
  Your base's **Lock** pad seals it for 60 seconds so nobody can steal from you.
- **Progress**: **Rebirth** trades your cash and collection for a permanent income multiplier,
  and the base shop sells **Slap** upgrades (range and bonk power) and **Speed** upgrades.

## The cast

Ten characters on a five-rarity ladder:
Brr Brr Patapim and Lirili Larila (Common), Tralalero Tralala and Chimpanzini Bananini (Rare),
Ballerina Cappuccina and Cappuccino Assassino (Epic), Tung Tung Sahur and Frigo Camelo
(Legendary), Bombardiro Crocodilo and La Vaca Saturno Saturnita (Mythic).
Each one is a Creator Store model from the owner's inventory (asset ids live in
`CharacterFactory`), scaled to about five studs, re-pivoted so its feet are its pivot, and
posed by a measured ground offset so it stands exactly on the belt and the pads. The Brainrot
Pack (asset 137461628889541) is a fallback source, and the part recipes in `BrainrotData` are
the final fallback. Set dressing follows the same rule — decoration only, added in the
background after the game is live: the "Steal A Brainrot Base" platform (107398504693015)
stands as a display shelf behind each base's pads, a Conveyor Belt model (7063606146) tiles
over the belt while our own invisible collidable surface guarantees the footing, and the plaza
decor comes from a Foliage Pack (7990107300), Street Lamps (14212653287), Neon Signs
(11666458445) and Wooden Walls (1408960132).

## Layout of the entry

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`,
  `screenshots/` and `PLAY.json` to `/output` (skipping any name that starts with a dot) and
  writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the binary place Rojo builds from `src/` and `default.project.json`:
  `rojo build default.project.json --output game.rbxl`.
- `src/shared/` — `BrainrotData` (the cast, rarities, prices, build recipes) and `Config`
  (every tuning number), as ModuleScripts in ReplicatedStorage.
- `src/server/` — the `GameServer` bootstrap Script in ServerScriptService and its ModuleScripts:
  `GameState` (all runtime state, in memory only — no DataStore), `WorldBuilder` (the plaza,
  conveyor and bases), `AssetLibrary` (loads, sanitizes and normalizes the owner's Creator
  Store models), `CharacterFactory` (character models, labels, walk animation),
  `BaseManager` (bases, pads, the lock), `Economy` (cash, income, rebirth, upgrades),
  `Conveyor` (spawning and buying) and `StealSystem` (stealing, carrying, the slap).
- `src/client/` — `Hud`, a LocalScript that draws the cash/income panel, the Lock and Rebirth
  buttons, toast notifications and the carrying banner, and fires the slap remote.
- `PLAY.json` names the published place (place 107649210185098, universe 7987983561).
- `TOUR.json` is the optional reviewer tour of the screenshots.

State is per-server and in memory only: a fresh server is a fresh game.
