# Steam Deck generated-geometry Lua-field reuse — October 8, 2026 UTC

## Native evidence and governing authority

The supplied October 8 UTC / October 7 local capture verifies clean main
`4af3b40a4f9d3c87139dfbe3149d1e8f2c7e413e`. Its settings stay fixed and both
client and server CPU profiles complete. There are 3,662 active frames over
167.073779 seconds: **21.918460 FPS**, 38.689 ms median, 81.794 ms p95,
141.747 ms p99, and 359.494 ms maximum. Of those frames, 1,062 exceed 50 ms
and 98 exceed 100 ms. Native walls remain at 1,732. Recorded Lua errors remain
zero; VR stays fully idle with no hooks, timers, method overrides or native
resources. The client verifies 15 source files; population reports verify
45 sources, with no missing or mismatched files. This generated scene differs
from previous captures, so its FPS is not a controlled source regression.
Sustained 40 FPS remains unproved.

Generated static geometry is the largest measured custom client callback:
110.351710 ms/second, averaging 2.569081 ms over 7,732 calls for 3,865 total
rendered frames. The complete render phase averages 17.121835 ms. These are
inclusive wall-clock measurements with profiling overhead; nested rows overlap
and GPU work is unmeasured. Do not add them into a total CPU budget. Server
EntrySafety.BeforeAI and EnemyRoster.TickCloseDefense remain prominent.

Governing live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
00 → 01 → 07, LOD-IMPL-001 through -005. Its read revision is
`AHj4eMRd4acJKKEDgqukO9zGvoMQvxlbUMdF6nZCAXYFhQm-CNvzGIub5PLIO_oXk6fEWbrk_V-_2bJc4m1wqQvkXjzdDNhY5wQfHSd7Pg`.
No authored tuning or game rule changes. Main is the implementation authority;
native acceptance remains a separate evidence state.

## Implementation and finite gate

Extend the existing static entity's verified weak Lua-table borrow to the
drawable readiness, geometry accessors and visual snapshot. The current kind
accessor pair and backing-record identity must still match. Copied/expired
tables and missing/inherited instance accessors retain ordinary entity lookup.
Every drawable pass still reads native validity, hidden state, bounds and pose.
Read each current geometry scalar once, including during snapshot rebuilds;
retain all camera/frustum tests and immediate geometry/pose changes.
Facepunch's [Entity:GetTable documentation](https://wiki.facepunch.com/gmod/Entity%3AGetTable)
confirms that this table exposes stored Lua fields. It is not a replacement for
engine state: the actual bounds/pose getters still execute on each pass.

The existing TexturedBox mesh authority uses the same verified registry borrow
to check snapshot ownership, preserving exact raw argument identity and the
ordinary direct-call API. No bound functions or entities are retained by the
weak table. Draw order, mesh/UV/matrix/material/alpha submissions, wireframes,
grates, underdeck, cache lifetimes, transmission/full-update recovery and Lua
refresh stay intact. There is no new timer, cadence, renderer, preference,
graphics setting, server rule, AI or population change.

In the paired 1,200-box scene, 120 drawable floors over 120 warmed passes keep
**14,400 draws** while counted native entity-field reads fall from
**273,600 to 172,800 (36.8421%)**. The exact parent fails the new work gate.
All 726 recorded mesh/wireframe rows match byte for byte; their SHA256 is
`f2ec0cd283b57450ee7b88f7094acda235b93368a4e0ec0390c140ffe06bb021`.
The observed-table path also verifies mutable bounds/pose, custom/inherited
geometry accessors and hidden-state changes. Snapshot rebuilding reads each
position/bounds component once before mesh rebuilding starts. All inherited
kind notifications, reentrancy, missing/copy/weak tables, invalid entities,
frustum, nested-view, UV, resource and cleanup regressions remain in the gate.
These are headless work counts, not measured Steam Deck FPS savings.

The focused gate passes **29/29 checks and 884 Lua syntax files**. The complete
frozen gate passes **313/313 suites**, with all 2553 source files unchanged. All
313 canonical commands, individual receipts and 626 raw stream hashes are
independently verified. No production/test change follows the gate; only
documentation and evidence packaging are added. Production/test bytes are
independently rechecked before publication. The checks JSON and ZIP beside this
report preserve the native uploads, complete/focused receipts and raw streams,
paired/negative-control evidence, source manifests and failed early probe.
The early probe failure was an overly broad component-count expectation that
included mesh rebuilding; the final probe measures snapshot work before the
mesh boundary and retains the complete geometry assertions.

## Next native gate

Fully quit GMod, pull/install verified main, restart gm_flatgrass and play for
three minutes with the same Proton/windowed/graphics configuration:

`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`

Keep preferences fixed and leave GMod open through the final server reply.
Return performance_client_latest.txt and console_latest.txt. Require the exact
installed source, complete profiles, idle VR, zero new Lua errors and intact
floors/stairs/grates/underdeck after dungeon changes and reset. Native visuals
and sustained >=40 FPS remain open. Workshop publication and VPS deployment
are outside this checkpoint.
