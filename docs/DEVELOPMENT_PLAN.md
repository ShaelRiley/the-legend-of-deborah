# Development Plan — 2026-08-27 Post-Audit / Multiplayer Priority

The live GDD is design authority. GitHub `main` is implementation authority.

## Current objective

**Run a real two-client multiplayer test on August 28, 2026.**

Multiplayer integration and testing now occurs **before** Neil + The Brute and before Gordon the Warden.

The first multiplayer gate is deliberately a functional smoke/integration test, not a release-candidate multiplayer pass. Use the currently implemented dungeon progression as the test harness:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah → intermission → next generated level`

The live GDD now requires Neil + The Brute after the Blue Gate, but that midboss is intentionally deferred until after the first multiplayer gate. Gordon the Warden is also deferred.

Detailed test procedure: `docs/MULTIPLAYER_TEST_PLAN.md`.

---

## Development order

1. **MP-A — multiplayer lifecycle hardening — CURRENT.**
2. **MP-B — single-client regression of the hardening changes.**
3. **MP-C — real two-client gameplay test.**
4. Fix defects revealed by the two-client run until the multiplayer smoke gate is accepted.
5. Continue the Second Full-System Audit consolidation work where it directly improves multiplayer robustness and maintainability.
6. Expand multiplayer validation toward split-floor play, reconnect churn, 3–4 active clients and dedicated-server soak.
7. Implement the remaining ordinary enemy roster only as appropriate after multiplayer stability is established.
8. Implement **Neil + The Brute** as the mandatory post-Blue-Gate midboss.
9. Implement **Gordon the Warden** and final arena.
10. Perform final multiplayer/release-candidate soak, performance and polish.

Do not resume Neil/Brute or Warden implementation before the first multiplayer test unless a multiplayer prerequisite specifically requires their existence. None currently does.

---

# MP-A — Multiplayer Lifecycle Hardening

The existing RunManager already provides a strong multiplayer-oriented foundation:

- four active player slots;
- up to ten played campaign identities;
- persistent identity → character assignment;
- personal lives/elimination/respawn state;
- inventory capture/restoration;
- waiting spectators and promotion;
- reconnect admission through persistent identity;
- server-authoritative team progression;
- campaign freeze when every played identity is disconnected.

The first hardening pass adds the missing cross-system invariants without changing accepted combat/economy balance.

## Implemented hardening

`sv_multiplayer_hardening.lua` currently owns only cross-system lifecycle rules:

### Active-slot authority

- `RunManager` remains the sole authority for `ActiveIdentity`.
- Extra-life teammate revival may no longer force an identity directly into an active slot.
- Revived identities request normal RunManager activation.
- If all four slots are occupied, a revived connected player remains a waiting spectator until promoted.

### Death / reconnect

- Death-Tetris eligibility survives a network disconnect.
- A reconnecting identity can resume the death interaction while still eligible.
- A reconnecting dead identity cannot respawn unless RunManager has actually admitted that identity to an active slot.
- The mandatory death wait is fixed at the authored 20 seconds.
- Tetris line clears award next-life HP only and cannot authorize an early respawn.

### Intermission / reconnect

- Intermission-Tetris eligibility is identity-scoped rather than connection-scoped.
- A played identity disconnected at level clear can reconnect during the same 20-second window and participate.
- Disconnecting during an active intermission board discards only that transient board; the identity may start a fresh board if the shared window remains open.

### Full-party disconnect freeze

RunManager already freezes campaign deadlines when no played client remains connected. Multiplayer hardening extends that same elapsed-time correction to Death/Intermission Tetris module-local deadlines.

### Diagnostics

`lod_multiplayer_status` checks:

- connected / played / active / living / waiting counts;
- four-player active-slot cap;
- active identity → PlayerState integrity;
- no eliminated identity occupying an active slot;
- no disconnected identity occupying an active slot;
- no identity simultaneously active and waiting;
- hostile targets are living active players;
- loot owners resolve to campaign PlayerState;
- Death-Tetris and Intermission-Tetris identity state resolves to campaign PlayerState.

`lod_multiplayer_lifecycle_status` reports exercised revival, reconnect, Tetris-suspension and full-disconnect timeline-shift paths.

---

# MP-B — Single-client Regression

Before introducing a second human client, validate that the multiplayer hardening did not disturb the accepted single-player game.

## Required test

1. Fully quit and restart Garry's Mod.
2. Use the required map `gm_flatgrass`.
3. Start a normal fresh campaign.
4. Confirm generation/loading produces no Lua error.
5. Run `lod_multiplayer_status`.
6. Confirm ordinary movement, combat, loot, Magic, minimap and progression.
7. Die with a life remaining.
8. Clear at least one Tetris line if practical.
9. Confirm respawn remains unavailable until the normal 20-second mandatory wait expires.
10. Continue normal play long enough to catch obvious Watcher/Seeker/Soldier regressions.

## Acceptance

- `lod_multiplayer_status` → `result=PASS`;
- the expected `<2 connected clients` warning is harmless;
- no Lua errors;
- no single-player regression;
- death wait remains fixed at 20 seconds.

Do not add further systems before MP-B is accepted if this hardening pass introduced a regression.

---

# MP-C — Two-Client Multiplayer Smoke Gate

Use **two real human clients** first. Do not begin with four players; two clients expose ownership/state disagreements with much less diagnostic noise.

The authoritative checklist is `docs/MULTIPLAYER_TEST_PLAN.md`.

Minimum required evidence:

## 1. Admission

- two distinct persistent identities;
- two distinct character assignments;
- `connected=2`;
- `active=2/4`;
- both spawn into the same level instance.

## 2. Shared world / personal state

Shared:

- graph;
- generated geometry;
- progression state;
- gates/keycards/Jail Key/Deborah;
- encounters and hostile population;
- checkpoints;
- level transition.

Personal:

- Health;
- lives/elimination;
- inventory/ammo;
- Magic;
- map-open/drain state;
- individualized loot;
- Death/Intermission Tetris;
- next-life Tetris HP bonus.

## 3. Combat targeting

- enemies may select either living active player;
- target changes must remain legal when players split up;
- no persistent targeting of dead, disconnected or waiting identities;
- hostile-vs-hostile damage remains suppressed;
- generated geometry remains authoritative cover.

## 4. Personal death

One player dying must not pause, kill, respawn or otherwise commandeer the living teammate.

The deceased player receives only their own life decrement, death/Tetris interaction and later checkpoint respawn.

## 5. Disconnect / reconnect

A reconnect must restore the same campaign identity rather than admitting a new character.

Exercise reconnect:

- while alive;
- while dead with lives remaining;
- during intermission if practical.

## 6. Individualized loot

A player's loot must never become collectible by the other client.

Join/rejoin must correctly set entity transmission and reconstruct unconsumed static loot for the returning identity.

## 7. Progression

Either player may perform a progression interaction. The result is global, server-authored and immediately shared.

For the initial smoke gate, use the current temporary progression without Neil/Brute.

## 8. Level clear

One Deborah rescue must clear the level once for the entire party, open independent personal intermission-Tetris opportunities, then build one shared next level.

## MP-C acceptance

A two-human-client run reaches at least one meaningful stretch of cooperative dungeon play with:

- `lod_multiplayer_status` reporting zero failures;
- no state divergence;
- no cross-player personal-resource contamination;
- no progression duplication;
- no major targeting failure;
- no serious Steam Deck/server performance collapse;
- no Lua error.

Completing an entire Level 1 and entering Level 2 is preferred and becomes the acceptance target if the first session is stable enough.

---

# Post-Smoke Multiplayer Hardening

After MP-C, use real defects rather than speculation to choose the next changes.

Highest-priority scenarios:

1. players on different generated floors;
2. simultaneous encounters near different players;
3. death/reconnect while the teammate continues combat;
4. 5th identity waiting/promotion semantics;
5. extra-life revival with four active slots occupied;
6. repeated disconnect/reconnect churn;
7. three and four active clients;
8. dedicated-server lifecycle;
9. longer campaign soak;
10. entity/network cost of individualized loot across many played identities.

---

# Second Full-System Audit Consolidation

The audit conclusion remains valid: the game does not need a rewrite, but successful iterative fixes have produced too many historical wrapper layers.

Do **not** attempt a broad cleanup immediately before tomorrow's multiplayer test. Preserve behavior and use the multiplayer run to establish the next evidence-based priorities.

After the first multiplayer smoke gate, consolidation should proceed approximately in this order:

1. canonical weapon/ammo/enemy rule registries;
2. explicit level-build pipeline instead of nested `MazeBuilder.Build` wrappers;
3. one resource/economy authority;
4. explicit combat modifier pipeline;
5. one hostile registry/controller scheduling architecture;
6. unified Watcher controller preserving all historical regression guarantees;
7. unified Seeker controller;
8. canonical MapService and dungeon-tier map degradation;
9. unified Death/Intermission Tetris session service;
10. removal of retired scaffolding and stale compatibility layers.

Every consolidation must retain a decisive runtime acceptance criterion.

---

# Design/runtime work deliberately deferred until after multiplayer smoke

## Neil + The Brute

The live GDD requires:

`Blue Gate → Neil + The Brute → Yellow Keycard`

This remains required production design, but implementation is intentionally deferred until after multiplayer has been exercised.

## Gordon the Warden

Final boss implementation remains deferred until after Neil/Brute and the relevant multiplayer foundations are stable.

## Map degradation tiers

The GDD's dungeon-tier map degradation still requires production implementation. Do not let this block the first two-client test; the currently functional map remains the test harness.

## Armor cleanup

HL2 suit/armor is retired from the intended design, but remaining implementation residue should be removed during economy consolidation rather than destabilizing the immediate multiplayer gate.

---

# Preserved hard constraints

1. `gm_flatgrass` remains the required development map.
2. The canonical generated 3D graph remains topology/progression/routing/minimap authority.
3. Motion V2 remains the sole ordinary hostile ground-motion authority.
4. Validated stairs remain the sole ordinary hostile elevation-changing route.
5. Soldier warning/projectile truth remains one immutable server-authored line committed at beam-on.
6. Generated geometry remains authoritative cover and pushback collision.
7. Shotgun/SMG/Magnum/AR2 remain peer firearms; do not reintroduce power-tier rarity gating.
8. Player Magic and loot remain personal; progression and world state remain team-global.
9. Networking and recurring graph/entity work remain bounded and low-end-safe.
10. Do not introduce automatic high-volume telemetry.
11. Do not alter accepted broad combat/economy balance without concrete runtime evidence.
12. Do not implement Neil + The Brute or Gordon the Warden before the first multiplayer smoke gate.

---

# Immediate next action

**Run MP-B on a fully restarted single-client build.**

If MP-B passes, the next development action is not another code feature: it is the real two-client MP-C session defined in `docs/MULTIPLAYER_TEST_PLAN.md`.
