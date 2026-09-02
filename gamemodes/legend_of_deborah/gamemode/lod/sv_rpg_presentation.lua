LOD = LOD or {}
LOD.RPGPresentation = LOD.RPGPresentation or {}

local Presentation = LOD.RPGPresentation
local CELEBRATION_NET = "LOD_RPGCelebrationFX"
local FX_FEEDBACK = 1
local FX_LEVEL_UP = 2
local FX_FEAT_CONFIRM = 3

Presentation.SourceDocumentId = "1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY"
Presentation.SourceRevisionId = "AIroW36s25ioPk9DIsvM8gX9POD03soJPmktICQwL53j2ZNtX0cD6CDj4tnG78jDYD8nJtyekJCWOllqzOEkZLn-QdKjNR_ovnEPTA9XOQ"
Presentation.ArcaneSurgeFeedCooldown = 0.12
Presentation.Stats = Presentation.Stats or {
    feedbackFX = 0,
    levelUpFX = 0,
    featConfirmFX = 0,
    arcaneSurgeNotices = 0
}

util.AddNetworkString(CELEBRATION_NET)

local function combatRolls()
    return LOD.CombatRolls
end

local function testLog()
    return LOD.RPGTestLog
end

local function entityLabel(ent)
    if not IsValid(ent) then return "invalid" end
    if ent:IsPlayer() then
        return string.format("player:%s#%d", tostring(ent:Nick()), ent:EntIndex())
    end
    if ent.LODHostile then
        return string.format("hostile:%s#%d", tostring(ent.LODArchetypeId or ent:GetClass()), ent:EntIndex())
    end
    return string.format("%s#%d", tostring(ent:GetClass()), ent:EntIndex())
end

local function formulaText(contract)
    if not contract then return "" end
    if contract.formula then return tostring(contract.formula) end
    local profile = contract.profile or {}
    local count = math.max(1, math.floor(tonumber(profile.count) or 1))
    local sides = math.max(1, math.floor(tonumber(profile.sides) or 1))
    local text = string.format("%dd%d", count, sides)
    if profile.exploding then text = text .. "!" end
    local bonus = tonumber(profile.bonus) or 0
    if bonus > 0 then text = text .. "+" .. tostring(bonus) end
    if bonus < 0 then text = text .. tostring(bonus) end
    return text
end

local function logEvent(name, fields)
    local log = testLog()
    if log and log.Write then log:Write(name, fields or {}) end
end

local function feed(ply, category, text)
    local rolls = combatRolls()
    if IsValid(ply) and rolls and rolls._Send then
        rolls:_Send(ply, category or 3, tostring(text or ""))
    end
end

function Presentation:SendFX(ply, kind, primary, secondary)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    net.Start(CELEBRATION_NET)
    net.WriteUInt(math.Clamp(math.floor(tonumber(kind) or 0), 0, 7), 3)
    net.WriteString(tostring(primary or ""))
    net.WriteString(tostring(secondary or ""))
    net.Send(ply)
    return true
end

local function definitionLabel(definition, fallback)
    if not definition then return tostring(fallback or "Feat") end
    return tostring(definition.name or definition.label or definition.title or definition.id or fallback or "Feat")
end

