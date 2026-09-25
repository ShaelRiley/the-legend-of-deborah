# Great Crate release candidate — focused safety

Resumed baseline: clean fetched main `b7bcae2aa79ca925419f028f0e152572c18df680`.
Author override: fatal-crash/game-ending-bug sweep → LOCAL playtest and acceptance
→ Steam Workshop publication (3791535712) → matching verified VPS deployment.
Deferred September 28–October 4, 2026: Low-End PC Optimization → Big Loot →
Event System → comprehensive systems audit. Preserve P1–P4; active-scan profiling
and dense successive-seed frame-time/texture-residency certification remain pending
in that deferred optimization phase.

## Great Crate reconciliation

`GREAT_CRATE_C3.md` remains the full 35-exit reconciliation and failure history.
Implementation closure does not mean full native acceptance. No new Crate defect
is demonstrated by the supplied evidence. The reported TRANS-PIEDMONT BULK sample,
approved restored hull/concrete and prior static checks are inherited evidence.
P1–P4, Bribe removal, original assets, stock blast-door gates, deterministic
placement and renderer `source-front-face-20260924` are unchanged here.
All six Crate suites remain registered in the canonical integration gate.

| Required boundary | Release status |
| --- | --- |
| Original model, NP repair, neutral hull, complete 256-brand compositions | Implemented; retained asset/fit/render tests. Broader native hull/tints, offsets/mips/legibility pending. |
| Coherent concrete, selective grates, collision/topology, cover/rails | Implemented; approved floor sample inherited. Native traversal/cover/rails and other lighting samples pending. |
| Stock gates, deterministic/lazy/shared render resources | Implemented; bounds/lifecycle tests retained. Gate appearance and reset/rejoin pending native evidence. |
| Dense frame times and successive-seed texture residency | **Pending; deferred to next week's Low-End PC Optimization.** Headless CPU results do not certify either. |
| GDD/roadmap/publication | Current release override applied and read back in live 00/01/05/07/90; exact publication SHA supplied by verified remote receipt. |
| Original no-deployment exit | Superseded by authorization for Workshop publication after local acceptance, then matching VPS deployment/restart after package/revision parity verification. |

## Inherited checkpoint — focused defect repairs and finite proof

The following repairs and 221-suite receipt belong to the prior checkpoint, based
on `fee9f872f54751ae788ffa351c122ea7f1917488`. They are preserved evidence, not
blanket native certification or the current invocation result.

1. `sv_campaign_bootstrap_reliability.lua`: an exception from `NewCampaign()`
   escaped before clearing `InProgress`; because `NewCampaign` assigns a seed
   before physical generation, a failed partial state also looked like a live
   campaign and suppressed retry. The new production regression first failed with
   `bootstrap exception escaped recovery boundary`. Recovery now catches/reports
   exceptions, always releases its latch, records the exact failed state and permits
   explicit retry of that incomplete state. It preserves the one automatic attempt
   limit and never rebuilds a ready or externally replaced campaign. Exception,
   normal-false-return, partial seed, retry and live-state preservation tests pass.
   No native exception was observed in this session; this is a reproduced harness
   failure through the real production boundary.
2. `run_public_server.sh`: old launcher deleted the mounted addon before its
   replacement copied and rewrote operator config each start. It now stages a full
   copy before swapping, retains prior bytes outside mounted addons, restores them
   if the swap fails, preserves existing config/data/token and writes exact build
   receipts. Fault-injected real-shell copy tests prove old bytes survive failure;
   success/default-install tests prove config/data preservation and correct receipt.
3. `deploy_verified.sh`: pinned fast-forward deployment refuses dirty/diverged
   source, checks the existing service checkout, stops before backing up data/cfg/
   SQLite and installed addon, restarts the existing service, verifies local A2S
   identity, exact installed SHA, short service stability and startup error
   signatures. Failure restores previous source and requests service restart;
   database/player records are never automatically rolled back. Backup is private.
   Tests use real git/filesystem and a simulated systemd/query boundary; they prove
   success, startup-error rollback and dirty-work refusal. Actual A2S challenge and
   wrong-identity handling have separate parser tests. This is not VPS evidence.

