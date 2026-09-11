LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Menace feats require catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Menace feats require ordinary feats")
local Effects = assert(RPG.FeatEffectSystem, "Menace feats require effects")
local IDS = {"CHA_MENACE_1", "CHA_MENACE_2", "CHA_MENACE_3"}
local NAMES, DCS, FRACTIONS = {"Menacing", "Dreadful", "Terrifying"}, {2, 4, 4}, {.30, .25, .20}
for rank, id in ipairs(IDS) do
    Feats[id] = {featId = id, displayName = NAMES[rank], featFamilyId = "cha_menace", rankIndex = rank,
        replacesLowerRank = rank > 1, repeatableFallback = false, governingAbilities = {"cha"}, abilityRequirements = {cha = 11 + rank * 2},
        prerequisiteFeatIds = rank > 1 and {IDS[rank - 1]} or {}, requiredCapabilityTags = {"morale"}, incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"}, requiredSubsystemTags = {"morale"}, synergyTags = {"morale", "offense"}, oneRank = true,
        effectHandlerId = "morale_dc_intimidation", effectParams = {moraleDCBonus = DCS[rank], humanMoraleTraumaFraction = FRACTIONS[rank],
            terrifyingFirstSaveDisadvantage = rank == 3,
            description = "Replaces lower-rank Morale DC and human trauma values; Terrifying rolls the first eligible defender save against this actor twice and keeps the lower natural d20."},
        directorBaseWeight = 1.0, eligibilityText = "CHA " .. (11 + rank * 2) .. (rank > 1 and " / requires " .. NAMES[rank - 1] or ""),
        actorText = "Heroes, human Soldiers, and AI"}
end
Catalog.OrdinaryFeats = Feats
local function rank(state)
    local out = 0
    for _, id in ipairs(state and state.featIds or {}) do for i, candidate in ipairs(IDS) do if id == candidate then out = math.max(out, i) end end end
    return out
end
if not Effects.LODCheckpointDMenaceDerivedWrapped then
    Effects.LODCheckpointDMenaceDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        local current = rank(state)
        derived.moraleDCBonus = DCS[current] or 0
        derived.humanMoraleTraumaFraction = FRACTIONS[current]
        derived.terrifyingFirstSaveDisadvantage = current == 3
    end
end
function RPG:ValidateCheckpointDMenaceFeats()
    local errors = {}; local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    for i, id in ipairs(IDS) do
        local definition, derived = Feats[id], {}; Effects:ApplyDerived({featIds = {id}}, derived)
        expect(definition and definition.abilityRequirements.cha == 11 + i * 2 and derived.moraleDCBonus == DCS[i]
            and derived.humanMoraleTraumaFraction == FRACTIONS[i], id .. " definition/derived")
        if i > 1 then expect(definition.prerequisiteFeatIds[1] == IDS[i - 1], id .. " prerequisite") end
    end
    return #errors == 0, errors
end
concommand.Add("lod_rpg_validate_menace", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDMenaceFeats()
    print("[LOD:MENACE] " .. (ok and "PASS" or "FAIL") .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
