LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Aura Burst feats require catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Aura Burst feats require ordinary feats")
local Rules = assert(LOD.RPGAbilityRules, "Aura Burst feats require ability rules")
local Status = assert(LOD.RPGStatusElements, "Aura Burst feats require status authority")

local IDS = {"CHA_AURA_BURST_1", "CHA_RADIANCE_2", "CHA_MAJESTY_3"}
local NAMES, RADII = {"Aura Burst", "Radiance", "Majesty"}, {0, 1, 2}
for rank, id in ipairs(IDS) do
    assert(Feats[id] == nil, "duplicate canonical feat " .. id)
    Feats[id] = {featId = id, displayName = NAMES[rank], featFamilyId = "cha_aura_burst", rankIndex = rank,
        replacesLowerRank = rank > 1, repeatableFallback = false, governingAbilities = {"cha"}, abilityRequirements = {cha = 11 + rank * 2},
        prerequisiteFeatIds = rank > 1 and {IDS[rank - 1]} or {}, requiredCapabilityTags = {"discrete_magic_activation"},
        incompatibleFeatIds = {}, allowedActorTypes = {"hero", "human_soldier", "ai"}, requiredSubsystemTags = {"magic_forms", "maze_navigation"},
        synergyTags = {"magic", "aura", "charisma"}, oneRank = true, effectHandlerId = "triggered_magic_aura_burst",
        effectParams = {cellRadius = RADII[rank], flatDamageAbility = "cha",
            description = "On one successful discrete Magic spend, deals max(0, CHA_MOD) supplemental magical damage to hostiles within " .. RADII[rank] .. " same-floor cell radius."},
        directorBaseWeight = 1.0, eligibilityText = "CHA " .. (11 + rank * 2) .. (rank > 1 and " / requires " .. NAMES[rank - 1] or ""),
        actorText = "Heroes, human Soldiers, and AI with a discrete active Magic Form"}
end
Catalog.OrdinaryFeats = Feats

local function owns(state, id)
    for _, owned in ipairs(state and state.featIds or {}) do if owned == id then return true end end
    return false
end

function RPG:CheckpointDAuraBurstProfile(state)
    for rank = #IDS, 1, -1 do
        if owns(state, IDS[rank]) then return RADII[rank], IDS[rank] end
    end
    return nil
end

function RPG:CheckpointDAuraBurstCellInRadius(ownerCell, targetCell, radius)
    return ownerCell ~= nil and targetCell ~= nil and ownerCell.z == targetCell.z
        and math.max(math.abs(ownerCell.x - targetCell.x), math.abs(ownerCell.y - targetCell.y)) <= radius
end

RPG.CheckpointDAuraBurstStats = RPG.CheckpointDAuraBurstStats or {pulses = 0, targets = 0, damageEvents = 0}
function RPG:ResolveCheckpointDAuraBurst(actor)
    local state = Rules:ProgressionState(actor)
    local radius = self:CheckpointDAuraBurstProfile(state)
    if radius == nil or not IsValid(actor) or not actor:Alive() then return 0 end
    local run, navigator = LOD.RunManager and LOD.RunManager.State, LOD.MazeNavigator
    local graph = run and run.Graph
    if not graph or not navigator or not LOD.HostileRegistry then return 0 end
    local ownerCell = navigator:WorldToCell(graph, actor:GetPos())
    if not ownerCell then return 0 end
    local derived = Rules:Derived(actor) or {}
    local damage = math.max(0, math.floor(tonumber(derived.chaMod) or 0))
    self.CheckpointDAuraBurstStats.pulses = self.CheckpointDAuraBurstStats.pulses + 1
    if damage <= 0 then return 0 end
    local hits = 0
    for _, target in ipairs(LOD.HostileRegistry:List() or {}) do
        if IsValid(target) and target.LODHostile and not target.LODDead and target:Health() > 0 then
            local targetCell = navigator:WorldToCell(graph, target:GetPos())
            if self:CheckpointDAuraBurstCellInRadius(ownerCell, targetCell, radius) then
                local info = DamageInfo()
                info:SetAttacker(actor); info:SetInflictor(actor); info:SetDamage(damage)
                info:SetDamageType(DMG_ENERGYBEAM); info:SetDamagePosition(target:WorldSpaceCenter())
                info:SetDamageForce(vector_origin)
                Status:AttachDamageContext(info, {magic = true, wisScaled = false, auraBurst = true,
                    statusProcIneligible = true, moraleIneligible = true, feedbackIneligible = true})
                target:TakeDamageInfo(info)
                hits = hits + 1
                self.CheckpointDAuraBurstStats.damageEvents = self.CheckpointDAuraBurstStats.damageEvents + 1
            end
        end
    end
    self.CheckpointDAuraBurstStats.targets = self.CheckpointDAuraBurstStats.targets + hits
    return hits
end

hook.Add("LODDiscreteMagicSpent", "LOD_CheckpointDAuraBurst", function(actor)
    RPG:ResolveCheckpointDAuraBurst(actor)
end)

function RPG:ValidateCheckpointDAuraBurstFeats()
    local errors = {}; local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    for rank, id in ipairs(IDS) do
        local definition = Feats[id]
        expect(definition and definition.abilityRequirements.cha == 11 + rank * 2, id .. " CHA requirement")
        expect(definition and definition.effectParams.cellRadius == RADII[rank], id .. " radius")
        if rank > 1 then expect(definition.prerequisiteFeatIds[1] == IDS[rank - 1], id .. " prerequisite") end
    end
    expect(self:CheckpointDAuraBurstProfile({featIds = {IDS[1], IDS[3]}}) == 2, "highest Aura rank replaces lower ranks")
    expect(self:CheckpointDAuraBurstCellInRadius({x = 3, y = 3, z = 0}, {x = 5, y = 1, z = 0}, 2), "same-floor square radius")
    expect(not self:CheckpointDAuraBurstCellInRadius({x = 3, y = 3, z = 0}, {x = 3, y = 3, z = 1}, 2), "same-floor restriction")
    return #errors == 0, errors
end

concommand.Add("lod_rpg_validate_aura_burst", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDAuraBurstFeats()
    print("[LOD:AURA-BURST] " .. (ok and "PASS" or "FAIL") .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
