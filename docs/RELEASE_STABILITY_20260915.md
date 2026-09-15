# Release stabilization — September 15, 2026

Branch: `astra/equipment-update`. Audit baseline: `951efa8acbd1dc65d86c3e03e531d419eb370264`.
Runtime identity: `stability-20260915-06`. Live GDD navigation: 00 → 01 → 03 and 06;
the current author explicitly authorized cross-system stabilization. No balance-law change is needed for the shotgun repair.

This is a **development candidate requiring native acceptance**, not authorization to
promote. The retained reports isolate native failures during `Player:Give` and
hostile death/loot handoff; they do not contain a native stack proving one cause.
No Garry's Mod executable is available in the automated workspace.

## Confirmed defects and repairs

- Firearm modifiers had no final `GM:EntityFireBullets` return committing the
  modified bullet table. Hooks now compose normally and the final gamemode seam
  commits them while retaining an explicit base cancellation.
- Shotgun hits were inferred from `EntityTakeDamage`, after Source may combine
  same-target pellets. Individual bullet callbacks now count confirmed hits,
  suppress native pellet damage, then settle one shared RPG event per target.
  Scaled-hostile fallback uses the same geometric resolver. CON, flat modifiers,
  equipment, defense, riders, feed and shell control retain their shared authorities.
  No additional damage dice, bypasses, or artificial range multiplier were added.
  Nine connected pellets at minimum shell roll against CON reduction 3 now yield
  nine damage before downstream equipment/element/defense modifiers. Genuine
  Dodge/Block/immunity/zero-scale effects remain valid; ordinary CON cannot erase
  the shell. Split targets receive their actual pellet counts. Shell feed/control uses actual
  post-engine HP loss, so native armor, rejection and overkill agree with the readout.
- Deferred shell settlement is idempotent and rejects removed/dead actors, changed
  progression/level and death/respawn life epochs. Same-frame shells own separate
  contracts rather than reading the most recent active-weapon contract.
- Ordinary loot still ran its grant inside native Touch/Use despite the earlier
  starter repair. The entire collection now settles next tick, with one pending
  claim and explicit Use taking priority over automatic collection. Native Give,
  ownership mutation and removal happen after touch traversal unwinds.
- Deferred equipment/ammo callbacks now recheck actual weapon ownership. An old
  grenade rejection removes that exact entity, not an unrelated later grant of
  the same class through `StripWeapon`.
- Manual and GPS nested includes used gamemode-root-looking relative paths from
  within `lod/`. Explicit absolute gamemode paths remove the duplicated-folder
  resolution failure. Manual registration happens early on both realms. P and
  staging E still open the one canonical reader.
- Manual transfer previously queued 60KB messages every 30ms. It now allows one
  acknowledged 16KB chunk in flight, validates ordered metadata, caps decompression,
  expires abandoned transfers, cleans disconnect state, shows progress/retry, and
  preserves an in-flight download when the reader is closed/reopened.
- Cinematic refresh restores existing presentation wrappers before replacing
  their local ownership. Warden props retire before refresh and on map cleanup;
  container models also retire on map cleanup.
- Bounded durable client/server Lua-error journals record counts, stack locations,
  and manual open/HTML/ready stages. Resource reports include Lua-error counts;
  existing starter and death/loot breadcrumbs remain.

## Evidence and audit coverage

Baseline: 95 suites passed. Stabilization checkpoint: **99 suites pass**, including
all production Lua syntax, real SQLite rollback, native-resource stress, pickup
transactions, hero inventory retention/respawn, Soldier isolation, enemy roster
animation guards, boss/hunt transitions, TIME OVER, feat/status/equipment damage
integration, manual DOM navigation and streamed transport.

New tests exercise actual shotgun bullet callbacks (including same-frame shells,
CON 0–3, split targets, cover, cancellation, duplicate settlement), paced transfer
with duplicate/foreign ACKs, expiry/disconnect, and bounded error diagnostics.
The wiring audit resolves 464 literal include/distribution paths and checks
hook/timer/net registration collisions by realm. Intentional replacements remain:
container wayfinding progresses to the marking-panel authority; reliable map
chunks replace the original receiver. Equipment inspection has one receiver in
each realm. No unexplained duplicate static registration was found.

Reviewed lifecycle seams include starter/native grant callbacks, normal/procedural
loot, inventory replacement/retention, hostile deferred death, boss cleanup,
projectile/work caps, cinematic cleanup, mesh/afterimage/model ownership, owner-only
network transactions and manual startup. Automated boundaries cannot establish
Source collision/GPU behavior, engine hook delivery, third-party addon effects,
or native process-memory stability.

## Native gate before promotion

Close GMod, update this branch, run `bash tools/install_dev.sh`, and fresh-start
`gm_flatgrass`. Use `lod_stability_status; lod_stability_client_status`; require
`build=stability-20260915-06`, `missing=none`, and zero new Lua errors.

In one continuous session: collect the Hermit starter; open E's manual, switch to
P/Character and back, then reopen it after deploying; use the shotgun at close
range on a durable enemy and across two targets, comparing pellet/feed damage;
finish Soldiers/Shamblers and collect/swap drops; die/respawn and check retained
loadout; rescue Deborah, redeploy, and repeat combat/pickups. On the multiplayer
candidate, reconnect one participant and repeat equipment/manual access. Finish
with `lod_dev_timeout_in 5` while deployed and confirm reset releases UI/models.

Require no forced close, Lua error, lost/duplicated equipment, or stalled manual.
Retain `console_latest.txt` and `rpg_summary_latest.txt`. On force-close preserve
`rpg_test_session.txt`, `stability_client_latest.txt`, `stability_server_latest.txt`
and any native crash dump **before relaunching**. Files are under
`garrysmod/data/legend_of_deborah/` except the engine dump. Native acceptance is
still required; the earlier unexplained process terminations are not declared
proven fixed by Lua mocks.

## Shared native damage lifetime closure

The follow-up audit found a second engine-boundary defect independent of pellet
counting: [DamageInfo() returns shared storage](https://wiki.facepunch.com/gmod/Global.DamageInfo).
Weak-key maps alone therefore cannot retire old `settledShotgun`, status, report
or Magnum penetration metadata. Every project-created damage object now enters
through `LOD.NewDamageInfo`, which clears these maps before reuse; the final
post-damage gamemode seam retires metadata after ordinary observers finish.

Pusher, crowbar Bash, and equipment Push could synchronously cause wall-crush
damage inside the original post-damage callback. They now capture plain attack
values and defer the reaction until the native stack unwinds, rechecking life,
identity, target health and campaign/level. No borrowed DamageInfo crosses the
callback boundary. The new harness reuses one engine-like object 1,000 times,
exercises the real Pusher observer with nested mutation forbidden, and verifies
removal, death/respawn and transition cancellation. The wiring gate prohibits
new direct factory calls outside this authority.

API checks supporting the startup/firearm fixes:
[include path resolution](https://wiki.facepunch.com/gmod/Global.include),
[EntityFireBullets return contract](https://wiki.facepunch.com/gmod/GM:EntityFireBullets),
[individual bullet callback suppression](https://wiki.facepunch.com/gmod/Structures/Bullet),
[bounded decompression](https://wiki.facepunch.com/gmod/util.Decompress).
