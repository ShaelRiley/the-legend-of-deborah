# Development Plan — 2026-08-25 Dice-Era Reconciliation

The live GDD is design authority; GitHub `main` is implementation authority. Milestone numbers describe capability groups, while the current execution gate follows accepted runtime evidence.

## Current order

1. **Complete and tune Gate C8 whole-dungeon dice play.**
2. Make only evidence-driven combat/economy corrections required by authentic runs.
3. Resume the remaining expanded normal-enemy roster.
4. Finish remaining Milestone-4 expedition work, especially Brute + Neil / Map acquisition and broader attrition/soak validation.
5. Implement Gordon the Warden while preserving the proven Jail Key → jail door → Deborah pipeline.
6. Integrate/harden multiplayer last.

Production LootDirector is already implemented. Do not schedule it again as future work.

XP, character levels, procedural equipment/affixes, elements, Magic, Luck Ring, and the broader RPG layer remain deferred post-release systems.

---

## Gate A — Complete Dungeon Vertical Slice — ACCEPTED

The production progression loop is established:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah → level clear → intermission → next generated level`

Do not reopen without new regression evidence.

---

## Gate C — v1 Dice Combat / Current Balance Gate

### Combat roll authority / feed — IMPLEMENTED

`sv_combat_rolls.lua` owns authoritative player/hostile dice and hostile health rolls. `cl_combat_roll_feed.lua` presents bounded attributed results such as:

`ShaelRiley dealt 1d4 (3) damage to Shambler, via pistol`

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
- exploding `1d12`;
- natural 10/11/12 recursively explode;
- one cartridge regardless of chain length;
- the bullet **penetrates multiple properly aligned hostiles**, carrying the same resolved exploding-d12 total through each body until blocking world/generated geometry or another solid obstruction stops the line;
- penetration work is bounded.

**Shotgun**
- one shared `1d6` per shell;
- floor each die below 3 to 3 for contribution;
- natural **5 or 6 recursively explodes**;
- six guaranteed pellets plus independent 33% chances for pellets 7/8/9;
- aggregate once per damaged target;
- one **4× ordinary hit stun** per damaged target per shell (nominal 1.20 s);
- **168-unit nominal pushback** once per target per shell;
- pellet count never multiplies stun, push, or wall-crush rolls.

**Grenades**
- `1d20`;
- separate nonregenerating consumable rewards.

### Generic push / wall crush — IMPLEMENTED

`LOD.Pushback` is the reusable authority for Shotgun and future weapon/element/environmental displacement.

- bounded collision resolution;
- cannot push through walls/gates/jail doors;
- actual architectural blockage causes one additional `1d3` wall-crush roll per push event;
- wall crush has a distinctive spatial heavy-impact + crunch cue;
- open cell boundaries do not count as walls merely because a cell edge is crossed.

### Peer-firearm design goal — IMPLEMENTED, RUNTIME VALIDATION PENDING

Shotgun, SMG, Magnum, and AR2 are **peers, not power tiers**.

- all four can appear from Dungeon 1;
- randomized firearm acquisition weights them equally;
- Level 1 guarantees two distinct upgrades uniformly selected from those four rather than fixed Shotgun + SMG;
- join-in-progress catch-up grants two deterministic distinct firearms from the same pool;
- contextual ammo-family selection is driven by depletion rather than hidden weapon rarity;
- Grenades remain separate consumables.

The balance objective is **equal viability through distinct mechanics**, not equal damage-per-trigger and not a stronger/weaker rarity ladder.

### Production LootDirector — IMPLEMENTED

LootDirector owns:
- individualized static supplies;
- individualized seeded enemy drops;
- useful-drop pity protection;
- extra-life behavior;
- Level-1 firearm access;
- contextual HP/ammo support;
- join-in-progress catch-up;
- sector resource-budget validation.

LOD does not use HL2's auxiliary suit/armor pool. Former armor rewards restore ordinary HP instead.

### Hostile damage retune — IMPLEMENTED / RUNTIME VALIDATION PENDING

Authentic runs showed unacceptable ordinary melee spikes. Current formulas before existing size/stat scaling:

- Shambler `3d4+8` (11–20 unscaled)
- Runner `2d4+2` (4–10 unscaled)

Do not compensate by endlessly raising healing before evaluating these new formulas in whole-dungeon play.

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

Run ordinary complete dungeons and judge the integrated experience. Observe:

- progress/completion time against the Level-1 20–35 minute target;
- deaths/lives;
- outgoing and incoming lethality;
- sustain and ammunition pressure through progression;
- whether all four acquired guns feel worth using for different reasons;
- Shotgun 5–6 explosions / 4× stun / 168 push / wall crush;
- AR2 three-projectile burst consuming one ammo unit;
- Magnum penetration through aligned hostiles without penetrating maze geometry;
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
8. Visible hostile size remains monotonic durability information.
9. Networking/graph work remains compact, cached, bounded, and low-end-safe.
10. No per-frame global BFS or large entity scans.
11. Automatic startup telemetry remains retired.
12. Work one decisive runtime acceptance criterion at a time.
