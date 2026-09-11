function IsValid(value) return type(value) == "table" and value.valid ~= false end
function GetConVar() return nil end
concommand = {Add = function() end}
GM = {EntityTakeDamage = function() end}
LOD = {RPG = {IdentityCatalog = {OrdinaryFeats = {}}}, RPGAbilityRules = {}, RPGStatusElements = {}}
function LOD.RPGAbilityRules:ApplyPlayerDefense() return true end
dofile("./gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_wis_defense_feats.lua")
local ok, errors = LOD.RPG:ValidateCheckpointDWisDefenseFeats()
assert(ok, table.concat(errors or {}, "; "))
print("Checkpoint D WIS defense headless PASS")
