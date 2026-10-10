# Recurring Favored Enemy identity pool — October 10, 2026

Published parent main: `b1e604b5d380492ff55de1c2c12eb22df911fa4c`.
The author's explicit direction removes boss-only targets and Nodule from future
Favored Enemy identity perks. Live GDD 00 → 01 → 04/05/07 was read. The exact
IdentityPerkDirector HUMAN anchor was inspected; normalized 04 LOD-ID-002 now
records the correction, with revision-guarded write and exact readback. The
verified revision and paragraph are in the adjacent evidence archive.

`sv_identity_perks.lua:TargetRegistries` now derives enemy targets from
nonobjective ordinary encounter compositions and the existing autonomous
wandering roster. Registering a boss, boss companion, unique hunt, event actor
or summon alone does not admit its model. The full Nodule/Barnacle family is
excluded, including Lurker's shared model. A recurring family remains eligible
when a boss also uses it. Model lineage resolution and combat handlers are
unchanged. Perk version stays v2, preserving saved records without rerolling;
the existing v1 upgrade still preserves original families, targets and stats.
Population, boss registrations, attacks, effects and graphics are unchanged.

The resulting pool has 14 model families: Zombie, Fast Zombie, Soldier,
Headcrab, Roller, Combine Scanner, Combine Super Soldier, Floor Turret, Manhack,
Metrocop, Stalker, Antlion, Vortigaunt and Slave Vortigaunt. All 23 loaded
boss/companion/unique-hunt archetypes have excluded model families in the current
roster. A synthetic shared boss lineage also verifies recurring-model retention.
The canonical manual and its five affected generated chunks agree.

11/11 bounded checks pass on the identical before/after 2,590-file snapshot
`fa24b5472b931339bf77edc42dea1df956c383f1e84c79f0791c87f74f8154ff`:

- Seven selected canonical suites: recurring identity pool, weakness/identity
  combat, Magic/progression schema, manual document/reader, portable manual,
  manual server transport and population evidence transport.
- The new pool gate rejects the unchanged published-parent selector. Production
  ordinary and modular-boss registrations supply the fixture. 1,500 new identity
  packages produce 1,497 Favored Enemy records, cover all 14 permitted families,
  match deterministic repeats and never select excluded models. Saved v2 and
  upgraded v1 Barnacle/Pigeon records remain exact.
- All 10 changed/new Lua files parse, installer shell syntax passes and patch
  whitespace is clean. Source coverage is 58 installed hashes / 54 population
  modules / unchanged 19 client-capture modules; the selector is verified through
  the existing server evidence cadence.

The first gate retained five stale 53-source assertions after extending the
transport fixture's manifest to 54. Its 10/11 receipt and failure stream are
preserved in the archive. The corrected final gate has no failing check and no
source changes during validation. This was a fixture count correction, not a
transport or gameplay repair. Previous completed full performance/control gates
were not repeated. All raw streams, frozen manifest, parent selector, scoped
patch, changed authorities, design readback and replay script are archived;
generated HTML reconstructs through `tools/build_manual.py` from the recorded
canonical book and unchanged builder.

Evidence archive SHA256:
`783627d8c7104355096d8781c83238e36442c26028c4ae9c7354372306cb1dd8`.

Native acceptance is pending. Fully quit/update/install main and restart GMod.
New characters use the filtered pool; existing characters keep saved perks.
The earlier double-click equipment and per-button Content changes remain in the
build and retain their outstanding native checks. Then use the current plan's
same-scene `lod_perf_compare 60` procedure on gm_flatgrass and return
`performance_client_latest.txt` + `console_latest.txt`. Exact sources, complete
profiles, idle VR, zero new Lua errors, unchanged appearance/gameplay and
sustained ≥40 FPS remain the native acceptance gate. No Workshop or VPS action.
