# Bestiary B11 automated validation record

Base: `86ec5ff6f2fbf84a36ad1521c5a728b69de64f72` on main.
Native engine entities, traces, health application, rendering and transport are
doubled. These results do not establish native Source acceptance.

## Focused gates

- `test_bestiary_b11.lua`: actual footstep hook, FactionManager acquisition,
  canonical cloak source/forget dispatch, frozen hearing/sight, crouch/quiet/
  invisibility denial, no camera queries, co-op witness, real MotionV2, separate
  canonical melee/GM mitigation/HP boundary, exact source/Hero/run/graph/
  progression/campaign life matrix, finite recovery/late-service retirement,
  status interruption, full hull/support/geometry changes and work caps.
- `test_bestiary_b11_production.lua`:32 seeded generations/replays, usable
  physical classes/feats, growth/HP and once-only shared XP, production unified
  spawning/variance/ordinals, ceiling/idempotence/retries/fallback, complementary
  templates and safe/objective/transition/lateral-pocket/exit admission.
- `test_bestiary_b11_visual.lua`: actual native Draw seam/render bounds,
  full/reduced glyphs, frozen harmless routes, separate damaging melee warning,
  countdowns and death/interruption/distance/fixed-expiry retirement.
- Existing invisibility-ring and prior cohort regressions remain required.
- Review repaired a perception early return that could swallow canonical morale
  locomotion; an explicit real HandleAIFlee dispatch regression now covers it.

## Unchanged production-exposure gate and retained failed trials

Every sample uses512 deterministic plans,32 generated mazes,parties1–4 and
Dungeon Levels1–5. Every sampled identity must reach25 planned/20 legal/5 early;
no threshold, seed set, native-placement predicate or threat ceiling was weakened.
The final sample has4952 encounters; Listener43/41/6, Shy33/30/5.
Selection tickets affect the existing shared seeded template pool only. There is
no seed-specific branching or new director authority. Whole-phase campaign
novelty/theme/pacing work remains outstanding.

| Trial | Identities below the unchanged gate (planned/legal/early) |
| --- | --- |
| 1 | afterburst 24/24/6; carrion 28/26/4; shy 29/28/4 |
| 2 | cantor 24/24/8; wirewright 24/24/8; towline 22/22/5; screenwright 28/24/4 |
| 3 | stitcher 23/23/5; repriser 27/27/4; cordon 22/21/5; reaper 22/20/7; censer 25/24/4; trailmaker 21/18/5; listener 24/22/7 |
| 4 | bulwark 18/17/5; pincer 21/20/7; forker 22/21/7; wirewright 21/20/6; snarer 18/18/6 |
| 5 | repulsor 28/26/2; pavise 23/23/8; reeler 22/22/5 |
| 6 | harrier 20/20/6; caromer 24/23/6 |
| 7 | gaoler 30/30/4; fencer 29/29/4; towline 21/20/9 |
| 8 | redliner 20/20/5 |
| 9 | **All pass** |

Final additional B11 tickets: +1 each Afterburst, Bulwark, Cantor, Caromer,
Carrion, Censer, Cordon, Fencer, Forker, Gaoler, Harrier, Listener, Pavise, Pincer,
Reaper, Redliner, Reeler, Repriser, Repulsor, Screenwright, Shy, Snarer, Stitcher,
Trailmaker and Wirewright; +2 Towline. The earlier Waylayer ticket remains.
No added wandering weights or increase in bodies per encounter.

## Integration and native boundary

One fresh final canonical integration run passed **all181 suites with zero
failures**, after the morale-dispatch repair and its new regression. No gameplay
edits followed that final integrated pass. An earlier181-suite pass preceded
completion of that repair and is not the final acceptance evidence. All prior
cohorts, combat/status/progression, bosses/finale/succession/Abundance/Level21,
repository Lua syntax, release wiring and manual readers/transport remain green.
Live GDD00/01/03/05/07 design, tuning, evidence and continuation were amended and
read-back verified.

After the ordered development phases, test gm_flatgrass footsteps versus crouch,
cooperative geometric sight and occlusion, warning/audio clarity, actual scaled
body travel/support/gates/Walls/false floors, statuses/morale, death/revival/
disconnect, freeze/reset/same-seed rebuild, native HP/reward application,
1–4-player balance/networking, full/reduced effects and all prior cohort/boss/
finale/succession/Abundance/Level21 regressions. Evidence:console_latest.txt +
rpg_summary_latest.txt; detailed session log only for ordering. No deployment or
Workshop publication occurred.
