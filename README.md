# The Legend of Deborah

Real Garry's Mod gamemode implementation of **The Legend of Deborah**.

The production GDD linked in the ChatGPT Project is the authoritative design specification. This repository is implementation, tests/debug tooling, and release history; it does not supersede the GDD.

## Current milestone

**Milestone 1 — The Labyrinth (in progress)**

Implemented in the initial development baseline:

- Standard Garry's Mod gamemode structure derived from `base`, not Sandbox.
- Server-authoritative campaign seed and deterministic level-seed derivation.
- Internal deterministic Park-Miller RNG with derived substreams; no global `math.randomseed` mutation.
- 21×21 layered logical-cell maze generation.
- 2–3 partial layers normally, rare fourth layer.
- Forced canonical spine with 3–6 vertical transitions.
- Occupancy targets matching the GDD's initial bands.
- Perfect-maze spanning-tree backbone plus controlled 5–10% loops.
- Connectivity and critical-route vertical-traversal validation with deterministic regeneration attempts.
- Frozen HL2 cargo-container wall construction on `gm_flatgrass`.
- Elevated industrial floor collision/render geometry.
- Broad 16-step mandatory stair transitions with side rail collision.
- 1–4 active players with randomized unique eligible HL2 character models.
- No player-player collision, no Sandbox building affordances, and no friendly fire.
- Developer graph visualization, validation report, regeneration, and multi-seed generation test commands.

## Install for local Garry's Mod testing

Copy or symlink `gamemodes/legend_of_deborah` into your Garry's Mod `garrysmod/gamemodes/` directory, then start `gm_flatgrass` with the `legend_of_deborah` gamemode.

Useful developer commands:

- `lod_debug_graph` — draw the authoritative logical graph for 30 seconds.
- `lod_validation` — print current seed validation metrics.
- `lod_regenerate [levelSeed]` — safely tear down and rebuild the current level; explicit seed marks the run unranked.
- `lod_seed_test [count]` — generate/validate many logical mazes without spawning their geometry.

## Runtime verification still required

This execution environment does not contain Garry's Mod itself, so the initial code can be statically reviewed and determinism-tested here but cannot yet be honestly declared Milestone 1-complete. In-engine verification must confirm collision, exact model variants, stair feel, generation time, geometry overlap, and wall-top/bypass behavior before the Milestone 1 checkpoint commit is made.
