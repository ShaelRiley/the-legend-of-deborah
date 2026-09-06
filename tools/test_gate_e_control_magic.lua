-- Pure-Lua regression harness for Gate E Batch 11. It loads the production feat
-- module with only the small Garry's Mod surface needed by its finite validator.

LOD = {
    RPG = {
        IdentityCatalog = {OrdinaryFeats = {}},
        FeatEffectSystem = {},
        Schema = {DerivedStats = {}},
        SystemBootstrap = {},
        ImplementationGate = "E",
        GameplayEnabled = true
    },
    RPGAbilityRules = {},
    CharacterProgressionSystem = {},
    RPGValidation = {}
}

function math.Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

function IsValid() return false end
function GetConVar() return nil end
function ErrorNoHalt(message) io.stderr:write(message) end
concommand = {Add = function() end}

function LOD.RPG.FeatEffectSystem:ApplyDerived() end
function LOD.RPGAbilityRules:HitStunMultiplier() return 1.2 end
function LOD.RPGAbilityRules:Derived(actor) return actor and actor.derivedStats or nil end
function LOD.RPGAbilityRules:ProgressionState() return nil end
function LOD.CharacterProgressionSystem:BuildClientSnapshot() return {} end
function LOD.RPGValidation:Run() return true, {} end

assert(loadfile(
    "gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_e_control_magic.lua"))()

local effects = LOD.RPG.FeatEffectSystem
local ok, errors = effects:ValidateControlMagicFamilies()
assert(ok, table.concat(errors or {}, "; "))

local derived = {}
effects:ApplyDerived({featIds = {
    "CON_STEADFAST", "WIS_FORCEFUL_MAGIC", "INT_MANA_SPRING"
}}, derived)
assert(derived.steadfastHitStunMultiplier == 0.75)
assert(derived.steadfastPushMultiplier == 0.75)
assert(derived.magicPushMultiplier == 1.25)
assert(derived.manaSpringRegenMultiplier == 1.50)

local defender = {derivedStats = derived}
assert(math.abs(LOD.RPGAbilityRules:HitStunMultiplier(nil, defender) - 0.9) < 0.0001)
assert(math.abs(LOD.RPGAbilityRules:HitStunMultiplier(
    nil, defender, {ignoreResistance = true}) - 1.2) < 0.0001)

print("gate_e_batch_11_control_magic PASS")
