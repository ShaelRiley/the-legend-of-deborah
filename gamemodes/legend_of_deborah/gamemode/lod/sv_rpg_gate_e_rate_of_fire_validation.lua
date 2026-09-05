LOD = LOD or {}
local RPG = LOD.RPG
local Catalog = RPG and RPG.IdentityCatalog
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects = RPG and RPG.FeatEffectSystem
local Progression = LOD.CharacterProgressionSystem
local Rules = LOD.RPGAbilityRules
local Validation = LOD.RPGValidation
local Config = Effects and Effects.RateOfFireConfig
if not Feats or not Effects or not Progression or not Rules or not Config then return end

local CHAIN = Config.chain
local RANK = Config.rankById
local FIREARMS = Config.ordinaryFirearms
local MELEE = Config.ordinaryMelee or {}

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

if not Progression.LODDexRateOfFireSnapshotWrapped then
    Progression.LODDexRateOfFireSnapshotWrapped = true
    local base = Progression.BuildClientSnapshot
    function Progression:BuildClientSnapshot(ply)
        local snapshot = base(self, ply)
        if not snapshot then return nil end
        local ps = LOD.RunManager and LOD.RunManager:GetPlayerState(ply) or nil
        local state = ps and ps.progressionState or nil
        local derived = state and state.derivedStats or nil
        snapshot.rateOfFireMultiplier = tonumber(derived and derived.rateOfFireMultiplier) or 1
        local highest = highestOwned(state)
        if highest and snapshot.rateOfFireMultiplier > 1 then
            for _, item in ipairs(snapshot.ownedFeats or {}) do
                if item.featId == highest then
                    item.effect = tostring(item.effect or "") .. string.format(
                        " Current RateOfFireMultiplier: %.2f (authored attack intervals ÷ %.2f).",
                        snapshot.rateOfFireMultiplier, snapshot.rateOfFireMultiplier)
                    break
                end
            end
        end
        return snapshot
    end
end

