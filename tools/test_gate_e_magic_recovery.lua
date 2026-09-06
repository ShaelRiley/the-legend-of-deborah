-- Pure-Lua regression harness for Gate E Batch 12 Magic recovery.

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
function LOD.RPGAbilityRules:Derived(actor) return actor and actor.derivedStats or nil end
function LOD.RPGAbilityRules:ProgressionState(actor) return actor and actor.progressionState or nil end
function LOD.CharacterProgressionSystem:BuildClientSnapshot() return {} end
function LOD.RPGValidation:Run() return true, {} end

assert(loadfile(
    "gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_e_magic_recovery.lua"))()

local effects = LOD.RPG.FeatEffectSystem
local ok, errors = effects:ValidateMagicRecoveryFamilies()
assert(ok, table.concat(errors or {}, "; "))

local derived = {}
effects:ApplyDerived({featIds = {"INT_FEEDBACK_LOOP", "INT_ARC_RECOVERY"}}, derived)
assert(derived.feedbackLoopEnabled and derived.feedbackLoopPerCastCap == 6)
assert(derived.arcRecoveryEnabled and derived.arcRecoveryMagic == 5)

local actor = {progressionState = {featIds = {"INT_FEEDBACK_LOOP", "INT_ARC_RECOVERY"}}}
local resource = {magic = 70, arcRecoveryReadyAt = 0}
local restored, used = effects:ApplyFeedbackLoop(actor, resource, 8, 0)
assert(restored == 6 and used == 6 and resource.magic == 76)
restored = effects:ApplyArcRecovery(actor, resource, true, 10)
assert(restored == 5 and resource.magic == 81 and resource.arcRecoveryReadyAt == 12)
restored = effects:ApplyArcRecovery(actor, resource, true, 11)
assert(restored == 0 and resource.magic == 81)

print("gate_e_batch_12_magic_recovery PASS")
