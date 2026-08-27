# Development Status — 2026-08-27 Multiplayer Priority

## Current execution phase

**MP-STAGING — Shared Hut Deployment: IMPLEMENTED / AWAITING FIRST RUNTIME VALIDATION.**

**Immediate goal: real two-client multiplayer test on August 28, 2026.**

The live GDD is design authority. GitHub `main` is implementation authority.

Development order remains: staging/runtime validation → real multiplayer integration/testing → authority cleanup → Neil + The Brute → Gordon the Warden.

The current implemented dungeon progression remains the temporary multiplayer test harness:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah → intermission → next generated level`

Neil + The Brute and Gordon remain intentionally outside the first multiplayer gate.

## Newly implemented first-deployment staging

Every newly admitted cooperative identity now reserves a RunManager slot but begins outside dungeon-active play in the native `gm_flatgrass` spawn hut.

StagingDeployment owns:

- native-hut anchoring from the map's real player-start entities;
- a red-tinted Dungeon Hermit presentation with the line `It's dangerous to go alone. Take this.`;
- deterministic identity-bound advanced starter assignment from Shotgun, SMG, Magnum, and AR2;
- without-replacement starter assignment among the currently reserved four-player cooperative party wherever the four-gun pool permits;
- identity-instanced starter pickup visibility/claim ownership;
- persistent starter assignment and claim state across reconnects;
- staged-versus-deployed state;
- hidden collision containment inside the native hut so ordinary movement cannot exit into Flatgrass;
- a blue USE/E portal that is the sole legal transition to the current valid dungeon start/checkpoint;
- a deployment diagnostic: `lod_staging_status`.

The universal baseline loadout is now Crowbar + Pistol 18 loaded with zero reserve. The advanced starter is a physical hut pickup with one loaded magazine and zero reserve:

- Shotgun: 7
- SMG: 25
- Magnum: 6
- AR2: 20

No starter grants Grenades or AR2 secondary ammunition.

## Staged-player authority rule

RunManager still owns the raw four-slot ledger. For ordinary gameplay consumers, `RunManager:IsActivePlayer` now means **slot-reserved and deployed**.

Therefore a staged identity:

- reserves one of the four cooperative slots;
- keeps its character/lives/Magic/persistent identity state;
- is not a legal hostile target;
- cannot advance dungeon progression;
- cannot use the dungeon minimap;
- is not included in dungeon enemy-drop rolls;
- does not materialize ordinary individualized static dungeon loot until deployment.

Portal deployment changes only that identity into dungeon-active play; teammates may remain staged or deployed independently.

## Retired rules

The staging system supersedes two older onboarding assumptions:

1. the Level-1 JIP catch-up kit that automatically granted SMG + Shotgun and later Magnum/AR2 is retired;
2. the two guaranteed Level-1 firearm placements near early keycards are retired.

Further firearm discoveries remain in the ordinary individualized reward/drop economy. Additional late-campaign JIP assistance beyond the universal hut starter is deliberately deferred until multiplayer lifecycle testing shows whether it is needed.

`sv_loot_catchup.lua` now exists only as a harmless retired-compatibility marker.

## Multiplayer hardening already accepted in single-client runtime

The previous one-client preflight passed:

- `lod_multiplayer_status` → PASS
- `lod_multiplayer_contract_status` → PASS
- `lod_multiplayer_roster_status` → PASS
- fixed 20-second Death-Tetris wait;
- slot-safe teammate revival;
- reconnect-safe death/intermission state;
- friendly-fire suppression and teammate non-collision;
- D1–20 personal map policy;
- connected-party encounter planning;
- individualized loot transmission safety;
- complementary-blue minimap player marker.

The staging feature was added after that pass and therefore requires a fresh narrow regression gate before the second human client is introduced.

## Immediate gate — S0

Fully restart Garry's Mod and start a fresh normal campaign on `gm_flatgrass`.

Required evidence before deployment:

- player appears in the native Flatgrass hut;
- red Dungeon Hermit and one advanced firearm are visible ahead;
- blue portal is behind/near the exit side;
- portal refuses USE/E before starter claim;
- player cannot walk out into Flatgrass;
- `lod_staging_status` reports one reserved slot, one staged identity, zero deployed, one pickup, hut ready, result PASS;
- staged player has no dungeon map, no ordinary static dungeon loot, and is not dungeon-active.

Then claim the starter and use the portal.

Required evidence after deployment:

- starter has correct loaded magazine and zero reserve;
- portal teleports to current valid maze start/checkpoint;
- `lod_staging_status` reports staged=0, deployed=1, claimed=1, result PASS;
- `lod_multiplayer_status`, `lod_multiplayer_contract_status`, and `lod_multiplayer_roster_status` remain PASS;
- normal combat, map/Magic, loot, and progression resume.

See `docs/MULTIPLAYER_TEST_PLAN.md` for the complete staged and two-client protocol.

## Next gate — MP1

After S0 passes, use a multiplayer/listen server and connect a second real human after player 1 has deployed.

The second identity must independently stage in the same native hut, receive a different character and distinct advanced starter where possible, remain excluded from dungeon-active systems until portal deployment, and then join the current dungeon without disturbing player 1.

## Accepted foundations to preserve

Do not disturb without concrete regression evidence:

- deterministic procedural multi-floor maze generation;
- canonical graph authority;
- optimized merged server wall collision + client wall presentation;
- validated stair/floor geometry;
- Motion V2 ordinary hostile movement;
- generated-geometry ballistics/cover;
- current minimap caching/reliability behavior and personal Magic drain;
- server-authoritative combat dice;
- immutable Soldier warning/projectile contract;
- current Watcher and Seeker accepted behavior;
- individualized LootDirector;
- finite ammo/regeneration system;
- Magic/Force Shout;
- current broad combat/economy balance;
- campaign restart and level transition pipeline.

## Known discrepancies outside the immediate staging/multiplayer smoke gate

- Neil + The Brute required post-Blue midboss: deferred until after multiplayer validation begins.
- Gordon the Warden: not implemented; deferred.
- Dungeon-tier Map degradation: not yet production-complete.
- armor residue: retired design still has implementation residue; remove during economy consolidation.
- architectural wrapper debt: consolidate after real multiplayer evidence, not before the first test.

## Current rule

**Validate the new native-hut staging flow first. If S0 passes, move directly into the two-human multiplayer gate. Do not implement Neil + The Brute, Gordon the Warden, or a broad refactor before that evidence.**
