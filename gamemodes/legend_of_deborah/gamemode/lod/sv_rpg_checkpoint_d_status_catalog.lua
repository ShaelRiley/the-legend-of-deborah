LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Checkpoint D status catalog requires IdentityCatalog")
local Feats = Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats
assert(Feats, "Checkpoint D status catalog requires ordinary feat registry")
Catalog.OrdinaryFeats = Feats

-- Canonical live-GDD Checkpoint D tranche: all ordinary three-rank offensive
-- status-proc families.  Definitions are registered before CharacterProgression
-- loads so Hero drafts and automatic monster/Soldier progression share one pool.
local CHANCES = {0.11, 0.22, 0.33}
local REQUIREMENTS = {13, 15, 17}
local ACTORS = {"hero", "human_soldier", "ai"}

local FAMILIES = {
    {
        familyId = "con_poison_proc",
        governingAbility = "con",
        dcAbility = "con",
        statusId = "poisoned",
        handlerId = "status_proc_family",
        capabilityTag = "attributable_damaging_attack",
        ids = {"CON_POISON_PROC_1", "CON_POISON_PROC_2", "CON_POISON_PROC_3"},
        descriptions = {"Sets PoisonProcChance = 0.11. On an eligible target-hit event under the common status-proc rules, a successful proc creates one poison-status application attempt using the attacker's CON for PoisonDC and the defender's CON for PoisonSave. A failed save applies the canonical Poisoned state; a successful save prevents it. Existing Poisoned reapplication/recovery rules remain authoritative.", "Replaces lower ranks. Sets PoisonProcChance = 0.22. On an eligible target-hit event under the common status-proc rules, a successful proc creates one poison-status application attempt using the attacker's CON for PoisonDC and the defender's CON for PoisonSave. A failed save applies the canonical Poisoned state; a successful save prevents it. Existing Poisoned reapplication/recovery rules remain authoritative.", "Replaces lower ranks. Sets PoisonProcChance = 0.33. On an eligible target-hit event under the common status-proc rules, a successful proc creates one poison-status application attempt using the attacker's CON for PoisonDC and the defender's CON for PoisonSave. A failed save applies the canonical Poisoned state; a successful save prevents it. Existing Poisoned reapplication/recovery rules remain authoritative."},
        names = {"Venomous", "Toxic", "Virulent"}
    },
    {
        familyId = "dex_clumsy_proc",
        governingAbility = "dex",
        dcAbility = "dex",
        statusId = "clumsy",
        handlerId = "status_proc_family",
        capabilityTag = "attributable_damaging_attack",
        ids = {"DEX_CLUMSY_PROC_1", "DEX_CLUMSY_PROC_2", "DEX_CLUMSY_PROC_3"},
        descriptions = {"Sets ClumsyProcChance = 0.11. On an eligible target-hit event under the common status-proc rules, a successful proc creates one clumsy-tagged application attempt using the attacker's DEX for ClumsyDC and the defender's DEX for ClumsySave. A failed save applies canonical Clumsy; a successful save prevents it.", "Replaces lower ranks. Sets ClumsyProcChance = 0.22. On an eligible target-hit event under the common status-proc rules, a successful proc creates one clumsy-tagged application attempt using the attacker's DEX for ClumsyDC and the defender's DEX for ClumsySave. A failed save applies canonical Clumsy; a successful save prevents it.", "Replaces lower ranks. Sets ClumsyProcChance = 0.33. On an eligible target-hit event under the common status-proc rules, a successful proc creates one clumsy-tagged application attempt using the attacker's DEX for ClumsyDC and the defender's DEX for ClumsySave. A failed save applies canonical Clumsy; a successful save prevents it."},
        names = {"Distracting", "Disorienting", "Discombobulating"}
    },
    {
        familyId = "dex_immolate_proc",
        governingAbility = "dex",
        dcAbility = "dex",
        statusId = "immolated",
        handlerId = "status_proc_family",
        capabilityTag = "attributable_damaging_attack",
        ids = {"DEX_IMMOLATE_PROC_1", "DEX_IMMOLATE_PROC_2", "DEX_IMMOLATE_PROC_3"},
        descriptions = {"Sets ImmolateProcChance = 0.11. On an eligible target-hit under the shared Status-proc feat-family rules, a successful proc creates exactly one Immolated application attempt using the attacker's DEX for ImmolateDC and the defender's DEX for ImmolateSave. A successful save prevents ignition. If that attack already guarantees an Immolated save through an authored fire/immolate rule, skip this redundant proc roll.", "Replaces lower ranks. Sets ImmolateProcChance = 0.22. On an eligible target-hit under the shared Status-proc feat-family rules, a successful proc creates exactly one Immolated application attempt using the attacker's DEX for ImmolateDC and the defender's DEX for ImmolateSave. A successful save prevents ignition. If that attack already guarantees an Immolated save through an authored fire/immolate rule, skip this redundant proc roll.", "Replaces lower ranks. Sets ImmolateProcChance = 0.33. On an eligible target-hit under the shared Status-proc feat-family rules, a successful proc creates exactly one Immolated application attempt using the attacker's DEX for ImmolateDC and the defender's DEX for ImmolateSave. A successful save prevents ignition. If that attack already guarantees an Immolated save through an authored fire/immolate rule, skip this redundant proc roll."},
        names = {"Singeing", "Scorching", "Incendiary"}
    },
    {
        familyId = "int_arcane_disruption_proc",
        governingAbility = "int",
        dcAbility = "int",
        statusId = "arcane_shattered",
        handlerId = "arcane_disruption_proc",
        capabilityTag = "attributable_nonmagical_damaging_attack",
        requiresArcaneShieldOnline = true,
        requiresPhysicalNonmagical = true,
        ids = {"INT_ARCANE_PROC_1", "INT_ARCANE_PROC_2", "INT_ARCANE_PROC_3"},
        descriptions = {"Sets ArcaneDisruptionProcChance = 0.11. When an eligible physical=true, magical=false target-hit event damages a surviving target whose Arcane Shield is online, a successful proc forces exactly one post-damage Arcane Integrity save using the ordinary attacker-INT ArcaneBreakDC and defender-INT ArcaneIntegritySave formulas. This does not retag the underlying damage as magical. The physical hit remains ordinarily Feedback-eligible, and any Feedback resolution from that hit completes before this proc-created Arcane Integrity save. Magical hits do not roll this family because they already force Arcane Integrity saves automatically.", "Replaces lower ranks. Sets ArcaneDisruptionProcChance = 0.22. When an eligible physical=true, magical=false target-hit event damages a surviving target whose Arcane Shield is online, a successful proc forces exactly one post-damage Arcane Integrity save using the ordinary attacker-INT ArcaneBreakDC and defender-INT ArcaneIntegritySave formulas. This does not retag the underlying damage as magical. The physical hit remains ordinarily Feedback-eligible, and any Feedback resolution from that hit completes before this proc-created Arcane Integrity save. Magical hits do not roll this family because they already force Arcane Integrity saves automatically.", "Replaces lower ranks. Sets ArcaneDisruptionProcChance = 0.33. When an eligible physical=true, magical=false target-hit event damages a surviving target whose Arcane Shield is online, a successful proc forces exactly one post-damage Arcane Integrity save using the ordinary attacker-INT ArcaneBreakDC and defender-INT ArcaneIntegritySave formulas. This does not retag the underlying damage as magical. The physical hit remains ordinarily Feedback-eligible, and any Feedback resolution from that hit completes before this proc-created Arcane Integrity save. Magical hits do not roll this family because they already force Arcane Integrity saves automatically."},
        names = {"Disruptor", "Spellbreaker", "Nullifier"}
    },
    {
        familyId = "str_bleed_proc",
        governingAbility = "str",
        dcAbility = "con",
        statusId = "bleeding",
        handlerId = "status_proc_family",
        capabilityTag = "attributable_damaging_attack",
        ids = {"STR_BLEED_PROC_1", "STR_BLEED_PROC_2", "STR_BLEED_PROC_3"},
        descriptions = {"Sets BleedProcChance = 0.11 under the shared status-proc feat-family rules. On an eligible target-hit event, a successful proc creates exactly one Bleeding application attempt. Bloodletter is STR-governed for feat qualification, but Bleeding remains a canonical CON-resisted condition: the attacker's CON sets BleedDC and the defender's CON sets BleedSave. A successful save prevents Bleeding. If the authored attack already guarantees a Bleeding application attempt, skip the redundant Bloodletter-family proc roll.", "Replaces lower ranks. Sets BleedProcChance = 0.22 under the shared status-proc feat-family rules. On an eligible target-hit event, a successful proc creates exactly one Bleeding application attempt. Bloodletter is STR-governed for feat qualification, but Bleeding remains a canonical CON-resisted condition: the attacker's CON sets BleedDC and the defender's CON sets BleedSave. A successful save prevents Bleeding. If the authored attack already guarantees a Bleeding application attempt, skip the redundant Bloodletter-family proc roll.", "Replaces lower ranks. Sets BleedProcChance = 0.33 under the shared status-proc feat-family rules. On an eligible target-hit event, a successful proc creates exactly one Bleeding application attempt. Bloodletter is STR-governed for feat qualification, but Bleeding remains a canonical CON-resisted condition: the attacker's CON sets BleedDC and the defender's CON sets BleedSave. A successful save prevents Bleeding. If the authored attack already guarantees a Bleeding application attempt, skip the redundant Bloodletter-family proc roll."},
        names = {"Bloodletter", "Deep Wounds", "Exsanguinator"}
    },
    {
        familyId = "wis_mute_proc",
        governingAbility = "wis",
        dcAbility = "wis",
        statusId = "muted",
        handlerId = "status_proc_family",
        capabilityTag = "attributable_damaging_attack",
        ids = {"WIS_MUTE_PROC_1", "WIS_MUTE_PROC_2", "WIS_MUTE_PROC_3"},
        descriptions = {"Sets MuteProcChance = 0.11. On an eligible target-hit event under the common status-proc rules, a successful proc creates one mute-tagged application attempt using the ordinary attacker-WIS MagicDC and defender-WIS MagicSave formulas. Failure applies canonical Muted; success prevents it.", "Replaces lower ranks. Sets MuteProcChance = 0.22. On an eligible target-hit event under the common status-proc rules, a successful proc creates one mute-tagged application attempt using the ordinary attacker-WIS MagicDC and defender-WIS MagicSave formulas. Failure applies canonical Muted; success prevents it.", "Replaces lower ranks. Sets MuteProcChance = 0.33. On an eligible target-hit event under the common status-proc rules, a successful proc creates one mute-tagged application attempt using the ordinary attacker-WIS MagicDC and defender-WIS MagicSave formulas. Failure applies canonical Muted; success prevents it."},
        names = {"Hushing", "Silencing", "Dead Air"}
    },
    {
        familyId = "wis_held_proc",
        governingAbility = "wis",
        dcAbility = "wis",
        statusId = "held",
        handlerId = "status_proc_family",
        capabilityTag = "attributable_damaging_attack",
        ids = {"WIS_HELD_PROC_1", "WIS_HELD_PROC_2", "WIS_HELD_PROC_3"},
        descriptions = {"Sets HeldProcChance = 0.11 under the shared status-proc feat-family rules. On a successful proc, the target makes exactly one ordinary WIS MagicSave against the attacker's WIS-based MagicDC; failure applies canonical Held. This creates a Held attempt only and never bypasses the defender's Wisdom.", "Replaces lower ranks. Sets HeldProcChance = 0.22 under the shared status-proc feat-family rules. On a successful proc, the target makes exactly one ordinary WIS MagicSave against the attacker's WIS-based MagicDC; failure applies canonical Held. This creates a Held attempt only and never bypasses the defender's Wisdom.", "Replaces lower ranks. Sets HeldProcChance = 0.33 under the shared status-proc feat-family rules. On a successful proc, the target makes exactly one ordinary WIS MagicSave against the attacker's WIS-based MagicDC; failure applies canonical Held. This creates a Held attempt only and never bypasses the defender's Wisdom."},
        names = {"Snaring", "Binding", "Entrapping"}
    },
    {
        familyId = "wis_reckless_proc",
        governingAbility = "wis",
        dcAbility = "wis",
        statusId = "reckless",
        handlerId = "status_proc_family",
        capabilityTag = "attributable_damaging_attack",
        ids = {"WIS_RECKLESS_PROC_1", "WIS_RECKLESS_PROC_2", "WIS_RECKLESS_PROC_3"},
        descriptions = {"Sets RecklessProcChance = 0.11 under the shared status-proc feat-family rules. On a successful proc, the target makes exactly one ordinary WIS MagicSave against the attacker's WIS-based MagicDC; failure applies canonical Reckless. This creates a Reckless attempt only and never bypasses the defender's Wisdom.", "Replaces lower ranks. Sets RecklessProcChance = 0.22 under the shared status-proc feat-family rules. On a successful proc, the target makes exactly one ordinary WIS MagicSave against the attacker's WIS-based MagicDC; failure applies canonical Reckless. This creates a Reckless attempt only and never bypasses the defender's Wisdom.", "Replaces lower ranks. Sets RecklessProcChance = 0.33 under the shared status-proc feat-family rules. On a successful proc, the target makes exactly one ordinary WIS MagicSave against the attacker's WIS-based MagicDC; failure applies canonical Reckless. This creates a Reckless attempt only and never bypasses the defender's Wisdom."},
        names = {"Agitating", "Unhinging", "Maddening"}
    },
    {
        familyId = "cha_intimidation_proc",
        governingAbility = "cha",
        dcAbility = "cha",
        handlerId = "morale_proc_family",
        capabilityTag = "attributable_damaging_attack",
        moraleProc = true,
        ids = {"CHA_FEAR_PROC_1", "CHA_FEAR_PROC_2", "CHA_FEAR_PROC_3"},
        descriptions = {"Sets IntimidationProcChance = 0.11. If an eligible target-hit event damages a surviving defender whose MoraleCheckCooldown is inactive and that same event did not already require a Morale check from an ordinary trauma trigger, a successful proc forces exactly one Morale check even when the hit would otherwise be below the defender's trauma threshold. The ordinary attacker-CHA MoraleDC and defender-CHA MoraleSave formulas apply, and the normal controller-specific cooldown begins after that check whether it succeeds or fails.", "Replaces lower ranks. Sets IntimidationProcChance = 0.22. If an eligible target-hit event damages a surviving defender whose MoraleCheckCooldown is inactive and that same event did not already require a Morale check from an ordinary trauma trigger, a successful proc forces exactly one Morale check even when the hit would otherwise be below the defender's trauma threshold. The ordinary attacker-CHA MoraleDC and defender-CHA MoraleSave formulas apply, and the normal controller-specific cooldown begins after that check whether it succeeds or fails.", "Replaces lower ranks. Sets IntimidationProcChance = 0.33. If an eligible target-hit event damages a surviving defender whose MoraleCheckCooldown is inactive and that same event did not already require a Morale check from an ordinary trauma trigger, a successful proc forces exactly one Morale check even when the hit would otherwise be below the defender's trauma threshold. The ordinary attacker-CHA MoraleDC and defender-CHA MoraleSave formulas apply, and the normal controller-specific cooldown begins after that check whether it succeeds or fails."},
        names = {"Daunting", "Cowing", "Overawing"}
    }
}

