LOD = LOD or {}; LOD.RPG = LOD.RPG or {}
local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Personality aura feats require catalog")
local Feats = assert(Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats, "Personality aura feats require ordinary feats")
local Rules = assert(LOD.RPGAbilityRules, "Personality aura feats require ability rules")
local Status = assert(LOD.RPGStatusElements, "Personality aura feats require status authority")
assert(RPG.CheckpointDCellRadiusIncludes, "Personality aura requires shared cell-radius authority")

local IDS = {"CHA_ABRASIVE_PERSONALITY_1", "CHA_NARCISSISM_2", "CHA_MEGALOMANIA_3"}
local NAMES, RADII = {"Abrasive Personality", "Narcissism", "Megalomania"}, {0, 1, 2}
for rank, id in ipairs(IDS) do
    assert(Feats[id] == nil, "duplicate canonical feat " .. id)
    Feats[id] = {featId = id, displayName = NAMES[rank], featFamilyId = "cha_personality_aura", rankIndex = rank,
        replacesLowerRank = rank > 1, repeatableFallback = false, governingAbilities = {"cha"}, abilityRequirements = {cha = 11 + rank * 2},
        prerequisiteFeatIds = rank > 1 and {IDS[rank - 1]} or {}, requiredCapabilityTags = {}, incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"}, requiredSubsystemTags = {"hostile_registry", "maze_navigation"},
        synergyTags = {"aura", "charisma", "passive_damage"}, oneRank = true, effectHandlerId = "personality_aura_pulse",
        effectParams = {cellRadius = RADII[rank], intervalDice = {3, 4}, flatDamageAbility = "cha",
            description = "Every sealed non-exploding 3d4 seconds, deals max(0, CHA_MOD) untyped passive damage to hostiles within " .. RADII[rank] .. " same-floor cell radius."},
        directorBaseWeight = 1.0, eligibilityText = "CHA " .. (11 + rank * 2) .. (rank > 1 and " / requires " .. NAMES[rank - 1] or ""),
        actorText = "Heroes, human Soldiers, and AI"}
end
Catalog.OrdinaryFeats = Feats

local function owns(state, id)
    for _, owned in ipairs(state and state.featIds or {}) do if owned == id then return true end end
    return false
end

local function alive(owner)
    if not IsValid(owner) then return false end
    if owner.IsPlayer and owner:IsPlayer() then return owner:Alive() end
    return not owner.LODDead and (not owner.Health or owner:Health() > 0)
end

function RPG:CheckpointDPersonalityAuraProfile(state)
    for rank = #IDS, 1, -1 do
        if owns(state, IDS[rank]) then return RADII[rank], IDS[rank] end
    end
    return nil
end

function RPG:CheckpointDPersonalityAuraInterval(owner)
    owner.LODPersonalityAuraRollSerial = (owner.LODPersonalityAuraRollSerial or 0) + 1
    local run = LOD.RunManager and LOD.RunManager.State
    local seed = LOD.Seeds.Derive((run and run.LevelSeed) or 1,
        string.format("personality-aura:%d:%d", owner.EntIndex and owner:EntIndex() or 0, owner.LODPersonalityAuraRollSerial))
    local rng = LOD.RNG.New(seed)
    return rng:Int(1, 4) + rng:Int(1, 4) + rng:Int(1, 4)
end

