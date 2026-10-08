# Steam Deck — shared enemy AI work

The latest native capture averages **21.8151 active FPS**, below the sustained
40 FPS target. This checkpoint removes repeated field and cell work from shared
server AI without changing attack, status, admission or movement rules. Its
hardware benefit requires the next native capture.

The baseline is published main `0388d032b48a3b310d0429b44ca44791842aea52`.
The live GDD's 00 → 01 → 07 route governs this implementation-only work;
revision `AHj4eMRd4acJKKEDgqukO9zGvoMQvxlbUMdF6nZCAXYFhQm-CNvzGIub5PLIO_oXk6fEWbrk_V-_2bJc4m1wqQvkXjzdDNhY5wQfHSd7Pg`
is unchanged. No tuning or design edit is required.

The three-minute October 8 UTC / October 7 local capture labels clean
`0388d03`; all 15 tracked client and 45 tracked population hashes match.
It records 2,807 active frames over 128.67259 seconds, median 37.870 ms,
p95 77.751 ms and p99 129.473 ms. The native scene has 1,614 walls,
unchanged preferences, complete client/server profiles, fully idle VR and
zero Lua errors. Generated workloads differ between captures, so the FPS
difference does not isolate the preceding source change.

Close-defense costs 44.7563 CPU ms per recorded second over 273,398 calls;
sanctuary BeforeAI costs 41.5602 over 536,164 calls. These inclusive CPU
measurements overlap and are not GPU measurements or an additive frame budget.

Close-defense borrows repeated plain entity fields within adjacent comparisons.
Status, ownership and preparation callbacks retain fresh reads afterward.
BeforeAI queries exact cell depth only when admission leaves that depth relevant;
positions used after Claim remain live. There is no persistent status cache,
new timer, AI cadence, cooldown, quota, population or graphics change.

The production-backed probe loads the exact parent and revised authorities
into the same existing harness. Only native entity lookup, admission results
and movement boundaries are doubled. The 20,608 recorded return/state/status
and callback rows match exactly (SHA-256
`2c2b5a292c7de8bee5f481bbef27afd2942ee33edf56439ea5884921e983e36b`).
Callback mutations, expired status cleanup, primary commitments, Claim-time
movement and frozen/dead lifecycle rejection are retained.

| Probe work | Published parent | Candidate |
| --- | ---: | ---: |
| Entity Lua-field reads across 3,600 close-defense calls | 161,400 | 134,400 |
| Status queries in those calls | 12,000 | 12,000 |
| Exact-cell queries across 5,001 admission calls | 5,001 | 2,001 |
| Position queries in those calls | 15,003 | 12,003 |

The parent fails the new work bound. These operation counts establish removed
work, not an FPS gain. The runtime fingerprint manifest now includes
`sv_enemy_melee.lua`: 50 installer hashes and 46 runtime population hashes.
Installer repetition, transport, absent/mixed sources and session-cached hashing
are checked. Earlier fixture failures and interrupted pre-final matrices remain
in the archive and contribute no accepted results.

The frozen final source passes **21/21 focused checks, 314/314 canonical suites and 885 Lua parses**. All 2,560 source files remain unchanged during both gates. Every canonical and focused command/receipt and all 628 matrix stream hashes plus 21 focused log hashes are independently checked. Only documentation/evidence packaging follows; all nine authority/test file hashes are rechecked before publication. The adjacent checks JSON and ZIP preserve raw native uploads, exact parent/candidate sources, paired traces/work counts, the expected failing parent work gate, prior failed/interrupted attempts, final complete/focused commands, receipts, raw streams and source manifests.


Fully quit GMod, update/install verified main, restart gm_flatgrass and use:

```bash
cd ~/Downloads/the-legend-of-deborah && git pull --ff-only origin main && bash tools/install_dev.sh
```

```text
lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile
```

Leave the game open through the final server reply. Return
performance_client_latest.txt and console_latest.txt. The native gate requires
verified final source including both changed AI authorities, complete profiles,
idle VR, no new Lua errors, preserved AI/status/admission and world visuals,
and sustained >=40 FPS. Native acceptance remains open. No Workshop or VPS
operation is included.
