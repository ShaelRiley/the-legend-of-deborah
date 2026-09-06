-- Pure-Lua regression harness for Gate E Batch 13 Pusher and shared push saves.

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
    RPGValidation = {},
    HostileMotionV2 = {}
}

function math.Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end
function table.Copy(source)
    local copy = {}
    for key, value in pairs(source or {}) do copy[key] = value end
    return copy
end

function IsValid() return false end
function GetConVar() return nil end
function CurTime() return 0 end
function ErrorNoHalt(message) io.stderr:write(message) end
concommand = {Add = function() end}
hook = {Add = function() end}
util = {AddNetworkString = function() end}

function LOD.RPG.FeatEffectSystem:ApplyDerived() end
function LOD.RPGAbilityRules:Derived(actor) return actor and actor.derivedStats or nil end
function LOD.RPGAbilityRules:ProgressionState(actor) return actor and actor.progressionState or nil end
function LOD.CharacterProgressionSystem:BuildClientSnapshot() return {} end
function LOD.RPGValidation:Run() return true, {} end

assert(loadfile(
    "gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_e_pusher.lua"))()
assert(loadfile(
    "gamemodes/legend_of_deborah/gamemode/lod/sv_pushback.lua"))()

local effects = LOD.RPG.FeatEffectSystem
local ok, errors = effects:ValidatePusherFamily()
assert(ok, table.concat(errors or {}, "; "))
ok, errors = LOD.Pushback:ValidateSharedPushSave()
assert(ok, table.concat(errors or {}, "; "))

local derived = {}
effects:ApplyDerived({featIds = {
    "STR_KNOCKBACK_1", "STR_KNOCKBACK_2", "STR_KNOCKBACK_3"
}}, derived)
assert(derived.pusherRank == 3)
assert(derived.weaponKnockbackProcChance == 0.75)
assert(derived.weaponKnockbackProcDistance == 168)
assert(derived.pusherProcTargetCooldownSeconds == 0.50)
assert(derived.wallSlamDieSides == 12)
assert(derived.wallSlamExplodes and not derived.wallSlamClassExplosionImmune)

print("gate_e_batch_13_pusher PASS")
