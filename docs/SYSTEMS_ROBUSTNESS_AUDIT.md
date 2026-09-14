# Systems robustness audit — 2026-09-14

User-directed audit on `hybrid/antigravity`, starting at
`2db9be19f7328c03e52cb6d1de24ac0158f6d34c`. Main promotion remains subject to
Shael's exact-candidate runtime approval. No server or Workshop deployment.

Design navigation: live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
00 → 01 → 02/03/05/06/07, revision
`ANLCKQmY4d8FQ0np0TDKJqTewiNXqFyyuDPrSLM3OOwGX_6GUHcVCfqIgeYjwWCL2nEYtL6iSlfP2bBsY0GRVWemgkqABv831NqVtF7MkA`.
This is implementation repair, not a new balance or roadmap mandate.

## Checkpoint 1 — actor identity, progression and validation authority

- Soldier StateFor/Retire/Award wrongly required Lua `table` objects. Real GMod
  players have type `Player`. One StateFor boundary now resolves both controllers
  and active generated profiles. Repeated attachment preserves an occupied profile;
  retirement revokes captured profile references as well as clearing the controller.
- Soldier damage XP is bounded by the victim's remaining HP, excludes overkill,
  and uses post-defense damage. RunManager's actual personal-life consumption now
  supplies the missing canonical +50 credit to the attacking Soldier.
- Automatic Soldier level-up applies the shared MaxHP authority and queues the
  current sheet. It does not heal the player's existing HP or alter the stored Hero.
- AI and human Soldier eligibility previously diverged on reload/magic capability,
  changing deterministic feat drafts. Both now use the automatic Soldier capability
  set; controller input affordances do not change generated RPG build semantics.
- Automatic progression's post-20 bulk path was unreachable. Stop the milestone
  loop at 20, generate remaining seeded HP dice once, and recompute numeric stats
  once. Level-999 generation matches sequential advancement without quadratic scans.
- Checkpoint E and Soldier lifecycle validators printed FAIL without failing the
  process. They now fail the gate. The Soldier fixtures model GMod entity types;
  retired-reference, overkill, life-credit and live MaxHP assertions use production
  seams. Corrected an incomplete snapshot fixture to represent an active incarnation.

Checkpoint validation: integrated gate **53/53**, including Lua syntax, diff check,
150-entry feat inventory and zero blank descriptions. This is static evidence;
Source-runtime acceptance remains pending. Continue with cross-system lifecycle,
targeting, status scheduling and bounded-work inspection before final handoff.

## Checkpoint 2 — shared opposition and lifecycle transactions

- FactionManager now owns opposition for Magic area selection, Beam/Bolt impacts,
  projectiles and summons. A human-controlled Soldier is an enemy combatant, not
  an ignored cooperative player. Enemy friendly-fire protection covers Soldiers
  and NPCs, retaining the authored Reckless exception. Soldier damage cannot grant
  the controller's stored Hero XP. Soldier control queries use the active-profile
  authority rather than treating a retired profile reference as sufficient.
- Status ticks snapshot actors and entries in deterministic order. Damage callbacks
  can kill, replace, clear or introduce states without causing an old status to
  execute on the new life. Same-seed world replacement and map cleanup invalidate
  bound lifetimes. Empty status tables and inactive Haste entries are released;
  sustained Haste is cleared with the shared life state.
- RunManager makes each death a single life-consumption transaction and coalesces
  wipe evaluation until the current callback batch has completed. Deferred spawn
  work checks the current body serial, living state, campaign and graph before
  applying health, inventory or placement.
- LootDirector owns collection admission, ownership and idempotence. Repeated or
  reentrant Touch/Use/direct calls cannot grant the same pickup twice, including
  duplicated static pickup identities. An unusable pickup remains collectible later.
  Hostile loot handoff also commits once.
- Death Tetris has one action receiver and one mandatory deadline. Removed the old
  line-clear timer reduction and its competing multiplayer override. Clearing lines
  cannot shorten the 20-second wait or its HUD readout. Duplicate preparation cannot
  restart the timer. Normal Hero spawn now restores RPG MaxHP plus earned temporary
  overfill together; the obsolete delayed `100 + bonus` health writer is removed.
  Reconnect/freeze adapters and the existing ordinary/Russian Asset hard caps remain.
