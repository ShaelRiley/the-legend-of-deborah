# Stair collision repair

The shared walking bypass is fixed in tested source `54bf0698`: ordinary and legacy boss ground movement now respects actual generated stair solids. Valid flights use supported full-hull waypoint positions and up/across/down sweeps; blocked horizontal paths take a clear two-corner detour. Active stair commitments survive local chase goals, and geometry recovery cannot teleport across stair solids. No geometry, enemy counts, combat timing or AI cadence was reduced.

Lua5.4/LuaJIT:56cases,1084 supported steps,9138 geometric boundary traces; all four orientations, full flights, bosses, large-step tunneling, Z snaps, detour completion and lifecycle invalidation. Retained source fails the penetration regression. These tests double engine boundaries.

Actual Steam Deck/GMod validation passed all9 required physical cases on a generated W-oriented flight: ordinary and Warden/Hector/Neil/generic-boss flags crossed safely around the obstruction, and ordinary/generic actors completed ascent and descent. Native TraceHull checked actual tread/rail/landing collision after every step. All providers, actors and frozen state restored. The test uses paused AI and a32×72 hull; it does not replace full boss-AI, all authored hulls or ordinary-play coverage.

The initial native fixture had an incorrect public-function source assertion and failed before movement. The public method is legitimately wrapped by device-motion safety. The failed helper and correction are preserved; four production file hashes and core physical-method sources still verify.

Performance work resumed with a corrected-build profiler-off D20 attempt. It failed the client bridge renewal before FPS capture. That failure is preserved; no new baseline, source gain or40FPS claim. Earlier optimizer results cannot validate this changed movement code.

The owned game is stopped, helpers/providers restored and all120 installed hashes verify. Both displays remain ON. PR7 stays draft; main unchanged; full five-scenario warmed repeated180s,ordinaryplay/fullboss and40-cap acceptance remain unverified. Resume from a successful corrected-build baseline next; no automatic new checkpoint.