function Presentation:InstallProgressionPresentation()
    local progression = LOD.CharacterProgressionSystem
    if not progression or not progression.AdvanceHeroToLevel or not progression.CommitFeat then return false end
    if self.ProgressionWrapped then return true end

    self.ProgressionWrapped = true

    self.BaseAdvanceHeroToLevel = progression.AdvanceHeroToLevel
    function progression:AdvanceHeroToLevel(ply, targetLevel)
        local runManager = LOD.RunManager
        local ps = runManager and runManager.GetPlayerState and runManager:GetPlayerState(ply) or nil
        local beforeLevel = tonumber(ps and ps.progressionState and ps.progressionState.level) or 0
        local results = {Presentation.BaseAdvanceHeroToLevel(self, ply, targetLevel)}
        local ok = results[1] == true

        ps = runManager and runManager.GetPlayerState and runManager:GetPlayerState(ply) or ps
        local afterLevel = tonumber(ps and ps.progressionState and ps.progressionState.level) or beforeLevel
        if ok and afterLevel > beforeLevel and IsValid(ply) then
            Presentation:SendFX(ply, FX_LEVEL_UP, "LEVEL UP!", "PRESS P TO SEE")
            feed(ply, 2, string.format("LEVEL UP! %d → %d — Press P to see progression.",
                beforeLevel, afterLevel))
            Presentation.Stats.levelUpFX = (Presentation.Stats.levelUpFX or 0) + 1
            logEvent("RPG_LEVEL_UP_PRESENTATION", {
                player = entityLabel(ply),
                from_level = beforeLevel,
                to_level = afterLevel
            })
        end
        return unpack(results)
    end

    self.BaseCommitFeat = progression.CommitFeat
    function progression:CommitFeat(ply, featId, expectedEarnedAtLevel)
        local definition = self._FindFeat and self:_FindFeat(featId) or nil
        local label = definitionLabel(definition, featId)
        local results = {Presentation.BaseCommitFeat(self, ply, featId, expectedEarnedAtLevel)}
        if results[1] == true and IsValid(ply) then
            Presentation:SendFX(ply, FX_FEAT_CONFIRM, "FEAT CHOSEN", label)
            feed(ply, 3, "FEAT CHOSEN — " .. label)
            Presentation.Stats.featConfirmFX = (Presentation.Stats.featConfirmFX or 0) + 1
            logEvent("RPG_FEAT_CONFIRMATION", {
                player = entityLabel(ply),
                feat = tostring(featId or ""),
                label = label,
                kind = "ordinary"
            })
        end
        return unpack(results)
    end

    if progression.CommitCapstone then
        self.BaseCommitCapstone = progression.CommitCapstone
        function progression:CommitCapstone(ply, featId)
            local results = {Presentation.BaseCommitCapstone(self, ply, featId)}
            if results[1] == true and IsValid(ply) then
                local runManager = LOD.RunManager
                local ps = runManager and runManager.GetPlayerState and runManager:GetPlayerState(ply) or nil
                local state = ps and ps.progressionState or nil
                local definition = state and self._CapstoneDefinition and self:_CapstoneDefinition(state) or nil
                local label = definitionLabel(definition, featId)
                Presentation:SendFX(ply, FX_FEAT_CONFIRM, "CAPSTONE CHOSEN", label)
                feed(ply, 3, "CAPSTONE CHOSEN — " .. label)
                Presentation.Stats.featConfirmFX = (Presentation.Stats.featConfirmFX or 0) + 1
                logEvent("RPG_FEAT_CONFIRMATION", {
                    player = entityLabel(ply),
                    feat = tostring(featId or ""),
                    label = label,
                    kind = "capstone"
                })
            end
            return unpack(results)
        end
    end

    return true
end

function Presentation:InstallFeedbackPresentation()
    local wizard = LOD.RPGWizardOffense
    if not wizard or not wizard.TryFeedback or not wizard.ApplyFeedback then return false end
    if self.FeedbackWrapped then return true end
    self.FeedbackWrapped = true

    self.BaseTryFeedback = wizard.TryFeedback
    function wizard:TryFeedback(ply, dmginfo, defenseResult)
        local stats = self.Stats or {}
        local checksBefore = tonumber(stats.feedbackChecks) or 0
        local blocksBefore = tonumber(stats.feedbackCooldownBlocks) or 0
        local derived
        local rules = LOD.RPGAbilityRules
        if rules and rules.Derived and IsValid(ply) then derived = rules:Derived(ply) end
        local chance = self.FeedbackChanceFromDerived and self:FeedbackChanceFromDerived(derived) or 0
        local attacker = dmginfo and dmginfo.GetAttacker and dmginfo:GetAttacker() or nil
        local result = Presentation.BaseTryFeedback(self, ply, dmginfo, defenseResult)
        local checksAfter = tonumber((self.Stats or {}).feedbackChecks) or checksBefore
        local blocksAfter = tonumber((self.Stats or {}).feedbackCooldownBlocks) or blocksBefore

        if blocksAfter > blocksBefore then
            logEvent("WIZARD_FEEDBACK_COOLDOWN", {
                player = entityLabel(ply),
                attacker = entityLabel(attacker),
                chance = chance,
                remaining = IsValid(ply)
                    and math.max(0, (tonumber(ply.LODWizardFeedbackNextReadyAt) or 0) - CurTime()) or 0
            })
        elseif checksAfter > checksBefore then
            logEvent("WIZARD_FEEDBACK_CHECK", {
                player = entityLabel(ply),
                attacker = entityLabel(attacker),
                chance = chance,
                proc = result == true
            })
        end
        return result
    end

    self.BaseApplyFeedback = wizard.ApplyFeedback
    function wizard:ApplyFeedback(ply, attacker, diceCount, intBonus)
        local damageBefore = tonumber((self.Stats or {}).feedbackDamage) or 0
        local ok = Presentation.BaseApplyFeedback(self, ply, attacker, diceCount, intBonus)
        if ok and IsValid(ply) then
            local damageAfter = tonumber((self.Stats or {}).feedbackDamage) or damageBefore
            local damage = math.max(0, damageAfter - damageBefore)
            local count = math.max(1, math.floor(tonumber(diceCount) or 1))
            local bonus = math.max(0, math.floor(tonumber(intBonus) or 0))
            local formula = string.format("%dd4%s", count, bonus > 0 and ("+" .. bonus) or "")
            local detail = string.format("%s → %.1f DAMAGE", formula, damage)

            Presentation:SendFX(ply, FX_FEEDBACK, "FEEDBACK!", detail)
            feed(ply, 0, string.format("FEEDBACK! %s = %.1f damage to %s",
                formula, damage, IsValid(attacker) and tostring(attacker.LODConfig and attacker.LODConfig.name
                    or attacker.LODArchetypeId or "enemy") or "enemy"))
            Presentation.Stats.feedbackFX = (Presentation.Stats.feedbackFX or 0) + 1
            logEvent("WIZARD_FEEDBACK_PROC", {
                player = entityLabel(ply),
                attacker = entityLabel(attacker),
                dice = count,
                int_bonus = bonus,
                formula = formula,
                damage = damage,
                cooldown_seconds = tonumber(self.FeedbackCooldownSeconds) or 0
            })
        end
        return ok
    end

    return true
