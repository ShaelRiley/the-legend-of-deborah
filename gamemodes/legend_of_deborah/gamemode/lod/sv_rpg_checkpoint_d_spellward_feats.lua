LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Spellward feats require catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Spellward feats require ordinary feats")
local Effects = assert(RPG.FeatEffectSystem, "Spellward feats require effects")
local IDS, NAMES, BONUSES = {"WIS_SPELLWARD", "WIS_SPELLBREAKER", "WIS_SPELLBANE"},
    {"Spellward", "Spellbreaker", "Spellbane"}, {2, 4, 6}

for rank, id in ipairs(IDS) do
    local definition = Feats[id]
    if rank > 1 then
        assert(definition == nil, "duplicate canonical feat " .. id)
        definition = {}
        Feats[id] = definition
    end
    assert(definition ~= nil, "missing canonical Spellward base feat")
    definition.featId, definition.displayName, definition.featFamilyId, definition.rankIndex = id, NAMES[rank], "wis_spellward", rank
    definition.replacesLowerRank, definition.repeatableFallback = rank > 1, false
    definition.governingAbilities, definition.abilityRequirements = {"wis"}, {wis = 11 + rank * 2}
    definition.prerequisiteFeatIds = rank > 1 and {IDS[rank - 1]} or {}
    definition.requiredCapabilityTags, definition.incompatibleFeatIds = {}, {}
    definition.allowedActorTypes, definition.requiredSubsystemTags = {"hero", "human_soldier", "ai"}, {"status_saves"}
    definition.synergyTags, definition.oneRank = {"wisdom", "magic_save", "defense"}, true
    definition.effectHandlerId = "magic_save_bonus"
    definition.effectParams = {magicSaveBonus = BONUSES[rank], description = "Replaces the lower-rank MagicSave bonus with +" .. BONUSES[rank] .. " against explicitly resistible magical effects."}
    definition.directorBaseWeight, definition.eligibilityText = 1.0,
        "WIS " .. (11 + rank * 2) .. (rank > 1 and " / requires " .. NAMES[rank - 1] or "")
    definition.actorText = "Heroes, human Soldiers, and AI"
end
Catalog.OrdinaryFeats = Feats

local function rank(state)
    local current = 0
    for _, owned in ipairs(state and state.featIds or {}) do
        for index, id in ipairs(IDS) do if owned == id then current = math.max(current, index) end end
    end
    return current
end

if not Effects.LODCheckpointDSpellwardDerivedWrapped then
    Effects.LODCheckpointDSpellwardDerivedWrapped = true
    local baseApplyDerived = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        baseApplyDerived(self, state, derived)
        derived.magicSaveBonus = math.floor(tonumber(derived.magicSaveBonus) or 0) + (BONUSES[rank(state)] or 0)
    end
end

function RPG:ValidateCheckpointDSpellwardFeats()
    local errors = {}; local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    for index, id in ipairs(IDS) do
        local definition, derived = Feats[id], {}
        Effects:ApplyDerived({featIds = {id}}, derived)
        expect(definition and definition.abilityRequirements.wis == 11 + index * 2, id .. " WIS requirement")
        expect(derived.magicSaveBonus == BONUSES[index], id .. " replacement bonus")
        if index > 1 then expect(definition.prerequisiteFeatIds[1] == IDS[index - 1], id .. " prerequisite") end
    end
    local derived = {}; Effects:ApplyDerived({featIds = {IDS[1], IDS[3]}}, derived)
    expect(derived.magicSaveBonus == 6, "highest Spellward rank replaces lower bonus")
    return #errors == 0, errors
end

concommand.Add("lod_rpg_validate_spellward", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDSpellwardFeats()
    print("[LOD:SPELLWARD] " .. (ok and "PASS" or "FAIL") .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
