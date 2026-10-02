LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Attunement requires catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Attunement requires ordinary feats")

Feats.WIS_ATTUNEMENT = {featId = "WIS_ATTUNEMENT", displayName = "Attunement", featFamilyId = "wis_attunement", rankIndex = 1,
    replacesLowerRank = false, repeatableFallback = false, governingAbilities = {"wis"}, abilityRequirements = {wis = 17},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {"elemental_magic_attack"}, incompatibleFeatIds = {},
    allowedActorTypes = {"hero", "human_soldier", "ai"}, requiredSubsystemTags = {"elements", "magic_forms"},
    synergyTags = {"wisdom", "element", "magic"}, oneRank = true, effectHandlerId = "weakness_bonus_double",
    effectParams = {weaknessBonusMultiplier = 2, weaknessBonusRolls = 1,
        description = "When elemental Magic exploits a weakness, roll the ordinary weakness bonus once and double that bonus contribution, not the entire attack. No additional weakness roll or riders are generated."},
    directorBaseWeight = 1.0, eligibilityText = "WIS 17 / owns an elemental Magic attack",
    actorText = "Heroes, human Soldiers, and eligible AI"}
Catalog.OrdinaryFeats = Feats

function RPG:ValidateCheckpointDAttunementFeat()
    local definition = Feats.WIS_ATTUNEMENT
    local ok = definition and definition.abilityRequirements.wis == 17
        and definition.requiredCapabilityTags[1] == "elemental_magic_attack"
        and definition.effectParams.weaknessBonusRolls == 1 and definition.effectParams.weaknessBonusMultiplier == 2
    return ok == true, ok and {} or {"Attunement definition mismatch"}
end

concommand.Add("lod_rpg_validate_attunement", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDAttunementFeat()
    print("[LOD:ATTUNEMENT] " .. (ok and "PASS" or "FAIL") .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
