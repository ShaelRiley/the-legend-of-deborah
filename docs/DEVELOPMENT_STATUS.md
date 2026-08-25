# Development Status — 2026-08-25 Post-C8

## Current execution phase

**Gate C8 — Complete-Dungeon Dice-Era Validation: ACCEPTED.**

**Gate D — Expanded Enemy Roster: CURRENT.**

The live GDD remains design authority. GitHub `main` remains implementation authority. Gate A and Gate C8 are closed unless new regression evidence appears.

## Accepted whole-game balance checkpoint

Authentic dice-era play progressed through **Level 5** before a total-party wipe. The player explicitly reports the game as **fun, balanced, and playable**. This is sufficient to accept Gate C8 and freeze broad combat/economy balance unless a specific runtime regression or clearly isolated balance problem appears.

The accepted production progression loop remains:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah → level clear → intermission → next generated level`

Previous accepted evidence also includes three consecutive complete dungeons, successful Level-4 generation/release, legal progression, Deborah rescue/intermission/next-level generation, `lod_m2_seed_test 100` at 100/100, progression persistence through death, accepted minimap/breadcrumb behavior, and corrected stair presentation.

## Minimap performance — ACCEPTED

A performance audit found that breadcrumb BFS was already cached, but the presentation layer was still redrawing hundreds of static maze cells/walls each HUD frame while the map was open. The subsystem was consolidated to one canonical server module and one canonical client module.

Production minimap architecture now provides:

- immutable current-floor topology rendered once into a reusable **256×256 render target** and composited as a single textured rectangle;
- dynamic gates, JailEdge, stairs, breadcrumb route, objective, and player marker as lightweight overlays;
- floor/stair/gate/jail indexes and compact adjacency built once after topology reception;
- BFS cached by player cell + gate/jail/objective state;
- same-level close/reopen with **no topology retransmission**;
- throttled mismatch/incomplete map requests;
- maze origin sent once in the map-begin packet rather than polled every client frame;
- level-stamped map entitlement instead of server per-tick level-reset scanning;
- dead-player/access safety folded into the canonical modules.

Steam Deck acceptance evidence:

- `paintFrames=1297`
- `bfsBuilds=20`
- `bfsHits=1277` — approximately **98.5% route-cache reuse**
- `floorIndexBuilds=1`
- `topologyBuilds=1`
- `mapRequests=0`
- `cachedReopens=1`
- `ready=true`
- `result=PASS`
- player reports map-open play now feels smooth enough to close the performance issue.

The minimap performance issue is therefore **closed**. `lod_minimap_cache_status` remains a lightweight manual regression probe; automatic telemetry remains prohibited.

## Canonical exploding-die invariant

- **Every d6 rolled anywhere in LOD recursively explodes only on a natural 6.**
- **Every d12 rolled anywhere in LOD recursively explodes on a natural 8, 9, 10, 11, or 12.**
- New mechanics inherit these thresholds automatically unless a later explicit design change supersedes them.

Current implementation is compliant for Force Shout, both Shotgun d6 systems, and Magnum/Magnum-pierce d12 chains.

## Current combat foundation

### Player weapons

- Crowbar: `1d3`, 96-unit reach.
- Pistol: `1d4`; fresh expedition begins with Pistol + Crowbar, Pistol 18 loaded / 0 reserve.
- SMG: `1d8`; six rapid shots overheat, 0.25 s per heat cooling, 2.0 s overheat lock, staged audiovisual feedback.
- AR2: `1d10` per projectile; 0.45-second committed targeting laser followed by exactly three rounds; complete burst costs **one AR2 ammo unit**.
- .357 Magnum: exploding `1d12` on natural **8–12**; aligned piercing adds one fresh independently exploding d12 chain for every deeper target: `1d12!`, `2d12!`, `3d12!`, etc., capped at eight targets and stopped by authoritative geometry.
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

## Next production work

Proceed to **Gate D — Expanded Enemy Roster**, in this order:

`Watcher → Seeker → Sentry → Razor → Flamer → Big Crab → Arc Caster → Lurker → Beam Sweeper`

Implement and runtime-accept **one enemy archetype at a time**, beginning with **Watcher**. Preserve the immutable Soldier shot contract and the accepted low-end architecture.

After Gate D:

1. Remaining Milestone-4 expedition work, especially Brute + Neil / production Map acquisition and broader attrition/soak validation.
2. Gordon the Warden.
3. Dedicated multiplayer integration / release-candidate QA.

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