- HostileRegistry sorts its rebuilt cache by entity index, giving consumers a stable
  order without adding another recurring world scan.

## Audit coverage and limits

Structural inventory covered **325 production Lua files** (71,196 lines at the
inventory point), 324 distinct named hook pairs, 50 distinct named receivers and
16 literal named repeating timers. This inventory is not a claim of exhaustive
line-by-line or Source-runtime verification.

| Boundary reviewed | Authority / result |
| --- | --- |
| Campaign, admission, lives, Soldiers, reconnects | RunManager and SoldierProgression; identity, life credit, spawn/death and wipe repairs above |
| Generation, topology, navigation, encounters | Existing seeded generation and navigator retained; cached BFS bounded to 72 trees; stable registry iteration |
| RPG growth, acquisition, feats and derived values | Shared progression/feat machinery retained; automatic actor parity and post-20 computation repaired |
| Combat, statuses, Magic and summons | Shared damage/status seams and faction opposition; callback-safe scheduling and controller-independent targeting |
| Individualized resources and rewards | LootDirector collection/handoff transaction; personal life credit authored at actual consumption |
| Networking, presentation and telemetry | Existing coalesced snapshots, bounded logger history and impact effects preserved; no new network channel or decorative HUD panel |
| Persistence and installation | Existing bounded leaderboard, run deduplication and installer safeguards retained; no schema migration or deployment change |
| Bootstrap and legacy replacements | Load-order inspection retained deliberate Magnum, minimap and wayfinding replacements; obsolete Tetris receiver removed |

The integrated gate is **54/54**, including `git diff --check`, project Lua syntax
validation, the approved 150-entry feat inventory with **zero blank descriptions**,
and existing feat behavior/feedback/snapshot regressions. New checks exercise the
production faction, status scheduler, loot and run authorities. The Tetris harness
uses a real board/two-line clear through the actual input receiver; engine transport
and player objects are test boundaries. The feat gate remains static evidence under
the previously approved exclusions, not proof of every feat's Source behavior.

This pass preserves accepted mechanics and does not implement the remaining RPG
roadmap. Instruction Booklet reconciliation and final full-update release acceptance
remain separate release work. No main promotion, workflow retirement, public-server
or Workshop deployment has occurred. A fully restarted Source session, multiplayer
event ordering, engine collision/rendering/audio and sustained networking require
Shael's acceptance of the pushed candidate.

## Focused integrated acceptance

1. Fully quit GMod before updating the checkout/install; start a fresh `gm_flatgrass`
   campaign. Complete normal character/feat selection and deploy. Check sheet values,
   live HUD, DIE-LOGGER and ordinary combat/loot.
2. Use a Hero with MaxHP other than 100. Die with lives remaining, clear Tetris lines,
   and verify F remains unavailable until 20 seconds, then respawns at MaxHP plus
   earned overfill. Repeat after an immediate death and after a level transition.
3. With a second player controlling a Soldier, test Beam/Bolt, Bomb/Missile splash,
   Blast and summons against that Soldier. Check allied Heroes remain excluded,
   Soldier/NPC friendly fire is blocked except authored Reckless, and Soldier XP/
   level/sheet update without altering the stored Hero. A consumed Hero life grants
   +50 Soldier XP in addition to effective damage XP.
4. Combine statuses and Haste with death/respawn, Soldier retirement and level change;
   verify effects/cooldowns do not survive their old life. Reconnect both an eligible
   dead Hero and an eliminated player; test Soldier/return-to-Hero selection.
5. Exercise repeated Touch/Use on individualized loot and a multi-kill area attack.
   Check one reward per pickup, truthful damage feedback, visible impact boundaries,
   and no reliable-channel disconnect. Continue through a gate and rescue if practical.
6. Return console, RPG summary/session and DIE-LOGGER history with the installed SHA.
   This candidate still needs runtime approval; static green is not promotion approval.
