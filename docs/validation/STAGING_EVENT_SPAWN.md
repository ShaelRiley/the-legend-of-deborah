# Immediate staging failure repair — 2026-09-28

Parent main: `b5a829355291fcae11e963d8891dd9441719b0e7`.
The delivery response identifies the verified publication commit.

The author reports two immediate Campaign Failed resets in staging, followed by
a third maze in one session. The full native failure reason/seed was not supplied.
The new regression reproduces a matching startup failure in the parent source:

```text
[LOD] Campaign failed at Level 1. seed=31676 reason=Skeleton blockade unavailable: hostile removed
```

## Cause and correction

Campaign 31676, level seed 1939356277, passes the preceding bootstrap repair on
layout 14 with `skeleton_blockade,memory_terminal`. The accepted Skeleton cell
`1:9:0` is inside the no-spawn arrival apron. The native hostile Initialize
therefore calls Remove. Source delays deletion until the next tick, so IsValid
still succeeds; Skeleton synthesis then assigns positive HP. The build releases
staging before the required-hostile watchdog discovers the deletion.
The [Facepunch Entity reference](https://wiki.facepunch.com/gmod/ENTITY) documents
this deferred Remove/IsMarkedForDeletion boundary.

Skeleton validation now consults the canonical EntrySafety SpawnCellAllowed
query before accepting a placement. EventDirector Track rejects pending native
deletions, and Activate checks every tracked resource after all creators finish.
Partial construction follows existing cleanup and complete-build rejection.
The same seed/layout and event identities now select safe cell `16:16:1`.
No failure is suppressed, no event is dropped, and no replacement campaign is
silently generated. Legitimate combat death/rewards, protected arrival and
failure for genuinely lost required live resources retain their existing rules.
These extra construction checks add no recurring timer or network traffic.

Authority: live GDD 00 → 01 → 05/06/07, specifically LOD-B29-ENTRY,
LOD-EVENT-SKELETON-001, LOD-BIG-SKELETON-001 and staging/timer lifecycle rules.
This repairs implementation; no design/tuning amendment is needed.

## Finite verification

**35/35 targeted suites passed; all 807 Lua files passed syntax checks.**
The source snapshot was unchanged throughout:
`5ba821118addfd8fe3b22eca8c8f46c64bdf6cbce893467dc1a40406373208c6`.
Only coordination/evidence files were added afterward. This is not the full
campaign-wide registry or native Source acceptance.

The new test loads actual generation, event planning, all three Skeleton
profiles, Spawn, hostile Initialize/OnRemove, barrier initialization, bootstrap,
staging build handoff and campaign clock. Engine methods model deferred deletion
instead of immediately invalidating entities. It verifies an hour of simulated
staging without clock start or maze regeneration, same-level replacement with
delayed old callbacks, five primary/secondary creation or activation failures,
late barrier loss from another creator, full-build rollback, unchanged ecology
and successful subsequent reconstruction. Native room discovery/presentation,
geometry queries and transport remain doubled. Existing deployment, clock,
real death/reward, cleanup, B29, geometry and music regressions also pass.

The final regression was rerun with the exact two parent production modules:
it fails with the expected immediate staging error. Earlier fixture setup
failures and the original reproduction are preserved alongside the final pass.

[Gate receipt](staging_event_spawn/receipt.json),
[reproduction facts](staging_event_spawn/reproduction.json),
[tested file hashes](staging_event_spawn/tested-files.json) and
[complete evidence](staging_event_spawn/evidence.zip).
Archive SHA-256:
`cb09cb0b654751f62a72b6294adbbccdf2303e0cabc67bc6622d0271dc5db4d0`.

```bash
python3 tools/test_bootstrap_gate.py --output /tmp/lod-staging-spawn-gate --workers 4 --suite-timeout 120
```

## Native confirmation

Fully quit GMod, install verified main using `docs/DEVELOPMENT_WORKFLOW.md`, and
launch the gamemode on `gm_flatgrass`. Prepare in staging, then deploy through
the portal and play normally. If another failure occurs, retain
`console_latest.txt` and `rpg_summary_latest.txt` from
`garrysmod/data/legend_of_deborah/`; the console's Campaign failed reason and seed
identify whether another path is involved. No Workshop or VPS deployment is
part of this source checkpoint.