Focused authority inspection covered native resource cleanup/error unwinding,
campaign bootstrap/restart and epoch guards, deferred staging state/identity
checks, and SQLite transaction/participant rollback. Existing canonical suites
exercise native damage/touch/death handoffs, mesh/model cleanup, full-update
geometry, death/Tetris/revival/Soldier isolation, disconnect/rejoin, inventory
transition, wallet/DFT/sell-fuse failures, controls, gate/key progression, timers,
finale and Damsel/Level-21 progression. These reuse established authorities;
this is not the deferred top-to-bottom systems audit.

Fresh validation: **221 suites passed, zero failures** (fresh invocation).
Log: `RELEASE_SAFETY_INTEGRATION.log`; SHA-256
`9400716a65a1d043412731ac5846d1743c7efed5fe5884f547baaebcaf6a890b`. The two added matrix suites cover bootstrap
recovery and deployment preservation; the latter also runs the pinned-deployment
regression. The focused automated safety gate passes; no known unresolved demonstrated fatal/game-ending defect remains in the exercised scope. Native failures remain possible and require the smoke test.
No native Source stability, render, multiplayer or campaign acceptance
is inferred from these results. P4's earlier 219-pass run remains inherited evidence.

## Release gates and deployment truth

Direct SSH to `ubuntu@40.160.86.240` and A2S to `40.160.86.240:27015` both failed
here with **Network is unreachable**, before authentication or server inspection.
No VPS file, player record, config, service or Workshop item was changed. The
installed VPS revision, current service health, logs and public listing are unknown.
The infrastructure document's historical checks are not fresh evidence.

The historical deployment command is not the next action. First complete the focused
sweep and publish a verified GitHub candidate; then obtain LOCAL acceptance below.
After any fixes, validate and publish the revised candidate and retest affected paths.

Only after local acceptance: build/publish that exact clean candidate with the existing
`tools/workshop/build_workshop.sh` and `tools/workshop/publish_workshop.sh` to item
**3791535712**. Record the source SHA, package digest, publisher success receipt and
verify downloaded package content/revision parity. A successful upload alone does
not prove the client received the intended package.