end

function Presentation:InstallArcaneSurgePresentation()
    if self.ArcaneSurgeWrapped then return true end
    local wizard = LOD.RPGWizardOffense
    local rules = LOD.RPGAbilityRules
    if not wizard or not wizard.IntegrationReady or not rules or not rules.ResolveDamageContract then return false end

    self.BaseResolveDamageContract = rules.ResolveDamageContract
    function rules:ResolveDamageContract(contract, attacker, target, tags)
        local resolved, reduced, resistance = Presentation.BaseResolveDamageContract(self, contract, attacker, target, tags)
        local bonus = math.max(0, math.floor(tonumber(contract and contract.wizardFullMagicIntBonus) or 0))
        if contract and contract.ignoreWizardFullMagicIntBonus ~= true and bonus > 0
            and IsValid(attacker) and wizard:IsWizard(attacker)
        then
            logEvent("WIZARD_FULL_MAGIC_BONUS", {
                player = entityLabel(attacker),
                target = entityLabel(target),
                bonus = bonus,
                formula = formulaText(contract),
                source = tostring(contract.weaponClass
                    or (contract.profile and (contract.profile.source or contract.profile.label)) or ""),
                raw = tonumber(contract.total) or "",
                resolved = resolved
            })

            if not contract.LODArcaneSurgePresented then
                contract.LODArcaneSurgePresented = true
                local now = CurTime()
                if now >= (tonumber(attacker.LODArcaneSurgeNextNoticeAt) or 0) then
                    attacker.LODArcaneSurgeNextNoticeAt = now + Presentation.ArcaneSurgeFeedCooldown
                    feed(attacker, 0, string.format("ARCANE SURGE — FULL MAGIC +%d INT DAMAGE", bonus))
                    Presentation.Stats.arcaneSurgeNotices =
                        (Presentation.Stats.arcaneSurgeNotices or 0) + 1
                end
            end
        end
        return resolved, reduced, resistance
    end

    self.ArcaneSurgeWrapped = true
    return true
end

local function installAll()
    Presentation:InstallProgressionPresentation()
    Presentation:InstallFeedbackPresentation()
    if Presentation:InstallArcaneSurgePresentation() then
        timer.Remove("LOD_RPGPresentationInstall")
    end
end

timer.Create("LOD_RPGPresentationInstall", 0.10, 0, installAll)
timer.Simple(0, installAll)
hook.Add("InitPostEntity", "LOD_RPGPresentationInstall", installAll)

concommand.Add("lod_rpg_presentation_validate", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    installAll()
    local ok = Presentation.ProgressionWrapped == true
        and Presentation.FeedbackWrapped == true
        and Presentation.ArcaneSurgeWrapped == true
    local line = string.format(
        "RPG presentation validation %s - feedHold=9.0s progression=%s feedback=%s arcaneSurge=%s",
        ok and "PASS" or "FAILED",
        tostring(Presentation.ProgressionWrapped == true),
        tostring(Presentation.FeedbackWrapped == true),
        tostring(Presentation.ArcaneSurgeWrapped == true))
    print("[LOD:RPG-PRESENTATION] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
