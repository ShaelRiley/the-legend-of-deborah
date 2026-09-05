LOD = LOD or {}
local RPG = LOD.RPG
local Catalog = RPG and RPG.IdentityCatalog
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects = RPG and RPG.FeatEffectSystem
local Progression = LOD.CharacterProgressionSystem
local Rules = LOD.RPGAbilityRules
local Validation = LOD.RPGValidation
local Specials = LOD.PlayerWeaponSpecials
local Config = Effects and Effects.BurstSizeConfig
if not Feats or not Effects or not Progression or not Rules or not Config or not Specials then return end

local CHAIN = Config.chain
local RANK = Config.rankById

local function owns(state, id)
    for _, value in ipairs(state and state.featIds or {}) do
        if value == id then return true end
    end
    return false
end

local function highestOwned(state)
    for rank = 3, 1, -1 do
        if owns(state, CHAIN[rank]) then return CHAIN[rank], rank end
    end
    return nil, 0
end

if not Progression.LODDexBurstSizeSnapshotWrapped then
    Progression.LODDexBurstSizeSnapshotWrapped = true
    local base = Progression.BuildClientSnapshot
    function Progression:BuildClientSnapshot(ply)
        local snapshot = base(self, ply)
        if not snapshot then return nil end
        local ps = LOD.RunManager and LOD.RunManager:GetPlayerState(ply) or nil
        local state = ps and ps.progressionState or nil
        local derived = state and state.derivedStats or nil
        snapshot.burstBonusRounds = math.floor(tonumber(
            derived and (derived.burstBonusRounds or derived.burstSizeBonus)) or 0)
        snapshot.burstSizeBonus = snapshot.burstBonusRounds
        local highest = highestOwned(state)
        if highest and snapshot.burstBonusRounds > 0 then
            for _, item in ipairs(snapshot.ownedFeats or {}) do
                if item.featId == highest then
                    item.effect = tostring(item.effect or "") .. string.format(
                        " Current BurstBonusRounds: +%d (AR2 authored 3 -> %d projectiles; still exactly 1 AR2 ammo per trigger burst).",
                        snapshot.burstBonusRounds,
                        Config.ar2AuthoredBurstCount + snapshot.burstBonusRounds)
                    break
                end
            end
        end
        return snapshot
    end
end

