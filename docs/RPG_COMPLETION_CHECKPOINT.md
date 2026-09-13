# Integrated RPG Completion Checkpoint

**Updated:** 2026-09-13
**Development branch:** `hybrid/antigravity`
**Accepted main reference:** `f7da934b33d250e4d7e032f6d66f404d0f80f4ac`
**Canonical GDD:** `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`  
**GDD revision:** `ANLCKQmjFx3fTZxP09CRHVOO_fgMiaXVXqAh6lf_by1mKt0ExbMSE6x7KN8nMl4VxCrNKupQ0i-Q_x77o7aZgX6sumGBgseGHr39gD8Y6Q`

## Current preservation point

Checkpoints A, B, C, D, E, and F are statically and deterministically complete; integrated Garry's Mod runtime acceptance remains deferred to Checkpoint G.

### Checkpoint F — Heroes of Legend Leaderboard & Staging/UI Static Closure (AG-009R2)

Task **AG-009R2** repaired HEROES OF LEGEND run-end submission and completed Checkpoint-F deterministic static gate:

- **Canonical Run-End Submission Seam:**
  - Removed HEROES OF LEGEND submission from level-clear (`CompleteLevel`).
  - Added `RunManager:FinalizeCampaignRun()`, called exclusively from canonical campaign end transaction (`FailCampaign`), using final accumulated `RescueCount`.
- **Ranked Eligibility Seam:**
  - Evaluated `State.Ranked == true` prior to submission. Unranked runs submit no entry, alter no ranking, and consume no completion order.
- **Participant Authority:**
  - Participant set derived from `RunManager.State.PlayedIdentities` and `PlayerState` ordered deterministically by `ps.ordinal` ASC.
  - Includes connected, disconnected, eliminated, and Soldier-role participating heroes. Excludes spectator visitors. Does not list Human Soldier incarnation as separate entry.
- **PlayerCharacterText Authority:**
  - Derived using canonical `CharacterProgressionSystem:PlayerCharacterText(plyOrState)` (`<nick> as <heroDisplayName>`), supporting both connected and disconnected participating heroes.
- **Immutability & Duplicate Protection:**
  - Completed run records are immutable (idempotent NO-OP on re-submission; shallow snapshot copy of `partyMembers`).
  - Server-session `ProcessedRunIds` table prevents duplicate submissions for truncated low-scoring runs from consuming sequence numbers.
- **Canonical Ranking & Exact Wording:**
  - Primary ranking: `rescueCount` DESC; tie-break: earlier completed party run (`completionOrder` ASC).
  - Exact presentation wording: `<PartyRunMemberList> rescued Deborah <RescueCount> times`.
- **P Character Sheet & I Spellbook Gates:**
  - Hero P snapshot remains authoritative and read-only for Soldier.
  - Spellbook exposes 6 canonical Forms (Blast, Beam, Bomb, Missile, Bolt, Summon) and RAW + 6 Contents (Earth, Fire, Dark, Ice, Light, Electric) matching production `MagicProgression` state with P/I UI mutual exclusion.
- **Validation:**
  - 54-point deterministic validator `tools/test_checkpoint_f_closure.lua` passing all requirements (A through X) with 0 discrepancies.
  - Passed all regression suites (`test_soldier_character_sheet.lua`, `test_checkpoint_e_closure.lua`, `test_checkpoint_c_headless.lua .`, syntax check).

Checkpoint F is **STATICALLY / DETERMINISTICALLY COMPLETE**.

### Checkpoint G — Integrated Validation & Playtest Candidate (AG-010)

Task **AG-010** constructed the integrated automated RPG validation gate and prepared the playtest candidate for Shael's single organic `gm_flatgrass` session:

- **Playtest Candidate SHA:** `[HEAD]`
- **Integrated Automated Gate Runner:** `tools/test_checkpoint_g_integration.py`
- **Suite Matrix Results:** 24/24 test suites passed with 0 failures (`CHECKPOINT_G_AUTOMATED_GATE_PASS`), covering:
  - Actor core, Level caps (Hero 20 / Monster 999), 60/30/10 tier generation, fixed named tiers, monster D+3 ceiling;
  - Status & Element core matrices, damage->survival->rider ordering, tick damage recursion safety;
  - Magic 6 Forms (Blast, Beam, Bomb, Missile, Bolt, Summon) and 6 Contents (Earth, Fire, Dark, Ice, Light, Electric) + RAW state;
  - Feat registry equality (124 ordinary feats + 9 class capstones), Hero 1/3/6/9/12/15/18 cadence, prerequisites, replacement ladders;
  - Human Soldier RPG progression, XP (+1 HP / +50 life loss), 100/250/450 thresholds, reincarnation reset, lifecycle queue isolation;
  - Staging & UI (P Character Sheet, I Spellbook mutual exclusion, read-only Soldier snapshot);
  - HEROES OF LEGEND leaderboard run-end submission, ranked eligibility, participant authority, immutability, tie order, and exact wording;
  - All protected regression families (Deadeye, Crowbar, Pusher, Map Movement, Quantum, Strafe, Backpedal, Winning Personality, Deadcrab Dispatch, Dev Ingress, Control Magic, Magic Recovery).
- **Subsystem & Seam Validation:** `lod_rpg_validate` extended to verify `MagicProgression`, `HeroesOfLegend`, and `SoldierProgression` subsystem authorities without destructive state modification.
- **Evidence Integrity & Telemetry:** Verified `console_latest.txt` and `rpg_summary_latest.txt` evidence export path. No static/headless script writes to engine `console.log` or `garrysmod/data/`.
- **Local Playtest Candidate:** Installed via `tools/install_dev.sh` to local Garry's Mod dev checkout. Prepared `PLAYTEST_SHAEL.txt` instructions for ONE ~15–20 minute organic `gm_flatgrass` human play session.
- **Voluntary Termination Seam:** Verified that campaign restart is currently scoped to `State.Failed == true` (total party wipe). Recorded `VOLUNTARY RUN TERMINATION PLAYER-FACING SEAM NOT YET IMPLEMENTED` as post-RPG release follow-up.

**CHECKPOINT G AUTOMATED GATE COMPLETE**
**HUMAN RUNTIME GATE PENDING**

## Next work

Shael Riley organic 15–20 minute `gm_flatgrass` human play session using candidate `[HEAD]`, followed by evidence review by Sol for final integrated RPG completion acceptance.
