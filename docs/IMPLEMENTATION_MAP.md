# Implementation map

| GDD responsibility | Current module |
|---|---|
| Campaign/level seeds, campaign state, active-player admission, character assignments, regeneration | `gamemode/lod/sv_run_manager.lua` |
| Central tuning constants and verified/verify-at-runtime asset paths | `gamemode/lod/sh_config.lua` |
| Deterministic PRNG/substreams and level seed derivation | `gamemode/lod/sh_rng.lua` |
| 3D logical occupancy, mandatory spine, perfect-maze tree, loops, validation | `gamemode/lod/sv_maze_generator.lua` |
| Graph-to-world walls, floors, stairs, cleanup, cell/world transforms | `gamemode/lod/sv_maze_builder.lua` |
| Exact static box collision/render primitive used by floors/stairs/rails | `entities/entities/lod_static_box/` |
| Admin regeneration, validation, seed suites, graph transmission | `gamemode/lod/sv_debug_tools.lua` |
| Client-only graph visualization | `gamemode/lod/cl_debug.lua` |
| ProgressionDirector | Milestone 2 |
| EncounterDirector / MazeNavigator / FactionManager | Milestone 3 |
| LootDirector | Milestone 4 |
| Warden/Deborah final sequence | Milestone 5 |
| HUD beyond developer visualization | Begins Milestone 2, hardened through Milestone 6 |
