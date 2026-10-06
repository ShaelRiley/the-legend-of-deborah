# Native frame-cost diagnosis — October 6, 2026

Parent: clean remote main `7f93cb145fdf1e84fa6a3cfebb62cba76511aab2`, tree
`f1b9fe871a7a2c99eb16c9fd7f6bf36cfa769760`. Live GDD 00 → 01 → 07,
LOD-IMPL-001–004, revision
`ANLCKQmUlHpIXlUgqqjCRjeDq_RX5wfx7ceBkFwsdpnj5ZxQkzwWH2SxmdIiMnmRGrSLjqw2kDKEAZWGg9e2Cg8ohbKLMunfHqqeJwdRdA`,
governs this extension of the existing RuntimeAudit. The author's instruction is
to optimize and simulate autonomously until native testing is necessary. No
authored behavior or tunable value changes; no live GDD amendment is needed.

## Exact native result

Inputs: `performance_client_latest(4).txt` and
`console_latest(20261006-123310).txt`. Their content hashes and extracted evidence
are recorded in the native JSON receipt. All 42 mounted and installed SHA256
hashes independently equal the parent checkout bytes; the renderer verifies 8/8.
No Lua errors are reported. The supplied console does contain material warnings;
zero Lua errors does not certify all native assets or appearance.

| Active-play result | Current 7f93cb1 | Earlier f657913 |
| --- | ---: | ---: |
| Measured active seconds | 163.496407 | 92.947516 |
| Active frames | 2,830 | 2,692 |
| Aggregate FPS | 17.309249 | 28.962581 |
| Median frame ms | 47.440 | 31.063 |
| 95th percentile ms | 104.987 | 56.397 |
| 99th percentile ms | 151.317 | 88.416 |
| Maximum frame ms | 1,464.579 | 281.202 |
| Wall models | 1,718 | 1,364 |
| Initial roamers / occupied floors | 60 / 3 | 36 / 2 |

The current capture covers 179.923794 measured seconds, 180.153942 seconds since
sample start, and all 36 pacing windows; shutdown is the recorded end reason.
Its 2,830 active frames all exceed 25 ms. Nonempty active windows range from
8.70 to 24.75 FPS. The >=40 FPS acceptance gate fails decisively.

Start/end graphics configuration matches the earlier capture: 1280×800,
gm_flatgrass singleplayer, x64 Windows engine under the user's Proton/windowed
Arch Desktop setup, fps_max 60, vsync 0, AA 0, DX95, queue -2, HDR2, picmip0,
shadows 1, Reduced Effects 1 and wall batches 0. Both runs have developer dense
mode enabled. Layout, floors, entities and population differ; this comparison
cannot attribute a regression to the new source or prove an FPS gain from it.

Every live renderer window retains 1,718 applied wall appearances, zero retries,
complete preparation and zero hidden originals. The appearance-loop repair is
still observed. Logo CPU snapshots range 0.3903–1.0095 ms (median 0.58315), with
17–57 candidates/admitted and 3–21 draws. No window reaches the 64-brand admission
ceiling. These are individual render-pass CPU snapshots, not frame averages or
GPU costs. Wayfinding reports zero visits/draws at every window snapshot; these
logs do not establish board visibility. The new heap's synthetic loaded-scene
savings are not representative of this sub-ceiling native workload.

## Bounded attribution checkpoint

`lod_perf_start 180 profile` extends the same opt-in frame observer. Profiling
starts after the existing preparation/warmup. It times registered LOD hooks,
actual native LOD entity callbacks and selected server targeting/navigation/
entry services. Already bound and newly initialized entities are included;
Watcher is timed at its direct canonical behavior call; entry safety uses its
existing method body. Their registered method/binding identities remain intact
during profiling, including the observer's exact AI binding check. Client rendering
also records the inclusive PreRender-to-PostRender interval.

Each row records calls, completed calls, total/mean/max milliseconds and
milliseconds per elapsed second. Rows are **inclusive**: nested service/hook/
entity rows overlap and must not be summed into a total. Errors remain originally
thrown and show an incomplete call. Wrappers preserve self, arguments, every
return and nil position without per-call result arrays or protected calls.
Weak restoration ownership does not retain removed native objects. Stop, restart,
cleanup, shutdown and Lua refresh release wrappers; a newer callback replacement
is never overwritten by the previous captured authority.

