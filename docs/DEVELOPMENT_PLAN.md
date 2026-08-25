# Development Plan — 2026-08-25 Post-C8

The live GDD is design authority; GitHub `main` is implementation authority. Milestone numbers describe capability groups, while the current execution gate follows accepted runtime evidence.

## Current order

1. **Gate D — Expanded Enemy Roster:** implement and runtime-accept one archetype at a time, beginning with **Watcher**.
2. Continue ordinary whole-dungeon play with broad combat/economy balance frozen unless specific evidence demands a targeted change.
3. Finish remaining Milestone-4 expedition work, especially Brute + Neil / production Map acquisition and broader attrition/soak validation.
4. Implement Gordon the Warden while preserving the proven Jail Key → jail door → Deborah pipeline.
5. Integrate/harden multiplayer last.

Production LootDirector is already implemented. Do not schedule it again as future work.

A limited pre-release Magic subsystem is implemented: Magic meter, global RMB ownership, and Force Shout. XP, character levels, procedural equipment/affixes, elements, Luck Ring, Magic items, and the broader RPG Magic layer remain deferred.

---

## Gate A — Complete Dungeon Vertical Slice — ACCEPTED

The production progression loop is established:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah → level clear → intermission → next generated level`

Do not reopen without new regression evidence.

---

## Gate C8 — Complete-Dungeon Dice-Era Validation — ACCEPTED

Acceptance evidence now includes an authentic run reaching **Level 5** before total-party wipe and the player's explicit assessment that the game is **fun, balanced, and playable**.

Broad combat/economy balance is therefore frozen. Future tuning must be evidence-driven and narrowly scoped.

The minimap performance issue discovered during C8 is also accepted as closed. Steam Deck validation produced:

- `paintFrames=1297`
- `bfsBuilds=20`
- `bfsHits=1277`
- `floorIndexBuilds=1`
- `topologyBuilds=1`
- `mapRequests=0`
- `cachedReopens=1`
- `ready=true result=PASS`

The player confirms map-open gameplay now feels smooth. Preserve the optimized architecture.

---

## Canonical dice / weapon contracts

### Universal exploding-die rule

- **Every d6 recursively explodes only on natural 6.**
- **Every d12 recursively explodes on natural 8–12.**
- Future d6/d12 mechanics inherit these rules unless explicitly redesigned.

### Current player weapons

**Crowbar**
- `1d3`
- 96-unit reach.

**Pistol**
- `1d4`
- fresh expedition begins with 18 loaded / 0 reserve.

**SMG**
- `1d8`
- six-shot overheat threshold;
- 0.25 s cooling per heat;
- 2.0 s overheat lock;
- staged audiovisual/model feedback.

**AR2**
- `1d10` per projectile;
- 0.45 s committed targeting laser;
- exactly three projectiles;
- entire burst costs **one AR2 primary-ammo unit**.

**.357 Magnum**
- exploding `1d12` on natural **8–12**;
- aligned penetration escalates cumulatively by one fresh exploding d12 chain per deeper target: `1d12!`, `2d12!`, `3d12!`, etc.;
- eight-target cap;
- authoritative geometry stops penetration.

**Shotgun**
- shared damage `1d6!`, floor 3 per damage die;
- natural 6 only explodes;
- **8 guaranteed pellets**;
- separate exploding `1d6!` additional-pellet roll;
- every connecting pellet deals at least **1 damage**;
- final trace count capped at 36;
- one **4× ordinary hit stun** per target per shell;
- **168-unit nominal pushback** once per target per shell;
- pellet count never multiplies stun, push, or wall-crush rolls.

**Grenade**
- `1d20`
- separate consumable reward.

Player-side exploding dice share one bounded audiovisual confirmation cue.

---

## Basic Magic / Force Shout — IMPLEMENTED

- personal Magic resource 0–100;
- blue Suit-style HUD slot beside Health;
- 0→100 regeneration over 60 seconds while alive;
- RMB globally reserved for Magic; firearms expose no HL2-style secondary fire;
- Force Shout costs 30 Magic;
- unobstructed ~60° / 1100-unit cone;
- independent exploding `2d6` per hostile;
- 336-unit shared-authority push to survivors.

---

## Generic push / wall crush — IMPLEMENTED

`LOD.Pushback` is the reusable authority for Shotgun, Force Shout, and future displacement effects.

- bounded collision resolution;
- cannot push through walls/gates/jail doors;
- architectural blockage can add one `1d3` wall-crush roll;
- wall crush has distinctive audiovisual feedback;
- push travel uses bounded 4–16 body-ghost trails from reusable leased clientside render models.

---

## Peer-firearm design — ACCEPTED

Shotgun, SMG, Magnum, and AR2 are peers rather than power tiers.

- all available from Dungeon 1;
- equal randomized firearm acquisition weighting;
- Level 1 guarantees two distinct upgrades selected from the four;
- join-in-progress catch-up grants two deterministic distinct firearms from the same pool;
- contextual ammo-family selection is driven by depletion rather than hidden rarity;
- Grenades remain separate consumables.

---

## Production LootDirector — IMPLEMENTED

LootDirector owns individualized static supplies, individualized seeded enemy drops, useful-drop pity protection, extra-life behavior, Level-1 firearm access, contextual HP/ammo support, join-in-progress catch-up, and sector resource-budget validation.

LOD does not use HL2's auxiliary suit/armor pool.

---

## Current hostile health / ordinary melee

- Deadcrab health `2d4+1`
- Runner health `3d4+3`; melee `2d4+2`
- Shambler health `4d4+5`; melee `3d4+8`
- Soldier / Blitzer health `4d4+5`
- Bio Blaster health `5d4+6`

Visible hostile size remains monotonic durability information.

---

## Finite ammo

- Pistol 54 cap / 18 floor / 60 s empty-to-floor
- Shotgun 18 / 6 / 90 s
- SMG 135 / 45 / 120 s
- AR2 90 / 30 / 150 s
- .357 18 / 6 / 180 s

Shared 4 Hz server timer remains the regeneration authority. Grenades do not regenerate.

---

## Minimap architecture — ACCEPTED

Production minimap has one canonical server module and one canonical client module.

- static current-floor topology is cached in one reusable 256×256 render target rather than redrawn every HUD frame;
- dynamic overlays remain live;
- client floor/stair/gate/jail indexes and adjacency are built once per topology reception;
- route BFS is cached by player cell + relevant progression state;
- same-level reopen does not retransmit topology;
- request mismatch recovery is throttled;
- no per-frame maze-origin polling or server level-reset scans.

`lod_minimap_cache_status` remains available as a lightweight manual regression check.

---

## Gate D — Expanded Enemy Roster — CURRENT

Implement and runtime-accept one enemy at a time in this order:

`Watcher → Seeker → Sentry → Razor → Flamer → Big Crab → Arc Caster → Lurker → Beam Sweeper`

### Gate D working rule

For each enemy:

1. Read its exact GDD contract before coding.
2. Reuse existing graph/motion/ballistics/presentation authorities wherever possible.
3. Add no competing locomotion, trajectory, LOS, or global-scan architecture.
4. Keep low-end work bounded and event-driven.
5. Push one implementation milestone.
6. Give one decisive runtime acceptance test.
7. Do not proceed to the next archetype until the current one is accepted.

The **Watcher** is next.

Do not regress the immutable Soldier shot contract.

---

## Gate E — Remaining Milestone 4 Expedition

After Gate D:

- Brute + Neil / production Map acquisition for applicable dungeon tiers;
- cross-level economy/persistence hardening;
- broader complete-dungeon attrition and low-end soak testing;
- remaining approved pre-release presentation work.

Production loot itself is no longer future work.

---

## Gate F — Gordon the Warden

Implement the reserved final arena and Warden phases only after prior gates are stable. Warden death must feed the already-proven production Jail Key → jail door → Deborah rescue pipeline.

---

## Gate G — Multiplayer / Release Candidate

Preserve multiplayer-compatible server authority now; perform dedicated 1–4-player joins/rejoins, individualized-resource, wipe/respawn, intermission, dedicated-server, and long-campaign validation after the single-player game is stable.

## Architecture invariants

1. Canonical generated 3D graph remains topology/progression/routing/minimap authority.
2. Physical geometry agrees with graph.
3. Motion V2 is sole production hostile ground-motion authority.
4. Validated stairs are sole ordinary hostile elevation route.
5. Soldier shot line is immutable from beam-on; animation bones/client scale are never trajectory authorities.
6. Generated geometry remains authoritative cover for ordinary bullets and Magnum penetration.
7. Pushback uses the shared collision-safe authority; future elemental/weapon pushes reuse it.
8. d6 explosion threshold is universally natural 6; d12 explosion threshold is universally natural 8–12.
9. Visible hostile size remains monotonic durability information.
10. Networking/graph work remains compact, cached, bounded, and low-end-safe.
11. Minimap has one canonical server module and one canonical client module; static topology is cached rather than redrawn/retransmitted per frame/open.
12. No per-frame global BFS or large entity scans.
13. Automatic startup telemetry remains retired.
14. Work one decisive runtime acceptance criterion at a time.
