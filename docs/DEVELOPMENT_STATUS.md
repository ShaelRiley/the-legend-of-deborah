# Development status

## Milestone 1 — The Labyrinth

Status: **implementation underway; in-engine acceptance not yet passed**.

### Implemented

- [x] Gamemode structure.
- [x] Campaign and level seed infrastructure.
- [x] Deterministic local PRNG and substreams.
- [x] 21×21 layered logical graph generation.
- [x] Partial 2–3 layer occupancy and rare fourth layer.
- [x] 3–6 forced vertical transitions in the canonical spine.
- [x] Perfect-maze spanning tree plus controlled loops.
- [x] Logical connectivity validation.
- [x] Critical-route minimum vertical-transition validation.
- [x] Deterministic failed-layout retry sequence.
- [x] Shipping-container wall builder.
- [x] Elevated floor geometry.
- [x] Broad mandatory stairs and rail collision.
- [x] Generated-entity registry and cleanup.
- [x] 1–4 active-player admission for Milestone 1 traversal tests.
- [x] Unique randomized eligible character assignment for active players.
- [x] Developer graph visualization.
- [x] Safe regeneration command.
- [x] Multi-seed logical validation command.
- [x] Cross-process deterministic topology regression hash.
- [x] First 1,000-seed logical sweep: 0 failures, minimum 3 critical-route vertical transitions.

### Must be verified/fixed in Garry's Mod before Milestone 1 completion

- [ ] Confirm all configured player model paths and Deborah's reserved model in the live mounted content set.
- [ ] Confirm `cargo_container01.mdl` collision orientation/bounds and wall lattice alignment.
- [ ] Confirm stair geometry is comfortable under ordinary HL2 movement without collision snagging.
- [ ] Confirm elevated floor apertures permit bidirectional stair traversal.
- [ ] Confirm no container/floor/stair overlaps create blocked graph edges.
- [ ] Confirm no wall-top or arbitrary-drop bypasses in representative 2-, 3-, and 4-layer seeds.
- [ ] Confirm spawn safety for 1–4 simultaneous players.
- [ ] Measure typical/worst generation/build time against ≤5s / ≤10s targets.
- [x] Run at least 100 logical seed tests during M1 development. Current headless suite has passed 1,000 seeds twice with identical topology hash `981725631`; Milestone 6 still requires full release-qualification automation in the target runtime.
- [ ] Conduct listen-server and dedicated-server smoke tests.

### Git

Foundation checkpoint: `dd56188` (`Establish Milestone 1 labyrinth foundation`). The current connected GitHub tooling can inspect/write existing repositories but does not expose repository creation, so a new remote cannot be created from this environment unless an empty repository is created through another available GitHub path.
