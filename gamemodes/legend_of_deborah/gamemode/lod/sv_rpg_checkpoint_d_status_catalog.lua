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