function Effects:ValidateRateOfFireCadence()
    local errors = {}
    local function expect(ok, message)
        if not ok then errors[#errors + 1] = message end
    end
    local expected = {
        DEX_RATE_OF_FIRE_1 = {1, 13, nil, 1.10},
        DEX_RATE_OF_FIRE_2 = {2, 15, "DEX_RATE_OF_FIRE_1", 1.20},
        DEX_RATE_OF_FIRE_3 = {3, 17, "DEX_RATE_OF_FIRE_2", 1.30}
    }
    for id, values in pairs(expected) do
        local feat = Feats[id]
        expect(feat and feat.featFamilyId == Config.family, id .. " definition/family")
        if feat then
            expect(feat.rankIndex == values[1] and feat.replacesLowerRank == (values[1] > 1),
                id .. " replacement rank")
            expect(feat.abilityRequirements.dex == values[2], id .. " DEX requirement")
            expect((feat.prerequisiteFeatIds or {})[1] == values[3], id .. " prerequisite")
            expect(math.abs((feat.effectParams.rateOfFireMultiplier or 0) - values[4]) < 0.0001,
                id .. " multiplier")
        end
    end

    local p0 = self:RateOfFireProfile({featIds = {}})
    local p1 = self:RateOfFireProfile({featIds = {CHAIN[1]}})
    local p2 = self:RateOfFireProfile({featIds = {CHAIN[1], CHAIN[2]}})
    local p3 = self:RateOfFireProfile({featIds = {CHAIN[1], CHAIN[2], CHAIN[3]}})
    expect(p0.rank == 0 and p0.rateOfFireMultiplier == 1.0, "baseline attack-rate profile")
    expect(p1.rank == 1 and math.abs(p1.rateOfFireMultiplier - 1.10) < 0.0001,
        "Hair Trigger profile")
    expect(p2.rank == 2 and math.abs(p2.rateOfFireMultiplier - 1.20) < 0.0001,
        "Rapid Fire replaces lower rank")
    expect(p3.rank == 3 and math.abs(p3.rateOfFireMultiplier - 1.30) < 0.0001,
        "Lead Storm replaces lower ranks")

    local scaled, changed = Rules:ScaleAttackDeadline(100, 99, 101.3, 1.30)
    expect(changed and math.abs(scaled - 101.0) < 0.0001,
        "authored attack interval is divided by multiplier")
    local protected, protectedChanged = Rules:ScaleAttackDeadline(100, 100.9, 101.0, 1.30)
    expect(protectedChanged and math.abs(protected - 100.9) < 0.0001,
        "pre-existing attack lock remains absolute floor")
    local untouched, untouchedChanged = Rules:ScaleAttackDeadline(100, 101.1, 101.0, 1.30)
    expect(not untouchedChanged and math.abs(untouched - 101.0) < 0.0001,
        "non-attack/pre-existing deadline is untouched")

    expect(FIREARMS.weapon_pistol and FIREARMS.weapon_shotgun and FIREARMS.weapon_smg1
        and FIREARMS.weapon_ar2 and FIREARMS.weapon_357,
        "ordinary firearm attack-rate authority coverage")
    expect(not MELEE.weapon_lod_crowbar, "rate-of-fire family is firearm-only; Crowbar excluded")
    expect(not FIREARMS.weapon_frag and not MELEE.weapon_frag,
        "grenade/non-ordinary tools excluded")

    local state = {
        featIds = {}, featQualificationAbilities = {dex = 17}, classId = "wizard",
        secondaryAbilities = {}, capabilityTags = {}
    }
    local ps = {starterWeaponClass = "weapon_smg1"}
    expect(Progression:_FeatEligible(ps, state, Feats[CHAIN[1]]), "Hair Trigger legal")
    expect(not Progression:_FeatEligible(ps, state, Feats[CHAIN[2]]), "Rapid Fire prerequisite")
    state.featIds = {CHAIN[1]}
    expect(Progression:_FeatEligible(ps, state, Feats[CHAIN[2]]), "Rapid Fire legal")
    expect(not Progression:_FeatEligible(ps, state, Feats[CHAIN[3]]), "Lead Storm prerequisite")
    state.featIds = {CHAIN[1], CHAIN[2]}
    expect(Progression:_FeatEligible(ps, state, Feats[CHAIN[3]]), "Lead Storm legal")

    return #errors == 0, errors
end

if Validation and not Validation.LODDexRateOfFireWrapped then
    Validation.LODDexRateOfFireWrapped = true
    local base = Validation.Run
    local function count(values)
        local n = 0
        for _ in pairs(values or {}) do n = n + 1 end
        return n
    end
    function Validation:Run(printResult)
        local baseOK, errors = base(self, false)
        errors = errors or {}
        local featOK, featErrors = Effects:ValidateRateOfFireCadence()
        for _, message in ipairs(featErrors or {}) do
            errors[#errors + 1] = "Gate E DEX Rate-of-Fire: " .. message
        end
        local ok = baseOK and featOK and #errors == 0
        if printResult ~= false then
            if ok then
                print(string.format(
                    "[LOD:RPG] core RPG validation PASS — gate=%s schemas=%d classes=%d abilities=%d featSlots=%d gameplayEnabled=%s gateEExplodingDice=true gateEReload=true gateERateOfFire=true",
                    tostring(RPG.ImplementationGate), count(RPG.Schema), count(RPG.Classes),
                    #RPG.Abilities, #RPG.OrdinaryFeatLevels, tostring(RPG.GameplayEnabled)))
            else
                ErrorNoHalt("[LOD:RPG] core RPG validation FAILED (" .. #errors .. " error(s))\n")
                for _, message in ipairs(errors) do ErrorNoHalt("[LOD:RPG]  - " .. message .. "\n") end
            end
        end
        return ok, errors
    end
end

local function developerAllowed(ply)
    local cv = GetConVar("lod_developer_mode")
    return cv and cv:GetBool() and (not IsValid(ply) or ply:IsAdmin())
end

concommand.Add("lod_rpg_gate_e_rate_of_fire_validate", function(ply)
    if not developerAllowed(ply) then return end
    local ok, errors = Effects:ValidateRateOfFireCadence()
    if ok then
        print("[LOD:RPG-E] DEX Rate-of-Fire feat family PASS — 1.10/1.20/1.30 replacement ladder; firearm primary-attack interval division; authored exclusions preserved")
    else
        ErrorNoHalt("[LOD:RPG-E] DEX Rate-of-Fire feat family FAILED\n")
        for _, message in ipairs(errors or {}) do ErrorNoHalt("[LOD:RPG-E]  - " .. message .. "\n") end
    end
end)

concommand.Add("lod_rpg_gate_e_rate_of_fire_status", function(ply)
    if not developerAllowed(ply) then return end
    if not IsValid(ply) then
        print("[LOD:RPG-E] Run this command from an attached player console.")
        return
    end
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState or nil
    local profile = Effects:RateOfFireProfile(state)
    local weapon = ply:GetActiveWeapon()
    local class = IsValid(weapon) and weapon:GetClass() or "none"
    local session = Effects.AttackRateSessions and Effects.AttackRateSessions[ply] or nil
    local last = Effects.AttackRateStats and Effects.AttackRateStats.lastScale or nil
    local lastText = last and string.format("%s/%s %.3fs->%.3fs via %s",
        tostring(last.weaponClass), tostring(last.channel),
        tonumber(last.authoredSeconds) or 0, tonumber(last.scaledSeconds) or 0,
        tostring(last.confirmation or "unknown")) or "none"
    local line = string.format(
        "rateRank=%d multiplier=%.2f active=%s observing=%s scaledAttacks=%d last=%s",
        profile.rank or 0, Rules:RateOfFireMultiplier(ply), class, tostring(session ~= nil),
        Effects.AttackRateStats and Effects.AttackRateStats.attackIntervalsScaled or 0, lastText)
    print("[LOD:RPG-E] " .. line)
    ply:ChatPrint(line)
end)

concommand.Add("lod_rpg_test_rate_of_fire", function(ply, _, args)
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
    if run.MarkUnranked then run:MarkUnranked("Gate E DEX Rate-of-Fire feat test") end
    ply:ChatPrint(string.format(
        "Gate E rate-of-fire rank %d configured (0=1.00, 1=1.10, 2=1.20, 3=1.30 RateOfFireMultiplier).",
        rank))
end)

concommand.Add("lod_rpg_gate_e_rate_of_fire_testkit", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) or not ply:Alive() then return end
    local requested = string.lower(tostring(args[1] or "pistol"))
    local classes = {
        pistol = "weapon_pistol",
        shotgun = "weapon_shotgun",
        smg = "weapon_smg1",
        ar2 = "weapon_ar2",
        magnum = "weapon_357"
    }
    local class = classes[requested] or classes.pistol
    local weapon = ply:GetWeapon(class)
    if not IsValid(weapon) then weapon = ply:Give(class, true) end
    if not IsValid(weapon) then ply:ChatPrint("Could not grant rate-of-fire test weapon.") return end

    local maximum = weapon.GetMaxClip1 and weapon:GetMaxClip1() or -1
    if maximum and maximum > 0 then
        weapon:SetClip1(maximum)
        local ammoType = weapon:GetPrimaryAmmoType()
        if ammoType and ammoType >= 0 then ply:SetAmmo(maximum * 3, ammoType) end
    end
    ply:SelectWeapon(class)
    ply:ChatPrint(string.format(
        "Rate-of-fire testkit ready: %s. Fire several attacks at ranks 0-3; status reports multiplier and confirmed scaled attacks.",
        class))
end)

return Effects
