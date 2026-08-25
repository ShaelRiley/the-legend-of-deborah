# Development Status — 2026-08-25 Dice-Era Reconciliation

## Current execution phase

**Gate C8 — Complete-Dungeon Dice-Era Validation.**

The live GDD remains design authority. GitHub `main` remains implementation authority. Gate A is closed unless new regression evidence appears.

## Accepted complete-dungeon checkpoint

Accepted runtime evidence includes three consecutive complete dungeons, successful Level-4 generation/release, legal Red → Blue → Yellow → Jail Key → jail door → Deborah progression, Deborah rescue/intermission/next-level generation, `lod_m2_seed_test 100` at 100/100, accepted minimap/breadcrumb behavior, corrected stair presentation, and progression persistence through death.

## Current combat foundation

### Player weapons

- Crowbar: `1d3`, dedicated authoritative SWEP, 96-unit reach, miss whoosh, soft impact, hit-confirm beep.
- Pistol: `1d4`; fresh expedition starts with Pistol + Crowbar, Pistol loaded to 18 with 0 reserve.
- SMG: `1d8`; six rapid shots overheat, one heat cools every 0.25 s below threshold, 2.0 s overheat lock, staged model/audio/smoke feedback.
- AR2: `1d10` per projectile; every activation commits one 0.45-second targeting-laser tell then exactly three rapid rounds. **The complete three-projectile burst consumes one AR2 primary-ammo unit total**, spent when the first projectile releases.
- .357 Magnum: exploding `1d12`; natural 10/11/12 recursively explode. A bullet also **pierces multiple properly aligned hostiles**, reusing the same resolved shot total until blocking geometry/solid obstruction stops it.
- Shotgun: one shared exploding `1d6`, per-die floor 3, **natural 5 or 6 recursively explodes**, six guaranteed pellets plus independent 33% checks for pellets 7/8/9. Per damaged target it applies **4× ordinary hit stun (nominal 1.20 s)** and a **168-unit nominal push**, once per shell rather than per pellet.
- Grenade: `1d20`; remains a separate consumable reward.

XP, character levels, procedural affixes/equipment, elements, Magic, and Luck Ring remain deferred.

### Generic pushback / wall crush

`LOD.Pushback` is the reusable displacement authority for Shotgun now and future weapon/element/environment effects. Pushes use bounded collision checks and cannot force hostiles through walls, gates, jail doors, or unauthored geometry. If blocking architectural geometry stops the requested push, the target takes one additional `1d3` wall-crush roll per push event and receives a distinct heavy-impact + crunch audio cue.

### Hostile damage and health

Current ordinary melee retune from full-run evidence:

- Shambler: `3d4+8` before existing size/stat scaling; unscaled 11–20.
- Runner: `2d4+2`; unscaled 4–10.

Other hostile attacks retain their existing dice contracts.

Deterministic health profiles remain:

- Deadcrab `2d4+1`
- Runner `3d4+3`
- Shambler / Soldier / Blitzer `4d4+5`
- Bio Blaster `5d4+6`

Visible hostile size remains a monotonic durability cue.

## Production loot and firearm economy

LootDirector is implemented and owns individualized static supplies, individualized contextual enemy drops, pity protection, rare extra lives, join-in-progress catch-up, and sector resource-budget validation. HL2 suit/armor is **not** part of LOD's economy; the former armor recovery band is ordinary HP recovery instead.

The current weapon-design goal is **peer firearms, not a power-tier rarity ladder**:

- Shotgun, SMG, .357 Magnum, and AR2 are all available from Dungeon 1.
- Random firearm rewards weight those four equally.
- Level 1 guarantees two distinct firearm upgrades selected uniformly from those four rather than fixed Shotgun + SMG.
- Join-in-progress catch-up similarly grants two deterministic distinct firearms from the four-gun pool.
- Ammo-drop family choice has no hidden per-weapon rarity coefficient; depletion drives contextual weighting.
- Grenades remain a separate consumable reward.

The intent is that each gun remains viable because of its mechanic, not because one is a strictly rarer/higher tier.

## Finite-ammo economy

Combined loaded-plus-reserve caps / one-reload regeneration floors:

- Pistol: 54 / 18 / 60 s empty-to-floor
- Shotgun: 18 / 6 / 90 s
- SMG: 135 / 45 / 120 s
- AR2: 90 / 30 / 150 s
- .357: 18 / 6 / 180 s

One shared 4 Hz server timer owns regeneration. Grenades do not regenerate. The H-key developer Pistol remains an intentional test bypass.

## Runtime evidence still needed

Recent authentic runs proved the LootDirector and HP recovery work, but repeatedly ended in campaign wipes. Shambler/Runner melee was consequently narrowed. The newest Shotgun retune, one-ammo AR2 burst, peer-firearm distribution, and Magnum penetration still require runtime acceptance.

The immediate Gate-C8 objective remains a repeatedly completable ordinary dungeon with acceptable lethality, sustain, ammo pressure, combat-feed readability, and Steam Deck performance.

## Telemetry safety policy

The failed automatic dice-run telemetry experiment remains fully retired after causing a startup regression into ordinary Sandbox Flatgrass. Full-run validation uses existing diagnostics, screenshots, console output, and manual observations. Any future telemetry must be explicitly developer-armed after successful startup and absent from the normal production loader.

## Preserved hard constraints

- `gm_flatgrass` remains the required base map.
- Canonical generated 3D graph remains topology/progression/routing/minimap authority.
- Motion V2 remains the sole ordinary hostile ground-movement authority; validated stairs remain the sole ordinary elevation-changing route.
- Soldier warning/projectile truth remains one immutable server-authored origin/direction committed at beam-on.
- Generated geometry remains authoritative cover, including Magnum penetration and pushback collision.
- Preserve bounded networking, cached graph/minimap work, shared hostile registry, bounded death scheduling, and developer-only heavy audits.
- Do not introduce per-frame global BFS or large entity scans.
