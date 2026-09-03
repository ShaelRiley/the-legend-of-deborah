LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG
local Catalog = RPG.IdentityCatalog
local Feats = Catalog and (Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats)
local Effects = RPG.FeatEffectSystem
local Progression = LOD.CharacterProgressionSystem
local Rules = LOD.RPGAbilityRules
local Validation = LOD.RPGValidation
if not Feats or not Effects or not Progression or not Rules then return end

local FAMILY = "dex_exploding_damage_dice"
local CHAIN = {"DEX_EXPLODE_D10", "DEX_EXPLODE_D8", "DEX_EXPLODE_D4"}
local SIDES = {10, 8, 4}
local RANK = {DEX_EXPLODE_D10 = 1, DEX_EXPLODE_D8 = 2, DEX_EXPLODE_D4 = 3}
local SOURCE_REVISION = "ANLCKQlK0CLl2Fs6HxRSmvQtJ64NnbR5HNXdS6m7gbfsgOXB-VlnaGZlXKlQxdLirxGy7uzVJguUC_AEFtLrDhAnQp4LaCWiw5ErJMjjCg"

local function definition(id, name, dex, prerequisite, rank, sides)
    return {
        featId = id, displayName = name, featFamilyId = FAMILY, rankIndex = rank,
        replacesLowerRank = false, repeatableFallback = false,
        governingAbilities = {"dex"}, abilityRequirements = {dex = dex},
        prerequisiteFeatIds = prerequisite and {prerequisite} or {},
        requiredCapabilityTags = {"d" .. sides .. "_damage"}, incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"}, requiredSubsystemTags = {},
        synergyTags = {"damage_dice", "exploding_dice", "boom_shift"}, oneRank = true,
        effectHandlerId = "dex_exploding_damage_dice",
        effectParams = {dieSides = sides, description = string.format(
            "Makes ordinary actor-owned d%d damage dice explode. Fresh d%d dice explode only on natural %d; continuation dice use threshold max(2, %d - BoomShift). The unlock is additive with earlier ranks and every chain obeys the universal 32-die cap.",
            sides, sides, sides, sides)},
        directorBaseWeight = 1.0,
        eligibilityText = string.format("DEX %d%s", dex,
            prerequisite and (" / requires " .. prerequisite) or ""),
        actorText = string.format("Non-Rogue heroes, human Soldiers, and AI with d%d damage rolls", sides)
    }
end

Feats.DEX_EXPLODE_D10 = definition("DEX_EXPLODE_D10", "Perfect Ten", 12, nil, 1, 10)
Feats.DEX_EXPLODE_D8 = definition("DEX_EXPLODE_D8", "Eight Is Enough", 14, "DEX_EXPLODE_D10", 2, 8)
Feats.DEX_EXPLODE_D4 = definition("DEX_EXPLODE_D4", "Fourtunate", 16, "DEX_EXPLODE_D8", 3, 4)
Catalog.OrdinaryFeats = Feats
Catalog.GateEExplodingDiceSourceRevisionId = SOURCE_REVISION

local function owns(state, id)
    for _, value in ipairs(state and state.featIds or {}) do if value == id then return true end end
    return false
end

function Effects:ExplodingDiceProfile(state)
    local rank = 0
    for id, value in pairs(RANK) do if value > rank and owns(state, id) then rank = value end end
    local enabled = {}
    for index = 1, rank do enabled[SIDES[index]] = true end
    return {rank = rank, enabledBySides = enabled}
end

function Effects:ApplyExplodingDiceToDamageProfile(profile, derived)
    if not profile or profile.classExplosionImmune == true or profile.exploding ~= nil then return profile end
    if derived and derived.rogueAllDamageDiceExplode == true then return profile end
    local sides = math.max(2, math.floor(tonumber(profile.sides) or 2))
    local enabled = derived and derived.featExplodingDamageDice or nil
    if enabled and enabled[sides] and (sides == 4 or sides == 8 or sides == 10) then
        profile.exploding = sides
        profile.rpgFeatExplosion = true
    end
    return profile
