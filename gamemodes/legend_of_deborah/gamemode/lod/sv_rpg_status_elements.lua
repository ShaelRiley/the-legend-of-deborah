LOD = LOD or {}
LOD.RPGStatusElements = LOD.RPGStatusElements or {}

local System = LOD.RPGStatusElements
local RPG = LOD.RPG
local Rules = LOD.RPGAbilityRules
local Progression = LOD.CharacterProgressionSystem
local SCHEDULER_TIMER = "LOD_RPG_StatusScheduler"

System.SourceRevisionId = "ANLCKQklvdyHThE8HWSCcoMDbGwhsNpoailKMiClpIgfAltvXjgrAiGJaX2X4XL1ranKVUXhub39Sn1Mk2qKfxRID0aGPtXjibXy-m0IIg"
System.Elements = {"earth", "fire", "dark", "ice", "light", "electric"}
System.WeaknessMultipliers = {1.11, 1.22, 1.33, 1.44, 1.55, 1.66, 1.77, 1.88}
System.ResistanceMultipliers = {0.89, 0.78, 0.67, 0.56, 0.45, 0.34, 0.23, 0.12}
System.Active = System.Active or setmetatable({}, {__mode = "k"})
System.DamageContexts = System.DamageContexts or setmetatable({}, {__mode = "k"})
System.Serial = System.Serial or 0
System.Stats = System.Stats or {
    applications = 0, saves = 0, immunities = 0, duplicates = 0,
    statusDamage = 0, weaknessHits = 0, resistanceHits = 0,
    moraleChecks = 0, moraleFailures = 0
}

local function clamp(value, low, high)
    value = tonumber(value) or low
    return math.max(low, math.min(high, value))
end

local function now()
    return CurTime and CurTime() or 0
end

local function valid(actor)
    return actor ~= nil and (IsValid == nil or IsValid(actor)
        or (type(actor) == "table" and actor.LODStatusValidationActor == true))
end

local function actorState(actor)
    return Rules and Rules.ProgressionState and Rules:ProgressionState(actor)
        or actor and actor.LODProgressionState or nil
end

local function derived(actor)
    local state = actorState(actor)
    return state and state.derivedStats or nil
end

local function score(actor, ability)
    local state = actorState(actor)
    local values = state and (state.effectiveAbilities or state.abilities
        or state.featQualificationAbilities)
    return tonumber(values and values[ability]) or 10
end

local function modifier(value)
    return math.floor(((tonumber(value) or 10) - 10) / 2)
end

local function level(actor)
    return math.max(1, math.floor(tonumber(actorState(actor) and actorState(actor).level) or 1))
end

local function isPlayer(actor)
    return valid(actor) and actor.IsPlayer and actor:IsPlayer()
end

local function isAlive(actor)
    if not valid(actor) then return false end
    if actor.LODDead then return false end
    if actor.Alive and isPlayer(actor) and not actor:Alive() then return false end
    return not actor.Health or actor:Health() > 0
end

local function listContains(values, wanted)
    for key, value in pairs(values or {}) do
        local candidate = type(key) == "string" and value == true and key or value
        if string.lower(tostring(candidate)) == wanted then return true end
    end
    return false
end

local function owns(actor, featId)
    local state = actorState(actor)
    return listContains(state and state.featIds, featId)
end

local function statusTable(actor, create)
    local states = System.Active[actor]
    if not states and create then
        states = {}
        System.Active[actor] = states
    end
    return states
end

local function syncStatus(actor, id, active, expiresAt)
    if not valid(actor) then return end
    local suffix = string.gsub(id, "_(%l)", function(c) return string.upper(c) end)
    suffix = string.upper(string.sub(suffix, 1, 1)) .. string.sub(suffix, 2)
    if actor.SetNW2Bool then actor:SetNW2Bool("LOD_Status" .. suffix, active == true) end
    if actor.SetNW2Float then actor:SetNW2Float("LOD_Status" .. suffix .. "Until", expiresAt or 0) end
end

function System:_RNG(label, supplied)
    if supplied then return supplied end
    local rolls = LOD.CombatRolls
    if rolls and rolls._RNG then return rolls:_RNG("status:" .. tostring(label)) end
    self.Serial = self.Serial + 1
    local seed = LOD.Seeds and LOD.Seeds.Derive
        and LOD.Seeds.Derive(self.Serial, "status:" .. tostring(label)) or self.Serial
    return LOD.RNG.New(seed)
end

