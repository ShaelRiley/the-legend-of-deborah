# Development Status

## Current phase
Milestone 2 — The Three Keys

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

## Next implementation target
Milestone 2 — The Three Keys:

- ordered Red → Blue → Yellow progression;
- keycard objective placement and non-color identifiers;
- team-wide card state;
- scripted permanent bidirectional gates;
- gate checkpoints;
- personal lives and 20-second teammate-spectator respawn;
- elimination and next-level one-life restoration;
- join/rejoin state and ten-played-identity campaign cap;
- spectator-only visitors excluded from the cap;
- Deborah as the provisional level-clear endpoint for end-to-end progression-loop testing.
