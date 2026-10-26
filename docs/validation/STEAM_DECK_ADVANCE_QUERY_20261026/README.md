# Forced-advance query experiment and stair bug handoff

The optimization candidate is **not retained**. Four valid profiler-off captures completed in parent/candidate/candidate/parent order. A fifth parent attempt failed the focus gate before FPS capture; it is preserved and was not replaced. The sixth planned run was not started.

Parent/candidate means: 22.628/23.176 FPS; p95 80.549/78.523 ms; p99 106.780/125.316 ms; 1% low 7.221/6.165 FPS; longest below-target episode 9.073/10.536 seconds. The modest throughput difference does not earn retention given worse tail pacing. No significance or final-acceptance claim.

Experiment `2a3485c5` is published separately on `perf/experimental-forced-advance-query-20261026`. Gameplay/tools are restored byte-exact retained `fcdf6f03` / `fdd75bfc` / `4b68237f`. Both displays stayed ON. Native source/provider and before/after integrity gates passed. All 120 installed hashes and private-controller restoration verify. Probe-helper lexical preflight correction occurred before first bridge execution/FPS; no measured run was replaced.

The user then prioritized enemies and bosses walking through stairs. The production movement kernel calls SetPos without a physical sweep for ordinary and legacy boss actors; only LODBossEncounter actors get the hull check. A local chase goal can also override a committed stair waypoint. The included boundary-double reproduction confirms that code-path bypass; it is not native physics proof. **The stair bug is not fixed in this checkpoint.** A naive collision blocker risks stuck navigation and is not presented as a fix.

The current checkpoint ends at04:16:29 UTC. A separate bug-fix time budget was requested before extending beyond that limit. Complete the shared collision/routing repair and native ordinary/boss stair checks, then resume optimization against the corrected baseline. Old performance results must not validate changed collision code. SP40 remains UNMET; full five-scenario warmed repeated 180-second/ordinary-play/boss/capped acceptance remains UNVERIFIED; PR7draft/main unchanged.
