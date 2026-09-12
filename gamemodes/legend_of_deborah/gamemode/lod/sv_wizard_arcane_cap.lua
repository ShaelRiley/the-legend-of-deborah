LOD = LOD or {}
LOD.RPGWizardRules = LOD.RPGWizardRules or {}

local WizardRules = LOD.RPGWizardRules
local Progression = LOD.CharacterProgressionSystem
local RPG = LOD.RPG
local priorValidate = WizardRules.Validate

WizardRules.ArcaneDiversionCap = 0.50
WizardRules.WizardDiversionBase = 0.10
WizardRules.WizardDiversionPerLevelAfterFirst = 0.025

function WizardRules:ClassDiversionFraction(state)
    if not state or state.classId ~= "wizard" then return 0 end
    local level = math.Clamp(math.floor(tonumber(state.level) or 1), 1,
        RPG and RPG.Constants and RPG.Constants.HeroMaxLevel or 20)
    return math.min(self.ArcaneDiversionCap,
        self.WizardDiversionBase + self.WizardDiversionPerLevelAfterFirst * (level - 1))
end

-- Preserve every existing source of Arcane Shield and Living Aegis efficiency,
-- but make the canonical 50% ceiling an absolute final clamp. Level-20 capstone
-- availability is intentionally unaffected by this cap.
if not WizardRules.LODArcaneCapApplyWrapped then
    WizardRules.LODArcaneCapApplyWrapped = true
    local base = WizardRules.ApplyDerived
    function WizardRules:ApplyDerived(state)
        if base then base(self, state) end
        if not state or not state.derivedStats then return end
        local derived = state.derivedStats
        derived.wizardClassHpToMagicDiversionFraction = self:ClassDiversionFraction(state)
        derived.hpToMagicDiversionFraction = math.min(self.ArcaneDiversionCap,
            math.max(0, tonumber(derived.wizardClassHpToMagicDiversionFraction) or 0)
            + math.max(0, tonumber(derived.manaBarrierFeatDiversionFraction) or 0)
            + math.max(0, tonumber(derived.wizardCapstoneDiversionBonus) or 0))
    end
end

local function closeEnough(a, b)
    return math.abs((tonumber(a) or 0) - (tonumber(b) or 0)) < 0.00001
end

-- Supersede the pre-reconciliation validator that expected 57.5%/67.5% at Level
-- 20. This focused validator protects the current cap while leaving the existing
-- combat/Feedback validators to test their own behavior.
function WizardRules:ValidateArcaneCap()
    local errors = {}
    local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    local function state(level, capstoneBonus)
        local s = {classId = "wizard", level = level, derivedStats = {
            manaBarrierFeatDiversionFraction = 0,
            wizardCapstoneDiversionBonus = capstoneBonus or 0,
            livingAegisHPPerMagic = capstoneBonus and capstoneBonus > 0 and 1.50 or 1
        }}
        self:ApplyDerived(s)
        return s
    end
    local l1 = state(1)
    local l16 = state(16)
    local l17 = state(17)
    local l20 = state(20)
    local l20Aegis = state(20, 0.10)
    expect(closeEnough(l1.derivedStats.hpToMagicDiversionFraction, 0.10), "Level 1 = 10%")
    expect(closeEnough(l16.derivedStats.hpToMagicDiversionFraction, 0.475), "Level 16 = 47.5%")
    expect(closeEnough(l17.derivedStats.hpToMagicDiversionFraction, 0.50), "Level 17 reaches cap")
    expect(closeEnough(l20.derivedStats.hpToMagicDiversionFraction, 0.50), "Level 20 stays capped")
    expect(closeEnough(l20Aegis.derivedStats.hpToMagicDiversionFraction, 0.50),
        "Living Aegis cannot exceed cap")
    expect(closeEnough(l20Aegis.derivedStats.livingAegisHPPerMagic, 1.50),
        "Living Aegis efficiency remains available")
    return #errors == 0, errors
end

-- Existing source files expose lod_rpg_wizard_validate. Preserve the reconciled
-- rebalance validator's unrelated assertions, filtering only its two obsolete
-- >50% expectations, then append the canonical cap checks.
function WizardRules:Validate(ply)
    local errors = {}
    local current
    if priorValidate then
        local _, oldErrors, oldCurrent = priorValidate(self, ply)
        current = oldCurrent
        for _, message in ipairs(oldErrors or {}) do
            if message ~= "Wizard Level-20 innate diversion"
                and message ~= "Living Aegis Level-20 diversion/exchange"
            then
                errors[#errors + 1] = message
            end
        end
    end
    local capOK, capErrors = self:ValidateArcaneCap()
    for _, message in ipairs(capErrors or {}) do errors[#errors + 1] = message end

    local state = IsValid(ply) and LOD.RPGAbilityRules
        and LOD.RPGAbilityRules:ProgressionState(ply) or nil
    local derived = state and state.derivedStats or nil
    current = current or {}
    current.classId = state and state.classId or current.classId or "none"
    current.level = state and state.level or current.level or 0
    current.innate = tonumber(derived and derived.wizardClassHpToMagicDiversionFraction) or 0
    current.feat = tonumber(derived and derived.manaBarrierFeatDiversionFraction) or 0
    current.capstone = tonumber(derived and derived.wizardCapstoneDiversionBonus) or 0
    current.total = tonumber(derived and derived.hpToMagicDiversionFraction) or 0
    current.magic = IsValid(ply) and ply:GetNW2Float("LOD_Magic", 0) or 0
    current.exchange = tonumber(derived and derived.livingAegisHPPerMagic) or 1
    current.boomShift = tonumber(derived and derived.magicBoomThresholdShift) or 0
    return capOK and #errors == 0, errors, current
end

-- Recompute any already-created states when hot-loaded in developer mode.
if Progression and Progression._RecomputeProgressionState then
    for _, ply in ipairs(player.GetAll()) do
        local run = LOD.RunManager
        local ps = run and run.GetPlayerState and run:GetPlayerState(ply) or nil
        local state = ps and ps.progressionState
        if state then Progression:_RecomputeProgressionState(state) end
    end
end
