# SAHUR BASE — Steal a Brainrot

A 3D Steal-a-Brainrot game for Roblox, built entirely from Luau code (the world, the characters,
the economy — every Part is placed by a script; there are no external assets). Entry for make.fun's
**roblox-brainrot-01** bounty, "Make the best AI Roblox brainrot game".

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

Ten original characters on a five-rarity ladder, all modelled from parts in code:
Brr Brr Patapim and Lirili Larila (Common), Tralalero Tralala and Chimpanzini Bananini (Rare),
Ballerina Cappuccina and Cappuccino Assassino (Epic), Tung Tung Sahur and Frigo Camelo
(Legendary), Bombardiro Crocodilo and La Vaca Saturno Saturnita (Mythic).

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
  conveyor and bases), `CharacterFactory` (part-built characters, labels, walk animation),
  `BaseManager` (bases, pads, the lock), `Economy` (cash, income, rebirth, upgrades),
  `Conveyor` (spawning and buying) and `StealSystem` (stealing, carrying, the slap).
- `src/client/` — `Hud`, a LocalScript that draws the cash/income panel, the Lock and Rebirth
  buttons, toast notifications and the carrying banner, and fires the slap remote.
- `PLAY.json` names the published place (place 107649210185098, universe 7987983561).
- `TOUR.json` is the optional reviewer tour of the screenshots.

State is per-server and in memory only: a fresh server is a fresh game.