function System:RollExploding(rng, count, sides)
    local total, values = 0, {}
    local cap = RPG and RPG.Constants and RPG.Constants.MaxDamageDicePerChain or 32
    for _ = 1, count do
        local natural = rng:Int(1, sides)
        local chain = 0
        while natural and chain < cap do
            total = total + natural
            values[#values + 1] = natural
            chain = chain + 1
            if natural ~= sides then break end
            natural = rng:Int(1, sides)
        end
    end
    return total, values
end

function System:ConditionDC(source, ability, explicit)
    if explicit ~= nil then return math.floor(tonumber(explicit) or 10) end
    local bonus = ability == "wis"
        and math.floor(tonumber(derived(source) and derived(source).wizardCapstoneMagicDCBonus) or 0)
        or 0
    return 10 + modifier(score(source, ability)) + math.floor((level(source) - 1) / 4) + bonus
end

function System:ConditionSave(target, ability, rng)
    local bonus = modifier(score(target, ability)) + math.floor((level(target) - 1) / 4)
    local natural = rng:Int(1, 20)
    if ability == "wis" then
        local authored = derived(target) and derived(target).magicSaveBonus
        bonus = bonus + (authored ~= nil and math.floor(tonumber(authored) or 0)
            or (owns(target, "WIS_SPELLWARD") and 2 or 0))
    end
    return natural + bonus, natural
end

System.Registry = {
    clumsy = {ability = "dex", duration = function(self, rng) return 1 + rng:Int(1, 4) end,
        reapply = "extend"},
    immolated = {ability = "dex", duration = function(self, rng) return self:RollExploding(rng, 3, 6) end,
        reapply = "raise_dc_extend", tick = "immolated"},
    poisoned = {ability = "con", duration = nil, reapply = "raise_dc_keep_schedule", tick = "poisoned"},
    bleeding = {ability = "con", duration = nil, reapply = "raise_dc_keep_schedule", tick = "bleeding"},
    muted = {ability = "wis", duration = function(self, rng) return 1 + rng:Int(1, 4) end,
        reapply = "extend"},
    held = {ability = "wis", duration = function(self, rng) return self:RollExploding(rng, 1, 6) end,
        reapply = "extend"},
    reckless = {ability = "wis", duration = function(self, rng) return self:RollExploding(rng, 4, 6) end,
        reapply = "extend"},
    arcane_shattered = {ability = "int", duration = function(self, rng) return self:RollExploding(rng, 5, 6) end,
        reapply = "ignore"},
    intimidated = {ability = "cha", duration = function(self, rng) return rng:Int(1, 3) end,
        reapply = "extend", direct = true}
}

function System:IsImmune(target, id)
    local state = actorState(target)
    local immunities = target and target.LODStatusImmunities
        or state and state.statusImmunities
    if listContains(immunities, id) then return true end
    if (id == "intimidated" or id == "morale_flee")
        and (state and state.moraleBonus == "immune"
            or target and target.LODMoraleImmune == true)
    then
        return true
    end
    return false
end

function System:Has(target, id, at)
    local entry = statusTable(target, false)
    entry = entry and entry[id]
    if not entry then return false end
    if entry.expiresAt and (at or now()) >= entry.expiresAt then
        self:Clear(target, id, "expired")
        return false
    end
    return true, entry
end

function System:Clear(target, id, reason)
    local states = statusTable(target, false)
    local entry = states and states[id]
    if not entry then return false end
    states[id] = nil
    syncStatus(target, id, false, 0)
    if id == "morale_flee" and valid(target) then
        target.LODMoraleFleeSource = nil
        target.LODMoraleFleeUntil = nil
        if target.LODTargetWasMoraleFlee then target.LODTarget = nil end
        target.LODTargetWasMoraleFlee = nil
    end
    if id == "reckless" and valid(target) and target.LODRecklessAllyTarget then
        target.LODTarget = nil
        target.LODRecklessAllyTarget = nil
    end
    hook.Run("LODStatusCleared", target, id, reason)
    self:_Schedule()
    return true
end

function System:_Schedule()
    if not timer or not timer.Create then return end
    local due
    for actor, states in pairs(self.Active) do
        if isAlive(actor) then
            for _, entry in pairs(states) do
                for _, value in pairs({entry.expiresAt, entry.nextTickAt, entry.nextRecoveryAt}) do
                    if value and (not due or value < due) then due = value end
                end
            end
        end
    end
    if not due then
        if timer.Remove then timer.Remove(SCHEDULER_TIMER) end
        return
    end
    timer.Create(SCHEDULER_TIMER, math.max(0.01, due - now()), 1,
        function() System:Process() end)
end

function System:_ScheduleInitial(target, id, entry, rng)
    local t = now()
    if id == "immolated" then
        entry.nextTickAt = t + 1
    elseif id == "poisoned" then
        entry.nextRecoveryAt = t + self:RollExploding(rng, 9, 6)
        entry.lastCellKey = self:CellKey(target)
    elseif id == "bleeding" then
        entry.nextTickAt = t + rng:Int(1, 3)
    end
end

function System:Apply(target, id, source, options)
    options = options or {}
    id = string.lower(tostring(id or ""))
    local definition = self.Registry[id]
    if not definition or not valid(target) or not isAlive(target) then return false, "invalid" end
    if self:IsImmune(target, id) then
        self.Stats.immunities = self.Stats.immunities + 1
        return false, "immune"
    end
    local rng = self:_RNG(id .. ":apply", options.rng)
    local dc = self:ConditionDC(source, definition.ability, options.dc)
    if not options.direct and not definition.direct then
        local save = self:ConditionSave(target, definition.ability, rng)
        self.Stats.saves = self.Stats.saves + 1
        if save >= dc then return false, "saved", {dc = dc, save = save} end
    end
    local duration = options.duration
    if duration == nil and definition.duration then duration = definition.duration(self, rng) end
    local expiresAt = duration and (now() + math.max(0, duration)) or nil
    local states = statusTable(target, true)
    local existing = states[id]
    if existing then
        self.Stats.duplicates = self.Stats.duplicates + 1
        if definition.reapply == "ignore" then return false, "duplicate", existing end
        if definition.reapply == "raise_dc_keep_schedule" then
            existing.dc = math.max(existing.dc or dc, dc)
            self:_Schedule()
            return true, "refreshed", existing
        end
        if definition.reapply == "raise_dc_extend" then existing.dc = math.max(existing.dc or dc, dc) end
        if expiresAt then existing.expiresAt = math.max(existing.expiresAt or 0, expiresAt) end
        syncStatus(target, id, true, existing.expiresAt)
        self:_Schedule()
        return true, "extended", existing
    end
    local entry = {id = id, source = source, dc = dc, appliedAt = now(), expiresAt = expiresAt}
    states[id] = entry
    self:_ScheduleInitial(target, id, entry, rng)
    self.Stats.applications = self.Stats.applications + 1
    syncStatus(target, id, true, expiresAt)
    hook.Run("LODStatusApplied", target, id, source, entry)
    self:_Schedule()
    return true, "applied", entry
end

function System:AttachDamageContext(dmginfo, context)
    if dmginfo then self.DamageContexts[dmginfo] = context or {} end
    return dmginfo
end

function System:DamageContext(dmginfo, target)
    return self.DamageContexts[dmginfo]
        or (target and target.LODPendingStatusDamageContext) or {}
end

function System:ResolveElementDamage(amount, attacker, target, tags, rng)
    tags = tags or {}
    local element = tags.element and string.lower(tostring(tags.element)) or nil
    if not listContains(self.Elements, element) then return amount, {kind = "none", multiplier = 1} end
    local state = actorState(target)
    local current = tags.targetElement or target and target.LODElement
        or state and state.currentElement
    current = current and string.lower(tostring(current)) or nil
    local weaknesses = tags.targetWeaknesses or target and target.LODElementalWeaknesses
        or state and state.elementalWeaknesses
    rng = self:_RNG("element:" .. element, rng or tags.rng)
    if listContains(weaknesses, element) then
        local index = rng:Int(1, #self.WeaknessMultipliers)
        local multiplier = self.WeaknessMultipliers[index]
        self.Stats.weaknessHits = self.Stats.weaknessHits + 1
        return math.max(0, amount * multiplier), {kind = "weakness", multiplier = multiplier,
            index = index, element = element, hitStunMultiplier = 2.5, knockback = true}
    end
    if current == element then
        local index = rng:Int(1, #self.ResistanceMultipliers)
        local multiplier = self.ResistanceMultipliers[index]
        self.Stats.resistanceHits = self.Stats.resistanceHits + 1
        return math.max(0, amount * multiplier), {kind = "resistance", multiplier = multiplier,
            index = index, element = element}
    end
    return amount, {kind = "neutral", multiplier = 1, element = element}
end

function System:CellKey(actor)
    local state = LOD.RunManager and LOD.RunManager.State
    local graph = state and state.Graph
    local navigator = LOD.MazeNavigator
    if not graph or not navigator or not navigator.WorldToCell or not valid(actor) then return nil end
    local cell = navigator:WorldToCell(graph, actor:GetPos())
    if not cell then return nil end
    return string.format("%d:%d:%d", cell.x or 0, cell.y or 0, cell.z or 0)
end

function System:_ApplyStatusDamage(target, entry, amount, damageType, label, options)
    if not isAlive(target) or amount <= 0 or not DamageInfo then return false end
    options = options or {}
    local contributions = options.contributions or {amount}
    local resolved = amount
    if Rules and Rules.ResolveDamageContract then
        resolved = select(1, Rules:ResolveDamageContract({contributions = contributions, bonus = 0},
            entry.source, target, {element = options.element, statusDamage = true,
                wisScaled = false}))
    end
    resolved = math.max(0, tonumber(resolved) or 0)
    if resolved <= 0 then return false end
    local info = DamageInfo()
    if valid(entry.source) then info:SetAttacker(entry.source) else info:SetAttacker(game.GetWorld()) end
    info:SetInflictor(valid(entry.source) and entry.source or game.GetWorld())
    info:SetDamage(resolved)
    info:SetDamageType(damageType or DMG_GENERIC)
    if target.WorldSpaceCenter then info:SetDamagePosition(target:WorldSpaceCenter()) end
    if info.SetDamageForce then info:SetDamageForce(vector_origin) end
    local context = {statusDamage = true, statusProcIneligible = true,
        feedbackIneligible = true, moraleIneligible = true, statusId = entry.id,
        element = options.element, label = label}
    self:AttachDamageContext(info, context)
    target.LODPendingStatusDamageContext = context
    target:TakeDamageInfo(info)
    target.LODPendingStatusDamageContext = nil
    self.Stats.statusDamage = self.Stats.statusDamage + resolved
    return true
end

function System:ObserveCell(actor)
    local has, entry = self:Has(actor, "poisoned")
    if not has then return false end
    local key = self:CellKey(actor)
    if not key or key == entry.lastCellKey then return false end
    entry.lastCellKey = key
    local rng = self:_RNG("poison:step")
    self:_ApplyStatusDamage(actor, entry, rng:Int(1, 3), DMG_POISON, "Poison step")
    return true
end

function System:_ProcessImmolated(actor, entry, at)
    if at < (entry.nextTickAt or math.huge) then return end
    local rng = self:_RNG("immolated:tick")
    local damage, values = self:RollExploding(rng, 1, 6)
    self:_ApplyStatusDamage(actor, entry, damage, DMG_BURN, "Immolated",
        {element = "fire", contributions = values})
    if not isAlive(actor) or (entry.expiresAt and at >= entry.expiresAt) then return end
    local save = self:ConditionSave(actor, "dex", rng)
    self.Stats.saves = self.Stats.saves + 1
    if save >= entry.dc then self:Clear(actor, "immolated", "extinguished")
    else entry.nextTickAt = at + 1 end
end

function System:_ProcessPoisoned(actor, entry, at)
    if at < (entry.nextRecoveryAt or math.huge) then return end
    local rng = self:_RNG("poisoned:recovery")
    local save = self:ConditionSave(actor, "con", rng)
    self.Stats.saves = self.Stats.saves + 1
    if save >= entry.dc then self:Clear(actor, "poisoned", "recovered")
    else entry.nextRecoveryAt = at + self:RollExploding(rng, 9, 6) end
end

function System:_ProcessBleeding(actor, entry, at)
    if at < (entry.nextTickAt or math.huge) then return end
    local rng = self:_RNG("bleeding:tick")
    self:_ApplyStatusDamage(actor, entry, rng:Int(1, 3), DMG_SLASH, "Bleeding")
    if not isAlive(actor) then return end
    local save = self:ConditionSave(actor, "con", rng)
    self.Stats.saves = self.Stats.saves + 1
    if save >= entry.dc then self:Clear(actor, "bleeding", "recovered")
    else entry.nextTickAt = at + rng:Int(1, 3) end
end

function System:Process(at)
    at = at or now()
    for actor, states in pairs(self.Active) do
        if not isAlive(actor) then
            self.Active[actor] = nil
        else
            local ids = {}
            for id in pairs(states) do ids[#ids + 1] = id end
            for _, id in ipairs(ids) do
                local entry = states[id]
                if entry then
                    if entry.expiresAt and at >= entry.expiresAt then
                        self:Clear(actor, id, "expired")
                    elseif id == "immolated" then self:_ProcessImmolated(actor, entry, at)
                    elseif id == "poisoned" then self:_ProcessPoisoned(actor, entry, at)
                    elseif id == "bleeding" then self:_ProcessBleeding(actor, entry, at) end
                end
            end
        end
    end
    self:_Schedule()
end

function System:IsArcaneShieldOnline(actor)
    local d = derived(actor)
    local fraction = tonumber(d and d.hpToMagicDiversionFraction) or 0
    return fraction > 0 and not self:Has(actor, "arcane_shattered")
end

function System:MoraleDC(source)
    local featBonus = owns(source, "CHA_MENACE_3") and 4
        or owns(source, "CHA_MENACE_2") and 4
        or owns(source, "CHA_MENACE_1") and 2 or 0
    local authored = derived(source) and derived(source).moraleDCBonus
    return 10 + modifier(score(source, "cha")) + math.floor((level(source) - 1) / 4)
        + (authored ~= nil and math.floor(tonumber(authored) or 0) or featBonus)
end

function System:MoraleSave(target, rng)
    local state = actorState(target)
    local bonus = state and state.moraleBonus
    if bonus == "immune" then return math.huge, 20 end
    local natural = rng:Int(1, 20)
    return natural + modifier(score(target, "cha")) + math.floor((level(target) - 1) / 4)
        + math.floor(tonumber(bonus) or 0)
        + math.floor(tonumber(derived(target) and derived(target).moraleSaveBonus) or 0), natural
end

function System:AttemptMorale(source, target, event)
    event = event or {}
    if event.statusDamage or event.moraleIneligible or not isAlive(target)
        or self:IsImmune(target, isPlayer(target) and "intimidated" or "morale_flee")
    then return false, "ineligible" end
    local at = event.at or now()
    if at < (target.LODMoraleCooldownUntil or 0) then return false, "cooldown" end
    local maxHP = math.max(1, tonumber(event.maxHP)
        or (target.GetMaxHealth and target:GetMaxHealth()) or 1)
    local before = clamp(event.hpBefore or (target.Health and target:Health()) or maxHP, 0, maxHP)
    local damage = clamp(event.finalHPDamage, 0, before)
    local after = before - damage
    local trigger = event.forceMorale == true
    if isPlayer(target) then
        local featFraction = owns(source, "CHA_MENACE_3") and 0.20
            or owns(source, "CHA_MENACE_2") and 0.25
            or owns(source, "CHA_MENACE_1") and 0.30 or nil
        local authored = derived(source) and derived(source).humanMoraleTraumaFraction
        local fraction = tonumber(event.humanTraumaFraction)
            or tonumber(authored) or featFraction or (1 / 3)
        trigger = trigger or damage > fraction * maxHP
    else
        trigger = trigger or (before >= maxHP * 0.5 and after < maxHP * 0.5)
            or damage > maxHP / 3 or (before < maxHP * 0.5 and damage > 0)
    end
    if not trigger then return false, "no_trigger" end
    local rng = self:_RNG("morale", event.rng)
    local dc = self:MoraleDC(source)
    local save = self:MoraleSave(target, rng)
    local cooldown = 30 + rng:Int(1, 20) + rng:Int(1, 20) + rng:Int(1, 20)
    if not isPlayer(target) then cooldown = cooldown * 0.25 end
    target.LODMoraleCooldownUntil = at + cooldown
    self.Stats.moraleChecks = self.Stats.moraleChecks + 1
    if save >= dc then return true, "saved", {dc = dc, save = save, cooldown = cooldown} end
    self.Stats.moraleFailures = self.Stats.moraleFailures + 1
    if isPlayer(target) then
        local applied, reason, entry = self:Apply(target, "intimidated", source,
            {direct = true, rng = rng})
        return applied, reason, {dc = dc, save = save, cooldown = cooldown, entry = entry}
    end
    local duration = clamp(4 + (dc - save), 4, 10)
    local states = statusTable(target, true)
    states.morale_flee = {id = "morale_flee", source = source, appliedAt = at,
        expiresAt = at + duration, dc = dc, save = save}
    target.LODMoraleFleeSource = source
    target.LODMoraleFleeUntil = at + duration
    target.LODTarget = nil
    target.LODTargetWasMoraleFlee = true
    syncStatus(target, "morale_flee", true, at + duration)
    hook.Run("LODStatusApplied", target, "morale_flee", source, states.morale_flee)
    self:_Schedule()
    return true, "flee", {dc = dc, save = save, cooldown = cooldown, duration = duration}
end

function System:ObserveDamage(target, dmginfo, defenseResult)
    if not valid(target) or not dmginfo then return false end
    local context = self:DamageContext(dmginfo, target)
    local source = dmginfo.GetAttacker and dmginfo:GetAttacker() or nil
    local before = math.max(0, target.Health and target:Health() or 0)
    local finalDamage = math.min(before, math.max(0, dmginfo:GetDamage()))
    if finalDamage <= 0 then return false end
    local survives = before - finalDamage > 0
    local maxHP = target.GetMaxHealth and target:GetMaxHealth() or before
    if survives and not context.statusDamage then
        context.riderConsumedTargets = context.riderConsumedTargets
            or setmetatable({}, {__mode = "k"})
        if context.riderStatusId and not context.riderConsumedTargets[target] then
            context.riderConsumedTargets[target] = true
            self:Apply(target, context.riderStatusId, source, {dc = context.riderDC})
        end
        self:AttemptMorale(source, target, {
            hpBefore = before, maxHP = maxHP, finalHPDamage = finalDamage,
            forceMorale = context.forceMorale, moraleIneligible = context.moraleIneligible,
            statusDamage = context.statusDamage,
            humanTraumaFraction = context.humanTraumaFraction
        })
        if context.magic and self:IsArcaneShieldOnline(target) then
            self:Apply(target, "arcane_shattered", source, {rng = context.rng})
        end
    end
    return true
end

function System:CanInitiateMagic(actor)
    return not self:Has(actor, "muted") and not self:Has(actor, "intimidated")
end

function System:CanInitiateAttack(actor)
    return not self:Has(actor, "intimidated")
end

function System:CanMoveVoluntarily(actor)
    return not self:Has(actor, "held")
end

function System:LocomotionMultiplier(actor)
    return self:Has(actor, "clumsy") and 0.5 or 1
end

function System:AimMultiplier(actor)
    return self:Has(actor, "clumsy") and 2 or 1
end

function System:AllowsFriendlyFire(actor)
    return self:Has(actor, "reckless") == true
end

function System:ChooseRecklessTarget(actor, graph, originCell, maximumDistance)
    if not self:AllowsFriendlyFire(actor) or not graph or not originCell
        or not LOD.MazeNavigator or not LOD.HostileRegistry
    then return nil end
    local navigator = LOD.MazeNavigator
    local candidates = {}
    for _, ally in ipairs(LOD.HostileRegistry:List() or {}) do
        if valid(ally) and ally ~= actor and ally.LODHostile and not ally.LODDead
            and (actor.LODEncounterId == nil or ally.LODEncounterId == actor.LODEncounterId)
        then
            local cell = navigator:WorldToCell(graph, ally:GetPos())
            local distance = cell and navigator:Distance(graph, originCell, cell) or math.huge
            if distance ~= math.huge and (maximumDistance == nil or distance <= maximumDistance) then
                candidates[#candidates + 1] = {actor = ally, distance = distance,
                    world = actor:GetPos():DistToSqr(ally:GetPos())}
            end
        end
    end
    if #candidates == 0 or self:_RNG("reckless:betrayal"):Int(1, 3) ~= 1 then return nil end
    table.sort(candidates, function(a, b)
        if a.distance ~= b.distance then return a.distance < b.distance end
        if a.world ~= b.world then return a.world < b.world end
        return a.actor:EntIndex() < b.actor:EntIndex()
    end)
    actor.LODRecklessAllyTarget = candidates[1].actor
    return candidates[1].actor, candidates[1].distance
end

function System:HandleAIFlee(actor, graph, motion)
    local fleeing, entry = self:Has(actor, "morale_flee")
    if not fleeing then return false end
    if not motion or not graph or not LOD.MazeNavigator then return true end
    if not self:CanMoveVoluntarily(actor) then motion:Stop(actor) return true end
    local navigator = LOD.MazeNavigator
    local here = navigator:WorldToCell(graph, actor:GetPos())
    local source = entry.source
    local sourceCell = valid(source) and navigator:WorldToCell(graph, source:GetPos()) or nil
    if not here or not sourceCell then motion:Stop(actor) return true end
    local hereDistance = navigator:Distance(graph, here, sourceCell)
    local candidates = {}
    for key in pairs(here.neighbors or {}) do candidates[#candidates + 1] = key end
    table.sort(candidates)
    local best, bestDistance = nil, hereDistance
    for _, key in ipairs(candidates) do
        local cell = graph.Cells[key]
        if cell and navigator:CanTraverse(graph,
            string.format("%d:%d:%d", here.x, here.y, here.z), key)
        then
            local distance = navigator:Distance(graph, cell, sourceCell)
            if distance > bestDistance then best, bestDistance = cell, distance end
        end
    end
    if best then
        motion:MoveToward(actor, {pos = navigator:CellCenter(best) + Vector(0, 0, 2),
            tolerance = 18, stair = best.z ~= here.z})
    else
        motion:Stop(actor)
    end
    return true
end

if Rules and not System.RulesWrapped then
    System.RulesWrapped = true
    local baseResolve = Rules.ResolveDamageContract
    function Rules:ResolveDamageContract(contract, attacker, target, tags)
        local resolved, reduced, resistance = baseResolve(self, contract, attacker, target, tags)
        local elementResult
        resolved, elementResult = System:ResolveElementDamage(resolved, attacker, target, tags)
        if tags then tags.elementResolution = elementResult end
        return resolved, reduced, resistance, elementResult
    end
    local baseMove = Rules.MovementMultiplier
    function Rules:MovementMultiplier(actor)
        return baseMove(self, actor) * System:LocomotionMultiplier(actor)
    end
    local baseAim = Rules.AimSpreadMultiplier
    function Rules:AimSpreadMultiplier(actor)
        return baseAim(self, actor) * System:AimMultiplier(actor)
    end
end

hook.Add("SetupMove", "LOD_RPG_StatusHeld", function(ply, move)
    if not System:CanMoveVoluntarily(ply) then
        move:SetForwardSpeed(0)
        move:SetSideSpeed(0)
        move:SetUpSpeed(0)
        move:SetMaxClientSpeed(0)
        move:SetMaxSpeed(0)
    end
end)

hook.Add("FinishMove", "LOD_RPG_StatusPoisonCell", function(ply)
    System:ObserveCell(ply)
end)

hook.Add("StartCommand", "LOD_RPG_StatusActionLocks", function(ply, cmd)
    if System:Has(ply, "held") then
        cmd:RemoveKey(IN_FORWARD)
        cmd:RemoveKey(IN_BACK)
        cmd:RemoveKey(IN_MOVELEFT)
        cmd:RemoveKey(IN_MOVERIGHT)
        cmd:RemoveKey(IN_SPEED)
        cmd:RemoveKey(IN_JUMP)
    end
    if System:Has(ply, "intimidated") then
        cmd:RemoveKey(IN_ATTACK)
        cmd:RemoveKey(IN_ATTACK2)
    elseif System:Has(ply, "muted") then
        cmd:RemoveKey(IN_ATTACK2)
    end
end)

function System:ValidateMatrix()
    local errors = {}
    local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    local function scripted(values)
        local index = 0
        return {Int = function(_, low, high)
            index = index + 1
            return clamp(values[index] or low, low, high)
        end}
    end
    expect(#self.Elements == 6, "six elements")
    for _, element in ipairs(self.Elements) do
        local weak, weakInfo = self:ResolveElementDamage(100, nil, nil,
            {element = element, targetWeaknesses = {element}}, scripted({8}))
        local resist, resistInfo = self:ResolveElementDamage(100, nil, nil,
            {element = element, targetElement = element}, scripted({8}))
        local neutral, neutralInfo = self:ResolveElementDamage(100, nil, nil,
            {element = element}, scripted({8}))
        expect(math.abs(weak - 188) < 0.001 and weakInfo.kind == "weakness",
            element .. " weakness")
        expect(math.abs(resist - 12) < 0.001 and resistInfo.kind == "resistance",
            element .. " resistance")
        expect(neutral == 100 and neutralInfo.kind == "neutral", element .. " neutral")
    end
    for _, id in ipairs({"clumsy", "immolated", "poisoned", "bleeding", "muted",
        "held", "reckless", "arcane_shattered", "intimidated"}) do
        expect(self.Registry[id] ~= nil, "status registry " .. id)
    end
    expect(self.Registry.clumsy.ability == "dex" and self.Registry.immolated.ability == "dex",
        "DEX status lane")
    expect(self.Registry.poisoned.ability == "con" and self.Registry.bleeding.ability == "con",
        "CON status lane")
    expect(self.Registry.muted.ability == "wis" and self.Registry.held.ability == "wis"
        and self.Registry.reckless.ability == "wis", "WIS status lane")
    expect(self.Registry.arcane_shattered.ability == "int", "INT status lane")
    expect(self.Registry.intimidated.ability == "cha", "CHA status lane")
    local actor = {LODStatusValidationActor = true, LODProgressionState = {level = 1, abilities = {
        str = 10, dex = 10, con = 10, int = 10, wis = 10, cha = 10},
        derivedStats = {}}, health = 100}
    function actor:IsPlayer() return false end
    function actor:Health() return self.health end
    function actor:GetMaxHealth() return 100 end
    function actor:SetNW2Bool() end
    function actor:SetNW2Float() end
    local applied, reason, entry = self:Apply(actor, "clumsy", nil,
        {rng = scripted({1, 4}), dc = 20})
    expect(applied and reason == "applied" and math.abs(entry.expiresAt - (now() + 5)) < 0.001,
        "failed save applies duration")
    local repeated, repeatReason = self:Apply(actor, "clumsy", nil,
        {rng = scripted({1, 1}), dc = 20})
    expect(repeated and repeatReason == "extended" and self:LocomotionMultiplier(actor) == 0.5,
        "duplicate does not stack and preserves effect")
    for _, id in ipairs({"immolated", "poisoned", "bleeding", "muted", "held",
        "reckless", "arcane_shattered", "intimidated"}) do
        local resolved, resolvedReason = self:Apply(actor, id, nil,
            {direct = true, dc = 20, rng = scripted({1, 1, 1, 1, 1, 1, 1, 1, 1})})
        expect(resolved and resolvedReason == "applied", id .. " resolves through registry")
    end
    local invalid, invalidReason = self:Apply(actor, "not_a_status", nil,
        {direct = true, rng = scripted({1})})
    expect(not invalid and invalidReason == "invalid", "invalid status cannot proc")
    actor.LODStatusImmunities = {held = true}
    local immune, immuneReason = self:Apply(actor, "held", nil,
        {rng = scripted({1}), dc = 20})
    expect(not immune and immuneReason == "immune", "explicit immunity")
    local moraleActor = {LODStatusValidationActor = true, LODProgressionState = {
        level = 1, abilities = {str = 10, dex = 10, con = 10, int = 10, wis = 10, cha = 10},
        derivedStats = {}, moraleBonus = 0}, health = 100}
    function moraleActor:IsPlayer() return false end
    function moraleActor:Health() return self.health end
    function moraleActor:GetMaxHealth() return 100 end
    function moraleActor:SetNW2Bool() end
    function moraleActor:SetNW2Float() end
    local moraleResolved, moraleReason = self:AttemptMorale(actor, moraleActor, {
        hpBefore = 100, maxHP = 100, finalHPDamage = 40,
        rng = scripted({1, 1, 1, 1})})
    expect(moraleResolved and moraleReason == "flee", "Morale Flee resolves through registry")
    local recursive, recursiveReason = self:AttemptMorale(actor, moraleActor, {
        hpBefore = 60, maxHP = 100, finalHPDamage = 40, statusDamage = true,
        rng = scripted({1})})
    expect(not recursive and recursiveReason == "ineligible", "status damage cannot recurse")
    self.Active[actor] = nil
    self.Active[moraleActor] = nil
    return #errors == 0, errors
end

if LOD.RPGValidation and not System.ValidationWrapped then
    System.ValidationWrapped = true
    local baseRun = LOD.RPGValidation.Run
    function LOD.RPGValidation:Run(printResult)
        local baseOK, errors = baseRun(self, false)
        errors = errors or {}
        local matrixOK, matrixErrors = System:ValidateMatrix()
        for _, message in ipairs(matrixErrors) do errors[#errors + 1] = "Status/element: " .. message end
        local ok = baseOK and matrixOK and #errors == 0
        if printResult ~= false then
            if ok then print("[LOD:RPG] integrated status/element validation PASS")
            else
                ErrorNoHalt("[LOD:RPG] integrated status/element validation FAILED\n")
                for _, message in ipairs(errors) do ErrorNoHalt("[LOD:RPG]  - " .. message .. "\n") end
            end
        end
        return ok, errors
    end
end

concommand.Add("lod_rpg_status_element_validate", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if valid(ply) and not ply:IsAdmin() then return end
    local ok, errors = System:ValidateMatrix()
    if ok then print("[LOD:RPG-STATUS] matrix PASS — six elements; nine statuses; immunity/non-stack guards")
    else for _, message in ipairs(errors) do ErrorNoHalt("[LOD:RPG-STATUS] " .. message .. "\n") end end
end)

return System
