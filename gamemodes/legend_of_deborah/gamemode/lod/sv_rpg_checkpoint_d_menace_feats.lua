LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Menace feats require catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Menace feats require ordinary feats")
local Effects = assert(RPG.FeatEffectSystem, "Menace feats require effects")
local IDS = {"CHA_MENACE_1", "CHA_MENACE_2", "CHA_MENACE_3"}
local NAMES, DCS, FRACTIONS = {"Menacing", "Dreadful", "Terrifying"}, {2, 4, 4}, {.30, .25, .20}
local DESCRIPTIONS = {
    "This is rank 1 of the dedicated offensive intimidation family. Adds +2 to MoraleDC whenever this actor is the credited attacker for a Morale check. AI actors may acquire this family through the same ordinary deterministic FeatDirector eligibility and selection rules as other AI-legal feats whenever their CHA and prerequisites qualify; it is not reserved for player characters. Against a human-controlled defender, also set HumanMoraleTraumaFraction = 0.30 for damage credited to this actor, so a single hit dealing more than 30% of current MaxHP may trigger Morale instead of the ordinary greater-than-one-third requirement. This never enables the below-50%-HP trigger or repeated-below-half trigger against humans. Against AI defenders, trigger cadence remains the ordinary AI Morale cadence; Menacing improves the opposed check rather than creating extra checks.",
    "Replaces Menacing's +2 with +4 total MoraleDC. Against human-controlled defenders, replaces Menacing's trauma threshold with HumanMoraleTraumaFraction = 0.25, so a single hit dealing more than 25% of current MaxHP may trigger Morale. It still never enables a human below-50%-HP or repeated-below-half trigger. Dreadful replaces rather than stacks with Menacing's threshold and DC bonus.",
    "Retains Dreadful's +4 total MoraleDC. Against human-controlled defenders, replaces Dreadful's trauma threshold with HumanMoraleTraumaFraction = 0.20, so a single hit dealing more than 20% of current MaxHP may trigger Morale; it still never enables the below-50%-HP or repeated-below-half trigger against humans. In addition, the first Morale Save each eligible defender makes against this actor during an encounter is rolled twice and the lower natural d20 is kept before modifiers. Later Morale Saves by that defender against the same actor return to one d20. Terrifying therefore specializes an actor into intimidation by widening the set of genuinely traumatic hits against human-controlled targets and making its first fear attempt especially difficult, while the defender's controller-based Morale cooldown remains unchanged and continues to prevent repeated player lockout.",
}
for rank, id in ipairs(IDS) do
    Feats[id] = {featId = id, displayName = NAMES[rank], featFamilyId = "cha_menace", rankIndex = rank,
        replacesLowerRank = rank > 1, repeatableFallback = false, governingAbilities = {"cha"}, abilityRequirements = {cha = 11 + rank * 2},
        prerequisiteFeatIds = rank > 1 and {IDS[rank - 1]} or {}, requiredCapabilityTags = {"morale"}, incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"}, requiredSubsystemTags = {"morale"}, synergyTags = {"morale", "offense"}, oneRank = true,
        effectHandlerId = "morale_dc_intimidation", effectParams = {moraleDCBonus = DCS[rank], humanMoraleTraumaFraction = FRACTIONS[rank],
            terrifyingFirstSaveDisadvantage = rank == 3,
            description = DESCRIPTIONS[rank]},
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
