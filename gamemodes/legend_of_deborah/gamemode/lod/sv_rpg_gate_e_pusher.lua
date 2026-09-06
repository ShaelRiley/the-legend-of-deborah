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
local FAMILY = "str_pusher"
local CHAIN = {"STR_KNOCKBACK_1", "STR_KNOCKBACK_2", "STR_KNOCKBACK_3"}
local RANK = {STR_KNOCKBACK_1 = 1, STR_KNOCKBACK_2 = 2, STR_KNOCKBACK_3 = 3}
local CHANCE = {[1] = 0.25, [2] = 0.50, [3] = 0.75}
local WALL_DIE = {[1] = 8, [2] = 10, [3] = 12}
local PROC_DISTANCE = 168
local TARGET_COOLDOWN = 0.50

local ORDINARY_WEAPONS = {
    weapon_pistol = true,
    weapon_smg1 = true,
    weapon_ar2 = true,
    weapon_357 = true,
    weapon_shotgun = true,
    weapon_lod_crowbar = true,
    weapon_crowbar = true
}

local function owns(state, id)
    for _, value in ipairs(state and state.featIds or {}) do
        if value == id then return true end
    end
    return false
end

local function definition(id, name, requirement, prerequisite, rank, chance, wallDie)
    local sealed = rank < 3
    return {
        featId = id,
        displayName = name,
        featFamilyId = FAMILY,
        rankIndex = rank,
        replacesLowerRank = rank > 1,
        repeatableFallback = false,
        governingAbilities = {"str"},
        abilityRequirements = {str = requirement},
        prerequisiteFeatIds = prerequisite and {prerequisite} or {},
        requiredCapabilityTags = {"pushable_weapon"},
        incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"},
        requiredSubsystemTags = {},
        synergyTags = {FAMILY, "physical_push", "wall_slam"},
        oneRank = true,
        effectHandlerId = "pusher_weapon_knockback",
        effectParams = {
            weaponKnockbackProcChance = chance,
            weaponKnockbackProcDistance = PROC_DISTANCE,
            pusherProcTargetCooldownSeconds = TARGET_COOLDOWN,
            wallSlamDieSides = wallDie,
            wallSlamExplodes = rank == 3,
            wallSlamClassExplosionImmune = sealed,
            description = string.format(
                "Eligible nonlethal ordinary weapon hits have a %.0f%% chance to add 168 push before the shared STR push save. Successful procs start a 0.50-second attacker-target cooldown. Ordinary physical-push wall slams use 1d%d%s.",
                chance * 100, wallDie, sealed and " with classExplosionImmune" or " SUPER exploding")
        },
        directorBaseWeight = 1.0,
        eligibilityText = string.format("STR %d%s", requirement,
            prerequisite and (" / requires " .. prerequisite) or ""),
        actorText = "Heroes, human Soldiers, and AI with an ordinary weapon capable of damaging a pushable hostile"
    }
end

Feats.STR_KNOCKBACK_1 = definition(
    "STR_KNOCKBACK_1", "Pusher", 13, nil, 1, 0.25, 8)
Feats.STR_KNOCKBACK_2 = definition(
    "STR_KNOCKBACK_2", "Shover", 15, "STR_KNOCKBACK_1", 2, 0.50, 10)
Feats.STR_KNOCKBACK_3 = definition(
    "STR_KNOCKBACK_3", "Space Hog", 17, "STR_KNOCKBACK_2", 3, 0.75, 12)

Catalog.OrdinaryFeats = Feats
Catalog.GateEPusherSourceRevisionId = SOURCE_REVISION

Effects.PusherConfig = {
    sourceRevision = SOURCE_REVISION,
    family = FAMILY,
    chain = CHAIN,
    chanceByRank = CHANCE,
    wallDieByRank = WALL_DIE,
    procDistance = PROC_DISTANCE,
    targetCooldownSeconds = TARGET_COOLDOWN
}
Effects.PusherStats = Effects.PusherStats or {
    eligibleHits = 0,
    procRolls = 0,
    procs = 0,
    cooldownBlocks = 0,
    pushesRequested = 0
}
Effects.PusherCooldowns = Effects.PusherCooldowns or setmetatable({}, {__mode = "k"})
Effects.PusherRNGState = Effects.PusherRNGState or setmetatable({}, {__mode = "k"})

