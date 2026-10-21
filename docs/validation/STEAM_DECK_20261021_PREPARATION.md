# Steam Deck optimization checkpoint — 2026-10-21

**Target unverified; optimization task incomplete.** This publication prepares
measurement. No performance optimization or measured FPS improvement is claimed.

Canonical source base: main1335a3c8b16c5ff0cbf00f1baebdb8b8aeb7fd20, independently
confirmed through GitHub and an authorized git ls-remote. Remote workflow is
direct, non-forced main publication. Live GDD read-only navigation00→01→07,
document1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY, revision
AHj4eMSb0l-TOayXny05SAGYLJ5o6QJTx6Pz6jtdvtoXek2A-goOHyMC7RdJmiUVOgYTxfv9jFozq4KjQrs-jIDWtXgcPvRC2XcxKf7z7Q.
LOD-IMPL-004 preserves low-end resource constraints and existing authorities.
No game-design/tuning rule was changed.

## Recovered state and access blocker

- Physical machine identifies as Steam Deck LCD/Jupiter, SteamOS3.8.28,
  kernel6.18.50-valve2-1-neptune-618-gc7289a96b14d. AC is connected.
- Installed GMod Steam build25375506 contains Windows executables. Prior capture
  reports engine2026.09.17/Windows/x64; Proton prefix configuration identifies
  Experimental11.0-100. Actual current running runtime remains unverified.
- Development addon points to missing~/Downloads/the-legend-of-deborah. No
  recoverable checkout or uncommitted Deborah source was found. Do not replace
  the addon with the partial recovery directory.
- Sandbox exposes no DRM device; Vulkan reports no valid GPU. Ordinary shell
  networking is disabled. Approved read-only git ls-remote and X11 inspection
  work, but they do not grant game execution or clone access. A normal Steam
  launch attempt produced no game or new console log.
- Canonical clone failed DNS resolution. The required escalation was rejected by
  platform policy: sandbox_approval=false. Existing user authorization remains
  valid; the blocker is the execution environment, not missing user consent.
- GitHub connector reads work. A checked Workshop extraction supplied1481 exact
  Git-blob matches;95 current runtime text files were fetched and independently
  Git-hash-verified. The loading JPEG and GPS audio bank remain unavailable
  through this UTF-8-only connector. This is a partial source recovery, never a
  complete installable/current-build validation.
- Prior captures and local recovery/checkpoints are preserved under
  /home/deck/deborah-recovery/. The existing addon and saved game data were not
  repointed to the partial source. No public server or Workshop release occurred.

## Available performance evidence

These rows are not equivalent before/after benchmarks. There is no fresh
baseline on the current source and no candidate hardware measurement.

| Evidence | AverageFPS | Medianms | p95ms | p99ms | 1%low | Time below40 |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| Historical ca7f7d75f69d75b83859a07200f6f85f621f228b, interrupted37.995s active/882frames | 23.214 | 43.329 | 58.147 | 67.422 | unavailable | all882 active frames;37.995s |
| Current main1335a3c8 | unmeasured | — | — | — | — | — |
| This diagnostic checkpoint | unmeasured | — | — | — | — | — |

The historical file was last written October11, despite the newer October14
installed-build marker. Its own start_resources.install identifiesca7f7d75;
never attribute it to1335a3c8. It ended with reasonshutdown during a profile
comparison, fps_max60,1280×800, single-player, native walls, Reduced Effects1,
vsync0. Maximum frame91.696ms;110frames>50ms. No chronological frames survive,
so longest continuous drop and1%low cannot be reconstructed. Earlier moving-view
profile pairs likewise do not establish profiler overhead. VR was observed idle
in historical evidence; current-build idle work still needs fresh confirmation.

## Implemented measurement change

The existing opt-in capture retained only aggregate percentiles and five-second
windows. Those summaries cannot prove the requested two-second failure bound.
Retain its bounded≤65536 chronological frame intervals and compact active index
ranges; sort temporary copies only when saving. Report slowest-1%-mean FPS,
full slow-interval time and continuous slow episodes. Menus/death/staging split
episodes. Expose elapsed unrendered time at termination so a missing final hitch
cannot silently pass. Sampling still has no per-frame disk writes or idle hook.

tools/analyze_deck_capture.py recomputes metrics from chronological evidence,
checks the expected clean install, mounted source, fixed settings, resolution,
map, duration, profile exclusion and terminal gap. It reports uncapped and capped
limits separately, including a predeclared0.25ms capped-only tolerance. It cannot
attest device identity, complete scenario coverage, thermal state, external cap,
ordinary workload, controls or visuals. Old aggregate-only captures are rejected.
The new negative checks are registered in the existing complete matrix.

## Validation and next action

Focused sampler/lifecycle and client/server profiler suites pass, including
bounded collection, no per-frame hashing/I/O, inactive separation, refresh/reset/
shutdown, same-file profile transport and callback restoration. Five Python
test methods cover hidden sustained failures, disjoint active ranges, cap
tolerance, wrong source/build/settings, interrupted/profiled/short captures,
terminal gaps and malformed timelines. All578 recovered Lua files parse.
This is not the full repository923-file syntax inventory or complete matrix.
Raw scoped commands, outputs and source hashes accompany this record.

One initial new fixture expected four active ranges; its own scenario has three
(deployment, then death/menu interruptions). The assertion was corrected;
production remained unchanged. Initial failure details remain in the local
checkpoint and tool receipts. Existing baseline sampler/profiler suites passed
before instrumentation edits. No native capture-overhead measurement is possible
in this session; retain that gate before trusting final FPS.

Restore a session with authorized complete-checkout/network and Steam/GPU game
execution access. Use the exact install/launch/capture/retrieval commands in
[the benchmark protocol](../STEAM_DECK_BENCHMARK.md). Freeze actual starting
checkpoints/routes during the native baseline, then measure→profile→optimize→
regress→remeasure until every required scenario passes three times. Four-player
access, later bosses, ordinary gameplay, visibility/audio/input and capped
smoothness remain unverified. Publish validated optimization source and verify
its final main SHA only after that full gate. This diagnostic commit does not
fulfill the user's completed optimization/publication request.
