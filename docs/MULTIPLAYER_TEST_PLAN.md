# Multiplayer Test Plan — 2026-08-28

## Objective

Reach a trustworthy **two-client playable multiplayer test on August 28, 2026** before implementing Neil + The Brute or Gordon the Warden.

Neil + The Brute and Gordon remain deliberately deferred. The current pre-boss dungeon progression is the temporary multiplayer test harness:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah`

The purpose of this gate is not release-candidate multiplayer. It is to prove that the existing server-authoritative campaign can support two real human clients through ordinary dungeon play without state corruption.

## Current multiplayer-hardening checkpoint

The multiplayer hardening and contract layers now provide these pre-test guarantees:

- RunManager remains the sole authority for the four active player slots.
- Extra-life teammate revival requests activation through RunManager instead of writing `ActiveIdentity` directly.
- A revived identity waits normally if all four active slots are occupied.
- Death-Tetris line clears award HP only; they cannot shorten the fixed 20-second mandatory death wait.
- Death/Tetris eligibility survives a network disconnect and can be restored on reconnect while the identity remains eligible.
- Intermission-Tetris eligibility survives disconnect; a reconnect during the same 20-second window may begin a fresh session.
- Full-party disconnect freeze time is also applied to Death/Intermission Tetris deadlines.
- Friendly fire is explicitly suppressed, including owned-entity/projectile damage paths.
- Colored-gate progression requires a living active player.
- Dungeons 1–20 derive personal minimap access from campaign/player state instead of the retired Map-pickup entitlement; personal Magic drain remains unchanged.
- Future level generation snapshots the connected cooperative party before active identities are repopulated, so authored encounter threat scaling no longer silently plans every new dungeon as solo.
- First-time JIP catch-up kits match the live GDD and current dice-ammo floors: Level 1 adds SMG 25 + Shotgun 7; Level 2 also adds Magnum 6; Level 3+ also adds AR2 20. Pistol remains 18, all reserve starts at zero, and no Grenades/AR2 secondary are granted.
- `lod_multiplayer_status` audits live slot, identity, hostile-target, loot-owner, and Tetris ownership invariants.
- `lod_multiplayer_contract_status` audits map, gate, friendly-fire, and party-scaling contracts.
- `lod_multiplayer_lifecycle_status` reports revival/reconnect/timeline events exercised during the run.

## Gate MP0 — Single-client regression

Before adding the second human client:

1. Fully restart Garry's Mod on `gm_flatgrass`.
2. Begin a normal Level-1 dungeon.
3. Confirm no Lua errors during generation/spawn.
4. Run `lod_multiplayer_status`.
5. Run `lod_multiplayer_contract_status`.
6. Play far enough to confirm ordinary movement, combat, loot, map/Magic, and progression still work.
7. Die once, play some Tetris, and verify the respawn does **not** become available before 20 seconds even after clearing lines.

### MP0 acceptance

- `lod_multiplayer_status` reports `result=PASS`.
- A warning that fewer than two clients are connected is expected.
- `lod_multiplayer_contract_status` reports `result=PASS`, `mapMismatch=0`, `friendlyFire=OFF/ARMED`, `gateContract=ARMED`, and `partyScale=ARMED`.
- On Dungeon 1 with one living active player, `mapAllowed=1` and `plannedParty=1` are expected.
- No single-player regression appears.
- Death countdown remains fixed at 20 seconds.

## Gate MP1 — Two clients join the same campaign

Connect a second real human client to the running server.

Verify:

- both clients receive different persistent character identities;
- both are active simultaneously;
- both spawn at the current checkpoint/start position;
- both see the same maze/progression state;
- each has personal lives, Health, Magic, inventory and loot state;
- the first-time Level-1 JIP client receives Crowbar + Pistol (18) + SMG (25) + Shotgun (7), with zero reserve, no Grenades, and no AR2 secondary;
- one player's Magic/map use does not drain the other player's Magic;
- individualized loot is visible/collectible only by its owner;
- enemies can select either living active player as a target;
- enemies never retain a dead/disconnected/non-active player as their target.

Run `lod_multiplayer_status` and `lod_multiplayer_contract_status` after both clients are active.

### MP1 acceptance

- `connected=2`, `active=2/4`, `failures=0`, `result=PASS`.
- `mapAllowed=2`, `mapMismatch=0`, and multiplayer contracts remain `PASS`.
- The already-generated Level 1 is not destructively replanned merely because the second player joined. On Level 2 generation, both still-connected cooperative identities must be included in the party-size planning snapshot.

## Gate MP2 — Cooperative combat and split positioning

Play ordinary combat together, then deliberately separate.

Test:

- both players in one encounter;
- players in adjacent maze regions;
- players on different generated floors;
- one player attracting a hostile while the other moves elsewhere;
- Watcher/Seeker/Soldier behavior with two legal targets;
- no enemy damages another hostile;
- generated walls/floors remain authoritative cover for both players;
- shoot/explode one another deliberately and verify teammate HP does not change;
- walk directly through one another and verify there is no teammate body blocking.

### MP2 acceptance

No targeting deadlocks, teleporting, cross-floor wall shooting, friendly-fire damage, teammate collision, permanent stuck states, or material performance collapse.

## Gate MP3 — Personal death while teammate remains alive

Player A dies while Player B remains alive.

Verify:

- simulation continues for B;
- A enters restricted death/spectator state;
- A's life decrements independently;
- A may play Death Tetris;
- Tetris line clears increase only A's next-life HP bonus;
- respawn remains unavailable until exactly the normal 20-second gate expires;
- A respawns at the team checkpoint without disturbing B.

Run `lod_multiplayer_status` while A is dead and again after A respawns.

## Gate MP4 — Disconnect/reconnect during a life

With both players alive:

1. Disconnect A.
2. Continue moving/fighting as B.
3. Reconnect A.

Verify:

- A's identity/character persists;
- inventory/lives persist;
- A is re-admitted through the normal slot authority;
- no duplicate character/player state is created;
- A's individualized static loot remains correctly isolated.

## Gate MP5 — Disconnect/reconnect during death

A dies with lives remaining, then disconnects before respawning.

Reconnect A before the one-minute hard cap.

Verify:

- death eligibility was not erased;
- if the 20-second mandatory wait remains, the HUD shows the correct remainder;
- if 20 seconds have elapsed, respawn is available;
- A may restart Death Tetris if still inside the optional death interaction window;
- A cannot respawn unless RunManager has actually re-admitted A to an active slot.

Run `lod_multiplayer_lifecycle_status`; `deathReconnects` or `deathSuspends` should demonstrate the path was exercised.

## Gate MP6 — Shared progression

Advance through the current temporary multiplayer progression:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah`

