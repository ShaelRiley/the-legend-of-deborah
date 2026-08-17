# Development Status

## Current phase
Milestone 2 — The Three Keys

**Current M2 state: integrated implementation awaiting first live Garry's Mod runtime validation.**

Implemented in the current development branch/state:

- deterministic progression planning over the authoritative maze graph;
- three ordered progression-safe bridge gates targeting Red → Blue → Yellow sectors;
- deterministic keycard objective pockets chosen from accessible pre-gate sectors with minimum detour constraints;
- explicit ordered-solvability simulation before the level is committed;
- deterministic layout retry when a generated maze cannot support safe gate/card placement;
- gate checkpoint safety rejection for vertical-transition cells;
- team-wide Red/Blue/Yellow card state;
- non-color identifiers R/triangle, B/circle, Y/square on cards, gates, readers, and HUD;
- scripted permanent bidirectional gate opening with locked collision and full-height anti-bypass blocking;
- checkpoint advancement immediately beyond each opened gate;
- persistent Source-era HUD for level, lives, keycards, objective, ranked state, and post-card directional gate guidance without a minimap;
- three starting personal lives, four-life state cap, authoritative 20-second death/spectate timer, checkpoint respawn, elimination at zero lives, and next-level one-life comeback;
- persistent identity/character/life/inventory state across disconnect/reconnect within the server-session campaign;
- four active-player slots and ten-played-identity campaign ledger, with spectator-only visitors excluded until they actually enter play;
- disconnect/wipe semantics that ignore disconnected participants while another played identity remains connected and freeze campaign simulation when no played identity is connected;
- provisional Deborah physical-touch rescue trigger;
- 15-second minimum M2 level-clear intermission and deterministic Level N+1 rebuild;
- dedicated M2 status, objective, teleport, seed-test, and audit developer commands.

This is **not yet a Milestone-2 completion checkpoint**. Live runtime validation must first prove startup, gate/card rendering and collision, ordered progression, checkpoints, death timing, elimination/comeback, level transition, and join/rejoin/cap behavior.

## Milestone 1 — The Labyrinth
**Status: implementation checkpoint accepted on 2026-08-16.**

Live Garry's Mod validation on `gm_flatgrass` has confirmed:

- deterministic multi-layer maze generation;
- authoritative logical graph connectivity and required vertical progression;
- real shipping-container labyrinth presentation;
- stable generated floor collision and ordinary player locomotion;
- visible opaque elevated floors;
- visible broad stair traversal without jumping;
- usable upper landings;
- no Level-0 z-fighting after floor separation;
- safe runtime regeneration into a fresh validated maze;
- stairs 1–3 manually passed on one maze and stair 1 passed after regeneration;
- regenerated validation result of 607/607 reachable cells, critical path 56, 3 critical vertical transitions, attempt 1;
- representative live generation/build around 0.21–0.34 seconds total on the Steam Deck test system, comfortably inside the GDD's <=5-second typical / <=10-second worst-case targets;
- 1,000-seed headless logical validation with zero failures and deterministic aggregate topology hash `981725631`.

Milestone-1 Git/runtime details and retained validation debt are recorded in `docs/M1_TEST_REPORT.md`.

Known diagnostic debt: the current automated wall-top bypass audit can false-negative where stair geometry intercepts its hull before the anti-bypass blocker. The working gameplay build remains intact; the failed blocker-only audit experiment was reverted. Multi-client 1–4-player, dedicated-server, and exhaustive bypass/soak QA remain scheduled for later hardening and Release Candidate work.
