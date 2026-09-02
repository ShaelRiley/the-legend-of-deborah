LOD = LOD or {}
LOD.RPGWizardOffense = LOD.RPGWizardOffense or {}

local WizardOffense = LOD.RPGWizardOffense

WizardOffense.SourceDocumentId = "1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY"
WizardOffense.SourceRevisionId = "ANLCKQkNcjBF3sFnckn_5ExOJDK0c-DXb291V5jp_bjHB-KnEf7LMJJeKGpB6mAQDFUwZk1ZhRLm1MfvE0i1TjrZSTmnbeVr2HOKoXy_KQ"
WizardOffense.FeedbackContractMaxAge = 0.20
WizardOffense.FeedbackCooldownSeconds = 1.0
WizardOffense.ActiveFullMagicSnapshots = WizardOffense.ActiveFullMagicSnapshots
    or setmetatable({}, {__mode = "k"})
WizardOffense.Stats = WizardOffense.Stats or {
    fullMagicBonusEvents = 0,
    fullMagicBonusDamage = 0,
    feedbackChecks = 0,
    feedbackProcs = 0,
    feedbackCooldownBlocks = 0,
    feedbackDice = 0,
    feedbackDamage = 0
}

util.AddNetworkString("LOD_WizardFeedbackFX")

local function rules()
    return LOD.RPGAbilityRules
end

local function rolls()
    return LOD.CombatRolls
end

local function magic()
    return LOD.Magic
end

function WizardOffense:ProgressionState(actor)
    local abilityRules = rules()
    return abilityRules and abilityRules.ProgressionState
        and abilityRules:ProgressionState(actor) or nil
end

function WizardOffense:IsWizard(actor)
    local state = self:ProgressionState(actor)
    return state and state.classId == "wizard" or false
end

function WizardOffense:IntBonusFromDerived(derived)
    return math.max(0, math.floor(tonumber(derived and derived.intMod) or 0))
end

function WizardOffense:IntBonus(actor)
    local abilityRules = rules()
    local derived = abilityRules and abilityRules.Derived and abilityRules:Derived(actor) or nil
    return self:IntBonusFromDerived(derived)
end

function WizardOffense:FeedbackChanceFromDerived(derived)
    return math.Clamp(tonumber(derived and derived.hpToMagicDiversionFraction) or 0, 0, 1)
end

function WizardOffense:CurrentMagic(actor)
    if not IsValid(actor) or not actor:IsPlayer() then return nil, nil end
    local authority = magic()
    local ps = authority and authority._EnsureState and authority:_EnsureState(actor) or nil
    if not ps then return nil, nil end
    return tonumber(ps.magic), 100
end

-- This is intentionally a pure read of the Wizard's current authored state.
-- Attack snapshots belong on attack contracts (or the tightly scoped Force Shout
-- snapshot below), never on a persistent player field. A stale player override
-- could otherwise report or apply a positive bonus after INT changed or went
-- negative, which is exactly the bug this module guards against.
function WizardOffense:FullMagicBonus(actor)
    if not self:IsWizard(actor) then return 0 end
    local current, maximum = self:CurrentMagic(actor)
    if current == nil or maximum == nil or current < maximum - 0.0001 then return 0 end
    return self:IntBonus(actor)
end

function WizardOffense:AttackSnapshotBonus(actor)
    if not IsValid(actor) then return 0 end
    local snapshot = self.ActiveFullMagicSnapshots[actor]
    if snapshot ~= nil then return math.max(0, math.floor(tonumber(snapshot) or 0)) end
    return self:FullMagicBonus(actor)
end

