# Development Status — 2026-08-27 Multiplayer Priority

## Current execution phase

**MP-A — Multiplayer Lifecycle Hardening: IMPLEMENTED / AWAITING SINGLE-CLIENT RUNTIME REGRESSION.**

**Immediate goal: real two-client multiplayer test on August 28, 2026.**

The live GDD is design authority. GitHub `main` is implementation authority.

Development order has changed: multiplayer integration/testing now precedes Neil + The Brute and Gordon the Warden.

The current implemented dungeon progression remains a temporary multiplayer test harness:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah → intermission → next generated level`

The GDD's required post-Blue-Gate Neil + The Brute midboss is intentionally not yet implemented and does not block the first multiplayer smoke test. Gordon the Warden is likewise deferred.

See `docs/MULTIPLAYER_TEST_PLAN.md` for the complete August 28 protocol and `docs/DEVELOPMENT_PLAN.md` for current sequencing.

## Multiplayer foundation already present

RunManager already supports:

- maximum four active players;
- maximum ten played campaign identities;
- persistent identity → character assignment;
- individualized lives/elimination/respawn state;
- inventory capture/restoration;
- restricted waiting spectators;
- promotion when a slot becomes available;
- reconnect through persistent identity;
- server-authoritative shared progression;
- campaign freeze when all played clients disconnect.

LootDirector already provides individualized owner-validated loot and reapplies per-client transmission rules to joining clients.

FactionManager and hostile targeting already resolve against living active players rather than treating every connected client as a combat target.

## New multiplayer hardening

`gamemodes/legend_of_deborah/gamemode/lod/sv_multiplayer_hardening.lua` is loaded after the current production systems and owns cross-system lifecycle invariants needed for the first real multiplayer run.

### Slot-safe teammate revival

Previously, LootDirector's extra-life teammate revival directly wrote `RunManager.State.ActiveIdentity[revivedId] = true`, which could bypass the four-active-player cap.

Now:

- `RunManager:ReviveIdentity(identity)` restores persistent life/elimination state;
- normal `TryActivatePlayer` arbitrates the active slot;
- a revived identity waits if all active slots are occupied;
- a connected revived identity spawns only after successful activation.

### Fixed death wait

The GDD requires a fixed 20-second mandatory death wait.

The existing Death-Tetris implementation still contains a retired line-clear wait-reduction field internally, but multiplayer hardening makes it non-authoritative:

- `DeathTetris:GetMandatoryRemaining` uses an immutable 20-second deadline;
- the authoritative `LOD_DeathTetrisAction` receiver uses that same deadline;
- Tetris line clears therefore award next-life HP only and cannot authorize an early respawn.

This should be verified immediately in runtime and later folded directly into a consolidated Tetris implementation.

### Death disconnect/reconnect

Previously, disconnect deleted the identity's Death-Tetris/death interaction state.

Now:

- disconnect removes only the live Tetris board/session;
- death eligibility remains identity-scoped;
- reconnect restores the death interaction when the identity is re-admitted to an active slot and remains inside the hard-cap window;
- a waiting/non-active reconnect cannot use the death action to bypass slot authority;
- a promoted dead identity has its interaction ownership re-synchronized at 4 Hz.

### Intermission disconnect/reconnect

Previously, disconnect deleted both the intermission session and the identity's opportunity.

Now:

- level clear creates a pending intermission opportunity for every admitted played identity in campaign PlayerState, connected or not;
- disconnect during an active board discards only that transient board;
- the pending opportunity survives;
- reconnect during the same 20-second window may start a fresh intermission board.

### Full-party disconnect timeline

RunManager already pauses its campaign timers when no played clients remain connected. The hardening layer now applies the same elapsed-time correction to Death/Intermission Tetris module-local deadlines so a full-party disconnect does not silently consume those windows.

## New diagnostics

### `lod_multiplayer_status`

Reports:

- connected clients;
- played campaign identities;
- active identities / four-slot cap;
- living active players;
- waiting identities;
- active identity → PlayerState integrity;
- eliminated/disconnected identities illegally occupying slots;
- active+waiting contradiction;
- hostiles targeting dead/non-active players;
- loot with invalid campaign owners;
- orphan Death-Tetris state;
- orphan Intermission-Tetris state.

`result=PASS` means no integrity failure was detected. A single-client run intentionally warns that fewer than two clients are connected.

### `lod_multiplayer_lifecycle_status`

Reports counters for:

- teammate revivals;
- immediate vs waiting revival dispositions;
- death reconnect restoration;
- suspended death-Tetris sessions;
- suspended intermission-Tetris sessions;
- full-disconnect timeline shifts.

## Immediate acceptance gate — MP-B

Fully restart Garry's Mod and run the existing game single-player on `gm_flatgrass`.

Required evidence:

1. no Lua errors at startup/generation;
2. normal movement/combat/loot/Magic/minimap/progression remain functional;
3. `lod_multiplayer_status` reports `result=PASS`;
4. death with lives remaining produces the normal interaction;
5. clearing a Tetris line does not make respawn available before 20 seconds;
6. ordinary Watcher/Seeker/Soldier behavior shows no obvious regression.

If this passes, proceed directly to the two-client MP-C test rather than implementing another feature.

## Two-client acceptance target — MP-C

Preferred acceptance is a complete cooperative Level 1 followed by a successful shared transition into Level 2.

Minimum acceptable evidence:

- two real clients simultaneously active;
- same level/progression state;
- personal Magic/lives/inventory/loot remain isolated;
- enemies can legally target either player;
- personal death does not commandeer the teammate;
- disconnect/reconnect restores the same identity;
- either player may advance shared progression;
- one Deborah rescue clears the level globally exactly once;
- independent intermission-Tetris opportunities;
- next dungeon generated once and shared;
- `lod_multiplayer_status` has zero failures;
- no serious performance regression or Lua error.

## Accepted single-player foundations preserved

Do not disturb without concrete regression evidence:

- deterministic procedural multi-floor maze generation;
- canonical graph authority;
- optimized merged server wall collision + client wall presentation;
- validated stair/floor geometry;
- Motion V2 ordinary hostile movement;
- generated-geometry ballistics/cover;
- current minimap caching/reliability behavior;
- server-authoritative combat dice;
- immutable Soldier warning/projectile contract;
- current Watcher and Seeker accepted behavior;
- individualized LootDirector;
- finite ammo/regeneration system;
- Magic/Force Shout;
- current broad combat/economy balance;
- campaign restart and level transition pipeline.

## Known design/runtime discrepancies deliberately outside tomorrow's smoke gate

### Neil + The Brute

Required by the live GDD after Blue Gate, but intentionally deferred until after multiplayer testing begins.

### Gordon the Warden

Not implemented; deferred.

### Dungeon-tier Map degradation

Required by current GDD, not yet production-complete. Existing functional map is retained as the multiplayer test harness.

### Armor residue

HL2 suit/armor is retired from intended design but some implementation residue remains. Remove during economy consolidation rather than immediately before multiplayer testing.

### Architectural wrapper debt

The Second Full-System Audit found substantial wrapper/load-order debt in weapon economy, hostile controllers, minimap reliability, Tetris and level-build integration. The codebase does not require a rewrite, but these layers should be consolidated after the first multiplayer run supplies real integration evidence.

## Current rule

**Do not implement Neil + The Brute or Gordon the Warden yet. Do not initiate a broad refactor tonight. First prove that the hardened current game still works single-player; then test it with two humans.**