end

if not Effects.LODDexExplodingApplyDerivedWrapped then
    Effects.LODDexExplodingApplyDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        derived.featExplodingDamageDice = self:ExplodingDiceProfile(state).enabledBySides
    end
end

local WEAPONS = {
    [4] = {weapon_pistol = true},
    [8] = {weapon_smg1 = true, weapon_lod_crowbar = true, weapon_crowbar = true},
    [10] = {weapon_ar2 = true}
}
local function stateHas(state, tag)
    for _, value in ipairs(state and state.capabilityTags or {}) do if value == tag then return true end end
    return false
end
local function inventoryHas(ps, wanted)
    for _, weapon in ipairs(ps and ps.inventory and ps.inventory.weapons or {}) do
        if wanted[weapon.class] then return true end
    end
    return false
end
local function liveHas(ps, wanted)
    local run = LOD.RunManager
    if not ps or not run or not run.GetPlayerState then return false end
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and run:GetPlayerState(ply) == ps then
            for class in pairs(wanted) do if IsValid(ply:GetWeapon(class)) then return true end end
        end
    end
    return false
end
local function hasDamageCapability(ps, state, sides)
    local tag, wanted = "d" .. sides .. "_damage", WEAPONS[sides] or {}
    if stateHas(state, tag) or inventoryHas(ps, wanted) or liveHas(ps, wanted) then return true end
    if ps and wanted[ps.starterWeaponClass] then return true end
    -- Pistol and Crowbar-family d8 access are guaranteed cooperative-Hero baseline tools.
    return ps ~= nil and (sides == 4 or sides == 8)
end

if not Progression.LODDexExplodingCapabilityWrapped then
    Progression.LODDexExplodingCapabilityWrapped = true
    local base = Progression._HasCapability
    function Progression:_HasCapability(ps, state, tag)
        local sides = tostring(tag or ""):match("^d(%d+)_damage$")
        if sides then return hasDamageCapability(ps, state, tonumber(sides)) end
        return base(self, ps, state, tag)
    end
end

if not Progression.LODDexExplodingEligibilityWrapped then
    Progression.LODDexExplodingEligibilityWrapped = true
    local base = Progression._FeatEligible
    function Progression:_FeatEligible(ps, state, feat)
        if feat and feat.featFamilyId == FAMILY and state and state.classId == "rogue" then return false end
        return base(self, ps, state, feat)
    end
end

if not Rules.LODDexExplodingDamageProfileWrapped then
    Rules.LODDexExplodingDamageProfileWrapped = true
    local base = Rules.CopyDamageProfile
    function Rules:CopyDamageProfile(profile, actor)
        local copy = base(self, profile, actor)
        return Effects:ApplyExplodingDiceToDamageProfile(copy, copy.rpgDerived)
    end
end

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do if value == wanted then return true end end
    return false
