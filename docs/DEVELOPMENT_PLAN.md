# Development Plan — 2026-08-27 Post-Audit / Multiplayer Priority

The live GDD is design authority. GitHub `main` is implementation authority.

## Current objective

**Validate the new native-hut deployment flow, then run a real two-client multiplayer test on August 28, 2026.**

Multiplayer integration and testing occurs before Neil + The Brute and before Gordon the Warden.

The first multiplayer gate is deliberately a functional smoke/integration test, not a release-candidate multiplayer pass. Use the currently implemented dungeon progression as the test harness:

`Red Card → Red Gate → Blue Card → Blue Gate → Yellow Card → Yellow Gate → Jail Key → jail door → Deborah → intermission → next generated level`

Detailed test procedure: `docs/MULTIPLAYER_TEST_PLAN.md`.

---

## Development order

1. **MP-A — multiplayer lifecycle hardening — ACCEPTED in one-client runtime.**
2. **MP-STAGING — native Flatgrass hut + individualized advanced starter + portal — IMPLEMENTED, awaiting S0 runtime.**
3. **S0 — single-client staging/deployment regression.**
4. **MP-C — real two-client staged admission + gameplay test.**
5. Fix defects revealed by the two-client run until the multiplayer smoke gate is accepted.
6. Continue Second Full-System Audit consolidation where real multiplayer evidence identifies the highest-risk authority debt.
7. Expand validation toward split-floor play, reconnect churn, 3–4 active clients, slot churn and dedicated-server soak.
8. Separately tune deeper-level JIP assistance beyond the universal hut starter only if playtesting demonstrates a need.
9. Implement **Neil + The Brute** as the mandatory post-Blue-Gate midboss.
10. Implement **Gordon the Warden** and final arena.
11. Perform final multiplayer/release-candidate soak, performance and polish.

Do not resume Neil/Brute or Warden implementation before the first multiplayer test unless a multiplayer prerequisite specifically requires their existence. None currently does.

---

# Accepted MP-A — Multiplayer Lifecycle Hardening

The existing RunManager provides:

- four reserved cooperative slots;
- up to ten played campaign identities;
- persistent identity → character assignment;
- personal lives/elimination/respawn state;
- inventory capture/restoration;
- waiting spectators and promotion;
- reconnect admission through persistent identity;
- server-authoritative team progression;
- campaign freeze when every played identity disconnects.

Accepted hardening adds:

- RunManager-only active-slot arbitration for teammate revival;
- reconnect-safe death/Tetris eligibility;
- fixed authored 20-second death wait;
- reconnect-safe intermission opportunity;
- full-party disconnect timeline correction;
- explicit friendly-fire suppression and teammate non-collision;
- living-player progression authority;
- D1–20 personal map authority;
- connected-party encounter planning;
- live multiplayer integrity/contract/roster diagnostics.

The pre-staging one-client build passed `lod_multiplayer_status`, `lod_multiplayer_contract_status`, and `lod_multiplayer_roster_status` with zero failures.

---

# MP-STAGING — First-Deployment Hut

## Design goal

A player should immediately understand that LOD contains highly developed firearms rather than spending an arbitrary first stretch assuming the Pistol is the whole combat game.

The onboarding solution also serves multiplayer admission:

`reserved campaign slot → shared native Flatgrass hut → individualized starter claim → USE/E portal → dungeon-active player`

## Implemented authority

`sv_staging_deployment.lua` owns:

- deterministic anchoring to the map's native player-start/hut area;
- the red-tinted Dungeon Hermit presentation;
- deterministic identity-bound advanced starter assignment;
- without-replacement assignment within the currently reserved four-player party wherever possible;
- per-identity starter pickup transmission/claim state;
- staged versus deployed state;
- hidden physical containment of the native hut;
- portal-only deployment to the current valid maze start/checkpoint;
- reconnect reconstruction for an unclaimed starter;
- removal of the former two guaranteed Level-1 firearm nodes.

`sv_staging_simulation_hold.lua` reuses RunManager's existing `SimulationFrozen` authority so the generated dungeon does not age while every connected reserved participant remains staged. One deployed player is sufficient to resume ordinary simulation even if teammates remain in the hut.

## Starting inventory contract

Every newly admitted identity receives:

- Crowbar;
- Pistol: 18 loaded, zero reserve;
- one physical individualized advanced starter:
  - Shotgun: 7 loaded, zero reserve;
  - SMG: 25 loaded, zero reserve;
  - Magnum: 6 loaded, zero reserve;
  - AR2: 20 loaded, zero reserve.

No starter grants Grenades or AR2 secondary ammunition.

The former level-banded JIP kit is retired. `sv_loot_catchup.lua` remains only as a compatibility marker until a later cleanup pass removes retired include names.

## Staged-player contract

RunManager still owns `ActiveIdentity` as the raw slot ledger. For gameplay consumers, `RunManager:IsActivePlayer` means slot-reserved **and deployed**.

A staged identity therefore:

- consumes one cooperative slot;
- keeps character/lives/Magic/persistent identity state;
- is not a legal hostile target;
- cannot advance dungeon progression;
- cannot use the dungeon map;
- cannot receive dungeon enemy-drop rolls;
- does not materialize ordinary individualized static dungeon loot.

Portal deployment activates ordinary dungeon semantics for that identity without moving or restarting teammates.

---

# S0 — Single-Client Staging Regression

Before introducing a second human client, validate the new physical/tutorial path.

Required:

