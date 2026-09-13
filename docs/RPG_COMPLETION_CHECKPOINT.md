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

Checkpoint F is **STATICALLY / DETERMINISTICALLY COMPLETE**; integrated Garry's Mod runtime acceptance remains deferred to Checkpoint G.

## Next work

Proceed to Checkpoint G automated integration and single unified GMod engine human test pass on `gm_flatgrass`.
