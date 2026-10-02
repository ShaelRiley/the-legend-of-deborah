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

-- Position must never be requested by this feat; only the underlying legal
-- attack adapter owns range. Both nearby and million-unit legal target events
-- receive the same once-per-target flat bonus, with one originating cooldown.
dofile('gamemodes/legend_of_deborah/gamemode/lod/sh_rng.lua')
local now=100;function CurTime() return now end
timer={Simple=function() end}
function actor:EntIndex() return 1 end
function actor:GetPos() error('Aggressive Personality has no spatial gate') end
LOD.RPGAbilityRules.ProgressionState=function() return {featIds={'CHA_AGGRESSIVE_PERSONALITY'}} end
local contract={};local rules=LOD.RPGAbilityRules
for _,distance in ipairs({1,1000000}) do
 local target={valid=true,distance=distance,GetPos=function() error('no radius or cell query allowed') end}
 assert(rules:ResolveDamageContract(contract,actor,target,{physical=true})==8,'range-independent +3 CHA')
end
LOD.RPG:ObserveDirectChaDamage(contract,8);LOD.RPG:FinishAggressiveAttack(contract,actor)
assert(actor.LODCheckpointDAggressiveReadyAt>=101 and actor.LODCheckpointDAggressiveReadyAt<=103)
assert(rules:ResolveDamageContract({},actor,{}, {physical=true})==5,'cooldown unchanged')
now=actor.LODCheckpointDAggressiveReadyAt
assert(rules:ResolveDamageContract({},actor,{}, {physical=true})==8,'ready again at sealed deadline')
print('AGGRESSIVE_RANGE_PASS: identical nearby/very-long legal attack contribution, no position/cell/radius access, original single sealed cooldown')
