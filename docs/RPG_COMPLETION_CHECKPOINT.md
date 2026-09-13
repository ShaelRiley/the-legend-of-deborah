# Integrated RPG Completion Checkpoint

**Updated:** 2026-09-13
**Development branch:** `hybrid/antigravity`
**Accepted main reference:** `f7da934b33d250e4d7e032f6d66f404d0f80f4ac`
**Canonical GDD:** `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`  
**GDD revision:** `ANLCKQmjFx3fTZxP09CRHVOO_fgMiaXVXqAh6lf_by1mKt0ExbMSE6x7KN8nMl4VxCrNKupQ0i-Q_x77o7aZgX6sumGBgseGHr39gD8Y6Q`

## Current preservation point

Checkpoints A, B, C, D, E, and F are statically and deterministically complete; integrated Garry's Mod runtime acceptance remains deferred to Checkpoint G.

### Checkpoint F — Heroes of Legend Leaderboard Closure (AG-009 / AG-009R1)

Task **AG-009R1** completed the server-local HEROES OF LEGEND completed-run leaderboard authority, persistence, wall-board display, and tie-break resolution:

- **Canonical Ranking & Tie Rule:** 
  - Primary ranking: Deborah rescue count, descending (`rescueCount` DESC).
  - Canonical tie-break: Equal rescue count → earlier completed party run ranks higher (`completionOrder` ASC).
  - Unrelated record properties (alphabetical party member text, player SteamID, timestamp, etc.) do NOT affect ranking.
- **Completion Sequence Mechanism:**
  - Implemented server-authoritative monotonic completion counter (`completionOrder`) in `sv_heroes_of_legend.lua`.
  - Assigned exactly once when a qualifying party run completes; monotonically increasing within persisted leaderboard history (`the_legend_of_deborah/heroes_of_legend.json`); immutable after assignment.
  - Idempotent `SubmitRun` guards run identity (`runId`), updating rescue counts without creating duplicate records or consuming new sequence numbers.
- **Top 10 Cutoff Behavior:**
  - Canonical sorting (`rescueCount` DESC, `completionOrder` ASC) applied before truncation.
  - At the #10/#11 boundary, earlier equal-scoring runs remain above later equal-scoring runs; later runs cannot displace earlier equal-scoring runs.
- **Staging Hut Wall-Board Entity:**
  - Registered `lod_heroes_of_legend_board` entity beside `lod_staging_mirror` in `sv_staging_deployment.lua:EnsureRoomDecor()`.
  - Client 3D2D renderer (`cl_init.lua`) renders top 10 runs with wording contract: `<PartyRunMemberList> — Rescued Deborah <N> time` (if N=1) / `times` (if N!=1).
- **Validation:**
  - Created 22-point deterministic validator `tools/test_checkpoint_f_closure.lua` passing all requirements (ranking order, completion sequence monotonicity, top-10 cutoff stability, idempotency, persistence save/load, and text formatting contract).
  - All static syntax checks and regression suites (`test_soldier_character_sheet.lua`, `test_checkpoint_e_closure.lua`) pass with 0 errors.

Checkpoint F is **STATICALLY / DETERMINISTICALLY COMPLETE**.

## Next work

Proceed to Checkpoint G automated integration and single unified GMod engine human test pass on `gm_flatgrass`.
