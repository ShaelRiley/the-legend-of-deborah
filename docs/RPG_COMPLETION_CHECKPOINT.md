# Integrated RPG Completion Checkpoint

**Updated:** 2026-09-11
**Development branch:** `astra/rpg-complete`
**Current remote HEAD:** `65fb9106aeb857091b17f5ad80545231fbea75e7`
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
- `INT_SIZE_SHIFTER` now owns a server-side continuous crouch transformation to absolute 0.33 scale over three seconds, returning smoothly to the ordinary current size after release. It composes with Little Guy/Big Guy through `PlayerTargetScale` and preserves ordinary legal collision and traversal geometry.
- `DEX_SHRINK` now supplies the canonical 0.70 ordinary target scale, is mutually exclusive with Big Guy, and composes as Size Shifter's release destination. `INT_HASTE_1` through `INT_HASTE_3` supply the rebindable default-H sustained toggle, 2.00 final voluntary movement multiplier, and replacement drain multipliers 1, 2/3, 1/3 of the current WIS-scaled map rate. Haste drains independently alongside a map, suppresses regeneration while active, and stops immediately at zero Magic.
- `INT_MIDDLE_MANAGER`, `INT_TASKMASTER`, and `INT_OVERLORD` now use the existing caster-specific allied Seeker cap authority at 2/3/4, gated by actual Summon-Form ownership. `INT_GRAND_UNIFIED_THEORY` and `INT_EXTRACURRICULAR_ACTIVITY` each grant one persistent deterministic distinct Form/Content through MagicProgression and remain ineligible once their respective six-item catalog is exhausted.
- `CHA_NERVE_1` and `CHA_NERVE_2` now provide their canonical replacement MoraleSave bonuses of +2/+4 through the shared Morale resolver for Heroes, human Soldiers, and AI.
- `CHA_MENACE_1` through `CHA_MENACE_3` now reconcile the stale rank-one definition and provide canonical CHA 13/15/17 prerequisites, replacement DC bonuses +2/+4/+4, human trauma fractions .30/.25/.20, and Terrifying's once-per-defender/attacker encounter lower-of-two first Morale Save through the shared resolver.
- `CHA_PANIC` now uses a shared nonrecursive Morale-failure cascade: eligible sub-half-health AI hostiles within two graph cells make one immediate check, with a 3.0-second per-target cascade-immunity timer.
- `WIS_ASTRAL_REACH` now supplies its canonical Hero-only WIS 15 +2-cell rider through the existing WIS-scaled Magic Form spatial authority. It remains unavailable until the Hero owns at least one Magic Form; no duplicate range/damage/cost implementation was added.
- Evidence: `tools/test_checkpoint_d_core_feats.lua`, `tools/test_checkpoint_d_wall_jump.lua`, syntax validation of the movement module, status/element validation, and `tools/test_actor_progression.lua` PASS.

## Next work

Continue Checkpoint D with the remaining exact live-GDD spot/aura families or another shared family; do not redo A-C or completed D tranches absent contradictory evidence. Then satisfy the full D gate: exact canonical feat-set equality, reachable mechanics/data consumers, hard prerequisite/capability/actor restrictions, automatic AI/human-Soldier selection, and protected accepted regressions.

If autonomous compute is limited, finish/validate/commit/push the currently active coherent D family before starting another. Human runtime testing remains deferred to the integrated Checkpoint-G playtest.
