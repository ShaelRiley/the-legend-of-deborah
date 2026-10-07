# Steam Deck static-box kind notifications — October 7, 2026

## Native evidence and authority

The complete fixed-preference capture verifies clean published main
`d02c9e4b5954f80bc7f8b549dc68328fbc5031ce`. All 44 population module hashes
independently match that commit; the client verifies 14 presentation sources.
The 179.968-second active sample contains 4,886 frames: 27.1493 FPS,
32.779 ms median, 61.674 ms p95, 95.382 ms p99 and 251.999 ms maximum.
It has 491 frames over 50 ms and 43 over 100 ms. All 36 five-second windows
remain below 40 FPS. Client/server profiles complete; settings stay fixed,
VR remains idle and recorded Lua errors stay zero. The scene has 1,456 native
walls and initially 36 living wanderers. Its seed/layout differs from the prior
capture, so this is not a controlled source-only before/after FPS comparison.

Generated geometry remains the largest measured custom client render callback:
134.466 ms/second, mean 2.4774 ms across 9,772 calls. The complete render phase
averages 17.2065 ms. Inclusive wall-clock rows overlap, include profiling cost
and omit GPU/unwrapped engine work; do not add them into a total CPU cost.
Server EntrySafety.BeforeAI and EnemyRoster.TickCloseDefense remain prominent.

Governing live GDD: exact document `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
00 → 01 → 07, LOD-IMPL-001 through -005. No authored value or game rule changes.
Main is the implementation authority; native evidence remains separate from
headless checks. Workshop publication and VPS deployment remain outside scope.

## Implementation and finite gate

Keep the existing weak static-box registry and its draw order. The declared
client BoxKind accessor pair can cache a nonzero kind; NetworkVarNotify
invalidates it before every native update, including equal-value updates.
Pending proxy values prevent reentrant rendering from freezing the old kind.
Unreceived zero values continue polling because initial client replication can
omit notification. Missing/custom/replaced accessors keep ordinary live polling.
Initialize, full-update removal and resumed transmission clear classification.
Drawable boxes retain native validity, hidden-state, bounds and pose checks on
each pass. Collision-only boxes skip native validity/kind queries once observed.
Server datatables and all collision, population, AI, graphics and Options stay
unchanged. There is no new timer, cadence, tuning value, renderer or preference.
Add the shared datatable source to installer/client/server source evidence.
The registry borrows the native entity's Lua table weakly, without retaining
bound accessors or removed entities. Cached invisible boxes use no native entity
field reads. Missing or copied Lua tables retain the ordinary guarded path.

The existing production renderer validator exercises the real shared entity,
renderer and mesh authority against pre-write native-proxy doubles. Paired exact
parent/candidate scenes keep 14,400 floor submissions over 120 warmed passes
with 120 drawable and 1,080 invisible boxes. Kind queries fall from 144,000 to
zero, validity calls from 144,000 to 14,400, and cached collision-box native field
reads remain zero. The parent fails the new work bound.
All 726 recorded mesh/wireframe rows match byte for byte, including notified
floor/stair/underdeck transitions. Test missed initial replication, receive-only
proxies, reentrancy, equal notifications, unknown accessors, datatable refresh,
server isolation, full updates/transmission, incomplete accessors, invalid native
guards, weak/copied Lua-table fallback and removal.
Retain inherited immediate geometry/pose/visibility, frustum, UV/material,
draw-state, mesh lifetime, weak-owner and Lua-refresh checks.

Source validation is complete: **29/29 focused checks, 313/313 canonical suites
and 884 Lua syntax files**, with all 2,551 pre/post source files unchanged.
The final candidate was isolated from concurrent edits in the recovered workspace.
After an interrupted poll terminated its runner, 120 passing canonical receipts
and their exact raw stream hashes were independently verified under that same
complete source manifest; all 193 remaining suites ran and passed. The earlier
cross-source attempts are preserved and supply no reused passing receipts.
The 1,800-second local per-suite budget retained every assertion, seed and workload;
an earlier 600-second campaign attempt had timed out.

All 313 canonical commands, individual receipts and 626 raw stream hashes are
verified. The checks JSON and complete ZIP beside this report preserve full and
focused logs, source manifests, receipt recovery, paired/negative-control evidence,
failed/interrupted attempts, governing live GDD identity and native uploads.
The archived native summary's server-completion flag is corrected against the
received 180-second client-stop profile; the original summary is preserved.
Only documentation and evidence packaging follow the frozen source gate; production
and test hashes are checked again before publication. Headless operation counts
are not Steam Deck timing or FPS claims. Native acceptance remains pending.

## Next native gate

Fully quit GMod, pull/install verified main and restart gm_flatgrass. Play for
three minutes with the same Proton/windowed/graphics configuration and:

`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`

Keep preferences fixed and leave GMod open through the final server reply.
Return performance_client_latest.txt and console_latest.txt. Require exact
source, complete profiles, idle VR, zero new Lua errors and intact native
floors/stairs/grates/underdeck after dungeon changes and reset. Native visual
and sustained >=40 FPS acceptance remain open.
