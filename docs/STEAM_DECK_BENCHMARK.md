# Steam Deck acceptance protocol — frozen 2026-10-21

Status: **unverified**. Focused stationary Deck baselines exist in
`docs/validation/STEAM_DECK_20261021_ITERATIONS.md`; required gameplay coverage
and final acceptance remain open.
This protocol precedes further performance changes. The October 14 consultant
changes remain source-validated, not native-performance accepted. Do not adjust
scenarios, thresholds, counts, graphics or resolution in response to poor results.

## Current user scope — 2026-10-23

The user explicitly narrowed the current goal to **singleplayer on Steam Deck**.
The five singleplayer scenarios below remain required, with their existing
resolution, both-monitors-ON condition, gameplay, pacing, warmup, three-repeat
and capped/uncapped criteria. Multiplayer testing is deferred and cannot block
this current goal. The historical coop row is retained as future coverage,
not part of current singleplayer acceptance. No performance threshold or
singleplayer workload was relaxed by this scope clarification.

## Developer-fixture qualification — 2026-10-23

Existing short D20/D10 developer fixtures use `lod_developer_mode 1`.
`sv_m3_dense_testing.lua` doubles discretionary encounter-planning threat budgets,
sets developer caps3/4/4/4 and spacing2; the plan reports `developerDense=true`.
“Normal resources” in those records means canonical XP/feats/starter/deployment
and unchanged active gameplay; it does **not** prove release-density equivalence.
Preserve these frozen stress conditions and all prior results. Do not quietly
remove enemies, change planning or relax any acceptance requirement. Record
ordinary release-mode corroboration separately; it remains unverified, alongside
all five full singleplayer acceptance scenarios. Current short stress captures
are not final acceptance.

## Conditions and evidence

- Steam Deck LCD/Jupiter, 1280×800 actual viewport. Record SteamOS/kernel, GMod
  engine/Steam build ID, native Linux versus Proton and the exact Proton version.
- Retain graphics, native cargo renderer (`lod_wall_batches 0`), content, AI and
  ordinary population. Initial graphics match the prior Deck capture: picmip0,
  AA0/quality0, HDR2, shadows1, shadow-to-texture1, expensive water1, viewportscale1,
  vsync0, Reduced Effects1, first person, map size/opacity1. Record all remaining
  settings. A different baseline is a separately identified condition.
- Target device: SteamOS3.8.28, kernel6.18.50-valve2-1-neptune-618-gc7289a96b14d,
  Steam GMod build25375506. Installed files indicate Windows x64 under Proton
  Experimental11.0-100; confirm the actual running process before accepting it.
- Keep **both monitors on at all times**, as explicitly required on2026-10-22.
  Internal1280×800@60; external1920×1080@75 restored after historical diagnostics.
  No monitor-off result qualifies. Preserve display layout and record both states.
- Fix internal display60Hz, power15W, GPU automatic, AC connected; verify these on device
  rather than assuming them from installation files. Record fan/temperature,
  CPU/GPU clocks/utilization, memory and network observations where accessible.
  Keep background workload identical. Initial loading and compilation get their
  own records; never include them as steady gameplay or discard gameplay hitches.
- Uncapped: `fps_max 300; mat_vsync 0`, external Steam/MangoHUD limits disabled.
  Capped verification: intended40FPS limiter; identify exactly one limiter and
  keep all other conditions identical. Report the two modes separately.
- Warm the device under game load for at least10minutes, then verify temperatures
  have stabilized. The sampler's3-second warmup alone is insufficient.
- Initial seeds: campaign654759237 and developer roster2084084476. Preserve the
  same Hero, party, inventory, map, progression and world checkpoint between
  builds. Custom seeds mark the session unranked; they do not alter gameplay.
  Record actual layout/population seeds, counts and boss phase from the logs.
