# Development Plan — 2026-08-25 Post-C8

The live GDD is design authority; GitHub `main` is implementation authority. Milestone numbers describe capability groups, while the current execution gate follows accepted runtime evidence.

## Current order

1. **Gate D — Watcher runtime acceptance.** Watcher is implemented; validate its scan presentation, cancellation, wanderer alert behavior, and Steam Deck cost.
2. **Gate D — Seeker:** implement only after Watcher is accepted, then continue one archetype at a time through `Sentry → Razor → Flamer → Big Crab → Arc Caster → Lurker → Beam Sweeper`.
3. Continue ordinary whole-dungeon play with broad combat/economy balance frozen unless specific evidence demands a targeted change. The recently implemented Magnum identity mechanics remain available for regression observation during normal play but no longer block Gate D.
4. Finish remaining Milestone-4 expedition work, especially Brute + Neil / production Map acquisition and broader attrition/soak validation.
5. Implement Gordon the Warden while preserving the proven Jail Key → jail door → Deborah pipeline.
6. Integrate/harden multiplayer last.

Production LootDirector is already implemented. Do not schedule it again as future work.

A limited pre-release Magic subsystem is implemented: Magic meter, global RMB ownership, and Force Shout. XP, character levels, procedural equipment/affixes, elements, Luck Ring, Magic items, and the broader RPG Magic layer remain deferred.

---

## Gate A — Complete Dungeon Vertical Slice — ACCEPTED

