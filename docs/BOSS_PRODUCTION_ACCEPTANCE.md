# Modular boss production and finite acceptance

Source parent: `96ab02aa78254eed9bfccb5b06dca947b82abd9f` on canonical `main`.
Design: the original live Google GDD, ID `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`, navigated through 00 → 01 → 05/06/07. The complete original-body reconciliation was readback-verified before gameplay implementation. All twenty authored boss blocks, Chuck/Jane authority, timer-only automatic failure/retention and safe authored key-drop exceptions govern this work. Original comment provenance remains intact.

## Authored identity and production architecture

The shared registry fixes the exact order through Dungeon 20. Gordon remains at 1 and 20; eighteen new primary identities occupy 2–19. Jane is subordinate to Chuck at 14. Gordon 1 has no clones/turrets. Gordon 20 has exactly four clones and four Sentries before the existing Hector handoff; partial native composition rolls back instead of silently accepting fewer actors. The prior endless path remains unchanged; this revision does not invent a 21+ selection policy.

The common encounter owner controls immutable campaign/run/graph/epoch identity, frozen party snapshots, exact native actor lives, phase work, budgets, genuine defeat receipts, delayed safe keys, client snapshots and cleanup. Actual attacks enter the existing CombatRolls, EnemyRoster, status, Pushback, Motion V2, native death, attribution and loot authorities. No separate boss HP/status/damage engine or uncontrolled physics simulation is introduced.

Every module implements its own authored state machine, interactables and finite signatures. Melf has immutable executable Mirror Kits and genuine multi-body succession; Button uses baseline reachable E-only segments; Joilette tracks exactly three unique Cleaner opportunities and persistent BDD progress. Chuck has his own citizen/beaver body and three distinct wood classes; Jane retains the complete propane vocabulary and can never complete the encounter. Gunship flight and Strider movement use bounded authored paths and proper body bounds. Scene props are harmless, finite and cannot create keys or rewards.

Arena geometry shares the existing graph/floor/stair/lock system. Authored additions include real shallow bowl/loading-ramp/drainage support surfaces, cover, aisle/traffic/roadwork objects, validated safe routes, protected entrance and a separate jail. Native movement sweeps the true body hull; moved solid hazards must retain required routes. The finite death scene and first key use the same absolute deadline. Authored drop locations are captured before native corpse removal; a missing key is recoverable without another receipt.

Exact chosen values are in [BOSS_IMPLEMENTATION_TUNING.md](BOSS_IMPLEMENTATION_TUNING.md) for live tab-07 reconciliation. Authored fixed counts/roles/order remain design law rather than tuning.

## Source validation gate

Publication requires the current complete registered matrix on a frozen source snapshot, including all new boss suites, the previously omitted Gordon dancefloor wrapper, existing actor/combat/feat/lifecycle/progression/event/music/manual/VR regressions, release wiring and every Lua syntax check. Use a new evidence directory outside the checkout:

`python3 tools/test_checkpoint_g_integration.py --workers 4 --suite-timeout 600 --output /tmp/lod-boss-final-gate`

The gate records every result and source manifests; success requires identical before/after source digests. Independent Lua 5.1 parsing covers production files under `gamemodes/` and `lua/`; existing headless harnesses intentionally target Lua 5.4. Run the complete music/VR gates and manual check on the same final source. The exact publication commit, remote readback and final receipts accompany delivery. A focused suite or source inspection is not a full gate.

The production integration harness loads real registry/modules, arena planning, RPG progression/variance, CombatRolls, EnemyRoster packets, source/target lives, Pushback, Motion V2, native hostile/static-box initialization, deferred death and key/jail/rescue. Only engine boundaries are emulated. It includes rejected allocation/Start rollback, source/target reincarnation, nested callbacks, manual fuses, canceled motion, no-Hero retention, three Cleaners, Melf recovery, both Chuck/Jane orders and Gordon→Hector. Separate production client parsing covers all eighteen snapshot/ghost lifetimes. A continuous baseline 150-unit/second route-and-E test completes Button solo, two-player and four-player cycles without teleport or direct damage shortcuts.

Independent review reproduced and required repair of genuine failures, including growing Mirror Kits after failed spawns, lost Melf bodies, airborne floor penetration, canceled charge deadlocks, stale-life delayed damage, swallowed contact damage, route/Push admission gaps, static death props and invalid removed-body key access. Keep failed evidence; do not reinterpret repaired source defects as native success.

## Native acceptance remains open

No native GMod session, live Source collision/model rig, rendered cooperative encounter or Steam Deck performance run was available in this environment. Headless geometry/input/render-boundary tests do not establish those outcomes. Workshop/VPS publication is outside this task.

After installing the exact source commit, fully restart GMod, choose The Legend of Deborah on `gm_flatgrass`, and use an unranked developer session. For one selected dungeon, set `lod_developer_mode 1; lod_boss_test_level 14`, deploy normally, then `lod_boss_testkit; lod_boss_status`. The first command explicitly builds the chosen 1–20 dungeon; the testkit reaches its entry without granting defeat/key/rescue. Existing Gordon diagnostics remain available. Do not skip special completion by console damage.

Traverse the twenty identities, observing their actual telegraphs, physical embodiment, interactions and unique recovery windows. Prioritize:

1. Chuck/Jane both defeat orders: primary title/HP stays Chuck; Jane neutralization never grants a key; Chuck retires all remaining wood/propane work
2. Melf solo and mixed classes: immutable kits, skeleton/native-body replacement, giant source disconnect, correct one-time completion
3. Button baseline routes, distant real/fake cues, E holds/paired windows, timeout retry, Big Red then separate Jail Key button
4. Joilette BDD immunity to all weapon/Magic/status channels, three unique successful throws, miss/loss/death/rejoin recovery, no Cleaner farming after break
5. Permanent cover, actual aerial clearance, Strider knees/underbody routes, moved solids, flight/large-body routes and cancellation-safe recovery
6. No-Hero elimination/reconnect/fresh-Hero entry retaining HP/phase/mandatory progress; timer expiry and same-seed rebuild retiring old work; exactly one reachable key followed by normal jail/rescue
7. Gordon 1 composition, Gordon 20 exact composition, preserved phase-one dance/tells/turrets, then genuine Hector receipt before the final key
8. Client stale snapshot/map cleanup/hot reload, death-scene/ghost transitions, tactile movement/collision, cue audio and low-end frame cost

Use `console_latest.txt` plus `rpg_summary_latest.txt`; add `rpg_session_latest.txt` only if event order needs clarification. Screenshots/video are appropriate for model alignment or visual geometry. Preserve previous native feat, music-listening and hit-stun floor acceptance debts. Source publication, native acceptance, Workshop parity and VPS deployment are distinct states.