function Effects:PusherProfile(state)
    local rank = 0
    for id, value in pairs(RANK) do
        if value > rank and owns(state, id) then rank = value end
    end
    return {
        rank = rank,
        featId = rank > 0 and CHAIN[rank] or nil,
        weaponKnockbackProcChance = CHANCE[rank] or 0,
        weaponKnockbackProcDistance = rank > 0 and PROC_DISTANCE or 0,
        pusherProcTargetCooldownSeconds = rank > 0 and TARGET_COOLDOWN or 0,
        wallSlamDieSides = WALL_DIE[rank] or 3,
        wallSlamExplodes = rank == 3,
        wallSlamClassExplosionImmune = rank == 1 or rank == 2
    }
end

function Effects:ResolvePusherRoll(chance, cooldownActive, roll)
    local probability = math.Clamp(tonumber(chance) or 0, 0, 1)
    if probability <= 0 then return false, false, "unowned" end
    if cooldownActive == true then return false, false, "cooldown" end
    local natural = math.Clamp(tonumber(roll) or 0, 0, 0.999999999)
    return natural < probability, true, natural < probability and "proc" or "miss"
end

local function levelSeed()
    local state = LOD.RunManager and LOD.RunManager.State
    return state and state.LevelSeed or 1
end

local function actorKey(actor)
    local state = Rules:ProgressionState(actor)
    if state and state.actorId then return tostring(state.actorId) end
    return IsValid(actor) and tostring(actor:EntIndex()) or "world"
end

function Effects:_PusherRoll(attacker, target)
    local seed = levelSeed()
    local byTarget = self.PusherRNGState[attacker]
    if not byTarget then
        byTarget = setmetatable({}, {__mode = "k"})
        self.PusherRNGState[attacker] = byTarget
    end
    local stream = byTarget[target]
    if not stream or stream.levelSeed ~= seed then
        stream = {levelSeed = seed, serial = 0}
        byTarget[target] = stream
    end
    stream.serial = stream.serial + 1
    local derivedSeed = LOD.Seeds.Derive(seed, string.format(
        "pusher-proc:v1:%s:%d:%d", actorKey(attacker),
        IsValid(target) and target:EntIndex() or 0, stream.serial))
    return LOD.RNG.New(derivedSeed):Float()
end

function Effects:_PusherCooldownReadyAt(attacker, target)
    local byTarget = self.PusherCooldowns[attacker]
    return byTarget and tonumber(byTarget[target]) or 0
end

function Effects:_SetPusherCooldown(attacker, target, readyAt)
    local byTarget = self.PusherCooldowns[attacker]
    if not byTarget then
        byTarget = setmetatable({}, {__mode = "k"})
        self.PusherCooldowns[attacker] = byTarget
    end
    byTarget[target] = readyAt
end

function Effects:TryPusherProc(attacker, target, now, forcedRoll)
    local profile = self:PusherProfile(Rules:ProgressionState(attacker))
    local at = tonumber(now) or CurTime()
    local stats = self.PusherStats
    if profile.rank <= 0 then return 0, false, "unowned" end
    if not IsValid(target) or not target.LODHostile or target.LODDead
        or target:Health() <= 0 or target.LODDeadcrabState == "latched"
        or target.LODPushImmune == true
        or target:GetNW2Bool("LOD_PushImmune", false) then
        return 0, false, "ineligible"
    end
    local readyAt = self:_PusherCooldownReadyAt(attacker, target)
    stats.eligibleHits = (stats.eligibleHits or 0) + 1
    if at < readyAt then
        stats.cooldownBlocks = (stats.cooldownBlocks or 0) + 1
        return 0, false, "cooldown"
    end
    local roll = forcedRoll ~= nil and forcedRoll or self:_PusherRoll(attacker, target)
    local proc, rolled, reason = self:ResolvePusherRoll(
        profile.weaponKnockbackProcChance, false, roll)
    if not rolled then
        return 0, false, reason
    end
    stats.procRolls = (stats.procRolls or 0) + 1
    stats.lastRoll = roll
    stats.lastChance = profile.weaponKnockbackProcChance
    if not proc then return 0, false, reason end
    self:_SetPusherCooldown(attacker, target, at + TARGET_COOLDOWN)
    stats.procs = (stats.procs or 0) + 1
    stats.pushesRequested = (stats.pushesRequested or 0) + 1
    stats.lastProcAt = at
    return PROC_DISTANCE, true, reason
