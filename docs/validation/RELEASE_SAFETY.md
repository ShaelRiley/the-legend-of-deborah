# Great Crate release candidate — focused safety

Baseline: clean fetched main `fee9f872f54751ae788ffa351c122ea7f1917488`.
Author override: Great Crate closure → focused fatal-crash/game-ending-bug
elimination → exact verified VPS deployment and native smoke test.
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
All six Crate suites are included in this fresh canonical run.

| Required boundary | Release status |
| --- | --- |
| Original model, NP repair, neutral hull, complete 256-brand compositions | Implemented; retained asset/fit/render tests. Broader native hull/tints, offsets/mips/legibility pending. |
| Coherent concrete, selective grates, collision/topology, cover/rails | Implemented; approved floor sample inherited. Native traversal/cover/rails and other lighting samples pending. |
| Stock gates, deterministic/lazy/shared render resources | Implemented; bounds/lifecycle tests retained. Gate appearance and reset/rejoin pending native evidence. |
| Dense frame times and successive-seed texture residency | **Pending; deferred to next week's Low-End PC Optimization.** Headless CPU results do not certify either. |
| GDD/roadmap/publication | Current release override applied and read back in live 00/01/05/07/90; exact publication SHA supplied by verified remote receipt. |
| Original no-deployment exit | Superseded by explicit authorization for VPS deployment/restart after this safety gate. Workshop publication is outside this request. |

## Focused defect repairs and finite proof

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

## Deployment truth and one operator action

Direct SSH to `ubuntu@40.160.86.240` and A2S to `40.160.86.240:27015` both failed
here with **Network is unreachable**, before authentication or server inspection.
No VPS file, player record, config, service or Workshop item was changed. The
installed VPS revision, current service health, logs and public listing are unknown.
The infrastructure document's historical checks are not fresh evidence.

Run the pinned command provided with the publication response from a machine with
VPS access. It retrieves this revision's helper via `git show` before executing it,
so a moving remote main cannot silently substitute another release. Review its
`DEPLOYED` receipt/query and backup path. It intentionally stops for existing local
work or service-layout differences. The rollback source SHA and previous branch
are retained in the private backup directory. On failure, inspect health before
play; the helper never claims the rollback itself has passed native acceptance.

The helper's successful local query proves a responding Source server, not Steam
master-list visibility or an Internet client connection. Verify those natively.
The existing Workshop distribution remains unchanged: for this candidate test,
install the **same published revision locally** using `tools/install_dev.sh` and
fully restart GMod. VPS Lua delivery alone does not certify current custom assets
on a client with an older Workshop package. Public Workshop asset parity is unverified.

## Single concise native smoke procedure

On the exact candidate client, find **The Legend of Deborah** in the Internet
server browser, then join `connect 40.160.86.240:27015` on `gm_flatgrass`.

1. Claim a Hermit gift, enter a dungeon, inspect an unbranded/tinted hull and one
   complete company composition close up and at a distance/oblique angle. Inspect
   a stock blast-door gate and its reader/signs, walk solid floors/stairs and any
   visible grate apron; check cover/rails and that locked progression cannot be bypassed.
   Use `lod_crate_preview` to sample the ten hull tints if available. Run the single
   diagnostic line below; a missing command is evidence, not a pass.
2. Pick up/equip/use loot, unlock a gate with its key, die and respawn, then disconnect
   and rejoin. Confirm controls, floor/gates, owned equipment and persistent wallet
   remain coherent. During an agreed empty/test interval, exercise a natural failed
   campaign's E restart; verify a fresh playable staging/maze with no stale controls.
3. Return one representative screenshot and `console_latest.txt` +
   `rpg_summary_latest.txt` from the client data folder documented in TEST_LOGGING.md.
   Server-admin diagnostics may require console/admin/developer access; keep the
   public server's existing configuration intact. Run server status/validator from
   its authorized console when available. Do not paste private journal/process lines.

Client diagnostic line:
`lod_crate_status; lod_container_brand_status; lod_progression_render_status; lod_stability_client_status`

Require branding renderer `source-front-face-20260924`, complete visible artwork,
stock gate bodies without concrete, safe traversal, no crash/Lua exception/control
lock or progression loss. Native full-campaign finale/Level-21, broader hull/brand
samples and real multiplayer lifecycle remain pending wherever this smoke does
not exercise them. Dense performance/residency certification stays deferred.

## Tested production/tool receipts

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
