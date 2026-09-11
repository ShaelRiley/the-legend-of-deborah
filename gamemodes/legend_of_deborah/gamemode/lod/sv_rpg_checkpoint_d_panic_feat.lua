LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Panic requires catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Panic requires ordinary feats")
assert(Feats.CHA_PANIC == nil, "duplicate canonical feat CHA_PANIC")
Feats.CHA_PANIC = {featId = "CHA_PANIC", displayName = "Panic Is Contagious", featFamilyId = "cha_panic", rankIndex = 1,
    replacesLowerRank = false, repeatableFallback = false, governingAbilities = {"cha"}, abilityRequirements = {cha = 17},
    prerequisiteFeatIds = {"CHA_MENACE_2"}, requiredCapabilityTags = {"morale"}, incompatibleFeatIds = {},
    allowedActorTypes = {"hero", "human_soldier", "ai"}, requiredSubsystemTags = {"morale", "hostile_targeting"}, synergyTags = {"morale", "cascade"}, oneRank = true,
    effectHandlerId = "morale_failure_cascade", effectParams = {graphCells = 2, cascadeImmunitySeconds = 3.0,
        description = "After an enemy fails Morale against this actor, eligible AI hostiles below half health within two graph cells make one nonrecursive Morale check; each receives 3.0 seconds cascade immunity."},
    directorBaseWeight = 1.0, eligibilityText = "CHA 17 / requires Dreadful", actorText = "Heroes, human Soldiers, and AI"}
Catalog.OrdinaryFeats = Feats
function RPG:ValidateCheckpointDPanic()
    local definition = Feats.CHA_PANIC
    local ok = definition and definition.abilityRequirements.cha == 17 and definition.prerequisiteFeatIds[1] == "CHA_MENACE_2"
        and definition.effectParams.graphCells == 2 and definition.effectParams.cascadeImmunitySeconds == 3
    return ok == true, ok and {} or {"Panic definition mismatch"}
end
concommand.Add("lod_rpg_validate_panic", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDPanic()
    print("[LOD:PANIC] " .. (ok and "PASS" or "FAIL") .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