end

if not Effects.LODGateEPusherApplyDerivedWrapped then
    Effects.LODGateEPusherApplyDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        local profile = self:PusherProfile(state)
        derived.pusherRank = profile.rank
        derived.weaponKnockbackProcChance = profile.weaponKnockbackProcChance
        derived.weaponKnockbackProcDistance = profile.weaponKnockbackProcDistance
        derived.pusherProcTargetCooldownSeconds = profile.pusherProcTargetCooldownSeconds
        derived.wallSlamDieSides = profile.wallSlamDieSides
        derived.wallSlamExplodes = profile.wallSlamExplodes
        derived.wallSlamClassExplosionImmune = profile.wallSlamClassExplosionImmune
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
addSchemaField("pusherRank")

if not Progression.LODGateEPusherSnapshotWrapped then
    Progression.LODGateEPusherSnapshotWrapped = true
    local base = Progression.BuildClientSnapshot
    function Progression:BuildClientSnapshot(ply)
        local snapshot = base(self, ply)
        if not snapshot then return nil end
        local derived = Rules:Derived(ply) or {}
        snapshot.pusherRank = derived.pusherRank or 0
        snapshot.weaponKnockbackProcChance = derived.weaponKnockbackProcChance or 0
        snapshot.weaponKnockbackProcDistance = derived.weaponKnockbackProcDistance or 0
        snapshot.pusherProcTargetCooldownSeconds = derived.pusherProcTargetCooldownSeconds or 0
        snapshot.wallSlamDieSides = derived.wallSlamDieSides or 3
        snapshot.wallSlamExplodes = derived.wallSlamExplodes == true
        snapshot.wallSlamClassExplosionImmune =
            derived.wallSlamClassExplosionImmune == true
        return snapshot
    end
end

