# Integrated RPG Completion Checkpoint

**Updated:** 2026-09-11
**Development branch:** `astra/rpg-complete`
**Current remote HEAD:** `c0f626fcb8fa5bafc601d18bfed7dcef62ac66b2`
**Development base:** `4a8c0a3b8232e7f1826478e529f0c252558e6a85`
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

### D core + movement preservation — 2026-09-11

- `STR_STEAMROLLER`, `CON_BIG_GUY`, and `CON_NOT_YET` remain on the shared Push/final-damage seams; `CON_GLOW_UP` adds its CON-modifier flat rider only through an explicit CHA-mod damage-contract helper and remains dynamically ineligible until an actor owns a usable registered CHA-mod damage source.
- `DEX_WALL_JUMP` is a server-authoritative once-per-airborne-cycle 24-unit static-world hull probe, with deterministic nearest-wall selection, a bounded lateral kick, normal voluntary-jump vertical impulse, and Spring Heel composition. `INT_CLOUD_STEP` adds its separate once-per-airborne-cycle 5-Magic jump, after a valid Wall Jump has priority. `INT_FLOAT_ON` is a held-at-apex, once-per-airborne-cycle float with exact 5-Magic-per-second accounting, a 3.0-second cap, and no upward-flight impulse.
- Evidence: `tools/test_checkpoint_d_core_feats.lua`, `tools/test_checkpoint_d_wall_jump.lua`, syntax validation of the movement module, status/element validation, and `tools/test_actor_progression.lua` PASS.

## Next work

Continue Checkpoint D from Size Shifter / remaining movement and other shared feat families; do not redo A-C or the status-proc/core/movement tranches absent contradictory evidence. Then satisfy the full D gate: exact canonical feat-set equality, reachable mechanics/data consumers, hard prerequisite/capability/actor restrictions, automatic AI/human-Soldier selection, and protected accepted regressions.

If autonomous compute is limited, finish/validate/commit/push the currently active coherent D family before starting another. Human runtime testing remains deferred to the integrated Checkpoint-G playtest.
