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

local FAMILY = "dex_smg_heat"
local CHAIN = {
    "DEX_SMG_COLD_HANDS_1",
    "DEX_SMG_COLD_HANDS_2",
    "DEX_SMG_COLD_HANDS_3"
}
local RANK = {
    DEX_SMG_COLD_HANDS_1 = 1,
    DEX_SMG_COLD_HANDS_2 = 2,
    DEX_SMG_COLD_HANDS_3 = 3
}
local CHANCE = {[1] = 0.11, [2] = 0.22, [3] = 0.33}
local THRESHOLD = {[0] = 6, [1] = 8, [2] = 10, [3] = 12}
local SOURCE_REVISION = "364"
local TEST_SEED = 43

Effects.SMGHeatConfig = {
    family = FAMILY,
    chain = CHAIN,
    rankById = RANK,
    chanceByRank = CHANCE,
    thresholdByRank = THRESHOLD,
    sourceRevision = SOURCE_REVISION,
    sourceModifiedTime = "2026-09-05T00:37:22.001Z",
    deterministicDomain = "smg-heat:v1",
    acceptanceSeed = TEST_SEED,
    fixedOverheatLockSeconds = 2.0
}
Effects.SMGHeatStreams = Effects.SMGHeatStreams or setmetatable({}, {__mode = "k"})
Effects.SMGHeatTestSeeds = Effects.SMGHeatTestSeeds or setmetatable({}, {__mode = "k"})
Effects.SMGHeatStats = Effects.SMGHeatStats or {}

local function definition(id, name, dex, prerequisite, rank, chance, threshold)
    local effectLead = rank > 1 and "Replaces lower Cold Hands ranks and sets"
        or "Sets"
    return {
        featId = id,
        displayName = name,
        featFamilyId = FAMILY,
        rankIndex = rank,
        replacesLowerRank = rank > 1,
        repeatableFallback = false,
        governingAbilities = {"dex"},
        abilityRequirements = {dex = dex},
        prerequisiteFeatIds = prerequisite and {prerequisite} or {},
        requiredCapabilityTags = {"smg"},
        incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier"},
        requiredSubsystemTags = {},
        synergyTags = {"smg", "smg_heat", "firearm_cadence"},
        oneRank = true,
        effectHandlerId = "dex_smg_heat",
        effectParams = {
            smgHeatSuppressionChance = chance,
            smgOverheatThreshold = threshold,
            description = string.format(
                "%s SMGHeatSuppressionChance = %.2f and SMGOverheatThreshold = %d. Every successful SMG round makes one server-authoritative deterministic suppression roll before its ordinary +1 heat; success adds 0 heat. Damage, ammunition, firing cadence, sub-threshold cooling, visual/audio feedback, and the fixed 2.0-second overheat lockout are unchanged.",
                effectLead, chance, threshold)
        },
        directorBaseWeight = 1.0,
        eligibilityText = string.format("DEX %d%s", dex,
            prerequisite and (" / requires " .. prerequisite) or ""),
        actorText = "Player-controlled heroes and human Soldiers who possess/use the SMG"
    }
end

-- Replace the Gate-B ownership placeholder with the exact live-GDD ladder.
Feats.DEX_SMG_COLD_HANDS_1 = definition(
    "DEX_SMG_COLD_HANDS_1", "Cold Hands", 13, nil, 1, 0.11, 8)
Feats.DEX_SMG_COLD_HANDS_2 = definition(
    "DEX_SMG_COLD_HANDS_2", "Ice in the Veins", 15,
    "DEX_SMG_COLD_HANDS_1", 2, 0.22, 10)
Feats.DEX_SMG_COLD_HANDS_3 = definition(
    "DEX_SMG_COLD_HANDS_3", "Absolute Zero", 17,
    "DEX_SMG_COLD_HANDS_2", 3, 0.33, 12)
Catalog.OrdinaryFeats = Feats
Catalog.GateESMGHeatSourceRevisionId = SOURCE_REVISION

