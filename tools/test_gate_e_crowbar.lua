-- Pure-Lua regression harness for Gate E Batch 14 Crowbar-family feats.

LOD = {
    Config = {Maze = {CellSize = 384}},
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
function isstring(value) return type(value) == "string" end
function GetConVar() return nil end
function CurTime() return 0 end
function ErrorNoHalt(message) io.stderr:write(message) end
concommand = {Add = function() end}
hook = {Add = function() end}
util = {AddNetworkString = function() end}

function LOD.RPG.FeatEffectSystem:ApplyDerived() end
function LOD.RPGAbilityRules:Derived(actor) return actor and actor.derivedStats or nil end
function LOD.RPGAbilityRules:ProgressionState(actor)
    return actor and actor.progressionState or actor
end
function LOD.CharacterProgressionSystem:BuildClientSnapshot() return {} end
function LOD.RPGValidation:Run() return true, {} end

assert(loadfile(
    "gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_e_pusher.lua"))()
assert(loadfile(
    "gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_e_crowbar.lua"))()
assert(loadfile(
    "gamemodes/legend_of_deborah/gamemode/lod/sv_pushback.lua"))()

local effects = LOD.RPG.FeatEffectSystem
local ok, errors = effects:ValidateCrowbarFamily()
assert(ok, table.concat(errors or {}, "; "))
ok, errors = LOD.Pushback:ValidateSharedPushSave()
assert(ok, table.concat(errors or {}, "; "))

local derived = {}
effects:ApplyDerived({featIds = {
    "STR_CROWBAR_D6", "STR_CROWBAR_D12", "STR_CROWBAR_CRUSH",
    "WIS_HERO_OF_LEGEND", "STR_KNOCKBACK_1", "STR_KNOCKBACK_2",
    "STR_KNOCKBACK_3"
}}, derived)
assert(derived.crowbarDamageRank == 2)
assert(derived.crowbarDamageDieSides == 12)
assert(derived.crowbarPushDistance == 168)
assert(derived.crowbarWallSlamBonusDice == 1)
assert(derived.heroOfLegendPulseEnabled)
assert(derived.heroOfLegendPulseRangeCells == 1)
assert(effects:HeroOfLegendRangeCells(-2) == 1)
assert(effects:HeroOfLegendRangeCells(0) == 1)
assert(effects:HeroOfLegendRangeCells(1) == 1)
assert(effects:HeroOfLegendRangeCells(3) == 3)
local hero = LOD.RPG.IdentityCatalog.OrdinaryFeats.WIS_HERO_OF_LEGEND
assert(hero and hero.abilityRequirements.wis == 15)
assert(LOD.RPG.IdentityCatalog.OrdinaryFeats.STR_HERO_OF_LEGEND == nil)
local heroDamage = effects:HeroOfLegendDamageProfile({})
assert(heroDamage.magicDamage and heroDamage.nonElemental)
assert(effects.CrowbarConfig.pulseSpeed == 620)
assert(derived.pusherRank == 3 and derived.weaponKnockbackProcDistance == 168)

local profile = LOD.Pushback:WallCrushProfile(derived, {crowbarPush = true})
assert(profile.count == 2 and profile.sides == 12)
assert(profile.classExplosionImmune == false)
assert(effects:ResolveCrowbarPushRequest(
    derived.crowbarPushDistance, derived.weaponKnockbackProcDistance) == 336)

print("gate_e_batch_14_crowbar PASS")
