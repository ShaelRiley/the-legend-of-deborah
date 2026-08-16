# Milestone 1 test report — foundation checkpoint

Date: 2026-08-16

This report records tests that can be executed without a Garry's Mod runtime. It does not qualify Milestone 1 as complete; physical collision, traversal, model mounting, listen-server behavior, and dedicated-server behavior remain target-runtime tests.

## Passed

- All committed Lua sources parse successfully with `texluac` as a syntax smoke test.
- 1,000 deterministic logical maze seeds generated with zero failures.
- Every accepted test seed retained at least 3 vertical transitions on the computed start-to-goal critical route.
- The 1,000-seed suite was run in two separate interpreter processes and produced the identical aggregate topology hash `981725631`.
- Worst deterministic regeneration attempt in that sweep: 19 of 32 allowed attempts.
- Accepted logical cell-count range in that sweep: 462–736 cells.
- Accepted layer distribution in that sweep: 367 two-layer, 529 three-layer, 104 rare four-layer layouts.
- A headless geometry-builder stub completed across 100 representative seeds without builder exceptions.

## Geometry entity estimate

The current builder deliberately favors correctness and literal frozen container construction over premature optimization. A 100-seed headless creation-count sample produced:

- total generated entities: average 1,719.6; maximum 2,144
- frozen cargo-container props: average 1,555.5; maximum 1,890
- merged elevated-floor collision entities: average 85.9; maximum 146
- stair collision entities: average 69.4; maximum 96
- invisible stair-rail blockers: average 8.7; maximum 12

This is not yet a performance pass. The GDD's <=5-second typical / <=10-second worst-case target must be measured in Garry's Mod. If frozen prop creation misses that target, wall construction will need further batching/representation work without altering the logical graph.

## Still required in Garry's Mod

- Verify all configured mounted model paths.
- Verify cargo-container model collision bounds/orientation against the 384-unit lattice.
- Walk representative two-, three-, and four-layer seeds with ordinary HL2 movement.
- Verify stair apertures and rail collision in both directions.
- Verify generated geometry never blocks an abstractly open graph edge.
- Attempt wall-top, arbitrary-drop, and outside-maze bypasses.
- Verify safe 1–4 player spawning and restricted spectator behavior.
- Profile generation/build latency and entity/network cost.
- Smoke-test listen and dedicated servers.