end
if RPG.Schema and RPG.Schema.DerivedStats and not contains(RPG.Schema.DerivedStats, "featExplodingDamageDice") then
    RPG.Schema.DerivedStats[#RPG.Schema.DerivedStats + 1] = "featExplodingDamageDice"
end
RPG.SystemBootstrap.FeatEffectSystem = "gate_e_batch_4_dex_exploding_dice"

local function thresholds(derived)
    local parts = {}
    for _, sides in ipairs(SIDES) do
        if derived and derived.featExplodingDamageDice and derived.featExplodingDamageDice[sides] then
            local p = Rules:ExplosionParameters(derived, sides, false)
            parts[#parts + 1] = string.format("d%d fresh=%d continuation=%d", sides, sides, p.continuation or sides)
        end
    end
    return table.concat(parts, "; ")
end

if not Progression.LODDexExplodingSnapshotWrapped then
    Progression.LODDexExplodingSnapshotWrapped = true
    local base = Progression.BuildClientSnapshot
    function Progression:BuildClientSnapshot(ply)
        local snapshot = base(self, ply)
        if not snapshot then return nil end
        local ps = LOD.RunManager and LOD.RunManager:GetPlayerState(ply) or nil
        local state = ps and ps.progressionState or nil
        local derived = state and state.derivedStats or nil
        snapshot.explodingDamageDice, snapshot.boomShift = {}, tonumber(derived and derived.boomShift) or 0
        for _, sides in ipairs(SIDES) do
            if derived and derived.featExplodingDamageDice and derived.featExplodingDamageDice[sides] then
                local p = Rules:ExplosionParameters(derived, sides, false)
                snapshot.explodingDamageDice[#snapshot.explodingDamageDice + 1] = {
                    sides = sides, freshThreshold = sides, continuationThreshold = p.continuation or sides}
            end
        end
        local summary, highest = thresholds(derived), nil
        for rank = 3, 1, -1 do if owns(state, CHAIN[rank]) then highest = CHAIN[rank] break end end
        if summary ~= "" and highest then
            for _, item in ipairs(snapshot.ownedFeats or {}) do
                if item.featId == highest then
                    item.effect = tostring(item.effect or "") .. " Current feat-enabled exploding dice: " .. summary .. "."
                    break
                end
            end
        end
        return snapshot
    end
end

local function rng(values, fallback)
    return {index = 0, Int = function(self, minimum, maximum)
        self.index = self.index + 1
        return math.Clamp(math.floor(tonumber(values and values[self.index]) or fallback or maximum), minimum, maximum)
    end}
end

function Effects:ValidateExplodingDice()
    local errors = {}
    local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    local expected = {
        DEX_EXPLODE_D10 = {1, 12, nil, 10}, DEX_EXPLODE_D8 = {2, 14, "DEX_EXPLODE_D10", 8},
        DEX_EXPLODE_D4 = {3, 16, "DEX_EXPLODE_D8", 4}}
    for id, values in pairs(expected) do
        local feat = Feats[id]
        expect(feat and feat.featFamilyId == FAMILY, id .. " definition/family")
        if feat then
            expect(feat.rankIndex == values[1] and feat.replacesLowerRank == false, id .. " additive rank")
            expect(feat.abilityRequirements.dex == values[2], id .. " DEX requirement")
            expect((feat.prerequisiteFeatIds or {})[1] == values[3], id .. " prerequisite")
            expect(feat.effectParams.dieSides == values[4], id .. " die size")
        end
    end
    local p0, p1 = self:ExplodingDiceProfile({featIds = {}}), self:ExplodingDiceProfile({featIds = {CHAIN[1]}})
    local p2, p3 = self:ExplodingDiceProfile({featIds = {CHAIN[2]}}), self:ExplodingDiceProfile({featIds = {CHAIN[3]}})
    expect(p0.rank == 0 and next(p0.enabledBySides) == nil, "baseline profile")
    expect(p1.enabledBySides[10] and not p1.enabledBySides[8], "rank 1 profile")
    expect(p2.enabledBySides[10] and p2.enabledBySides[8] and not p2.enabledBySides[4], "rank 2 cumulative profile")
    expect(p3.enabledBySides[10] and p3.enabledBySides[8] and p3.enabledBySides[4], "rank 3 cumulative profile")

    local none, d10, d8, d4 = {sides=10}, {sides=10}, {sides=8}, {sides=4}
    self:ApplyExplodingDiceToDamageProfile(none, {featExplodingDamageDice={}})
    self:ApplyExplodingDiceToDamageProfile(d10, {featExplodingDamageDice={[10]=true}})
    self:ApplyExplodingDiceToDamageProfile(d8, {featExplodingDamageDice={[8]=true}})
    self:ApplyExplodingDiceToDamageProfile(d4, {featExplodingDamageDice={[4]=true}})
    expect(none.exploding == nil and d10.exploding == 10 and d8.exploding == 8 and d4.exploding == 4,
        "ordinary feat explosion permissions")
    local immune = {sides=8, classExplosionImmune=true}
    self:ApplyExplodingDiceToDamageProfile(immune, {featExplodingDamageDice={[8]=true}})
    expect(immune.exploding == nil, "classExplosionImmune absolute")
    for _, sides in ipairs({6,12}) do
        local universal = {sides=sides}
        self:ApplyExplodingDiceToDamageProfile(universal, {featExplodingDamageDice={[4]=true,[8]=true,[10]=true}})
        expect(universal.exploding == nil, "universal d" .. sides .. " unchanged by feat layer")
    end

    local boom = {boomShift=2}
    expect(Rules:ExplosionParameters(boom,10,false).continuation == 8, "d10 continuation")
    expect(Rules:ExplosionParameters(boom,8,false).continuation == 6, "d8 continuation")
    expect(Rules:ExplosionParameters(boom,4,false).continuation == 2, "d4 continuation")
    local rolls = LOD.CombatRolls
    if rolls and rolls._RollExploding then
        for _, test in ipairs({{10,{10,8,1},8},{8,{8,6,1},6},{4,{4,2,1},2}}) do
            local _, values, _, _, used = rolls:_RollExploding(
                {sides=test[1],count=1,exploding=test[1],rpgDerived=boom}, rng(test[2]))
            expect(#values == 3 and used[1] == test[1] and used[2] == test[3], "d"..test[1].." fresh/continuation chain")
        end
        local _, values, _, capped = rolls:_RollExploding({sides=10,count=1,exploding=10,rpgDerived=boom}, rng(nil,10))
        expect(capped and #values == 32, "32-die chain cap")
        local progression = rolls:RollProgressionHitDie(7654321,10)
        expect(progression.formula == "d10" and #progression.values == 1, "progression dice isolated")
    else expect(false, "CombatRolls exploding authority unavailable") end

    local ps = {starterWeaponClass="weapon_ar2"}
    local state = {featIds={},featQualificationAbilities={dex=16},classId="fighter",secondaryAbilities={},capabilityTags={}}
    expect(Progression:_FeatEligible(ps,state,Feats[CHAIN[1]]), "Perfect Ten legal with d10 capability")
    expect(not Progression:_FeatEligible(ps,state,Feats[CHAIN[2]]), "Eight Is Enough prerequisite")
    state.featIds={CHAIN[1]}; expect(Progression:_FeatEligible(ps,state,Feats[CHAIN[2]]), "Eight Is Enough legal")
    expect(not Progression:_FeatEligible(ps,state,Feats[CHAIN[3]]), "Fourtunate prerequisite")
    state.featIds={CHAIN[1],CHAIN[2]}; expect(Progression:_FeatEligible(ps,state,Feats[CHAIN[3]]), "Fourtunate legal")
    state.classId="rogue"; for _, id in ipairs(CHAIN) do expect(not Progression:_FeatEligible(ps,state,Feats[id]), "Rogue exclusion "..id) end
    state.classId="fighter"; state.featIds={}; ps.starterWeaponClass="weapon_smg1"
    expect(not Progression:_FeatEligible(ps,state,Feats[CHAIN[1]]), "Perfect Ten actual d10 capability")
    return #errors == 0, errors
end

if Validation and not Validation.LODDexExplodingWrapped then
    Validation.LODDexExplodingWrapped = true
    local base = Validation.Run
    local function count(values) local n=0 for _ in pairs(values or {}) do n=n+1 end return n end
    function Validation:Run(printResult)
        local baseOK, errors = base(self, false)
        errors = errors or {}
        local featOK, featErrors = Effects:ValidateExplodingDice()
        for _, message in ipairs(featErrors or {}) do errors[#errors+1] = "Gate E DEX Exploding Dice: "..message end
        local ok = baseOK and featOK and #errors == 0
        if printResult ~= false then
            if ok then print(string.format(
                "[LOD:RPG] core RPG validation PASS — gate=%s schemas=%d classes=%d abilities=%d featSlots=%d gameplayEnabled=%s gateEExplodingDice=true",
                tostring(RPG.ImplementationGate),count(RPG.Schema),count(RPG.Classes),#RPG.Abilities,#RPG.OrdinaryFeatLevels,tostring(RPG.GameplayEnabled)))
            else
                ErrorNoHalt("[LOD:RPG] core RPG validation FAILED ("..#errors.." error(s))\n")
                for _, message in ipairs(errors) do ErrorNoHalt("[LOD:RPG]  - "..message.."\n") end
            end
        end
        return ok, errors
    end
end

concommand.Add("lod_rpg_gate_e_exploding_dice_validate", function(ply)
    local cv=GetConVar("lod_developer_mode"); if not cv or not cv:GetBool() or (IsValid(ply) and not ply:IsAdmin()) then return end
    local ok, errors=Effects:ValidateExplodingDice()
    if ok then print("[LOD:RPG-E] DEX Exploding-Dice feat family PASS — d10/d8/d4 additive ladder, Rogue exclusion, BoomShift continuation, 32-die cap")
    else ErrorNoHalt("[LOD:RPG-E] DEX Exploding-Dice feat family FAILED\n"); for _,e in ipairs(errors or {}) do ErrorNoHalt("[LOD:RPG-E]  - "..e.."\n") end end
end)

concommand.Add("lod_rpg_gate_e_exploding_dice_status", function(ply)
    local cv=GetConVar("lod_developer_mode"); if not cv or not cv:GetBool() or (IsValid(ply) and not ply:IsAdmin()) then return end
    if not IsValid(ply) then print("[LOD:RPG-E] Run this command from an attached player console.") return end
    local derived=Rules:Derived(ply); local summary=thresholds(derived)
    local line=string.format("BoomShift=%d featDice=%s RogueMastery=%s",math.floor(tonumber(derived and derived.boomShift) or 0),summary~="" and summary or "none",tostring(derived and derived.rogueAllDamageDiceExplode==true))
    print("[LOD:RPG-E] "..line); ply:ChatPrint(line)
end)

concommand.Add("lod_rpg_test_exploding_dice", function(ply, _, args)
    local cv=GetConVar("lod_developer_mode"); if not cv or not cv:GetBool() or not IsValid(ply) or not ply:IsAdmin() then return end
    local run=LOD.RunManager; local ps=run and run:GetPlayerState(ply) or nil; local state=ps and ps.progressionState or nil
    if not state then ply:ChatPrint("RPG progression state is unavailable.") return end
    if state.classId=="rogue" then ply:ChatPrint("Rogues already have exploding-dice mastery; use Fighter or Wizard for this feat-family test.") return end
    local rank=math.Clamp(math.floor(tonumber(args[1]) or 1),0,3); local kept={}
    for _,id in ipairs(state.featIds or {}) do if not RANK[id] then kept[#kept+1]=id end end
    state.featIds=kept; state.featStackCounts=state.featStackCounts or {}; for id in pairs(RANK) do state.featStackCounts[id]=nil end
    for index=1,rank do local id=CHAIN[index]; state.featIds[#state.featIds+1]=id; state.featStackCounts[id]=1 end
    Progression:_RecomputeProgressionState(state); Progression:SyncPlayer(ply)
    if run.MarkUnranked then run:MarkUnranked("Gate E DEX Exploding-Dice feat test") end
    ply:ChatPrint(string.format("Gate E exploding-dice rank %d configured (0=none, 1=d10, 2=d10+d8, 3=d10+d8+d4).",rank))
end)

return Effects
