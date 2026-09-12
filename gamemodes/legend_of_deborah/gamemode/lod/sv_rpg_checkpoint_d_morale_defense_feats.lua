LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Morale defense feats require catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Morale defense feats require ordinary feats")
local Effects = assert(RPG.FeatEffectSystem, "Morale defense feats require effects")
local IDS = {"CHA_NERVE_1", "CHA_NERVE_2"}
local NAMES, BONUSES = {"Iron Nerve", "Unbreakable Nerve"}, {2, 4}

for rank, id in ipairs(IDS) do
    assert(Feats[id] == nil, "duplicate canonical feat " .. id)
    Feats[id] = {featId = id, displayName = NAMES[rank], featFamilyId = "cha_nerve", rankIndex = rank,
        replacesLowerRank = rank > 1, repeatableFallback = false, governingAbilities = {"cha"}, abilityRequirements = {cha = 11 + rank * 2},
        prerequisiteFeatIds = rank > 1 and {IDS[rank - 1]} or {}, requiredCapabilityTags = {"morale"}, incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"}, requiredSubsystemTags = {"morale"}, synergyTags = {"morale", "defense"}, oneRank = true,
        effectHandlerId = "morale_save_bonus", effectParams = {moraleSaveBonus = BONUSES[rank],
            description = "Replaces the lower-rank Morale Save bonus with +" .. BONUSES[rank] .. "."},
        directorBaseWeight = 1.0, eligibilityText = "CHA " .. (11 + rank * 2) .. (rank > 1 and " / requires Iron Nerve" or ""),
        actorText = "Heroes, human Soldiers, and AI actors subject to Morale"}
end
Catalog.OrdinaryFeats = Feats
local function rank(state)
    local out = 0
    for _, id in ipairs(state and state.featIds or {}) do for i, candidate in ipairs(IDS) do if id == candidate then out = math.max(out, i) end end end
    return out
end
if not Effects.LODCheckpointDMoraleDefenseDerivedWrapped then
    Effects.LODCheckpointDMoraleDefenseDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        local current = rank(state)
        derived.moraleSaveBonus = BONUSES[current] or 0
    end
end
function RPG:ValidateCheckpointDMoraleDefenseFeats()
    local errors = {}; local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    for i, id in ipairs(IDS) do
        local definition, derived = Feats[id], {}
        Effects:ApplyDerived({featIds = {id}}, derived)
        expect(definition and definition.abilityRequirements.cha == 11 + i * 2 and derived.moraleSaveBonus == BONUSES[i], id .. " definition/bonus")
        if i > 1 then expect(definition.prerequisiteFeatIds[1] == IDS[i - 1], id .. " prerequisite") end
    end
    return #errors == 0, errors
end
concommand.Add("lod_rpg_validate_morale_defense", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDMoraleDefenseFeats()
    print("[LOD:MORALE-DEFENSE] " .. (ok and "PASS" or "FAIL") .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
