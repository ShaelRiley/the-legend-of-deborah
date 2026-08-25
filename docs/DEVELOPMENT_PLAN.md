# Development Plan — 2026-08-25 Dice-Era Reconciliation

The live GDD is design authority; GitHub `main` is implementation authority. Milestone numbers describe capability groups, while the current execution gate follows accepted runtime evidence.

## Current order

1. **Complete and tune Gate C8 whole-dungeon dice play.**
2. Validate the newly reconciled Shotgun under the universal d6 rule: natural-6-only damage explosions plus the separate exploding additional-pellet d6.
3. Make only evidence-driven combat/economy corrections required by authentic runs.
4. Resume the remaining expanded normal-enemy roster.
5. Finish remaining Milestone-4 expedition work, especially Brute + Neil / Map acquisition and broader attrition/soak validation.
6. Implement Gordon the Warden while preserving the proven Jail Key → jail door → Deborah pipeline.
7. Integrate/harden multiplayer last.

Production LootDirector is already implemented. Do not schedule it again as future work.

A limited pre-release Magic subsystem is now implemented: Magic meter, global RMB ownership, and Force Shout. XP, character levels, procedural equipment/affixes, elements, Luck Ring, Magic items, and the broader RPG Magic layer remain deferred.

---

## Gate A — Complete Dungeon Vertical Slice — ACCEPTED

