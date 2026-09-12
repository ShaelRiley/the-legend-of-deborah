LOD = LOD or {}
LOD.CharacterProgressionSystem = LOD.CharacterProgressionSystem or {}
LOD.FeatDirector = LOD.CharacterProgressionSystem

local CharacterProgressionSystem = LOD.CharacterProgressionSystem
local RPG = LOD.RPG
local Catalog = RPG.IdentityCatalog

util.AddNetworkString("LOD_RPG_RequestSheet")
util.AddNetworkString("LOD_RPG_Snapshot")
util.AddNetworkString("LOD_RPG_ChooseClass")
util.AddNetworkString("LOD_RPG_ChooseFeat")
util.AddNetworkString("LOD_RPG_ChooseCapstone")

local ABILITY_LABELS = {
    str = "STR", dex = "DEX", con = "CON", int = "INT", wis = "WIS", cha = "CHA"
}
local ALL_ABILITIES = {"str", "dex", "con", "int", "wis", "cha"}

local function emptyArray()
    return {}
end

local function emptyMap()
    return {}
end

local function copyArray(values)
    local result = {}
    for index, value in ipairs(values or {}) do result[index] = value end
    return result
end

local function copyAbilityBlock(values)
    local result = RPG.NewAbilityBlock(0)
    for _, ability in ipairs(ALL_ABILITIES) do result[ability] = tonumber(values and values[ability]) or 0 end
    return result
end

