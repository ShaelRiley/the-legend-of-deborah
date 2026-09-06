LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG
local Catalog = RPG.IdentityCatalog
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects = RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
local Progression = LOD.CharacterProgressionSystem
local Validation = LOD.RPGValidation
if not Feats or not Effects or not Rules or not Progression then return end

local SOURCE_REVISION = "ANLCKQmcBBEnzsnYbFvdzzXmHJB2gAgkhunV5P2pczqttiFNGF1lfRGWUVzYRmO9v_2DdQF2Dpg8w6Ms2v9KI5U5b6HhpuEYa3gnaXvXDA"
local DAMAGE_CHAIN = {"STR_CROWBAR_D6", "STR_CROWBAR_D12"}
local CROWBAR_IDS = {
    STR_CROWBAR_D6 = true,
    STR_CROWBAR_D12 = true,
    STR_CROWBAR_CRUSH = true,
    WIS_HERO_OF_LEGEND = true,
    -- Preserve old in-progress saves while the renamed feat migrates to WIS.
    STR_HERO_OF_LEGEND = true
}
local PUSHER_IDS = {
    STR_KNOCKBACK_1 = true,
    STR_KNOCKBACK_2 = true,
    STR_KNOCKBACK_3 = true
}
local PULSE_MIN_RANGE_CELLS = 1
local PUSH_DISTANCE = 168
local PULSE_SPEED = 620
local CROWBAR_CLASSES = {weapon_lod_crowbar = true, weapon_crowbar = true}

local function owns(state, id)
    for _, value in ipairs(state and state.featIds or {}) do
        if value == id then return true end
    end
    return false
end

local function definition(id, name, family, rank, requirement, prerequisite, params)
    return {
        featId = id,
        displayName = name,
        featFamilyId = family,
        rankIndex = rank,
        replacesLowerRank = family == "str_crowbar_damage" and rank > 1,
        repeatableFallback = false,
        governingAbilities = {"str"},
        abilityRequirements = {str = requirement},
        prerequisiteFeatIds = prerequisite and {prerequisite} or {},
        requiredCapabilityTags = {"crowbar"},
        incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier"},
        requiredSubsystemTags = {},
        synergyTags = {"crowbar", family, "physical"},
        oneRank = true,
        effectHandlerId = "crowbar_family",
        effectParams = params,
        directorBaseWeight = 1.0,
        eligibilityText = string.format("STR %d%s", requirement,
            prerequisite and (" / requires " .. prerequisite) or ""),
        actorText = "Player-controlled heroes and human Soldiers with Crowbar/Long-Sword-family access"
    }
end

Feats.STR_CROWBAR_D6 = definition("STR_CROWBAR_D6", "Bash",
    "str_crowbar_damage", 1, 13, nil, {
        crowbarDamageDieSides = 6,
        crowbarPushDistance = PUSH_DISTANCE,
        description = "Crowbar-family base damage becomes universal exploding 1d6. Each successful nonlethal hit requests one 168-unit physical push."
    })
Feats.STR_CROWBAR_D12 = definition("STR_CROWBAR_D12", "Walloper",
    "str_crowbar_damage", 2, 15, "STR_CROWBAR_D6", {
        crowbarDamageDieSides = 12,
        crowbarPushDistance = PUSH_DISTANCE,
        description = "Replaces Bash's d6 with universal SUPER 1d12 while retaining its one 168-unit physical push."
    })
Feats.STR_CROWBAR_CRUSH = definition("STR_CROWBAR_CRUSH", "Wrecking Bar",
    "str_crowbar_crush", 1, 17, "STR_CROWBAR_D12", {
        crowbarWallSlamBonusDice = 1,
        description = "Crowbar-caused wall slams gain one die while preserving the current authoritative wall-slam die class and explosion seal."
    })
