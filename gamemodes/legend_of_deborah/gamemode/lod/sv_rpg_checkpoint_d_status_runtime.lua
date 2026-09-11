LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local RPG = LOD.RPG
local Catalog = assert(RPG.IdentityCatalog, "Checkpoint D status runtime requires IdentityCatalog")
local CPS = assert(LOD.CharacterProgressionSystem,
    "Checkpoint D status runtime requires CharacterProgressionSystem")
local System = assert(LOD.RPGStatusElements,
    "Checkpoint D status runtime requires shared status/element authority")
local Rules = assert(LOD.RPGAbilityRules,
    "Checkpoint D status runtime requires RPGAbilityRules")
local Feats = Catalog.OrdinaryFeats or Catalog.LevelOneOrdinaryFeats
local Families = assert(RPG.CheckpointDStatusProcFamilies,
    "Checkpoint D status runtime requires status-proc catalog")

local function listContains(values, wanted)
    for key, value in pairs(values or {}) do
        local candidate = type(key) == "string" and value == true and key or value
        if candidate == wanted then return true end
    end
    return false
end

local function progressionState(actor)
    return Rules.ProgressionState and Rules:ProgressionState(actor)
        or actor and actor.LODProgressionState or nil
end

local function owns(state, featId)
    return listContains(state and state.featIds, featId)
end

local function highestOwnedRank(state, family)
    for rank = 3, 1, -1 do
        if owns(state, family.ids[rank]) then
            return rank, Feats[family.ids[rank]]
        end
    end
    return 0, nil
end

local function attributableActor(state)
    if not state then return false end
    return state.actorType == "hero" or state.actorType == "human_soldier"
        or state.actorType == "ai"
end

local function hasPhysicalAttackCapability(state)
    if not attributableActor(state) then return false end
    if state.actorType == "hero" or state.actorType == "human_soldier" then return true end
    return listContains(state.capabilityTags, "firearm")
        or listContains(state.capabilityTags, "pushable_weapon")
        or listContains(state.capabilityTags, "hit_stun_source")
end

local baseHasCapability = CPS._HasCapability
function CPS:_HasCapability(ps, state, tag)
    if tag == "attributable_damaging_attack" then
        return attributableActor(state)
    end
    if tag == "attributable_nonmagical_damaging_attack" then
        return hasPhysicalAttackCapability(state)
    end
    return baseHasCapability(self, ps, state, tag)
end

