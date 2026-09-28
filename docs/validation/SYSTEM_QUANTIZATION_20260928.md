# Custom-system quantization — 2026-09-28

Baseline: verified main `cdb85e6acde6a26f01b45eeee396cf8d8a661a17`.
Shael reports good Steam Deck performance on that renderer build and requests
further simplification of custom systems where extra precision adds little value.
Live GDD navigation: 00 → 01 → 07, especially LOD-IMPL-001–004. This pass changes
implementation, not authored game formulas, timing, content, or tuning.

## Implemented at existing authorities

| System | Simplification | Preserved contract |
| --- | --- | --- |
| Event navigation | Four event slots become a 0–15 blocked/open mask plus the existing context token. Repeated AI route queries allocate no signature tables or text. | Fresh ownership checks; same-tick opening/cleanup; graph/context/epoch invalidation; ordinary gates and filtered routes. |
| Equipment economy | Lazily evaluate the existing curve once per integer depth, with at most 999 cached numbers. | Exact rounding, item/fusion values, RNG draws, rarity, quality, innate values and live family multipliers. Out-of-domain developer caps do not grow the cache. |
| Near-crosshair identification | Precompute the six-degree cone constant; use signed squared projections; trace only candidates that can improve the visible result. | Fresh position/aim/occlusion, direct-hit priority, range, cloak/hidden exclusions, distance/entity tie-breaking; no delayed target cache. |
| Roster projectile presentation | Normalize the trail once on the first visible frame of each received snapshot. | Every frame still interpolates the current position; unchanged beam endpoints, expiry, turnaround marker, distance/sky/depth rejection and empty-snapshot clearing. |

## Finite source evidence

Command:

```bash
python3 tools/test_system_quantization_gate.py --output /tmp/lod-quantization-gate --workers 4 --suite-timeout 120
```

**38/38 selected checks passed; 810 Lua files passed syntax checks.** No tracked
or untracked source changed during the gate. The receipt and raw logs are in
`system_quantization/`; `tested-changes.json` binds the changed files to the
baseline and validated source fingerprint. Documentation/evidence were added
after the gate; gameplay and test source stayed unchanged.

| Paired workload | Parent work | Candidate work | Result |
| --- | ---: | ---: | --- |
| 95,904 loot-budget calls across all 999 depths, eight families, four rarities and three quality values | 95,904 square roots; 191,808 logarithms | 999 square roots; 1,998 logarithms | Every value equal; dynamic modifiers and invalid/fractional inputs checked. |
| Ten full snapshots of 64 visible projectiles, rendered at 60 FPS over one second | 3,840 direction normalizations | 640 | Identical interpolated beam endpoints; no work for unseen snapshots. |
| One ordered 64-candidate identification query | 64 visibility traces | 1 | Same visible target; saving depends on candidate order/occlusion. Worst-case queries may still trace every improving candidate. |
| 10,000 event route-signature reads with four active slots | 10,000 signature-table joins | 0 | No signature table or string allocation. |

Additional boundary checks: 8,646 paired cone/range cases, near-boundary angles,
vertical views, blocked/hidden/cloaked targets, direct-hit priority and ties;
1,152 path/distance cases spanning all sixteen event masks, ordinary-gate states
and ordered cell pairs. Route tests also exercise same-tick resolution, lost
ownership, failed/cleared/not-ready campaigns, epoch/context/graph changes and
cleanup. Existing real generated Skeleton-blockade, bootstrap/staging, loot
ownership, crash replay, visibility, renderer and lifecycle suites remain green.

These are operation counts and headless behavioral checks, not native CPU, FPS,
thermal or battery measurements. Lua-double cone comparisons preserve the
mathematical threshold; Source float-vector rounding at its exact tangent still
belongs to native acceptance. No FPS improvement is claimed for this build.

## Audit decisions and next evidence

Existing target/perception/music services already have bounded update cadences;
retain them. Keep exact movement/physics, collision, attacks, dodge thresholds,
status durations, dice probabilities, encounter population and progression.
Retain spawn-time size/variance power curves and navigation/movement square roots
where their continuous result is actually consumed; approximating those would
change behavior for a small or unproven saving. No new recurring service or
configuration setting is introduced.

Next: fully quit GMod, install the verified source, and play ordinary
`gm_flatgrass` through targeting/loot, projectile combat and a resolved Skeleton
blockade. Observe responsiveness/smoothness and that the cleared route opens.
Capture `console_latest.txt` + `rpg_summary_latest.txt` if anything regresses.
This is source-only work; retain native acceptance → Workshop parity → matching
VPS release. No Workshop publication or VPS deployment is included.
