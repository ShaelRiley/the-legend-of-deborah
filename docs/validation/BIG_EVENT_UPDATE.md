# Big Event System implementation and validation

Baseline main: `1685774415ea8bbd82abf931999a29ae7ba25f10`.
The author-promoted [event brief](../briefs/EVENT_SYSTEM_UPDATE.md) governs this
checkpoint. The production baseline has **8** meaningful active archetypes;
**20 additions yield 28 (3.5×)**. Bribe remains retired. See the
[catalog and system record](../EVENT_SYSTEM_EXPANSION.md) for every interaction,
cost, ownership rule, chosen tuning value and native acceptance procedure.

## Implementation

Ten services and ten incidents add resource trades, prisoners, hazards, timed
trials, shared mechanisms and personal rewards through the existing event entity,
CryptoStore, Equipment, RPG/status and navigation authorities. All use stock
assets. The existing non-exploding d4 still selects exactly 1–4 distinct events;
the fourth slot is rare, with no count truncation or substitute duplicates.

Selection weights families, identities, complementary roles and actual encounter
motifs. Successful full builds alone commit bounded campaign exposure history.
Same-level regeneration, failed builds, disabled population and previews cannot
advance it. Placement preferences use actual graph structure while preserving
the existing ordered progression, protected-cell, combined-plan and return proofs.

Reviewed service offers bind their owner, body and exact resources. Canonical
transactions and immutable account/dungeon receipts prevent replay across a
replacement Hero, reconnect or regeneration. Shared lots have a single buyer.
Incidents use the shared director tick; clues are recipient-specific, hazards
use canonical saves/statuses, and teardown invalidates every session and part.

The manual now contains 170 chapters in 32 client chunks. Its generated source
SHA256 is `7c9c4020bc772766676ddc7c520dff85e00af65ec5769f15c0aea5f07d80e744`.

## Complete finite gate

**274/274 suites pass; 784 Lua syntax files.** The inherited 268-suite matrix is
retained and six suites cover service settlement, incident/body lifetimes,
campaign determinism, selection coverage, full production generation and client
presentation. SQLite failures, stale native callbacks, exact-owner compensation,
late joins, creation failures and cleanup are exercised alongside the existing
loot, combat, progression, Bestiary, SPOT, Crate and lifecycle regressions.

```sh
python3 tools/test_checkpoint_g_integration.py --workers 4 --output ../big-event-gate-01
```

Frozen source digest before and after:
`aa5a465193d040eeb92f560138cb20524e9053b2edd17bed56ed95c9ae6dac8f`.
No source changed during the gate. Every stdout/stderr checksum in all 274 suite
records was verified, and the original source manifest matched again after the
gate. Subsequent closeout changes are documentation and evidence only.

The [complete receipt](big_event/matrix_receipt.json) includes each command,
exit code, duration and output checksum. All suite logs, the source manifest and
retained focused evidence are in
[automated_evidence.tar.gz](big_event/automated_evidence.tar.gz), SHA256
`b7ceba88abc2ff8363f1d5bc59eaed5c30a487b731da23ff721cb23eb07c742a`.

The production fixture loads all 28 actual registrations and the actual
RunManager/generator, encounter reservations and native event initialization.
All identities pass placement, Create, two-Hero and late-join snapshots, and
cleanup. All 20 additions pass native creation fault/retry boundaries, including
multipart teardown. Ten mixed campaign builds have zero bounded rejections and
cover every contract, d4 count and multiple physical floors. Peak parts per event
is five. Disabled population preserves maze and encounter RNG output. These
checks use native API doubles; they do not establish Source physics acceptance.

## Campaign selection evidence

The reproducible [sample](BIG_EVENT_ECOLOGY_SAMPLE.json) pairs 96 campaigns ×
20 dungeons with history enabled and disabled. Both use the actual 28 definitions
and actual encounter motif scheduler. Each side selects 4,775 events.

| Measure | Campaign history | History disabled |
| --- | ---: | ---: |
| Globally observed identities | 28 / 28 | 28 / 28 |
| Mean unique identities per campaign | 24.6875 | 20.8021 |
| Minimum unique identities per campaign | 21 | 14 |
| Immediate repeated identities | 17 | 701 |
| Maximum identity streak | 2 | 10 |
| Maximum family streak | 4 | 10 |
| Mean families per campaign | 12.9271 / 13 | 12.6146 / 13 |
| Rare slots | 478 | 478 |

Immediate repeats fall 97.5749%. The exact d4 count sequence is unchanged;
counts 1/2/3/4 occur 491/481/470/478 times. This is a selection sample, separate
from the real generation fixture. It does not measure native frame time,
placement acceptance rate across campaigns or human balance.

## Repaired findings and preserved evidence

- Affine seed derivation correlated first-draw family/identity quantiles and
  excluded valid Equipment Quiz partners. Separate purpose/slot streams with
  bounded warmups restore all historical partners. The failed focused coverage
  log and passing rerun are retained in the archive; permanent pair visibility
  checks now prevent recurrence.
- A body replacement during a native visibility trace could reach settlement
  after the original owner check. Rechecking exact ownership after the native
  call prevents charging or rewarding a replacement life.
- Scalar equality alone could restore old lives into a replacement body during
  rollback. Compensation now requires the original exact owner. Both ownership
  defects have focused regression coverage.
- Production integration caught an incident transaction invocation mismatch;
  the corrected path passes real SQLite settlement and the full catalog gate.

## Live GDD synchronization blocker

Live document: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.
Navigation followed 00 → 01 → targeted 05/06/07/90. A file-backed trusted read
preceded a revision-guarded additive write. Google returned HTTP 400
`FAILED_PRECONDITION`; fresh readback confirmed unchanged content and revision.
No live amendment succeeded. This remains an incomplete delivery requirement.

Exact six-tab changes are preserved in
[gdd_amendments.json](big_event/gdd_amendments.json), including the 28-entry catalog,
authored rules and tuning. Apply surgical additions after editing is restored,
using a fresh revision and readback; preserve earlier pending Big Loot amendments.
No document replacement, content pruning or access-control workaround was used.

## Native acceptance and deployment

Native GMod physics, controls, rendering, networking and co-op acceptance remain
open. Update the local install to the verified published commit, restart GMod,
then use the compact `gm_flatgrass` procedure in the system record. Verify readable
offers and clues, shared versus personal outcomes, reconnect after a claim and
same-dungeon regeneration without renewed entitlements or stale parts. Preserve
all earlier native acceptance constraints and pending gates.

Capture `console_latest.txt` + `rpg_summary_latest.txt` with short visual/control
observations; request the detailed session only for disputed event ordering.
No Workshop publication or VPS deployment is part of this update.