The existing admin permission gates one finite server lease. Owner/token checks,
30–300-second duration and the existing 60,000-byte evidence ceiling bound the
transport. Progress copies arrive every five seconds, with a final stop reply.
The same frame file retains a clearly partial server snapshot on immediate quit;
the matching final reply updates it after the next network tick. Stale/malformed
replies cannot overwrite a new run, and oversized reports are explicitly failed.
No recurring profiler hook, callback wrapper or entity scan runs in ordinary play
or a default `lod_perf_start 180` capture.

This is partial **CPU wall-clock attribution**, including engine work called by
the measured callbacks and diagnostic overhead. It does not measure GPU time,
all native engine work, timers, foreign addon callbacks or unwrapped gamemode
methods. It is sufficient to choose a measured next seam if one dominates; a
small measured total would require native engine/graphics investigation rather
than another claim about logo allocations. This environment cannot run the
actual GMod client or its target-hardware renderer. No further FPS gain is claimed.

Relevant native API references:
[Entity:GetTable](https://wiki.facepunch.com/gmod/Entity:GetTable),
[hook.GetTable](https://wiki.facepunch.com/gmod/hook.GetTable),
[GM:PostRender](https://wiki.facepunch.com/gmod/GM:PostRender).

## Finite source gate and native action

The source gate exercises the real observer in separate client/server realms,
exact callback timings/returns/errors, current/new/retired native incarnations,
Watcher dispatch, weak ownership, guarded restoration, bounded/malformed/stale/
oversized network replies, partial/final file merging, permission/lease ownership,
deadline, cleanup/reload/shutdown and default idle behavior. It also retains the
affected renderer, wall visibility, population, entry-safety and native-resource
regressions. This is static production execution with native boundary doubles,
not a native Source performance certification.

After publication, fully quit/update/install main and use the established
gm_flatgrass configuration. Run one console batch:
`lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180 profile`.
Play normally through the full capture, including turns, stairs and combat. Return
`performance_client_latest.txt` and `console_latest.txt`; server/client costs and
population are included. Preserve visible walls, boards and company artwork.
Next optimization is selected from that measured cost; sustained >=40 FPS remains
open. Source publication is authorized; Workshop and VPS remain held.

## Completed source validation

The final frozen candidate passed **37/37 selected checks** and **879 Lua syntax
checks**, with unchanged source throughout and all 37 log hashes verified. The
gate retains actual entry admission, native hostile dispatch/combat and accepted
rendering/lifetime regressions. Production coverage remains 562 files. Evidence:
[native receipt](STEAM_DECK_20261006_PROFILE_native.json),
[selected gate](STEAM_DECK_20261006_PROFILE_gate.json),
[production hashes](STEAM_DECK_20261006_PROFILE_production.json),
[proof](STEAM_DECK_20261006_PROFILE_proof.json) and
[complete selected logs](STEAM_DECK_20261006_PROFILE_logs.tar.gz).
Only these evidence/coordination documents were finalized after the gate; tested
production and test bytes stay unchanged. The separate complete frozen matrix
runs in Actions on the published commit; source checks do not establish native
profiling acceptance or sustained 40 FPS.

## Completed published matrix — recovered October 6, 2026

Published source `0e26d652d3c3beda7423326dd7a4fff53cc107d9`, tree
`6156b1d9c4b493435ed48e0e2501e79c0fa57d23`, completed the
[full matrix](https://github.com/ShaelRiley/the-legend-of-deborah/actions/runs/37468610450)
successfully at 13:18 UTC. All **309/309 suites** and **879 Lua syntax files**
passed. The complete, low-end, ambient-audio and VR workflows all succeeded.
The frozen source digest did not change during validation.

Recovery independently downloaded and SHA256-verified the complete Actions
artifact, verified both output-log hashes for every suite, and matched all
2,504 source files and 562 production files to the clean published checkout.
The production digest also matches the earlier 37-check selected gate. Preserve
the [complete artifact](STEAM_DECK_20261006_PROFILE_complete.zip) and
[CI/recovery receipt](STEAM_DECK_20261006_PROFILE_ci.json) beyond Actions retention.

This closes the pending full source validation. The recovery changes only these
evidence and coordination files; gameplay and diagnostic source remain exactly
the validated build. No new profiled native capture is present. The next action
remains the single `lod_perf_start 180 profile` capture above; native profiling
acceptance and sustained >=40 FPS remain open.
