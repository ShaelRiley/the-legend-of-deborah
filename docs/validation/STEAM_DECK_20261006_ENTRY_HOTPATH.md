# Entrance-safety hot-path checkpoint

Parent: verified clean main `a447d9f34ea6c40ef9c23cd15c1e129c681221f7`.
Live GDD: 00 -> 01 -> 07, LOD-IMPL-001–004; revision
`AHj4eMR_DDz2hGEg3eQDccBA3oDEdshBd8t5KzGw0L6BgYKYHYAAVfr7yRU5xdXTnheYySvXsqEVbNdxoArTDwvcvCbGuMNO723fBv8Vug`.

## Native observation

The supplied exact-source capture has 1,734 active frames over 104.6867 seconds,
16.5637 active FPS, median 58.654 ms, p95 103.064 ms. All active frames exceed
25 ms. It verifies all eight rendering authorities, has no configuration changes,
zero reported Lua errors in either realm and complete server attribution. All
42 installed/mounted population authorities also match. There are 1,648 wall
models and 54 initial roamers; settings remain 1280x800, native walls and the
existing Reduced Effects option.
The preceding capture had 166.2163 active seconds and a different generated maze;
the FPS difference alone does not establish a controlled regression.

Server EntrySafety.BeforeAI consumed 8,116.97 inclusive CPU milliseconds in
515,082 calls; EnemyRoster.TickCloseDefense consumed 7,874.36 milliseconds in
258,963 calls. The latter also uses the canonical sanctuary source/membership
queries through CanInitiateAttack. Nested timings overlap and include diagnostic
overhead. Static geometry remains the largest measured game render row, with
25,633.45 milliseconds in 5,516 calls. GPU and unwrapped engine work are unmeasured.

## Finite gate fixed before implementation

Optimize only EntrySafety's live spatial/source queries. Read position scalars
at most once inside each query, avoid constructing an owner-cycle table for direct
Heroes/hostiles, and exit Claim after its existing service/context checks when
there are no active opening records. Allocate a nearby-record array only when
the unchanged live distance/commitment checks find a nearby record.
No cross-call membership cache, scheduling
change, new configuration, tuning, admission bypass or return-state reuse.

Compare parent and candidate production methods against the same native-boundary
doubles. Require identical exact-cell and padded sanctuary membership across
horizontal/vertical boundary sweeps, missing cells, different floors and staging;
same source resolution for direct actors, owned proxies, cycles, invalid actors
and the existing four-hop limit; and immediate response to position, config,
graph/state, center and actor changes. Count native position-component reads and
measure allocation growth with GC stopped on a fixed direct-actor workload.
The unchanged parent must fail the new reduced-work gate as a negative control.

Retain existing generated B29 safety/dispatch/combat, co-op quota/admission,
freeze/reset/reconnect, close-defense identities/damage/telegraphs/reentry,
navigation and renderer/appearance regressions. Run the complete frozen canonical
matrix and Lua syntax gate before non-force main publication, preserving raw
streams, commands and tested source hashes. Native FPS remains unaccepted.

## Next native gate

Fully quit/update/install the verified source and use the established gm_flatgrass
configuration. Deploy before starting the same three-minute capture:
`lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180 profile`.
Keep the game open through the final server reply. Return
performance_client_latest.txt + console_latest.txt. Require exact mounted source,
zero new Lua errors, complete server attribution, intact native surfaces and safe
opening/close attacks. Sustained >=40 FPS is still the performance target.
No Workshop or VPS operation belongs to this checkpoint.

## Implemented candidate and paired work

ExactCell borrows three current position scalars once. ProtectedPosition lazily
borrows each required coordinate once, preserving X/Y/Z short-circuiting for
distant actors. Source allocates its existing cycle detector only when following
an actual owner chain. Claim keeps live service/context checks and every needed
distance query, but allocates nearby-record storage only for qualifying records.
No result survives the call. The source/profiler binding, all constants, entity
lifetimes, admission decisions, RNG, native rendering and combat remain unchanged.

The paired parent/candidate production gate passes 5,145 padded boundary cases,
immediate position/config/graph/center/owner changes and the original bounded
source resolution. In the fixed 10,000 distant sanctuary queries, native
position-component reads fall from 20,000 to 10,000. In 50,000 direct source
queries, GC-stopped allocation growth falls from 3,906.250 KiB to 0.000 KiB; in
10,000 far admission queries, it falls from 546.875 KiB to 0.000 KiB while all
10,000 live distance queries are retained. The parent fails the new work/allocation
conditions. These native-boundary doubles and Lua 5.4 allocation measurements
assign no Steam Deck hardware time or FPS improvement.

Initial additional-test fixture mistakes concerning graph.Start identity and
the inherited four-hop/invalid-owner return contract are retained in failed
attempt logs. The final paired gate uses the unchanged parent implementation;
no source-resolution rule was altered to satisfy a fixture.

## Completed source gate

All **310/310 canonical integration suites** and **880/880 Lua syntax files**
pass. Independent verification matches all 310 commands and individual receipts,
620 raw stdout/stderr hashes and all 2,516 frozen source hashes. The start/end
source digest is identical:
`5188b608b6bea41f849b385b95d20cc4d64652fda7922b89e9126c08ed54b5be`.
Production and validator bytes remain identical after this verification; only
coordination/evidence records are finalized afterward.

During the gate, a partial PNG prefix was observed after the inherited in-place
asset reproduction check reported success. It is exactly the first 458,865 bytes
of the 715,336-byte parent asset. The exact parent bytes were restored; an isolated
rebuild independently reproduces the original SHA256 and decodes at 1024x1024.
The final source matches the initial frozen hashes. The observation/restoration
receipt is retained; its underlying cause is unproven. No texture change is
published, and this transient observation is not hidden by the aggregate gate.

[The complete archive](STEAM_DECK_20261006_ENTRY_HOTPATH_complete.zip) preserves
all individual suite streams/receipts, source manifest, paired comparison and
failed fixture attempts, original uploads, exact parent source, changed source
bytes and native/asset verification receipts. Archive SHA256:
`7acd41e9d2afa768c1abf2491efd9a0dd796dd4d2b96b3d01cf68c355728e8a5`.
[The verification receipt](STEAM_DECK_20261006_ENTRY_HOTPATH_matrix.json)
contains the tested production hashes. Sustained native >=40 FPS remains open.