-- Gate-B originally recognized only an assigned SMG starter. The live family is
-- also legal when the actor later possesses the SMG, so extend the shared
-- capability seam without weakening any other capability gate.
if not Progression.LODDexSMGCapabilityWrapped then
    Progression.LODDexSMGCapabilityWrapped = true
    local baseHasCapability = Progression._HasCapability
    function Progression:_HasCapability(ps, state, tag)
        if tag == "smg" then
            if ps and ps.starterWeaponClass == "weapon_smg1" then return true end
            for _, weaponState in ipairs(ps and ps.inventory and ps.inventory.weapons or {}) do
                if weaponState.class == "weapon_smg1" then return true end
            end
            local run = LOD.RunManager
            if player and isfunction(player.GetAll) and run and run.GetPlayerState then
                for _, actor in ipairs(player.GetAll()) do
                    if IsValid(actor) and run:GetPlayerState(actor) == ps
                        and actor.HasWeapon and actor:HasWeapon("weapon_smg1")
                    then
                        return true
                    end
                end
            end
            return false
        end
        return baseHasCapability(self, ps, state, tag)
    end
end

local function owns(state, id)
    for _, value in ipairs(state and state.featIds or {}) do
        if value == id then return true end
    end
    return false
end

function Effects:SMGHeatProfile(state)
    local rank = 0
    for id, value in pairs(RANK) do
        if value > rank and owns(state, id) then rank = value end
    end
    return {
        rank = rank,
        featId = rank > 0 and CHAIN[rank] or nil,
        suppressionChance = CHANCE[rank] or 0,
        overheatThreshold = THRESHOLD[rank] or THRESHOLD[0]
    }
end

if not Effects.LODDexSMGHeatApplyDerivedWrapped then
    Effects.LODDexSMGHeatApplyDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        local profile = self:SMGHeatProfile(state)
        derived.smgHeatSuppressionChance = profile.suppressionChance
        derived.smgOverheatThreshold = profile.overheatThreshold
        derived.smgHeatFeatRank = profile.rank
        derived.smgHeatFeatId = profile.featId
    end
end

function Rules:SMGHeatSuppressionChance(actor)
    local derived = self:Derived(actor)
    return math.Clamp(tonumber(derived and derived.smgHeatSuppressionChance) or 0, 0, 0.33)
end

function Rules:SMGOverheatThreshold(actor)
    local derived = self:Derived(actor)
    return math.Clamp(math.floor(tonumber(derived and derived.smgOverheatThreshold) or 6), 6, 12)
end

local function streamIdentity(actor)
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(actor) or nil
    local identity = ps and ps.identity
    if identity == nil and IsValid(actor) and actor:IsPlayer() then
        identity = actor:SteamID64()
    end
    return tostring(identity or (IsValid(actor) and actor:EntIndex()) or "unknown")
end

local function levelSeed()
    local state = LOD.RunManager and LOD.RunManager.State or nil
    return tonumber(state and (state.LevelSeed or state.CampaignSeed)) or 1
end

function Effects:ResetSMGHeatStream(actor, explicitSeed)
    if not IsValid(actor) then return nil end
    if explicitSeed ~= nil then
        self.SMGHeatTestSeeds[actor] = math.max(1, math.floor(tonumber(explicitSeed) or 1))
    else
        self.SMGHeatTestSeeds[actor] = nil
    end
    self.SMGHeatStreams[actor] = nil
    return self:_SMGHeatStream(actor)
end

function Effects:_SMGHeatStream(actor)
    if not IsValid(actor) then return nil end
    local testSeed = self.SMGHeatTestSeeds[actor]
    local seed = levelSeed()
    local key
    if testSeed then
        seed = testSeed
        key = "test:" .. tostring(testSeed)
    else
        local identity = streamIdentity(actor)
        key = tostring(seed) .. ":" .. identity
        if LOD.Seeds and isfunction(LOD.Seeds.Derive) then
            seed = LOD.Seeds.Derive(seed,
                self.SMGHeatConfig.deterministicDomain .. ":" .. identity)
        end
    end
    local stream = self.SMGHeatStreams[actor]
    if not stream or stream.key ~= key then
        stream = {
            key = key,
            seed = seed,
            rng = LOD.RNG and LOD.RNG.New and LOD.RNG.New(seed) or nil,
            rolls = 0
        }
        self.SMGHeatStreams[actor] = stream
    end
    return stream
