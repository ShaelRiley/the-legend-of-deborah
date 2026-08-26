# Development Status — 2026-08-25 Post-C8

## Current execution phase

**Gate C8 — Complete-Dungeon Dice-Era Validation: ACCEPTED.**

**Targeted Magnum balance validation: CURRENT, immediately before Gate D.**

The live GDD remains design authority. GitHub `main` remains implementation authority. Gate A and Gate C8 are closed unless new regression evidence appears.

## Accepted whole-game balance checkpoint

Authentic dice-era play progressed through **Level 5** before a total-party wipe. The player explicitly reports the game as **fun, balanced, and playable**. This accepts Gate C8 and freezes broad combat/economy balance. The current Magnum work is a deliberately narrow peer-firearm correction identified before beginning Gate D; do not use it as license for broad retuning.

The accepted production progression loop remains:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah → level clear → intermission → next generated level`

Previous accepted evidence also includes three consecutive complete dungeons, successful Level-4 generation/release, legal progression, Deborah rescue/intermission/next-level generation, `lod_m2_seed_test 100` at 100/100, progression persistence through death, accepted minimap/breadcrumb behavior, and corrected stair presentation.

## Minimap performance — ACCEPTED

The production minimap is consolidated to one canonical server module and one canonical client module. Static current-floor topology is cached in a reusable 256×256 render target; dynamic gates, stairs, breadcrumb, objective, and player state remain lightweight overlays. Same-level reopen performs no topology retransmission.

Steam Deck acceptance evidence:

- `paintFrames=1297`
- `bfsBuilds=20`
- `bfsHits=1277` (~98.5% route-cache reuse)
- `floorIndexBuilds=1`
- `topologyBuilds=1`
- `mapRequests=0`
- `cachedReopens=1`
- `ready=true result=PASS`
- player reports map-open play now feels smooth.

The minimap performance issue is closed. `lod_minimap_cache_status` remains a lightweight manual regression probe; automatic telemetry remains prohibited.

## Canonical exploding-die invariant

- **Every d6 rolled anywhere in LOD recursively explodes only on natural 6.**
- **Every fresh d12 chain begins at natural 8–12.**
- After every successful d12 explosion, the next d12 in that same chain lowers its threshold by one.
- At the default settings the d12 sequence is **8+ → 7+ → 6+ → 5+**, then remains at 5+.
- **Boomchain Floor** is an exposed shared tuning variable, default **5**. Future Magic/items may lower it.
- Every newly started d12 chain resets to 8+ and descends independently toward the current Boomchain Floor.

Current implementation is compliant for Force Shout/Shotgun d6s and Magnum/Magnum-pierce d12 chains.

## Current combat foundation

### Player weapons

- Crowbar: `1d3`, 96-unit reach.
- Pistol: `1d4`; fresh expedition begins with Pistol + Crowbar, Pistol 18 loaded / 0 reserve.
- SMG: `1d8`; six rapid shots overheat, 0.25 s per heat cooling, 2.0 s overheat lock, staged audiovisual feedback.
- AR2: `1d10` per projectile; 0.45-second committed targeting laser followed by exactly three rounds; complete burst costs **one AR2 ammo unit**.
- .357 Magnum: each projectile deals **`1d12!+X`**, where X is the number of chambers already empty before that trigger. A normal cylinder progresses **+0,+1,+2,+3,+4,+5**. Trigger 5 fires two projectiles; trigger 6 fires three. Below 60 current HP, each trigger makes one `(60-HP)%` check to add exactly one further free Magnum projectile, so the final burst can become four projectiles. On a final-cartridge trigger below 34% max Health, the final cartridge has `floor(34-currentHealthPercent)%` chance not to be consumed; preservation restores exactly one cartridge after the complete burst, allowing another final-chamber/+5 trigger. **Aim State** arms after 0.5 seconds of complete player and aim stillness, announces itself with a gold muzzle-particle lock cue, sound, and compact persistent `AIM x2` indicator, cancels immediately on movement or aim change, and is consumed by the next actual trigger. An aimed trigger deals **×2 damage across the whole trigger**, including every chamber/low-health burst projectile, cylinder bonus, projectile Boomchains, and fresh deeper-pierce Boomchains. Extra projectiles consume no additional ammo, roll independent d12 Boomchains, and retain normal piercing. Each deeper pierced target adds one fresh independent d12 Boomchain; eight-target cap and authoritative geometry stop remain.
- Shotgun: shared exploding damage `1d6!`, per-die floor 3, natural 6 only; **8 guaranteed pellets + exploding `1d6!` additional pellets**; every connecting pellet deals at least 1 damage; 4× ordinary hit stun; 168-unit nominal push; 36-pellet safety cap.
- Grenade: `1d20`, separate consumable reward.

Player-side exploding dice use the shared bounded audiovisual confirmation cue.

### Basic Magic

- personal Magic 0–100;
- blue Suit-style HUD slot beside Health;
- 0→100 regeneration over 60 seconds while alive;
- RMB globally belongs to Magic; LOD weapons expose no HL2-style secondary fire;
- Force Shout costs 30 Magic, uses an unobstructed ~60° / 1100-unit cone, deals exploding `2d6`, and applies a 336-unit shared-authority push to survivors.

### Generic pushback / wall crush

`LOD.Pushback` remains the reusable displacement authority for Shotgun, Force Shout, and future effects. Architectural blockage can add one `1d3` wall-crush roll. Push presentation uses bounded 4–16 body-ghost trails from reusable leased clientside models.

### Hostile health / ordinary melee

- Deadcrab health `2d4+1`
- Runner health `3d4+3`; melee `2d4+2`
- Shambler health `4d4+5`; melee `3d4+8`
- Soldier / Blitzer health `4d4+5`
- Bio Blaster health `5d4+6`

Visible hostile size remains a monotonic durability cue.

## Production loot / firearm economy

LootDirector owns individualized static supplies, contextual enemy drops, pity protection, rare extra lives, join-in-progress catch-up, and sector resource-budget validation. HL2 suit/armor is not part of LOD's economy.

Shotgun, SMG, Magnum, and AR2 are peer firearms available from Dungeon 1 with equal randomized acquisition weighting. Contextual ammo-family selection is driven by depletion rather than hidden weapon rarity.

## Finite ammo

- Pistol: 54 cap / 18 floor / 60 s empty-to-floor
- Shotgun: 18 / 6 / 90 s
- SMG: 135 / 45 / 120 s
- AR2: 90 / 30 / 150 s
- .357: 18 / 6 / 180 s

One shared 4 Hz server timer owns regeneration. Grenades do not regenerate.

## Immediate runtime evidence needed

Validate the targeted Magnum pass before beginning Watcher:

1. A fresh/reloaded six-round cylinder reports chamber bonuses in order **+0,+1,+2,+3,+4,+5**.
2. D12 explosions visibly use descending thresholds **8+ → 7+ → 6+ → 5+** within one chain.
3. Trigger 5 produces exactly two Magnum projectiles total; trigger 6 produces exactly three at 60+ HP.
4. Below 60 HP, the diagnostic reports the correct `(60-HP)%` extra-projectile chance and observed procs can add only one projectile per trigger.
5. Below 34% max Health, the final-cartridge preservation diagnostic reports the correct chance; a successful proc resolves the full final burst and leaves exactly one cartridge available afterward.
6. Preserved final cartridges remain chamber-6/+5 shots and may make a new preservation check on the next trigger.
7. Hold completely still with the Magnum for **0.5 s**: the gold particle/sound lock cue and persistent `AIM x2` indicator must appear. Move the player or view aim before firing and confirm Aim State cancels immediately.
8. Fire from Aim State and confirm the combat feed detail includes **`AIM x2`** and applied damage is doubled. On a chamber burst, every projectile from that trigger inherits ×2; on a pierce, fresh deeper-target d12 chains are also doubled.
9. Extra burst/projectile mechanics do not consume additional reserve ammunition.
10. Burst projectiles retain independent damage, explosion cue, and penetration behavior.
11. No meaningful Steam Deck performance regression.

Diagnostics: `lod_magnum_super_status`, `lod_magnum_aim_status`, and `lod_magnum_pierce_status`.

After this targeted acceptance, proceed to **Gate D — Expanded Enemy Roster**, beginning with Watcher.

## Preserved hard constraints

- `gm_flatgrass` remains the required base map.
- Canonical generated 3D graph remains topology/progression/routing/minimap authority.
- Motion V2 remains the sole ordinary hostile ground-movement authority; validated stairs remain the sole ordinary elevation-changing route.
- Soldier warning/projectile truth remains one immutable server-authored origin/direction committed at beam-on.
- Generated geometry remains authoritative cover, including Magnum penetration and pushback collision.
- Minimap remains one canonical server module + one canonical client module; static topology must not return to per-frame redraw or same-level retransmission.
- Preserve bounded networking, cached graph/minimap work, shared hostile registry, bounded death scheduling, and developer-only heavy audits.
- Do not introduce per-frame global BFS or large entity scans.
- Automatic startup telemetry remains retired.