Test both clients taking turns collecting cards/opening gates.

Verify every transition is team-global and idempotent: the second client immediately observes the new state and cannot duplicate the progression action.

Neil + The Brute are **not part of this test gate**.

## Gate MP7 — Rescue/intermission/next level

Have either player rescue Deborah.

Verify:

- one rescue clears the level globally exactly once;
- both players enter the same 20-second transition window;
- each receives an independent intermission-Tetris opportunity;
- HP bonuses remain personal;
- next-level generation occurs once;
- both players emerge into the same new dungeon with their own persistent inventory/lives/resources;
- `lod_multiplayer_contract_status` on Level 2 reports `plannedParty=2` when both identities remained connected through generation.

Stretch reconnect test: disconnect one identity during the intermission and reconnect before the window closes; the identity should still be eligible to begin a fresh intermission-Tetris session.

## Gate MP8 — Wipe / promotion sanity

If practical during the same session:

- eliminate one player completely and verify the other continues;
- exercise an extra-life teammate revival if a drop becomes available;
- verify revival never increases active identities above four;
- if an identity must wait for a slot, it remains spectator until RunManager promotes it;
- verify campaign failure occurs only on a true party wipe under the current campaign rules.

## Diagnostic commands

- `lod_multiplayer_status` — authoritative live integrity summary.
- `lod_multiplayer_contract_status` — friendly-fire, map, progression-actor, and party-scaling contract summary.
- `lod_multiplayer_lifecycle_status` — revival/reconnect/freeze-path counters.
- Existing focused diagnostics remain authoritative for subsystem regressions (`lod_watcher_status`, Seeker/Soldier/loot/minimap diagnostics, etc.).

## Test-stop conditions

Stop the multiplayer gate and fix before proceeding if any of the following occurs:

- Lua error;
- active identities exceed four;
- duplicate/polluted persistent identity state;
- one player receives another player's loot or personal resource changes;
- one player's death freezes or respawns the other;
- teammate bullets/explosives damage the other player;
- enemies target dead/non-active players persistently;
- progression diverges between clients;
- level transition runs twice or clients enter different level instances;
- reconnect creates a new campaign identity instead of restoring the old one;
- serious Steam Deck/server performance regression.

## Post-test order

After the first real multiplayer gate is accepted:

1. fix any multiplayer defects revealed by the run;
2. perform the larger authority-consolidation work from the Second Full-System Audit;
3. expand multiplayer validation toward 3–4 clients / slot churn / dedicated-server soak;
4. implement Neil + The Brute and validate the midboss in multiplayer;
5. implement Gordon the Warden and validate the boss/rescue loop in multiplayer;
6. finish release-candidate multiplayer/soak/polish.
