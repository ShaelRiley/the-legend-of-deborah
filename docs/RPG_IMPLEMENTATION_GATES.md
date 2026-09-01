# RPG Overhaul Implementation Gates

Design authority: the live **The Legend of Deborah — Garry's Mod Game Design Document**. GitHub `main` remains implementation authority.

## Architecture map

| New system | Existing authority it must extend | Gate A module/status |
|---|---|---|
| CharacterProgressionSystem | RunManager player/campaign lifecycle | `lod/sv_character_progression.lua` scaffold; no lifecycle hook yet |
| AbilityRules | Existing combat dice, Magic, movement, HP authorities | shared schema/constant contract only |
| FeatDirector | CharacterProgressionSystem progression state | feat/capstone/draft schemas only |
| FeatEffectSystem | Existing combat/pushback/loot/Magic/weapon authorities | pending |
| IdentityGenerationSystem | RunManager RosterSeed lifecycle + independent deterministic substreams | identity schemas and seed-domain helpers only |
| IdentityPerkSystem | Existing semantic combat/navigation/loot/encounter events | identity perk schema only |
| CharacterSheetUI | Existing Field Manual visual language | pending Gate B |
| PlayerCharacterText | Existing HUD/feed/player-message surfaces | pending |
| RPGThreatEvaluator | EncounterDirector projected-profile spending | bounded threat contract only |

## Gate A — boot + architecture scaffold

Implemented without changing live combat or progression behavior:

- exact GDD schema field contracts for progression, derived stats, combat-hit state, XP damage ledgers, defensive proc state, feat definitions, capstones, pending drafts, and procedural identity;
- six-ability/class/level/Magic/safety-cap constants;
- Fighter/Rogue/Wizard favored-ability and hero hit-die metadata;
- seven ordinary feat levels (`1, 3, 6, 9, 12, 15, 18`);
- isolated RPG deterministic seed helpers;
- `CharacterProgressionSystem` state constructor and pure ABILITY_MOD/Level helpers;
- developer-only `lod_rpg_validate` command and finite startup validation when developer mode is enabled.

`LOD.RPG.GameplayEnabled` remains `false` at Gate A. This is deliberate: Gate A must prove that the new architecture can load beside the existing game without changing broad gameplay.

## Runtime gate

1. Fresh-start Garry's Mod on `gm_flatgrass` with the current checkout.
2. Confirm no Lua errors during startup.
3. Confirm the staging hut appears and the procedural dungeon still builds/releases normally.
4. With developer mode enabled, run `lod_rpg_validate` and confirm a single `Gate A validation PASS` line.

Do not begin Gate B until this gate passes.
