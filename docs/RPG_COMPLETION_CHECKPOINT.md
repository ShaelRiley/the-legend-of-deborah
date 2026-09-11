# Integrated RPG Completion Checkpoint

**Updated:** 2026-09-10  
**Accepted branch:** `main`  
**Current remote HEAD:** `09688f7dd8861a719266b20e51550bc56d723368`  
**Checkpoint C base:** `bb8e365dda2c6b655de48725ce09a9061fd61a1e`  
**Canonical GDD:** `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`  
**GDD revision after D status-proc reconciliation:** `ANLCKQmlzah9ZwI-_paNfuziK3DhYmVkwcNhu6iNplw_avI19r6YGo0zNW6s7nsQg8fIxL03rn6sHCQoYAW-uzw-Yo3tL11xbCa4CCUkEw`

## Current preservation point

Checkpoints A, B and C are statically complete; integrated Garry's Mod runtime acceptance remains pending.

Checkpoint D is **in progress**. The first coherent D tranche completes the shared offensive status-proc feat families through the existing Checkpoint-B status/Morale authority:

- 27 canonical feat IDs across 9 ranked families: Poison, Clumsy, Immolated, Arcane disruption, Bleeding, Muted, Held, Reckless and Intimidation/Morale.
- Common ranks use 11% / 22% / 33%; only the highest owned rank applies.
- Hero, AI and human-Soldier eligibility uses the existing FeatDirector path; automatic progression now removes superseded lower family ranks.
- Procs require attributable positive final HP damage that leaves the target alive. Status damage, self/environmental damage and non-attributable damage are excluded.
- Guaranteed same-condition riders suppress the redundant feat-family proc in accordance with normalized `LOD-STATUS-002` and the exact current feat rows.
- Arcane disruption remains a nonmagical physical-hit exception that uses the shared Arcane Integrity/shatter authority.
- Intimidation procs use the shared Morale authority rather than a parallel fear system.

### Static evidence

- `texluac -p` PASS: `sv_rpg_checkpoint_d_status_catalog.lua`
- `texluac -p` PASS: `sv_rpg_checkpoint_d_status_runtime.lua`
- `texluac -p` PASS: `sv_rpg_checkpoint_d_status_validation.lua`
- deterministic Lua status-proc harness: `STATUS_HARNESS_PASS`
- runtime command added: `lod_rpg_validate_status_procs`

This tranche is **implemented/statically validated, not runtime accepted**.

### D core feat slice — implemented 2026-09-11

- `STR_STEAMROLLER` now changes only a successful shared push save to retain 50% of SizeAdjustedPushDistance; PushImmune, DCs, failures, defender multipliers, collision, and wall-crush continuation remain shared authority.
- `CON_BIG_GUY` provides the authored 1.30 presentation/target scale, 1.15 melee-reach multiplier, and 1.20 outgoing physical-push multiplier through derived state.
- `CON_NOT_YET` preserves one HP and applies its 0.50-second protection once per owning actor per dungeon through the final damage seam; the consumed state is retained in progression state across reconnects.
- Validation: pure-Lua `tools/test_checkpoint_d_core_feats.lua`, changed-file syntax checks, actor progression, status/element, and Checkpoint-C static validators PASS.

### E Soldier progression core — implemented 2026-09-11

- A human Soldier now has a distinct disposable incarnation progression state. It is generated through the same deterministic Soldier/AI generator and automatic selection path, uses Soldier d8 growth, and never mutates the underlying cooperative Hero package.
- SoldierXP is server-authoritative: credited effective Hero HP damage adds 1 XP per whole HP; threshold state is 100/250/450 for +1/+2/+3 earned levels; the resulting level is clamped to the Soldier spawn level plus earned levels and the current `D+3`/999 ceilings. A dedicated `Award(..., lifeConsumed)` API reserves the authored +50 personal-life credit for the lifecycle owner rather than guessing from a pre-death damage callback.
- Existing actor progression now exposes `AdvanceAutomaticActor`, shared by AI and Soldiers while retaining Level-21+ linear generation and zero post-20 feat/capstone grants.
- Validation: expanded `tools/test_actor_progression.lua` PASS, including deterministic Soldier generation, Soldier d8, thresholds, automatic level-up, and ceiling behavior. Syntax and adjacent status/core-feat/Checkpoint-C validators PASS.

## Next work

Continue Checkpoint D's remaining canonical feat/capstone inventory by shared handler families, then complete E's role admission, life-consumption credit, retirement/reincarnation and P-sheet integration on top of the preserved Soldier progression authority. Do not redo A-C or the status-proc/core-feat tranches absent contradictory evidence.

If autonomous compute is limited, finish/validate/commit/push the currently active coherent D family before starting another. Human runtime testing remains deferred to the integrated Checkpoint-G playtest.