local function sortedKeys(values)
    local result = {}
    for key in pairs(values or {}) do result[#result + 1] = key end
    table.sort(result)
    return result
end

local function arrayContains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then return true end
    end
    return false
end

local function ordinarySlotIndexForLevel(level)
    for index, featLevel in ipairs(RPG.OrdinaryFeatLevels) do
        if featLevel == level then return index end
    end
    return nil
end

local function concise(text, limit)
    text = tostring(text or "")
    limit = tonumber(limit) or 360
    if #text <= limit then return text end
    return string.sub(text, 1, limit - 3) .. "..."
end

function CharacterProgressionSystem:NewProgressionState(actorId, archetypeId, actorType)
    actorType = actorType or "hero"
    local isHero = actorType == "hero"

    return {
        actorId = actorId,
        actorType = actorType,
        archetypeId = archetypeId,
        tierId = nil,
        dungeonLevel = nil,
        characterIdentityPackage = nil,
        level = RPG.Constants.MinLevel,
        xp = isHero and 0 or nil,
        classId = nil,
        primaryAbility = nil,
        secondaryAbilities = emptyArray(),
        baseAbilities = RPG.NewAbilityBlock(0),
        growthAbilities = RPG.NewAbilityBlock(0),
        identityAbilityDelta = RPG.NewAbilityBlock(0),
        equipmentAbilityDelta = RPG.NewAbilityBlock(0),
        featAbilityDelta = RPG.NewAbilityBlock(0),
        temporaryAbilityDelta = RPG.NewAbilityBlock(0),
        effectiveAbilities = RPG.NewAbilityBlock(0),
        featQualificationAbilities = RPG.NewAbilityBlock(0),
        fighterTraining = RPG.NewAbilityBlock(0),
        derivedStats = {},
        startingHP = nil,
        progressionHitDieSides = nil,
        hitDieRollsByLevel = emptyMap(),
        featSlotsGranted = 0,
        featIds = emptyArray(),
        featStackCounts = emptyMap(),
        pendingFeatSlots = emptyArray(),
        classCapstoneFeatId = nil,
        pendingClassCapstoneDraft = nil,
        dungeonEntryLevel = nil,
        replacementXpEarnedThisDungeon = 0,
        capabilityTags = emptyArray(),
        contentIds = emptyArray(),
        moraleBonus = 0,
        usesMagic = false,
        currentElement = nil,
        elementalWeaknesses = emptyArray(),
        statusImmunities = emptyArray()
    }
end

function CharacterProgressionSystem:ActorHardLevelCap(actorTypeOrState)
    local actorType = type(actorTypeOrState) == "table" and actorTypeOrState.actorType or actorTypeOrState
    if actorType == "ai" or actorType == "human_soldier" then
        return RPG.Constants.MonsterMaxLevel
    end
    return RPG.Constants.HeroMaxLevel
end

function CharacterProgressionSystem:DungeonEntityLevelCeiling(dungeonLevel)
    return math.max(1, math.floor(tonumber(dungeonLevel) or 1)) + 3
end

function CharacterProgressionSystem:EffectiveLevelCap(actorTypeOrState, dungeonLevel)
    return math.min(self:ActorHardLevelCap(actorTypeOrState),
        self:DungeonEntityLevelCeiling(dungeonLevel))
end

function CharacterProgressionSystem:ClampLevel(level, actorTypeOrState)
    return math.Clamp(math.floor(tonumber(level) or RPG.Constants.MinLevel),
        RPG.Constants.MinLevel, self:ActorHardLevelCap(actorTypeOrState))
end

function CharacterProgressionSystem:AbilityModifier(score)
    score = math.Clamp(tonumber(score) or 10, RPG.Constants.AbilityMin, RPG.Constants.AbilityMax)
    return math.floor((score - 10) / 2)
end

local function derive(seed, label)
    return LOD.Seeds.Derive(seed, "rpg:" .. tostring(label))
end

function CharacterProgressionSystem:HeroIdentitySeed(rosterSeed, persistentHeroIdentity)
    return derive(rosterSeed, "hero_identity:" .. tostring(persistentHeroIdentity) .. ":character_identity")
end

function CharacterProgressionSystem:HeroGrowthProfileSeed(campaignSeed, persistentHeroIdentity, classId)
    return derive(campaignSeed, "hero_growth:" .. tostring(persistentHeroIdentity) .. ":" .. tostring(classId) .. ":growth_profile")
end

function CharacterProgressionSystem:HumanSoldierGrowthProfileSeed(campaignSeed, persistentConnectionIdentity, classId)
    return derive(campaignSeed, "soldier_growth:" .. tostring(persistentConnectionIdentity) .. ":" .. tostring(classId) .. ":soldier_growth_profile")
end

function CharacterProgressionSystem:AIProgressionSeed(levelSeed, encounterOrWandererIdentity, spawnOrdinal, archetypeId)
    local label = table.concat({
        "ai_progression",
        tostring(encounterOrWandererIdentity),
        tostring(spawnOrdinal),
        tostring(archetypeId),
        "progression"
    }, ":")
    return derive(levelSeed, label)
end

function CharacterProgressionSystem:PrepareCampaignState(state)
    if not state then return end
    state.RPGAllocation = state.RPGAllocation or {
        used = {
            origin = {}, background = {}, motive = {},
            first_male = {}, first_female = {}, surname = {}, nickname = {}
        },
        displayNames = {}
    }

    for _, ps in pairs(state.PlayerState or {}) do
        local package = ps.progressionState and ps.progressionState.characterIdentityPackage
        if package then
            local used = state.RPGAllocation.used
            used.origin[package.originIndex] = ps.identity
            used.background[package.backgroundIndex] = ps.identity
            used.motive[package.motiveIndex] = ps.identity
            local firstDomain = "first_" .. tostring(package.presentationSex)
            used[firstDomain] = used[firstDomain] or {}
            used[firstDomain][package.masculineOrFeminineFirstNameIndex] = ps.identity
            used.surname[package.surnameIndex] = ps.identity
            used.nickname[package.nicknameIndex] = ps.identity
            state.RPGAllocation.displayNames[package.fullDisplayName] = ps.identity
        end
    end
end

local function deterministicOrder(seed, namespace)
    local order = {}
    for index = 1, 64 do order[index] = index end
    LOD.RNG.New(derive(seed, namespace)):Shuffle(order)
    return order
end

function CharacterProgressionSystem:_AvailableIndex(runState, domain, identitySeed, namespace)
    self:PrepareCampaignState(runState)
    local used = runState.RPGAllocation.used[domain]
    if not used then
        used = {}
        runState.RPGAllocation.used[domain] = used
    end
    local order = deterministicOrder(identitySeed, namespace or domain)
    for _, index in ipairs(order) do
        if not used[index] then return index end
    end
    return order[1]
end

function CharacterProgressionSystem:_ReserveIndex(runState, domain, index, identity)
    self:PrepareCampaignState(runState)
    runState.RPGAllocation.used[domain][index] = identity
end

function CharacterProgressionSystem:_BuildIdentityPackage(runManager, ps, character)
    local runState = runManager.State
    local rosterSeed = assert(runState.RosterSeed, "RosterSeed must exist before hero identity generation")
    local heroIdentityId = ps.identity
    local identitySeed = self:HeroIdentitySeed(rosterSeed, heroIdentityId)
    local presentationSex = character and character.presentationSex or nil
    assert(presentationSex == "male" or presentationSex == "female",
        "configured player character requires presentationSex=male|female")

    local originIndex = self:_AvailableIndex(runState, "origin", identitySeed, "identity:origin")
    local backgroundIndex = self:_AvailableIndex(runState, "background", identitySeed, "identity:background")
    local motiveIndex = self:_AvailableIndex(runState, "motive", identitySeed, "identity:motive")
    local firstDomain = "first_" .. presentationSex
    local firstIndex = self:_AvailableIndex(runState, firstDomain, identitySeed, "identity:first_name:" .. presentationSex)
    local surnameIndex = self:_AvailableIndex(runState, "surname", identitySeed, "identity:surname")
    local nicknameIndex = self:_AvailableIndex(runState, "nickname", identitySeed, "identity:nickname")

    local firstTable = presentationSex == "female" and Catalog.FeminineFirstNames or Catalog.MasculineFirstNames
    local firstName = firstTable[firstIndex]
    local surname = Catalog.Surnames[surnameIndex]
    local nickname = Catalog.Nicknames[nicknameIndex]
    local fullDisplayName = string.format('%s "%s" %s', firstName, nickname, surname)

    if runState.RPGAllocation.displayNames[fullDisplayName] then
        local surnameOrder = deterministicOrder(identitySeed, "identity:surname:collision")
        local nicknameOrder = deterministicOrder(identitySeed, "identity:nickname:collision")
        local found
        for _, candidateSurname in ipairs(surnameOrder) do
            if not runState.RPGAllocation.used.surname[candidateSurname] then
                for _, candidateNickname in ipairs(nicknameOrder) do
                    if not runState.RPGAllocation.used.nickname[candidateNickname] then
                        local candidate = string.format('%s "%s" %s',
                            firstName, Catalog.Nicknames[candidateNickname], Catalog.Surnames[candidateSurname])
                        if not runState.RPGAllocation.displayNames[candidate] then
                            surnameIndex, nicknameIndex = candidateSurname, candidateNickname
                            surname, nickname, fullDisplayName =
                                Catalog.Surnames[surnameIndex], Catalog.Nicknames[nicknameIndex], candidate
                            found = true
                            break
                        end
                    end
                end
            end
            if found then break end
        end
        assert(found, "could not allocate a unique procedural hero display name")
    end

    self:_ReserveIndex(runState, "origin", originIndex, heroIdentityId)
    self:_ReserveIndex(runState, "background", backgroundIndex, heroIdentityId)
    self:_ReserveIndex(runState, "motive", motiveIndex, heroIdentityId)
    self:_ReserveIndex(runState, firstDomain, firstIndex, heroIdentityId)
    self:_ReserveIndex(runState, "surname", surnameIndex, heroIdentityId)
    self:_ReserveIndex(runState, "nickname", nicknameIndex, heroIdentityId)
    runState.RPGAllocation.displayNames[fullDisplayName] = heroIdentityId

    local identityAbilityDelta = RPG.NewAbilityBlock(0)
    if motiveIndex == 64 then
        local abilityIndex = LOD.RNG.New(derive(identitySeed, "identity:motive:64:ability")):Int(1, #ALL_ABILITIES)
        identityAbilityDelta[ALL_ABILITIES[abilityIndex]] = 1
    end

    return {
        rosterSeed = rosterSeed,
        heroIdentityId = heroIdentityId,
        originIndex = originIndex,
        backgroundIndex = backgroundIndex,
        motiveIndex = motiveIndex,
        masculineOrFeminineFirstNameIndex = firstIndex,
        surnameIndex = surnameIndex,
        nicknameIndex = nicknameIndex,
        presentationSex = presentationSex,
        firstName = firstName,
        surname = surname,
        nickname = nickname,
        fullDisplayName = fullDisplayName,
        portraitCacheKey = tostring(derive(identitySeed, "portrait:" .. tostring(character.model))),
        identityAbilityDelta = identityAbilityDelta,
        resolvedIdentityPerkIds = {
            "origin:" .. originIndex,
            "background:" .. backgroundIndex,
            "motive:" .. motiveIndex
        }
    }
end

function CharacterProgressionSystem:InitializeHero(runManager, ps, character)
    if not ps then return nil end
    if ps.progressionState then return ps.progressionState end

    self:PrepareCampaignState(runManager.State)
    local state = self:NewProgressionState(ps.identity, "hero", "hero")
    state.baseAbilities = RPG.NewAbilityBlock(10)
    state.startingHP = 100
    state.characterIdentityPackage = self:_BuildIdentityPackage(runManager, ps, character)
    state.identityAbilityDelta = copyAbilityBlock(state.characterIdentityPackage.identityAbilityDelta)
    state.dungeonEntryLevel = tonumber(runManager.State.Level) or 1
    self:_RecomputeProgressionState(state)
    ps.progressionState = state
    ps.rpgGate = "C"
    return state
end

function CharacterProgressionSystem:_GrowthAtLevel(state, level)
    local growth = RPG.NewAbilityBlock(0)
    level = self:ClampLevel(level, state)
    if not state or not state.primaryAbility then return growth end

    for gainedLevel = 1, level do
        if gainedLevel % 2 == 1 then
            growth[state.primaryAbility] = growth[state.primaryAbility] + 1
        end
        if gainedLevel % 4 == 2 then
            for _, ability in ipairs(state.secondaryAbilities or {}) do
                growth[ability] = growth[ability] + 1
            end
        end
        if gainedLevel % 4 == 0 then
            for _, ability in ipairs(ALL_ABILITIES) do
                growth[ability] = growth[ability] + 1
            end
        end
    end
    return growth
end

function CharacterProgressionSystem:_FighterTrainingAtLevel(state, level)
    local training = RPG.NewAbilityBlock(0)
    if not state or state.classId ~= "fighter" or not state.primaryAbility then return training end
    local class = RPG.Classes.fighter
    local lead = state.primaryAbility
    local follow = lead == class.favoredAbilities[1]
        and class.favoredAbilities[2] or class.favoredAbilities[1]
    training[lead] = math.ceil(self:ClampLevel(level, state) / 2)
    training[follow] = math.floor(self:ClampLevel(level, state) / 2)
    return training
end

function CharacterProgressionSystem:_CapstoneDefinition(state)
    local classCatalog = Catalog.ClassCapstones and Catalog.ClassCapstones[state.classId]
    return classCatalog and state.classCapstoneFeatId
        and classCatalog[state.classCapstoneFeatId] or nil
end

-- Permanent one-rank grants are derived from campaign-owned feats. Keeping
-- these separate from accumulated fallback deltas makes recomputation and
-- reconnect idempotent, including states created before the grant was wired.
function CharacterProgressionSystem:PermanentFeatAbilityDelta(state, ability)
    local amount = tonumber(state.featAbilityDelta and state.featAbilityDelta[ability]) or 0
    if ability == "cha" and arrayContains(state.featIds or {}, "CHA_WINNING_PERSONALITY") then
        amount = amount + 1
    end
    return amount
end

function CharacterProgressionSystem:_RecomputeProgressionState(state)
    if not state then return end
    state.level = self:ClampLevel(state.level, state)
    state.growthAbilities = self:_GrowthAtLevel(state, state.level)
    state.fighterTraining = self:_FighterTrainingAtLevel(state, state.level)

    local effective = RPG.NewAbilityBlock(0)
    local qualification = RPG.NewAbilityBlock(0)
    for _, ability in ipairs(ALL_ABILITIES) do
        local intrinsic = (state.baseAbilities[ability] or 0)
            + (state.growthAbilities[ability] or 0)
            + (state.fighterTraining[ability] or 0)
            + (state.identityAbilityDelta[ability] or 0)
            + self:PermanentFeatAbilityDelta(state, ability)
        qualification[ability] = math.Clamp(intrinsic, RPG.Constants.AbilityMin, RPG.Constants.AbilityMax)
        effective[ability] = math.Clamp(intrinsic
            + (state.equipmentAbilityDelta[ability] or 0)
            + (state.temporaryAbilityDelta[ability] or 0),
            RPG.Constants.AbilityMin, RPG.Constants.AbilityMax)
    end
    state.featQualificationAbilities = qualification
    state.effectiveAbilities = effective

    local mods = {}
    for _, ability in ipairs(ALL_ABILITIES) do mods[ability .. "Mod"] = self:AbilityModifier(effective[ability]) end
    local capstone = self:_CapstoneDefinition(state)
    local capParams = capstone and capstone.effectParams or {}
    mods.fighterTrainingLead = state.classId == "fighter" and state.primaryAbility or nil
    mods.fighterClassStrBonus = state.fighterTraining.str or 0
    mods.fighterClassConBonus = state.fighterTraining.con or 0
    mods.physicalDamageMultiplier = math.Clamp(1 + 0.05 * mods.strMod, 0.50, 1.50)
    mods.aimSpreadMultiplier = math.Clamp(1 - 0.04 * mods.dexMod, 0.60, 1.40)
    mods.movementSpeedMultiplier = math.Clamp(1 + 0.02 * mods.dexMod, 0.85, 1.20)
    mods.boomShift = math.Clamp(math.floor(math.max(mods.dexMod, 0) / 2), 0, 2)
    mods.rogueAllDamageDiceExplode = state.classId == "rogue"
    mods.rogueBoomThresholdShift = state.classId == "rogue" and 1 or 0
    mods.rogueCapstoneBoomThresholdShift = capParams.boomThresholdShift or 0
    mods.rogueCapstoneEvasionChance = capParams.evasionChance or 0
    mods.rogueAcePrimeSeconds = capParams.primeSeconds or 0
    mods.damageResistancePerDie = math.Clamp(mods.conMod, 0, 3)
    mods.hpConBonusPerLevel = math.min(mods.conMod, 6)
    mods.conRegenMultiplier = math.Clamp(1 + 0.10 * mods.conMod, 0.50, 2.00)
    mods.magicRegenMultiplier = math.Clamp(1 + 0.10 * mods.intMod, 0.50, 2.00)
    mods.magicPowerMultiplier = math.Clamp(1 + 0.06 * mods.wisMod, 0.60, 1.60)
    mods.utilityMagicCostMultiplier = math.Clamp(1 - 0.04 * mods.wisMod, 0.60, 1.40)
    mods.breadcrumbCells = math.Clamp(6 + 2 * mods.wisMod, 2, 24)
    mods.chaHitStunInflictMultiplier = math.Clamp(1 + 0.03 * mods.chaMod, 0.75, 1.30)
    mods.chaHitStunResistanceMultiplier = math.Clamp(1 - 0.03 * mods.chaMod, 0.70, 1.25)
    mods.wizardClassHpToMagicDiversionFraction = state.classId == "wizard"
        and 0.02 * state.level or 0
    mods.wizardCapstoneDiversionBonus = capParams.diversionBonus or 0
    mods.livingAegisHPPerMagic = capParams.hpPerMagic or 1
    mods.hpToMagicDiversionFraction = math.min(1,
        mods.wizardClassHpToMagicDiversionFraction + mods.wizardCapstoneDiversionBonus)
    mods.fighterCapstonePhysicalDamageMultiplier = capParams.physicalDamageMultiplier or 1
    mods.fighterCapstoneMaxHPMultiplier = capParams.maxHPMultiplier or 1
    mods.fighterCapstoneOutgoingPushMultiplier = capParams.outgoingPushMultiplier or 1
    mods.fighterCapstoneIncomingPushMultiplier = capParams.incomingPushMultiplier or 1
    mods.fighterCapstoneWallSlamBonusDice = capParams.wallSlamBonusDice or 0
    mods.wizardCapstoneMagicRegenMultiplier = capParams.magicRegenMultiplier or 1
    mods.wizardCapstoneMagicPowerMultiplier = capParams.magicPowerMultiplier or 1
    mods.wizardCapstoneMagicDCBonus = capParams.magicDCBonus or 0
    mods.arcaneItemUseChance = state.classId == "wizard" and 1
        or (state.classId == "rogue" and math.min(0.95, 0.05 * state.level) or 0)
    mods.canActivateWandsScrolls = state.classId == "wizard" or state.classId == "rogue"
    mods.levelProficiency = math.floor((state.level - 1) / 4)
    mods.startingHP = state.startingHP or 100
    local featEffects = RPG.FeatEffectSystem
    if featEffects and featEffects.ApplyDerived then
        featEffects:ApplyDerived(state, mods)
    end

    local rolledSubtotal, coreMaxHP = 0, state.startingHP or 100
    for level = 2, state.level do
        local roll = state.hitDieRollsByLevel[level]
        local rolled = tonumber(roll and roll.total or roll) or 0
        rolledSubtotal = rolledSubtotal + rolled
        coreMaxHP = coreMaxHP + math.max(1, rolled + mods.hpConBonusPerLevel)
    end
    mods.progressionHitDieSides = state.progressionHitDieSides
    mods.rolledHitPointSubtotal = rolledSubtotal
    mods.coreMaxHP = coreMaxHP
    mods.maxHP = math.max(1, math.floor(coreMaxHP
        * mods.fighterCapstoneMaxHPMultiplier + 0.5))
    state.derivedStats = mods
end

function CharacterProgressionSystem:_ApplyPlayerMaxHP(ply, state)
    if not IsValid(ply) or not state then return end
    local maximum = math.max(1, state.derivedStats and state.derivedStats.maxHP or 100)
    ply:SetMaxHealth(maximum)
    if ply:Health() > maximum then ply:SetHealth(maximum) end
end

function CharacterProgressionSystem:_HasCapability(ps, state, tag)
    if not tag or tag == "" then return true end
    if arrayContains(state and state.capabilityTags or {}, tag) then return true end
    if tag == "offensive_magic_activation" then
        return state and state.usesMagic == true
            or (LOD.Magic ~= nil and type(LOD.Magic.CastForceShout) == "function")
    elseif tag == "d10_damage" or tag == "multi_fire_burst" then
        return ps and ps.starterWeaponClass == "weapon_ar2"
    elseif tag == "smg" then
        return ps and ps.starterWeaponClass == "weapon_smg1"
    elseif tag == "crowbar" or tag == "pushable_weapon" or tag == "tetris"
        or tag == "firearm" or tag == "reloadable_firearm" or tag == "magic_pool"
        or tag == "minimap" or tag == "cooperative_hero" or tag == "hit_stun_source"
        or tag == "magic_push"
    then
        return true
    end
    return false
end

function CharacterProgressionSystem:_FeatEligible(ps, state, definition)
    if not definition then return false end
    if definition.featId == "DEX_EXPLODE_D10" and state.classId == "rogue" then return false end

    local allowedActors = definition.allowedActorTypes or {}
    if #allowedActors > 0 and not arrayContains(allowedActors, state.actorType or "hero") then
        return false
    end

    for ability, required in pairs(definition.abilityRequirements or {}) do
        if (state.featQualificationAbilities[ability] or 0) < required then return false end
    end
    for _, tag in ipairs(definition.requiredCapabilityTags or {}) do
        if not self:_HasCapability(ps, state, tag) then return false end
    end
    for _, prerequisiteId in ipairs(definition.prerequisiteFeatIds or {}) do
        if not arrayContains(state.featIds, prerequisiteId) then return false end
    end
    for _, incompatibleId in ipairs(definition.incompatibleFeatIds or {}) do
        if arrayContains(state.featIds, incompatibleId) then return false end
    end
    if definition.repeatableFallback then
        local ability = definition.effectParams and definition.effectParams.ability
        return not ability or (state.featQualificationAbilities[ability] or 30) < 30
    end
    for _, ownedId in ipairs(state.featIds or {}) do
        if ownedId == definition.featId then return false end
    end
    return true
end

function CharacterProgressionSystem:_FeatWeight(ps, state, definition)
    local weight = tonumber(definition.directorBaseWeight) or 1
    local secondary, favored = {}, {}
    for _, ability in ipairs(state.secondaryAbilities or {}) do secondary[ability] = true end
    local class = RPG.Classes[state.classId]
    for _, ability in ipairs(class and class.favoredAbilities or {}) do favored[ability] = true end

    local affinity = 1
    for _, ability in ipairs(definition.governingAbilities or {}) do
        if ability == state.primaryAbility then affinity = math.max(affinity, 1.50)
        elseif secondary[ability] then affinity = math.max(affinity, 1.25)
        elseif favored[ability] then affinity = math.max(affinity, 1.15) end
    end
    weight = weight * affinity

    if definition.featFamilyId and (tonumber(definition.rankIndex) or 0) > 1 then
        local previousRank = (tonumber(definition.rankIndex) or 1) - 1
        for _, featId in ipairs(state.featIds or {}) do
            local owned = Catalog.OrdinaryFeats and Catalog.OrdinaryFeats[featId]
                or Catalog.LevelOneOrdinaryFeats[featId]
            if owned and owned.featFamilyId == definition.featFamilyId
                and owned.rankIndex == previousRank
            then
                weight = weight * 1.75
                break
            end
        end
    end

    local toolTag = definition.requiredCapabilityTags and definition.requiredCapabilityTags[1]
    if toolTag == "d10_damage" or toolTag == "multi_fire_burst" or toolTag == "smg" then
        weight = weight * 1.25
    end
    return math.Clamp(weight, 0.25, 5.00)
end

local function weightedDraw(rng, candidates, count)
    local pool, result = {}, {}
    for _, item in ipairs(candidates or {}) do pool[#pool + 1] = item end
    for _ = 1, math.min(count, #pool) do
        local total = 0
        for _, item in ipairs(pool) do total = total + item.weight end
        local roll = rng:Float(0, total)
        local running, selected = 0, #pool
        for index, item in ipairs(pool) do
            running = running + item.weight
            if roll <= running then selected = index break end
        end
        result[#result + 1] = pool[selected].definition
        table.remove(pool, selected)
    end
    return result
end

function CharacterProgressionSystem:_GenerateOrdinaryDraft(ps, state, campaignSeed, earnedAtLevel)
    local slotIndex = ordinarySlotIndexForLevel(earnedAtLevel)
    if not slotIndex then return nil end
    if state.pendingFeatSlots[slotIndex] then return state.pendingFeatSlots[slotIndex] end

    local draftSeed = derive(self:HeroGrowthProfileSeed(campaignSeed, ps.identity, state.classId),
        "feat_draft:ordinary:level:" .. earnedAtLevel .. ":slot:" .. slotIndex)
    local rng = LOD.RNG.New(draftSeed)
    local ordinaryCandidates = {}
    local ordinaryFeats = Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats
    for _, featId in ipairs(sortedKeys(ordinaryFeats)) do
        local definition = ordinaryFeats[featId]
        if self:_FeatEligible(ps, state, definition) then
            ordinaryCandidates[#ordinaryCandidates + 1] = {
                definition = definition,
                weight = self:_FeatWeight(ps, state, definition)
            }
        end
    end

    local selected = weightedDraw(rng, ordinaryCandidates, math.min(3, #ordinaryCandidates))
    if #selected < 3 then
        local fallbackCandidates = {}
        for _, featId in ipairs(sortedKeys(Catalog.FallbackFeats)) do
            local definition = Catalog.FallbackFeats[featId]
            if self:_FeatEligible(ps, state, definition) then
                fallbackCandidates[#fallbackCandidates + 1] = {
                    definition = definition,
                    weight = self:_FeatWeight(ps, state, definition)
                }
            end
        end
        for _, definition in ipairs(weightedDraw(rng, fallbackCandidates, 3 - #selected)) do
            selected[#selected + 1] = definition
        end
    end
    assert(#selected == 3,
        "Gate C Level-" .. earnedAtLevel .. " feat draft could not produce three legal distinct offers")

    local draft = {
        earnedAtLevel = earnedAtLevel,
        draftType = "ordinary",
        offerFeatIds = {selected[1].featId, selected[2].featId, selected[3].featId},
        rngSeed = draftSeed,
        selectedFeatId = nil,
        resolved = false
    }
    state.pendingFeatSlots[slotIndex] = draft
    state.featSlotsGranted = math.max(state.featSlotsGranted or 0, slotIndex)
    return draft
end

function CharacterProgressionSystem:_GenerateLevelOneDraft(ps, state, campaignSeed)
    return self:_GenerateOrdinaryDraft(ps, state, campaignSeed, 1)
end

function CharacterProgressionSystem:_NextPendingOrdinaryDraft(state)
    for index = 1, #(RPG.OrdinaryFeatLevels or {}) do
        local draft = state and state.pendingFeatSlots and state.pendingFeatSlots[index]
        if draft and not draft.resolved then return draft, index end
    end
    return nil, nil
end

function CharacterProgressionSystem:_LatestOrdinaryDraft(state)
    for index = #(RPG.OrdinaryFeatLevels or {}), 1, -1 do
        local draft = state and state.pendingFeatSlots and state.pendingFeatSlots[index]
        if draft then return draft, index end
    end
    return nil, nil
end

function CharacterProgressionSystem:CommitClass(ply, classId)
    local runManager = LOD.RunManager
    local ps = runManager and runManager:GetPlayerState(ply)
    local state = ps and ps.progressionState
    local class = RPG.Classes[classId]
    if not state or not class or state.classId then return false, "Class is already committed or unavailable." end

    state.classId = classId
    state.progressionHitDieSides = class.heroProgressionHitDieSides
    local growthSeed = self:HeroGrowthProfileSeed(runManager.State.CampaignSeed, ps.identity, classId)
    local rng = LOD.RNG.New(derive(growthSeed, "level_1_growth_profile"))
    local favored = class.favoredAbilities
    state.primaryAbility = favored[rng:Int(1, 2)]
    state.secondaryAbilities = {state.primaryAbility == favored[1] and favored[2] or favored[1]}
    local outside = {}
    for _, ability in ipairs(ALL_ABILITIES) do
        if ability ~= favored[1] and ability ~= favored[2] then outside[#outside + 1] = ability end
    end
    state.secondaryAbilities[2] = outside[rng:Int(1, #outside)]

    self:_RecomputeProgressionState(state)
    self:_GenerateLevelOneDraft(ps, state, runManager.State.CampaignSeed)
    self:SyncPlayer(ply)
    return true
end

function CharacterProgressionSystem:_FindFeat(featId)
    local ordinaryFeats = Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats
    return ordinaryFeats[featId] or Catalog.FallbackFeats[featId]
end

function CharacterProgressionSystem:CommitFeat(ply, featId, expectedEarnedAtLevel)
    local runManager = LOD.RunManager
    local ps = runManager and runManager:GetPlayerState(ply)
    local state = ps and ps.progressionState
    local draft = state and self:_NextPendingOrdinaryDraft(state) or nil
    if not draft then return false, "No unresolved ordinary feat draft." end
    if expectedEarnedAtLevel ~= nil
        and tonumber(expectedEarnedAtLevel) ~= tonumber(draft.earnedAtLevel)
    then
        return false, "That choice belongs to a stale ordinary feat draft."
    end

    local offered = false
    for _, offeredId in ipairs(draft.offerFeatIds or {}) do
        if offeredId == featId then offered = true break end
    end
    local definition = offered and self:_FindFeat(featId) or nil
    if not definition then
        return false, "That feat is not a legal offer in the locked draft."
    end

    draft.selectedFeatId = featId
    draft.resolved = true
    if not arrayContains(state.featIds, featId) then state.featIds[#state.featIds + 1] = featId end
    state.featStackCounts[featId] = (state.featStackCounts[featId] or 0) + 1
    if definition.repeatableFallback and definition.effectHandlerId == "fallback_ability_delta" then
        local ability = definition.effectParams.ability
        state.featAbilityDelta[ability] = (state.featAbilityDelta[ability] or 0)
            + (tonumber(definition.effectParams.amount) or 1)
    end
    self:_RecomputeProgressionState(state)
    self:_ApplyPlayerMaxHP(ply, state)
    self:SyncPlayer(ply)
    return true
end

function CharacterProgressionSystem:_GenerateProgressionHitDie(ps, state, campaignSeed, level)
    if state.hitDieRollsByLevel[level] then return state.hitDieRollsByLevel[level] end
    local rolls = LOD.CombatRolls
    assert(rolls and rolls.RollProgressionHitDie,
        "combat-roll authority unavailable for progression hit die")
    local growthSeed = self:HeroGrowthProfileSeed(campaignSeed, ps.identity, state.classId)
    local rollSeed = derive(growthSeed, "progression_hit_die:level:" .. level)
    local roll = rolls:RollProgressionHitDie(rollSeed, state.progressionHitDieSides)
    roll.level = level
    state.hitDieRollsByLevel[level] = roll
    return roll
end

function CharacterProgressionSystem:_GenerateClassCapstoneDraft(state)
    if state.pendingClassCapstoneDraft then return state.pendingClassCapstoneDraft end
    local definitions = Catalog.ClassCapstones and Catalog.ClassCapstones[state.classId]
    local ids = sortedKeys(definitions or {})
    assert(#ids == 3, "Level-20 class requires exactly three fixed capstones")
    state.pendingClassCapstoneDraft = {
        earnedAtLevel = 20,
        draftType = "classCapstone",
        offerFeatIds = ids,
        rngSeed = nil,
        selectedFeatId = nil,
        resolved = false
    }
    return state.pendingClassCapstoneDraft
end

function CharacterProgressionSystem:CommitCapstone(ply, featId)
    local runManager = LOD.RunManager
    local ps = runManager and runManager:GetPlayerState(ply)
    local state = ps and ps.progressionState
    local draft = state and state.pendingClassCapstoneDraft
    if not draft or draft.resolved or state.level ~= 20 then
        return false, "No unresolved Level-20 class-capstone draft."
    end
    if not arrayContains(draft.offerFeatIds, featId) then
        return false, "That capstone is not in the locked class trio."
    end
    local definition = Catalog.ClassCapstones[state.classId]
        and Catalog.ClassCapstones[state.classId][featId]
    if not definition then return false, "Unknown class capstone." end

    draft.selectedFeatId = featId
    draft.resolved = true
    state.classCapstoneFeatId = featId
    self:_RecomputeProgressionState(state)
    self:_ApplyPlayerMaxHP(ply, state)
    self:SyncPlayer(ply)
    return true
end

function CharacterProgressionSystem:LevelForXP(xp)
    xp = math.Clamp(math.floor(tonumber(xp) or 0), 0, RPG.Constants.HeroMaxXP)
    local level = 1
    for candidate = 2, RPG.Constants.HeroMaxLevel do
        if xp < RPG.HeroXPThresholds[candidate] then break end
        level = candidate
    end
    return level
end

function CharacterProgressionSystem:HeroLevelForXPAtDungeon(xp, dungeonLevel)
    return math.min(self:LevelForXP(xp), self:EffectiveLevelCap("hero", dungeonLevel))
end

function CharacterProgressionSystem:AdvanceHeroToLevel(ply, targetLevel)
    local runManager = LOD.RunManager
    local ps = runManager and runManager:GetPlayerState(ply)
    local state = ps and ps.progressionState
    local dungeonLevel = runManager and runManager.State and runManager.State.Level or 1
    targetLevel = math.min(self:ClampLevel(targetLevel, "hero"),
        self:EffectiveLevelCap("hero", dungeonLevel))
    if not state or not state.classId then return false, "Class must be committed first." end
    if targetLevel < state.level then return false, "Character Level cannot decrease." end

    local startingLevel = state.level
    local authoredTarget = math.min(targetLevel, RPG.Constants.HeroMaxLevel)
    while state.level < authoredTarget do
        local nextLevel = state.level + 1
        state.level = nextLevel
        self:_GenerateProgressionHitDie(ps, state, runManager.State.CampaignSeed, nextLevel)
        self:_RecomputeProgressionState(state)
        local slotIndex = ordinarySlotIndexForLevel(nextLevel)
        if slotIndex then
            self:_GenerateOrdinaryDraft(ps, state, runManager.State.CampaignSeed, nextLevel)
        end
        if nextLevel == RPG.Constants.HeroMaxLevel then self:_GenerateClassCapstoneDraft(state) end
    end

    self:_ApplyPlayerMaxHP(ply, state)
    self:SyncPlayer(ply)
    if targetLevel > startingLevel and IsValid(ply) then
        ply:ChatPrint(string.format("LEVEL UP - %d to %d. Press P to review progression.",
            startingLevel, targetLevel))
    end
    return true
end

function CharacterProgressionSystem:SetHeroXP(ply, xp)
    local runManager = LOD.RunManager
    local ps = runManager and runManager:GetPlayerState(ply)
    local state = ps and ps.progressionState
    if not state then return false, "Hero progression state unavailable." end
    local requested = math.Clamp(math.floor(tonumber(xp) or 0), 0, RPG.Constants.HeroMaxXP)
    if requested < (state.xp or 0) then return false, "Campaign XP cannot decrease." end
    state.xp = requested
    local dungeonLevel = runManager and runManager.State and runManager.State.Level or 1
    return self:AdvanceHeroToLevel(ply, self:HeroLevelForXPAtDungeon(requested, dungeonLevel))
end

function CharacterProgressionSystem:AwardHeroXP(ply, amount)
    local runManager = LOD.RunManager
    local recipient = ply
    if isstring(ply) and runManager and runManager.IdentityOf then
        for _, candidate in ipairs(player.GetAll()) do
            if runManager:IdentityOf(candidate) == ply then
                recipient = candidate
                break
            end
        end
    end
    local ps = runManager and runManager:GetPlayerState(recipient)
    local state = ps and ps.progressionState
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if not state or amount <= 0 then return false, "No positive XP award." end
    return self:SetHeroXP(recipient, math.min(RPG.Constants.HeroMaxXP, (state.xp or 0) + amount))
end

function CharacterProgressionSystem:ProcessBankedHeroXP(runManager)
    runManager = runManager or LOD.RunManager
    if not runManager or not runManager.State then return 0 end
    local advanced = 0
    for identity, ps in pairs(runManager.State.PlayerState or {}) do
        local state = ps and ps.progressionState
        if state and (state.actorType == nil or state.actorType == "hero") and state.classId then
            state.actorType = "hero"
            local target = self:HeroLevelForXPAtDungeon(state.xp or 0, runManager.State.Level)
            if target > state.level then
                local before = state.level
                local ok = self:AdvanceHeroToLevel(identity, target)
                if ok then advanced = advanced + (state.level - before) end
            end
        end
    end
    return advanced
end

function CharacterProgressionSystem:ArchetypeProgressionTemplate(archetypeId)
    local id = string.lower(tostring(archetypeId or ""))
    id = RPG.ArchetypeProgressionAliases[id] or id
    return RPG.ArchetypeProgressionTemplates[id], id
end

function CharacterProgressionSystem:TierForRoll(roll)
    roll = math.Clamp(math.floor(tonumber(roll) or 1), 1, 100)
    if roll <= 60 then return "typical", 0 end
    if roll <= 90 then return "elite", 1 end
    return "champion", 2
end

function CharacterProgressionSystem:ResolveMonsterSpawnLevel(seed, dungeonLevel, archetypeId)
    local _, normalizedId = self:ArchetypeProgressionTemplate(archetypeId)
    local fixed = {
        neil = {"typical", 0},
        brute = {"elite", 1},
        warden = {"champion", 2}
    }
    local fixedTier = fixed[normalizedId]
    local tierId, offset
    if fixedTier then
        tierId, offset = fixedTier[1], fixedTier[2]
    else
        local tierRoll = LOD.RNG.New(derive(seed or 1, "monster_tier")):Int(1, 100)
        tierId, offset = self:TierForRoll(tierRoll)
    end
    local dungeon = math.max(1, math.floor(tonumber(dungeonLevel) or 1))
    local level = math.min(dungeon + offset,
        self:EffectiveLevelCap("ai", dungeon), RPG.Constants.MonsterMaxLevel)
    return level, tierId, offset
end

function CharacterProgressionSystem:_AssignAutomaticClass(template, seed)
    local weights = table.Copy(template.aiClassWeights or {})
    if template.usesMagic ~= true then weights.wizard = 0 end
    local total = 0
    for _, classId in ipairs({"fighter", "rogue", "wizard"}) do
        total = total + math.max(0, tonumber(weights[classId]) or 0)
    end
    assert(total > 0, "archetype requires at least one usable AI class")
    local roll = LOD.RNG.New(derive(seed, "automatic_class")):Int(1, total)
    local running = 0
    for _, classId in ipairs({"fighter", "rogue", "wizard"}) do
        running = running + math.max(0, tonumber(weights[classId]) or 0)
        if roll <= running then return classId end
    end
    return "fighter"
end

function CharacterProgressionSystem:_AssignAutomaticGrowthProfile(state, seed)
    local class = assert(RPG.Classes[state.classId], "automatic actor class missing")
    local rng = LOD.RNG.New(derive(seed, "automatic_growth_profile"))
    local favored = class.favoredAbilities
    state.primaryAbility = favored[rng:Int(1, #favored)]
    state.secondaryAbilities = {
        state.primaryAbility == favored[1] and favored[2] or favored[1]
    }
    local outside = {}
    for _, ability in ipairs(ALL_ABILITIES) do
        if ability ~= favored[1] and ability ~= favored[2] then
            outside[#outside + 1] = ability
        end
    end
    state.secondaryAbilities[2] = outside[rng:Int(1, #outside)]
end

function CharacterProgressionSystem:_AutomaticActorCapabilities(archetypeId, usesMagic)
    local tags = {"hit_stun_source", "pushable_weapon"}
    local ranged = {
        soldier = true, blitzer = true, sniper = true, flamer = true,
        sentry = true, razor = true, arccaster = true, beamsweeper = true,
        watcher = true, bioblaster = true, warden = true
    }
    if ranged[archetypeId] then
        tags[#tags + 1] = "firearm"
        tags[#tags + 1] = "reloadable_firearm"
    end
    if archetypeId == "soldier" or archetypeId == "blitzer" then
        tags[#tags + 1] = "multi_fire_burst"
    end
    if usesMagic then
        tags[#tags + 1] = "magic_pool"
        tags[#tags + 1] = "offensive_magic_activation"
    end
    return tags
end

function CharacterProgressionSystem:_GenerateAutomaticHitDie(state, actorSeed, level)
    if state.hitDieRollsByLevel[level] then return state.hitDieRollsByLevel[level] end
    local rolls = assert(LOD.CombatRolls, "combat-roll authority unavailable")
    local rollSeed = derive(actorSeed, "progression_hit_die:level:" .. tostring(level))
    local roll = rolls:RollProgressionHitDie(rollSeed, state.progressionHitDieSides)
    roll.level = level
    state.hitDieRollsByLevel[level] = roll
    return roll
end

function CharacterProgressionSystem:_CommitAutomaticFeat(ps, state, draft, actorSeed)
    local candidates = {}
    for _, featId in ipairs(draft.offerFeatIds or {}) do
        local definition = self:_FindFeat(featId)
        if definition then
            candidates[#candidates + 1] = {
                definition = definition,
                weight = self:_FeatWeight(ps, state, definition)
            }
        end
    end
    local rng = LOD.RNG.New(derive(actorSeed,
        "automatic_feat_selection:level:" .. tostring(draft.earnedAtLevel)))
    local definition = weightedDraw(rng, candidates, 1)[1]
    assert(definition, "automatic actor feat selection requires one legal offer")
    draft.selectedFeatId = definition.featId
    draft.resolved = true
    if not arrayContains(state.featIds, definition.featId) then
        state.featIds[#state.featIds + 1] = definition.featId
    end
    state.featStackCounts[definition.featId] =
        (state.featStackCounts[definition.featId] or 0) + 1
    if definition.repeatableFallback and definition.effectHandlerId == "fallback_ability_delta" then
        local ability = definition.effectParams and definition.effectParams.ability
        if ability then
            state.featAbilityDelta[ability] = (state.featAbilityDelta[ability] or 0)
                + (tonumber(definition.effectParams.amount) or 1)
        end
    end
end

function CharacterProgressionSystem:_CommitAutomaticCapstone(state, actorSeed)
    local definitions = Catalog.ClassCapstones and Catalog.ClassCapstones[state.classId] or {}
    local ids = sortedKeys(definitions)
    assert(#ids == 3, "automatic Level-20 actor requires three class capstones")
    local rng = LOD.RNG.New(derive(actorSeed, "automatic_capstone"))
    local selected = ids[rng:Int(1, #ids)]
    state.pendingClassCapstoneDraft = {
        earnedAtLevel = 20,
        draftType = "classCapstone",
        offerFeatIds = ids,
        rngSeed = derive(actorSeed, "automatic_capstone"),
        selectedFeatId = selected,
        resolved = true
    }
    state.classCapstoneFeatId = selected
end

-- Both ordinary AI actors and player-controlled Soldier incarnations use this
-- exact automatic path.  It deliberately owns no player/UI state: callers give
-- it an already-generated profile and a bounded target Level.
function CharacterProgressionSystem:AdvanceAutomaticActor(ps, state, actorSeed, targetLevel)
    if not state or not state.classId then return false, "automatic actor is uninitialized" end
    local ceiling = self:EffectiveLevelCap(state.actorType, state.dungeonLevel)
    targetLevel = math.min(math.max(1, math.floor(tonumber(targetLevel) or state.level)),
        ceiling, self:ActorHardLevelCap(state))
    while state.level < targetLevel do
        local level = state.level + 1
        state.level = level
        self:_GenerateAutomaticHitDie(state, actorSeed, level)
        self:_RecomputeProgressionState(state)
        if level <= RPG.Constants.HeroMaxLevel then
            local slotIndex = ordinarySlotIndexForLevel(level)
            if slotIndex then
                local draft = self:_GenerateOrdinaryDraft(ps, state, actorSeed, level)
                self:_CommitAutomaticFeat(ps, state, draft, actorSeed)
                self:_RecomputeProgressionState(state)
            end
            if level == RPG.Constants.HeroMaxLevel then
                self:_CommitAutomaticCapstone(state, actorSeed)
                self:_RecomputeProgressionState(state)
            end
        end
    end
    -- Numeric growth continues beyond 20, but no further slot/capstone work is
    -- legal there.  Preserve the linear hit-die fill and one final recompute so
    -- a legal Level-999 monster remains inexpensive to construct.
    if state.level < targetLevel then
        for level = state.level + 1, targetLevel do
            self:_GenerateAutomaticHitDie(state, actorSeed, level)
        end
        state.level = targetLevel
        self:_RecomputeProgressionState(state)
    end
    return true
end

function CharacterProgressionSystem:GenerateMonsterProgression(archetypeId, actorSeed,
    dungeonLevel, startingHP, actorType)
    local template, normalizedId = self:ArchetypeProgressionTemplate(archetypeId)
    if not template then return nil, "unknown progression archetype " .. tostring(archetypeId) end
    actorSeed = tonumber(actorSeed) or 1
    actorType = actorType == "human_soldier" and "human_soldier" or "ai"
    local assignedLevel, tierId = self:ResolveMonsterSpawnLevel(actorSeed, dungeonLevel, normalizedId)
    local state = self:NewProgressionState("monster:" .. tostring(actorSeed), normalizedId, actorType)
    state.tierId = tierId
    state.dungeonLevel = math.max(1, math.floor(tonumber(dungeonLevel) or 1))
    state.baseAbilities = copyAbilityBlock(template.baseAbilities)
    state.startingHP = math.max(1, math.floor(tonumber(startingHP) or 1))
    state.progressionHitDieSides = template.progressionHitDieSides
    state.moraleBonus = template.moraleBonus
    state.usesMagic = template.usesMagic == true
    state.capabilityTags = self:_AutomaticActorCapabilities(normalizedId, state.usesMagic)
    state.classId = self:_AssignAutomaticClass(template, actorSeed)
    self:_AssignAutomaticGrowthProfile(state, actorSeed)

    local ps = {identity = state.actorId}
    if normalizedId == "soldier" or normalizedId == "blitzer" then
        ps.starterWeaponClass = "weapon_smg1"
    end
    state.level = 1
    self:_RecomputeProgressionState(state)
    local levelOne = self:_GenerateOrdinaryDraft(ps, state, actorSeed, 1)
    self:_CommitAutomaticFeat(ps, state, levelOne, actorSeed)
    self:_RecomputeProgressionState(state)

    assert(self:AdvanceAutomaticActor(ps, state, actorSeed, assignedLevel))
    return state
end

function CharacterProgressionSystem:AttachMonsterProgression(hostile, actorSeed, dungeonLevel)
    if not IsValid(hostile) or not hostile.LODHostile then return nil end
    if hostile.LODProgressionState then return hostile.LODProgressionState end
    local state, err = self:GenerateMonsterProgression(hostile.LODArchetypeId, actorSeed,
        dungeonLevel, hostile:GetMaxHealth(), "ai")
    if not state then
        ErrorNoHalt("[LOD:RPG] " .. tostring(err) .. "\n")
        return nil
    end
    hostile.LODProgressionState = state
    hostile.LODCharacterLevel = state.level
    hostile.LODMonsterTier = state.tierId
    hostile:SetNW2Int("LOD_CharacterLevel", state.level)
    hostile:SetNW2String("LOD_MonsterTier", state.tierId)
    hostile:SetMaxHealth(state.derivedStats.maxHP)
    hostile:SetHealth(state.derivedStats.maxHP)
    return state
end

function CharacterProgressionSystem:ValidateActorProgressionCore()
    local errors = {}
    local function expect(condition, message)
        if not condition then errors[#errors + 1] = message end
    end

    expect(self:ActorHardLevelCap("hero") == 20, "Hero hard cap")
    expect(self:ActorHardLevelCap("ai") == 999, "monster hard cap")
    expect(self:EffectiveLevelCap("hero", 1) == 4, "Hero D+3 ceiling")
    expect(self:EffectiveLevelCap("ai", 1000) == 999, "monster 999 clamp")
    expect(self:HeroLevelForXPAtDungeon(48000, 1) == 4, "banked Hero XP blocked at D+3")
    expect(self:HeroLevelForXPAtDungeon(48000, 17) == 20, "banked Hero XP released")
    expect(RPG.Classes.wizard.heroProgressionHitDieSides == 4, "Wizard d4")
    expect(RPG.ArchetypeProgressionTemplates.soldier.progressionHitDieSides == 8, "Soldier d8")

    local tierCounts = {typical = 0, elite = 0, champion = 0}
    for roll = 1, 100 do
        local tier = self:TierForRoll(roll)
        tierCounts[tier] = (tierCounts[tier] or 0) + 1
    end
    expect(tierCounts.typical == 60 and tierCounts.elite == 30
        and tierCounts.champion == 10, "60/30/10 categorical tiers")

    local neilLevel, neilTier = self:ResolveMonsterSpawnLevel(1, 30, "neil")
    local bruteLevel, bruteTier = self:ResolveMonsterSpawnLevel(1, 30, "brute")
    local gordonLevel, gordonTier = self:ResolveMonsterSpawnLevel(1, 30, "gordon")
    expect(neilLevel == 30 and neilTier == "typical", "Neil fixed tier")
    expect(bruteLevel == 31 and bruteTier == "elite", "Brute fixed tier")
    expect(gordonLevel == 32 and gordonTier == "champion", "Gordon fixed tier")

    local first, firstErr = self:GenerateMonsterProgression("shambler", 8675309, 25, 40, "ai")
    local replay, replayErr = self:GenerateMonsterProgression("shambler", 8675309, 25, 40, "ai")
    expect(first ~= nil and replay ~= nil, firstErr or replayErr or "monster generation")
    if first and replay then
        local function fingerprint(state)
            local dice = {}
            for level = 2, state.level do
                dice[#dice + 1] = tostring(state.hitDieRollsByLevel[level]
                    and state.hitDieRollsByLevel[level].total or "missing")
            end
            return table.concat({
                state.tierId, state.level, state.classId, state.primaryAbility,
                table.concat(state.secondaryAbilities or {}, ","),
                table.concat(state.featIds or {}, ","),
                state.classCapstoneFeatId or "none",
                table.concat(dice, ","),
                state.derivedStats and state.derivedStats.maxHP or 0
            }, "|")
        end
        expect(fingerprint(first) == fingerprint(replay), "deterministic monster replay")
        expect(first.level >= 21 and first.level <= 28, "Level-21+ monster sample")
        local expectedGrowth = self:_GrowthAtLevel(first, first.level)
        for _, ability in ipairs(ALL_ABILITIES) do
            expect(first.growthAbilities[ability] == expectedGrowth[ability],
                "post-20 growth " .. ability)
        end
        local dieCount = 0
        for _ in pairs(first.hitDieRollsByLevel or {}) do dieCount = dieCount + 1 end
        expect(dieCount == first.level - 1, "post-20 progression hit dice")
        expect(first.featSlotsGranted == #RPG.OrdinaryFeatLevels, "no post-20 feat slots")
        expect(#(first.featIds or {}) <= #RPG.OrdinaryFeatLevels, "no post-20 feat grants")
        expect(first.classCapstoneFeatId ~= nil, "Level-20 monster capstone retained")
    end

    return #errors == 0, errors
end

function CharacterProgressionSystem:IsDeploymentEligible(ps)
    local state = ps and ps.progressionState
    local draft = state and state.pendingFeatSlots and state.pendingFeatSlots[1]
    return state ~= nil and state.classId ~= nil and draft ~= nil
        and draft.resolved == true and draft.selectedFeatId ~= nil
end

local function perkSnapshot(definition)
    return {
        tableType = definition.tableType,
        tableIndex = definition.tableIndex,
        categoryName = definition.categoryName,
        perkDisplayName = definition.perkDisplayName,
        flavorText = definition.flavorText,
        mechanicalEffect = definition.mechanicalEffect
    }
end

local function featSnapshot(definition, selected)
    return {
        featId = definition.featId,
        displayName = definition.displayName,
        governingAbilities = copyArray(definition.governingAbilities),
        eligibilityText = definition.eligibilityText,
        effect = concise(definition.effectParams and definition.effectParams.description, 320),
        repeatableFallback = definition.repeatableFallback == true,
        selected = selected == true
    }
end

local function capstoneSnapshot(definition, selected)
    return {
        featId = definition.featId,
        displayName = definition.displayName,
        effect = concise(definition.effectParams and definition.effectParams.description, 360),
        selected = selected == true
    }
end

function CharacterProgressionSystem:BuildClientSnapshot(ply)
    local runManager = LOD.RunManager
    local ps = runManager and runManager:GetPlayerState(ply)
    local state = ps and ps.progressionState
    local package = state and state.characterIdentityPackage
    if not package then return nil end

    local draft = self:_NextPendingOrdinaryDraft(state)
    if not draft then draft = self:_LatestOrdinaryDraft(state) end
    local offers = {}
    if draft then
        for _, featId in ipairs(draft.offerFeatIds or {}) do
            local definition = self:_FindFeat(featId)
            if definition then offers[#offers + 1] = featSnapshot(definition, draft.selectedFeatId == featId) end
        end
    end
    local selectedFeat = draft and draft.selectedFeatId and self:_FindFeat(draft.selectedFeatId) or nil
    local pendingFeatCount = 0
    local ordinaryFeatsCommitted = 0
    for _, ordinaryDraft in ipairs(state.pendingFeatSlots or {}) do
        if ordinaryDraft and ordinaryDraft.resolved then
            ordinaryFeatsCommitted = ordinaryFeatsCommitted + 1
        elseif ordinaryDraft then
            pendingFeatCount = pendingFeatCount + 1
        end
    end
    local ownedFeats = {}
    for _, featId in ipairs(state.featIds or {}) do
        local definition = self:_FindFeat(featId)
        if definition then
            local item = featSnapshot(definition, true)
            item.stackCount = state.featStackCounts[featId] or 1
            local ability = definition.repeatableFallback and definition.effectParams
                and definition.effectParams.ability or nil
            if ability then
                item.effect = string.format("Permanent +%d %s from this feat.",
                    item.stackCount, string.upper(ability))
            end
            ownedFeats[#ownedFeats + 1] = item
        end
    end

    local hitDieRolls = {}
    for level = 2, state.level do
        local roll = state.hitDieRollsByLevel[level]
        if roll then
            local conBonus = state.derivedStats.hpConBonusPerLevel or 0
            hitDieRolls[#hitDieRolls + 1] = {
                level = level,
                formula = roll.formula or ("d" .. tostring(state.progressionHitDieSides)),
                values = copyArray(roll.values),
                total = roll.total,
                conBonus = conBonus,
                hpGain = math.max(1, (roll.total or 0) + conBonus),
                capped = roll.capped == true
            }
        end
    end

    local capstoneDraft = state.pendingClassCapstoneDraft
    local capstoneOffers = {}
    local classCapstones = state.classId and Catalog.ClassCapstones
        and Catalog.ClassCapstones[state.classId] or nil
    for _, featId in ipairs(capstoneDraft and capstoneDraft.offerFeatIds or {}) do
        local definition = classCapstones and classCapstones[featId]
        if definition then
            capstoneOffers[#capstoneOffers + 1] = capstoneSnapshot(definition,
                capstoneDraft.selectedFeatId == featId)
        end
    end
    local selectedCapstone = classCapstones and state.classCapstoneFeatId
        and classCapstones[state.classCapstoneFeatId] or nil

    local roles = {}
    if state.primaryAbility then roles[state.primaryAbility] = "Primary Growth" end
    for _, ability in ipairs(state.secondaryAbilities or {}) do roles[ability] = "Secondary Growth" end
    for _, ability in ipairs(ALL_ABILITIES) do roles[ability] = roles[ability] or "Ordinary Growth" end

    local abilities = {}
    for _, ability in ipairs(ALL_ABILITIES) do
        local score = state.effectiveAbilities[ability] or 10
        abilities[#abilities + 1] = {
            id = ability,
            label = ABILITY_LABELS[ability],
            score = score,
            modifier = self:AbilityModifier(score),
            role = roles[ability],
            base = state.baseAbilities[ability] or 0,
            growth = state.growthAbilities[ability] or 0,
            fighterTraining = state.fighterTraining[ability] or 0,
            identity = state.identityAbilityDelta[ability] or 0,
            feat = self:PermanentFeatAbilityDelta(state, ability)
        }
    end

    local class = state.classId and RPG.Classes[state.classId] or nil
    local classPassive
    if state.classId == "fighter" then
        classPassive = string.format("Fighter Training: +%d STR / +%d CON at Level %d; training alternates from %s.",
            state.fighterTraining.str or 0, state.fighterTraining.con or 0,
            state.level, string.upper(state.primaryAbility))
    elseif state.classId == "rogue" then
        classPassive = "Exploding-Dice Mastery: all actor-owned damage dice can explode; d6 and SUPER-d12 thresholds improve."
    elseif state.classId == "wizard" then
        classPassive = string.format("Arcane Diversion: %d%% of otherwise-final HP damage is diverted to Magic when available.",
            math.floor((state.derivedStats.wizardClassHpToMagicDiversionFraction or 0) * 100 + 0.5))
    end

    local ammoRegenFamilies = {}
    local ammo = LOD.DiceAmmo
    if ammo and ammo.RegenProfileSnapshot then
        ammoRegenFamilies = ammo:RegenProfileSnapshot(ply)
    end

    return {
        gate = RPG.ImplementationGate,
        schemaVersion = RPG.SchemaVersion,
        fullDisplayName = package.fullDisplayName,
        firstName = package.firstName,
        surname = package.surname,
        nickname = package.nickname,
        portraitCacheKey = package.portraitCacheKey,
        model = ps.model,
        avatarDescriptor = ps.characterName,
        presentationSex = package.presentationSex,
        level = state.level,
        xp = state.xp,
        xpForCurrentLevel = RPG.HeroXPThresholds[state.level],
        xpForNextLevel = state.level < RPG.Constants.HeroMaxLevel
            and RPG.HeroXPThresholds[state.level + 1] or nil,
        startingHP = state.startingHP,
        maxHP = state.derivedStats.maxHP,
        currentHP = IsValid(ply) and ply:Health() or state.derivedStats.maxHP,
        lives = ps.lives,
        dungeonLevel = runManager.State.Level,
        classId = state.classId,
        className = class and class.displayName or nil,
        classHitDie = class and class.heroProgressionHitDieSides or nil,
        classPassive = classPassive,
        primaryAbility = state.primaryAbility,
        secondaryAbilities = copyArray(state.secondaryAbilities),
        abilities = abilities,
        hitDieRolls = hitDieRolls,
        hpConBonusPerLevel = state.derivedStats.hpConBonusPerLevel,
        rolledHitPointSubtotal = state.derivedStats.rolledHitPointSubtotal,
        healthRegenEnabled = state.derivedStats.healthRegenEnabled == true,
        healthRegenRank = state.derivedStats.healthRegenRank,
        healthRegenCeilingFraction = state.derivedStats.healthRegenCeilingFraction,
        healthRegenRatePerSecond = (state.derivedStats.maxHP or 0)
            * (state.derivedStats.healthRegenBaseMaxHPPerSecond or 0)
            * (state.derivedStats.conRegenMultiplier or 1),
        breadcrumbCells = LOD.RPGAbilityRules and LOD.RPGAbilityRules:BreadcrumbCells(ply)
            or state.derivedStats.breadcrumbCells,
        breadcrumbFeatRank = state.derivedStats.breadcrumbFeatRank,
        breadcrumbFeatBonusCells = state.derivedStats.breadcrumbFeatBonusCells,
        frugalMapEnabled = state.derivedStats.frugalMapEnabled == true,
        mapDrainFeatMultiplier = state.derivedStats.mapDrainFeatMultiplier,
        mapDrainRatePerSecond = LOD.RPGAbilityRules
            and LOD.RPGAbilityRules:MapDrainPerSecond(ply, 100 / 15)
            or (100 / 15) * (state.derivedStats.utilityMagicCostMultiplier or 1),
        ammoRegenFloorRank = state.derivedStats.ammoRegenFloorRank,
        ammoRegenFloorFraction = state.derivedStats.ammoRegenFloorFraction,
        ammoRegenFamilies = ammoRegenFamilies,
        identityTraits = {
            perkSnapshot(Catalog.Origins[package.originIndex]),
            perkSnapshot(Catalog.Backgrounds[package.backgroundIndex]),
            perkSnapshot(Catalog.Motives[package.motiveIndex])
        },
        featDraft = draft and {
            earnedAtLevel = draft.earnedAtLevel,
            draftType = draft.draftType,
            rngSeed = draft.rngSeed,
            resolved = draft.resolved,
            selectedFeatId = draft.selectedFeatId,
            offers = offers
        } or nil,
        pendingFeatCount = pendingFeatCount,
        featSlotsGranted = state.featSlotsGranted,
        ordinaryFeatsCommitted = ordinaryFeatsCommitted,
        ownedFeats = ownedFeats,
        selectedFeat = selectedFeat and featSnapshot(selectedFeat, true) or nil,
        capstoneDraft = capstoneDraft and {
            earnedAtLevel = 20,
            draftType = "classCapstone",
            resolved = capstoneDraft.resolved,
            selectedFeatId = capstoneDraft.selectedFeatId,
            offers = capstoneOffers
        } or nil,
        selectedCapstone = selectedCapstone and capstoneSnapshot(selectedCapstone, true) or nil,
        requiredChoicesComplete = self:IsDeploymentEligible(ps),
        deploymentComplete = ps.deploymentComplete == true
    }
end

function CharacterProgressionSystem:SyncPlayer(ply)
    if not IsValid(ply) then return end
    if LOD.RPGAbilityRules and LOD.RPGAbilityRules.SyncPlayer then
        LOD.RPGAbilityRules:SyncPlayer(ply)
    end
    local featEffects = RPG.FeatEffectSystem
    if featEffects and featEffects.TrackActor then featEffects:TrackActor(ply, false) end
    local snapshot = self:BuildClientSnapshot(ply)
    if not snapshot then return end
    net.Start("LOD_RPG_Snapshot")
    net.WriteTable(snapshot)
    net.Send(ply)
end

function CharacterProgressionSystem:PlayerCharacterText(ply)
    if not IsValid(ply) then return "Unknown player" end
    local ps = LOD.RunManager and LOD.RunManager:GetPlayerState(ply)
    local package = ps and ps.progressionState and ps.progressionState.characterIdentityPackage
    if not package then return ply:Nick() end
    return string.format("%s as %s", ply:Nick(), package.fullDisplayName)
end

net.Receive("LOD_RPG_RequestSheet", function(_, ply)
    if not IsValid(ply) then return end
    local now = CurTime()
    if (ply.LODNextRPGSheetRequest or 0) > now then return end
    ply.LODNextRPGSheetRequest = now + 0.10
    CharacterProgressionSystem:SyncPlayer(ply)
end)

net.Receive("LOD_RPG_ChooseClass", function(_, ply)
    if not IsValid(ply) then return end
    local classId = string.lower(net.ReadString() or "")
    local ok, err = CharacterProgressionSystem:CommitClass(ply, classId)
    if not ok and err then
        ply:ChatPrint("RPG - " .. err)
        CharacterProgressionSystem:SyncPlayer(ply)
    end
end)

net.Receive("LOD_RPG_ChooseFeat", function(_, ply)
    if not IsValid(ply) then return end
    local featId = net.ReadString() or ""
    local earnedAtLevel = net.ReadUInt(5)
    local ok, err = CharacterProgressionSystem:CommitFeat(ply, featId, earnedAtLevel)
    if not ok and err then
        ply:ChatPrint("RPG - " .. err)
        CharacterProgressionSystem:SyncPlayer(ply)
    end
end)

net.Receive("LOD_RPG_ChooseCapstone", function(_, ply)
    if not IsValid(ply) then return end
    local featId = net.ReadString() or ""
    local ok, err = CharacterProgressionSystem:CommitCapstone(ply, featId)
    if not ok and err then
        ply:ChatPrint("RPG - " .. err)
        CharacterProgressionSystem:SyncPlayer(ply)
    end
end)

hook.Add("PlayerSpawn", "LOD_RPGGateCSyncOnSpawn", function(ply)
    timer.Simple(0, function()
        if IsValid(ply) then CharacterProgressionSystem:SyncPlayer(ply) end
    end)
end)

local function countKeys(values)
    local count = 0
    for _ in pairs(values or {}) do count = count + 1 end
    return count
end

function CharacterProgressionSystem:ValidateGateBPlayer(ply)
    local errors, perkNames = {}, {}
    for label, definitions in pairs({
        Origin = Catalog.Origins, Background = Catalog.Backgrounds, Motive = Catalog.Motives
    }) do
        if countKeys(definitions) ~= 64 then errors[#errors + 1] = label .. " count" end
        for index = 1, 64 do
            local definition = definitions[index]
            if not definition or definition.tableIndex ~= index then
                errors[#errors + 1] = label .. " index " .. index
            elseif perkNames[definition.perkDisplayName] then
                errors[#errors + 1] = "duplicate perk " .. definition.perkDisplayName
            else
                perkNames[definition.perkDisplayName] = true
            end
        end
    end
    for label, values in pairs({
        Masculine = Catalog.MasculineFirstNames, Feminine = Catalog.FeminineFirstNames,
        Surname = Catalog.Surnames, Nickname = Catalog.Nicknames
    }) do
        if countKeys(values) ~= 64 then errors[#errors + 1] = label .. " name count" end
    end
    if countKeys(perkNames) ~= 192 then errors[#errors + 1] = "perk uniqueness count" end

    local ps = IsValid(ply) and LOD.RunManager:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState
    local package = state and state.characterIdentityPackage
    local draft = state and state.pendingFeatSlots[1]
    if not package then errors[#errors + 1] = "player identity missing" end
    if not state or state.level ~= 1 or state.startingHP ~= 100 then errors[#errors + 1] = "Level-1 state mismatch" end
    if not state or not state.classId then
        errors[#errors + 1] = "class pending"
    else
        if not RPG.Classes[state.classId] then errors[#errors + 1] = "class invalid" end
        if not draft or #draft.offerFeatIds ~= 3 then errors[#errors + 1] = "draft count" end
        local seen = {}
        for _, featId in ipairs(draft and draft.offerFeatIds or {}) do
            if seen[featId] then errors[#errors + 1] = "duplicate draft offer" end
            seen[featId] = true
            if not self:_FindFeat(featId) then errors[#errors + 1] = "unknown draft offer" end
        end
        if draft and draft.resolved and not seen[draft.selectedFeatId] then errors[#errors + 1] = "selected feat not offered" end
        if not draft or not draft.resolved or not draft.selectedFeatId then
            errors[#errors + 1] = "Level-1 feat pending"
        end
    end

    local fingerprint = draft and util.CRC(table.concat(draft.offerFeatIds, "|") .. ":" .. tostring(draft.rngSeed)) or "none"
    return #errors == 0, errors, fingerprint
end

concommand.Add("lod_rpg_gate_b_validate", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local developerMode = GetConVar("lod_developer_mode")
    if not developerMode or not developerMode:GetBool() then
        if IsValid(ply) then ply:ChatPrint("Gate B validation requires lod_developer_mode 1 at startup.") end
        return
    end
    local target = IsValid(ply) and ply or player.GetAll()[1]
    local ok, errors, fingerprint = CharacterProgressionSystem:ValidateGateBPlayer(target)
    local ps = IsValid(target) and LOD.RunManager:GetPlayerState(target) or nil
    local state = ps and ps.progressionState
    local draft = state and state.pendingFeatSlots[1]
    local line = string.format(
        "Gate B validation %s - identity=%s class=%s draft=%s selected=%s eligible=%s fingerprint=%s rosterSeed=%s",
        ok and "PASS" or "FAILED",
        tostring(state and state.characterIdentityPackage and state.characterIdentityPackage.fullDisplayName or "missing"),
        tostring(state and state.classId or "pending"),
        tostring(draft and table.concat(draft.offerFeatIds, ",") or "pending"),
        tostring(draft and draft.selectedFeatId or "pending"),
        tostring(CharacterProgressionSystem:IsDeploymentEligible(ps)),
        tostring(fingerprint),
        tostring(LOD.RunManager and LOD.RunManager.State and LOD.RunManager.State.RosterSeed or "missing")
    )
    print("[LOD:RPG] " .. line)
    for _, err in ipairs(errors) do ErrorNoHalt("[LOD:RPG] Gate B: " .. err .. "\n") end
    if IsValid(ply) then ply:ChatPrint(line) end
end)

local function developerCommandPlayer(ply, commandName)
    if IsValid(ply) and not ply:IsAdmin() then return nil end
    local developerMode = GetConVar("lod_developer_mode")
    if not developerMode or not developerMode:GetBool() then
        if IsValid(ply) then ply:ChatPrint(commandName .. " requires lod_developer_mode 1 at startup.") end
        return nil
    end
    return IsValid(ply) and ply or player.GetAll()[1]
end

concommand.Add("lod_rpg_gate_c_level", function(ply, _, args)
    local target = developerCommandPlayer(ply, "lod_rpg_gate_c_level")
    if not IsValid(target) then return end
    local requestedLevel = CharacterProgressionSystem:ClampLevel(args and args[1])
    local ps = LOD.RunManager:GetPlayerState(target)
    if not CharacterProgressionSystem:IsDeploymentEligible(ps) then
        target:ChatPrint("Complete the Level-1 class and feat choices before accelerating progression.")
        return
    end
    if requestedLevel < ps.progressionState.level then
        target:ChatPrint("Gate C acceleration cannot reduce Character Level.")
        return
    end
    LOD.RunManager:MarkUnranked("Gate C developer level acceleration")
    local ok, err = CharacterProgressionSystem:SetHeroXP(target,
        RPG.HeroXPThresholds[requestedLevel])
    if not ok then
        target:ChatPrint("Gate C acceleration failed: " .. tostring(err))
        return
    end
    target:ChatPrint(string.format(
        "Gate C snapshot ready: Level %d / XP %d / press P.",
        ps.progressionState.level, ps.progressionState.xp))
end)

function CharacterProgressionSystem:ValidateGateCPlayer(ply)
    local errors = {}
    local ps = IsValid(ply) and LOD.RunManager:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState
    if not state or not state.classId then return false, {"progression/class missing"}, "none" end

    local level = state.level
    if level < 1 or level > 20 then errors[#errors + 1] = "level bounds" end
    if (state.xp or 0) < (RPG.HeroXPThresholds[level] or 0) then errors[#errors + 1] = "XP below level" end
    if level < 20 and (state.xp or 0) >= RPG.HeroXPThresholds[level + 1] then
        errors[#errors + 1] = "XP level not advanced"
    end

    local expectedGrowth = self:_GrowthAtLevel(state, level)
    local expectedTraining = self:_FighterTrainingAtLevel(state, level)
    for _, ability in ipairs(ALL_ABILITIES) do
        if state.growthAbilities[ability] ~= expectedGrowth[ability] then
            errors[#errors + 1] = "growth " .. ability
        end
        if state.fighterTraining[ability] ~= expectedTraining[ability] then
            errors[#errors + 1] = "Fighter Training " .. ability
        end
    end

    local hitFingerprints = {}
    local rolledSubtotal, expectedCoreHP = 0, state.startingHP or 100
    local conBonus = state.derivedStats.hpConBonusPerLevel or 0
    for gainedLevel = 2, level do
        local roll = state.hitDieRollsByLevel[gainedLevel]
        if not roll then
            errors[#errors + 1] = "hit die missing L" .. gainedLevel
        else
            local replay = LOD.CombatRolls:RollProgressionHitDie(roll.seed, state.progressionHitDieSides)
            if replay.total ~= roll.total or table.concat(replay.values, ",") ~= table.concat(roll.values, ",") then
                errors[#errors + 1] = "hit die nondeterministic L" .. gainedLevel
            end
            rolledSubtotal = rolledSubtotal + (roll.total or 0)
            expectedCoreHP = expectedCoreHP + math.max(1, (roll.total or 0) + conBonus)
            hitFingerprints[#hitFingerprints + 1] = gainedLevel .. ":"
                .. table.concat(roll.values or {}, "+")
        end
    end
    if countKeys(state.hitDieRollsByLevel) ~= math.max(0, level - 1) then
        errors[#errors + 1] = "hit die count"
    end
    if state.derivedStats.rolledHitPointSubtotal ~= rolledSubtotal then
        errors[#errors + 1] = "rolled HP subtotal"
    end
    if state.derivedStats.coreMaxHP ~= expectedCoreHP then errors[#errors + 1] = "CoreMaxHP" end
    local hpMultiplier = state.classCapstoneFeatId == "FTR_CAP_BUILT_DIFFERENT" and 1.25 or 1
    local expectedMaxHP = math.floor(expectedCoreHP * hpMultiplier + 0.5)
    if state.derivedStats.maxHP ~= expectedMaxHP then errors[#errors + 1] = "MaxHP" end

    local expectedSlots = 0
    for index, featLevel in ipairs(RPG.OrdinaryFeatLevels) do
        if featLevel <= level then
            expectedSlots = index
            local draft = state.pendingFeatSlots[index]
            if not draft or draft.earnedAtLevel ~= featLevel or #draft.offerFeatIds ~= 3 then
                errors[#errors + 1] = "ordinary draft L" .. featLevel
            else
                local seen = {}
                for _, featId in ipairs(draft.offerFeatIds) do
                    if seen[featId] then errors[#errors + 1] = "duplicate offer L" .. featLevel end
                    seen[featId] = true
                    if not self:_FindFeat(featId) then errors[#errors + 1] = "unknown offer " .. featId end
                end
                if not draft.resolved or not seen[draft.selectedFeatId] then
                    errors[#errors + 1] = "pending selection L" .. featLevel
                end
            end
        end
    end
    if state.featSlotsGranted ~= expectedSlots then errors[#errors + 1] = "feat slot cadence" end

    local capstone = state.pendingClassCapstoneDraft
    if level == 20 then
        local expected = sortedKeys(Catalog.ClassCapstones[state.classId] or {})
        if not capstone or #capstone.offerFeatIds ~= 3
            or table.concat(capstone.offerFeatIds, "|") ~= table.concat(expected, "|")
        then
            errors[#errors + 1] = "class capstone trio"
        elseif not capstone.resolved or not arrayContains(capstone.offerFeatIds, state.classCapstoneFeatId) then
            errors[#errors + 1] = "class capstone pending"
        end
    elseif capstone or state.classCapstoneFeatId then
        errors[#errors + 1] = "early class capstone"
    end

    local fingerprint = util.CRC(table.concat(hitFingerprints, "|") .. ":"
        .. tostring(state.derivedStats.maxHP) .. ":" .. tostring(state.featSlotsGranted)
        .. ":" .. tostring(state.classCapstoneFeatId or "none"))
    return #errors == 0, errors, fingerprint
end

concommand.Add("lod_rpg_gate_c_validate", function(ply)
    local target = developerCommandPlayer(ply, "lod_rpg_gate_c_validate")
    if not IsValid(target) then return end
    local ok, errors, fingerprint = CharacterProgressionSystem:ValidateGateCPlayer(target)
    local ps = LOD.RunManager:GetPlayerState(target)
    local state = ps and ps.progressionState
    local line = string.format(
        "Gate C validation %s - Level=%s XP=%s MaxHP=%s hitDice=%s featSlots=%s capstone=%s fingerprint=%s",
        ok and "PASS" or "FAILED", tostring(state and state.level or "missing"),
        tostring(state and state.xp or "missing"),
        tostring(state and state.derivedStats and state.derivedStats.maxHP or "missing"),
        tostring(state and countKeys(state.hitDieRollsByLevel) or 0),
        tostring(state and state.featSlotsGranted or 0),
        tostring(state and state.classCapstoneFeatId or "pending"), tostring(fingerprint))
    print("[LOD:RPG] " .. line)
    for _, err in ipairs(errors) do ErrorNoHalt("[LOD:RPG] Gate C: " .. err .. "\n") end
    if IsValid(ply) then ply:ChatPrint(line) end
end)

CharacterProgressionSystem.GateAScaffoldReady = true
CharacterProgressionSystem.GateBReady = true
CharacterProgressionSystem.GateCReady = true