The production progression loop is established:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah → level clear → intermission → next generated level`

Do not reopen without new regression evidence.

---

## Gate C — v1 Dice Combat / Current Balance Gate

### Universal exploding-die rule — CANONICAL GDD CONTRACT

Explosion thresholds are global dice-system invariants:

- **Every d6 rolled anywhere in LOD recursively explodes only on a natural 6.**
- **Every d12 rolled anywhere in LOD recursively explodes on a natural 8, 9, 10, 11, or 12.**
- Future d6/d12 mechanics inherit these rules automatically unless a later explicit design change supersedes them.

Current code is compliant for Force Shout, both Shotgun d6 systems, and Magnum/Magnum-pierce d12s.

### Combat roll authority / feed — IMPLEMENTED

`sv_combat_rolls.lua` owns authoritative player/hostile dice and hostile health rolls. `cl_combat_roll_feed.lua` presents bounded attributed results such as:

`ShaelRiley dealt 1d4 (3) damage to Shambler, via pistol`

Player-side exploding dice also trigger one bounded celebratory audiovisual confirmation near the center of the HUD. This shared cue is used by Magnum, Shotgun damage/pellet dice, Force Shout, and Magnum-pierce bonus dice.

### Current weapon identities

**Crowbar**
- `1d3`
- dedicated LOD SWEP
- 96-unit reach
- accepted miss/hit audio + hit-confirm.

**Pistol**
- `1d4`
- starts with 18 loaded / 0 reserve.

**SMG**
- `1d8`
- six rapid shots overheat;
- one heat cools every 0.25 s below threshold;
- 2.0 s overheat lock;
- model heat/glow, smoke, and staged audio feedback.

**AR2**
- `1d10` per projectile;
- every activation begins a 0.45 s committed targeting-laser tell;
- exactly three rapid projectiles follow the committed line;
- unrestricted automatic fire remains suppressed;
- **the entire three-projectile burst consumes one AR2 primary-ammo unit total**, spent only when the first projectile releases.

**.357 Magnum**
- universal exploding `1d12`;
- natural **8/9/10/11/12** recursively explode;
- one cartridge regardless of chain length;
- a bullet penetrates properly aligned hostiles while authoritative world/generated geometry remains blocking;
- target depth escalates cumulatively by one fresh independently exploding d12 chain: target 1 `1d12!`, target 2 `2d12!`, target 3 `3d12!`, etc., through the bounded eight-target cap.

**Shotgun**
- one shared damage `1d6!` per shell;
- floor each damage die below 3 to 3 for contribution;
- natural **6 only** recursively explodes under the universal d6 rule;
- six guaranteed pellets;
- every trigger pull rolls a separate exploding `1d6!` for additional pellets, with no damage floor because this die represents pellet count;
- after that pellet die, retain the existing three independent 33% bonus-pellet checks;
- cap final pellet traces at 36 as a low-end anti-runaway safeguard;
- aggregate damage once per damaged target;
- one **4× ordinary hit stun** per damaged target per shell (nominal 1.20 s);
- **168-unit nominal pushback** once per target per shell;
- pellet count never multiplies stun, push, or wall-crush rolls;
- floored shared damage d6 expected contribution before explosions = 4.0;
- recursive shared exploding-d6 expected total = **4.8**;
- exploding pellet-count d6 expected contribution = **4.2 extra pellets**;
- including the three 33% checks, uncapped average pellet count = **11.2**;
- expected full-connect base damage = approximately **8.96** before later modifiers and rare cap truncation.

### Basic Magic / Force Shout — IMPLEMENTED

- personal Magic resource 0–100;
- blue Suit-style HUD slot immediately beside Health;
- regeneration from 0→100 over 60 seconds while alive;
- RMB is globally reserved for Magic; LOD firearms expose no HL2-style secondary-fire gameplay;
- Force Shout costs 30 Magic;
- unobstructed ~60° / 1100-unit cone;
- independent exploding `2d6` per hostile using the universal natural-6 d6 threshold;
- 336-unit shared-authority push to survivors;
- expanding force-wave presentation, character-profiled shout, body-ghost push trails, and wall-crush audiovisual feedback.

### Generic push / wall crush — IMPLEMENTED

`LOD.Pushback` is the reusable authority for Shotgun, Force Shout, and future weapon/element/environmental displacement.

- bounded collision resolution;
- cannot push through walls/gates/jail doors;
- actual architectural blockage causes one additional `1d3` wall-crush roll per push event;
- wall crush has distinctive spatial audio and impact particles;
- push travel is shown with a bounded 4–16 body-ghost trail using reusable leased clientside render models;
- open cell boundaries do not count as walls merely because a cell edge is crossed.

### Peer-firearm design goal — IMPLEMENTED, RUNTIME VALIDATION ONGOING

Shotgun, SMG, Magnum, and AR2 are **peers, not power tiers**.

- all four can appear from Dungeon 1;
- randomized firearm acquisition weights them equally;
- Level 1 guarantees two distinct upgrades uniformly selected from those four rather than fixed Shotgun + SMG;
- join-in-progress catch-up grants two deterministic distinct firearms from the same pool;
- contextual ammo-family selection is driven by depletion rather than hidden weapon rarity;
- Grenades remain separate consumables.

The balance objective is **equal viability through distinct mechanics**, not equal damage-per-trigger and not a stronger/weaker rarity ladder.

### Production LootDirector — IMPLEMENTED

LootDirector owns individualized static supplies, individualized seeded enemy drops, useful-drop pity protection, extra-life behavior, Level-1 firearm access, contextual HP/ammo support, join-in-progress catch-up, and sector resource-budget validation.

LOD does not use HL2's auxiliary suit/armor pool. Former armor rewards restore ordinary HP instead.

### Hostile damage retune — IMPLEMENTED

Current formulas before existing size/stat scaling:

- Shambler `3d4+8` (11–20 unscaled)
- Runner `2d4+2` (4–10 unscaled)

### Health dice

- Deadcrab `2d4+1`
- Runner `3d4+3`
- Shambler / Soldier / Blitzer `4d4+5`
- Bio Blaster `5d4+6`

Visible size remains a monotonic durability cue.

### Finite ammo

Combined loaded + reserve cap / one-load floor / empty-to-floor recovery:

- Pistol 54 / 18 / 60 s
- Shotgun 18 / 6 / 90 s
- SMG 135 / 45 / 120 s
- AR2 90 / 30 / 150 s
- .357 18 / 6 / 180 s

Shared 4 Hz server timer remains the regeneration authority. Grenades are excluded.

### C8 — CURRENT ACCEPTANCE GATE

Continue ordinary complete-dungeon play and judge the integrated experience. Observe:

- progress/completion time against the Level-1 20–35 minute target;
- deaths/lives;
- outgoing and incoming lethality;
- sustain and ammunition pressure through progression;
- whether all four peer firearms feel worth using for different reasons;
- AR2 three-projectile burst consuming one ammo unit;
- Magnum 8–12 explosions and escalating aligned penetration;
- Shotgun natural-6 damage explosions plus exploding additional-pellet d6, including whether unusually large pellet bursts remain readable and performant;
- exploding-die audiovisual readability;
- Magic meter / Force Shout readability and balance;
- push/body-ghost/wall-crush presentation;
- Shambler/Runner melee after spike reduction;
- combat-feed readability;
- Steam Deck performance;
- eventual Deborah rescue/intermission/next level.

Tune from runtime evidence, not expected-value arithmetic alone.

---

## Gate D — Expanded Enemy Roster — BLOCKED ON C8

After C8 is accepted, continue:

`Watcher → Seeker → Sentry → Razor → Flamer → Big Crab → Arc Caster → Lurker → Beam Sweeper`

Do not regress the immutable Soldier shot contract.

---

## Gate E — Remaining Milestone 4 Expedition

Remaining work after combat/roster stability includes:
- Brute + Neil / Map acquisition for applicable dungeon tiers;
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
8. d6 explosion threshold is universally natural 6; d12 explosion threshold is universally natural 8–12.
9. Visible hostile size remains monotonic durability information.
10. Networking/graph work remains compact, cached, bounded, and low-end-safe.
11. No per-frame global BFS or large entity scans.
12. Automatic startup telemetry remains retired.
13. Work one decisive runtime acceptance criterion at a time.
