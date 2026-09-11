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

function RPG:ValidateCheckpointDSummonManagement()
    local errors = {}; local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    for rank, id in ipairs(IDs) do
        local definition = Feats[id]
        expect(definition and definition.abilityRequirements.int == 11 + rank * 2
            and definition.effectParams.maxActiveSummons == rank + 1, id .. " definition")
        expect(definition and definition.requiredCapabilityTags[1] == "magic_form_summon", id .. " summon capability")
        if rank > 1 then expect(definition.prerequisiteFeatIds[1] == IDs[rank - 1], id .. " prerequisite") end
        local progression = LOD.MagicProgression
        if progression and progression.MaxActiveSummons then
            expect(progression:MaxActiveSummons({featIds = {id}}) == rank + 1, id .. " caster cap")
        end
    end
    return #errors == 0, errors
end
concommand.Add("lod_rpg_validate_summon_management", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDSummonManagement()
    print("[LOD:SUMMON-MANAGEMENT] " .. (ok and "PASS" or "FAIL") .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
