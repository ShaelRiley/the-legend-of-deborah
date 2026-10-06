# Native container overlay work — October 5, 2026

Clean main parent `f657913cb5d719df704148ad0db4341708f1b46d` is verified against
the attached capture's seven renderer and 41 exact mounted/installed population
source hashes. The author reports: "Impression: performance has improved
somewhat, but still has a ways to go." The source hash checks and complete capture
are preserved in [native receipt](STEAM_DECK_20261005_OVERLAYS_native.json).

| Native capture | Walls | Active seconds | Active FPS | Median ms | p95 ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| 6dc145d | 1,868 | 41.80 | 13.68 | 68.930 | 137.926 |
| f657913 | 1,364 | 92.95 | 28.96 | 31.063 | 56.397 |

These are different generated mazes, not a controlled before/after experiment.
The latest capture ended on shutdown before its requested 180 seconds. Its 18
full active windows aggregate 28.49 FPS and range from 20.31 to 38.63 FPS; the
last 2.99-second partial window reaches 43.21 FPS. Sustained >=40 FPS fails.
Settings remain 1280x800, Proton's Windows x64 engine, Reduced Effects on, native
walls, fps_max 60 and the same reported graphics configuration, with no setting
changes or recorded Lua errors. Live native applications remain exactly 1,364
with completion true and zero retries/hidden models in every window. This accepts
the prior appearance-quiescence gate without claiming all performance is solved.

## Bounded source checkpoint

Native wall bodies retain their renderer, material, palette, geometry, collision
and bounds. The existing batch camera test now exposes two small shared methods
for manually submitted container overlays; experimental replacement batching stays
default-off. Perspective tests use the actual current pass, including nested
cameras, its adjusted FOV/aspect and full angle basis. Only spheres wholly outside
that view are rejected. Unknown, nonfinite, orthographic or off-center views draw
as before; tangency and visible edge intersections remain eligible.

The plywood/text hook excludes depth and skybox passes. Its sphere encloses the
actual board anchor, border, text and offset underprint. Exact instance/code/font
lifetime caches remove recurring text measurements and invalidate on code or Lua
refresh. Logos use the known physical stock cargo bounds rather than mutable
culling bounds. Their original nearest-64 distance selection precedes rejection,
so culling does not substitute farther company artwork. Placement, density,
coverage, artwork fit/UV/orientation, distance limits and all game rules remain.

The loaded regression has 300 boards plus 300 logo candidates split before/behind
one fixed camera. Parent overlays submit 300 boards and 64 logos; repaired ones
submit 150 and 32. The [negative control](STEAM_DECK_20261005_OVERLAYS_negative_control.json)
uses exact parent overlay sources with the repaired camera helper and fails for
continued offscreen submissions. The repair retains all 181 independently
projected visible-corner cases across FOV/aspect/yaw/pitch/roll combinations,
switches nested cameras, draws conservatively on incomplete views, skips every
excluded pass and performs zero text metric reads across 600 steady frames.
Existing 2,048 artwork/orientation, 64-draw, placement, UV and native-wall/idle
regressions remain. These submission counts are not native GPU timing or FPS.

The existing opt-in frame capture includes copied per-window overlay counts and
CPU durations without adding an idle profiler/timer or calling a placement census
from render. Branding joins exact-source verification: eight renderer and 42
population/installer sources. There is no new performance/quality preference.

Parent complete-matrix Actions [run 37377319992](https://github.com/ShaelRiley/the-legend-of-deborah/actions/runs/37377319992)
passes the Lua native regressions but fails installer-test cleanup with
`OSError: Directory not empty`, before its full matrix runs. The test now starts
each installer in an owned process group, adopts its background descendants,
terminates/reaps them within a finite deadline and only then removes temporary
files. Installer runtime behavior is unchanged apart from the additional hash.
This repairs test ownership rather than suppressing the failure.

Live design route remains the exact GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
00 -> 01 -> 07, preserving LOD-IMPL and the Great Crate bounds. There is no new
tuning value or live design amendment. Native source changes remain distinct
from visual/performance acceptance. Static gate evidence is appended after the
frozen candidate completes; source publication retains its exact production bytes.

## Next native gate

Fully quit/update/install main, deploy on gm_flatgrass in the established Proton
windowed Arch Desktop configuration, and run
`lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180`.
Play for the full capture through turns, stairs and combat. Confirm wall bodies,
nearby plywood/stencils and company artwork remain correct; return
performance_client_latest.txt + console_latest.txt. Source verification, copied
overlay work, idle appearance and population are automatic. The FPS effect of
this checkpoint is unmeasured and the >=40 FPS gate remains open. No Workshop
publication or VPS deployment is authorized by this source checkpoint.

## Completed source gate

The frozen candidate passed **307/307** suites and
**877** Lua syntax checks with zero source changes. Every suite
stdout/stderr hash verifies. Publication appends only this gate evidence;
all 562 production Lua files retain the validated bytes.
See [matrix](STEAM_DECK_20261005_OVERLAYS_matrix.json),
[production](STEAM_DECK_20261005_OVERLAYS_production.json),
[proof](STEAM_DECK_20261005_OVERLAYS_proof.json),
[complete logs](STEAM_DECK_20261005_OVERLAYS_gate_logs.tar.gz) and
[failed parent CI evidence](STEAM_DECK_20261005_OVERLAYS_parent_ci.json).
