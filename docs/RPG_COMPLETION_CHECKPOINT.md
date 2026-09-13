# Integrated RPG Completion Checkpoint

**Updated:** 2026-09-13
**Development branch:** `hybrid/antigravity`
**Accepted main reference:** `f7da934b33d250e4d7e032f6d66f404d0f80f4ac`
**Canonical GDD:** `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`  
**GDD revision:** `ANLCKQmjFx3fTZxP09CRHVOO_fgMiaXVXqAh6lf_by1mKt0ExbMSE6x7KN8nMl4VxCrNKupQ0i-Q_x77o7aZgX6sumGBgseGHr39gD8Y6Q`

## Current preservation point

Checkpoints A, B, C, D, and E are statically and deterministically complete; integrated Garry's Mod runtime acceptance remains deferred to Checkpoint G.

### Checkpoint E — Static & Deterministic Closure (AG-008)

Task **AG-008** completed the static and deterministic requirements of Checkpoint E:

- **AI/Human Soldier RPG Parity:** Verified 100% deterministic RPG generation parity between `human_soldier` and `ai` actor types via `LOD_CPS:GenerateMonsterProgression("soldier", seed, level, 35, actorType)` across all 11 progression fields (`tierId`, `level`, `classId`, `primaryAbility`, `growthProfile`, `baseAbilities`, `effectiveAbilities`, `progressionHitDieSides`, `derivedStats` including `maxHP`, `featIds`, and `featStackCounts`).
- **4 + 6 + 10 Config Contract:** Enforced `CC.MaxActivePlayers = 4`, `CC.MaxActiveSoldiers = 6`, and `CC.Campaign.MaxPlayedIdentities = 10` in `sh_config.lua`.
- **Read-Only Character Sheet & Choice Guard Rails:** Updated `CPS:BuildClientSnapshot(ply)` for Soldier control to return full read-only RPG snapshot metrics (`readOnly = true`, abilities, hit die rolls, ordinary feats, derived stats, SoldierXP thresholds). Blocked `CommitClass`, `CommitFeat`, `CommitCapstone` RPCs for Soldier callers with `"Soldier progression choices are read-only."`. Updated `cl_character_sheet.lua` to render clear Soldier read-only indicators.
- **Auto Runtime Hook Removal:** Removed `InitPostEntity` autostart hook from `sv_human_soldier_runtime_validation.lua`, keeping explicit validation concommands `lod_rpg_ag007r2_runtime_validate` and `lod_rpg_ag008_runtime_validate`.
- **20-Point Deterministic Test Suite:** Created `tools/test_checkpoint_e_closure.lua` verifying all 20 required Checkpoint E requirements with 0 discrepancies.
- **Engine Runtime Acceptance:** Garry's Mod engine runtime acceptance is explicitly deferred to Checkpoint G.

Checkpoint E is **STATICALLY / DETERMINISTICALLY COMPLETE**.

## Next work

Proceed to Checkpoint F static/deterministic closure according to execution policy, followed by Checkpoint G automated integration and single unified GMod engine human test pass on `gm_flatgrass`.
