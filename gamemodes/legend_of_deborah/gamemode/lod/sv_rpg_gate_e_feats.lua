LOD = LOD or {}
LOD.RPG = LOD.RPG or {}
LOD.RPG.FeatEffectSystem = LOD.RPG.FeatEffectSystem or {}

local RPG = LOD.RPG
local Catalog = RPG.IdentityCatalog
local FeatEffectSystem = RPG.FeatEffectSystem
local Feats = Catalog.LevelOneOrdinaryFeats

-- Gate E batch 1: the complete CON Health-Regeneration ladder.  Keep the
-- historical table name as a compatibility alias until the full Gate E catalog
-- is present; it is already the FeatDirector's ordinary pool at every feat level.
Catalog.OrdinaryFeats = Feats

local function regenDefinition(featId, displayName, requirement, prerequisite, rank, ceiling)
    return {
        featId = featId,
        displayName = displayName,
        featFamilyId = "con_health_regeneration",
        rankIndex = rank,
        replacesLowerRank = rank > 1,
        repeatableFallback = false,
        governingAbilities = {"con"},
        abilityRequirements = {con = requirement},
        prerequisiteFeatIds = prerequisite and {prerequisite} or {},
        requiredCapabilityTags = {},
        incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"},
        requiredSubsystemTags = {},
        synergyTags = {"health_regeneration", "maximum_hp"},
        oneRank = true,
        effectHandlerId = "health_regeneration",
        effectParams = {
            ceilingFraction = ceiling,
            damageFreeDelaySeconds = 5.0,
            baseMaxHPPerSecond = 0.01,
            description = rank == 1
                and "Enables passive Health Regeneration after 5.0 damage-free seconds, restoring 1.0% MaxHP/second × CON regeneration multiplier up to 11% MaxHP; never restores Tetris overfill."
                or string.format("Replaces lower Recovery ranks and raises the passive Health-Regeneration ceiling to %d%% MaxHP; the 5.0-second delay and CON-scaled rate remain unchanged.", math.floor(ceiling * 100 + 0.5))
        },
        directorBaseWeight = 1.0,
        eligibilityText = string.format("CON %d%s", requirement,
            prerequisite and (" / requires " .. prerequisite) or ""),
        actorText = "Heroes, human Soldiers, AI"
    }
end

Feats.CON_REGEN_11 = regenDefinition("CON_REGEN_11", "Second Wind", 12, nil, 1, 0.11)
Feats.CON_REGEN_22 = regenDefinition("CON_REGEN_22", "Rapid Recovery", 14,
    "CON_REGEN_11", 2, 0.22)
Feats.CON_REGEN_33 = regenDefinition("CON_REGEN_33", "Unbroken", 16,
    "CON_REGEN_22", 3, 0.33)

local REGEN_RANKS = {
    CON_REGEN_11 = 1,
    CON_REGEN_22 = 2,
    CON_REGEN_33 = 3
}

local function ownsFeat(state, featId)
    for _, ownedId in ipairs(state and state.featIds or {}) do
        if ownedId == featId then return true end
    end
    return false
end

function FeatEffectSystem:HealthRegenProfile(state)
    local bestRank, bestDefinition = 0, nil
    for featId, rank in pairs(REGEN_RANKS) do
        if rank > bestRank and ownsFeat(state, featId) then
            bestRank = rank
            bestDefinition = Feats[featId]
        end
    end
    if not bestDefinition then
        return {
            enabled = false,
            rank = 0,
            ceilingFraction = 0,
            damageFreeDelaySeconds = 5.0,
            baseMaxHPPerSecond = 0.01
        }
    end
    local params = bestDefinition.effectParams or {}
    return {
        enabled = true,
        rank = bestRank,
        featId = bestDefinition.featId,
        ceilingFraction = tonumber(params.ceilingFraction) or 0,
        damageFreeDelaySeconds = tonumber(params.damageFreeDelaySeconds) or 5.0,
        baseMaxHPPerSecond = tonumber(params.baseMaxHPPerSecond) or 0.01
    }
end

function FeatEffectSystem:ApplyDerived(state, derived)
    local profile = self:HealthRegenProfile(state)
    derived.healthRegenEnabled = profile.enabled
    derived.healthRegenRank = profile.rank
    derived.healthRegenCeilingFraction = profile.ceilingFraction
    derived.healthRegenDamageFreeDelaySeconds = profile.damageFreeDelaySeconds
    derived.healthRegenBaseMaxHPPerSecond = profile.baseMaxHPPerSecond
end

function FeatEffectSystem:HealthRegenPerSecond(maxHP, conRegenMultiplier, baseFraction)
    return math.max(0, tonumber(maxHP) or 0)
        * math.max(0, tonumber(baseFraction) or 0.01)
        * math.max(0, tonumber(conRegenMultiplier) or 1)
end

FeatEffectSystem.RegenActors = FeatEffectSystem.RegenActors
    or setmetatable({}, {__mode = "k"})

