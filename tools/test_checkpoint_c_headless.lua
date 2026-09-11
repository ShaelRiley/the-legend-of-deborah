-- Finite pure-Lua regression for Checkpoint C deterministic progression + Arcane cap.
unpack = unpack or table.unpack

function math.Clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

function table.Copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = table.Copy(v) end
    return out
end

util = {AddNetworkString = function() end}
net = {Receive = function() end}
concommand = {Add = function() end}
player = {GetAll = function() return {} end}
function IsValid(value) return type(value) == "table" and value.__valid == true end

LOD = {
    RPG = {
        Constants = {HeroMaxLevel = 20},
        Abilities = {"str", "dex", "con", "int", "wis", "cha"},
        Schema = {ProgressionState = {}},
        SystemBootstrap = {},
    },
    CharacterProgressionSystem = {},
    RPGWizardRules = {},
    Seeds = {},
    RNG = {},
}

function LOD.RPG.NewAbilityBlock(value)
    return {str=value, dex=value, con=value, int=value, wis=value, cha=value}
end

function LOD.Seeds.Derive(seed, label)
    local value = tonumber(seed) or 1
    for i = 1, #tostring(label) do
        value = (value * 33 + string.byte(label, i)) % 2147483647
    end
    return value
end

function LOD.RNG.New(seed)
    local state = (tonumber(seed) or 1) % 2147483647
    return {
        Int = function(self, low, high)
            state = (state * 48271) % 2147483647
            return low + (state % (high - low + 1))
        end
    }
end

local CPS = LOD.CharacterProgressionSystem
function CPS:NewProgressionState(actorId, archetypeId, actorType)
    return {
        actorId=actorId, archetypeId=archetypeId, actorType=actorType,
        level=1, classId=nil, featIds={}, contentIds={},
        featAbilityDelta=LOD.RPG.NewAbilityBlock(0),
        effectiveAbilities=LOD.RPG.NewAbilityBlock(10),
        featQualificationAbilities=LOD.RPG.NewAbilityBlock(10),
        derivedStats={},
    }
end
function CPS:_RecomputeProgressionState(state) state.derivedStats = state.derivedStats or {} end
function CPS:_GenerateOrdinaryDraft(ps, state, seed, level) return {level=level} end
function CPS:_GenerateProgressionHitDie(ps, state, seed, level) return {level=level} end
function CPS:_GenerateAutomaticHitDie(state, seed, level) return {level=level} end
function CPS:InitializeHero(run, ps, character) return ps.progressionState end
function CPS:CommitClass() return true end
function CPS:AdvanceHeroToLevel() return true end
function CPS:GenerateMonsterProgression() return nil, "stub" end
function CPS:SyncPlayer() return true end
function CPS:_ApplyPlayerMaxHP() end

local root = assert(arg[1], "repo root required")
dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_magic_progression.lua")
local MagicProgression = assert(LOD.MagicProgression)

local ok, errors = MagicProgression:Validate()
assert(ok, "Magic progression validator failed: " .. table.concat(errors or {}, "; "))

local l1 = CPS:NewProgressionState("ordering-l1", "hero", "hero")
l1.classId = "wizard"
CPS:_GenerateOrdinaryDraft({}, l1, 101, 1)
assert(#l1.magicFormIds == 1, "Level-1 Form must exist before ordinary draft")

local l2 = CPS:NewProgressionState("ordering-l2", "hero", "hero")
l2.classId = "wizard"
l2.level = 2
CPS:_GenerateProgressionHitDie({}, l2, 101, 2)
assert(#l2.magicFormIds == 2, "Wizard Level-2 Form must exist inside per-level transaction")

local auto = CPS:NewProgressionState("ordering-auto", "soldier", "ai")
auto.classId = "wizard"
auto.level = 8
CPS:_GenerateAutomaticHitDie(auto, 202, 8)
assert(#auto.magicFormIds == 3, "automatic Wizard should own Level 1/2/5 Forms by Level 8")
assert(#auto.contentIds == 2, "automatic Wizard should own Level 4/8 Contents by Level 8")

-- Install a minimal pre-cap Wizard implementation so the cap adapter is tested as
-- an actual wrapper, including preservation of Living Aegis efficiency.
function LOD.RPGWizardRules:ApplyDerived(state)
    local derived = state.derivedStats
    derived.wizardClassHpToMagicDiversionFraction = state.classId == "wizard" and 0.575 or 0
    derived.manaBarrierFeatDiversionFraction = derived.manaBarrierFeatDiversionFraction or 0
    derived.wizardCapstoneDiversionBonus = derived.wizardCapstoneDiversionBonus or 0
    derived.hpToMagicDiversionFraction = derived.wizardClassHpToMagicDiversionFraction
        + derived.manaBarrierFeatDiversionFraction + derived.wizardCapstoneDiversionBonus
end
function LOD.RPGWizardRules:Validate()
    return true, {}, {classId="none", level=0}
end

dofile(root .. "/gamemodes/legend_of_deborah/gamemode/lod/sv_wizard_arcane_cap.lua")
local WizardRules = LOD.RPGWizardRules
local capOK, capErrors = WizardRules:ValidateArcaneCap()
assert(capOK, "Arcane cap validator failed: " .. table.concat(capErrors or {}, "; "))
assert(math.abs(WizardRules:ClassDiversionFraction({classId="wizard", level=16}) - 0.475) < 0.00001)
assert(math.abs(WizardRules:ClassDiversionFraction({classId="wizard", level=17}) - 0.50) < 0.00001)
assert(math.abs(WizardRules:ClassDiversionFraction({classId="wizard", level=20}) - 0.50) < 0.00001)

print("Checkpoint C headless regression PASS")