Feats.STR_HERO_OF_LEGEND = nil
Feats.WIS_HERO_OF_LEGEND = {
    featId = "WIS_HERO_OF_LEGEND",
    displayName = "Hero of Legend",
    featFamilyId = "wis_hero_of_legend",
    rankIndex = 1,
    replacesLowerRank = false,
    repeatableFallback = false,
    governingAbilities = {"wis"},
    abilityRequirements = {wis = 15},
    prerequisiteFeatIds = {},
    requiredCapabilityTags = {"crowbar"},
    incompatibleFeatIds = {},
    allowedActorTypes = {"hero", "human_soldier"},
    requiredSubsystemTags = {},
    synergyTags = {"crowbar", "wis_hero_of_legend", "magic"},
    oneRank = true,
    effectHandlerId = "crowbar_family",
    effectParams = {
        heroOfLegendPulseEnabled = true,
        description = "At CurrentHP >= min(100, MaxHP), a committed Crowbar-family primary swing launches one globally exclusive, nonrecursive glowing Crowbar projectile. It travels at Bio Blaster speed for max(1, WIS bonus) grid cells and deals non-elemental Magic damage with the current Crowbar die."
    },
    directorBaseWeight = 1.0,
    eligibilityText = "WIS 15",
    actorText = "Player-controlled heroes and human Soldiers with Crowbar/Long-Sword-family access"
}

Catalog.OrdinaryFeats = Feats
Catalog.GateECrowbarSourceRevisionId = SOURCE_REVISION

Effects.CrowbarConfig = {
    sourceRevision = SOURCE_REVISION,
    damageChain = DAMAGE_CHAIN,
    pushDistance = PUSH_DISTANCE,
    pulseMinRangeCells = PULSE_MIN_RANGE_CELLS,
    pulseSpeed = PULSE_SPEED
}
Effects.CrowbarStats = Effects.CrowbarStats or {
    meleeHits = 0,
    pushRequests = 0,
    pulseEmissions = 0,
    pulseHits = 0,
    pulseBlocked = 0,
    pulseLaunchBlocks = 0,
    pulseExpired = 0
}

local function heroRangeCells(wisMod)
    return math.max(PULSE_MIN_RANGE_CELLS,
        math.floor(tonumber(wisMod) or 0))
end

function Effects:HeroOfLegendRangeCells(wisMod)
    return heroRangeCells(wisMod)
end

function Effects:CrowbarProfile(state, derived)
    local walloper = owns(state, "STR_CROWBAR_D12")
    local bash = walloper or owns(state, "STR_CROWBAR_D6")
    local hero = owns(state, "WIS_HERO_OF_LEGEND")
        or owns(state, "STR_HERO_OF_LEGEND")
    return {
        damageRank = walloper and 2 or (bash and 1 or 0),
        crowbarDamageDieSides = walloper and 12 or (bash and 6 or 3),
        crowbarPushDistance = bash and PUSH_DISTANCE or 0,
        wreckingBar = owns(state, "STR_CROWBAR_CRUSH"),
        crowbarWallSlamBonusDice = owns(state, "STR_CROWBAR_CRUSH") and 1 or 0,
        heroOfLegend = hero,
        heroOfLegendPulseRangeCells = hero
            and heroRangeCells(derived and derived.wisMod) or 0
    }
end

function Effects:HeroOfLegendDamageProfile(actor)
    local profile = self:CrowbarDamageProfile(actor)
    profile.label = "HERO OF LEGEND"
    profile.source = "hero_of_legend"
    profile.magicDamage = true
    profile.nonElemental = true
    return profile
end

function Effects:CrowbarDamageProfile(actor)
    local profile = self:CrowbarProfile(Rules:ProgressionState(actor))
    return {
        label = "CROWBAR",
        source = "crowbar",
        count = 1,
        sides = profile.crowbarDamageDieSides
    }
end

function Effects:HeroOfLegendThreshold(maxHP)
    return math.min(100, math.max(1, tonumber(maxHP) or 100))
end

function Effects:HeroOfLegendEligible(owned, currentHP, maxHP)
    return owned == true
        and (tonumber(currentHP) or 0) >= self:HeroOfLegendThreshold(maxHP)
end

function Effects:ResolveCrowbarPushRequest(authoredDistance, procDistance)
    return math.max(0, tonumber(authoredDistance) or 0)
        + math.max(0, tonumber(procDistance) or 0)
end

if not Effects.LODGateECrowbarApplyDerivedWrapped then
    Effects.LODGateECrowbarApplyDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        local profile = self:CrowbarProfile(state, derived)
        derived.crowbarDamageRank = profile.damageRank
        derived.crowbarDamageDieSides = profile.crowbarDamageDieSides
        derived.crowbarPushDistance = profile.crowbarPushDistance
        derived.crowbarWallSlamBonusDice = profile.crowbarWallSlamBonusDice
        derived.heroOfLegendPulseEnabled = profile.heroOfLegend
        derived.heroOfLegendPulseRangeCells = profile.heroOfLegendPulseRangeCells
    end
