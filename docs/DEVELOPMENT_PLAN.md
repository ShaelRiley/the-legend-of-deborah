# Development Plan — 2026-08-25 Dice-Era Reconciliation

This execution plan reconciles the live production GDD with the actual `main` implementation and accepted Steam Deck runtime evidence after the complete-dungeon vertical slice and v1 dice-combat subsystem work.

## Execution principle

Milestone numbers describe capability groups, not rigid chronological gates. Do not reopen accepted systems without new regression evidence, and do not tune future systems against obsolete fixed-damage assumptions.

Current order:

1. **Complete one full dice-era dungeon and evaluate the integrated combat economy.**
2. Make only evidence-driven dice balance corrections required by that run and subsequent confirming runs.
3. Resume the remaining expanded normal-enemy roster.
4. Finish the rest of Milestone 4 expedition/economy work, including production loot and Brute + Neil / Map acquisition.
5. Implement Gordon the Warden while preserving the proven Jail Key → jail door → Deborah pipeline.
6. Integrate and harden multiplayer last.

XP, character levels, procedural equipment/affixes, elements, Magic, Luck Ring, and the broader RPG layer remain deferred post-release systems.

---

## Gate A — Complete Dungeon Vertical Slice — ACCEPTED

The production-compatible progression loop is established:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → Deborah jail door → Deborah → level clear → intermission → next generated level`

Accepted evidence includes three consecutive complete dungeons, successful Level-4 generation/release, `lod_m2_seed_test 100` at 100/100, accepted minimap caching and breadcrumb routing, legal Jail Key/jail-door/Deborah state, death/checkpoint persistence, and corrected stair presentation.

**Do not reopen Gate A without new evidence of regression.** Gordon the Warden will later replace only the temporary Core source of the already-proven Jail Key.

---

## Gate B — Fixed-Damage Baseline — HISTORICAL / SUPERSEDED

The project has already crossed into the dice-era implementation. Do not spend additional development time perfecting the obsolete fixed-damage/fixed-HP baseline.

Any historical fixed-damage observations remain useful only as qualitative comparison material. The current shipping balance target is the v1 dice system.

---

## Gate C — v1 Dice-Combat Foundation

### C1. Server-authoritative roll service — IMPLEMENTED

`sv_combat_rolls.lua` owns authoritative player weapon rolls, hostile-originated damage rolls, deterministic enemy health dice, and compact resolved presentation events. Clients never decide damage.

### C2. Bounded combat-roll feed — IMPLEMENTED / RUNTIME ACCEPTED

`cl_combat_roll_feed.lua` presents a bounded lower-right event history between ammunition and the minimap. Damage attribution includes source/player name, formula, applied total, target, and `via` source.

Accepted example:

`ShaelRiley dealt 1d4 (3) damage to Shambler, via pistol`

Monster-originated dice damage follows the same attribution structure.

### C3. Straightforward weapon dice — IMPLEMENTED

- Crowbar `1d8`
- Pistol `1d4`
- SMG `1d8`
- AR2 `1d10`
- Grenade `1d20`

### C4. .357 Magnum — IMPLEMENTED

- `1d12`
- natural 10, 11, or 12 explodes;
- every bonus d12 may recursively explode;
- one cartridge is consumed regardless of chain length.

Do not implement Luck Ring behavior in v1.

### C5. Shotgun shell contract — IMPLEMENTED / RUNTIME ACCEPTED

- one shared `1d6` roll per shell;
- floor every die result below 3 to 3 for damage contribution;
- only natural 6 explodes;
- explosion dice follow the same floor/explosion rule;
- six guaranteed pellets;
- independent 33% chances for pellets 7, 8, and 9;
- aggregate resolved damage once per target;
- one doubled 0.60-second hit stun per damaged target per shell;
- 0.66-second retrigger lockout;
- never apply separate doubled stuns per pellet.

`durationMultiplier` must continue to propagate through both `sv_hostile_hurt_pose.lua` and the final `sv_soldier_shot_contract.lua` wrapper so Shotgun stun and Soldier/Blitzer shot cancellation remain compatible.

### C6. Ammunition economy — IMPLEMENTED / RUNTIME ACCEPTED

Combined loaded-plus-reserve capacity = three reload-equivalents. Regeneration floor = one reload-equivalent.

- Pistol: 54 cap / 18 floor / 60 s empty-to-floor
- Shotgun: 18 / 6 / 90 s
- SMG: 135 / 45 / 120 s
- AR2: 90 / 30 / 150 s
- .357: 18 / 6 / 180 s

One shared 4 Hz server timer owns bounded regeneration. Grenades are excluded. The H-key infinite developer Pistol is an intentional bypass and must not be used as balance evidence for ammo pressure.

### C7. Enemy health dice — IMPLEMENTED / RUNTIME ACCEPTED

Current deterministic profiles:

- Deadcrab `2d4+1`
- Runner `3d4+3`
- Shambler / Soldier / Blitzer `4d4+5`
- Bio Blaster `5d4+6`

Health dice replace the independent legacy HP jitter. Final durability remains monotonically constrained by visible hostile size so a clearly larger otherwise-comparable enemy never becomes less durable solely because of its health roll.

Accepted diagnostic:

`[LOD:DICE-HEALTH] active=32 diceApplied=32 missing=0 legacyHPJitter=0 clearSizePairs=88 inversions=0 healthRolls=32 result=PASS`

### C8. Complete-dungeon dice balance gate — CURRENT

This is the immediate development gate.

Complete whole dungeons under the dice system and judge the integrated experience, not isolated arithmetic. Observe:

- completion time relative to the GDD's 20–35 minute Level-1 target;
- deaths and remaining lives;
- player-to-hostile and hostile-to-player lethality;
- ammunition pressure through Red, Blue, Yellow, Core, and rescue progression;
- fights that feel excessively slow, cheap, or trivial;
- whether visible size remains a trustworthy durability cue;
- Steam Deck performance;
- whether the lower-right roll feed informs play without becoming visual noise;
- successful Deborah rescue, intermission, and next-level generation.

Gate C passes only when the dice version remains legible, performant, and repeatedly completable.

---

## Telemetry safety policy

The first attempt at automatic full-run dice telemetry is **retired**.

Loading `sv_dice_run_telemetry.lua` through normal gamemode startup caused Garry's Mod to lose the custom The Legend of Deborah startup path and enter ordinary Sandbox Flatgrass. Disabling only that loader restored normal startup. No useful GMod Lua exception was captured, so repository history cannot prove the module's exact internal runtime fault; static parsing is explicitly insufficient evidence.

The experiment's complete surviving footprint was isolated to:

- the telemetry module itself;
- three lifecycle `hook.Run` calls in `sv_run_manager.lua`;
- one guarded ammo sampling callback in `sv_dice_ammo.lua`.

Those additions are removed rather than repaired speculatively.

For the current C8 run, use existing subsystem diagnostics, screenshots, console output, and manual observations. If full-run telemetry is reconsidered later, it must satisfy all of these constraints before adoption:

1. developer-only;
2. explicitly armed after successful gamemode startup;
3. absent from the normal production/startup loader;
4. bounded and event-driven;
5. no new per-frame scans, BFS, or broad entity queries;
6. independently runtime-tested for startup safety before becoming a standard development tool.

---

## Gate D — Resume Expanded Enemy Roster — BLOCKED ON C8

Do not resume Watcher/Seeker/Sentry development until the complete-dungeon dice gate is accepted.

After C8, continue in current GDD order:

`Watcher → Seeker → Sentry → Razor → Flamer → Big Crab → Arc Caster → Lurker → Beam Sweeper`

Each archetype must be built and tuned against the dice-era combat economy and pass its systemic niche, placement/counterplay, graph navigation, death/hit feedback, durability, and low-end performance tests before moving to the next.

Do not regress the immutable Soldier shot contract while reusing Soldier/Blitzer projectile infrastructure.

---

## Gate E — Complete Remaining Milestone 4 Expedition

After dice-era combat and roster stability:

- full production weapon/resource placement;
- individualized pickups/drops;
- pity protection;
- rare extra-life behavior;
- health/armor/ammo economy validation;
- cross-level inventory persistence;
- production Brute + Neil encounter and Map acquisition for applicable dungeon tiers;
- broader complete-dungeon attrition and low-end soak testing;
- remaining approved pre-release presentation work.

All resource work must preserve the one-reload regeneration floor as anti-deadlock support rather than abundance.

---

## Gate F — Milestone 5: Gordon the Warden

Only after the prior gates are stable:

- implement the reserved final arena and Gordon the Warden phases;
- preserve the accepted graph/progression architecture;
- Warden death produces the same production Jail Key already proven by the vertical slice;
- reuse, rather than rewrite, Jail Key ownership, jail-door unlock, Deborah eligibility, touch rescue, intermission, and next-level transition;
- add boss HUD/music/resupply and final presentation per the live GDD.

---

## Gate G — Multiplayer Integration / Release Candidate

Dedicated multiplayer development remains last. Preserve multiplayer-compatible server authority now, but defer multiplayer-specific debugging until the complete single-player game is stable through Gordon the Warden.

Then validate 1–4 cooperative players, joins/rejoins, active slots, spectator-only connections, individualized resources, wipes, respawns, intermissions, dedicated servers, long campaign sequences, and the release-candidate criteria in the live GDD.

---

## Architecture invariants

1. The canonical generated 3D maze graph is the authority for topology, progression legality, routing, minimap interpretation, gates, and stairs.
2. Generated physical geometry must agree with that graph.
3. Motion V2 is the sole production hostile ground-motion authority.
4. Validated stairs are the sole ordinary hostile elevation-changing route.
5. Retired CLuaLocomotion recovery systems must not return as competing authorities.
6. Soldier warning and ordinary Soldier bolt share one immutable server-authored origin/direction committed at beam-on; Blitzer adds only its intentional deterministic veer.
7. Client-only hostile visual scale and animation bones are never trajectory authorities.
8. Visible hostile size remains a trustworthy monotonic durability cue under health dice.
9. Minimap topology, floor indexes, reachability, and routes remain cached; no per-frame graph traversal.
10. Networking remains compact/chunked rather than transmitting large generic state tables.
11. Ballistic/player searches remain bounded; generated maze geometry remains authoritative cover.
12. Recurring hostile consumers use the shared hostile registry rather than independent global scans.
13. Death presentation remains bounded through the shared scheduler.
14. Heavy audits and test modules remain developer-only.
15. Every generated entity participates correctly in level cleanup and regeneration remains idempotent.
16. Work one decisive runtime acceptance criterion at a time and commit coherent working increments directly to `main`.