function Effects:ValidatePusherFamily()
    local errors = {}
    local function expect(ok, message)
        if not ok then errors[#errors + 1] = message end
    end
    local expected = {
        {"STR_KNOCKBACK_1", 13, nil, 0.25, 8, true},
        {"STR_KNOCKBACK_2", 15, "STR_KNOCKBACK_1", 0.50, 10, true},
        {"STR_KNOCKBACK_3", 17, "STR_KNOCKBACK_2", 0.75, 12, false}
    }
    for rank, row in ipairs(expected) do
        local feat = Feats[row[1]]
        expect(feat ~= nil, "missing " .. row[1])
        if feat then
            expect(feat.abilityRequirements.str == row[2], row[1] .. " STR requirement")
            expect((feat.prerequisiteFeatIds or {})[1] == row[3], row[1] .. " prerequisite")
            expect(feat.rankIndex == rank and feat.replacesLowerRank == (rank > 1),
                row[1] .. " replacement rank")
            expect(feat.effectParams.weaponKnockbackProcChance == row[4], row[1] .. " chance")
            expect(feat.effectParams.wallSlamDieSides == row[5], row[1] .. " wall die")
            expect(feat.effectParams.wallSlamClassExplosionImmune == row[6],
                row[1] .. " explosion seal")
        end
    end
    local baseline = self:PusherProfile({featIds = {}})
    local pusher = self:PusherProfile({featIds = {"STR_KNOCKBACK_1"}})
    local shover = self:PusherProfile({featIds = {"STR_KNOCKBACK_1", "STR_KNOCKBACK_2"}})
    local hog = self:PusherProfile({featIds = CHAIN})
    expect(baseline.rank == 0 and baseline.wallSlamDieSides == 3,
        "baseline 1d3 wall slam")
    expect(pusher.rank == 1 and pusher.weaponKnockbackProcChance == 0.25
        and pusher.wallSlamDieSides == 8 and pusher.wallSlamClassExplosionImmune,
        "Pusher profile")
    expect(shover.rank == 2 and shover.weaponKnockbackProcChance == 0.50
        and shover.wallSlamDieSides == 10 and shover.wallSlamClassExplosionImmune,
        "Shover profile")
    expect(hog.rank == 3 and hog.weaponKnockbackProcChance == 0.75
        and hog.wallSlamDieSides == 12 and hog.wallSlamExplodes
        and not hog.wallSlamClassExplosionImmune, "Space Hog profile")
    local proc, rolled, reason = self:ResolvePusherRoll(0.25, false, 0.249)
    expect(proc and rolled and reason == "proc", "Pusher successful utility roll")
    proc, rolled, reason = self:ResolvePusherRoll(0.75, false, 0.751)
    expect(not proc and rolled and reason == "miss", "Space Hog failed utility roll")
    proc, rolled, reason = self:ResolvePusherRoll(0.75, true, 0.1)
    expect(not proc and not rolled and reason == "cooldown", "cooldown suppresses roll")
    return #errors == 0, errors
end

if Validation and not Validation.LODGateEPusherWrapped then
    Validation.LODGateEPusherWrapped = true
    local base = Validation.Run
    function Validation:Run(printResult)
        local baseOK, errors = base(self, false)
        errors = errors or {}
        local featOK, featErrors = Effects:ValidatePusherFamily()
        for _, message in ipairs(featErrors or {}) do
            errors[#errors + 1] = "Gate E Pusher: " .. message
        end
        local ok = baseOK and featOK and #errors == 0
        if printResult ~= false then
            if ok then
                print(string.format(
                    "[LOD:RPG] core RPG validation PASS — gate=%s gameplayEnabled=%s gateEPusher=true",
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

local function ordinaryWeaponClass(attacker, dmginfo)
    if not IsValid(attacker) or not dmginfo then return nil end
    if dmginfo:IsDamageType(DMG_BLAST) or dmginfo:IsDamageType(DMG_SONIC)
        or dmginfo:IsDamageType(DMG_CRUSH) then return nil end
    local weapon = attacker.GetActiveWeapon and attacker:GetActiveWeapon() or nil
    local class = IsValid(weapon) and weapon:GetClass() or nil
    if ORDINARY_WEAPONS[class] then return class, weapon end
    local inflictor = dmginfo:GetInflictor()
    class = IsValid(inflictor) and inflictor:GetClass() or nil
    if ORDINARY_WEAPONS[class] then return class, inflictor end
    return nil
end

-- Non-Shotgun ordinary weapon hits arrive here after actual HP damage. Shotgun
-- is excluded because its pellets are aggregated and bridged exactly once below.
hook.Add("PostEntityTakeDamage", "LOD_RPG_GateE_PusherWeaponHit", function(target, dmginfo, took)
    if took == false or not IsValid(target) or not target.LODHostile
        or target.LODDead or target:Health() <= 0 or not dmginfo
        or (tonumber(dmginfo:GetDamage()) or 0) <= 0 then return end
    local attacker = dmginfo:GetAttacker()
    local weaponClass, weapon = ordinaryWeaponClass(attacker, dmginfo)
    if not weaponClass or weaponClass == "weapon_shotgun" then return end
    local distance, proc = Effects:TryPusherProc(attacker, target, CurTime())
    if not proc or distance <= 0 then return end
    local pushback = LOD.Pushback
    if pushback and pushback.Apply then
        pushback:Apply(target, {
            attacker = attacker,
            inflictor = weapon,
            distance = distance,
            source = "pusher proc",
            pusherProc = true
        })
    end
end)

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    return cv and cv:GetBool() and (not IsValid(ply) or ply:IsAdmin())
end

local function configurePlayer(ply, rank)
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState or nil
    if not state then return nil, "RPG progression state is unavailable." end
    local kept = {}
    for _, id in ipairs(state.featIds or {}) do
        if not RANK[id] then kept[#kept + 1] = id end
    end
    state.featIds = kept
    state.featStackCounts = state.featStackCounts or {}
    for id in pairs(RANK) do state.featStackCounts[id] = nil end
    for index = 1, math.Clamp(math.floor(tonumber(rank) or 0), 0, 3) do
        local id = CHAIN[index]
        state.featIds[#state.featIds + 1] = id
        state.featStackCounts[id] = 1
    end
    Progression:_RecomputeProgressionState(state)
    Progression:SyncPlayer(ply)
    local weapon = ply:GetWeapon("weapon_pistol")
    if not IsValid(weapon) then weapon = ply:Give("weapon_pistol", true) end
    ply:SetAmmo(math.max(ply:GetAmmoCount("Pistol"), 90), "Pistol")
    if IsValid(weapon) then
        weapon:SetClip1(math.max(weapon:Clip1(), 18))
        ply:SelectWeapon("weapon_pistol")
    end
    if run.MarkUnranked then run:MarkUnranked("Gate E Pusher family test") end
    return ps
end

local function resetTelemetry()
    local stats = Effects.PusherStats
    stats.eligibleHits = 0
    stats.procRolls = 0
    stats.procs = 0
    stats.cooldownBlocks = 0
    stats.pushesRequested = 0
    stats.lastRoll = nil
    stats.lastChance = nil
    Effects.PusherCooldowns = setmetatable({}, {__mode = "k"})
    Effects.PusherRNGState = setmetatable({}, {__mode = "k"})
    local push = LOD.Pushback and LOD.Pushback.Stats
    if push then
        push.saveRolls = 0
        push.savesSucceeded = 0
        push.savesFailed = 0
        push.pushImmuneBlocks = 0
        push.lastSaveNatural = nil
        push.lastSaveDC = nil
        push.lastSaveTotal = nil
        push.lastSaveSucceeded = nil
    end
end

concommand.Add("lod_rpg_gate_e_pusher_validate", function(ply)
    if not developerAllowed(ply) then return end
    local ok, errors = Effects:ValidatePusherFamily()
    local pushOK, pushErrors = true, {}
    if LOD.Pushback and LOD.Pushback.ValidateSharedPushSave then
        pushOK, pushErrors = LOD.Pushback:ValidateSharedPushSave()
    end
    if ok and pushOK then
        print("[LOD:RPG-E] Pusher PASS — 25/50/75%; +168; cooldown 0.50s; wall dice d8/d10/SUPER-d12")
    else
        ErrorNoHalt("[LOD:RPG-E] Pusher FAILED\n")
        for _, message in ipairs(errors or {}) do ErrorNoHalt("[LOD:RPG-E]  - " .. message .. "\n") end
        for _, message in ipairs(pushErrors or {}) do ErrorNoHalt("[LOD:RPG-E]  - " .. message .. "\n") end
    end
end)

concommand.Add("lod_rpg_gate_e_pusher_status", function(ply)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    local profile = Effects:PusherProfile(Rules:ProgressionState(ply))
    local stats = Effects.PusherStats
    local push = LOD.Pushback and LOD.Pushback.Stats or {}
    local pass = profile.rank == 0 and (stats.procs or 0) == 0
        or profile.rank > 0 and (stats.procRolls or 0) >= 1 and (stats.procs or 0) >= 1
            and (push.saveRolls or 0) >= 1
    local line = string.format(
        "rank=%d chance=%.2f distance=%d cooldown=%.2fs wall=1d%d sealed=%s rolls=%d procs=%d cooldownBlocks=%d pushSaves=%d lastSave=%s result=%s",
        profile.rank, profile.weaponKnockbackProcChance,
        profile.weaponKnockbackProcDistance, profile.pusherProcTargetCooldownSeconds,
        profile.wallSlamDieSides, tostring(profile.wallSlamClassExplosionImmune),
        stats.procRolls or 0, stats.procs or 0, stats.cooldownBlocks or 0,
        push.saveRolls or 0, tostring(push.lastSaveSucceeded), pass and "PASS" or "WAITING")
    print("[LOD:RPG-E] " .. line)
    ply:ChatPrint(line)
end)

concommand.Add("lod_rpg_gate_e_pusher_testkit", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) or not ply:Alive() then return end
    local rank = math.Clamp(math.floor(tonumber(args[1]) or 3), 0, 3)
    local ps, message = configurePlayer(ply, rank)
    if not ps then ply:ChatPrint(message) return end
    resetTelemetry()
    local prepared = 0
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and hostile.LODHostile and not hostile.LODDead then
            hostile:SetHealth(math.max(hostile:Health(), 200))
            prepared = prepared + 1
        end
    end
    local profile = Effects:PusherProfile(Rules:ProgressionState(ply))
    local line = string.format(
        "Batch 13 rank %d: Pistol ready, %d durable targets. Shoot survivors until pushed; then run pusher_status. Chance %.0f%%, wall 1d%d%s.",
        rank, prepared, profile.weaponKnockbackProcChance * 100,
        profile.wallSlamDieSides, profile.wallSlamExplodes and "!" or " sealed")
    print("[LOD:RPG-E] " .. line)
    ply:ChatPrint(line)
end)

RPG.SystemBootstrap.FeatEffectSystem = "gate_e_batch_13_pusher"
return Effects
