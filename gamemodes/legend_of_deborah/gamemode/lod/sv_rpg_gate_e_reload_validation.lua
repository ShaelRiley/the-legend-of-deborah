LOD = LOD or {}
local RPG = LOD.RPG
local Catalog = RPG and RPG.IdentityCatalog
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects = RPG and RPG.FeatEffectSystem
local Progression = LOD.CharacterProgressionSystem
local Rules = LOD.RPGAbilityRules
local Validation = LOD.RPGValidation
local Config = Effects and Effects.ReloadConfig
if not Feats or not Effects or not Progression or not Rules or not Config then return end

local CHAIN = Config.chain
local RANK = Config.rankById
local ORDINARY_RELOADABLE = Config.ordinaryReloadable

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

if not Progression.LODDexReloadSnapshotWrapped then
    Progression.LODDexReloadSnapshotWrapped = true
    local base = Progression.BuildClientSnapshot
    function Progression:BuildClientSnapshot(ply)
        local snapshot = base(self, ply)
        if not snapshot then return nil end
        local ps = LOD.RunManager and LOD.RunManager:GetPlayerState(ply) or nil
        local state = ps and ps.progressionState or nil
        local derived = state and state.derivedStats or nil
        snapshot.reloadTimeMultiplier = tonumber(derived and derived.reloadTimeMultiplier) or 1
        local highest = highestOwned(state)
        if highest and snapshot.reloadTimeMultiplier < 1 then
            for _, item in ipairs(snapshot.ownedFeats or {}) do
                if item.featId == highest then
                    item.effect = tostring(item.effect or "") .. string.format(
                        " Current ordinary reload-time multiplier: %.2f (%.0f%% of base reload time).",
                        snapshot.reloadTimeMultiplier, snapshot.reloadTimeMultiplier * 100)
                    break
                end
            end
        end
        return snapshot
    end
end