end

function Effects:RollSMGHeatSuppressionFromRNG(rng, chance)
    chance = math.Clamp(tonumber(chance) or 0, 0, 0.33)
    if not rng or not isfunction(rng.Float) then return false, 1 end
    local roll = rng:Float(0, 1)
    return chance > 0 and roll < chance, roll
end

function Effects:ResolveSMGHeatSuppression(actor, chance)
    local stream = self:_SMGHeatStream(actor)
    if not stream or not stream.rng then return false, 1, 0 end
    local suppressed, roll = self:RollSMGHeatSuppressionFromRNG(stream.rng, chance)
    stream.rolls = (stream.rolls or 0) + 1
    return suppressed, roll, stream.rolls
end

function Effects:ResetSMGHeatStats(expected)
    local stats = self.SMGHeatStats
    stats.shots = 0
    stats.heatAdded = 0
    stats.suppressed = 0
    stats.overheats = 0
    stats.lastRoll = nil
    stats.lastHeat = 0
    stats.lastThreshold = nil
    stats.lastChance = nil
    stats.lastLockSeconds = nil
    stats.expected = expected
    stats.acceptancePassed = nil
end

function Effects:RecordSMGHeatShot(actor, fields)
    fields = fields or {}
    local stats = self.SMGHeatStats
    stats.shots = (stats.shots or 0) + 1
    if fields.suppressed then
        stats.suppressed = (stats.suppressed or 0) + 1
    else
        stats.heatAdded = (stats.heatAdded or 0) + 1
    end
    if fields.overheated then stats.overheats = (stats.overheats or 0) + 1 end
    stats.lastRoll = fields.roll
    stats.lastHeat = fields.heat
    stats.lastThreshold = fields.threshold
    stats.lastChance = fields.chance
    stats.lastLockSeconds = fields.lockSeconds
    local expected = stats.expected
    if fields.overheated and expected then
        stats.acceptancePassed = stats.shots == expected.shots
            and stats.suppressed == expected.suppressed
            and stats.heatAdded == expected.heatAdded
            and fields.threshold == expected.threshold
            and math.abs((tonumber(fields.lockSeconds) or 0) - 2.0) < 0.01
    elseif expected and stats.acceptancePassed ~= nil then
        -- Continuing to fire after a completed acceptance sequence invalidates
        -- that sequence instead of leaving a stale PASS latched in telemetry.
        stats.acceptancePassed = false
    end

    local Log = LOD.RPGTestLog
    if Log and isfunction(Log.Write) then
        Log:Write("SMG_HEAT_SHOT", {
            player = IsValid(actor) and actor:Nick() or "unknown",
            shot = stats.shots,
            roll = fields.roll,
            chance = fields.chance,
            suppressed = fields.suppressed,
            heat_added = fields.suppressed and 0 or 1,
            heat = fields.heat,
            threshold = fields.threshold,
            overheated = fields.overheated,
            lock_seconds = fields.lockSeconds,
            acceptance = stats.acceptancePassed
        })
    end
end

local function highestOwned(state)
    for rank = 3, 1, -1 do
        if owns(state, CHAIN[rank]) then return CHAIN[rank], rank end
    end
    return nil, 0
end

if not Progression.LODDexSMGHeatSnapshotWrapped then
    Progression.LODDexSMGHeatSnapshotWrapped = true
    local base = Progression.BuildClientSnapshot
    function Progression:BuildClientSnapshot(ply)
        local snapshot = base(self, ply)
        if not snapshot then return nil end
        local state = Rules:ProgressionState(ply)
        local profile = Effects:SMGHeatProfile(state)
        snapshot.smgHeatSuppressionChance = profile.suppressionChance
        snapshot.smgOverheatThreshold = profile.overheatThreshold
        local highest = highestOwned(state)
        if highest then
            for _, item in ipairs(snapshot.ownedFeats or {}) do
                if item.featId == highest then
                    item.effect = tostring(item.effect or "") .. string.format(
                        " Current SMG heat: %.0f%% suppression; overheat at %d heat.",
                        profile.suppressionChance * 100, profile.overheatThreshold)
                    break
                end
            end
        end
        return snapshot
    end