function Effects:ValidateBurstSizeFamily()
    local errors = {}
    local function expect(ok, message)
        if not ok then errors[#errors + 1] = message end
    end
    local expected = {
        DEX_BURSTER_1 = {1, 13, nil, 1},
        DEX_BURSTER_2 = {2, 15, "DEX_BURSTER_1", 2},
        DEX_BURSTER_3 = {3, 17, "DEX_BURSTER_2", 3}
    }
    for id, values in pairs(expected) do
        local feat = Feats[id]
        expect(feat and feat.featFamilyId == Config.family, id .. " definition/family")
        if feat then
            expect(feat.rankIndex == values[1] and feat.replacesLowerRank == (values[1] > 1),
                id .. " replacement rank")
            expect(feat.abilityRequirements.dex == values[2], id .. " DEX requirement")
            expect((feat.prerequisiteFeatIds or {})[1] == values[3], id .. " prerequisite")
            expect(feat.effectParams.burstBonusRounds == values[4],
                id .. " total BurstBonusRounds")
            expect(feat.effectParams.burstSizeBonus == values[4],
                id .. " compatibility BurstSizeBonus")
            expect((feat.requiredCapabilityTags or {})[1] == "multi_fire_burst",
                id .. " multiFireBurst capability requirement")
        end
    end

    local p0 = self:BurstSizeProfile({featIds = {}})
    local p1 = self:BurstSizeProfile({featIds = {CHAIN[1]}})
    local p2 = self:BurstSizeProfile({featIds = {CHAIN[1], CHAIN[2]}})
    local p3 = self:BurstSizeProfile({featIds = {CHAIN[1], CHAIN[2], CHAIN[3]}})
    expect(p0.rank == 0 and p0.burstBonusRounds == 0, "baseline burst-size profile")
    expect(p1.rank == 1 and p1.burstBonusRounds == 1, "Extra Round profile")
    expect(p2.rank == 2 and p2.burstBonusRounds == 2,
        "Extended Volley replaces lower rank")
    expect(p3.rank == 3 and p3.burstBonusRounds == 3,
        "Full Barrage replaces lower ranks")

    expect(Rules:ResolveBurstCount(3, 0) == 3, "baseline AR2 remains three projectiles")
    expect(Rules:ResolveBurstCount(3, 1) == 4, "Extra Round makes AR2 four projectiles")
    expect(Rules:ResolveBurstCount(3, 2) == 5,
        "Extended Volley makes AR2 five projectiles")
    expect(Rules:ResolveBurstCount(3, 3) == 6,
        "Full Barrage makes AR2 six projectiles")
    expect(Rules:ResolveBurstCount(2, 3) == 5,
        "authored two-projectile burst receives +3 without ammo inference")

    local ar2Config = Specials.AR2Config or {}
    expect(ar2Config.baseBurstShots == 3, "AR2 authored base burst remains three")
    expect(ar2Config.ammoPerTriggerBurst == 1,
        "AR2 authored ammo cost is exactly one round per trigger burst")
    expect(ar2Config.multiFireBurst == true, "AR2 is explicitly multiFireBurst")
    expect(math.abs((tonumber(ar2Config.burstSpacing) or 0) - 0.09) < 0.0001,
        "AR2 authored between-shot spacing remains 0.09s")
    expect(math.abs((tonumber(ar2Config.telegraph) or 0) - 0.45) < 0.0001,
        "AR2 targeting telegraph remains 0.45s")

    expect(isfunction(self.BeginAR2RateOfFirePlan),
        "AR2 Rate-of-Fire composition bridge available")

    -- Magnum is loaded later in init.lua than this validator. When present, its
    -- pure authored-state classifier must expose only chamber 5/6 as Burster events.
    local Magnum = LOD.MagnumSuperExplosive
    if Magnum then
        if isfunction(self.InstallMagnumBurstSizeBridge) then
            self:InstallMagnumBurstSizeBridge()
        end
        expect(Magnum.LODBurstSizeIntegrationInstalled == true,
            "Magnum Burst-Size integration installed")
        expect(isfunction(Magnum.BursterAuthoredBurstCount),
            "Magnum authored burst classifier available")
        if isfunction(Magnum.BursterAuthoredBurstCount) then
            expect(Magnum:BursterAuthoredBurstCount(6, 1) == 2,
                "Magnum chamber 5 is authored two-projectile burst")
            expect(Magnum:BursterAuthoredBurstCount(6, 0) == 3,
                "Magnum chamber 6 is authored three-projectile burst")
            expect(Magnum:BursterAuthoredBurstCount(6, 2) == 1,
                "ordinary Magnum trigger remains single-fire")
        end
    end

    local state = {
        featIds = {}, featQualificationAbilities = {dex = 17}, classId = "wizard",
        secondaryAbilities = {}, capabilityTags = {}
    }
    local ps = {starterWeaponClass = "weapon_ar2"}
    expect(Progression:_FeatEligible(ps, state, Feats[CHAIN[1]]), "Extra Round legal for AR2")
    local magnumPS = {starterWeaponClass = "weapon_357"}
    expect(Progression:_FeatEligible(magnumPS, state, Feats[CHAIN[1]]),
        "Extra Round legal for authored Magnum burst family")
    local pistolPS = {starterWeaponClass = "weapon_pistol"}
    expect(not Progression:_FeatEligible(pistolPS, state, Feats[CHAIN[1]]),
        "single-fire starter does not satisfy multiFireBurst capability")
    expect(not Progression:_FeatEligible(ps, state, Feats[CHAIN[2]]),
        "Extended Volley prerequisite")
    state.featIds = {CHAIN[1]}
    expect(Progression:_FeatEligible(ps, state, Feats[CHAIN[2]]), "Extended Volley legal")
    expect(not Progression:_FeatEligible(ps, state, Feats[CHAIN[3]]),
        "Full Barrage prerequisite")
    state.featIds = {CHAIN[1], CHAIN[2]}
    expect(Progression:_FeatEligible(ps, state, Feats[CHAIN[3]]), "Full Barrage legal")

    return #errors == 0, errors
end

if Validation and not Validation.LODDexBurstSizeWrapped then
    Validation.LODDexBurstSizeWrapped = true
    local base = Validation.Run
    local function count(values)
        local n = 0
        for _ in pairs(values or {}) do n = n + 1 end
        return n
    end
    function Validation:Run(printResult)
        local baseOK, errors = base(self, false)
        errors = errors or {}
        local featOK, featErrors = Effects:ValidateBurstSizeFamily()
        for _, message in ipairs(featErrors or {}) do
            errors[#errors + 1] = "Gate E DEX Burst Size: " .. message
        end
        local ok = baseOK and featOK and #errors == 0
        if printResult ~= false then
            if ok then
                print(string.format(
                    "[LOD:RPG] core RPG validation PASS — gate=%s schemas=%d classes=%d abilities=%d featSlots=%d gameplayEnabled=%s gateEExplodingDice=true gateEReload=true gateERateOfFire=true gateEBurstSize=true",
                    tostring(RPG.ImplementationGate), count(RPG.Schema), count(RPG.Classes),
                    #RPG.Abilities, #RPG.OrdinaryFeatLevels, tostring(RPG.GameplayEnabled)))
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

concommand.Add("lod_rpg_gate_e_burst_size_validate", function(ply)
    if not developerAllowed(ply) then return end
    local ok, errors = Effects:ValidateBurstSizeFamily()
    if ok then
        print("[LOD:RPG-E] DEX Burst-Size feat family PASS — DEX 13/15/17; +1/+2/+3 replacement ladder; AR2 4/5/6 projectiles for exactly one ammo per trigger; Magnum authored bursts only")
    else
        ErrorNoHalt("[LOD:RPG-E] DEX Burst-Size feat family FAILED\n")
        for _, message in ipairs(errors or {}) do
            ErrorNoHalt("[LOD:RPG-E]  - " .. message .. "\n")
        end
    end
end)

concommand.Add("lod_rpg_gate_e_burst_size_status", function(ply)
    if not developerAllowed(ply) then return end
    if not IsValid(ply) then
        print("[LOD:RPG-E] Run this command from an attached player console.")
        return
    end
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState or nil
    local profile = Effects:BurstSizeProfile(state)
    local specialState = Specials.PlayerState and Specials.PlayerState[ply] or nil
    local ar2 = specialState and specialState.ar2 or nil
    local stats = Effects.BurstSizeStats or {}
    local last = stats.lastResult
    local lastText = last and string.format("%s %d/%d authored=%d complete=%s",
        tostring(last.weaponClass), tonumber(last.roundsResolved) or 0,
        tonumber(last.finalBurstCount) or 0,
        tonumber(last.authoredBurstCount) or 0,
        tostring(last.complete == true)) or "none"
    local weapon = ply:GetActiveWeapon()
    local clip = IsValid(weapon) and weapon:GetClass() == "weapon_ar2"
        and weapon:Clip1() or -1
    local line = string.format(
        "burstRank=%d bonus=+%d finalAR2=%d clip=%d active=%s current=%d/%d completed=%d aborted=%d last=%s",
        profile.rank or 0, profile.burstBonusRounds or 0,
        Config.ar2AuthoredBurstCount + (profile.burstBonusRounds or 0),
        clip,
        tostring(ar2 and ar2.active == true),
        ar2 and (ar2.shotsFired or 0) or 0,
        ar2 and (ar2.targetShots or 0) or 0,
        stats.completedBursts or 0, stats.abortedBursts or 0, lastText)
    print("[LOD:RPG-E] " .. line)
    ply:ChatPrint(line)
end)

concommand.Add("lod_rpg_test_burst_size", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    local run = LOD.RunManager
    local ps = run and run:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState or nil
    if not state then ply:ChatPrint("RPG progression state is unavailable.") return end

    local rank = math.Clamp(math.floor(tonumber(args[1]) or 1), 0, 3)
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
    if run.MarkUnranked then run:MarkUnranked("Gate E DEX Burst-Size feat test") end
    ply:ChatPrint(string.format(
        "Gate E burst-size rank %d configured (AR2: %d projectiles, exactly 1 AR2 ammo per trigger burst).",
        rank, Config.ar2AuthoredBurstCount + rank))
end)

concommand.Add("lod_rpg_gate_e_burst_size_testkit", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) or not ply:Alive() then return end
    local weapon = ply:GetWeapon("weapon_ar2")
    if not IsValid(weapon) then weapon = ply:Give("weapon_ar2", true) end
    if not IsValid(weapon) then
        ply:ChatPrint("Could not grant AR2 burst-size test weapon.")
        return
    end

    local requestedClip = math.floor(tonumber(args[1]) or 1)
    local maximum = weapon.GetMaxClip1 and weapon:GetMaxClip1() or 30
    if maximum <= 0 then maximum = 30 end
    requestedClip = math.Clamp(requestedClip, 0, maximum)
    weapon:SetClip1(requestedClip)
    local ammoType = weapon:GetPrimaryAmmoType()
    if ammoType and ammoType >= 0 then ply:SetAmmo(maximum * 3, ammoType) end
    ply:SelectWeapon("weapon_ar2")
    ply:ChatPrint(string.format(
        "Burst-size testkit ready: weapon_ar2 clip=%d. Clip 1 must resolve the entire 3/4/5/6-projectile burst and become 0; clip 0 must not begin a burst.",
        requestedClip))
end)

return Effects
