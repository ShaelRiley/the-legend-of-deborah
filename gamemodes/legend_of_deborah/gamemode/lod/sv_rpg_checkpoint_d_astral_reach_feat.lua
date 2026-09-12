LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Astral Reach requires catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Astral Reach requires ordinary feats")

Feats.WIS_ASTRAL_REACH = {
    featId = "WIS_ASTRAL_REACH", displayName = "Astral Reach", featFamilyId = "wis_astral_reach", rankIndex = 1,
    replacesLowerRank = false, repeatableFallback = false, governingAbilities = {"wis"}, abilityRequirements = {wis = 15},
    prerequisiteFeatIds = {}, requiredCapabilityTags = {"magic_form_owned"}, incompatibleFeatIds = {}, allowedActorTypes = {"hero"},
    requiredSubsystemTags = {"magic_forms"}, synergyTags = {"magic", "spatial", "wisdom"}, oneRank = true,
    effectHandlerId = "magic_spatial_bonus_cells", effectParams = {cells = 2,
        description = "Adds 2 cells to WIS-scaled Magic Form spatial dimensions."},
    directorBaseWeight = 1.0, eligibilityText = "WIS 15 / owns a Magic Form", actorText = "Cooperative Heroes only"
}
Catalog.OrdinaryFeats = Feats

function RPG:ValidateCheckpointDAstralReachFeat()
    local errors = {}; local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    local definition = Feats.WIS_ASTRAL_REACH
    expect(definition and definition.abilityRequirements.wis == 15, "WIS_ASTRAL_REACH WIS requirement")
    expect(definition and definition.requiredCapabilityTags[1] == "magic_form_owned", "WIS_ASTRAL_REACH Form gate")
    expect(definition and definition.allowedActorTypes[1] == "hero", "WIS_ASTRAL_REACH Hero gate")
    expect(definition and definition.effectHandlerId == "magic_spatial_bonus_cells" and definition.effectParams.cells == 2,
        "WIS_ASTRAL_REACH spatial effect")
    return #errors == 0, errors
end

concommand.Add("lod_rpg_validate_astral_reach", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDAstralReachFeat()
    print("[LOD:ASTRAL-REACH] " .. (ok and "PASS" or "FAIL") .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