function FeatEffectSystem:TrackActor(actor, requireFreshDelay)
    if not IsValid(actor) then return end
    local rules = LOD.RPGAbilityRules
    local derived = rules and rules.Derived and rules:Derived(actor) or nil
    if not derived or derived.healthRegenEnabled ~= true then
        self.RegenActors[actor] = nil
        return
    end
    local maximum = math.max(1, actor:GetMaxHealth())
    local ceiling = math.max(1, math.floor(maximum
        * (tonumber(derived.healthRegenCeilingFraction) or 0)))
    if actor:Health() >= ceiling then
        self.RegenActors[actor] = nil
        return
    end
    self.RegenActors[actor] = true
    if requireFreshDelay or actor.LODRPGHealthRegenEligibleAt == nil then
        actor.LODRPGHealthRegenEligibleAt = CurTime()
            + (tonumber(derived.healthRegenDamageFreeDelaySeconds) or 5.0)
        actor.LODRPGHealthRegenAccumulator = 0
    end
end

function FeatEffectSystem:OnEffectiveDamage(actor, damage)
    if not IsValid(actor) or (tonumber(damage) or 0) <= 0 then return end
    local rules = LOD.RPGAbilityRules
    local derived = rules and rules.Derived and rules:Derived(actor) or nil
    if not derived or derived.healthRegenEnabled ~= true then return end
    -- EntityTakeDamage's final gamemode seam still precedes Source's HP write,
    -- so do not reject a full-health actor by inspecting pre-hit Health here.
    self.RegenActors[actor] = true
    actor.LODRPGHealthRegenEligibleAt = CurTime()
        + (tonumber(derived.healthRegenDamageFreeDelaySeconds) or 5.0)
    actor.LODRPGHealthRegenAccumulator = 0
end

function FeatEffectSystem:_TickActor(actor, elapsed)
    if not IsValid(actor) or (actor:IsPlayer() and not actor:Alive()) then
        self.RegenActors[actor] = nil
        return
    end
    local rules = LOD.RPGAbilityRules
    local derived = rules and rules.Derived and rules:Derived(actor) or nil
    if not derived or derived.healthRegenEnabled ~= true then
        self.RegenActors[actor] = nil
        return
    end

    local maximum = math.max(1, actor:GetMaxHealth())
    local ceiling = math.max(1, math.floor(maximum
        * (tonumber(derived.healthRegenCeilingFraction) or 0)))
    if actor:Health() >= ceiling then
        actor.LODRPGHealthRegenAccumulator = 0
        self.RegenActors[actor] = nil
        return
    end
    if CurTime() < (actor.LODRPGHealthRegenEligibleAt or 0) then return end

    local amount = self:HealthRegenPerSecond(maximum, derived.conRegenMultiplier,
        derived.healthRegenBaseMaxHPPerSecond) * elapsed
    local accumulated = (tonumber(actor.LODRPGHealthRegenAccumulator) or 0) + amount
    local whole = math.floor(accumulated)
    actor.LODRPGHealthRegenAccumulator = accumulated - whole
    if whole <= 0 then return end

    local before = actor:Health()
    actor:SetHealth(math.min(ceiling, before + whole))
    if actor:Health() > before then
        actor.LODRPGLastHealthRegenAt = CurTime()
    end
end

timer.Create("LOD_RPG_GateE_HealthRegen", 0.25, 0, function()
    for actor in pairs(FeatEffectSystem.RegenActors) do
        FeatEffectSystem:_TickActor(actor, 0.25)
    end
end)

