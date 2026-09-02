# Development Plan — 2026-09-02 Post-Multiplayer / RPG Priority

The live GDD is design authority. GitHub `main` is implementation authority.

## Current objective

**Continue the RPG overhaul now that the core live multiplayer smoke foundation has been validated on the public VPS.**

The previous plan treated first real-client multiplayer as an uncompleted prerequisite. That milestone is now accepted from the September 1 playtest documented in `docs/MP_PLAYTEST_2026-09-01.md`.

The accepted footage shows at least three simultaneous human-controlled clients completing meaningful cooperative dungeon progression through Deborah rescue and the next-level transition with no Lua errors reported at the end.

Because that footage predates the RPG overhaul, the correct next network task is a **targeted post-RPG regression pass**, not a repetition of the old foundational smoke gate.

---

## Development order

1. **Core multiplayer smoke foundation — ACCEPTED.**
2. **RPG Gates A–D / class integration — substantially implemented and under active runtime tuning.**
3. **Gate E — ordinary feat-family gameplay integration.** Batch 1 (CON Health Regeneration) is runtime accepted; Batch 2 (WIS Navigation) brings implementation to 6/73 feats and awaits runtime acceptance.
4. Complete the remaining Gate E matrix families with one canonical FeatEffectSystem registry and family-specific validators.
5. **Perk Gate — implement all 192 authored Origin/Background/Motive mechanical bridges.**
6. Perform the mandatory six-stat, Hero Level 1–20, enemy progression, player/enemy symmetry, combat-order, and entity-wide RPG consistency audit.
7. Runtime/play-balance the completed RPG across multiple randomized Heroes/classes/ability extremes.
8. **Post-RPG multiplayer regression** covering the systems added after the September 1 VPS build.
9. Fix defects revealed by that regression until RPG state remains coherent across clients.
10. Continue Second Full-System Audit consolidation where runtime evidence identifies the highest-risk authority debt.
11. Implement **Neil + The Brute** as the mandatory post-Blue-Gate midboss.
12. Implement **Gordon the Warden** and final arena.
13. Expand toward 3–4-client churn/reconnect/death/dedicated-server soak and release-candidate performance/polish.

---

# Accepted Multiplayer Foundation

The September 1 VPS footage retires the old blocker requiring proof that the game can function as real cooperative Garry's Mod multiplayer.

Accepted observed behaviors include:

- public Internet server reachability;
- at least three concurrent human clients;
- simultaneous teammate movement and combat;
- coherent shared objective progression;
- shared keycard/gate transitions;
- personal map use during network play;
- Deborah rescue once for the party;
- multiplayer victory/intermission state;
- one shared next-level build and return to the Red-key objective;
- no Lua errors reported at the end of the captured session.

This evidence validates the world/progression foundation. It does **not** automatically certify systems added later by the RPG overhaul.

---

# Gate E — Ordinary Feat Effects

## Goal

Turn ordinary feat ownership into actual authored gameplay behavior without creating parallel combat, movement, Magic, loot, or progression authorities.

The existing feat catalog, deterministic drafts, prerequisites, ranks, ownership, Character Sheet display, and acquisition cadence remain authoritative. Gate E should connect each authored ordinary feat to the semantic authority that already owns the affected behavior.

## Implementation principles

- Do not invent missing feat effects, percentages, dice, prerequisites, ranks, or scaling rules.
- Read exact definitions from the live GDD before implementing each family.
- Prefer one explicit `FeatEffectSystem`/registry over additional historical wrapper chains.
- Apply modifiers exactly once.
- Keep damage application at the existing canonical seam.
- Keep Magic personal and progression/world state team-global.
- Keep random feat drafts deterministic and persistent.
- Provide visible player feedback where an otherwise-correct feat would be difficult to notice in normal play.
- Add finite validation commands/logging for each feat family rather than recurring diagnostic work.

## Gate E runtime acceptance

A representative matrix of fresh Heroes should exercise ordinary feat families across Fighter, Rogue, and Wizard builds with randomized base abilities.

Acceptance requires:

- prerequisites and rank behavior match the GDD;
- effects appear only for Heroes that own the relevant feat;
- stacked/ranked effects apply the authored number of times and no more;
- effects survive Character Sheet reopen, death/respawn, level transition, and reconnect state serialization where applicable;
- no duplicate damage/resource modifiers appear in logs;
- no new Lua errors;
- broad movement/combat/Magic/loot/progression behavior remains intact.

## Gate E batch ledger