1. fully restart GMod on `gm_flatgrass`;
2. start a fresh campaign;
3. spawn in the native Flatgrass hut facing the Dungeon Hermit and one advanced starter;
4. confirm blue portal is behind/exit-side;
5. try portal before claim and confirm denial;
6. confirm ordinary walking cannot escape into Flatgrass;
7. run `lod_staging_status` and `lod_staging_simulation_status`;
8. claim starter and verify exact loaded magazine / zero reserve;
9. USE/E portal and confirm teleport to current dungeon start/checkpoint;
10. rerun staging diagnostics plus multiplayer status/contract/roster diagnostics;
11. confirm ordinary combat, loot, Magic/map and progression still operate.

Acceptance details are authoritative in `docs/MULTIPLAYER_TEST_PLAN.md`.

Do not add another feature if S0 exposes a staging regression.

---

# MP-C — Two-Client Multiplayer Smoke Gate

Use two real human clients first.

## 1. Staged admission

- player 1 may already be deployed;
- player 2 receives a distinct persistent identity and character;
- player 2 reserves a second cooperative slot but appears in the shared native hut;
- player 1 is not moved or restarted;
- player 2 receives one personalized advanced starter, distinct from current reserved assignments where possible;
- neither client can see/claim the other's starter;
- staged player 2 has no dungeon map/static loot/hostile targeting/progression authority;
- portal refuses deployment before starter claim.

## 2. Deployment

After player 2 claims the starter and uses the portal:

- both players are dungeon-active;
- player 2 arrives at the current valid team start/checkpoint;
- ordinary individualized static loot materializes for player 2;
- both share graph/progression/world state while retaining personal lives/inventory/Magic/loot/Tetris state.

## 3. Combat and split play

- enemies may legally select either deployed living player;
- target changes remain valid across separated maze regions and floors;
- no persistent target may point at staged/dead/disconnected/waiting identities;
- teammate damage remains disabled;
- teammates remain non-solid to one another;
- generated geometry remains authoritative cover.

## 4. Reconnect

Exercise reconnect before deployment and after deployment.

Before deployment, the same character/starter assignment/claim state must return without reroll or duplication. After deployment, reconnect uses ordinary dungeon restoration and must not send the identity through staging again.

## 5. Personal death

One player dying must not pause, kill, respawn or otherwise commandeer the living teammate. Ordinary death/respawn must not restage an already-deployed identity.

## 6. Progression and level clear

Either deployed player may perform a progression interaction. One Deborah rescue clears the level once for the party, opens personal intermission-Tetris opportunities, and builds one shared next level. Already-deployed identities do not return to the hut on ordinary next-level transition.

## MP-C acceptance

A two-human-client run reaches meaningful cooperative dungeon play with:

- staging diagnostics PASS;
- multiplayer integrity/contract/roster diagnostics PASS;
- no cross-player personal-resource contamination;
- no state divergence or progression duplication;
- no staged-player dungeon authority leak;
- no major targeting failure;
- no serious Steam Deck/server performance collapse;
- no Lua error.

Completing Level 1 and entering Level 2 is preferred if the first session is stable enough.

---

# Post-Smoke Multiplayer Hardening

After MP-C, choose changes from real defects rather than speculation. Highest-priority scenarios:

1. different generated floors;
2. simultaneous distant encounters;
3. death/reconnect while teammate continues combat;
4. reconnect before deployment;
5. fifth identity waiting/promotion semantics;
6. extra-life revival with four reserved slots;
7. repeated identity churn;
8. three and four active clients;
9. dedicated-server lifecycle;
10. longer campaign soak;
11. entity/network cost of individualized loot across many played identities.

---

# Second Full-System Audit Consolidation

The audit conclusion remains valid: no rewrite is needed, but historical wrapper layers should be consolidated after the first multiplayer smoke gate.

Approximate order:

1. canonical weapon/ammo/enemy rule registries;
2. explicit level-build pipeline instead of nested `MazeBuilder.Build` wrappers;
3. one resource/economy authority;
4. explicit combat modifier pipeline;
5. one hostile registry/controller scheduling architecture;
6. unified Watcher controller preserving historical regression guarantees;
7. unified Seeker controller;
8. canonical MapService and dungeon-tier map degradation;
9. unified Death/Intermission Tetris session service;
10. removal of retired scaffolding, including the compatibility-only old JIP catch-up file.

Every consolidation must retain a decisive runtime acceptance criterion.

---

# Deferred production work

- **Neil + The Brute:** required `Blue Gate → midboss → Yellow Keycard`, but intentionally after multiplayer smoke.
- **Gordon the Warden:** deferred until midboss and multiplayer foundations are stable.
- **Map degradation tiers:** required by GDD but not a blocker for first two-client validation.
- **Armor cleanup:** retired design residue; remove during economy consolidation.
- **Procedural rotating Hut Event System:** shops/gifts/exclusive rotating visits remain post-release. Only the minimal shared first-deployment hut state has been promoted to current v1.

---

# Preserved hard constraints

1. `gm_flatgrass` remains the required development map.
2. The canonical generated 3D graph remains topology/progression/routing/minimap authority.
3. Motion V2 remains sole ordinary hostile ground-motion authority.
4. Validated stairs remain sole ordinary hostile elevation-changing route.
5. Soldier warning/projectile truth remains one immutable server-authored line committed at beam-on.
6. Generated geometry remains authoritative cover and pushback collision.
7. Shotgun/SMG/Magnum/AR2 remain peer firearms.
8. Player Magic and loot remain personal; progression/world state remain team-global.
9. Staging reserves RunManager slots but does not create a second slot ledger.
10. Networking and recurring graph/entity work remain bounded and low-end-safe.
11. Do not alter accepted broad combat/economy balance without concrete runtime evidence.
12. Do not implement Neil + The Brute or Gordon the Warden before the first multiplayer smoke gate.

---

# Immediate next action

**Run S0 on a fully restarted single-client build.**

If S0 passes, the next development action is the real two-client staged-admission session defined in `docs/MULTIPLAYER_TEST_PLAN.md`.
