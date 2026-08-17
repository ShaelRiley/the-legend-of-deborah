# Milestone 1 test report — The Labyrinth

Date: 2026-08-16

This report records the completed Milestone-1 foundation and live Garry's Mod runtime validation performed on gm_flatgrass from the Steam Deck development environment.

## Headless deterministic validation

- All committed Lua sources parsed successfully with `texluac` as a syntax smoke test during the foundation pass.
- 1,000 deterministic logical maze seeds generated with zero failures.
- Every accepted test seed retained at least 3 vertical transitions on the computed start-to-goal critical route.
- The 1,000-seed suite ran in two separate interpreter processes and produced the identical aggregate topology hash `981725631`.
- Worst deterministic regeneration attempt in that sweep: 19 of 32 allowed attempts.
- Accepted logical cell-count range in that sweep: 462–736 cells.
- Accepted layer distribution in that sweep: 367 two-layer, 529 three-layer, 104 rare four-layer layouts.
- A headless geometry-builder stub completed across 100 representative seeds without builder exceptions.

## Live Garry's Mod validation

Confirmed in the real gamemode on `gm_flatgrass`:

- The gamemode appears and launches through Garry's Mod.
- Deterministic multi-level shipping-container labyrinth generation completes before players are released.
- The crash-prone per-container VPhysics implementation was replaced by visual cargo-container entities plus merged authoritative static wall collision.
- Level 0 has reliable generated floor support; the player no longer falls through to Flatgrass.
- The generated Level-0 floor is separated sufficiently from the underlying map to avoid z-fighting.
- Elevated floors are visibly opaque and use explicit per-cell geometry rather than long merged slabs.
- Mandatory staircases are visibly rendered, climbable without jumping, and terminate at usable upper landings.
- Ordinary player locomotion works through generated corridors.
- Open-edge and occupied-cell clearance checks have passed in live runtime audits.
- Configured model validation reported zero invalid models in tested builds.
- Live generation/build performance is comfortably inside the GDD targets. Representative measured builds were approximately 0.21–0.34 seconds total on the Steam Deck test system, versus <=5 seconds typical / <=10 seconds worst-case targets.
- A representative live audit passed with all logical cells reachable and the required vertical critical path.
- Three separate stair transitions on one generated maze were manually traversed successfully.
- `lod_regenerate` successfully cleaned the prior labyrinth and built a fresh validated maze.
- The regenerated maze reported 607/607 reachable cells, critical path length 56, 3 required vertical transitions, generation attempt 1, and approximately 0.343 seconds total build time.
- Stair transition 1 on that regenerated maze was manually traversed successfully.

## Anti-bypass status

Authoritative closed-wall collision extends to the full 384-unit logical layer height while the visible two-container wall stack remains 256 units high. This physically prevents ordinary container-top traversal from becoming the progression graph.

The current automated wall-top audit has a known diagnostic false-negative at a small number of closed edges where a kind-2 stair box intersects the test hull before the kind-4 blocker. A representative run detected 866 of 872 closed-wall blockers directly; all 6 residual cases were intercepted by stair geometry rather than reporting a true no-hit. A subsequent blocker-only trace-filter experiment caused a startup regression and was reverted. The working gameplay build is retained; this audit-only issue remains validation debt and is not being allowed to destabilize the labyrinth.

## Milestone-1 runtime acceptance

Manual acceptance sequence completed:

1. Generate and enter a live multi-level maze.
2. Walk ordinary corridors on Level 0.
3. Traverse stairs 1, 2, and 3 without jumping.
4. Reach visible, solid elevated floors and usable upper landings.
5. Regenerate the level safely.
6. Confirm the new graph validates at 607/607 reachable cells with 3 critical vertical transitions.
7. Traverse stair 1 on the regenerated maze.

Result: **Milestone 1 — The Labyrinth implementation accepted as the stable development checkpoint.**

## Validation debt retained for later hardening

The following are deliberately retained as later multiplayer/release-candidate QA rather than silently claimed as already tested:

- multi-client 1–4-player live traversal and spawn testing;
- dedicated-server smoke testing;
- exhaustive physical attempts at every possible wall-top/outside-maze bypass topology;
- repair/replacement of the current bypass-audit false-negative around stair intersections;
- broader campaign soak/performance testing across repeated live regenerations.