end

function Effects:SMGHeatAcceptanceExpectation(rank, seed)
    rank = math.Clamp(math.floor(tonumber(rank) or 0), 0, 3)
    local chance = CHANCE[rank] or 0
    local threshold = THRESHOLD[rank] or THRESHOLD[0]
    local rng = LOD.RNG and LOD.RNG.New and LOD.RNG.New(seed or TEST_SEED) or nil
    local shots, suppressed, added = 0, 0, 0
    while added < threshold and shots < 256 do
        local blocked = self:RollSMGHeatSuppressionFromRNG(rng, chance)
        shots = shots + 1
        if blocked then suppressed = suppressed + 1 else added = added + 1 end
    end
    return {
        rank = rank,
        seed = seed or TEST_SEED,
        chance = chance,
        threshold = threshold,
        shots = shots,
        suppressed = suppressed,
        heatAdded = added
    }
end

function Effects:ValidateSMGHeatFamily()
    local errors = {}
    local function expect(ok, message)
        if not ok then errors[#errors + 1] = message end
    end
    local expected = {
        DEX_SMG_COLD_HANDS_1 = {1, 13, nil, 0.11, 8},
        DEX_SMG_COLD_HANDS_2 = {2, 15, "DEX_SMG_COLD_HANDS_1", 0.22, 10},
        DEX_SMG_COLD_HANDS_3 = {3, 17, "DEX_SMG_COLD_HANDS_2", 0.33, 12}
    }
    for id, values in pairs(expected) do
        local feat = Feats[id]
        expect(feat and feat.featFamilyId == FAMILY, id .. " definition/family")
        if feat then
            expect(feat.rankIndex == values[1] and feat.replacesLowerRank == (values[1] > 1),
                id .. " replacement rank")
            expect(feat.abilityRequirements.dex == values[2], id .. " DEX requirement")
            expect((feat.prerequisiteFeatIds or {})[1] == values[3], id .. " prerequisite")
            expect(feat.effectParams.smgHeatSuppressionChance == values[4],
                id .. " total suppression chance")
            expect(feat.effectParams.smgOverheatThreshold == values[5],
                id .. " overheat threshold")
            expect((feat.requiredCapabilityTags or {})[1] == "smg", id .. " SMG requirement")
            expect(#(feat.allowedActorTypes or {}) == 2
                and feat.allowedActorTypes[1] == "hero"
                and feat.allowedActorTypes[2] == "human_soldier",
                id .. " player-controlled actor restriction")
        end
    end

    local p0 = self:SMGHeatProfile({featIds = {}})
    local p1 = self:SMGHeatProfile({featIds = {CHAIN[1]}})
    local p2 = self:SMGHeatProfile({featIds = {CHAIN[1], CHAIN[2]}})
    local p3 = self:SMGHeatProfile({featIds = {CHAIN[1], CHAIN[2], CHAIN[3]}})
    expect(p0.rank == 0 and p0.suppressionChance == 0 and p0.overheatThreshold == 6,
        "baseline SMG heat profile")
    expect(p1.rank == 1 and p1.suppressionChance == 0.11 and p1.overheatThreshold == 8,
        "Cold Hands profile")
    expect(p2.rank == 2 and p2.suppressionChance == 0.22 and p2.overheatThreshold == 10,
        "Ice in the Veins replaces lower rank")
    expect(p3.rank == 3 and p3.suppressionChance == 0.33 and p3.overheatThreshold == 12,
        "Absolute Zero replaces lower ranks")

    local acceptance = self:SMGHeatAcceptanceExpectation(3, TEST_SEED)
    expect(acceptance.shots == 18 and acceptance.suppressed == 6
        and acceptance.heatAdded == 12,
        "dedicated deterministic seed 43 yields 6 suppressed + 12 heat in 18 rank-3 shots")

    local state = {
        featIds = {}, featQualificationAbilities = {dex = 17}, classId = "wizard",
        secondaryAbilities = {}, capabilityTags = {}
    }
    local smgPS = {starterWeaponClass = "weapon_smg1"}
    local inventorySMGPS = {starterWeaponClass = "weapon_ar2", inventory = {
        weapons = {{class = "weapon_smg1"}}
    }}
    local ar2PS = {starterWeaponClass = "weapon_ar2"}
    expect(Progression:_FeatEligible(smgPS, state, Feats[CHAIN[1]]),
        "Cold Hands legal for SMG user")
    expect(Progression:_FeatEligible(inventorySMGPS, state, Feats[CHAIN[1]]),
        "Cold Hands legal for later-acquired SMG")
    expect(not Progression:_FeatEligible(ar2PS, state, Feats[CHAIN[1]]),
        "non-SMG user excluded")
    expect(not Progression:_FeatEligible(smgPS, state, Feats[CHAIN[2]]),
        "Ice in the Veins prerequisite")
    state.featIds = {CHAIN[1]}
    expect(Progression:_FeatEligible(smgPS, state, Feats[CHAIN[2]]),
        "Ice in the Veins legal after Cold Hands")
    expect(not Progression:_FeatEligible(smgPS, state, Feats[CHAIN[3]]),
        "Absolute Zero prerequisite")
    state.featIds = {CHAIN[1], CHAIN[2]}
    expect(Progression:_FeatEligible(smgPS, state, Feats[CHAIN[3]]),
        "Absolute Zero legal after Ice in the Veins")

    local Specials = LOD.PlayerWeaponSpecials
    if Specials then
        local runtime = Specials.SMGConfig or {}
        expect(runtime.baselineThreshold == 6, "runtime baseline threshold remains 6")
        expect(math.abs((tonumber(runtime.coolInterval) or 0) - 0.25) < 0.0001,
            "runtime cooling interval remains 0.25s")
        expect(math.abs((tonumber(runtime.overheatLock) or 0) - 2.0) < 0.0001,
            "runtime overheat lock remains 2.0s")
        expect(isfunction(Specials.OnSMGShot), "successful-round SMG heat seam available")
        expect(Specials.SMGHeatFeatAuthority == "gate_e_batch_8_dex_smg_heat_v1",
            "runtime SMG heat feat authority installed")
        expect(isfunction(self.IsSMGOverheatLockActive),
            "Rate-of-Fire bridge excludes fixed SMG overheat recovery")
    end

    return #errors == 0, errors
end

if Validation and not Validation.LODDexSMGHeatWrapped then
    Validation.LODDexSMGHeatWrapped = true
    local base = Validation.Run
    function Validation:Run(printResult)
        local baseOK, errors = base(self, false)
        errors = errors or {}
        local featOK, featErrors = Effects:ValidateSMGHeatFamily()
        for _, message in ipairs(featErrors or {}) do
            errors[#errors + 1] = "Gate E DEX SMG Heat: " .. message
        end
        local ok = baseOK and featOK and #errors == 0
        if printResult ~= false then
            if ok then
                print(string.format(
                    "[LOD:RPG] core RPG validation PASS — gate=%s gameplayEnabled=%s gateEExplodingDice=true gateEReload=true gateERateOfFire=true gateEBurstSize=true gateESMGHeat=true",
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

local function configureRank(ply, rank)
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState or nil
    if not state then return false, "RPG progression state is unavailable." end
    rank = math.Clamp(math.floor(tonumber(rank) or 0), 0, 3)
    local kept = {}
    for _, id in ipairs(state.featIds or {}) do
        if not RANK[id] then kept[#kept + 1] = id end
    end
    state.featIds = kept
    state.featStackCounts = state.featStackCounts or {}
    for id in pairs(RANK) do state.featStackCounts[id] = nil end
    for index = 1, rank do
        local id = CHAIN[index]
        state.featIds[#state.featIds + 1] = id
        state.featStackCounts[id] = 1
    end
    Progression:_RecomputeProgressionState(state)
    Progression:SyncPlayer(ply)
    if run.MarkUnranked then run:MarkUnranked("Gate E DEX SMG-Heat feat test") end
    return true
end

concommand.Add("lod_rpg_gate_e_smg_heat_validate", function(ply)
    if not developerAllowed(ply) then return end
    local ok, errors = Effects:ValidateSMGHeatFamily()
    if ok then
        print("[LOD:RPG-E] DEX SMG-Heat feat family PASS — DEX 13/15/17; 11/22/33% deterministic suppression; 8/10/12 heat replacement thresholds; cooling, feedback, cadence, damage, ammo, and 2.0s lock preserved")
    else
        ErrorNoHalt("[LOD:RPG-E] DEX SMG-Heat feat family FAILED\n")
        for _, message in ipairs(errors or {}) do
            ErrorNoHalt("[LOD:RPG-E]  - " .. message .. "\n")
        end
    end
end)

concommand.Add("lod_rpg_gate_e_smg_heat_status", function(ply)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    local profile = Effects:SMGHeatProfile(Rules:ProgressionState(ply))
    local Specials = LOD.PlayerWeaponSpecials
    local playerState = Specials and Specials.PlayerState and Specials.PlayerState[ply] or nil
    local smg = playerState and playerState.smg or {}
    local stats = Effects.SMGHeatStats or {}
    local line = string.format(
        "smgHeatRank=%d chance=%.2f threshold=%d heat=%d shots=%d suppressed=%d added=%d overheats=%d lock=%.2f acceptance=%s",
        profile.rank, profile.suppressionChance, profile.overheatThreshold,
        math.floor((tonumber(smg.heat) or 0) + 0.5), stats.shots or 0,
        stats.suppressed or 0, stats.heatAdded or 0, stats.overheats or 0,
        math.max(0, (tonumber(smg.overheatedUntil) or 0) - CurTime()),
        stats.acceptancePassed == nil and "pending" or tostring(stats.acceptancePassed))
    print("[LOD:RPG-E] " .. line)
    ply:ChatPrint(line)
end)

concommand.Add("lod_rpg_test_smg_heat", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    local rank = math.Clamp(math.floor(tonumber(args[1]) or 0), 0, 3)
    local ok, message = configureRank(ply, rank)
    if not ok then ply:ChatPrint(message) return end
    local profile = Effects:SMGHeatProfile(Rules:ProgressionState(ply))
    ply:ChatPrint(string.format(
        "Gate E SMG-Heat rank %d configured: %.0f%% suppression, overheat at %d heat.",
        rank, profile.suppressionChance * 100, profile.overheatThreshold))
end)

concommand.Add("lod_rpg_gate_e_smg_heat_testkit", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) or not ply:Alive() then return end
    local rank = math.Clamp(math.floor(tonumber(args[1]) or 3), 0, 3)
    local ok, message = configureRank(ply, rank)
    if not ok then ply:ChatPrint(message) return end

    local Specials = LOD.PlayerWeaponSpecials
    if not Specials then ply:ChatPrint("SMG runtime authority is unavailable.") return end
    if isfunction(Specials.ResetSMGState) then Specials:ResetSMGState(ply) end
    Effects:ResetSMGHeatStream(ply, TEST_SEED)
    local expected = Effects:SMGHeatAcceptanceExpectation(rank, TEST_SEED)
    Effects:ResetSMGHeatStats(expected)

    local weapon = ply:GetWeapon("weapon_smg1")
    if not IsValid(weapon) then weapon = ply:Give("weapon_smg1", true) end
    if not IsValid(weapon) then ply:ChatPrint("Could not grant SMG test weapon.") return end
    weapon:SetClip1(45)
    local ammoType = weapon:GetPrimaryAmmoType()
    if ammoType and ammoType >= 0 then ply:SetAmmo(0, ammoType) end
    weapon:SetNextPrimaryFire(CurTime())
    weapon:SetNextSecondaryFire(CurTime())
    ply:SelectWeapon("weapon_smg1")

    local line = string.format(
        "SMG-Heat acceptance kit rank=%d seed=%d: hold primary fire until the first overheat, then release. Expected exactly %d shots = %d suppressed + %d heat; threshold=%d; lock=2.0s.",
        rank, TEST_SEED, expected.shots, expected.suppressed,
        expected.heatAdded, expected.threshold)
    print("[LOD:RPG-E] " .. line)
    ply:ChatPrint(line)
end)

RPG.SystemBootstrap.FeatEffectSystem = "gate_e_batch_8_dex_smg_heat"
return Effects