- Batch 1 runtime accepted on `gm_flatgrass`: `CON_REGEN_11`, `CON_REGEN_22`, `CON_REGEN_33`; validator PASS, exact 11/22/33 HP ceilings, 1.20 HP/s tested rate, no visible Lua error.
- Runtime commands: `lod_rpg_gate_e_regen_validate`, `lod_rpg_gate_e_regen_status`, `lod_rpg_test_regen <0-3>`.
- Batch 2 complete in code: `WIS_SURVEYOR`, `WIS_CARTOGRAPHER`, `WIS_FRUGAL_MAP`.
- Batch 2 runtime commands: `lod_rpg_gate_e_navigation_validate`, `lod_rpg_gate_e_navigation_status`, `lod_rpg_test_navigation <0-3>`.
- Source matrices: `docs/RPG_GATE_E_FEAT_MATRIX.md` and `docs/RPG_GDD_RULES_BASELINE.md`.
- Next: runtime-accept Batch 2, then choose another complete family from the matrix; do not intermingle a half-implemented third family with this acceptance gate.

---

# Post-RPG Multiplayer Regression

Once Gate E is coherent in single-client runtime, use the VPS for a focused network regression of the post-September-1 feature set.

At minimum validate:

1. distinct procedural Hero identities and randomized ability arrays per player;
2. Character Sheet snapshots remain player-correct;
3. class and feat commitments do not leak between clients;
4. XP contribution/kill/rescue awards advance the correct Heroes and shared campaign state;
5. level-up and pending-feat state remain coherent across clients;
6. personal Magic remains personal;
7. Wizard Arcane Diversion/Feedback affect only the correct Wizard and correct attacker;
8. full-Magic INT bonuses use the initiating Wizard's own current state;
9. individualized loot/resources remain isolated;
10. one party-wide Deborah rescue and next-level transition remain authoritative;
11. death/respawn of one Hero does not commandeer another client;
12. reconnect restores the same RPG identity and committed progression.

This regression is the next meaningful multiplayer gate. The old foundational test has already served its purpose.

---

# Second Full-System Audit Consolidation

After post-RPG multiplayer evidence, consolidate historical authority debt without rewriting accepted systems.

Approximate order:

1. canonical weapon/ammo/enemy rule registries;
2. explicit level-build pipeline instead of nested `MazeBuilder.Build` wrappers;
3. one resource/economy authority;
4. explicit combat modifier pipeline, including feat effects;
5. one hostile registry/controller scheduling architecture;
6. unified Watcher controller preserving historical regression guarantees;
7. unified Seeker controller;
8. canonical MapService and dungeon-tier map degradation;
9. unified Death/Intermission Tetris session service;
10. removal of retired scaffolding and compatibility-only files.

Every consolidation must retain a decisive runtime acceptance criterion.

---

# Deferred Production Work

- **Neil + The Brute:** required `Blue Gate → midboss → Yellow Keycard`; now free to proceed after the RPG/network regression rather than waiting on the already-completed foundational multiplayer gate.
- **Gordon the Warden:** final boss/arena after midboss and current RPG foundations are stable.
- **Map degradation tiers:** still required by the GDD.
- **Armor cleanup:** retired-design implementation residue.
- **Procedural rotating Hut Event System:** remains post-release except for the minimal first-deployment hut already promoted to v1.

---

# Preserved Hard Constraints

1. `gm_flatgrass` remains the required development/test map.
2. The canonical generated 3D graph remains topology/progression/routing/minimap authority.
3. Motion V2 remains sole ordinary hostile ground-motion authority.
4. Validated stairs remain sole ordinary hostile elevation-changing route.
5. Soldier warning/projectile truth remains one immutable server-authored line committed at beam-on.
6. Generated geometry remains authoritative cover and pushback collision.
7. Shotgun/SMG/Magnum/AR2 remain peer firearms.
8. Player Magic and individualized resources remain personal; progression/world state remain team-global.
9. Staging reserves RunManager slots but does not create a second slot ledger.
10. Networking and recurring graph/entity work remain bounded and low-end-safe.
11. Do not alter accepted broad combat/economy balance without concrete runtime evidence.
12. Do not use the old pre-RPG multiplayer blocker to delay coherent RPG development; use targeted post-RPG regression instead.

---

# Immediate Next Action

**Runtime-accept Gate E Batch 2 on `gm_flatgrass`, then implement the next complete ordinary-feat family from the 73-entry live-GDD matrix.**
