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
assert(derived.steadfastHitStunMultiplier == nil and derived.steadfastPushMultiplier == nil)
assert(derived.magicPushMultiplier == nil, "removed Force Multiplier ownership is inert")
assert(derived.manaSpringRegenMultiplier == 1.22)
for _,id in ipairs({"CON_STEADFAST","WIS_FORCEFUL_MAGIC"}) do
 assert(LOD.RPG.IdentityCatalog.OrdinaryFeats[id]==nil,"removed feat is not registered")
end
local defender = {derivedStats = derived}
assert(LOD.RPGAbilityRules:HitStunMultiplier(nil, defender)==1.2,"ordinary resistance unchanged")
assert(effects:ResolvePushDistance(100,{}, {},{magicPush=true})==100)
assert(effects:ResolvePushDistance(100,{fighterCapstoneOutgoingPushMultiplier=2},
 {fighterCapstoneIncomingPushMultiplier=.5},{magicPush=true})==100,"retained shared Push modifiers compose")

print("gate_e_batch_11_control_magic PASS")
