# Native VProf phase checkpoint — October 26, 2026

**No source candidate was justified. This aggregate profiling approach has reached its current attribution limit.** Sustained 40 FPS remains UNMET; complete acceptance remains UNVERIFIED. PR #7 stays draft and `main` is unchanged.

The 45-minute cap counts from the resume first recorded at 23:57:20 UTC, including earlier CI verification and waiting. Steering arrived at 00:15:34 UTC and did not reset the clock. The conservative cutoff is 00:40 UTC. Measurement stopped at 00:24:56; the engineering decision was recorded at 00:26:49. Publication time is recorded in PR #7 and recovery records.

Tested source: `26ccc4d`. Gameplay and tools remain byte-identical to retained `fdd75bfc` / `4b68237f`. There is no experimental SHA, implementation, new calibration cycle or uninstrumented source gain. BeforeAI remains closed with its previous qualifications.

## Question and measurements

Does the previously reported 149–150 ms filesystem-open peak recur during later combat? We reused native VProf, delaying its first boundary by 15 seconds. Reports were generated after capture; host postprocessing waited until both games had stopped. No Lua method wrappers, symbols or profiling framework were added.

Conditions remained fixed: actual LCD Deck, singleplayer listen host, frozen D20 workload, 1280×800, both displays ON, 15 W AC, the existing runtime, graphics, population, legal resources and AI cadence. These are diagnostic runs with iteration warmup, not final warmed acceptance.

| Run | Nativewindow after firstframe s | Nativeframes / matchedrenderedframes | Full mixed-observer FPS | Later matched FPS | Later p95 / p99 ms | Later max ms | Later longest <40 s |
|---|---|---|---:|---:|---|---:|---:|
| arm01-on | 15.068–59.548 | 946 / 945 | 21.702 | 21.265 | 84.113 / 141.054 | 204.815 | 11.721 |
| arm02-on | 15.078–59.543 | 1012 / 1011 | 22.427 | 22.770 | 76.012 / 97.864 | 140.516 | 10.475 |

The largest rendered frames, 311.530 and 339.969 ms, occurred near +1 second, outside the later windows. The exact direct filesystem-open child beneath the server gamemode protected call reported 16 opens, 14.134 ms total and a 3.84 ms peak in the first late window; the second reports no such node. This is not absence of all I/O. The earlier 149–150 ms peak was not reproduced in these two later windows, but its resource, timing and call site remain unknown.

Later server gamemode protected-call peaks were 46.53/20.86 ms. Protected NextBot averages were 11.947/11.280 ms per native reported frame. These remain inclusive engine quantities, with opaque Lua and native descendants. Native counts and matching rendered counts are separate; peaks from different scopes cannot be assigned to one frame or added together. Later stalls and prolonged deficits remain.

The leaf/render-group possibility was already addressed in the prior plan: changing the static render group does not bypass the reference leaf pass. Visible geometry is opaque; invisible collision kinds already use `SetNoDraw`. No new mechanism or candidate was established.

## Evidence, restoration and decision

Each arm preserves compressed raw frame/native reports, parsed hierarchies, actual engine boundaries, source/HUD/resources/input/display receipts and failed acceptance analyses. Original complete logs remain at the private path in the JSON decision. `plan-qualification.json` identifies stale inherited C/P/P/C prose; the actual series was ON/ON, with no calibration or source comparison.

Both captures passed loaded-source, zero Lua-error, HUD, renderer, resource, input, display, boundary and restoration checks. All 120 installed hashes verify. The private controller is restored, the temporary DATA helper removed, owned game/profiler processes stopped, and both displays ON. Automatic acceptance failures and terminal-interval flags are preserved. No unchanged broad local matrix was repeated.

Retained `26ccc4d` CI passed 327/336, with exactly the same nine baseline failures; performance-source, VR and audio passed. New documentation-commit CI may be pending at delivery; PR #7 records its actual status. Full five-scenario warmed 3×180-second, ordinary-play, boss-progression and capped verification remain unverified.

**Decision:** stop this aggregate native VProf approach. No safely removable operation was identified. This is an attribution limit, not proof that 40 FPS is impossible. Require a concrete algorithmic mechanism or an identified new attribution capability before funding more equivalent captures. No next checkpoint is automatically commissioned.

Update the retained development installation with Garry’s Mod quit:

```bash
cd /home/deck/Downloads/the-legend-of-deborah
git switch perf/deck-20261021
git pull --ff-only origin perf/deck-20261021
bash tools/install_dev.sh
```