function FeatEffectSystem:ValidateHealthRegen()
    local errors = {}
    local function expect(condition, message)
        if not condition then errors[#errors + 1] = message end
    end
    local expected = {
        CON_REGEN_11 = {1, 12, nil, 0.11},
        CON_REGEN_22 = {2, 14, "CON_REGEN_11", 0.22},
        CON_REGEN_33 = {3, 16, "CON_REGEN_22", 0.33}
    }
    for featId, values in pairs(expected) do
        local definition = Feats[featId]
        expect(definition ~= nil, "missing " .. featId)
        if definition then
            expect(definition.featFamilyId == "con_health_regeneration", featId .. " family")
            expect(definition.rankIndex == values[1], featId .. " rank")
            expect(definition.abilityRequirements.con == values[2], featId .. " requirement")
            expect((definition.prerequisiteFeatIds or {})[1] == values[3], featId .. " prerequisite")
            expect(definition.effectHandlerId == "health_regeneration", featId .. " handler")
            expect(definition.effectParams.ceilingFraction == values[4], featId .. " ceiling")
        end
    end

    local rankOne = self:HealthRegenProfile({featIds = {"CON_REGEN_11"}})
    local rankThree = self:HealthRegenProfile({featIds = {
        "CON_REGEN_11", "CON_REGEN_22", "CON_REGEN_33"
    }})
    expect(rankOne.enabled and rankOne.rank == 1 and rankOne.ceilingFraction == 0.11,
        "rank-one profile")
    expect(rankThree.enabled and rankThree.rank == 3 and rankThree.ceilingFraction == 0.33,
        "rank replacement profile")
    expect(self:HealthRegenPerSecond(100, 1.5, 0.01) == 1.5,
        "CON-scaled regeneration rate")

    local progression = LOD.CharacterProgressionSystem
    if progression and progression._FeatEligible then
        local state = {
            featIds = {},
            featQualificationAbilities = {con = 16},
            classId = "fighter",
            secondaryAbilities = {}
        }
        expect(not progression:_FeatEligible({}, state, Feats.CON_REGEN_22),
            "rank two must require Second Wind")
        state.featIds = {"CON_REGEN_11"}
        expect(progression:_FeatEligible({}, state, Feats.CON_REGEN_22),
            "rank two legal after Second Wind")
        expect(not progression:_FeatEligible({}, state, Feats.CON_REGEN_33),
            "rank three must require Rapid Recovery")
        state.featIds[#state.featIds + 1] = "CON_REGEN_22"
        expect(progression:_FeatEligible({}, state, Feats.CON_REGEN_33),
            "rank three legal after Rapid Recovery")
    else
        expect(false, "FeatDirector eligibility authority unavailable")
    end
    return #errors == 0, errors
end

concommand.Add("lod_rpg_gate_e_regen_validate", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if not cv or not cv:GetBool() or (IsValid(ply) and not ply:IsAdmin()) then return end
    local ok, errors = FeatEffectSystem:ValidateHealthRegen()
    if ok then
        print("[LOD:RPG-E] Health-Regeneration feat family PASS — 3/3 ranks, replacement semantics, CON rate")
    else
        ErrorNoHalt("[LOD:RPG-E] Health-Regeneration feat family FAILED\n")
        for _, message in ipairs(errors) do ErrorNoHalt("[LOD:RPG-E]  - " .. message .. "\n") end
    end
end)

concommand.Add("lod_rpg_gate_e_regen_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if not cv or not cv:GetBool() or (IsValid(ply) and not ply:IsAdmin()) then return end
    if not IsValid(ply) then
        print("[LOD:RPG-E] Run this command from an attached player console.")
        return
    end
    local rules = LOD.RPGAbilityRules
    local derived = rules and rules:Derived(ply) or nil
    local maximum = math.max(1, ply:GetMaxHealth())
    local ceiling = math.floor(maximum * (tonumber(derived and derived.healthRegenCeilingFraction) or 0))
    local remaining = math.max(0, (ply.LODRPGHealthRegenEligibleAt or 0) - CurTime())
    local line = string.format("enabled=%s rank=%d HP=%d/%d ceiling=%d delay=%.2fs rate=%.2fHP/s",
        tostring(derived and derived.healthRegenEnabled == true),
        math.floor(tonumber(derived and derived.healthRegenRank) or 0),
        ply:Health(), maximum, ceiling, remaining,
        FeatEffectSystem:HealthRegenPerSecond(maximum,
            derived and derived.conRegenMultiplier,
            derived and derived.healthRegenBaseMaxHPPerSecond))
    print("[LOD:RPG-E] " .. line)
    ply:ChatPrint(line)
end)

concommand.Add("lod_rpg_test_regen", function(ply, _, args)
    local cv = GetConVar("lod_developer_mode")
    if not cv or not cv:GetBool() or not IsValid(ply) or not ply:IsAdmin() then return end
    local run = LOD.RunManager
    local ps = run and run:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState or nil
    local progression = LOD.CharacterProgressionSystem
    if not state or not progression then
        ply:ChatPrint("RPG progression state is unavailable.")
        return
    end
    local rank = math.Clamp(math.floor(tonumber(args[1]) or 1), 0, 3)
    local kept = {}
    for _, featId in ipairs(state.featIds or {}) do
        if not REGEN_RANKS[featId] then kept[#kept + 1] = featId end
    end
    state.featIds = kept
    for featId in pairs(REGEN_RANKS) do state.featStackCounts[featId] = nil end
    local chain = {"CON_REGEN_11", "CON_REGEN_22", "CON_REGEN_33"}
    for index = 1, rank do
        state.featIds[#state.featIds + 1] = chain[index]
        state.featStackCounts[chain[index]] = 1
    end
    progression:_RecomputeProgressionState(state)
    progression:_ApplyPlayerMaxHP(ply, state)
    if rank > 0 then ply:SetHealth(1) end
    progression:SyncPlayer(ply)
    FeatEffectSystem:TrackActor(ply, rank > 0)
    if run.MarkUnranked then run:MarkUnranked("Gate E Health-Regeneration feat test") end
    ply:ChatPrint(string.format("Gate E regen rank %d configured%s.", rank,
        rank > 0 and "; HP set to 1 and the 5-second delay started" or ""))
end)

return FeatEffectSystem
