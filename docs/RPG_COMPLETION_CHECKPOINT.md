# Integrated RPG Completion Checkpoint

**Updated:** 2026-09-13
**Development branch:** `hybrid/antigravity`
**Accepted main reference:** `f7da934b33d250e4d7e032f6d66f404d0f80f4ac`
**Canonical GDD:** `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`  
**GDD revision:** `ANLCKQmjFx3fTZxP09CRHVOO_fgMiaXVXqAh6lf_by1mKt0ExbMSE6x7KN8nMl4VxCrNKupQ0i-Q_x77o7aZgX6sumGBgseGHr39gD8Y6Q`

## Current preservation point

Checkpoints A, B, C, D, and E are statically and deterministically complete; integrated Garry's Mod runtime acceptance remains deferred to Checkpoint G.

### Checkpoint E — Static & Deterministic Closure (AG-008 / AG-008R1 Repair)

Task **AG-008R1** repaired character sheet snapshot compatibility, deep multi-scenario RPG parity validation, and contract testing for Checkpoint E:

- **AI/Human Soldier RPG Parity:** Verified 100% deterministic RPG generation parity between `human_soldier` and `ai` actor types across 5 distinct dungeon level / seed scenarios (`DL 1`, `DL 5`, `DL 10`, `DL 20`, `DL 25`), comparing all shared RPG build fields byte-for-byte (`tierId`, `dungeonLevel`, `level`, `classId`, `primaryAbility`, `secondaryAbilities`, `baseAbilities`, `growthAbilities`, `fighterTraining`, `effectiveAbilities`, `progressionHitDieSides`, `hitDieRollsByLevel`, `featSlotsGranted`, `featIds`, `featStackCounts`, `classCapstoneFeatId`, `capabilityTags`, `contentIds`, `usesMagic`, `derivedStats`).
- **Character Sheet Snapshot & Renderer Contract:** Repaired `CPS:BuildClientSnapshot(ply)` for Soldiers:
  - Empty `identityTraits = {}` array to prevent Hero trait schema dereference crashes.
  - Full ability row schema (`score`, `modifier`, `role`, `base`, `growth`, `fighterTraining=0`, `identity=0`, `feat`, `label`).
  - Enriched hit-die ledger rolls (`level`, `formula`, `values`, `total`, `conBonus`, `hpGain`, `capped`).
  - Authoritative `featSlotsGranted` and `featStackCounts` for ordinary feats ledger.
  - Read-only capstone definition snapshot (`resolved = true`, `selected = true`) for Level 20 Soldiers.
- **Client Sheet Renderer:** Updated `cl_character_sheet.lua` with dedicated `"Soldier Incarnation"` role panel and `"Soldier progression d8"` label.
- **Contract Test Suite:** Created `tools/test_soldier_character_sheet.lua` exercising production `BuildClientSnapshot` and emulating client widget traversal with 0 errors.
- **4 + 6 + 10 Config Contract:** Enforced `CC.MaxActivePlayers = 4`, `CC.MaxActiveSoldiers = 6`, and `CC.Campaign.MaxPlayedIdentities = 10` in `sh_config.lua`.
- **Auto Runtime Hook Removal:** Removed `InitPostEntity` autostart hook from `sv_human_soldier_runtime_validation.lua`.
- **Authored-Content Ambiguity:** `CANONICAL SOLDIER NAMING DETAIL UNDEFINED` in live GDD; using `"Human Soldier"` as presentation fallback.
- **Engine Runtime Acceptance:** Garry's Mod engine runtime acceptance is explicitly deferred to Checkpoint G.

Checkpoint E is **STATICALLY / DETERMINISTICALLY COMPLETE**.

## Next work

Proceed to Checkpoint F static/deterministic closure according to execution policy, followed by Checkpoint G automated integration and single unified GMod engine human test pass on `gm_flatgrass`.
