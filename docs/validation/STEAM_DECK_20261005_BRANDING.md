# Bounded logo work — October 5, 2026

Author direction: do as much optimization and simulated testing autonomously as
possible; request a native test when it is necessary. Parent is verified clean
main `85789e3211c4c9082fc1d938908c7542c7dd10a4`, including the 55% Hair Trigger
correction and accepted native wall visibility. Live GDD navigation was
00 → 01 → 07, revision
`ANLCKQmUlHpIXlUgqqjCRjeDq_RX5wfx7ceBkFwsdpnj5ZxQkzwWH2SxmdIiMnmRGrSLjqw2kDKEAZWGg9e2Cg8ohbKLMunfHqqeJwdRdA`.
LOD-IMPL-001/004 and Crate C1/C3 govern this implementation. Authored constants,
placement, population, palette, gameplay and native wall bodies stay intact;
no tuning value or live GDD amendment is needed.

## Implementation

The existing branding renderer formerly allocated and sorted all eligible nearby
records each frame, then drew only its nearest 64. It now admits the exact same
distance/index ordered prefix through a bounded max-heap only when candidates
exceed the existing ceiling; smaller scenes retain append/sort. At most 64 records
are allocated and sorted, with rejected slots reused. View rejection still occurs
after admission, so farther artwork never substitutes for a culled nearer logo.

Each drawn model retains one latest fitted projection and at most its two faces
through weak ownership. Scalar snapshots detect in-place translation, full
pitch/yaw/roll, scale, metadata bounds/dimensions, safe area, physical cargo bounds,
offset and helper changes. Missing angle access uses fresh computation. Reload
resets the local cache; retired/replaced models are not retained. UVs, outward
normals, front-face winding, untinted artwork, preview outline and native immediate
quad submission remain the same. No native Mesh is created for these logos and
no wall model is hidden or given changed bounds.

Existing opt-in frame evidence now copies branding candidates/admitted alongside
draw/cull/time fields, preserving each window against later mutations. Low-end CI
also runs the loaded Crate renderer/branding probe.

## Paired production probe

Both probes load the same production dependencies and engine-boundary doubles;
only the branding source differs. Exact parent bytes are extracted with
`git show 85789e3211c4c9082fc1d938908c7542c7dd10a4:gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua`.
Run `python3 tools/run_lua54.py tools/test_great_crate_render.lua`; pass
`--baseline /path/to/parent_cl_container_branding.lua` for the parent comparison.
Baseline mode skips only the new workload-reduction assertions, retaining the
same selection/geometry/lifecycle checks. Source/log hashes and measured rows
are preserved in the paired JSON receipt.

| Fixed workload | Parent | Candidate |
| --- | ---: | ---: |
| 600 steady logo draws: vector constructions | 19,800 | 600 |
| Same draws: fit resolutions | 600 | 0 |
| Largest sorted candidate list | 968 | 64 |

All 32 nearest-selection scenes and the existing 2,048 original-art orientation
cases retain their oracle result. Further checks cover mutable movement,
pitch/roll, scale, artwork, fit/helper changes, eligibility/model loss, both faces,
retired-owner collection and admission before culling. The existing overlay
oracle retains 181 visible-corner cases, unknown-view fail-open behavior, depth/sky
exclusion and zero text metric reads over 600 stable frames.

The loaded 968-candidate / 64-draw / 600-frame timings are Lua CPU time under
Lua 5.4 with doubles. They are descriptive samples, not performance assertions,
Source/LuaJIT measurements, native GPU timings or a prediction of Steam Deck FPS.
This environment has no usable GMod client/display/GPU runtime. The latest
native result remains 28.96 active FPS on the previous f657913 build; current
sustained >=40 FPS and appearance acceptance remain open.

## Finite source gate and next native action

The affected renderer/capture/resource/lifecycle/startup gate and all Lua syntax
checks are recorded after completion below. Exact receipts and logs remain
distinct from native acceptance. Source publication only; no Workshop/VPS action.

Fully quit GMod, update/install main, then run on gm_flatgrass in the established
Proton/windowed/Arch configuration:
`lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180`.
Play through turns, stairs and combat until the capture completes. Return
performance_client_latest.txt + console_latest.txt. This one test establishes
the new build's real frame pacing and validates logo appearance while retaining
accepted wall bodies; automatically captured source/population/overlay counts
provide the next bottleneck evidence.

## Completed source gate

The frozen candidate passed **33/33 selected checks** and **878 Lua syntax checks**,
with no source changes during the gate. All suite logs verify against their hashes.
Evidence: [gate](STEAM_DECK_20261005_BRANDING_gate.json),
[paired probe](STEAM_DECK_20261005_BRANDING_paired.json),
[production manifest](STEAM_DECK_20261005_BRANDING_production.json),
[proof](STEAM_DECK_20261005_BRANDING_proof.json) and
[complete selected logs](STEAM_DECK_20261005_BRANDING_logs.tar.gz).
This is the affected finite gate; the separate complete matrix runs in Actions
on the published commit. It is not native acceptance.
