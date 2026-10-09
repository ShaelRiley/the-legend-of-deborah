# Steam Deck checkpoint: hostile visual scale key reuse

Parent: `b8b9cfd6c4efb711fa2d8fe18f15e1fc75681505` on
`ShaelRiley/the-legend-of-deborah`, branch `main`. The containing commit is the
candidate. Native Steam Deck performance and sustained >=40 FPS acceptance
remain open.

## Evidence and implementation

The latest available October 9 UTC native capture precedes the published
physical-footstep checkpoint: clean `0fe2df6`, 21.3329 active FPS, median
40.331 ms, p95 75.604 ms, 1,604 wall models and 58 initial living wanderers.
Client/server profiles are complete, settings are fixed, VR is idle and Lua
errors are zero. Hostile Draw averages 0.097224 ms across 51,372 calls.
Inclusive profile timings overlap and include observer overhead; GPU cost is
unmeasured. Different generated scenes prevent isolated FPS attribution.
Earlier native logs remain in STEAM_DECK_20261009_PHYSICAL_STRIDE.tar.xz.

Extend the existing hostile visual-scale key cache. Read every native input and
run every pose/recoil callback as before. Reuse the formatted key only when
model, resolved size, Motion V2, archetype, lift, roll and recoil match exactly.
Changed inputs retain the original four/two-decimal formatting and matrix
decision, including rounding boundaries and signed zero. NaN never matches;
custom conversions retain the ordinary path. Formatter/converter replacements
invalidate reuse. A module-local weak registry owns one mutable record per
entity, without retaining retired entities; Lua refresh starts a fresh registry.
Clearing the existing native matrix key still forces its normal reconstruction.
No new hook, timer, network request or native getter is introduced. Models,
bounds, native draws, movement, gameplay and graphics preferences are preserved.

The installer now records 52 hashes; population verification watches 48 modules
and the performance capture verifies 16 client modules, including hostile
`cl_init.lua`. Existing once-per-session hashing stays outside drawing.
Both client capture fixtures and the B28 fixture include the new source;
tampered hostile client bytes and absent/mixed manifests remain rejected.

## Finite gate

Actual published-parent and candidate traces match byte for byte across
14,862 draws, including 942 branch, rounding, callback, roll/recoil and lifecycle
cases plus 58 stable visible bodies x 240 draws. All distinct native scale/bounds
branches, legacy motion, model/phase changes, death/hidden/boss dispatch, custom
conversion, formatter replacement, Lua refresh, retained full-update entities
and retired-entity collection are exercised.

| Work in the stable-body workload | Parent | Candidate |
| --- | ---: | ---: |
| Scale-key formatting calls | 13,920 | 58 |
| Native input getters | 125,338 | 125,338 |
| Model submissions | 13,920 | 13,920 |
| Matrix updates | 58 | 58 |
| Render-bounds updates | 58 | 58 |

Formatting calls fall 99.5833%; this is not a claim about total CPU time or FPS.
The unchanged parent passes the behavior probe and fails the new work bound.
Both traces contain 270,134 lines and 6,200,308 bytes; SHA256
`63dc48d99f55b6dd7fca493e553143368ab214d8063a53cfcd7da4a4444037fc`.

All 317 canonical checks have passing coverage on the same frozen 2,575-file
source: 66 completed receipts from the corrected run and the remaining 251 from
its continuation. The corrected session ended before its aggregate receipt;
only uncompleted checks were resumed, with unchanged canonical commands and the
600-second timeout. Every individual receipt, exact command and all 634 raw
stdout/stderr streams are independently verified. All 887 Lua files parse.
The source digest remains
`64b45a0f10b27203a5f80354d36c39e73519bdd9cb11e941851d6cafd3d67bab`
through both runs and final verification. These checks are headless evidence,
not native GMod or Steam Deck acceptance.

The first partial matrix exposed two omitted source-list fixtures and seven
dependent failures. Its completed receipts and raw streams are retained; it
is not final validation. Early focused-fixture diagnostics corrected a trace
serializer's custom-conversion side effect and accounted for the existing
model-bounds getter. The production optimization did not change after the first
successful parent/candidate trace comparison. Documentation and evidence
packaging follow validation; all frozen production/test hashes are rechecked.

Live GDD navigation: 00 -> 01 -> 05/07, document
`1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`, revision
`ANLCKQnrYkXEQkWhbY2lFbkh3C5XrRI-q4oBgGMtvVIvs78hQeS96NzZ3OIRtG4TjIZ4DGBr3d0o_ye6s_-butEXqxYjMR0xgyBfcEiqPQ`.
LOD-IMPL-001/004/005 and accepted world/presentation behavior govern this
implementation-only checkpoint. No authored tuning or design amendment.

[Reproducible evidence archive](STEAM_DECK_20261009_HOSTILE_SCALE.tar.xz) contains
paired traces, the published parent, negative control, final and failed partial
matrix receipts/streams, complete syntax output, scoped GDD, source manifest,
patch and independent verification.

## Next native gate

Fully quit GMod, then pull/install main:

```bash
cd ~/Downloads/the-legend-of-deborah && git fetch origin main && git switch main && git pull --ff-only origin main && bash tools/install_dev.sh
```

Restart `gm_flatgrass` and enter:

```text
lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile
```

Keep GMod open through the final server reply; return
`performance_client_latest.txt` and `console_latest.txt`. Require the exact
containing clean commit, 16 verified client / 48 population modules, complete
profiles, idle VR, zero new Lua errors, unchanged appearance/gameplay and
sustained >=40 FPS. No Workshop publication or VPS operation.