- Match actual AI execution cadence, not only actor counts or stored profiles.
  The listen-host baseline reports one NextBot tick. Native dedicated defaults
  were later found to move actors at less than half that travel rate; those
  earlier short results are not equivalent workloads. Current captures include
  authoritative `population.server_runtime` settings/human counts. Record
  nb_update_frequency, nb_update_framelimit, tick interval, time scale, sv_cheats,
  nb_stop and ai_disabled, and corroborate cadence with actual movement/behavior.
  A client-local cvar is not proof of a nonreplicated server value. Missing
  metadata or unexplained cadence differences leave acceptance unverified.
  In the2026.09.17 listen-host runtime, the exposed frequency reads`.1` while
  the native engine reports one-tick scheduling. Do not infer effective cadence
  from that convar alone or equate the simulation tick rate with observed AI
  callback rate. Preserve the fresh startup scheduling report and corroborate
  actual callbacks/movement; the bounded three-actor observation and its limits
  are recorded in `validation/STEAM_DECK_AI_CADENCE_20261023.json`.
  The one-tick sv_cheats1 mechanism diagnostic does not establish a normal
  production configuration or waive any frozen hosting/gameplay criterion.

## Required scenarios

Each scenario needs three independent complete180-second uncapped captures on
the warm device, with at least170 active seconds per capture. Short30-second
runs are useful during iteration and never replace final acceptance. Repeat
ordinary play as corroboration. Each controlled run must retain real AI,
ordinary enemy counts and authored effects. Record exact starting state,
waypoints, actions, targets and inventory during the initial baseline; freeze
that route/checkpoint before any performance optimization. Those physical route
and checkpoint records are currently missing, so scenario coverage remains open.

| ID | Required workload | Players and hosting |
| --- | --- | --- |
| traversal | Dungeon1: arrival through varied maze sightlines, corners, stairs and long views toward each colored gate; map open/close on the same route | 1, Deck listen host |
| combat | Dungeon10: dense ordinary encounters; move/aim/fire, cast owned Magic, retain projectiles/statuses and collect generated loot | 1, Deck listen host |
| interactions | Dungeon1: normal event, map/key pickup, red/blue/yellow progression, Neil console and objective prompts; orbit required props at ordinary angles | 1, Deck listen host |
| boss14 | Dungeon14: normal Chuck/Jane fight including hazards, adds and phase transitions; record phase-aligned starting checkpoint | 1, Deck listen host |
| finale | Dungeon20: Gordon→Hector phases, encounter effects and progression interactions; capture each phase separately if necessary | 1, Deck listen host |
| coop | Repeat combat with four actual connected players, normal behavior and effects, plus shared pickups/gates and reconnect state | 4, dedicated server; record host, RTT, loss and tick timing |

Record whether the intended deployment additionally requires a four-player Deck
listen host; if so, retain it as an additional required condition. Bots or a
headless server cannot stand in for native four-player input/rendering evidence.
An inaccessible scenario stays unverified. Developer boss setup may position a
test checkpoint; acceptance combat retains normal health/damage/resources and
must not use the boss testkit's altered player resources.

## Capture and analysis

Fully quit GMod before installing. Restore the missing checkout if needed:

```bash
git clone --branch main https://github.com/ShaelRiley/the-legend-of-deborah.git ~/Downloads/the-legend-of-deborah
```

Normal updates/install use the existing installer:

```bash
cd ~/Downloads/the-legend-of-deborah
git fetch origin main
git switch main
git pull --ff-only origin main
bash tools/install_dev.sh
git rev-parse HEAD
```

Launch the installed Windows x64 GMod through Steam/Proton with
`-windowed -w 1280 -h 800 -condebug -conclearlog +gamemode legend_of_deborah +map gm_flatgrass`.
Retain the existing verified VR dependency; confirm idle non-VR work in captures.


For the separately recorded public-Windows64/Proton10, multicore1 condition,
copy the checked-in settings file after installation:

```bash
cp tools/steam_deck_benchmark.cfg "$HOME/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/cfg/lod_deck_benchmark.cfg"
```

Append `+exec lod_deck_benchmark.cfg` **after** `+map gm_flatgrass` in the x64
launch arguments. A fresh actual Deck launch verified this order restores
multicore1 without a later console command. Confirm the running process is x64;
a generic Steam launch/selector previously selected32bit. This opt-in file uses
the recorded unchanged graphics, fps300/vsync0, multicore1, queue2 and threaded
bones1; it does not select a different hosting condition. It is not automatically
installed or applied to ordinary players. Initial Experimental/multicore0
measurements retain their original conditions and are separate comparisons.