function WizardOffense:FeedbackDiceCount(contract)
    return math.max(0, #(contract and contract.values or {}))
end

function WizardOffense:EmitFeedbackFX(wizard, attacker)
    if not IsValid(wizard) or not IsValid(attacker) then return end
    local startPos = wizard:WorldSpaceCenter()
    if wizard.EyePos then startPos = wizard:EyePos() end
    local endPos = attacker:WorldSpaceCenter()

    net.Start("LOD_WizardFeedbackFX")
    net.WriteVector(startPos)
    net.WriteVector(endPos)
    net.Broadcast()

    wizard:EmitSound("ambient/energy/zap5.wav", 82, 108, 0.92, CHAN_STATIC)
    local effect = EffectData()
    effect:SetOrigin(endPos)
    effect:SetScale(0.65)
    util.Effect("StunstickImpact", effect, true, true)
end

local function valuesText(values)
    local out = {}
    for index, value in ipairs(values or {}) do out[index] = tostring(value) end
    return table.concat(out, "+")
end

function WizardOffense:ApplyFeedback(wizard, attacker, diceCount, intBonus)
    if not IsValid(wizard) or not IsValid(attacker) then return false end
    if not attacker.LODHostile or attacker.LODDead or attacker:Health() <= 0 then return false end

    local combatRolls = rolls()
    local abilityRules = rules()
    if not combatRolls or not combatRolls._RNG or not combatRolls._RollFormula
        or not abilityRules or not abilityRules.ResolveDamageContract
    then
        return false
    end

    diceCount = math.Clamp(math.floor(tonumber(diceCount) or 0), 1, 128)
    intBonus = math.max(0, math.floor(tonumber(intBonus) or 0))
    local rng = combatRolls:_RNG("wizard-feedback:" .. tostring(wizard:EntIndex()))
    local total, values = combatRolls:_RollFormula({
        count = diceCount,
        sides = 4,
        bonus = intBonus
    }, rng)
    local contract = {
        label = "FEEDBACK",
        source = "feedback",
        formula = string.format("%dd4%s", diceCount, intBonus > 0 and ("+" .. intBonus) or ""),
        total = total,
        values = values,
        contributions = table.Copy(values or {}),
        bonus = intBonus,
        baseDice = diceCount,
        ignoreWizardFullMagicIntBonus = true
    }
    local resolved = select(1, abilityRules:ResolveDamageContract(contract, wizard, attacker,
        {magic = true, wisScaled = false}))
    resolved = math.max(0, tonumber(resolved) or 0)
    if resolved <= 0 then return false end

    self:EmitFeedbackFX(wizard, attacker)

    local info = DamageInfo()
    info:SetAttacker(wizard)
    info:SetInflictor(wizard)
    info:SetDamage(resolved)
    info:SetDamageType(DMG_SHOCK)
    info:SetDamagePosition(attacker:WorldSpaceCenter())
    info:SetDamageForce(vector_origin)

    -- Feedback has already passed through the RPG dice resolver. Temporarily hide
    -- any same-frame firearm contract so the canonical player-firearm hook cannot
    -- reinterpret this nested shock damage as the Wizard's held weapon attack.
    local activePlayerRoll = wizard.LODActivePlayerRoll
    local activeShotgunRoll = wizard.LODActiveShotgunRoll
    wizard.LODActivePlayerRoll = nil
    wizard.LODActiveShotgunRoll = nil
    wizard.LODWizardFeedbackDamageActive = true
    attacker:TakeDamageInfo(info)
    wizard.LODWizardFeedbackDamageActive = nil
    wizard.LODActivePlayerRoll = activePlayerRoll
    wizard.LODActiveShotgunRoll = activeShotgunRoll

    self.Stats.feedbackProcs = (self.Stats.feedbackProcs or 0) + 1
    self.Stats.feedbackDice = (self.Stats.feedbackDice or 0) + diceCount
    self.Stats.feedbackDamage = (self.Stats.feedbackDamage or 0) + resolved

    if combatRolls._Send then
        local targetName = tostring(attacker.LODConfig and attacker.LODConfig.name
            or attacker.LODArchetypeId or "enemy")
        combatRolls:_Send(wizard, 3, string.format(
            "FEEDBACK — %s [%s] = %.1f damage to %s",
            contract.formula, valuesText(values), resolved, targetName))
    end
    return true
end

function WizardOffense:TryFeedback(wizard, dmginfo, defenseResult)
    if not IsValid(wizard) or not self:IsWizard(wizard) then return false end
    local finalHPDamage = tonumber(defenseResult and defenseResult.finalHPDamage)
        or (dmginfo and dmginfo.GetDamage and dmginfo:GetDamage()) or 0
    if finalHPDamage <= 0 then return false end

    local now = CurTime()
    if now < (tonumber(wizard.LODWizardFeedbackNextReadyAt) or 0) then
        self.Stats.feedbackCooldownBlocks = (self.Stats.feedbackCooldownBlocks or 0) + 1
        return false
    end

    local attacker = dmginfo and dmginfo.GetAttacker and dmginfo:GetAttacker() or nil
    if not IsValid(attacker) or not attacker.LODHostile or attacker.LODDead then return false end
    local source = attacker.LODWizardFeedbackLastHostileRoll
    if not source or source.attacker ~= attacker
        or now - (tonumber(source.at) or -999) > self.FeedbackContractMaxAge
    then
        return false
    end

    local diceCount = math.max(0, math.floor(tonumber(source.diceCount) or 0))
    if diceCount <= 0 then return false end
    local abilityRules = rules()
    local derived = abilityRules and abilityRules.Derived and abilityRules:Derived(wizard) or nil
    local chance = self:FeedbackChanceFromDerived(derived)
    if chance <= 0 then return false end

    local combatRolls = rolls()
    local rng = combatRolls and combatRolls._RNG
        and combatRolls:_RNG("wizard-feedback-proc:" .. tostring(wizard:EntIndex())) or nil
    if not rng then return false end
    self.Stats.feedbackChecks = (self.Stats.feedbackChecks or 0) + 1
    if rng:Float(0, 1) >= chance then return false end

    wizard.LODWizardFeedbackNextReadyAt = now + self.FeedbackCooldownSeconds
    local intBonus = self:IntBonus(wizard)
    timer.Simple(0, function()
        if IsValid(wizard) and IsValid(attacker) then
            WizardOffense:ApplyFeedback(wizard, attacker, diceCount, intBonus)
        end
    end)
    return true
end

function WizardOffense:Install()
    local combatRolls = rolls()
    local abilityRules = rules()
    local magicAuthority = magic()
    if not combatRolls or not combatRolls.RollActorDamage or not combatRolls.RollHostileAttack
        or not combatRolls.RollPlayerWeapon or not abilityRules
        or not abilityRules.ResolveDamageContract or not abilityRules.ApplyPlayerDefense
        or not magicAuthority or not magicAuthority.CastForceShout
    then
        return false
    end
    if self.IntegrationReady then return true end

    -- Clear the obsolete field on clean startup/hot load. FullMagicBonus no longer
    -- reads it, so even an old saved/stale value cannot affect combat or status.
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then ply.LODWizardFullMagicAttackOverride = nil end
    end

    local priorRollActorDamage = combatRolls.RollActorDamage
    function combatRolls:RollActorDamage(attacker, profile, rng, bonusDice)
        local rolled = priorRollActorDamage(self, attacker, profile, rng, bonusDice)
        if rolled and IsValid(attacker) then
            rolled.wizardFullMagicIntBonus = WizardOffense:AttackSnapshotBonus(attacker)
        end
        return rolled
    end

    local priorRollPlayerWeapon = combatRolls.RollPlayerWeapon
    function combatRolls:RollPlayerWeapon(ply, weaponClass)
        local contract = priorRollPlayerWeapon(self, ply, weaponClass)
        if contract and IsValid(ply) then
            contract.wizardFullMagicIntBonus = WizardOffense:FullMagicBonus(ply)
        end
        return contract
    end

    local priorRollHostileAttack = combatRolls.RollHostileAttack
    function combatRolls:RollHostileAttack(hostile, profile, originalDamage, cacheOwner)
        local contract = priorRollHostileAttack(self, hostile, profile, originalDamage, cacheOwner)
        if contract and IsValid(hostile) then
            hostile.LODWizardFeedbackLastHostileRoll = {
                at = CurTime(),
                attacker = hostile,
                diceCount = WizardOffense:FeedbackDiceCount(contract)
            }
        end
        return contract
    end

    local priorResolveDamageContract = abilityRules.ResolveDamageContract
    function abilityRules:ResolveDamageContract(contract, attacker, target, tags)
        local resolved, reduced, resistance = priorResolveDamageContract(self, contract, attacker, target, tags)
        if contract and contract.ignoreWizardFullMagicIntBonus ~= true and WizardOffense:IsWizard(attacker) then
            local bonus = tonumber(contract.wizardFullMagicIntBonus)
            if bonus == nil then bonus = WizardOffense:FullMagicBonus(attacker) end
            bonus = math.max(0, math.floor(tonumber(bonus) or 0))
            if bonus > 0 then
                resolved = math.max(0, tonumber(resolved) or 0) + bonus
                WizardOffense.Stats.fullMagicBonusEvents =
                    (WizardOffense.Stats.fullMagicBonusEvents or 0) + 1
                WizardOffense.Stats.fullMagicBonusDamage =
                    (WizardOffense.Stats.fullMagicBonusDamage or 0) + bonus
            end
        end
        return resolved, reduced, resistance
    end

    local priorApplyPlayerDefense = abilityRules.ApplyPlayerDefense
    function abilityRules:ApplyPlayerDefense(target, dmginfo)
        local result = priorApplyPlayerDefense(self, target, dmginfo)
        WizardOffense:TryFeedback(target, dmginfo, result)
        return result
    end

    local priorCastForceShout = magicAuthority.CastForceShout
    function magicAuthority:CastForceShout(ply)
        if not IsValid(ply) then return priorCastForceShout(self, ply) end

        -- Force Shout spends Magic before rolling its damage. Snapshot the authored
        -- full-Magic bonus just for the synchronous cast, then always restore the
        -- prior snapshot even if the underlying cast raises a Lua error.
        local previous = WizardOffense.ActiveFullMagicSnapshots[ply]
        WizardOffense.ActiveFullMagicSnapshots[ply] = WizardOffense:FullMagicBonus(ply)
        local ok, result = xpcall(function()
            return priorCastForceShout(self, ply)
        end, debug.traceback)
        WizardOffense.ActiveFullMagicSnapshots[ply] = previous
        if not ok then error(result, 0) end
        return result
    end

    self.IntegrationReady = true
    return true
end

local function install()
    if WizardOffense:Install() then
        hook.Remove("InitPostEntity", "LOD_WizardOffenseInstall")
    end
end

timer.Simple(0, install)
hook.Add("InitPostEntity", "LOD_WizardOffenseInstall", install)

function WizardOffense:Validate(ply)
    local errors = {}
    local function expect(condition, label)
        if not condition then errors[#errors + 1] = label end
    end

    expect(self:IntBonusFromDerived({intMod = 3}) == 3, "INT bonus +3")
    expect(self:IntBonusFromDerived({intMod = -2}) == 0, "negative INT modifier is not bonus damage")
    expect(math.abs(self:FeedbackChanceFromDerived({hpToMagicDiversionFraction = 0.325}) - 0.325) < 0.00001,
        "Feedback chance equals Arcane Diversion")
    expect(self:FeedbackDiceCount({values = {12, 11, 5, 1}}) == 4,
        "source explosion dice count as Feedback dice")
    expect(math.abs(self.FeedbackCooldownSeconds - 1.0) < 0.00001, "Feedback cooldown is 1 second")
    expect(self.IntegrationReady == true, "runtime integration")

    local abilityRules = rules()
    local state = IsValid(ply) and self:ProgressionState(ply) or nil
    local derived = IsValid(ply) and abilityRules and abilityRules.Derived
        and abilityRules:Derived(ply) or nil
    local currentMagic = IsValid(ply) and select(1, self:CurrentMagic(ply)) or 0
    local liveIntMod = tonumber(derived and derived.intMod) or 0
    local fullMagicBonus = IsValid(ply) and self:FullMagicBonus(ply) or 0
    local expectedFullMagicBonus = state and state.classId == "wizard" and currentMagic >= 99.9999
        and math.max(0, math.floor(liveIntMod)) or 0
    if IsValid(ply) then
        expect(fullMagicBonus == expectedFullMagicBonus,
            "live full-Magic bonus equals max(0, INT_MOD) only at 100 Magic")
    end

    local cooldownRemaining = IsValid(ply)
        and math.max(0, (tonumber(ply.LODWizardFeedbackNextReadyAt) or 0) - CurTime()) or 0
    return #errors == 0, errors, {
        classId = state and state.classId or "none",
        level = state and state.level or 0,
        intMod = liveIntMod,
        magic = tonumber(currentMagic) or 0,
        fullMagicBonus = fullMagicBonus,
        feedbackChance = self:FeedbackChanceFromDerived(derived),
        feedbackCooldown = self.FeedbackCooldownSeconds,
        cooldownRemaining = cooldownRemaining
    }
end

concommand.Add("lod_rpg_wizard_feedback_validate", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local target = IsValid(ply) and ply or player.GetAll()[1]
    local ok, errors, current = WizardOffense:Validate(target)
    local line = string.format(
        "Wizard offense validation %s - class=%s level=%d INTmod=%d magic=%.2f fullMagicBonus=%d feedbackChance=%.3f cooldown=%.1fs remaining=%.2fs example=4d4+INT",
        ok and "PASS" or "FAILED", tostring(current.classId), tonumber(current.level) or 0,
        math.floor(current.intMod), current.magic, current.fullMagicBonus, current.feedbackChance,
        current.feedbackCooldown, current.cooldownRemaining)
    print("[LOD:RPG-WIZARD-OFFENSE] " .. line)
    for _, err in ipairs(errors) do
        ErrorNoHalt("[LOD:RPG-WIZARD-OFFENSE] " .. tostring(err) .. "\n")
    end
    if IsValid(ply) then ply:ChatPrint(line) end
end)
