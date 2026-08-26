# Development Status — 2026-08-25 Post-C8

## Current execution phase

**Gate C8 — Complete-Dungeon Dice-Era Validation: ACCEPTED.**

**Gate D — Expanded Enemy Roster: CURRENT. Watcher implemented; runtime acceptance pending.**

The live GDD remains design authority. GitHub `main` remains implementation authority. Gate A and Gate C8 are closed unless new regression evidence appears.

The targeted Magnum identity pass is implemented and remains available for ordinary-play regression observation through `lod_magnum_super_status`, `lod_magnum_aim_status`, and `lod_magnum_pierce_status`, but it no longer blocks roster development.

## Accepted whole-game balance checkpoint

Authentic dice-era play progressed through **Level 5** before a total-party wipe. The player explicitly reports the game as **fun, balanced, and playable**. Broad combat/economy balance is therefore frozen; future tuning should be narrow and evidence-driven.

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

## Current combat foundation

### Player weapons

- Crowbar: `1d3`, 96-unit reach.
- Pistol: `1d4`; fresh expedition begins with Pistol + Crowbar, Pistol 18 loaded / 0 reserve.
- SMG: `1d8`; six rapid shots overheat, 0.25 s per heat cooling, 2.0 s overheat lock, staged audiovisual feedback.
- AR2: `1d10` per projectile; 0.45-second committed targeting laser followed by exactly three rounds; complete burst costs **one AR2 ammo unit**.
- .357 Magnum: each projectile deals **`1d12!+X`**, where X is the number of chambers already empty before that trigger. Cylinder bonuses progress **+0,+1,+2,+3,+4,+5**. Trigger 5 fires two projectiles; trigger 6 fires three. Below 60 current HP, each trigger makes one `(60-HP)%` check to add exactly one further free projectile. Below 34% max Health, the final cartridge has `floor(34-currentHealthPercent)%` chance to be restored after its complete burst. Aim State arms after 0.5 seconds of complete player/aim stillness, cancels on movement or aim change, and makes the entire next Magnum trigger resolve at **×2 damage** including burst and pierce-added Boomchains. Each trigger pull consumes at most one cartridge regardless of projectile count; successful final-cartridge preservation produces zero net cartridge consumption for that trigger.
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

## Gate D — Watcher implementation — RUNTIME ACCEPTANCE CURRENT

The live GDD defines Watcher as a Combine Scanner-derived support archetype that weaponizes the existing wandering population rather than adding direct damage or reinforcements.

Current implementation:

- no direct attack;
- Scanner model, graph-bound Motion-V2 movement;
- rare wandering eligibility with low production weight;
- Sector-2+ authored `Surveillance = 1 Watcher + 2 Shamblers` encounter option;
- unmistakable **1.25-second scan** with escalating cyan beam and electronic cues;
- line-of-sight break cancels the scan;
- firearm hit-stun cancels the scan;
- successful scan retargets only **already-existing** eligible wanderers on the same floor within **6 graph cells**;
- alerted wanderers immediately acquire the scanned player but remain subject to ordinary safe-zone, floor, and pursuit-leash rules;
- the scan never spawns enemies and therefore cannot bypass threat budgets or hostile ceilings;
- alert iteration uses `WanderingDirector.Entities` plus cached graph distance rather than a global entity scan;
- provisional Watcher dice durability is `3d4+3`, chosen as Runner-class focus-fire durability because the GDD does not prescribe a numeric Watcher health formula.

Developer probes:

- `lod_watcher_test` creates a Watcher plus a test wandering Shambler deliberately placed outside the normal 4-cell acquisition radius but, when geometry permits, inside the Watcher's 6-cell alert radius.
- `lod_watcher_status` reports live/scanning Watchers, scan starts/completions, LOS/hit-stun cancellations, alerted wanderers, and PASS/WAITING.

### Watcher acceptance criterion

In an ordinary non-safe corridor, run `lod_watcher_test`, allow one complete visible scan, then run `lod_watcher_status`. Acceptance requires a readable escalating beam/audio sequence and status evidence of at least one scan start, one completion, and one alerted wanderer (`result=PASS`). Also confirm there is no obvious Steam Deck performance regression.

After Watcher acceptance, **Seeker** is next. Do not begin Seeker implementation before Watcher is accepted.

## Hostile health / ordinary melee

- Deadcrab health `2d4+1`
- Runner health `3d4+3`; melee `2d4+2`
- Watcher health `3d4+3` **provisional implementation tuning; no direct attack**
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

## Preserved hard constraints

- `gm_flatgrass` remains the required base map.
- Canonical generated 3D graph remains topology/progression/routing/minimap authority.
- Motion V2 remains the sole ordinary hostile ground-movement authority; validated stairs remain the sole ordinary elevation-changing route.
- Soldier warning/projectile truth remains one immutable server-authored origin/direction committed at beam-on.
- Generated geometry remains authoritative cover, including Magnum penetration and pushback collision.
- Watcher may only alert already-existing eligible wanderers; never create Watcher-specific reinforcement spawning or global hostile scans.
- Minimap remains one canonical server module + one canonical client module; static topology must not return to per-frame redraw or same-level retransmission.
- Preserve bounded networking, cached graph/minimap work, shared hostile registry, bounded death scheduling, and developer-only heavy audits.
- Do not introduce per-frame global BFS or large entity scans.
- Automatic startup telemetry remains retired.