local canonicalIds = {}
local familyByFeatId = {}

for _, family in ipairs(FAMILIES) do
    for rank = 1, 3 do
        local featId = family.ids[rank]
        local prerequisite = rank > 1 and family.ids[rank - 1] or nil
        canonicalIds[#canonicalIds + 1] = featId
        familyByFeatId[featId] = family
        if Feats[featId] == nil then
            Feats[featId] = {
                featId = featId,
                displayName = family.names[rank],
                featFamilyId = family.familyId,
                rankIndex = rank,
                replacesLowerRank = rank > 1,
                repeatableFallback = false,
                governingAbilities = {family.governingAbility},
                abilityRequirements = {[family.governingAbility] = REQUIREMENTS[rank]},
                prerequisiteFeatIds = prerequisite and {prerequisite} or {},
                requiredCapabilityTags = {family.capabilityTag},
                incompatibleFeatIds = {},
                allowedActorTypes = ACTORS,
                requiredSubsystemTags = {"status_elements"},
                synergyTags = {"status_proc", family.statusId or "morale"},
                oneRank = true,
                effectHandlerId = family.handlerId,
                effectParams = {
                    description = family.descriptions[rank],
                    procChance = CHANCES[rank],
                    statusId = family.statusId,
                    dcAbility = family.dcAbility,
                    moraleProc = family.moraleProc == true,
                    requiresArcaneShieldOnline = family.requiresArcaneShieldOnline == true,
                    requiresPhysicalNonmagical = family.requiresPhysicalNonmagical == true
                },
                directorBaseWeight = 1.0,
                eligibilityText = string.format("%s %d%s",
                    string.upper(family.governingAbility), REQUIREMENTS[rank],
                    prerequisite and (" / requires " .. prerequisite) or ""),
                actorText = "Heroes, human Soldiers, AI with an eligible attributable damaging attack"
            }
        end
    end
end

RPG.CheckpointDStatusProcFamilies = FAMILIES
RPG.CheckpointDStatusProcFeatIds = canonicalIds
RPG.CheckpointDStatusProcFamilyByFeatId = familyByFeatId