Only after Workshop parity: run that revision's `tools/server/deploy_verified.sh
FULL_SHA` on the existing VPS. Retain its private backup/rollback receipt; preserve
configuration and persistent data. Verify installed SHA, service stability, startup
errors, local A2S response, external Internet listing and a native client join.
Local A2S proves neither master-list visibility nor external connectivity. Prior
network failures are not current server-health evidence.

## One local playtest procedure — acceptance pending

Fully quit GMod. Require a clean existing local checkout; preserve any local work
before updating. Fetch and fast-forward main, verify
`git rev-parse HEAD` equals the published candidate, then run `bash tools/install_dev.sh`.
Retain Steam launch options `-condebug -conclearlog`. Start **Legend of Deborah**
on **gm_flatgrass locally** (listen-server co-op when a second tester is available).
The installer prints exact evidence paths under `garrysmod/data/legend_of_deborah/`.

1. Claim the Hermit gift and enter the maze. Inspect several unbranded/tinted hulls
   (`lod_crate_preview` samples the hull palette), complete branding close up and at
   distance/oblique angles for offset, flicker, mips and legibility; inspect stock
   blast-door gates with no concrete leakage. Walk floors, stairs and a grate apron;
   check rails/cover and that locked progression cannot be bypassed. Run:
   `lod_crate_status; lod_container_brand_status; lod_progression_render_status; lod_stability_client_status`
2. Fight/use Magic, collect/equip/use loot, unlock a gate with its key and complete
   a rescue into staging. Die/respawn; in co-op also exercise elimination/revival
   and disconnect/rejoin while the host stays running. Check controls, geometry,
   inventory under the authored lifecycle and persistent wallet; no duplicate grants.
   Exercise a natural failed campaign's **E restart**, then enter the fresh maze.
   Solo session restart is not evidence of same-campaign multiplayer rejoin.
3. Finish with `lod_rpg_test_finish release_local; lod_rpg_test_upload_status`.
   Return **console_latest.txt + rpg_summary_latest.txt**, screenshots showing hulls,
   branding/gate and grate/rails, and a short pass/fail/unexercised note for the steps.
   After a crash, preserve evidence before launching again; use the existing crash
   exporter if the normal files were not finalized.

Require renderer `source-front-face-20260924`, complete visible artwork, stock gates,
safe traversal and no crash, Lua exception, trapped controls or progression loss.
Record unexercised full-campaign finale/Level-21 and multiplayer boundaries explicitly;
do not infer them from a short solo run. Review local evidence and resolve demonstrated
blockers before marking the candidate accepted or publishing Workshop. Dense
successive-seed frame-time/texture-residency certification stays deferred.

## Inherited tested production/tool receipts

- `gamemodes/legend_of_deborah/gamemode/lod/sv_campaign_bootstrap_reliability.lua`: `6668ca7d24e85a79fa67e1299fa2a37748e71a35`.
- `tools/server/run_public_server.sh`: `6b79acb430f93314f425c7cfd158892cd6d2efdf`.
- `tools/server/deploy_verified.sh`: `5b5c5cf2994a7c006f13a3e9a252c121b52c7ead`.
- `tools/server/query_server.py`: `153206a8342f2e93e25547ec5af86801b22a3254`.
- `tools/test_bootstrap_failure.lua`: `f4390a182b6f60eb91a635b11f7f6f416d7d9b9d`.
- `tools/test_server_launcher.py`: `646b813dccefd2b05d7ebe78b6480c1ee8d60c10`.
- `tools/test_server_deploy.py`: `e482b4dff2c2a5f0c28493984bf7f3d9738fdbc1`.
- `tools/test_checkpoint_g_integration.py`: `403d4f04d8aaa7ee2a69ceba9ad376fc7e989953`.

No production/test/tool changes followed completion of the canonical run. Only
evidence and coordination text were finalized. Publication compares every changed
blob and the complete local tree before a non-forced main update and fetched readback.

## September 25 focused sweep — normal startup recovery

Remote main and the previous checkpoint workspace were both verified clean at
`b7bcae2aa79ca925419f028f0e152572c18df680`; no intervening work was overwritten.
Live GDD 00 → 01 → relevant 05/06/07 rules were read; corrected release sequencing
was read back in 00/01/05/07/90. No additional GDD mutation was necessary. Repository
roadmap/handoff and this local-first release procedure now agree with that order.

A new regression invokes the actual RunManager `InitPostEntity` hook with an
injected failure after campaign-seed assignment. Before repair it failed with
`initial startup exception escaped recovery boundary`. The initial hook called
NewCampaign directly, bypassing the prior checkpoint's protected recovery helper;
the seeded partial state could then suppress player/watchdog recovery. Startup now
uses that same helper, permits its ordinary empty-dedicated-server initial attempt,
records exception/false-return failures and leaves one automatic player recovery
available. A late initial callback preserves an already live campaign. No new
retry loop, gameplay tuning, asset change or manual rule was introduced.

The expanded bootstrap regression passes for exception and false-return startup,
partial-state recovery, automatic retry bounds and live-state preservation.
Focused inspection also checked restart epoch/error handling, deferred staging
identity/state/graph guards, native DamageInfo handoff and resource cleanup,
transaction rollback and gate/key placement. Existing canonical validators cover
these plus death/revival/Soldier isolation, disconnect/rejoin, control/minigame
release, gate/boss/key and Damsel/finale/cash progression. This remains a focused
safety sweep, not the deferred comprehensive audit.

Fresh canonical result: **221 suites passed, zero failures**.
Command: `python3 -u tools/test_checkpoint_g_integration.py`.
Log: `RELEASE_SAFETY_SWEEP_INTEGRATION.log`; SHA-256:
`25470ec12bb8a55f7081b8ae56fe466a112e853badf7b175b46eceabdd1c9bbb`.
No production or test changes followed that invocation. The demonstrated startup
failure is repaired; no known unresolved demonstrated fatal/game-ending defect
remains in the exercised scope. This is automated evidence, not native acceptance.
Local native acceptance: **pending**. No GMod client or authenticated publisher
was found in this execution workspace. Shael's local evidence is required for the
next gate. No Workshop publication, VPS deployment/restart or fresh server-health
claim was made. Previous unreachable-network evidence is retained above.
