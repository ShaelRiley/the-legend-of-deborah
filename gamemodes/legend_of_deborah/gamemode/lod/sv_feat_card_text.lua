-- Presentation only. Loaded after every feat registration so the character sheet,
-- offers and exported manual consume the same edited text and live parameters.
local Catalog = LOD.RPG.IdentityCatalog
local function percent(v) return math.floor(v * 100 + .5) end
local cards = {
    CHA_ACADEMIC_ACHIEVEMENT = 'Add your positive CHA modifier to your INT modifier when calculating passive Magic regeneration. Regeneration must be permitted.',
    CHA_AGGRESSIVE_PERSONALITY = 'Your next physical attack adds your positive CHA modifier as damage to each target. Cooldown: 1d3 seconds; these timing dice do not explode.',
    CHA_PANIC = 'When an enemy fails Morale against you, AI enemies below half HP within 2 connected cells make a Morale check. This cannot cascade again; each target is immune to cascades for 3 seconds.',
    CHA_SELF_ACTUALIZATION = 'Add your positive CHA modifier to each target’s magical damage, once after damage multipliers.',
    CHA_WINNING_PERSONALITY = 'Gain +1 intrinsic CHA, up to the ability ceiling. Use the higher of INT or CHA to meet INT feat ability requirements. Other prerequisites still apply.',
    CON_BIG_GUY = 'Your body and hurt volume become 30% larger. Gain 15% melee reach and 20% physical push dealt. Your movement hull stays the same. Incompatible with Little Guy.',
    CON_BLAST_PROOF = 'Stop the first continuation of an incoming exploding damage chain. Keep damage already rolled; other chains continue normally. Cooldown: 2 seconds.',
    CON_GLOW_UP = 'Whenever your own ability adds your positive CHA modifier as damage, also add your positive CON modifier once to that damage event.',
    CON_NOT_YET = 'Once per dungeon, lethal damage received above 1 HP leaves you at 1 HP and grants 0.5 seconds of damage immunity. Death, respawn and reconnect do not restore this use.',
    CON_RUSSIAN_ASSET = 'Double Tetris HP rewards to 20/60/100/160 for 1/2/3/4 lines. Death Tetris lasts up to 120 seconds. The 20-second respawn lock and victory window stay unchanged.',
    CON_STEADFAST = 'Reduce ordinary hit-stun duration and incoming push distance by 25%. Scripted boss effects may ignore this resistance.',
    CROSS_BIG_SCARY = 'Gain +2 Morale DC when dealing melee damage, physical push or wall-crush damage. This stacks with Menacing.',
    CROSS_BOOM_BATTERY = 'Every second continuation die in a non-Magic attack restores 1 Magic. Maximum: 5 Magic per attack; never above 100 Magic.',
    CROSS_CRUSH_PANIC = 'Your wall crush forces an eligible target to check Morale, even during its normal recheck cooldown. Once per target every 3 seconds.',
    CROSS_FORCE_OF_WILL = 'Magic that already pushes can trigger Pusher, Shover or Space Hog after Force Multiplier. A successful proc adds 168 units and uses your Pusher wall-slam die. Shared per-target cooldown: 0.5 seconds.',
    CROSS_METEOR_STRIKE = 'After using Cloud Step, your first Crowbar hit before landing adds one exploding d6 and doubles its Crowbar push. A miss does not consume this strike. Landing resets it.',
    CROSS_TINY_TERROR = 'While Little Guy is active, gain +2 Morale DC against enemies within 2 connected cells. This stacks with Menacing.',
    DEX_MAGNUM_DEADEYE = 'Stand perfectly still for 0.5 seconds to empower your next primary attack: double damage with a standard weapon, or triple damage with the .357 Magnum. One attack consumes the aim.',
    DEX_SHRINK = 'Your visible body becomes 30% smaller. Your movement hull, weapon traces and interaction reach stay the same. Incompatible with Big Guy.',
    DEX_SPRING_HEEL = 'Double the height of voluntary jumps, including Wall Jump and Cloud Step. Ceilings, wall-top barriers and locked routes still block travel.',
    DEX_WALL_JUMP = 'Press Jump within 24 units of a vertical wall to jump and kick away. Four uses before landing; no Magic cost. Spring Heel increases the jump height.',
    INT_ARC_RECOVERY = 'Kill an AI enemy with Magic damage to restore 5 Magic, up to 100. Cooldown: 2 seconds.',
    INT_EXTRACURRICULAR_ACTIVITY = 'Learn one new Magic content immediately. Your later scheduled grants remain available.',
    INT_FEEDBACK_LOOP = 'Each continuation die rolled by your offensive Magic restores 1 Magic. Maximum: 6 per cast, up to 100 Magic. Initial dice do not count.',
    INT_GRAND_UNIFIED_THEORY = 'Learn one new Magic form immediately. Your later scheduled grants remain available.',
    INT_MANA_SPRING = 'After reaching 0 Magic, your next permitted regeneration is 50% faster for 4 seconds. Sustained effects that block regeneration pause this timer.',
    INT_SIZE_SHIFTER = 'Hold Crouch for 3 seconds to shrink your visible body to 33% size. Release to grow back at the same rate. Your ordinary crouched movement hull stays unchanged.',
    INT_WAS_DEBORAH = 'Move backward 25% faster, including backward diagonals. This affects voluntary ground movement and obeys the ordinary speed cap.',
    STR_CROWBAR_CRUSH = 'Add one die to your Crowbar wall-slam damage. Use the current wall-slam die and its explosion rules.',
    STR_MELEE_REACH = 'Gain 25% melee reach. Blocking walls, gates and floors still stop the attack.',
    STR_STEAMROLLER = 'Targets that save against your push still move half the size-adjusted distance. Failed saves take full distance. Push immunity, resistance and collision still apply.',
    WIS_ASTRAL_REACH = 'Add 2 cells to Magic form dimensions that scale with WIS.',
    WIS_ATTUNEMENT = 'When your elemental Magic exploits a weakness, roll the weakness bonus twice and keep the higher result.',
    WIS_FORCEFUL_MAGIC = 'Increase your Magic push distance by 25%. Physical push feats require Force of Will to apply.',
    WIS_FRUGAL_MAP = 'Reduce minimap Magic drain by 15%, to a minimum of 3 Magic per second. Magic does not regenerate while the map is open.',
    WIS_GPS = 'Press G to toggle spoken directions to the current objective; starts enabled and costs no Magic. Stand still for 1 second with no living enemy within 2 same-floor cells to hear a direction. Repeats after 4 seconds of silence. Movement, danger and inactive play stop speech.',
    WIS_HERO_OF_LEGEND = 'At HP ≥ the lower of 100 or your MaxHP, a Crowbar swing launches a glowing Crowbar that deals your current Crowbar die as non-elemental Magic. Range: at least 1 cell, or your WIS bonus if higher. Only one such projectile may exist at a time.',
    WIS_KILLER_INSTINCT = 'After viewing at least two visible enemies for 0.5 seconds, a red outline marks the best target for your equipped weapon: strongest one-shot kill margin, otherwise fewest estimated shots to kill. Rechecks once per second. Losing the multi-enemy view clears it; it grants no aim assistance.',
    WIS_MIND_OVER_MATTER = 'When ready, reduce incoming physical damage by your positive WIS modifier, once per damage event before Magic diversion. Cooldown: 3d4 seconds; these timing dice do not explode. Damage cannot fall below 0.',
    WIS_TRUE_FAITH = 'Reduce incoming magical damage by your positive WIS modifier, once per damage event after other damage modifiers and before Magic diversion. Damage cannot fall below 0.',
    WIS_OMNISCIENCE = 'Look at a visible monster to see its type, level, class and current/max HP. Human Soldiers retain their player identity above these stats.',
    WIS_SIXTH_SENSE = 'See normally visible invisible entities as translucent silhouettes. Outline living enemies within 2 cells on your floor, even through walls. Hear private positional movement sounds from same-floor Watchers. These senses grant no attacks or interactions through walls.',
    WIS_SPATIAL_AWARENESS = 'Warn when an enemy becomes visible behind or beside you on your floor. Rear range: your WIS modifier, minimum 1 cell, in a 3-cell-wide strip; side range: half that, rounded up. A violet direction cue and named alert identify one target; no repeat while it stays detected.',
    FTR_CAP_BUILT_DIFFERENT = 'Gain 25% ordinary MaxHP before Tetris overfill. Choosing this feat does not heal you.',
    FTR_CAP_ONE_PERSON_ARMY = 'Deal 20% more damage with STR-scaled physical attacks, before elemental modifiers.',
    FTR_CAP_UNSTOPPABLE_FORCE = 'Deal 33% more physical push and receive 25% less. Add one die to valid wall-slam damage.',
    ROG_CAP_ACE_IN_THE_HOLE = 'After 3 seconds without attacking, your next committed eligible attack gains one primary damage die. That attack consumes the bonus.',
    ROG_CAP_LOADED_DICE = 'Lower Rogue damage-die explosion thresholds by 1. Minimum thresholds, sealed dice and explosion limits still apply.',
    ROG_CAP_NOW_YOU_SEE_ME = 'Gain 20 percentage points of Dodge while moving voluntarily at least one-quarter walk speed: 31% normally, 42% at 90% sprint speed. Slower movement grants no Dodge. Roll once per attack and target, before diversion and control.',
    WIZ_CAP_ARCHMAGE = 'Increase WIS-scaled offensive Magic power by 20%. Gain +2 DC for resistible Wizard Magic.',
    WIZ_CAP_LIVING_AEGIS = 'Arcane Shield spends 1 Magic per 1.5 HP prevented. It still diverts at most 50% of damage. Spell costs and Feedback chance stay unchanged.',
    WIZ_CAP_MANA_ENGINE = 'Regenerate Magic 50% faster after INT scaling, up to 100 Magic. Regeneration must be permitted.'
}
local families = {
    cha_personality_aura = function(p) return string.format('Every 3d4 seconds, deal your positive CHA modifier as untyped damage to enemies within %d same-floor cells. Timing dice do not explode.',p.cellRadius) end,
    cha_aura_burst = function(p) return string.format('When you successfully spend Magic on a discrete action, deal your positive CHA modifier as extra Magic damage to enemies within %d same-floor cells. Sustained drain does not trigger this.',p.cellRadius) end,
    cha_intimidation_proc = function(p) return string.format('Your damaging hit has a %d%% chance to force a surviving target to check Morale. Requires its Morale cooldown to be ready; skips hits that already force a check.',percent(p.procChance)) end,
    cha_hitstun_presence = function(p) return string.format('Increase hit stun you inflict by %d%% after CHA scaling. Resistance, retrigger protection and duration caps still apply.',percent(p.featHitStunMultiplier-1)) end,
    cha_menace = function(p) return string.format('Gain +%d Morale DC. A hit exceeding %d%% of a human target’s MaxHP can trigger Morale; low HP alone cannot.',p.moraleDCBonus,percent(p.humanMoraleTraumaFraction))..(p.terrifyingFirstSaveDisadvantage and ' Each target’s first Morale save against you per encounter rolls twice and keeps the lower die.' or '') end,
    cha_nerve = function(p) return string.format('Gain +%d to Morale saves.',p.moraleSaveBonus) end,
    con_health_regeneration = function(p) return string.format('After %g damage-free seconds, regenerate %g%% MaxHP per second, scaled by CON. Add %d%% MaxHP to your regeneration ceiling; this stacks with Fighter’s innate 33%% and cannot restore Tetris overfill.',p.damageFreeDelaySeconds,percent(p.baseMaxHPPerSecond),percent(p.ceilingFraction)) end,
    dex_burst_size = function(p) return string.format('Add %d rounds to existing multi-shot bursts at their normal spacing and damage, with no extra ammunition cost. Single shots and Shotgun pellets are not bursts.',p.burstBonusRounds) end,
    dex_exploding_damage_dice = function(p) return string.format('Your ordinary d%d damage dice explode on their maximum face. Continuations explode at %d minus BoomShift, minimum 2. Maximum: 32 dice per chain. Earlier die unlocks remain active.',p.dieSides,p.dieSides) end,
    dex_reload_cadence = function(p) return string.format('Reduce ordinary weapon reload time by %d%%. This does not shorten SMG cooling or attack windups.',percent(1-p.reloadTimeMultiplier)) end,
    dex_strafe = function(p) return string.format('Strafe %d%% faster on the ground. Only the sideways component changes on diagonals. The ordinary speed cap still applies.',percent(p.multiplier-1)) end,
    dex_rate_of_fire = function(p) return string.format('Increase ordinary firearm primary-fire rate by %d%%. Reloads, cooling, targeting windups and spacing within bursts stay unchanged.',percent(p.rateOfFireMultiplier-1)) end,
    dex_smg_heat = function(p) return string.format('Each SMG round has a %d%% chance to add no heat. Overheat threshold: %d. Overheating still locks firing for 2 seconds.',percent(p.smgHeatSuppressionChance),p.smgOverheatThreshold) end,
    int_ammo_regeneration_floor = function(p) return string.format('Owned regenerative firearm ammunition refills to %d%% of family capacity, rounded up. Regeneration timing and capacity stay unchanged; consumables and AR2 secondary ammo are excluded.',percent(p.floorFraction)) end,
    int_arcane_disruption_proc = function(p) return string.format('A nonmagical physical hit has a %d%% chance to force a surviving target with an active Arcane Shield to make an INT Arcane Integrity save. Failure shatters the shield. Feedback from that hit resolves first.',percent(p.procChance)) end,
    int_map_movement = function(p) return string.format('Move %d%% faster while your minimap is open. Closing it or exhausting Magic ends the bonus. The ordinary speed cap still applies.',percent(p.multiplier-1)) end,
    int_haste = function(p) return string.format('Press H to toggle double ground movement speed, subject to the ordinary cap. Drain %s of your minimap Magic rate per second; map drain adds separately. Regeneration stops while active. At 0 Magic or on death, Haste ends.',p.drainMultiplier==1 and '100%' or p.drainMultiplier>.5 and 'two-thirds' or 'one-third') end,
    mana_barrier = function(p) return string.format('Spend Magic to divert %d%% of damage remaining after mitigation, at 1 Magic per HP prevented. Limited by current Magic. Unavailable to Wizards.',percent(p.manaBarrierFeatDiversionFraction)) end,
    int_summon_management = function(p) return string.format('You may have %d Seeker summons at once. Casting at the limit fails without spending Magic. Other Summon rules stay unchanged.',p.maxActiveSummons) end,
    int_quantum_cost = function(p) return string.format('Offensive active Magic costs %d%% less; round costs up, minimum 1. Utility Magic and sustained drain are unchanged.',percent(1-p.multiplier)) end,
    str_crowbar_damage = function(p) return string.format('Your Crowbar deals %s d%d damage. Each nonlethal hit attempts a 168-unit physical push.',p.crowbarDamageDieSides==12 and 'SUPER exploding' or 'exploding',p.crowbarDamageDieSides) end,
    str_pusher = function(p) return string.format('Nonlethal ordinary weapon hits have a %d%% chance to add a 168-unit push, subject to a STR save. Successful proc cooldown: %g seconds per target. Physical wall slams use %s d%d.',percent(p.weaponKnockbackProcChance),p.pusherProcTargetCooldownSeconds,p.wallSlamExplodes and 'SUPER exploding' or 'sealed',p.wallSlamDieSides) end,
    wis_breadcrumb_range = function(p) return string.format('Extend your breadcrumb route by %d cells. Map degradation and floor restrictions still apply.',p.breadcrumbBonusCells) end,
    wis_spellward = function(p) return string.format('Gain +%d to Magic saves against resistible magical effects.',p.magicSaveBonus) end
}
local conditions={bleeding='Bleeding',poisoned='Poisoned',clumsy='Clumsy',immolated='Immolated',held='Held',muted='Muted',reckless='Reckless'}
local function apply(definition)
    local p=definition.effectParams
    local description=cards[definition.featId]
    local family=families[definition.featFamilyId]
    if family then description=family(p) end
    if not description and p.statusId and conditions[p.statusId] then
        description=string.format('Your hit has a %d%% chance to attempt %s. The target saves with %s against your %s modifier; success prevents the condition. Hits already attempting that condition do not roll again.',percent(p.procChance),conditions[p.statusId],string.upper(p.dcAbility),string.upper(p.dcAbility))
    end
    if definition.featId=='INT_CLOUD_STEP' then
        description=string.format('Once before landing, press Jump in the air to spend %g Magic on an extra jump. A valid Wall Jump takes priority and preserves this use.',p.magicCost)
    elseif definition.featId=='INT_FLOAT_ON' then
        description=string.format('Once before landing, hold Jump at your apex to float for up to %g seconds, spending %g Magic per second. Release Jump, land or run out of Magic to end it.',p.maximumSeconds,p.magicPerSecond)
    elseif definition.repeatableFallback then
        description=string.format('Permanently gain +%d intrinsic %s. Repeatable until that intrinsic ability reaches 30.',p.amount,string.upper(p.ability))
    end
    assert(description,'Missing edited feat card: '..definition.featId)
    if definition.replacesLowerRank then description=description..' Replaces lower ranks.' end
    p.description=description
end
for _,definition in pairs(Catalog.OrdinaryFeats) do apply(definition) end
for _,class in pairs(Catalog.ClassCapstones) do for _,definition in pairs(class) do apply(definition) end end
for _,definition in pairs(Catalog.FallbackFeats) do apply(definition) end
