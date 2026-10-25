# BeforeAI diagnostic checkpoint — October 25, 2026

**Outcome C: stop this measurement approach.** No source candidate or child probe is justified. SP40 remains **UNMET**; complete acceptance remains **UNVERIFIED**. PR #7 stays draft and `main` is unchanged.

Tested source: `a4ccd068938a5f1dfa70b6476ad6d7983f16abeb`. Gameplay and tools remain byte-identical to retained `fdd75bfc42d60ca15b11441a40489c64334cb9a7` / `4b68237f`. No new experimental SHA or uninstrumented source gain.

Start: **22:36:58 UTC**; hard deadline: **23:36:58 UTC**. Measurement stopped at **23:13:54 UTC**. One boundary, one alignment/confirmation refinement, eight fresh 60-second captures; no automatic continuation. Final publication time and SHA are recorded in PR #7 and the private recovery checkpoint.

Actual LCD Jupiter Deck, SteamOS 3.9.5/build20261023.100/kernel7.2.7, GMod Win64 2026.09.17/build25375506, Proton10.0-4b, LuaJIT2.1beta3. SP listen-host, one human; 1280×800@60 plus external1920×1080@75 **both ON**;15W AC; fixed graphics/resources/AI cadence. Frozen D20 phase1 lower-court developer-density stress:57initialhostiles/1820walls, campaign654759232/level1217159003/layout899898795/pop588052291; legal20Wizard resources and unchanged640point288radius physical orbit. These short diagnostic captures do not replace ordinary release, full boss progression or the five warmed acceptance scenarios. Earlier SteamOS/hosting results remain separate.

## Captures

Same retained source in every row. OFF has no BeforeAI wrapper, so function calls/cost are **unmeasured**, not zero. Cost is inclusive elapsed wall time under the observer, divided by the corresponding rendered-frame count. It is not exclusive CPU or recoverable time.

| Series / arm | Observer | FPS | p95 ms | p99 ms | 1% low | Longest <40 s | Calls in frame window | BeforeAI wall ms/frame |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| initial-v1 / arm01-off | off | 23.555 | 73.757 | 96.017 | 7.451 | 8.903 | — | — |
| initial-v1 / arm02-on | on | 23.400 | 74.033 | 99.467 | 7.419 | 9.248 | 235369 | 2.538 |
| initial-v1 / arm03-on | on | 23.111 | 76.547 | 117.125 | 6.542 | 10.099 | 233199 | 2.553 |
| initial-v1 / arm04-off | off | 23.167 | 77.728 | 105.968 | 7.006 | 9.682 | — | — |
| confirmation-v1 / arm01-on | on | 23.074 | 75.395 | 93.391 | 7.304 | 10.401 | 236782 | 2.617 |
| confirmation-v1 / arm02-off | off | 22.425 | 77.484 | 97.612 | 7.548 | 8.796 | — | — |
| confirmation-v1 / arm03-off | off | 22.852 | 77.338 | 110.244 | 7.246 | 12.380 | — | — |
| confirmation-v1 / arm04-on | on | 22.158 | 79.360 | 115.436 | 6.824 | 20.944 | 236391 | 2.730 |

## Observer decision and limits

Initial mean throughput penalty **0.451%**, reversed confirmation **0.099%**, pooled **0.278%**. Controls span **22.425–23.555 FPS** (4.915% of their mean). The full observed cross-condition penalty envelope is **−4.351% to +5.932%**. That envelope is descriptive variation, not a matched causal estimate or confidence interval. A small mean does not establish the 5% bound.

Confirmation longest-drop means are **10.588s OFF /15.673s ON**, including **20.944s** in the closing ON versus8.796/12.380s in its controls. Initial p99 worsens7.23%; confirmation0.47%;1%low worsens3.43%/4.50%. These do not prove observer-caused regression, but do not establish harmless pacing. The finite gate remains unresolved; no second refinement or child was started.

The whole-window constant filesystem/SysTime offset is explicitly rejected. The one refinement uses endpoint-local start/end brackets, the same2msguard and an unchanged recorder, followed by reversed confirmation. Zero direct client/server SysTime delta is compatible with both local brackets. Tiny endpoint-supported count/cost sensitivity does not bound nonlinear drift or prove exact frame assignment. Raw clocks and the rejected analyzer are preserved.

Qualified BeforeAI observations span2.538–2.730ms/frame across233199–236782calls/window. All calls completed, no overflow, maximum active nesting1. Long wall durations can include native work, scheduling or waiting. Do not sum these values with NextBot/movement scopes, subtract the old20.6% penalty, or infer redundancy from call count. Nested code remains stateful; no safely removable subset is identified. This does not prove there is no economical remedy or that40FPS is impossible.

## Regression and restoration

Both Lua5.4 and LuaJIT probe fixtures pass exact arguments/self/all nil-bearing returns, off path, inherited/foreign-owner restoration, errors, yields and overflow forwarding. All eight native capture source checks verify52authorities/0missing/mismatches, start/endLuaerrors0; HUD/native renderer/scene/resources/input/both-display checks completed. The runtime/tool trees remain unchanged; all120installed hashes verify. Providers and private controller restored, new DATA scripts removed, owned games/profilers stopped, both displays ON.

All eight **automatic acceptance checks FAIL**, including the budget/prolonged-drop and unrendered-terminal-interval flags. Integrity checks above are separate. Reported metrics cover actual rendered first-to-last intervals; the terminal unrendered remainder is not hidden or counted as a sampled frame. Full five-scenario3×180s warmed ordinary-play/boss progression and separate40cap verification remain UNVERIFIED. No broad unchanged matrix was repeated locally. Existing nine/336 CI failures are documented separately from instrumentation fixtures; no green or accepted-optimization claim.

## Evidence and reuse

`initial-v1/` and `confirmation-v1/` preserve every frame capture and full BeforeAI timeline (gzip), clocks, source/resources/input/display receipts and all failed acceptance analyses. `SHA256SUMS` covers the artifacts. Complete original logs remain under `/home/deck/deborah-benchmarks/low-overhead-native/a4ccd068/{initial-v1,confirmation-v1}`. Helpers and the private-controller patch archive the exact instrumentation; they are not installed gameplay code. To rerun analysis, copy an arm outside the repository, decompress `bench_beforeai.json.gz` and `performance_client_latest.txt.gz` there, then run the archived analyzer on the series directory. See the JSON decision beside this directory for all qualifications.

Update the retained development installation with Garry’s Mod fully quit:

```bash
cd /home/deck/Downloads/the-legend-of-deborah
git switch perf/deck-20261021
git pull --ff-only origin perf/deck-20261021
bash tools/install_dev.sh
```

One next decision, only if another bounded tranche is commissioned: reuse the already-working native VProf path to localize the largest recurring stalls within existing engine scopes. Avoid further per-call Lua wrappers, new symbol infrastructure and speculative implementation. Multiplayer, future features, Workshop and VPS remain deferred.