end

local function addSchemaField(name)
    local fields = RPG.Schema and RPG.Schema.DerivedStats
    if not fields then return end
    for _, existing in ipairs(fields) do
        if existing == name then return end
    end
    fields[#fields + 1] = name
end
for _, field in ipairs({
    "crowbarDamageRank", "crowbarDamageDieSides", "crowbarPushDistance",
    "crowbarWallSlamBonusDice"
}) do addSchemaField(field) end

if not Progression.LODGateECrowbarSnapshotWrapped then
    Progression.LODGateECrowbarSnapshotWrapped = true
    local base = Progression.BuildClientSnapshot
    function Progression:BuildClientSnapshot(ply)
        local snapshot = base(self, ply)
        if not snapshot then return nil end
        local derived = Rules:Derived(ply) or {}
        snapshot.crowbarDamageRank = derived.crowbarDamageRank or 0
        snapshot.crowbarDamageDieSides = derived.crowbarDamageDieSides or 3
        snapshot.crowbarPushDistance = derived.crowbarPushDistance or 0
        snapshot.crowbarWallSlamBonusDice = derived.crowbarWallSlamBonusDice or 0
        snapshot.heroOfLegendPulseEnabled = derived.heroOfLegendPulseEnabled == true
        snapshot.heroOfLegendPulseRangeCells = derived.heroOfLegendPulseRangeCells or 0
        return snapshot
    end
end

function Effects:CommitHeroOfLegendPulse(attacker, weapon, startPos, direction, reach)
    if not IsValid(attacker) or not attacker:IsPlayer() then return false, "attacker" end
    local profile = self:CrowbarProfile(Rules:ProgressionState(attacker))
    local derived = Rules:Derived(attacker) or {}
    local maxHP = tonumber(derived.maxHP) or attacker:GetMaxHealth()
    if not self:HeroOfLegendEligible(profile.heroOfLegend, attacker:Health(), maxHP) then
        return false, "threshold"
    end
    if IsValid(self.ActiveHeroOfLegendPulse) then
        local stats = self.CrowbarStats
        stats.pulseLaunchBlocks = (stats.pulseLaunchBlocks or 0) + 1
        return false, "active"
    end

    local normalized = Vector(direction.x, direction.y, direction.z):GetNormalized()
    if normalized:LengthSqr() <= 0.001 then return false, "direction" end
    local cellSize = tonumber(LOD.Config and LOD.Config.Maze
        and LOD.Config.Maze.CellSize) or 384
    local rangeCells = self:HeroOfLegendRangeCells(derived.wisMod)
    local originOffset = 18
    local origin = startPos + normalized * originOffset
    local rolls = LOD.CombatRolls
    local damageProfile = self:HeroOfLegendDamageProfile(attacker)
    local contract = rolls and rolls.RollActorDamage and rolls._RNG
        and rolls:RollActorDamage(attacker, damageProfile,
            rolls:_RNG("hero-of-legend:crowbar"), 0) or nil
    if not contract then return false, "rolls" end

    local pulse = ents.Create("lod_hero_crowbar_pulse")
    if not IsValid(pulse) then return false, "entity" end
    pulse:SetModel("models/weapons/w_crowbar.mdl")
    pulse:SetPos(origin)
    pulse:SetAngles(normalized:Angle())
    pulse:SetOwner(attacker)
    pulse.LODOwner = attacker
    pulse.LODWeapon = weapon
    pulse.LODDirection = normalized
    pulse.LODSpeed = PULSE_SPEED
    pulse.LODMaxDistance = rangeCells * cellSize
    pulse.LODArmDistance = math.max(0,
        (math.max(0, tonumber(reach) or 96) + 1) - originOffset)
    pulse.LODDamageContract = contract
    pulse:Spawn()
    pulse:Activate()
    self.ActiveHeroOfLegendPulse = pulse

    local stats = self.CrowbarStats
    stats.pulseEmissions = (stats.pulseEmissions or 0) + 1
    stats.lastPulseRangeCells = rangeCells
    stats.lastPulseRange = pulse.LODMaxDistance
    stats.lastPulseMagic = true
    attacker:EmitSound("lod/hero_of_legend_launch.wav", 79, 100, 0.84, CHAN_WEAPON)
    return true, "launched"
end

function Effects:ResolveHeroOfLegendHit(pulse, target, hitPos)
    if not IsValid(pulse) or pulse.LODResolved then return false end
    if not IsValid(target) or not target.LODHostile or target.LODDead
        or target:Health() <= 0 then return false end
    local attacker = pulse.LODOwner
    local contract = pulse.LODDamageContract
    local rolls = LOD.CombatRolls
    if not IsValid(attacker) or not contract or not rolls then return false end

    pulse.LODResolved = true
    local total = rolls:ResolveActorDamage(contract, attacker, target, {
        magic = true,
        wisScaled = true,
        nonElemental = true,
        crowbarPulse = true
    })
    total = math.max(1, math.floor(tonumber(total) or 1))
    local healthBefore = target:Health()
    local info = DamageInfo()
    info:SetAttacker(attacker)
    info:SetInflictor(pulse)
    info:SetDamage(total)
    info:SetDamageType(DMG_ENERGYBEAM)
    info:SetDamagePosition(hitPos or target:WorldSpaceCenter())
    info:SetDamageForce(vector_origin)
    target:TakeDamageInfo(info)

    local healthAfter = IsValid(target) and target:Health() or 0
    local defeated = not IsValid(target) or target.LODDead == true or healthAfter <= 0
    local effectiveDamage = math.max(0, healthBefore - math.max(0, healthAfter))
    if effectiveDamage <= 0 and not defeated then return true end
    local stats = self.CrowbarStats
    stats.pulseHits = (stats.pulseHits or 0) + 1
    stats.lastPulseDamage = effectiveDamage

    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(attacker) or nil
    local continuations = math.max(0,
        #(contract.values or {}) - (tonumber(contract.baseDice) or 1))
    if ps and self.ApplyFeedbackLoop then
        self:ApplyFeedbackLoop(attacker, ps, continuations, 0)
    end
    if ps and self.ApplyArcRecovery then
        self:ApplyArcRecovery(attacker, ps, defeated, CurTime())
    end
    if ps and LOD.Magic and LOD.Magic._Sync then LOD.Magic:_Sync(attacker, ps) end

    if rolls._Send and rolls._DamageEventText then
        local detail = contract.values and #contract.values > 0
            and string.format("[rolls %s; non-elemental Magic Crowbar projectile]",
                table.concat(contract.values, ">"))
            or "[non-elemental Magic Crowbar projectile]"
        rolls:_Send(attacker, 0, rolls:_DamageEventText(attacker,
            contract.formula, total, target, detail, nil,
            "Hostile", "Hero of Legend"))
    end
    return true
end

local function crowbarWeapon(attacker, dmginfo)
    if not IsValid(attacker) or not attacker:IsPlayer() or not dmginfo
        or not dmginfo:IsDamageType(DMG_CLUB) then return nil end
    local inflictor = dmginfo:GetInflictor()
    if IsValid(inflictor) and CROWBAR_CLASSES[inflictor:GetClass()] then return inflictor end
    local weapon = attacker:GetActiveWeapon()
    return IsValid(weapon) and CROWBAR_CLASSES[weapon:GetClass()] and weapon or nil
end

hook.Add("PostEntityTakeDamage", "LOD_RPG_GateE_CrowbarPush", function(target, dmginfo, took)
    if took == false or not IsValid(target) or not target.LODHostile
        or target.LODDead or target:Health() <= 0 or not dmginfo
        or (tonumber(dmginfo:GetDamage()) or 0) <= 0 then return end
    local attacker = dmginfo:GetAttacker()
    local weapon = crowbarWeapon(attacker, dmginfo)
    if not IsValid(weapon) then return end

    local profile = Effects:CrowbarProfile(Rules:ProgressionState(attacker))
    local procDistance, pusherProc = 0, false
    if Effects.TryPusherProc then
        procDistance, pusherProc = Effects:TryPusherProc(attacker, target, CurTime())
    end
    local requested = Effects:ResolveCrowbarPushRequest(
        profile.crowbarPushDistance, procDistance)
    local stats = Effects.CrowbarStats
    stats.meleeHits = (stats.meleeHits or 0) + 1
    stats.lastMeleeDamageDie = profile.crowbarDamageDieSides
    stats.lastPushRequest = requested
    stats.maxPushRequest = math.max(stats.maxPushRequest or 0, requested)
    if requested <= 0 then return end

    stats.pushRequests = (stats.pushRequests or 0) + 1
    local pushback = LOD.Pushback
    if pushback and pushback.Apply then
        local savesBefore = pushback.Stats and pushback.Stats.saveRolls or 0
        local result = pushback:Apply(target, {
            attacker = attacker,
            inflictor = weapon,
            distance = requested,
            source = pusherProc and "crowbar+pusher" or "crowbar",
            crowbarPush = true,
            pusherProc = pusherProc
        })
        stats.lastPushResult = result
        local savesAfter = pushback.Stats and pushback.Stats.saveRolls or savesBefore
        if requested >= PUSH_DISTANCE * 2 and savesAfter - savesBefore == 1 then
            stats.combinedSingleSaves = (stats.combinedSingleSaves or 0) + 1
        end
    end
end)

function Effects:ValidateCrowbarFamily()
    local errors = {}
    local function expect(ok, message)
        if not ok then errors[#errors + 1] = message end
    end
    local expected = {
        {"STR_CROWBAR_D6", "str", 13, nil, 1, false},
        {"STR_CROWBAR_D12", "str", 15, "STR_CROWBAR_D6", 2, true},
        {"STR_CROWBAR_CRUSH", "str", 17, "STR_CROWBAR_D12", 1, false},
        {"WIS_HERO_OF_LEGEND", "wis", 15, nil, 1, false}
    }
    for _, row in ipairs(expected) do
        local feat = Feats[row[1]]
        expect(feat ~= nil, "missing " .. row[1])
        if feat then
            expect(feat.abilityRequirements[row[2]] == row[3],
                row[1] .. " ability requirement")
            expect((feat.prerequisiteFeatIds or {})[1] == row[4], row[1] .. " prerequisite")
            expect(feat.rankIndex == row[5], row[1] .. " rank")
            expect(feat.replacesLowerRank == row[6], row[1] .. " replacement")
        end
    end
    expect(Feats.STR_HERO_OF_LEGEND == nil, "legacy STR Hero catalog row removed")
    local base = self:CrowbarProfile({featIds = {}})
    local bash = self:CrowbarProfile({featIds = {"STR_CROWBAR_D6"}})
    local walloper = self:CrowbarProfile({featIds = DAMAGE_CHAIN})
    local all = self:CrowbarProfile({featIds = {
        "STR_CROWBAR_D6", "STR_CROWBAR_D12", "STR_CROWBAR_CRUSH",
        "WIS_HERO_OF_LEGEND"
    }}, {wisMod = 2})
    expect(base.crowbarDamageDieSides == 3 and base.crowbarPushDistance == 0,
        "baseline Crowbar profile")
    expect(bash.crowbarDamageDieSides == 6 and bash.crowbarPushDistance == 168,
        "Bash d6 and push")
    expect(walloper.crowbarDamageDieSides == 12 and walloper.crowbarPushDistance == 168,
        "Walloper replacement d12 and retained push")
    expect(all.crowbarWallSlamBonusDice == 1 and all.heroOfLegend
        and all.heroOfLegendPulseRangeCells == 2, "Wrecking Bar and Hero of Legend")
    expect(self:HeroOfLegendRangeCells(-2) == 1
        and self:HeroOfLegendRangeCells(0) == 1
        and self:HeroOfLegendRangeCells(1) == 1
        and self:HeroOfLegendRangeCells(3) == 3,
        "Hero range is max(1, WIS bonus)")
    local magicProfile = self:HeroOfLegendDamageProfile({})
    expect(magicProfile.magicDamage == true and magicProfile.nonElemental == true,
        "Hero damage profile is non-elemental Magic")
    expect(self.CrowbarConfig.pulseSpeed == 620, "Hero matches Bio Blaster speed")
    expect(self:ResolveCrowbarPushRequest(168, 168) == 336,
        "Bash and Pusher assemble before one save")
    expect(self:HeroOfLegendEligible(true, 100, 160), "Hero threshold caps at 100")
    expect(self:HeroOfLegendEligible(true, 80, 80), "sub-100 MaxHP threshold")
    expect(not self:HeroOfLegendEligible(true, 99, 160), "Hero threshold rejects low HP")
    return #errors == 0, errors
end

if Validation and not Validation.LODGateECrowbarWrapped then
    Validation.LODGateECrowbarWrapped = true
    local base = Validation.Run
    function Validation:Run(printResult)
        local baseOK, errors = base(self, false)
        errors = errors or {}
        local familyOK, familyErrors = Effects:ValidateCrowbarFamily()
        for _, message in ipairs(familyErrors or {}) do
            errors[#errors + 1] = "Gate E Crowbar: " .. message
        end
        local ok = baseOK and familyOK and #errors == 0
        if printResult ~= false then
            if ok then
                print(string.format(
                    "[LOD:RPG] core RPG validation PASS — gate=%s gameplayEnabled=%s gateECrowbar=true",
                    tostring(RPG.ImplementationGate), tostring(RPG.GameplayEnabled)))
            else
                ErrorNoHalt("[LOD:RPG] core RPG validation FAILED (" .. #errors .. " error(s))\n")
                for _, message in ipairs(errors) do
                    ErrorNoHalt("[LOD:RPG]  - " .. message .. "\n")
                end
            end
        end
        return ok, errors
    end
end

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    return cv and cv:GetBool() and (not IsValid(ply) or ply:IsAdmin())
end

local function configurePlayer(ply, mode)
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState or nil
    if not state then return nil, "RPG progression state is unavailable." end
    local kept = {}
    for _, id in ipairs(state.featIds or {}) do
        if not CROWBAR_IDS[id] and not PUSHER_IDS[id] then
            kept[#kept + 1] = id
        end
    end
    state.featIds = kept
    state.featStackCounts = state.featStackCounts or {}
    for id in pairs(CROWBAR_IDS) do state.featStackCounts[id] = nil end
    for id in pairs(PUSHER_IDS) do state.featStackCounts[id] = nil end
    if mode >= 2 then
        for _, id in ipairs({
            "STR_CROWBAR_D6", "STR_CROWBAR_D12", "STR_CROWBAR_CRUSH",
            "WIS_HERO_OF_LEGEND"
        }) do
            state.featIds[#state.featIds + 1] = id
            state.featStackCounts[id] = 1
        end
    end
    if mode == 3 then
        for _, id in ipairs({"STR_KNOCKBACK_1", "STR_KNOCKBACK_2", "STR_KNOCKBACK_3"}) do
            state.featIds[#state.featIds + 1] = id
            state.featStackCounts[id] = 1
        end
    end
    Progression:_RecomputeProgressionState(state)
    Progression:SyncPlayer(ply)
    local threshold = Effects:HeroOfLegendThreshold((Rules:Derived(ply) or {}).maxHP)
    ply:SetHealth(math.max(ply:Health(), threshold))
    local weapon = ply:GetWeapon("weapon_lod_crowbar")
    if not IsValid(weapon) then weapon = ply:Give("weapon_lod_crowbar", true) end
    if IsValid(weapon) then ply:SelectWeapon("weapon_lod_crowbar") end
    if run.MarkUnranked then run:MarkUnranked("Gate E Crowbar family test") end
    return ps
end

local function resetTelemetry()
    local stats = Effects.CrowbarStats
    if IsValid(Effects.ActiveHeroOfLegendPulse) then
        Effects.ActiveHeroOfLegendPulse.LODRemovalReason = "test-reset"
        Effects.ActiveHeroOfLegendPulse:Remove()
    end
    Effects.ActiveHeroOfLegendPulse = nil
    for _, field in ipairs({
        "meleeHits", "pushRequests", "pulseEmissions", "pulseHits", "pulseBlocked",
        "pulseLaunchBlocks", "pulseExpired"
    }) do stats[field] = 0 end
    stats.lastMeleeDamageDie = nil
    stats.lastPushRequest = nil
    stats.maxPushRequest = nil
    stats.combinedSingleSaves = 0
    stats.lastPushResult = nil
    stats.lastPulseRange = nil
    stats.lastPulseRangeCells = nil
    stats.lastPulseDamage = nil
    stats.lastPulseMagic = nil
    local push = LOD.Pushback and LOD.Pushback.Stats
    if push then
        push.wallCrushes = 0
        push.crushDamage = 0
        push.lastCrowbarWallDieCount = nil
        push.lastCrowbarWallDieSides = nil
    end
    if Effects.PusherStats then
        Effects.PusherStats.procRolls = 0
        Effects.PusherStats.procs = 0
        Effects.PusherStats.cooldownBlocks = 0
    end
    Effects.PusherCooldowns = setmetatable({}, {__mode = "k"})
    Effects.PusherRNGState = setmetatable({}, {__mode = "k"})
end

concommand.Add("lod_rpg_gate_e_crowbar_validate", function(ply)
    if not developerAllowed(ply) then return end
    local ok, errors = Effects:ValidateCrowbarFamily()
    if ok then
        print("[LOD:RPG-E] Crowbar PASS — Bash d6/+168; Walloper SUPER-d12; Wrecking +1 wall die; Hero WIS15/Magic/range=max(1,WIS bonus)/620ups")
    else
        ErrorNoHalt("[LOD:RPG-E] Crowbar FAILED\n")
        for _, message in ipairs(errors or {}) do
            ErrorNoHalt("[LOD:RPG-E]  - " .. message .. "\n")
        end
    end
end)

concommand.Add("lod_rpg_gate_e_crowbar_status", function(ply)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    local derived = Rules:Derived(ply) or {}
    local profile = Effects:CrowbarProfile(Rules:ProgressionState(ply), derived)
    local pusher = Effects.PusherProfile
        and Effects:PusherProfile(Rules:ProgressionState(ply)) or {rank = 0}
    local stats = Effects.CrowbarStats
    local push = LOD.Pushback and LOD.Pushback.Stats or {}
    local expectedWallCount = profile.wreckingBar and 2 or 1
    local pass = profile.damageRank == 2 and profile.crowbarDamageDieSides == 12
        and profile.crowbarPushDistance == 168 and profile.wreckingBar
        and profile.heroOfLegend and (stats.meleeHits or 0) >= 1
        and (stats.pushRequests or 0) >= 1 and (stats.pulseEmissions or 0) >= 1
        and (stats.pulseHits or 0) >= 1 and stats.lastPulseMagic == true
        and (stats.pulseLaunchBlocks or 0) >= 1 and (push.wallCrushes or 0) >= 1
        and (push.lastCrowbarWallDieCount or 0) == expectedWallCount
        and ((pusher.rank or 0) == 0 or (stats.combinedSingleSaves or 0) >= 1)
    local line = string.format(
        "die=1d%d push=%d wreck=%s hero=%s wisMod=%d range=%dcell/%du speed=%du magic=%s swings=%d pushes=%d maxPush=%d oneSaveCombos=%d pulses=%d hits=%d launchBlocks=%d blocked=%d expired=%d walls=%d wall=%dd%d result=%s",
        profile.crowbarDamageDieSides, profile.crowbarPushDistance,
        tostring(profile.wreckingBar), tostring(profile.heroOfLegend),
        math.floor(tonumber(derived.wisMod) or 0), profile.heroOfLegendPulseRangeCells,
        profile.heroOfLegendPulseRangeCells * (tonumber(LOD.Config and LOD.Config.Maze
            and LOD.Config.Maze.CellSize) or 384), PULSE_SPEED,
        tostring(stats.lastPulseMagic == true), stats.meleeHits or 0,
        stats.pushRequests or 0, stats.maxPushRequest or 0,
        stats.combinedSingleSaves or 0, stats.pulseEmissions or 0, stats.pulseHits or 0,
        stats.pulseLaunchBlocks or 0, stats.pulseBlocked or 0,
        stats.pulseExpired or 0, push.wallCrushes or 0,
        push.lastCrowbarWallDieCount or 0, push.lastCrowbarWallDieSides or 0,
        pass and "PASS" or "WAITING")
    print("[LOD:RPG-E] " .. line)
    ply:ChatPrint(line)
end)

concommand.Add("lod_rpg_gate_e_crowbar_testkit", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) or not ply:Alive() then return end
    local mode = math.Clamp(math.floor(tonumber(args[1]) or 3), 1, 3)
    local ps, message = configurePlayer(ply, mode)
    if not ps then ply:ChatPrint(message) return end
    resetTelemetry()
    local prepared = 0
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and hostile.LODHostile and not hostile.LODDead then
            hostile:SetHealth(math.max(hostile:Health(), 400))
            prepared = prepared + 1
        end
    end
    local labels = {[1] = "BASELINE", [2] = "CROWBAR", [3] = "CROWBAR+SPACE HOG"}
    local line = string.format(
        "Batch 14R %s: full Health, Crowbar ready, %d durable targets. Hold attack toward a distant target to see one glowing Crowbar at 620ups and block extra launches; hit one target, drive one into a wall, then run crowbar_status.",
        labels[mode], prepared)
    print("[LOD:RPG-E] " .. line)
    ply:ChatPrint(line)
end)

RPG.SystemBootstrap.FeatEffectSystem = "gate_e_batch_14_crowbar"
return Effects
