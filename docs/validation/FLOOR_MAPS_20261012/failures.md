# Preserved development failures

- The first new path fixture lacked the native table.Count double: sv_maze_generator.lua:196 reported a nil Count. Adding the missing native boundary made the real 48-layout test pass.
- The integration fixture initially treated RunManager:BuildCurrentLevel’s second return (the graph) as a build report; line 24 failed. It now reads RunManager.State.BuildReport, preserving the actual return contract.
- The first loot reservation edit matched _RewardCells but left _SectorCandidates unchanged. The full integration gate reported `tools/test_floor_maps_integration.lua:29: ordinary loot occupies map access path`. Both canonical selectors now exclude the reserved path, and the same full-build assertion passes.
- Google Docs returned HTTP 400 FAILED_PRECONDITION / “Precondition check failed.” for scoped 05/06/07/HUMAN inserts and tutorial replacement, with and without revision guards. These atomic failures did not mutate those tabs. Scoped 00/01 insertions, pointer correction and body-style updates succeeded. Do not report the live subsystem/tutorial mirrors as updated.

These are development/fixture failures, not failed native Garry’s Mod observations. Final raw passing streams and unchanged-source receipt are in this directory.
