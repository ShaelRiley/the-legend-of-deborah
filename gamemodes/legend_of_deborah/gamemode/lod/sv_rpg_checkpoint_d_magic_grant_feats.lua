LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Magic grant feats require catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Magic grant feats require ordinary feats")
local Progression = assert(LOD.CharacterProgressionSystem, "Magic grant feats require progression")
local MagicProgression = assert(LOD.MagicProgression, "Magic grant feats require Magic progression")

local definitions = {
    {id = "INT_GRAND_UNIFIED_THEORY", name = "Grand Unified Theory", kind = "form", capability = "magic_form_grant_available", stream = "grand_unified_theory"},
    {id = "INT_EXTRACURRICULAR_ACTIVITY", name = "Extracurricular Activity", kind = "content", capability = "magic_content_grant_available", stream = "extracurricular_activity"}
}
for _, item in ipairs(definitions) do
    assert(Feats[item.id] == nil, "duplicate canonical feat " .. item.id)
    Feats[item.id] = {featId = item.id, displayName = item.name, featFamilyId = item.id:lower(), rankIndex = 1,
        replacesLowerRank = false, repeatableFallback = false, governingAbilities = {"int"}, abilityRequirements = {int = 17},
        prerequisiteFeatIds = {}, requiredCapabilityTags = {item.capability}, incompatibleFeatIds = {}, allowedActorTypes = {"hero"},
        requiredSubsystemTags = {"magic_progression"}, synergyTags = {"magic", item.kind, "progression"}, oneRank = true,
        effectHandlerId = "grant_distinct_magic_" .. item.kind, effectParams = {kind = item.kind, rngSubstream = item.stream,
            description = "Immediately grants one deterministic distinct canonical Magic " .. item.kind .. " without replacing later scheduled grants."},
        directorBaseWeight = 1.0, eligibilityText = "INT 17 / unowned Magic " .. item.kind, actorText = "Cooperative Heroes only"}
end
Catalog.OrdinaryFeats = Feats

local byId = {}; for _, item in ipairs(definitions) do byId[item.id] = item end
function MagicProgression:ApplyCheckpointDMagicGrantFeat(state, featId, campaignSeed)
    local item = byId[featId]
    if not item or not state then return false end
    local streamSeed = LOD.Seeds.Derive(campaignSeed or 1, item.stream)
    return self:_GrantDistinct(state, item.kind, "feat:" .. item.stream, streamSeed)
end

if not Progression.LODCheckpointDMagicGrantFeatCommitWrapped then
    Progression.LODCheckpointDMagicGrantFeatCommitWrapped = true
    local base = Progression.CommitFeat
    function Progression:CommitFeat(ply, featId, expectedEarnedAtLevel)
        local ok, err = base(self, ply, featId, expectedEarnedAtLevel)
        if not ok then return ok, err end
        local run = LOD.RunManager
        local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
        local state = ps and ps.progressionState
        if state and byId[featId] then
            MagicProgression:ApplyCheckpointDMagicGrantFeat(state, featId, run and run.State and run.State.CampaignSeed or 1)
            self:_RecomputeProgressionState(state)
            self:SyncPlayer(ply)
        end
        return ok, err
    end
end
if not Progression.LODCheckpointDMagicGrantFeatAutomaticWrapped then
    Progression.LODCheckpointDMagicGrantFeatAutomaticWrapped = true
    local base = Progression._CommitAutomaticFeat
    function Progression:_CommitAutomaticFeat(ps, state, draft, actorSeed)
        local result = {base(self, ps, state, draft, actorSeed)}
        if state and draft and byId[draft.selectedFeatId] then
            MagicProgression:ApplyCheckpointDMagicGrantFeat(state, draft.selectedFeatId, actorSeed)
        end
        return unpack(result)
    end
end

function RPG:ValidateCheckpointDMagicGrantFeats()
    local errors = {}; local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    for _, item in ipairs(definitions) do
        local definition = Feats[item.id]
        expect(definition and definition.abilityRequirements.int == 17 and definition.requiredCapabilityTags[1] == item.capability,
            item.id .. " definition")
        local state = {actorId = "magic-grant-validator", magicFormIds = {}, contentIds = {}, magicGrantMilestones = {}}
        local changed, granted = MagicProgression:ApplyCheckpointDMagicGrantFeat(state, item.id, 77)
        expect(changed and granted, item.id .. " first distinct grant")
        local again = MagicProgression:ApplyCheckpointDMagicGrantFeat(state, item.id, 77)
        expect(not again, item.id .. " grant persists without reroll")
    end
    return #errors == 0, errors
end
concommand.Add("lod_rpg_validate_magic_grant_feats", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDMagicGrantFeats()
    print("[LOD:MAGIC-GRANT-FEATS] " .. (ok and "PASS" or "FAIL") .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