RPG.CheckpointDPersonalityAuraStats = RPG.CheckpointDPersonalityAuraStats or {pulses = 0, targets = 0, damageEvents = 0}
function RPG:ResolveCheckpointDPersonalityAura(owner)
    local state = Rules:ProgressionState(owner)
    local radius = self:CheckpointDPersonalityAuraProfile(state)
    if radius == nil or not alive(owner) then return 0 end
    local run, navigator = LOD.RunManager and LOD.RunManager.State, LOD.MazeNavigator
    local graph = run and run.Graph
    if not graph or not navigator or not LOD.HostileRegistry then return 0 end
    local ownerCell = navigator:WorldToCell(graph, owner:GetPos())
    if not ownerCell then return 0 end
    local damage = math.max(0, math.floor(tonumber((Rules:Derived(owner) or {}).chaMod) or 0))
    self.CheckpointDPersonalityAuraStats.pulses = self.CheckpointDPersonalityAuraStats.pulses + 1
    if damage <= 0 then return 0 end
    local hits = 0
    for _, target in ipairs(LOD.HostileRegistry:List() or {}) do
        if IsValid(target) and target.LODHostile and not target.LODDead and target:Health() > 0 then
            local targetCell = navigator:WorldToCell(graph, target:GetPos())
            if self:CheckpointDCellRadiusIncludes(ownerCell, targetCell, radius) then
                local info = DamageInfo()
                info:SetAttacker(owner); info:SetInflictor(owner); info:SetDamage(damage)
                info:SetDamageType(DMG_GENERIC); info:SetDamagePosition(target:WorldSpaceCenter())
                info:SetDamageForce(vector_origin)
                Status:AttachDamageContext(info, {personalityAura = true, passiveDamage = true,
                    statusProcIneligible = true, moraleIneligible = true, feedbackIneligible = true})
                target:TakeDamageInfo(info)
                hits = hits + 1
                self.CheckpointDPersonalityAuraStats.damageEvents = self.CheckpointDPersonalityAuraStats.damageEvents + 1
            end
        end
    end
    self.CheckpointDPersonalityAuraStats.targets = self.CheckpointDPersonalityAuraStats.targets + hits
    return hits
end

local function allOwners()
    local out, seen = {}, {}
    local function add(actor)
        if IsValid(actor) and not seen[actor] then seen[actor] = true; out[#out + 1] = actor end
    end
    for _, ply in ipairs(player.GetAll()) do add(ply) end
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do add(hostile) end
    return out
end

RPG.CheckpointDPersonalityAuraNextThink = RPG.CheckpointDPersonalityAuraNextThink or 0
hook.Add("Think", "LOD_CheckpointDPersonalityAura", function()
    local now = CurTime()
    if now < RPG.CheckpointDPersonalityAuraNextThink then return end
    RPG.CheckpointDPersonalityAuraNextThink = now + 0.25
    for _, owner in ipairs(allOwners()) do
        if RPG:CheckpointDPersonalityAuraProfile(Rules:ProgressionState(owner)) and alive(owner) then
            if now >= (owner.LODPersonalityAuraNextAt or 0) then
                RPG:ResolveCheckpointDPersonalityAura(owner)
                owner.LODPersonalityAuraNextAt = now + RPG:CheckpointDPersonalityAuraInterval(owner)
            end
        end
    end
end)

function RPG:ValidateCheckpointDPersonalityAuraFeats()
    local errors = {}; local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    for rank, id in ipairs(IDS) do
        local definition = Feats[id]
        expect(definition and definition.abilityRequirements.cha == 11 + rank * 2, id .. " CHA requirement")
        expect(definition and definition.effectParams.cellRadius == RADII[rank], id .. " radius")
        expect(definition and definition.effectParams.intervalDice[1] == 3 and definition.effectParams.intervalDice[2] == 4, id .. " sealed 3d4")
        if rank > 1 then expect(definition.prerequisiteFeatIds[1] == IDS[rank - 1], id .. " prerequisite") end
    end
    expect(self:CheckpointDPersonalityAuraProfile({featIds = {IDS[1], IDS[3]}}) == 2, "highest personality rank replaces lower ranks")
    return #errors == 0, errors
end

concommand.Add("lod_rpg_validate_personality_aura", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = RPG:ValidateCheckpointDPersonalityAuraFeats()
    print("[LOD:PERSONALITY-AURA] " .. (ok and "PASS" or "FAIL") .. (#errors > 0 and (" " .. table.concat(errors, "; ")) or ""))
end)
