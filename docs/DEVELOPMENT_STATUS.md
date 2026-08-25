# Development Status — 2026-08-25 Dice-Era Reconciliation

## Current execution phase

**Gate C8 — Complete-Dungeon Dice-Era Validation.**

The live GDD remains design authority. GitHub `main` remains implementation authority. Gate A is closed unless new regression evidence appears.

## Accepted complete-dungeon checkpoint

Accepted runtime evidence includes three consecutive complete dungeons, successful Level-4 generation/release, legal Red → Blue → Yellow → Jail Key → jail door → Deborah progression, Deborah rescue/intermission/next-level generation, `lod_m2_seed_test 100` at 100/100, accepted minimap/breadcrumb behavior, corrected stair presentation, and progression persistence through death.

Recent authentic dice-era play has also produced a legitimate Level-1 clear and meaningful Level-2 progress. Balance is currently treated as challenging but viable; avoid broad difficulty changes without new runtime evidence.

## Canonical exploding-die invariant

The live GDD defines explosion thresholds globally:

- **Every d6 rolled anywhere in LOD recursively explodes only on a natural 6.**
- **Every d12 rolled anywhere in LOD recursively explodes on a natural 8, 9, 10, 11, or 12.**
- New mechanics that use d6s or d12s inherit these thresholds automatically unless a later explicit design change supersedes them.

Current implementation is compliant for Force Shout d6 chains, both Shotgun d6 systems, and Magnum / Magnum-pierce d12 chains.

The Shotgun uses two pellet-count layers only: eight guaranteed pellets plus a separate exploding `1d6!` for additional pellets. The earlier three independent 33% bonus-pellet checks are retired. The pellet-count die has no damage floor, averages 4.2 extra pellets before the rare safety cap, and triggers the shared exploding-die audiovisual confirmation when it explodes. Production clamps final shell trace count to 36 for low-end safety. With the universal natural-6-only shared damage die, the uncapped shell averages 12.2 pellets and approximately 9.76 full-connect base damage before later modifiers.

## Current combat foundation

### Player weapons

- Crowbar: `1d3`, dedicated authoritative SWEP, 96-unit reach, miss whoosh, soft impact, hit-confirm beep.
- Pistol: `1d4`; fresh expedition starts with Pistol + Crowbar, Pistol loaded to 18 with 0 reserve.
- SMG: `1d8`; six rapid shots overheat, one heat cools every 0.25 s below threshold, 2.0 s overheat lock, staged model/audio/smoke feedback.
- AR2: `1d10` per projectile; every activation commits one 0.45-second targeting-laser tell then exactly three rapid rounds. **The complete three-projectile burst consumes one AR2 primary-ammo unit total**, spent when the first projectile releases.
- .357 Magnum: universal exploding `1d12`; natural **8–12** recursively explode. A bullet pierces properly aligned hostiles and adds one fresh independently exploding d12 chain for every deeper target: target 1 `1d12!`, target 2 `2d12!`, target 3 `3d12!`, etc., up to the bounded eight-target cap and authoritative geometry stop.
- Shotgun: shared universal exploding damage `1d6!`, per-die floor 3, **natural 6 only** recursively explodes; eight guaranteed pellets + one separate exploding `1d6!` additional-pellet roll; one 4× ordinary hit stun and 168-unit nominal push per damaged target per shell; 36-pellet safety cap.
- Grenade: `1d20`; remains a separate consumable reward.

Player-side exploding dice have bounded audiovisual confirmation: center-screen radial burst/label plus a short positive two-layer sound. This is shared by Magnum, Shotgun damage/pellet dice, Force Shout, and Magnum-pierce bonus dice.

### Basic Magic

A deliberately limited pre-release Magic subsystem is implemented while the broader RPG Magic layer remains deferred:

- personal 0–100 Magic resource;
- blue Suit-style HUD slot beside Health;
- regeneration from 0→100 over 60 seconds while alive;
- RMB globally belongs to Magic; LOD weapons have no HL2-style secondary fire;
- Force Shout costs 30 Magic, attacks an unobstructed ~60° / 1100-unit cone, deals exploding `2d6` using the universal natural-6 rule, and pushes surviving targets 336 units through `LOD.Pushback`.

### Generic pushback / wall crush

`LOD.Pushback` is the reusable displacement authority for Shotgun, Force Shout, and future weapon/element/environment effects. Pushes use bounded collision checks and cannot force hostiles through walls, gates, jail doors, or unauthored geometry. If blocking architectural geometry stops the requested push, the target takes one additional `1d3` wall-crush roll per push event and receives distinct audiovisual impact feedback.

Push travel presentation uses a short 4–16 body-ghost trail from the hostile's authoritative start position to its resolved destination. Distinct leased clientside render models are reused from bounded per-model pools so multiple ghosts can coexist in one frame without AI/physics work.

### Hostile damage and health

Current ordinary melee retune from full-run evidence:

- Shambler: `3d4+8` before existing size/stat scaling; unscaled 11–20.
- Runner: `2d4+2`; unscaled 4–10.

Deterministic health profiles remain:

- Deadcrab `2d4+1`
- Runner `3d4+3`
- Shambler / Soldier / Blitzer `4d4+5`
- Bio Blaster `5d4+6`

Visible hostile size remains a monotonic durability cue.

## Production loot and firearm economy

LootDirector is implemented and owns individualized static supplies, contextual enemy drops, pity protection, rare extra lives, join-in-progress catch-up, and sector resource-budget validation. HL2 suit/armor is not part of LOD's economy; former armor recovery restores ordinary HP instead.

Shotgun, SMG, .357 Magnum, and AR2 are peer firearms rather than power tiers. All can appear from Dungeon 1, randomized firearm acquisition weights them equally, Level 1 guarantees two distinct peer firearms, and contextual ammo-family choice is driven by depletion rather than hidden rarity coefficients.

## Finite-ammo economy

Combined loaded-plus-reserve caps / one-reload regeneration floors:

- Pistol: 54 / 18 / 60 s empty-to-floor
- Shotgun: 18 / 6 / 90 s
- SMG: 135 / 45 / 120 s
- AR2: 90 / 30 / 150 s
- .357: 18 / 6 / 180 s

One shared 4 Hz server timer owns regeneration. Grenades do not regenerate. The H-key developer Pistol remains an intentional test bypass.

## Runtime evidence still needed

Current testing should continue to judge the integrated dungeon experience: completion time, deaths/lives, sustain, ammunition pressure, peer-firearm usefulness, Magic readability, Magnum alignment reward, exploding-die feedback, Shotgun pellet volatility, combat-feed readability, and Steam Deck performance.

The next Shotgun-specific evidence should verify that eight guaranteed pellets plus the exploding pellet-count die feels fun and powerful without producing unacceptable close-range lethality or Steam Deck trace cost.

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
