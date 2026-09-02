LOD = LOD or {}
LOD.RPGWizardOffense = LOD.RPGWizardOffense or {}

local WizardOffense = LOD.RPGWizardOffense

WizardOffense.SourceDocumentId = "1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY"
WizardOffense.SourceRevisionId = "ANLCKQkNcjBF3sFnckn_5ExOJDK0c-DXb291V5jp_bjHB-KnEf7LMJJeKGpB6mAQDFUwZk1ZhRLm1MfvE0i1TjrZSTmnbeVr2HOKoXy_KQ"
WizardOffense.FeedbackContractMaxAge = 0.20
WizardOffense.FeedbackCooldownSeconds = 1.0
WizardOffense.FullMagicAttackMemory = 0.30
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

function WizardOffense:FullMagicBonus(actor)
    if not self:IsWizard(actor) then return 0 end
    local forced = tonumber(actor.LODWizardFullMagicAttackOverride)
    if forced ~= nil then return math.max(0, math.floor(forced)) end
    local current, maximum = self:CurrentMagic(actor)
    if current == nil or maximum == nil or current < maximum - 0.0001 then return 0 end
    return self:IntBonus(actor)
end

function WizardOffense:FeedbackDiceCount(contract)
    return math.max(0, #(contract and contract.values or {}))
end

function WizardOffense:RememberFullMagicAttack(actor, bonus)
    if not IsValid(actor) then return end
    actor.LODWizardLastFullMagicAttack = {
        at = CurTime(),
        bonus = math.max(0, math.floor(tonumber(bonus) or 0))
    }
end

function WizardOffense:RecentFullMagicBonus(actor)
    if not IsValid(actor) then return 0 end
    local remembered = actor.LODWizardLastFullMagicAttack
    if not remembered or CurTime() - (tonumber(remembered.at) or -999) > self.FullMagicAttackMemory then
        return 0
    end
    return math.max(0, math.floor(tonumber(remembered.bonus) or 0))
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

    local priorRollActorDamage = combatRolls.RollActorDamage
    function combatRolls:RollActorDamage(attacker, profile, rng, bonusDice)
        local rolled = priorRollActorDamage(self, attacker, profile, rng, bonusDice)
        if rolled and IsValid(attacker) then
            local bonus = WizardOffense:FullMagicBonus(attacker)
            rolled.wizardFullMagicIntBonus = bonus
            WizardOffense:RememberFullMagicAttack(attacker, bonus)
        end
        return rolled
    end

    local priorRollPlayerWeapon = combatRolls.RollPlayerWeapon
    function combatRolls:RollPlayerWeapon(ply, weaponClass)
        local contract = priorRollPlayerWeapon(self, ply, weaponClass)
        if contract and IsValid(ply) then
            local bonus = WizardOffense:FullMagicBonus(ply)
            contract.wizardFullMagicIntBonus = bonus
            WizardOffense:RememberFullMagicAttack(ply, bonus)
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
            if bonus == nil then bonus = WizardOffense:RecentFullMagicBonus(attacker) end
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
        local previous = IsValid(ply) and ply.LODWizardFullMagicAttackOverride or nil
        local bonus = IsValid(ply) and WizardOffense:FullMagicBonus(ply) or 0
        if IsValid(ply) then ply.LODWizardFullMagicAttackOverride = bonus end
        local ok = priorCastForceShout(self, ply)
        if IsValid(ply) then ply.LODWizardFullMagicAttackOverride = previous end
        return ok
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
    local cooldownRemaining = IsValid(ply)
        and math.max(0, (tonumber(ply.LODWizardFeedbackNextReadyAt) or 0) - CurTime()) or 0
    return #errors == 0, errors, {
        classId = state and state.classId or "none",
        level = state and state.level or 0,
        intMod = tonumber(derived and derived.intMod) or 0,
        magic = tonumber(currentMagic) or 0,
        fullMagicBonus = IsValid(ply) and self:FullMagicBonus(ply) or 0,
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