function Effects:ValidateReloadCadence()
    local errors = {}
    local function expect(ok, message)
        if not ok then errors[#errors + 1] = message end
    end
    local expected = {
        DEX_FAST_RELOAD = {1, 12, nil, 0.80},
        DEX_FAST_RELOAD_2 = {2, 16, "DEX_FAST_RELOAD", 0.60},
        DEX_FAST_RELOAD_3 = {3, 18, "DEX_FAST_RELOAD_2", 0.40}
    }
    for id, values in pairs(expected) do
        local feat = Feats[id]
        expect(feat and feat.featFamilyId == Config.family, id .. " definition/family")
        if feat then
            expect(feat.rankIndex == values[1] and feat.replacesLowerRank == (values[1] > 1),
                id .. " replacement rank")
            expect(feat.abilityRequirements.dex == values[2], id .. " DEX requirement")
            expect((feat.prerequisiteFeatIds or {})[1] == values[3], id .. " prerequisite")
            expect(math.abs((feat.effectParams.reloadTimeMultiplier or 0) - values[4]) < 0.0001,
                id .. " multiplier")
        end
    end

    local p0 = self:ReloadProfile({featIds = {}})
    local p1 = self:ReloadProfile({featIds = {CHAIN[1]}})
    local p2 = self:ReloadProfile({featIds = {CHAIN[1], CHAIN[2]}})
    local p3 = self:ReloadProfile({featIds = {CHAIN[1], CHAIN[2], CHAIN[3]}})
    expect(p0.rank == 0 and p0.reloadTimeMultiplier == 1.0, "baseline reload profile")
    expect(p1.rank == 1 and p1.reloadTimeMultiplier == 0.80, "Quick Reload profile")
    expect(p2.rank == 2 and p2.reloadTimeMultiplier == 0.60, "Lightning Reload replaces lower rank")
    expect(p3.rank == 3 and p3.reloadTimeMultiplier == 0.40, "Blink Reload replaces lower ranks")

    local scaled, changed = Rules:ScaleReloadDeadline(100, 99, 102, 0.80)
    expect(changed and math.abs(scaled - 101.6) < 0.0001, "ordinary reload deadline scaling")
    local protected, protectedChanged = Rules:ScaleReloadDeadline(100, 101.5, 102, 0.40)
    expect(protectedChanged and math.abs(protected - 101.5) < 0.0001,
        "pre-existing lock remains absolute floor")
    local untouched, untouchedChanged = Rules:ScaleReloadDeadline(100, 102, 101.8, 0.40)
    expect(not untouchedChanged and math.abs(untouched - 101.8) < 0.0001,
        "non-reload/pre-existing deadline is untouched")

    expect(ORDINARY_RELOADABLE.weapon_pistol and ORDINARY_RELOADABLE.weapon_shotgun
        and ORDINARY_RELOADABLE.weapon_smg1 and ORDINARY_RELOADABLE.weapon_ar2
        and ORDINARY_RELOADABLE.weapon_357, "ordinary firearm reload authority coverage")
    expect(not ORDINARY_RELOADABLE.weapon_lod_crowbar and not ORDINARY_RELOADABLE.weapon_frag,
        "non-reload/non-firearm tools excluded")

    local state = {
        featIds = {}, featQualificationAbilities = {dex = 18}, classId = "wizard",
        secondaryAbilities = {}, capabilityTags = {}
    }
    local ps = {starterWeaponClass = "weapon_smg1"}
    expect(Progression:_FeatEligible(ps, state, Feats[CHAIN[1]]), "Quick Reload legal")
    expect(not Progression:_FeatEligible(ps, state, Feats[CHAIN[2]]), "Lightning Reload prerequisite")
    state.featIds = {CHAIN[1]}
    expect(Progression:_FeatEligible(ps, state, Feats[CHAIN[2]]), "Lightning Reload legal")
    expect(not Progression:_FeatEligible(ps, state, Feats[CHAIN[3]]), "Blink Reload prerequisite")
    state.featIds = {CHAIN[1], CHAIN[2]}
    expect(Progression:_FeatEligible(ps, state, Feats[CHAIN[3]]), "Blink Reload legal")

    return #errors == 0, errors
end

if Validation and not Validation.LODDexReloadWrapped then
    Validation.LODDexReloadWrapped = true
    local base = Validation.Run
    local function count(values)
        local n = 0
        for _ in pairs(values or {}) do n = n + 1 end
        return n
    end
    function Validation:Run(printResult)
        local baseOK, errors = base(self, false)
        errors = errors or {}
        local featOK, featErrors = Effects:ValidateReloadCadence()
        for _, message in ipairs(featErrors or {}) do
            errors[#errors + 1] = "Gate E DEX Reload: " .. message
        end
        local ok = baseOK and featOK and #errors == 0
        if printResult ~= false then
            if ok then
                print(string.format(
                    "[LOD:RPG] core RPG validation PASS — gate=%s schemas=%d classes=%d abilities=%d featSlots=%d gameplayEnabled=%s gateEExplodingDice=true gateEReload=true",
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

concommand.Add("lod_rpg_gate_e_reload_validate", function(ply)
    if not developerAllowed(ply) then return end
    local ok, errors = Effects:ValidateReloadCadence()
    if ok then
        print("[LOD:RPG-E] DEX Reload feat family PASS — 0.80/0.60/0.40 replacement ladder; reload-only deadline scaling; pre-existing lockouts preserved")
    else
        ErrorNoHalt("[LOD:RPG-E] DEX Reload feat family FAILED\n")
        for _, message in ipairs(errors or {}) do ErrorNoHalt("[LOD:RPG-E]  - " .. message .. "\n") end
    end
end)

concommand.Add("lod_rpg_gate_e_reload_status", function(ply)
    if not developerAllowed(ply) then return end
    if not IsValid(ply) then
        print("[LOD:RPG-E] Run this command from an attached player console.")
        return
    end
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState or nil
    local profile = Effects:ReloadProfile(state)
    local weapon = ply:GetActiveWeapon()
    local class = IsValid(weapon) and weapon:GetClass() or "none"
    local session = Effects.ReloadSessions and Effects.ReloadSessions[ply] or nil
    local last = Effects.ReloadStats and Effects.ReloadStats.lastScale or nil
    local lastText = last and string.format("%s/%s %.2fs->%.2fs",
        tostring(last.weaponClass), tostring(last.channel),
        tonumber(last.authoredSeconds) or 0, tonumber(last.scaledSeconds) or 0) or "none"
    local line = string.format(
        "reloadRank=%d multiplier=%.2f active=%s observing=%s inReload=%s scaledExtensions=%d last=%s",
        profile.rank or 0, Rules:ReloadTimeMultiplier(ply), class, tostring(session ~= nil),
        tostring(IsValid(weapon) and Effects:IsWeaponInReload(weapon) or false),
        Effects.ReloadStats and Effects.ReloadStats.reloadExtensionsScaled or 0, lastText)
    print("[LOD:RPG-E] " .. line)
    ply:ChatPrint(line)
end)

concommand.Add("lod_rpg_test_reload", function(ply, _, args)
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
    if run.MarkUnranked then run:MarkUnranked("Gate E DEX Reload feat test") end
    ply:ChatPrint(string.format(
        "Gate E reload rank %d configured (0=1.00, 1=0.80, 2=0.60, 3=0.40 reload-time multiplier).",
        rank))
end)

concommand.Add("lod_rpg_gate_e_reload_testkit", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) or not ply:Alive() then return end
    local requested = string.lower(tostring(args[1] or "pistol"))
    local class = requested == "shotgun" and "weapon_shotgun" or "weapon_pistol"
    local weapon = ply:GetWeapon(class)
    if not IsValid(weapon) then weapon = ply:Give(class, true) end
    if not IsValid(weapon) then ply:ChatPrint("Could not grant reload test weapon.") return end
    local maximum = math.max(1, weapon:GetMaxClip1())
    weapon:SetClip1(math.min(1, maximum - 1))
    local ammoType = weapon:GetPrimaryAmmoType()
    if ammoType and ammoType >= 0 then ply:SetAmmo(maximum * 2, ammoType) end
    ply:SelectWeapon(class)
    ply:ChatPrint(string.format(
        "Reload testkit ready: %s clip=%d/%d. Press R and compare ranks 0-3; status reports active multiplier.",
        class, weapon:Clip1(), maximum))
end)

return Effects
