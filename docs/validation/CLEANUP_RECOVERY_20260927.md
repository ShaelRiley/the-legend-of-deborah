# September 27 stalled cleanup recovery

## Recovered source and authority

Actual remote parent: `aa102cc31951d34937ebaa106314cfcfdb855a2f`.
Exact parent tree: `4e7654b2826517afe90a89405b1b852bde614caf`.
Inspection run `36344707397`, artifact `10940425343`, preserved that exact source.
The previous thread's reported repairs and 264-suite result had no recoverable
publication or patch. This checkpoint reconstructs the repairs from production
code and fresh failing tests; it does not recover the old working tree.

Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.
Navigation: 00 -> 01; targeted 04 Spring Heel/Cloud Step preservation, 05 staging,
and 06 lives. No game law, tuning, costs, jump multipliers or GDD content changed.

## Repairs

- Static/owned loot no longer inherits enemy-drop expiry. Ordinary drops still
  expire; static loot remains owner-bound and is retired on level change.
- Random campaigns no longer carry a custom-seed rejection reason. Custom maze
  and developer roster seeds retain correct unranked classification.
- Repeat staging explicitly suppresses starter dialogue. Failed or silent
  placement does not consume the introduction; successful announcement does.
- Pre-build party scaling excludes voluntary spectators, preserves dead Heroes
  with remaining lives and new admissions, and retains the four-slot cap/minimum.
  Unused historical admission-count variables were removed.
- Spring Heel coalesces pending ground-jump input. Deferred impulses/telemetry
  belong to the exact campaign/dungeon, progression owner and spawn serial.
  Death cancels pending work; an old callback cannot erase a replacement claim.
  Existing sqrt(2) impulse / 2x apex and airborne feat combinations are unchanged.
- Hero/Soldier death spectator callbacks share a local lifecycle guard, preventing
  an earlier death from modifying a replacement body or dungeon.
- Successful warp endpoint validation no longer returns an error alongside true.
- Three unbooted Bribe modules moved byte-for-byte outside the shipping gamemode
  into `tools/fixtures/retired_bribe/`. Historical tests use the explicit archive.
  Compatibility readers and shared barrier code remain. Current Bribe exclusion
  and quiz catalog tests are strengthened, not weakened.

## Finite automated gate

New production-executing suites: `test_cleanup_contracts.lua` (20 assertions) and
`test_cleanup_lifecycle.lua` (58 assertions), in addition to inherited SPOT-15
checks in each harness. Existing Hermit, warp and quiz suites gained assertions.
All prior 262 suites remain: expanded matrix 264, with 767 Lua syntax files.

```sh
python3 tools/test_checkpoint_g_integration.py --workers 4 --suite-timeout 1200 --output ../cleanup-evidence
```

At source preparation, focused cleanup and Hermit tests pass. Corrected baseline
runs reproduce production failures. Full-matrix attempt 01 was stopped after diff
review caught an overly broad edit in the developer telemetry reset. That edit
was corrected and a native-testkit command regression added before rerunning. The first lifecycle fixture left its Hero in
staging; the first warp invocation omitted the SQLite wrapper; the first skeleton
run was interrupted by the local tool timeout. These attempts are retained, not
counted as production regressions or passes. The earlier thread's 264/767 claim
is not evidence for this reconstructed tree.

Final full-matrix results, unchanged-source digest and independent publication
identity belong to the delivery receipt, not an unrun claim in this source file.

## Native acceptance remains open

Exact-build `gm_flatgrass`: ordinary/chained jumps, death/respawn and Soldier
return, repeat-hut introduction/gift collection, and a cooperative party with a
voluntary spectator. Static loot must survive beyond ordinary enemy-drop expiry.
Preserve SPOT01-17, Soldier/Reckless, stairs, stomp/arrow input, B28/B29 and Crate.
Collect `console_latest.txt` and `rpg_summary_latest.txt`; detailed session only
for disputed timing. Headless checks do not prove native physics/render/network.

No Workshop/VPS action, deferred-roadmap implementation or native acceptance.
Release sequence: local acceptance -> Workshop package parity -> matching VPS.