`gmod_mcore_test` resets to0 on a normal restart; do not assume its previous
value persisted. The task-local capture harness now verifies multicore, queue,
threaded bones, FPS limit, vsync,1280×800 and focus before starting a capture.
A deliberately mismatched expected multicore value was rejected before any
performance capture. Exact harness/launcher snapshots and receipts:
`~/deborah-benchmarks/auto-settings-launch/31a09219/` and
`~/deborah-benchmarks/preflight-guard/31a09219/`.
For capped verification, apply `fps_max 40` after the uncapped launch config and
use the declared capped analyzer mode; never rerun the uncapped config during
a capped capture.
Use the installed developer marker for controlled unranked setup. In the GMod
console, before starting the baseline campaign:

```text
lod_campaign_seed 654759237; lod_roster_seed 2084084476; changelevel gm_flatgrass
```

Deploy normally. Existing `lod_boss_test_level 10`, `14` or `20` can prepare the
selected dungeon in an admin developer session; it requires a living active
player and ready world. Record the actual starting state and deploy normally.
After thermal warmup, the uncapped capture batch is:

```text
lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; fps_max 300; mat_vsync 0; lod_perf_start 180
```

Close the console and execute the frozen scenario. Keep the game open through
the save. Copy the files after **every** run because latest files overwrite:

```bash
cd ~/Downloads/the-legend-of-deborah
run_dir="$HOME/deborah-benchmarks/BASELINE/traversal/uncapped/run-1"
mkdir -p "$run_dir"
data_dir="$HOME/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah"
cp "$data_dir/performance_client_latest.txt" "$data_dir/console_latest.txt" "$run_dir/"
cp "$data_dir/dev_build.txt" "$data_dir/dev_population_sources.txt" "$run_dir/"
python3 tools/analyze_deck_capture.py "$run_dir/performance_client_latest.txt" --expected-commit "$(git rev-parse HEAD)" > "$run_dir/analysis.json"
```

Change the build/scenario/mode/repetition directory for each run. Retrieve from
`~/deborah-benchmarks/` with ordinary file transfer; preserve raw captures and
the condition/route/checkpoint record. An analyzer exit1 means failed capture
checks; exit2 means absent/invalid evidence. Do not delete failed runs.

Profile a separate matched short run with `lod_perf_start 30 profile` only when
diagnosing the bottleneck. `lod_perf_compare 60` is the existing stationary
overhead diagnostic; keep position, view and workload fixed through both legs.
Its moving-view results do not measure profiler overhead. Inclusive client/server
CPU rows overlap, and the render submission interval is not GPU time. Compare
GPU counters and render-resolution diagnostics separately; restore the frozen
settings before comparative/acceptance runs. No profile run certifies final FPS.

## Thresholds and regressions

Uncapped **every repeat**: average≥40FPS; p95≤25ms; p99≤31ms; no continuous
below40 episode≥2seconds; inspect recurrence and all major stalls. Retain18.5ms
steady-state as headroom goal. 1% low = reciprocal of the mean of the slowest
ceil(N/100) active frame intervals; time-below-budget counts full slow intervals.
Inactive menus/death/staging split episodes. Ordered intervals and active ranges
remain in the JSON; no per-frame disk writes or idle sampler are added.

After all uncapped scenarios pass, verify each with the intended40FPS cap and
smooth controls. Use `fps_max 40` for the engine limiter, or retain300 with a
documented external40FPS limiter. Repeat captures and analyze with
`--mode capped40`. The predeclared limiter tolerance is0.25ms: mean/p95≤25.25ms
(mean≥39.604FPS), p99≤31.25ms, no≥2second episode above25.25ms. Raw25ms results
are still reported. This tolerance never applies to uncapped acceptance.
The analyzer rejects an unknown or excessive unrendered terminal gap rather
than silently omitting a final hitch. It checks one capture, not device identity,
whole-scenario coverage, controls or subjective smoothness.

For each iteration record: source SHA/hash, hypothesis and subsystem, change,
equivalent baseline/previous/candidate measurements, noise/thermal observations,
retain/revert decision, regressions and next bottleneck. Confirm routes/collision,
all-angle required-prop visibility, progression/loot, AI/combat/Magic timing,
input, continuous audio, reset/cleanup and co-op synchronization. Measure capture
overhead against equivalent ordinary play; corroborate final results with sampling
disabled or independent frame telemetry. Tests and predicted gains are never
Steam Deck acceptance. Publish final source to main only with its actual evidence
state; the completed optimization claim requires the full hardware gate.