local baseCommitAutomaticFeat = CPS._CommitAutomaticFeat
function CPS:_CommitAutomaticFeat(ps, state, draft, actorSeed)
    baseCommitAutomaticFeat(self, ps, state, draft, actorSeed)
    local selectedId = draft and draft.selectedFeatId
    local selected = selectedId and Feats[selectedId]
    if not selected or not selected.replacesLowerRank or not selected.featFamilyId then return end

    local retained = {}
    local selectedRank = tonumber(selected.rankIndex) or 0
    for _, featId in ipairs(state.featIds or {}) do
        local definition = Feats[featId]
        local lowerSameFamily = featId ~= selectedId and definition
            and definition.featFamilyId == selected.featFamilyId
            and (tonumber(definition.rankIndex) or 0) < selectedRank
        if not lowerSameFamily then
            retained[#retained + 1] = featId
        else
            state.featStackCounts[featId] = nil
        end
    end
    state.featIds = retained
end

System.StatusProcStats = System.StatusProcStats or {
    eligibleEvents = 0,
    rolls = 0,
    successes = 0,
    applications = 0,
    moraleRequests = 0,
    suppressedGuaranteedRider = 0,
    skippedStatusDamage = 0,
    skippedSelfDamage = 0,
    skippedNonAttributable = 0
}

local function stableFamilyList()
    local ordered = {}
    for _, family in ipairs(Families) do ordered[#ordered + 1] = family end
    table.sort(ordered, function(a, b)
        return tostring(a.ids[1]) < tostring(b.ids[1])
    end)
    return ordered
end

System.StatusProcFamiliesStable = System.StatusProcFamiliesStable or stableFamilyList()

local function isValidActor(actor)
    return actor ~= nil and (IsValid == nil or IsValid(actor))
end

local function guaranteedSameCondition(context, statusId)
    if not statusId then return false end
    if context.riderStatusId == statusId then return true end
    local guaranteed = context.guaranteedStatusIds or context.guaranteedConditionTags
    return listContains(guaranteed, statusId)
end

local function physicalNonmagical(context, dmginfo)
    if context.magic == true or context.magical == true then return false end
    if context.physical == true then return true end
    if context.magic == false or context.magical == false then return true end
    return dmginfo ~= nil
end

function System:_StatusProcRNG(family, source, target)
    local sourceIndex = isValidActor(source) and source.EntIndex and source:EntIndex() or 0
    local targetIndex = isValidActor(target) and target.EntIndex and target:EntIndex() or 0
    return self:_RNG(string.format("feat-proc:%s:%d:%d",
        tostring(family.familyId), sourceIndex, targetIndex))
end

function System:_ResolveOneStatusProcFamily(family, source, target, dmginfo, context, event)
    local sourceState = progressionState(source)
    local rank, definition = highestOwnedRank(sourceState, family)
    if rank <= 0 or not definition then return false, "not_owned" end

    local params = definition.effectParams or {}
    local statusId = params.statusId
    if statusId and guaranteedSameCondition(context, statusId) then
        self.StatusProcStats.suppressedGuaranteedRider =
            self.StatusProcStats.suppressedGuaranteedRider + 1
        return false, "guaranteed_same_condition"
    end
    if params.requiresPhysicalNonmagical and not physicalNonmagical(context, dmginfo) then
        return false, "requires_physical_nonmagical"
    end
    if params.requiresArcaneShieldOnline and not self:IsArcaneShieldOnline(target) then
        return false, "arcane_shield_offline"
    end
    if params.moraleProc and (target.LODMoraleCooldownUntil or 0) > (CurTime and CurTime() or 0) then
        return false, "morale_cooldown"
    end

    local rng = self:_StatusProcRNG(family, source, target)
    self.StatusProcStats.rolls = self.StatusProcStats.rolls + 1
    local chance = math.max(0, math.min(1, tonumber(params.procChance) or 0))
    if rng:Float(0, 1) >= chance then return false, "proc_failed" end
    self.StatusProcStats.successes = self.StatusProcStats.successes + 1

    if params.moraleProc then
        self.StatusProcStats.moraleRequests = self.StatusProcStats.moraleRequests + 1
        local ok, reason = self:AttemptMorale(source, target, {
            hpBefore = event.hpBefore,
            maxHP = event.maxHP,
            finalHPDamage = event.finalHPDamage,
            forceMorale = true,
            statusDamage = false,
            moraleIneligible = context.moraleIneligible,
            rng = rng
        })
        return ok, reason
    end

    local dc = self:ConditionDC(source, params.dcAbility or family.dcAbility)
    local ok, reason = self:Apply(target, statusId, source, {dc = dc, rng = rng})
    if ok then self.StatusProcStats.applications = self.StatusProcStats.applications + 1 end
    return ok, reason
end

function System:ResolveStatusProcFamilies(source, target, dmginfo, context, event)
    context = context or {}
    event = event or {}
    if context.statusDamage or context.statusProcIneligible then
        self.StatusProcStats.skippedStatusDamage = self.StatusProcStats.skippedStatusDamage + 1
        return false, "status_damage"
    end
    if not isValidActor(source) or source == target or source == (game and game.GetWorld and game.GetWorld()) then
        self.StatusProcStats.skippedSelfDamage = self.StatusProcStats.skippedSelfDamage + 1
        return false, "self_or_environment"
    end
    local state = progressionState(source)
    if not attributableActor(state) then
        self.StatusProcStats.skippedNonAttributable = self.StatusProcStats.skippedNonAttributable + 1
        return false, "non_attributable"
    end
    if (tonumber(event.finalHPDamage) or 0) <= 0 or not event.targetSurvived then
        return false, "no_surviving_damage"
    end

    self.StatusProcStats.eligibleEvents = self.StatusProcStats.eligibleEvents + 1
    local attempted = false
    for _, family in ipairs(self.StatusProcFamiliesStable) do
        local rank = highestOwnedRank(state, family)
        if rank > 0 then
            attempted = true
            self:_ResolveOneStatusProcFamily(family, source, target, dmginfo, context, event)
        end
    end
    return attempted, attempted and "resolved" or "no_owned_family"
end

local baseObserveDamage = System.ObserveDamage
function System:ObserveDamage(target, dmginfo, defenseResult)
    if not isValidActor(target) or not dmginfo then
        return baseObserveDamage(self, target, dmginfo, defenseResult)
    end

    local context = self:DamageContext(dmginfo, target) or {}
    local source = dmginfo.GetAttacker and dmginfo:GetAttacker() or nil
    local hpBefore = math.max(0, target.Health and target:Health() or 0)
    local finalHPDamage = math.min(hpBefore, math.max(0, dmginfo:GetDamage()))
    local targetSurvived = hpBefore - finalHPDamage > 0
    local maxHP = target.GetMaxHealth and target:GetMaxHealth() or hpBefore

    local observed = baseObserveDamage(self, target, dmginfo, defenseResult)
    if finalHPDamage > 0 and targetSurvived then
        self:ResolveStatusProcFamilies(source, target, dmginfo, context, {
            hpBefore = hpBefore,
            maxHP = maxHP,
            finalHPDamage = finalHPDamage,
            targetSurvived = true
        })
    end
    return observed
end
