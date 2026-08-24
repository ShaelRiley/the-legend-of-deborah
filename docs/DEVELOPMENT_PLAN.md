# Development Plan — 2026-08-24 Reconciliation

This execution plan reconciles the live GDD with the actual `main` implementation after the low-end optimization work and Soldier shot-contract repair.

## Execution principle

Milestone numbers describe capability groups; they are not rigid chronological gates when a later foundational system would otherwise invalidate earlier tuning work.

Current order:

1. Complete single-player dungeon vertical slice.
2. Run several complete fixed-damage baseline dungeons.
3. Implement and balance the v1 dice-combat foundation.
4. Resume remaining expanded hostile roster.
5. Finish the rest of the single-player expedition/economy.
6. Implement Gordon the Warden and production final sequence.
7. Integrate/test multiplayer last.

---

## Gate A — Complete Dungeon Vertical Slice

### Target loop

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → Deborah jail door → Deborah → level clear → next generated level`

There is **no Warden combat yet**. The temporary Core key source is a development substitute only.

### A1. Expand authoritative progression state

Replace the current seven-stage progression with explicit legal states sufficient for the final rescue pipeline:

1. FIND RED KEYCARD
2. OPEN RED GATE
3. FIND BLUE KEYCARD
4. OPEN BLUE GATE
5. FIND YELLOW KEYCARD
6. OPEN YELLOW GATE
7. TAKE JAIL KEY
8. UNLOCK DEBORAH'S CELL
9. RESCUE DEBORAH

The state machine, not entity proximity alone, owns legality. Invalid/out-of-order pickup, gate, jail-door, and Deborah-touch events must do nothing useful.

### A2. Reserve a real jail edge

The current planner uses the last two critical-path cells as `CoreCell` and `DeborahCell`. Make the edge between them an explicit `JailEdge` and validate it before level commitment.

Prefer/require a horizontal door-compatible edge. If the final critical-path edge is unsuitable, deterministically choose/reserve another valid final horizontal edge or reject/retry the layout. Do not bolt an ad-hoc door onto an incompatible vertical transition.

Progression validation must model the jail edge as locked until the Jail Key is legally used. Ordered solvability becomes:

`Start → Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → Jail Door → Deborah`

### A3. Implement production-compatible Jail Key

Create one authoritative Jail Key state/entity. At this checkpoint it is deterministically placed/spawned in the Core after Yellow Gate becomes legally open/reachable.

The future Warden implementation must call the same grant/spawn path. Milestone 5 is allowed to replace **only the source of the key**, not its ownership semantics, map target, jail-door interaction, Deborah eligibility, or level-clear logic.

### A4. Implement Deborah jail door

Create a distinct final jail-door/gate entity on `JailEdge`:

- physically blocks Deborah before legal unlock;
- is not one of the three colored progression gates;
- requires team Jail Key state and progression stage 8;
- permanently opens/unlocks for the level;
- advances the objective to RESCUE DEBORAH;
- survives death/checkpoint respawn exactly like colored-gate progression;
- is cleaned/recreated with the generated level.

### A5. Harden Deborah rescue legality

`lod_deborah` may trigger level clear only when:

- player is a living active participant;
- Jail Key has been acquired;
- jail door has been legally opened;
- progression stage is RESCUE DEBORAH;
- level is not failed/already cleared.

Preserve the existing minimum intermission and deterministic next-level rebuild path.

### A6. Convert minimap into progression navigation

Keep the existing entitlement model:

- production: no map by default; future Brute + Neil encounter grants the team Map for the current level;
- development: developer mode auto-entitles map access without creating a second navigation implementation.

Once entitled, the map must mark **only the currently active mandatory objective**, progressively revealing Red Card, Red Gate, Blue Card, Blue Gate, Yellow Card, Yellow Gate, Jail Key, jail door, and Deborah.

Do not reveal later locked-stage objectives all at once. Do not reveal enemies, ordinary loot, or encounters.

### A7. Replace stair-only breadcrumb with full 3D objective routing

The client already receives compact canonical topology and gate encoding. Extend that architecture rather than sending the whole graph again.

The breadcrumb must:

- start from the player's current canonical graph cell;
- terminate at the current objective cell/edge;
- traverse horizontal and vertical graph edges;
- treat unopened colored gates and the locked jail edge as blocked;
- choose the actual legal stair sequence when the objective is on another floor;
- display the route segment relevant to the player's current floor;
- recompute when player cell/floor, gate/jail state, objective stage/target, or map revision changes;
- remain cached between those changes, never BFS/A* every paint frame.

Prefer compact objective metadata (stage/type + cell coordinates or edge endpoints) over generic state transmission.

### A8. Vertical-slice runtime acceptance

Validate one thing at a time. Final Gate-A acceptance requires complete runs without progression teleports/cheats:

- one full dungeon on an ordinary generated seed;
- at least two additional different seeds;
- breadcrumb never points through a locked gate or wrong stair;
- each objective marker changes at the exact legal transition;
- keycards/gates/checkpoints persist through death;
- Jail Key cannot be obtained early;
- Deborah cannot be reached/rescued early;
- rescue enters intermission and Level N+1 builds successfully;
- no new Steam Deck performance regression attributable to map routing or final progression entities.

---

## Gate B — Baseline Full-Run Observation

Before changing combat mathematics, complete a small set of whole dungeons with the current fixed-damage system and record qualitative/diagnostic baseline data:

- completion time;
- deaths/lives pressure;
- ammo state by sector;
- mandatory fights that feel disproportionately slow/cheap;
- hostile counts and obvious performance spikes;
- whether the breadcrumb produces excessive backtracking or trivializes spatial comprehension.

This is a baseline, not a long balancing pass. Do not spend weeks perfecting fixed-damage tuning that Gate C will replace.

---

## Gate C — v1 Dice-Combat Foundation

Implement before the remaining expanded enemy roster so future archetypes are built against the shipping combat economy.

### C1. One server-authoritative roll service

Create a bounded authoritative combat-roll pipeline used by player weapon damage and later enemy-health generation. Do not let individual SWEP callbacks independently invent dice semantics.

Network compact resolved roll events for presentation; clients never decide damage.

### C2. Combat-roll feed

Implement the GDD-defined bounded Neverwinter-Nights-style lower-right roll feed. It must display resolved authoritative rolls, including grouped explosion chains, without an unbounded message history or expensive per-frame reconstruction.

### C3. Convert straightforward weapon families first

Introduce and runtime-validate the simple baselines before special cases:

- Crowbar/melee: d8
- Pistol: d4
- SMG: d8
- AR2: d10
- Grenade: d20

### C4. Magnum

Implement the authoritative d12 rule exactly as the GDD specifies:

- natural 10, 11, or 12 explodes;
- each explosion adds another d12;
- added dice may themselves explode;
- keep later Luck Ring advantage hooks architecturally possible, but **do not implement Luck Ring/Magic yet**.

### C5. Shotgun

Implement the GDD shell contract as one coherent roll event:

- six guaranteed pellets;
- independent 33% chances for pellets 7, 8, and 9;
- shared d6 shell damage rule;
- floor results below 3 up to 3;
- only a natural kept 6 explodes;
- explosion chains follow the GDD contract;
- apply the shotgun's 2x hit-stun duration after shell damage aggregation as specified.

### C6. Ammunition economy

Align maximum carried ammunition and regeneration with the GDD dice identities:

- capacity = three reload-equivalents;
- 33% regeneration floor = one reload-equivalent;
- zero-to-floor regeneration timing: Pistol 60s, Shotgun 90s, SMG 120s, AR2 150s, Magnum 180s.

Preserve the rule that regeneration is a floor, not free continuous replenishment above that threshold.

### C7. Enemy health dice

Replace the temporary flat HP + independent HP jitter model with deterministic health-dice generation while preserving the crucial visual contract:

**larger visible enemies must never become less durable than smaller otherwise-comparable enemies because of an unlucky roll.**

Derive health from deterministic enemy identity/seed and make size a monotonic durability cue. Do not stack the old ±8% HP jitter on top unless the GDD explicitly retains a bounded role for it after conversion.

### C8. Dice full-run balance gate

Repeat complete dungeons across several seeds. Tune by hits-to-kill, encounter duration, ammo pressure, and dodge/readability rather than isolated expected-value arithmetic alone.

Gate C passes only when the dice version is at least as legible and completable as the fixed-damage baseline.

---

## Gate D — Resume Enemy Roster Breadth

After dice combat is authoritative, continue the remaining normal roster in GDD order:

`Watcher → Seeker → Sentry → Razor → Flamer → Big Crab → Arc Caster → Lurker → Beam Sweeper`

Each archetype must pass its systemic niche, placement, counterplay, graph navigation, death/hit feedback, dice-era durability, and low-end performance tests before moving to the next.

Do not regress the accepted Soldier shot contract while reusing Soldier/Blitzer/Neil projectile infrastructure.

---

## Gate E — Complete Milestone 4 Expedition

After core dice and roster stability:

- production Brute + Neil Map encounter and team-global Map pickup;
- full weapon/resource placement;
- individualized drops/pickups;
- pity protection;
- rare extra-life behavior;
- ammo/health/armor economy validation;
- cross-level inventory persistence;
- complete-dungeon attrition tuning and low-end soak testing.

---

## Gate F — Milestone 5: Gordon the Warden

Only now replace the temporary Core Jail Key source with the real final encounter:

- final arena reservation/presentation;
- Warden fight/phases/state persistence;
- Warden death grants/drops the already-proven Jail Key;
- existing jail-door and Deborah pipeline remains unchanged;
- boss HUD/music/resupply/celebration/final sequence per GDD.

---

## Gate G — Multiplayer Integration / Release Candidate

Dedicated multiplayer work remains last. Preserve multiplayer-compatible server authority now, but defer multiplayer-specific debugging until the complete single-player game is stable through the Warden.

Then validate 1–4 players, joins/rejoins, active slots, spectator-only connections, individualized pickups, wipes, respawns, intermissions, dedicated servers, long campaign sequences, and release-candidate performance/deadlock criteria.

---

## Architecture invariants

1. Canonical maze graph is the topology/progression/routing authority.
2. Motion V2 is the sole production hostile ground-motion authority.
3. Generated geometry remains authoritative cover/collision and must not be bypassed by alternative traces.
4. Soldier warning + ordinary Soldier bolts share one immutable server-authored shot line; no live bone reconstruction may become trajectory authority again.
5. Hostile visual size is client-rendered; gameplay systems must not assume server studio-bone positions equal the rendered scaled model.
6. Minimap remains compact/chunked and cached; objective guidance must not reintroduce per-frame graph traversal.
7. Ballistic/player searches remain bounded by proximity/segment broad phases.
8. Heavy audits/test modules remain developer-only where current Phase Zero architecture has separated them from production runtime.
9. Every generated entity belongs to level cleanup and regeneration must remain idempotent.
10. Work one runtime acceptance criterion at a time and commit working milestones directly to `main`.