The production progression loop is established:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah → level clear → intermission → next generated level`

Do not reopen without new regression evidence.

---

## Gate C8 — Complete-Dungeon Dice-Era Validation — ACCEPTED

Acceptance evidence includes an authentic run reaching **Level 5** before total-party wipe and the player's explicit assessment that the game is **fun, balanced, and playable**.

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
- **Every fresh d12 chain begins at natural 8–12.**
- Every successful d12 explosion lowers the next d12's threshold by one.
- Default d12 sequence: **8+ → 7+ → 6+ → 5+**, remaining at 5+ thereafter.
- **Boomchain Floor** is a shared exposed variable, default **5**; future Magic/items may lower it.
- Every new d12 chain resets to 8+ and descends independently toward the current Boomchain Floor.

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
- every projectile deals **`1d12!+X`**, with X equal to the number of chambers already empty before that trigger;
- a normal six-round cylinder progresses **+0,+1,+2,+3,+4,+5** and reload resets the sequence;
- trigger 5 fires a rapid **two-projectile** Magnum burst;
- trigger 6 fires a rapid **three-projectile** Magnum burst;
- below 60 current HP, each trigger makes one `(60-HP)%` chance check to add exactly one further free Magnum projectile;
- below 34% of maximum Health, the final-cartridge trigger has `floor(34-currentHealthPercent)%` chance to restore that cartridge after the complete burst;
- **each trigger pull consumes at most one cartridge regardless of total projectiles generated**; a successful final-cartridge preservation proc therefore produces zero net cartridge consumption for that trigger;
- **Aim State:** after 0.5 seconds of complete player-position and view-aim stillness, the Magnum arms with a gold muzzle-particle lock cue, short sound, and compact persistent `AIM x2` indicator;
- movement/aim change, weapon switch, or death cancels Aim State before firing;
- Aim State persists while perfectly still and is consumed by the next actual Magnum trigger;
- an aimed trigger deals **×2 damage across the complete trigger**, including every normal/chamber/low-health burst projectile, cylinder bonus, every projectile's d12 Boomchain, and every fresh Boomchain added by deeper pierced targets;
- aligned penetration adds one fresh independent Boomchain per deeper target;
- eight-target penetration cap;
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

The Magnum diagnostics (`lod_magnum_super_status`, `lod_magnum_aim_status`, `lod_magnum_pierce_status`) remain available for opportunistic regression checks during normal play. Magnum validation is no longer a prerequisite for continuing Gate D.

---

## Gate D — Expanded Enemy Roster — CURRENT

Build and runtime-accept one enemy at a time in this order:

`Watcher → Seeker → Sentry → Razor → Flamer → Big Crab → Arc Caster → Lurker → Beam Sweeper`

### Watcher — IMPLEMENTED / RUNTIME ACCEPTANCE CURRENT

The live GDD's Watcher contract is implemented without adding a new spawn or movement authority:

- Combine Scanner-derived support archetype;
- **no direct attack**;
- graph-bound Motion-V2 movement and validated stair/gate traversal;
- rare wandering eligibility;
- Sector-2+ `Surveillance = 1 Watcher + 2 Shamblers` authored encounter option;
- **1.25-second** visible scanning beam with escalating electronic cue;
- line-of-sight break cancels the scan;
- firearm hit-stun cancels the scan;
- successful scan broadcasts the target only to already-existing same-floor wanderers within **6 graph cells**;
- alerted wanderers immediately acquire the player but retain ordinary safe-zone, same-floor, and pursuit-leash rules;
- Watcher scan **never spawns reinforcements** and cannot bypass EncounterDirector threat budgets or the hostile safety ceiling;
- alert work iterates `WanderingDirector.Entities` and cached graph distance rather than performing a global entity scan;
- provisional dice-era durability is `3d4+3` because the live GDD does not specify a numeric Watcher health formula.

Presentation is event-driven client-side: active scans alone draw a pulsating cyan beam/glow. There is no per-frame search for Watchers.

### Watcher acceptance test

1. Enter an ordinary corridor outside spawn/checkpoint safe space.
2. Run `lod_watcher_test`.
3. Allow the full scan to complete without breaking line of sight or shooting the Watcher.
4. Confirm the cyan beam and escalating electronic cue are clear.
5. Run `lod_watcher_status`.
6. Accept Watcher when status shows at least one scan start, one completion, one alerted wanderer, and `result=PASS`, with no obvious Steam Deck performance regression.

The test intentionally attempts to place its alert-target Shambler **5–6 graph cells away**: outside the normal 4-cell wanderer acquisition radius but inside the Watcher's 6-cell broadcast radius. An alert therefore demonstrates Watcher behavior rather than ordinary acquisition.

### Gate D working rule

For every remaining archetype:

1. Read its exact live-GDD contract before coding.
2. Reuse existing graph/motion/ballistics/presentation authorities wherever possible.
3. Add no competing locomotion, trajectory, LOS, spawning, or global-scan architecture.
4. Keep low-end work bounded and event-driven.
5. Push one coherent implementation milestone.
6. Give one decisive runtime acceptance test.
7. Do not proceed to the next archetype until the current one is accepted.

**Seeker is next only after Watcher acceptance.**

Do not regress the immutable Soldier shot contract.

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
- Watcher health `3d4+3` **provisional implementation tuning**; no direct attack
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

## Gate E — Remaining Milestone 4 Expedition

After Gate D:

- Brute + Neil / production Map acquisition for applicable dungeon tiers;
- cross-level economy/persistence hardening;
- broader complete-dungeon attrition and low-end soak testing;
- remaining approved pre-release presentation work.

Production loot itself is no longer future work.

---

## Gate F — Gordon the Warden

Implement the reserved final arena and Warden phases only after prior gates are stable. Warden death must feed the already-proven production Jail Key → jail door → Deborah rescue pipeline rather than replacing it.

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
8. d6 explosions are universally natural-6; fresh d12 chains start at 8+ and descend one threshold per explosion toward the Boomchain Floor.
9. Boomchain Floor defaults to 5 and is exposed for future Magic/item modification.
10. Magnum Aim State uses bounded per-player input/state tracking only; do not replace it with a global entity scan or per-frame world trace.
11. Watcher scans may alert only already-live `WanderingDirector` wanderers; never create a Watcher-specific reinforcement or global-scan path.
12. Visible hostile size remains monotonic durability information.
13. Networking/graph work remains compact, cached, bounded, and low-end-safe.
14. Minimap has one canonical server module and one canonical client module; static topology is cached rather than redrawn/retransmitted per frame/open.
15. No per-frame global BFS or large entity scans.
16. Automatic startup telemetry remains retired.
17. Work one decisive runtime acceptance criterion at a time.
