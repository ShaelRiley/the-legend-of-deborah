# Integrated RPG Completion Checkpoint

**Updated:** 2026-09-10  
**Accepted branch:** `main`  
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

## Next work

Continue Checkpoint D from `docs/DEVELOPMENT_PLAN.md`; do not redo A-C or this status-proc tranche absent contradictory evidence. Complete the remaining canonical feat/capstone inventory by shared handler families, then satisfy the full D gate: exact canonical feat-set equality, reachable mechanics/data consumers, hard prerequisite/capability/actor restrictions, automatic AI/human-Soldier selection, and protected accepted regressions.

If autonomous compute is limited, finish/validate/commit/push the currently active coherent D family before starting another. Human runtime testing remains deferred to the integrated Checkpoint-G playtest.
