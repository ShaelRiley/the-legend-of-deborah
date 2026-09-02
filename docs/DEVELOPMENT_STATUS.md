# Development Status — 2026-09-02

## Current execution phase

**CORE MULTIPLAYER SMOKE FOUNDATION: ACCEPTED.**

**RPG OVERHAUL: ACTIVE DEVELOPMENT.**

The live GDD is design authority. GitHub `main` is implementation authority.

The previous status document was stale: it still described first real-client multiplayer as an uncompleted blocker. That blocker has now been retired based on the September 1 live VPS playtest recorded in `docs/MP_PLAYTEST_2026-09-01.md`.

## Multiplayer evidence now accepted

The September 1 footage demonstrates a public VPS-hosted `gm_flatgrass` server with at least three simultaneous human-controlled clients in the generated dungeon. The run visibly exercises:

- concurrent teammate movement and combat;
- shared Red/Blue/Yellow progression;
- shared key/gate state transitions;
- personal map use during cooperative play;
- Jail Key / Deborah-cell progression;
- one party-wide Deborah rescue;
- multiplayer victory/intermission presentation;
- transition into the next generated labyrinth;
- no Lua errors reported by the end-of-session Problems panel.

This is sufficient evidence to accept the basic live-network world/progression foundation and move forward. The footage predates the RPG overhaul, so post-RPG multiplayer synchronization remains a regression target, not an uncompleted prerequisite.

## Current RPG state

The active RPG implementation now includes:

- deterministic procedural hero identity and Character Sheet;
- randomized base abilities using 4d6-drop-lowest with below-average arrays rerolled;
- Fighter, Rogue, and Wizard class commitment;
- Levels 1–20 progression, XP, ability growth, hit-die HP progression, ordinary feat drafts, and Level-20 capstones;
- server-authoritative ability/class gameplay bridges;
- current Wizard Arcane Diversion, full-Magic INT bonus, Feedback, and Feedback cooldown;
- improved combat-feed and major-screen presentation for Feedback and level-up events;
- feat-choice confirmation presentation.

The next RPG boundary is the ordinary feat-effect layer: ownership/drafting exists, but the broad ordinary feat families still require their authored semantic gameplay integrations.

## Multiplayer policy going forward

Do not repeat the old pre-RPG multiplayer smoke gate as a blocker before every feature.

Instead:

1. continue the RPG implementation to its next coherent runtime gate;
2. perform focused multi-client regression of the systems that changed after the September 1 build;
3. keep reconnect/death/resource-isolation/4-player soak as release-hardening scenarios;
4. fix defects from actual network evidence rather than speculative rewrites.

Post-RPG multiplayer regression should explicitly cover Character Sheet state, randomized abilities, XP/level progression, feat ownership/effects, class mechanics, personal Magic, Wizard Feedback, and player-specific resources.

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
- campaign restart and level-transition pipeline;
- core live multiplayer world/progression behavior demonstrated on the VPS.

## Known deferred production work

- ordinary feat-family gameplay effects;
- Neil + The Brute required post-Blue midboss;
- Gordon the Warden and final arena;
- dungeon-tier Map degradation;
- armor-residue cleanup;
- architectural wrapper consolidation;
- broader 3–4-client/reconnect/churn/dedicated-server soak after the post-RPG regression pass.

## Current rule

**Multiplayer smoke is no longer the blocking milestone. Finish the next coherent RPG implementation gate, then regression-test the newer RPG layer in multiplayer before treating the build as release-ready.**
