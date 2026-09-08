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

local SOURCE_REVISION = "ANLCKQlapECu8CFLXSznFQ2lgvQ8M8VlvQhJ6jUmVhQbn2lCBBwIhl7vSnqoITG_UgVn6lRA023z123S2E8aBALkwBAko20hUtbYAf053Q"
local HITSTUN_FAMILY = "cha_hitstun_presence"
local HITSTUN_CHAIN = {"CHA_HITSTUN_1", "CHA_HITSTUN_2", "CHA_HITSTUN_3"}
local HITSTUN_RANK = {CHA_HITSTUN_1 = 1, CHA_HITSTUN_2 = 2, CHA_HITSTUN_3 = 3}
local HITSTUN_MULTIPLIER = {[1] = 1.10, [2] = 1.20, [3] = 1.30}
local UTILITY_IDS = {
    CHA_ACADEMIC_ACHIEVEMENT = true,
    CHA_WINNING_PERSONALITY = true
}

Effects.CharismaConfig = {
    sourceRevision = SOURCE_REVISION,
    hitStunFamily = HITSTUN_FAMILY,
    hitStunChain = HITSTUN_CHAIN,
    hitStunMultiplierByRank = HITSTUN_MULTIPLIER
}
Effects.CharismaStats = Effects.CharismaStats or {
    hitStunMultiplierQueries = 0,
    lastBaseHitStunMultiplier = 1,
    lastFeatHitStunMultiplier = 1,
    lastFinalHitStunMultiplier = 1
}

local function owns(state, id)
    for _, value in ipairs(state and state.featIds or {}) do
        if value == id then return true end
    end
    return false
end

local function hitStunDefinition(id, name, requirement, prerequisite, rank, multiplier)
    return {
        featId = id,
        displayName = name,
        featFamilyId = HITSTUN_FAMILY,
        rankIndex = rank,
        replacesLowerRank = rank > 1,
        repeatableFallback = false,
        governingAbilities = {"cha"},
        abilityRequirements = {cha = requirement},
        prerequisiteFeatIds = prerequisite and {prerequisite} or {},
        requiredCapabilityTags = {"hit_stun_source"},
        incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"},
        requiredSubsystemTags = {},
        synergyTags = {"hit_stun", "charisma"},
        oneRank = true,
        effectHandlerId = "cha_hitstun_presence",
        effectParams = {
            featHitStunMultiplier = multiplier,
            description = string.format(
                "After the ordinary CHA hit-stun multiplier is calculated, multiplies eligible hit stun inflicted by this actor by %.2f total. Higher ranks replace lower ranks; ordinary retrigger guards, defender resistance, anti-stunlock rules, and hard caps remain authoritative.",
                multiplier)
        },
        directorBaseWeight = 1.0,
        eligibilityText = string.format("CHA %d%s", requirement,
            prerequisite and (" / requires " .. prerequisite) or ""),
        actorText = "Heroes, human Soldiers, and AI with an eligible hit-stun source"
    }
end

local function charismaSingleton(id, name, requirement, capability, family, handler,
    description)
    return {
        featId = id,
        displayName = name,
        featFamilyId = family,
        rankIndex = 1,
        replacesLowerRank = false,
        repeatableFallback = false,
        governingAbilities = {"cha"},
        abilityRequirements = {cha = requirement},
        prerequisiteFeatIds = {},
        requiredCapabilityTags = capability and {capability} or {},
        incompatibleFeatIds = {},
        allowedActorTypes = {"hero", "human_soldier", "ai"},
        requiredSubsystemTags = {},
        synergyTags = {family, "charisma"},
        oneRank = true,
        effectHandlerId = handler,
        effectParams = {description = description},
        directorBaseWeight = 1.0,
        eligibilityText = string.format("CHA %d%s", requirement,
            capability and (" / " .. capability) or ""),
        actorText = "Heroes, human Soldiers, and AI"
    }
end

Feats.CHA_HITSTUN_1 = hitStunDefinition(
    "CHA_HITSTUN_1", "Unnerving Presence", 13, nil, 1, 1.10)
Feats.CHA_HITSTUN_2 = hitStunDefinition(
    "CHA_HITSTUN_2", "Dazing Presence", 15, "CHA_HITSTUN_1", 2, 1.20)
