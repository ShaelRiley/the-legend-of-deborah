# RPG GDD Rules Baseline

Source of truth: **The Legend of Deborah — Garry's Mod Game Design Document**  
Google Doc ID: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`  
Read revision: `AIroW34oX054OqUeAC2-cC5N_IFZe9RvAJd02sHDzl7wJD30-D1IamAlE4a-Wyg1MGc1c_UP-K3vqk_NBDJkCqdSU0FEZS0qqAq37IzqTQ`

This file preserves the exact six-ability baseline used to ground Gate E and the later full-system audit. It is a transcription aid, not a replacement for the live GDD.

## Universal ability rule

Every progression-bearing actor has STR, DEX, CON, INT, WIS, and CHA. Effective scores are clamped to 3–30 after archetype base score, level growth, equipment, feats, and temporary effects are combined.

`ABILITY_MOD(score) = floor((score - 10) / 2)`

Examples: 6 = −2; 8 = −1; 10–11 = +0; 12–13 = +1; 14–15 = +2; 16–17 = +3; 18–19 = +4; 20–21 = +5; 22–23 = +6; 24–25 = +7; 26–27 = +8; 28–29 = +9; 30 = +10.

## STR

Ordinary physical/weapon damage: `PhysicalDamageMultiplier = clamp(1 + 0.05 × STR_MOD, 0.50, 1.50)`. Apply after the attack's authored dice/base resolution and before elemental weakness/resistance. It applies to ordinary guns, melee, and ordinary physical explosives, but not to Magic damage or environmental wall-crush damage. Shotgun STR applies once to each target's aggregated shell damage, never once per pellet. Magnum STR applies independently to each real projectile after that projectile's authored Boomchain/cylinder result.

## DEX

Aim/handling, movement, exploding-die continuation: `AimSpreadMultiplier = clamp(1 - 0.04 × DEX_MOD, 0.60, 1.40)`. `MovementSpeedMultiplier = clamp(1 + 0.02 × DEX_MOD, 0.85, 1.20)`. DEX may reduce continuation thresholds only after an exploding-die chain has legitimately begun; it never changes the fresh die's initial explosion qualification.

## CON

Hit Points, bounded per-die Damage Resistance, and any enabled Health Regeneration: `DamageResistancePerDie = clamp(CON_MOD, 0, 3)`, so CON 12–13 = DR 1, CON 14–15 = DR 2, and CON 16+ reaches the DR 3 ceiling. Level-based MaxHP uses one stored hit-die roll for every level above 1 plus `HPConBonusPerLevel = min(CON_MOD, 6)`, with a minimum +1 HP contribution per gained level. Higher CON remains valuable through regeneration, feat requirements, and other CON-derived rules without allowing either per-die immunity or runaway retroactive HP multiplication. If an entity has a health-regeneration source, `ConRegenMultiplier = clamp(1 + 0.10 × CON_MOD, 0.50, 2.00)`. CON does not itself grant passive regeneration; a feat, item, archetype, or other system must enable it.

## INT

Magic regeneration speed: `MagicRegenMultiplier = clamp(1 + 0.10 × INT_MOD, 0.50, 2.00)`. Base regeneration remains 100 Magic per 60 seconds; future regeneration rate is `(100/60) × MagicRegenMultiplier` Magic/second whenever regeneration is permitted.

## WIS

Offensive Magic power, utility-Magic efficiency, Magic resistance, minimap breadcrumb length: `MagicPowerMultiplier = clamp(1 + 0.06 × WIS_MOD, 0.60, 1.60)` for offensive Magic explicitly tagged as WIS-scaled. `UtilityMagicCostMultiplier = clamp(1 - 0.04 × WIS_MOD, 0.60, 1.40)` for the minimap and other explicitly noncombat utility Magic. `BreadcrumbCells = clamp(6 + 2 × WIS_MOD, 2, 24)`. Magic resistance uses the GDD's opposed d20 rule.

## CHA

Morale pressure, morale resistance, hit-stun infliction/resistance, and spotting efficacy: an attacker's CHA raises Morale DC and makes wounded AI enemies more likely to retreat; a defending monster's own CHA adds to its Morale Save, so high-CHA enemies are more courageous and harder to rout.

`ChaHitStunInflictMultiplier = clamp(1 + 0.03 × CHA_MOD, 0.75, 1.30)`

`ChaHitStunResistanceMultiplier = clamp(1 - 0.03 × CHA_MOD, 0.70, 1.25)`

Hit-stun order: authored base duration → equipment/direct Stun Duration → attacker CHA infliction multiplier → attacker CHA feat multiplier → weapon-specific multipliers → elemental-weakness multiplier → defender CHA resistance multiplier → archetype/boss resistance, retrigger guards, anti-stunlock safeguards, and hard caps.

Defender CHA never creates/cancels stun eligibility. AI enemies use the defensive rule when eligible. Human-controlled Soldiers use it only for effects already allowed to stun adversarial humans. CHA also scales Watcher/human-Soldier spot/mark range and persistence. Human-controlled actors are never movement-forced by AI Morale.

Morale is event-driven. An AI hostile below 50% current MaxHP that takes effective credited damage may check at most once per second and never while already fleeing:

`MoraleDC = 10 + attacker CHA_MOD + floor((attackerLevel - 1) / 4)`

`MoraleSave = d20 + defender CHA_MOD + floor((defenderLevel - 1) / 4) + ArchetypeMoraleBonus`

`MoraleSave >= MoraleDC` holds. Failure enters real Morale Flee for `clamp(4 + (MoraleDC - MoraleSave), 4, 10)` seconds through Motion V2 legal away/cover goals. It gives up offensive advance goals; ranged actors may finish already-committed defensive releases but cannot begin a new advance attack. Warden immunity is an explicit exception.

## Open CHA authority discrepancy

The implementation handoff requires high-CHA Heroes to receive lower hostile target priority. The exact live GDD revision above contains no target-priority formula or rule for Hero CHA after searches for `target priority`, `lower priority`, `lower-priority`, and equivalent terminology. The later CHA batch must therefore pause at this seam unless the live GDD acquires an exact authored targeting rule; implementation must not invent the magnitude, clamp, or evaluator order.

## Canonical damage order

Kept values/explosion qualification → continuation generation/Blast-Proof → work caps → per-die CON resistance → aggregation → source-wide stat/item modifiers → elemental weakness/resistance/immunity → other target-wide modifiers → freeze ResolvedHPDamage → HP-to-Magic diversion → lethal interceptors → HP/overfill loss → control, attribution, Morale, and death.
