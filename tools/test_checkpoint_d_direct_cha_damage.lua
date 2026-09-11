function IsValid(value) return type(value) == "table" and value.valid ~= false end
function GetConVar() return nil end
concommand = {Add = function() end}
LOD = {RPG = {IdentityCatalog = {OrdinaryFeats = {}}, FeatEffectSystem = {}}, RPGAbilityRules = {}}
function LOD.RPG.FeatEffectSystem:RegisterChaModDamageSource() end
function LOD.RPGAbilityRules:ResolveDamageContract() return 5 end
dofile("./gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_direct_cha_damage_feats.lua")
local ok, errors = LOD.RPG:ValidateCheckpointDDirectChaDamageFeats()
assert(ok, table.concat(errors or {}, "; "))
local actor = {valid = true}
function LOD.RPGAbilityRules:ProgressionState() return {featIds = {"CHA_SELF_ACTUALIZATION", "CON_GLOW_UP"}} end
function LOD.RPGAbilityRules:Derived() return {chaMod = 3, conMod = 2} end
assert(LOD.RPGAbilityRules:ResolveDamageContract({}, actor, {}, {magic = true}) == 10,
    "Self-Actualization and Glow Up apply once after source resolution")
assert(LOD.RPGAbilityRules:ResolveDamageContract({}, actor, {}, {magic = true, statusDamage = true}) == 5,
    "status damage does not receive direct CHA riders")
print("Checkpoint D direct CHA damage headless PASS")