Feats.CHA_HITSTUN_3 = hitStunDefinition(
    "CHA_HITSTUN_3", "Overwhelming Presence", 17, "CHA_HITSTUN_2", 3, 1.30)

Feats.CHA_ACADEMIC_ACHIEVEMENT = charismaSingleton(
    "CHA_ACADEMIC_ACHIEVEMENT", "Academic Achievement", 15, "magic_pool",
    "cha_academic_achievement", "academic_magic_regeneration",
    "Adds max(0, CHA_MOD) to INT_MOD only for the canonical passive Magic-regeneration calculation. This does not enable suspended regeneration, raise Max Magic, alter active costs, map drain, spell damage, saves, or any other INT/CHA rule.")

Feats.CHA_WINNING_PERSONALITY = charismaSingleton(
    "CHA_WINNING_PERSONALITY", "Winning Personality", 17, nil,
    "cha_winning_personality", "winning_personality_qualification",
    "Permanently grants +1 intrinsic CHA, subject to the ordinary ability ceiling. For the printed ability-score prerequisite of INT-prefixed feats only, uses max(INT, CHA) after that increase. Actual INT and INT_MOD remain unchanged, and every prerequisite, restriction, capability, class exclusion, and availability rule remains authoritative.")

Catalog.OrdinaryFeats = Feats
Catalog.GateECharismaSourceRevisionId = SOURCE_REVISION

function Effects:CharismaProfile(state)
    local rank = 0
    for id, value in pairs(HITSTUN_RANK) do
        if value > rank and owns(state, id) then rank = value end
    end
    return {
        hitStunRank = rank,
        hitStunFeatId = rank > 0 and HITSTUN_CHAIN[rank] or nil,
        featHitStunMultiplier = HITSTUN_MULTIPLIER[rank] or 1,
        academicAchievement = owns(state, "CHA_ACADEMIC_ACHIEVEMENT"),
        winningPersonality = owns(state, "CHA_WINNING_PERSONALITY")
    }
end

function Effects:AcademicMagicRegenMultiplier(intMod, chaMod, enabled)
    local effective = (tonumber(intMod) or 0)
        + (enabled and math.max(0, tonumber(chaMod) or 0) or 0)
    return math.Clamp(1 + 0.10 * effective, 0.50, 2.00), effective
end

if not Effects.LODGateECharismaApplyDerivedWrapped then
    Effects.LODGateECharismaApplyDerivedWrapped = true
    local base = Effects.ApplyDerived
    function Effects:ApplyDerived(state, derived)
        base(self, state, derived)
        local profile = self:CharismaProfile(state)
        derived.featHitStunRank = profile.hitStunRank
        derived.featHitStunMultiplier = profile.featHitStunMultiplier
        derived.academicAchievementEnabled = profile.academicAchievement
        derived.academicRegenCHAContribution = profile.academicAchievement
            and math.max(0, tonumber(derived.chaMod) or 0) or 0
        derived.magicRegenMultiplier, derived.effectiveMagicRegenModifier =
            self:AcademicMagicRegenMultiplier(derived.intMod, derived.chaMod,
                profile.academicAchievement)
        derived.winningPersonalityEnabled = profile.winningPersonality
    end
end

if not Rules.LODGateECharismaHitStunWrapped then
    Rules.LODGateECharismaHitStunWrapped = true
    local base = Rules.HitStunMultiplier
    function Rules:HitStunMultiplier(attacker, defender)
        local ordinary = base(self, attacker, defender)
        local attack = self:Derived(attacker)
        local featMultiplier = math.Clamp(
            tonumber(attack and attack.featHitStunMultiplier) or 1, 1, 1.30)
        local final = ordinary * featMultiplier
        local stats = Effects.CharismaStats
        stats.hitStunMultiplierQueries = (stats.hitStunMultiplierQueries or 0) + 1
        stats.lastBaseHitStunMultiplier = ordinary
        stats.lastFeatHitStunMultiplier = featMultiplier
        stats.lastFinalHitStunMultiplier = final
        return final
    end
end

local function isINTFeat(definition)
    return definition and string.sub(tostring(definition.featId or ""), 1, 4) == "INT_"
end

