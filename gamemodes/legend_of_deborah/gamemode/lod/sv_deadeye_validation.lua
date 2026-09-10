if not LOD or not LOD.RPG or not LOD.RPGAbilityRules then return end

local RPG = LOD.RPG
local Catalog = RPG.IdentityCatalog
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects = RPG.FeatEffectSystem
local Rules = LOD.RPGAbilityRules
local Progression = LOD.CharacterProgressionSystem
local Aim = LOD.UniversalAim
if not Feats or not Effects or not Rules or not Progression or not Aim then return end

local DEADEYE_ID = "DEX_MAGNUM_DEADEYE"
local WEAPON_CLASSES = {
    "weapon_lod_crowbar",
    "weapon_pistol",
    "weapon_357",
    "weapon_smg1",
    "weapon_shotgun",
    "weapon_ar2",
    "weapon_frag"
}

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    return cv and cv:GetBool() and (not IsValid(ply) or ply:IsAdmin())
end

local function owns(state, featId)
    for _, id in ipairs(state and state.featIds or {}) do
        if id == featId then return true end
    end
    return false
end

local function validateDeadeyeDefinition()
    local errors = {}
    local function expect(condition, message)
        if not condition then errors[#errors + 1] = message end
    end

    local feat = Feats[DEADEYE_ID]
    expect(feat ~= nil, "missing DEX_MAGNUM_DEADEYE")
    if feat then
        expect(feat.featId == DEADEYE_ID, "Deadeye feat ID")
        expect((feat.governingAbilities or {})[1] == "dex", "Deadeye governing ability")
        expect((feat.abilityRequirements or {}).dex == 15, "Deadeye DEX requirement")
        expect(#(feat.prerequisiteFeatIds or {}) == 0, "Deadeye feat prerequisite")
        expect(#(feat.requiredCapabilityTags or {}) == 0, "Deadeye capability prerequisite")
    end

    local baseline = {featIds = {}}
    local deadeye = {featIds = {DEADEYE_ID}}
    expect(math.abs((Rules:AimHoldSeconds(baseline) or 0) - 0.50) < 0.0001,
        "baseline Aim hold")
    expect(math.abs((Rules:AimHoldSeconds(deadeye) or 0) - 0.50) < 0.0001,
        "Deadeye Aim hold")
    expect(math.abs((Rules:MagnumAimHoldSeconds(baseline) or 0) - 0.50) < 0.0001,
        "baseline Magnum compatibility hold")
    expect(math.abs((Rules:MagnumAimHoldSeconds(deadeye) or 0) - 0.50) < 0.0001,
        "Deadeye Magnum compatibility hold")

    expect(Aim:CanAimClass(baseline, "weapon_pistol") == false,
        "baseline Pistol cannot Aim")
    expect(Aim:CanAimClass(baseline, "weapon_357") == true,
        "baseline Magnum can Aim")
    expect(Aim:MultiplierForClass(baseline, "weapon_357") == 2,
        "baseline Magnum multiplier")

    local expected = {
        weapon_lod_crowbar = 2,
        weapon_pistol = 2,
        weapon_357 = 3,
        weapon_smg1 = 2,
        weapon_shotgun = 2,
        weapon_ar2 = 2,
        weapon_frag = 2
    }
    for weaponClass, multiplier in pairs(expected) do
        expect(Aim:CanAimClass(deadeye, weaponClass) == true,
            "Deadeye cannot Aim " .. weaponClass)
        expect(Aim:MultiplierForClass(deadeye, weaponClass) == multiplier,
            "Deadeye multiplier " .. weaponClass)
        expect(Aim:MultiplierForClass(deadeye, weaponClass) ~= 4,
            "Deadeye x4 prohibited " .. weaponClass)
    end

    return #errors == 0, errors
end

function Effects:ValidateSingletonFamilies()
    local errors = {}
    local function expect(condition, message)
        if not condition then errors[#errors + 1] = message end
    end

    local expectedDefinitions = {
        DEX_SPRING_HEEL = {"dex", 13, nil, "spring_heel"},
        DEX_MAGNUM_DEADEYE = {"dex", 15, nil, "magnum_deadeye"},
        STR_MELEE_REACH = {"str", 15, "crowbar", "melee_reach"},
        CON_RUSSIAN_ASSET = {"int", 13, "tetris", "russian_asset"}
    }
    for id, values in pairs(expectedDefinitions) do
        local feat = Feats[id]
        expect(feat ~= nil, "missing " .. id)
        if feat then
            expect((feat.governingAbilities or {})[1] == values[1], id .. " governing ability")
            expect((feat.abilityRequirements or {})[values[1]] == values[2], id .. " requirement")
            expect((feat.requiredCapabilityTags or {})[1] == values[3], id .. " capability")
            expect(feat.effectHandlerId == values[4], id .. " handler")
        end
    end

    local baseline = self:SingletonProfile({featIds = {}})
    local all = self:SingletonProfile({featIds = {
        "DEX_SPRING_HEEL", DEADEYE_ID, "STR_MELEE_REACH", "CON_RUSSIAN_ASSET"
    }})
    expect(baseline.meleeReachMultiplier == 1, "baseline melee reach")
    expect(all.meleeReachMultiplier == 1.25
        and self.SingletonConfig.baseMeleeReach * all.meleeReachMultiplier == 120,
        "Long Reach trace distance")
    expect(baseline.jumpHeightMultiplier == 1 and all.jumpHeightMultiplier == 2,
        "Spring Heel height multiplier")
    expect(math.abs(all.jumpImpulseMultiplier * all.jumpImpulseMultiplier - 2) < 0.00001,
        "Spring Heel impulse produces 2x ballistic height")
    expect(baseline.tetrisOverfillMultiplier == 1
        and baseline.deathTetrisMaxSeconds == 60, "baseline Tetris profile")
    expect(all.tetrisOverfillMultiplier == 2 and all.deathTetrisMaxSeconds == 120,
        "Russian Asset Tetris profile")
    expect(baseline.aimHoldSeconds == 0.50 and all.aimHoldSeconds == 0.50,
        "Deadeye does not shorten Aim")
    expect(baseline.magnumAimHoldSeconds == 0.50 and all.magnumAimHoldSeconds == 0.50,
        "Magnum Aim compatibility hold")

    local deadeyeState = {
        featIds = {}, featQualificationAbilities = {dex = 15},
        classId = "rogue", secondaryAbilities = {}, capabilityTags = {}
    }
    local magnumPS = {inventory = {weapons = {{class = "weapon_357"}}}}
    local pistolPS = {inventory = {weapons = {{class = "weapon_pistol"}}}}
    expect(Progression:_FeatEligible(magnumPS, deadeyeState, Feats[DEADEYE_ID]),
        "Deadeye legal with .357 access")
    expect(Progression:_FeatEligible(pistolPS, deadeyeState, Feats[DEADEYE_ID]),
        "Deadeye legal without .357 access")

    local deadeyeOK, deadeyeErrors = validateDeadeyeDefinition()
    expect(deadeyeOK, "Deadeye universal Aim definition")
    for _, message in ipairs(deadeyeErrors or {}) do
        errors[#errors + 1] = "Deadeye: " .. message
    end

    local tetris = LOD.Tetris
    if tetris and tetris.RewardForLines then
        local rewards = {10, 30, 50, 80}
        for lines, reward in ipairs(rewards) do
            expect(self:TetrisOverfillReward(lines, {featIds = {}}) == reward,
                "baseline Tetris reward " .. lines)
            expect(self:TetrisOverfillReward(lines,
                {featIds = {"CON_RUSSIAN_ASSET"}}) == reward * 2,
                "Russian Asset Tetris reward " .. lines)
        end
    end

    return #errors == 0, errors
end

concommand.Add("lod_deadeye_aim_validate", function(ply)
    if not developerAllowed(ply) then return end
    local ok, errors = validateDeadeyeDefinition()
    if not ok then
        ErrorNoHalt("[LOD:DEADEYE] definition=FAIL\n")
        for _, message in ipairs(errors or {}) do
            ErrorNoHalt("[LOD:DEADEYE]  - " .. message .. "\n")
        end
        return
    end
    print("[LOD:DEADEYE] definition=PASS requirement=DEX15 hold=0.50 ordinary=x2 magnum=x3 universal=true result=PASS")
end)

local function configureDeadeye(ply, enabled)
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState or nil
    if not state then return false, "RPG progression state is unavailable." end

    local kept = {}
    for _, id in ipairs(state.featIds or {}) do
        if id ~= DEADEYE_ID then kept[#kept + 1] = id end
    end
    state.featIds = kept
    state.featStackCounts = state.featStackCounts or {}
    state.featStackCounts[DEADEYE_ID] = nil
    if enabled then
        state.featIds[#state.featIds + 1] = DEADEYE_ID
        state.featStackCounts[DEADEYE_ID] = 1
    end

    Progression:_RecomputeProgressionState(state)
    Progression:SyncPlayer(ply)
    if run and run.MarkUnranked then run:MarkUnranked("Deadeye developer testkit") end
    Aim:ResetPlayer(ply)
    return true
end

concommand.Add("lod_deadeye_aim_testkit", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) or not ply:Alive() then return end
    local enabled = tonumber(args[1]) ~= 0
    local ok, message = configureDeadeye(ply, enabled)
    if not ok then
        ply:ChatPrint(message)
        return
    end

    for _, weaponClass in ipairs(WEAPON_CLASSES) do
        if not ply:HasWeapon(weaponClass) then ply:Give(weaponClass, true) end
    end
    ply:GiveAmmo(99, "Pistol")
    ply:GiveAmmo(99, "357")
    ply:GiveAmmo(99, "SMG1")
    ply:GiveAmmo(99, "Buckshot")
    ply:GiveAmmo(99, "AR2")
    ply:GiveAmmo(10, "Grenade")

    local magnum = LOD.MagnumSuperExplosive
    if magnum and magnum.Stats then
        magnum.Stats.aimLocks = 0
        magnum.Stats.aimShots = 0
        magnum.Stats.aimCancels = 0
        magnum.Stats.aimAttackInterruptions = 0
        magnum.Stats.lastAimMultiplier = nil
        magnum.Stats.lastAimWeaponClass = nil
        magnum.Stats.lastFragAimMultiplier = nil
    end

    local text = string.format(
        "Deadeye testkit %s: standard weapons granted; Aim requires 0.50s perfect stillness. Baseline Magnum=x2; Deadeye ordinary=x2, Magnum=x3.",
        enabled and "ON" or "OFF")
    print("[LOD:DEADEYE] " .. text)
    ply:ChatPrint(text)
end)

concommand.Add("lod_deadeye_aim_status", function(ply)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    local progressionState = Rules:ProgressionState(ply)
    local state = Aim.States and Aim.States[ply] or nil
    local weapon = ply:GetActiveWeapon()
    local weaponClass = IsValid(weapon) and weapon:GetClass() or "none"
    local aimable = Aim:CanAimClass(progressionState, weaponClass)
    local multiplier = state and state.armed
        and math.max(1, tonumber(state.multiplier) or 1) or 1
    local stats = LOD.MagnumSuperExplosive and LOD.MagnumSuperExplosive.Stats or {}

    local line = string.format(
        "deadeye=%s hold=%.2fs active=%s aimable=%s armed=%s multiplier=x%d locks=%d aimedShots=%d cancels=%d interruptions=%d lastWeapon=%s lastMultiplier=x%d frag=x%d",
        tostring(owns(progressionState, DEADEYE_ID)),
        Rules:AimHoldSeconds(ply),
        weaponClass,
        tostring(aimable),
        tostring(state and state.armed == true or false),
        multiplier,
        stats.aimLocks or 0,
        stats.aimShots or 0,
        stats.aimCancels or 0,
        stats.aimAttackInterruptions or 0,
        tostring(stats.lastAimWeaponClass or "none"),
        math.max(1, math.floor(tonumber(stats.lastAimMultiplier) or 1)),
        math.max(1, math.floor(tonumber(stats.lastFragAimMultiplier) or 1)))
    print("[LOD:DEADEYE] status: " .. line)
    ply:ChatPrint("[LOD:DEADEYE] " .. line)
end)
