# SPOT-08 — finite Gordon turret production gate

Defined before gameplay code. Parent: `35c43bc8bac86e5ea108b9f96e9d5ab6a94bf542`.
Live GDD 00 → 01 → 03/05/06/07 read; SPOT-08 was reconciled in 05/07
under the author's explicit design delegation before implementation. Initial
candidate revision: `ANLCKQkSqQvppZSFYBgWt9tzoRyfBlmPuZD29y8TseUiOG8hF904yq_DgfrzbK82HOTOJC5DA8g3fsK7lljtobV_fxII1Nag7sfZ5FJgeA`.

## Required observable production behavior

* Cumulative counts at D1/4/5/9/10/14/15/19/20/25/endless; deterministic independent
  four-corner permutation, no duplicates, no party multiplier or destruction retry.
* Actual generated arena's lower corners, canonical Motion seating, flat full-footprint
  support, native hull, protected entry, connected court and two stair/gallery routes.
  Failed/occupied/capacity slots skip once, without replacement or delayed spawn.
* Ordinary Sentry generation/HP/defenses/status/rewards; one shared 96-hostile
  ceiling and reciprocal Gordon 16-hazard / EnemyRoster 64-projectile admission.
* Execute actual Sentry Begin/Attack/Release, shared projectile service and guarded
  native damage packet. Full minimum .75s warning, immutable aim, .2s release grace,
  .25s service limit, source displacement/interruption, finite one-shot settlement.
* Exact source/root/run/graph/progression/level/seed/campaign identities and canonical
  progression/status lives. Captured cooperative Hero lives only; no role/revival/
  reconnect transfer. Invisibility forbids acquisition, not released interception.
* Court-only acquisition and damage; protected alcove bilateral including proxies;
  fixed cone/range, native sight/cover. No-target waiting preserves body/HP/slots.
* Freeze, failure/wipe, reset, same-seed replacement, source/root replacement and
  Gordon death retire stale attacks. Deferred exact-body cleanup outside lethal
  callbacks precedes Hector reveal and cannot mutate newer ownership.

## Finite automated selection

`python3 tools/test_spot08_gate.py --output <empty directory outside repository>`

Retain all 50 selected SPOT-07 gate suites, add the SPOT-08 production harness and
ordinary EnemyRoster/placement regression. All-source SHA256 before/after must
match; all Lua files must parse. Each suite has the existing 45-second timeout.
Preserve failed attempts separately. This is not a full campaign-matrix pass.

## Native acceptance (open until observed)

Fully restart Garry's Mod on `gm_flatgrass`. In ordinary play, reach threshold
arenas; check `lod_warden_status` against the visible corner turrets. Confirm safe
arrival, both stairs/gallery routes, warning visibility in full/reduced effects,
dodging/flanking/destruction, no respawn on co-op return, and no surviving turret
attacks after Gordon death or during Hector's reveal. Capture `console_latest.txt`
and `rpg_summary_latest.txt` plus a brief visual/listening report. Automated doubles
do not prove native geometry, model seating, prediction, sound or balance.

No dedicated Razor retest, Workshop publication, VPS deployment or restart.
