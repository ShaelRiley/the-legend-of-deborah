function IsValid(value) return type(value) == "table" and value.valid ~= false end
function GetConVar() return nil end
concommand = {Add = function() end}; hook = {Add = function() end}
LOD = {RPG = {IdentityCatalog = {OrdinaryFeats = {}}}, RPGAbilityRules = {}, RPGStatusElements = {}}
dofile("./gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_aura_burst_feats.lua")
local ok, errors = LOD.RPG:ValidateCheckpointDAuraBurstFeats()
assert(ok, table.concat(errors or {}, "; "))
assert(LOD.RPG:CheckpointDAuraBurstProfile({featIds = {"CHA_AURA_BURST_1", "CHA_RADIANCE_2"}}) == 1)
print("Checkpoint D Aura Burst headless PASS")
