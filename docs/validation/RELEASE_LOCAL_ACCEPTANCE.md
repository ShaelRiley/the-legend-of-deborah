# Local release playtest — September 24, 2026 (America/Chicago)

Tested revision: `0ce9a499429b1309b23d1229c8282b872b3c6b7d`.
Shael's report: “Game looks good. I just barely defeated Gordon. No crashes or
noticeable bugs.” Local solo gameplay and the observed appearance are accepted
for this release checkpoint. This is scoped human acceptance, not certification
of every native requirement or all seeds/platforms/multiplayer paths.

## Evidence read from the supplied files

| Source | Bytes | SHA-256 |
| --- | ---: | --- |
| console_latest(2).txt | 62715 | 75fb3c311bca21501bf20c33c6889b09e1528dcca93d5b10897f458b5d07b9fd |
| rpg_summary_latest(2).txt | 3494 | e6185c602ae1607b5f4a726c09f221fe09eb23515ec24997519ffacffa0e2ce9 |

Both client and server installation receipts report the exact tested revision as
**clean**, with loaded component receipt `missing=none`. The console identifies
singleplayer, `gm_flatgrass`, `legend_of_deborah`, x64 engine 2026.09.17. The summary
is stamped 2026-09-25T02:28:36Z and contains 5,761 events.

Observed evidence:
- Startup recovery produced a ready first dungeon, followed by Hermit starter
  acquisition and deployment.
- Neil's Black Keycard drop and Warden defeat each occurred once in the summary.
  The console records two player deaths followed by continued play.
- Level 1 was cleared, the player received **100 $DEB**, Level 2 built successfully,
  and the recurring Hermit staging welcome appeared.
- Both generated levels passed the native geometry and vertical-audit reports.
  Server Lua-error counters remained zero. Session ended through ordinary server
  shutdown, consistent with the user's report of no crash.
- The session used the developer dense-encounter configuration (2.0x budgets);
  this is evidence for the tested configuration, not public default load certification.

## Demonstrated reporting defect and repair

The console also records two client Lua exceptions, one after each dungeon build:
`cl_crate_preview.lua:105: attempt to index local 'mat' (a nil value)` from the
automatic `LOD_CrateSummary` Think callback. This contradicts a zero-Lua-error
claim, but not the user's report of no noticeable gameplay problem or crash.

The summary assumed `Material(override)` always returned a handle. Model creation
and section-material reconciliation occur separately; the exact engine lookup
cause was not established by this log. The diagnostic now tolerates a nil handle
and reports `shader=missing`, `materialError=true`, `sampler=missing` instead of
throwing or inventing valid artwork. It does not change the model, materials,
rendering, geometry, gameplay, RNG, economy or lifecycle.

The existing hull runtime suite now executes the real automatic and manual summary
callbacks. It first reproduced the nil-handle exception, then passed nil/error
material, missing sampler, valid later material, once-per-world cadence and world
replacement cases after the repair. Fresh canonical integration: **221 suites passed, zero failures**.
Command: `python3 -u tools/test_checkpoint_g_integration.py`.
Log: `RELEASE_LOCAL_DIAGNOSTIC_INTEGRATION.log`; SHA-256:
`25470ec12bb8a55f7081b8ae56fe466a112e853badf7b175b46eceabdd1c9bbb`.
No production or test edits followed this run.

Other console warnings (stock fonts/material flags, weapon samplers, grenade-model
sequence and missing kill icon) remain recorded in the supplied evidence; none
establishes a fatal or game-ending failure in this successful run. No unrelated
visual or gameplay tuning is included in this reporting repair.

## Coverage limits and release continuation

No fresh explicit branding renderer/offset/mip readout or screenshot was supplied.
The user's overall appearance approval applies to the observed sample. Both seeds
report **grates=0**, so grate/rail traversal is unexercised. Campaign-failure E
restart, same-campaign reconnect, co-op revival/Soldier isolation and Level-20/21
finale/cash progression are not established by these files. Retain those native
limits; the prior full automated gate is supporting evidence, not a substitute.
Dense successive-seed frame-time and texture-residency certification remain in
September 28–October 4 optimization, followed by Big Loot → Events → comprehensive
audit. Preserve P1–P4, Bribe removal and approved Crate assets/renderer.

Next release step after publishing this validated diagnostic repair to GitHub:
Steam Workshop item **3791535712**, using the exact clean revision. Local acceptance
of the tested gameplay/appearance is retained because only read-only reporting
changed. Native confirmation of the diagnostic itself remains unobserved; a fresh
`lod_crate_status` read can confirm it during the Workshop client verification.

The existing Workshop builder was attempted here and stopped before creating a
package: `Could not find Garry's Mod gmad`. This workspace also has no authenticated
Steam publisher. Build/upload therefore requires the owning account's Steam
machine. Record the exact source SHA, GMA digest and successful publisher output;
verify downloaded package/source parity before deploying the same revision to the
VPS. Workshop publication and VPS deployment/restart have **not occurred**.
