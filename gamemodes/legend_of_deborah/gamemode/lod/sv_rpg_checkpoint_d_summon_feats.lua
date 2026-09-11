LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Summon feats require catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Summon feats require ordinary feats")
local IDs, Names = {"INT_MIDDLE_MANAGER", "INT_TASKMASTER", "INT_OVERLORD"}, {"Middle Manager", "Taskmaster", "Overlord"}
for rank, id in ipairs(IDs) do
    assert(Feats[id] == nil, "duplicate canonical feat " .. id)
    Feats[id] = {featId = id, displayName = Names[rank], featFamilyId = "int_summon_management", rankIndex = rank,
        replacesLowerRank = rank > 1, repeatableFallback = false, governingAbilities = {"int"}, abilityRequirements = {int = 11 + rank * 2},
        prerequisiteFeatIds = rank > 1 and {IDs[rank - 1]} or {}, requiredCapabilityTags = {"magic_form_summon"}, incompatibleFeatIds = {},
        allowedActorTypes = {"hero"}, requiredSubsystemTags = {"magic_summon"}, synergyTags = {"magic", "summon"}, oneRank = true,
        effectHandlerId = "summon_active_cap", effectParams = {maxActiveSummons = rank + 1,
            description = "Replaces this caster's active allied Seeker Summon cap without changing cost, duration, placement, payload, damage, AI, or lifecycle."},
        directorBaseWeight = 1.0, eligibilityText = "INT " .. (11 + rank * 2) .. " / Summon Form"}
end
Catalog.OrdinaryFeats = Feats