function Effects:WinningPersonalityQualificationScore(state)
    local scores = state and state.featQualificationAbilities or {}
    local intelligence = tonumber(scores.int) or 0
    if not owns(state, "CHA_WINNING_PERSONALITY") then return intelligence end
    return math.max(intelligence, tonumber(scores.cha) or 0)
end

if not Progression.LODGateEWinningPersonalityWrapped then
    Progression.LODGateEWinningPersonalityWrapped = true
    local base = Progression._FeatEligible
    function Progression:_FeatEligible(ps, state, definition)
        if not isINTFeat(definition) or not owns(state, "CHA_WINNING_PERSONALITY") then
            return base(self, ps, state, definition)
        end
        local proxy = {}
        for key, value in pairs(state or {}) do proxy[key] = value end
        proxy.featQualificationAbilities = {}
        for ability, score in pairs(state.featQualificationAbilities or {}) do
            proxy.featQualificationAbilities[ability] = score
        end
        proxy.featQualificationAbilities.int =
            Effects:WinningPersonalityQualificationScore(state)
        return base(self, ps, proxy, definition)
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
    "featHitStunRank", "academicAchievementEnabled",
    "academicRegenCHAContribution", "effectiveMagicRegenModifier",
    "winningPersonalityEnabled"
}) do
    addSchemaField(field)
end

if not Progression.LODGateECharismaSnapshotWrapped then
    Progression.LODGateECharismaSnapshotWrapped = true
    local base = Progression.BuildClientSnapshot
    function Progression:BuildClientSnapshot(ply)
        local snapshot = base(self, ply)
        if not snapshot then return nil end
        local state = Rules:ProgressionState(ply)
        local derived = state and state.derivedStats or {}
        snapshot.featHitStunRank = derived.featHitStunRank or 0
        snapshot.featHitStunMultiplier = derived.featHitStunMultiplier or 1
        snapshot.academicAchievementEnabled = derived.academicAchievementEnabled == true
        snapshot.academicRegenCHAContribution = derived.academicRegenCHAContribution or 0
        snapshot.effectiveMagicRegenModifier = derived.effectiveMagicRegenModifier
            or derived.intMod or 0
        snapshot.winningPersonalityEnabled = derived.winningPersonalityEnabled == true
        snapshot.effectiveINTFeatQualificationScore =
            Effects:WinningPersonalityQualificationScore(state)
        return snapshot
    end
end

