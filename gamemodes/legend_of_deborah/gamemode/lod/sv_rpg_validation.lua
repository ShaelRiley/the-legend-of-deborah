LOD = LOD or {}
LOD.RPGValidation = LOD.RPGValidation or {}

local Validation = LOD.RPGValidation
local RPG = LOD.RPG
local CPS = LOD.CharacterProgressionSystem

local function addError(errors, message)
    errors[#errors + 1] = tostring(message)
end

local function countKeys(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function validateUniqueList(errors, name, list)
    local seen = {}
    for index, value in ipairs(list or {}) do
        if seen[value] then addError(errors, name .. " duplicate value " .. tostring(value)) end
        seen[value] = index
    end
end

local function validateSchema(errors, name, requiredFields)
    local fields = RPG.Schema and RPG.Schema[name]
    if not istable(fields) then
        addError(errors, "missing schema " .. tostring(name))
        return
    end

    validateUniqueList(errors, "schema " .. name, fields)
    local present = {}
    for _, field in ipairs(fields) do present[field] = true end
    for _, field in ipairs(requiredFields) do
        if not present[field] then addError(errors, name .. " missing field " .. field) end
    end
end

function Validation:Run(printResult)
    local errors = {}
    local constants = RPG.Constants or {}

    if #RPG.Abilities ~= 6 then addError(errors, "ability count must be 6") end
    validateUniqueList(errors, "abilities", RPG.Abilities)
    for _, ability in ipairs({"str", "dex", "con", "int", "wis", "cha"}) do
        if not RPG.AbilitySet[ability] then addError(errors, "missing ability " .. ability) end
    end

    if constants.MinLevel ~= 1 or constants.MaxLevel ~= 20 then addError(errors, "Level bounds must be 1..20") end
    if constants.HeroMaxXP ~= 48000 then addError(errors, "HeroMaxXP must be 48000") end
    if constants.AbilityMin ~= 3 or constants.AbilityMax ~= 30 then addError(errors, "ability bounds must be 3..30") end
    if constants.MagicCapacity ~= 100 then addError(errors, "Magic capacity must remain exactly 100") end
    if constants.MaxDamageDicePerChain ~= 32 then addError(errors, "damage chain cap must be 32") end
    if constants.MaxDamageDicePerAttackEvent ~= 128 then addError(errors, "attack damage-die cap must be 128") end
    if constants.MaxProjectilesPerAttackEvent ~= 16 then addError(errors, "attack projectile cap must be 16") end
    if constants.MaxPenetrationTargetsPerProjectile ~= 4 then addError(errors, "penetration target cap must be 4") end
    if constants.RPGThreatMultiplierMin ~= 0.75 or constants.RPGThreatMultiplierMax ~= 2.00 then
        addError(errors, "RPG threat multiplier bounds must be 0.75..2.00")
    end

    if countKeys(RPG.Classes) ~= 3 then addError(errors, "class count must be 3") end
    local expectedClasses = {
        fighter = {10, "str", "con"},
        rogue = {8, "dex", "cha"},
        wizard = {6, "int", "wis"}
    }
    for classId, expected in pairs(expectedClasses) do
        local definition = RPG.Classes[classId]
        if not definition then
            addError(errors, "missing class " .. classId)
        else
            if definition.heroProgressionHitDieSides ~= expected[1] then addError(errors, classId .. " hit die mismatch") end
            if definition.favoredAbilities[1] ~= expected[2] or definition.favoredAbilities[2] ~= expected[3] then
                addError(errors, classId .. " favored abilities mismatch")
            end
        end
    end

    local expectedFeatLevels = {1, 3, 6, 9, 12, 15, 18}
    if #RPG.OrdinaryFeatLevels ~= #expectedFeatLevels then addError(errors, "ordinary feat cadence length mismatch") end
    for i, level in ipairs(expectedFeatLevels) do
        if RPG.OrdinaryFeatLevels[i] ~= level then addError(errors, "ordinary feat cadence mismatch at index " .. i) end
    end

    validateSchema(errors, "ProgressionState", {"actorId", "level", "xp", "classId", "hitDieRollsByLevel", "featStackCounts", "pendingFeatSlots", "classCapstoneFeatId", "capabilityTags"})
    validateSchema(errors, "ArchetypeProgressionTemplate", {"archetypeId", "baseAbilities", "aiClassWeights", "progressionHitDieSides", "usesMagic"})
    validateSchema(errors, "DamageContributionLedger", {"effectiveDamageByHeroId", "killingBlowHeroId", "totalEligibleEffectiveDamage", "resolved"})
    validateSchema(errors, "DefensiveProcState", {"blastProofReadyAtSeconds", "notYetConsumedDungeonNumber"})
    validateSchema(errors, "CombatHitResolution", {"hitConnected", "harmWasEffective", "effectiveHPDamage", "targetSurvived", "pushEligible", "hitStunEligible"})
    validateSchema(errors, "DerivedStats", {"damageResistancePerDie", "hpConBonusPerLevel", "hpToMagicDiversionFraction", "rpgThreatMultiplier", "levelProficiency"})
    validateSchema(errors, "FeatDefinition", {"featId", "abilityRequirements", "requiredCapabilityTags", "effectHandlerId", "directorBaseWeight"})
    validateSchema(errors, "ClassCapstoneDefinition", {"featId", "classId", "effectHandlerId"})
    validateSchema(errors, "PendingFeatDraft", {"earnedAtLevel", "draftType", "offerFeatIds", "selectedFeatId", "resolved"})
    validateSchema(errors, "IdentityPerkDefinition", {"tableType", "tableIndex", "perkDisplayName", "effectHandlerId"})
    validateSchema(errors, "CharacterIdentityPackage", {"rosterSeed", "heroIdentityId", "originIndex", "backgroundIndex", "motiveIndex", "presentationSex", "fullDisplayName", "identityAbilityDelta", "resolvedIdentityPerkIds"})

    local heroState = CPS:NewProgressionState("validation:hero", "hero", "hero")
    local aiState = CPS:NewProgressionState("validation:ai", "shambler", "ai")
    if heroState.level ~= 1 or heroState.xp ~= 0 then addError(errors, "new Hero progression state must begin at Level 1 / 0 XP") end
    if aiState.level ~= 1 or aiState.xp ~= nil then addError(errors, "new AI progression state must begin at Level 1 / no XP ledger") end
    if CPS:ClampLevel(0) ~= 1 or CPS:ClampLevel(99) ~= 20 then addError(errors, "Level clamp failed") end
    if CPS:AbilityModifier(10) ~= 0 or CPS:AbilityModifier(18) ~= 4 or CPS:AbilityModifier(6) ~= -2 then
        addError(errors, "ABILITY_MOD implementation mismatch")
    end

    local rosterSeed = 1234567
    local idA = CPS:HeroIdentitySeed(rosterSeed, "validation-player")
    local idB = CPS:HeroIdentitySeed(rosterSeed, "validation-player")
    local growth = CPS:HeroGrowthProfileSeed(rosterSeed, "validation-player", "fighter")
    if idA ~= idB then addError(errors, "Hero identity seed is not deterministic") end
    if idA == growth then addError(errors, "identity and growth RNG domains collided in validation sample") end

    local ok = #errors == 0
    if printResult ~= false then
        if ok then
            print(string.format(
                "[LOD:RPG] Gate A validation PASS — schemas=%d classes=%d abilities=%d featSlots=%d gameplayEnabled=%s",
                countKeys(RPG.Schema), countKeys(RPG.Classes), #RPG.Abilities, #RPG.OrdinaryFeatLevels,
                tostring(RPG.GameplayEnabled)
            ))
        else
            ErrorNoHalt("[LOD:RPG] Gate A validation FAILED (" .. #errors .. " error(s))\n")
            for _, message in ipairs(errors) do ErrorNoHalt("[LOD:RPG]  - " .. message .. "\n") end
        end
    end

    return ok, errors
end

concommand.Add("lod_rpg_validate", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local cvDeveloperMode = GetConVar("lod_developer_mode")
    if not cvDeveloperMode or not cvDeveloperMode:GetBool() then
        if IsValid(ply) then ply:ChatPrint("LOD RPG validation requires lod_developer_mode 1 at startup.") end
        return
    end
    Validation:Run(true)
end)

hook.Add("InitPostEntity", "LOD_RPG_GateAValidation", function()
    local cvDeveloperMode = GetConVar("lod_developer_mode")
    if cvDeveloperMode and cvDeveloperMode:GetBool() then Validation:Run(true) end
end)
