# Development Status

## Current execution phase
Vertical Slice Completion Gate — between core Milestone 3 stabilization and the Milestone 4 dice-combat foundation.

**Implementation authority at audit start:** `d05c145348aadf6bfd99caf9a53a41f43a2b16a2` (`main`).

The repository had materially outgrown its old status document. Milestone 2 is no longer awaiting first runtime validation: the project now has live progression, a production minimap stack, graph-authoritative hostile motion, multiple ranged/melee archetypes, encounter/wandering systems, hit/death feedback, generated-geometry ballistics, low-end runtime optimization, and the accepted immutable Soldier shot contract.

## Accepted / established systems

### Milestone 1 — The Labyrinth
Accepted implementation checkpoint. Deterministic multi-layer generation, canonical graph connectivity, generated container/floor/stair geometry, regeneration, and representative Steam Deck generation performance are established. The 1,000-seed logical validation checkpoint remains recorded in `docs/M1_TEST_REPORT.md`.

### Milestone 2 — The Three Keys
Substantially implemented and runtime-tested in representative progression tests:

- deterministic ordered Red → Blue → Yellow keycard/gate planning;
- progression-safe gate edges and validated objective pockets;
- permanent gate opening and checkpoint advancement;
- team card/gate state and Source-style objective HUD;
- lives, death/spectate/respawn, elimination/comeback, and session-local player state;
- provisional Deborah touch rescue and next-level intermission path;
- canonical M-toggle minimap architecture with gate-aware topology and current-floor routing support.

The remaining Milestone-2 debt is no longer isolated feature validation; it is **end-to-end dungeon-loop validation** under the current hostile/optimization architecture.

### Milestone 3 — The Hostiles / runtime architecture
Established implementation includes:

- `MazeNavigator`, `FactionManager`, deterministic encounter planning/activation, wandering population, hostile separation, and encounter/spawn variance;
- Motion V2 as the sole production ground-movement authority over canonical graph waypoints;
- Shambler, Runner, Soldier, Deadcrab, Bio Blaster, and the Soldier-derived Blitzer path;
- deterministic 0.33x–1.33x client-rendered hostile size variance with server-authoritative stat consequences;
- generated-geometry LOS/ballistic cover enforcement;
- player hit confirmation, hit stun, hurt/death pose/audio presentation, and scaled-hostile combat-hull fallback;
- bounded/optimized low-end runtime systems, including minimap caching/serialization and Phase Zero hot-path reductions;
- Soldier warning/burst trajectory fixed on 2026-08-24 by one immutable server-authored world-space shot contract; live testing accepted the warning origin, frozen aim, and bolt colinearity.

## Immediate development gate: completable dungeon

Do **not** resume broad enemy-roster expansion yet. First produce and validate a complete single-player dungeon loop:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Core/Jail Key → Deborah jail door → Deborah touch rescue → intermission → next generated level`

Requirements:

1. The entitled minimap marks the **current** mandatory progression objective and supplies a complete canonical-graph breadcrumb that respects live gate state and vertical transitions.
2. Keycard stages breadcrumb to the currently required card; card acquisition retargets the route to its matching gate.
3. After Yellow Gate, a deterministic temporary Core stand-in provides the production Jail Key. No Warden fight is implemented at this checkpoint.
4. The Jail Key, Deborah jail-door lock/unlock state, rescue eligibility, and level-clear path must be production-compatible. Milestone 5 will replace only the key's source with Gordon the Warden's death/drop.
5. Deborah cannot clear the level before the jail door has been legally unlocked.
6. The complete loop must survive several no-teleport, no-progression-cheat playthroughs on different seeds before this gate is accepted.

## Next major system after the vertical slice

After a small baseline set of complete fixed-damage dungeon runs, implement the **v1 dice-combat foundation before further roster breadth**. This avoids balancing Watcher/Seeker/Sentry/etc. against a fixed-damage/fixed-HP economy already scheduled for replacement.

The v1 dice foundation comprises the GDD-defined weapon dice, Magnum exploding d12, Shotgun shared exploding/floored d6 and bonus pellets, authoritative bounded combat-roll feed, three-reload ammo capacities with die-scaled regeneration timing, and deterministic enemy health dice with monotonic visible-size/durability behavior.

XP, character leveling, procedural equipment/affixes, elemental progression, Magic, Luck Ring, and the broader RPG layer remain post-release.

## Deferred until after dice foundation

- remaining expanded normal roster: Watcher → Seeker → Sentry → Razor → Flamer → Big Crab → Arc Caster → Lurker → Beam Sweeper;
- production Brute + Neil Map-guardian encounter and ordinary Map acquisition flow (developer mode may auto-entitle the same production map behavior meanwhile);
- broader Milestone-4 loot/resource economy;
- Gordon the Warden combat and final presentation;
- dedicated multiplayer integration and multiplayer-specific QA, which remain Milestone 6.

## Preserved hard constraints

- `gm_flatgrass` remains the required base map.
- The canonical logical graph remains authoritative for maze topology, progression validation, routing, and generated-world interpretation.
- Motion V2 remains the sole production hostile ground-motion authority.
- Do not restore retired competing locomotion/recovery layers.
- Soldier warning/projectile geometry remains governed by the immutable shot contract; do not reconstruct its trajectory from live client/server bones.
- Preserve the validated low-end architecture: compact/chunked network state, cached minimap work, bounded ballistic queries, client-side visual scaling/batching, and developer-only heavy audit modules.
- Multiplayer-aware server authority may remain in code, but active multiplayer development/testing waits until the full single-player experience is complete through Milestone 5.