function Effects:ValidateCharismaFamilies()
    local errors = {}
    local function expect(ok, message)
        if not ok then errors[#errors + 1] = message end
    end
    local expected = {
        CHA_HITSTUN_1 = {1, 13, nil, 1.10},
        CHA_HITSTUN_2 = {2, 15, "CHA_HITSTUN_1", 1.20},
        CHA_HITSTUN_3 = {3, 17, "CHA_HITSTUN_2", 1.30}
    }
    for id, values in pairs(expected) do
        local feat = Feats[id]
        expect(feat and feat.featFamilyId == HITSTUN_FAMILY, id .. " family")
        if feat then
            expect(feat.rankIndex == values[1], id .. " rank")
            expect(feat.replacesLowerRank == (values[1] > 1), id .. " replacement")
            expect(feat.abilityRequirements.cha == values[2], id .. " CHA requirement")
            expect((feat.prerequisiteFeatIds or {})[1] == values[3], id .. " prerequisite")
            expect(feat.effectParams.featHitStunMultiplier == values[4], id .. " multiplier")
        end
    end

    local hit0 = self:CharismaProfile({featIds = {}})
    local hit3 = self:CharismaProfile({featIds = HITSTUN_CHAIN})
    expect(hit0.hitStunRank == 0 and hit0.featHitStunMultiplier == 1,
        "baseline hit-stun profile")
    expect(hit3.hitStunRank == 3 and hit3.featHitStunMultiplier == 1.30,
        "Overwhelming Presence replaces lower ranks")

    local academic = Feats.CHA_ACADEMIC_ACHIEVEMENT
    expect(academic and academic.abilityRequirements.cha == 15,
        "Academic Achievement CHA 15")
    expect(academic and (academic.requiredCapabilityTags or {})[1] == "magic_pool",
        "Academic Achievement Magic-pool capability")
    local regen, effective = self:AcademicMagicRegenMultiplier(1, 3, true)
    expect(math.abs(regen - 1.40) < 0.0001 and effective == 4,
        "Academic Achievement adds positive CHA_MOD to passive regen")
    local negative = self:AcademicMagicRegenMultiplier(1, -3, true)
    expect(math.abs(negative - 1.10) < 0.0001,
        "Academic Achievement ignores negative CHA_MOD")

    local winning = Feats.CHA_WINNING_PERSONALITY
    expect(winning and winning.abilityRequirements.cha == 17,
        "Winning Personality CHA 17")
    local permanent = {featIds = {"CHA_WINNING_PERSONALITY"}, featAbilityDelta = {cha = 2}}
    expect(Progression:PermanentFeatAbilityDelta(permanent, "cha") == 3,
        "Winning Personality adds one permanent CHA alongside fallback grants")
    expect(Progression:PermanentFeatAbilityDelta(permanent, "cha") == 3
        and permanent.featAbilityDelta.cha == 2,
        "Winning Personality recomputation does not accumulate grants")
    expect(Progression:PermanentFeatAbilityDelta(permanent, "int") == 0,
        "Winning Personality never grants actual INT")
    local state = {
        featIds = {"CHA_WINNING_PERSONALITY"},
        featQualificationAbilities = {int = 11, cha = 17, str = 13},
        classId = "fighter", secondaryAbilities = {}, capabilityTags = {}
    }
    local intFeat = {
        featId = "INT_VALIDATION_FEAT", abilityRequirements = {int = 13},
        prerequisiteFeatIds = {}, requiredCapabilityTags = {}, incompatibleFeatIds = {}
    }
    expect(Progression:_FeatEligible({}, state, intFeat),
        "Winning Personality substitutes CHA for INT-feat score")
    state.featIds = {}
    expect(not Progression:_FeatEligible({}, state, intFeat),
        "INT feat remains ineligible without Winning Personality")
    state.featIds = {"CHA_WINNING_PERSONALITY"}
    local crossFeat = {
        featId = "CROSS_VALIDATION_FEAT", abilityRequirements = {str = 13, int = 13},
        prerequisiteFeatIds = {}, requiredCapabilityTags = {}, incompatibleFeatIds = {}
    }
    expect(not Progression:_FeatEligible({}, state, crossFeat),
        "Winning Personality does not substitute for cross-feat INT requirement")
    intFeat.prerequisiteFeatIds = {"INT_REQUIRED_PRIOR_FEAT"}
    expect(not Progression:_FeatEligible({}, state, intFeat),
        "Winning Personality preserves non-ability prerequisites")

    return #errors == 0, errors
end

if Validation and not Validation.LODGateECharismaWrapped then
    Validation.LODGateECharismaWrapped = true
    local base = Validation.Run
    function Validation:Run(printResult)
        local baseOK, errors = base(self, false)
        errors = errors or {}
        local featOK, featErrors = Effects:ValidateCharismaFamilies()
        for _, message in ipairs(featErrors or {}) do
            errors[#errors + 1] = "Gate E Charisma: " .. message
        end
        local ok = baseOK and featOK and #errors == 0
        if printResult ~= false then
            if ok then
                print(string.format(
                    "[LOD:RPG] core RPG validation PASS — gate=%s gameplayEnabled=%s gateECharisma=true",
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

local function configure(ply, rank, utilityEnabled)
    local run = LOD.RunManager
    local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
    local state = ps and ps.progressionState or nil
    if not state then return false, "RPG progression state is unavailable." end
    rank = math.Clamp(math.floor(tonumber(rank) or 0), 0, 3)
    local kept = {}
    for _, id in ipairs(state.featIds or {}) do
        if not HITSTUN_RANK[id] and not UTILITY_IDS[id] then kept[#kept + 1] = id end
    end
    state.featIds = kept
    state.featStackCounts = state.featStackCounts or {}
    for id in pairs(HITSTUN_RANK) do state.featStackCounts[id] = nil end
    for id in pairs(UTILITY_IDS) do state.featStackCounts[id] = nil end
    for index = 1, rank do
        local id = HITSTUN_CHAIN[index]
        state.featIds[#state.featIds + 1] = id
        state.featStackCounts[id] = 1
    end
    if utilityEnabled then
        for _, id in ipairs({"CHA_ACADEMIC_ACHIEVEMENT", "CHA_WINNING_PERSONALITY"}) do
            state.featIds[#state.featIds + 1] = id
            state.featStackCounts[id] = 1
        end
    end
    Progression:_RecomputeProgressionState(state)
    Progression:SyncPlayer(ply)
    if run.MarkUnranked then run:MarkUnranked("Gate E Charisma feat test") end
    return true
end

concommand.Add("lod_rpg_gate_e_charisma_validate", function(ply)
    if not developerAllowed(ply) then return end
    local ok, errors = Effects:ValidateCharismaFamilies()
    if ok then
        print("[LOD:RPG-E] Charisma families PASS — hit stun x1.10/x1.20/x1.30 replacement ladder; Academic passive-regeneration CHA contribution; Winning Personality INT-feat qualification only")
    else
        ErrorNoHalt("[LOD:RPG-E] Charisma families FAILED\n")
        for _, message in ipairs(errors or {}) do
            ErrorNoHalt("[LOD:RPG-E]  - " .. message .. "\n")
        end
    end
end)

concommand.Add("lod_rpg_gate_e_charisma_status", function(ply)
    if not developerAllowed(ply) or not IsValid(ply) then return end
    local state = Rules:ProgressionState(ply)
    local derived = state and state.derivedStats or {}
    local profile = Effects:CharismaProfile(state)
    local stats = Effects.CharismaStats
    local line = string.format(
        "hitStunRank=%d feat=x%.2f queries=%d lastBase=x%.3f lastFinal=x%.3f academic=%s intMod=%d chaContribution=%d effectiveRegenMod=%d regen=x%.2f winning=%s INTqualification=%d intrinsicCHA=%d permanentFeatCHA=%d",
        profile.hitStunRank, profile.featHitStunMultiplier,
        stats.hitStunMultiplierQueries or 0, stats.lastBaseHitStunMultiplier or 1,
        stats.lastFinalHitStunMultiplier or 1,
        tostring(profile.academicAchievement), tonumber(derived.intMod) or 0,
        tonumber(derived.academicRegenCHAContribution) or 0,
        tonumber(derived.effectiveMagicRegenModifier) or tonumber(derived.intMod) or 0,
        tonumber(derived.magicRegenMultiplier) or 1,
        tostring(profile.winningPersonality),
        Effects:WinningPersonalityQualificationScore(state),
        tonumber(state and state.featQualificationAbilities and state.featQualificationAbilities.cha) or 0,
        state and Progression:PermanentFeatAbilityDelta(state, "cha") or 0)
    print("[LOD:RPG-E] " .. line)
    ply:ChatPrint(line)
end)

concommand.Add("lod_rpg_gate_e_charisma_testkit", function(ply, _, args)
    if not developerAllowed(ply) or not IsValid(ply) or not ply:Alive() then return end
    local rank = math.Clamp(math.floor(tonumber(args[1]) or 3), 0, 3)
    local utilityEnabled = tonumber(args[2]) ~= 0
    local ok, message = configure(ply, rank, utilityEnabled)
    if not ok then ply:ChatPrint(message) return end
    Effects.CharismaStats.hitStunMultiplierQueries = 0
    Effects.CharismaStats.lastBaseHitStunMultiplier = 1
    Effects.CharismaStats.lastFeatHitStunMultiplier = 1
    Effects.CharismaStats.lastFinalHitStunMultiplier = 1
    local shotgun = ply:GetWeapon("weapon_shotgun")
    if not IsValid(shotgun) then shotgun = ply:Give("weapon_shotgun", true) end
    if IsValid(shotgun) then
        shotgun:SetClip1(math.max(6, shotgun:Clip1()))
        ply:SelectWeapon("weapon_shotgun")
    end
    ply:ChatPrint(string.format(
        "Charisma test configured: hit-stun rank %d (x%.2f); Academic/Winning %s. Shoot a surviving hostile once, then run charisma_status.",
        rank, HITSTUN_MULTIPLIER[rank] or 1, utilityEnabled and "ON" or "OFF"))
end)

RPG.SystemBootstrap.FeatEffectSystem = "gate_e_batch_10_charisma"
return Effects
