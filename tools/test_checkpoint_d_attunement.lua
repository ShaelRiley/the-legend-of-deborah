function IsValid(value) return type(value) == "table" and value.valid ~= false end
function GetConVar() return nil end
concommand = {Add = function() end}
LOD = {RPG = {IdentityCatalog = {OrdinaryFeats = {}}}}
dofile("./gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_attunement_feat.lua")
local ok, errors = LOD.RPG:ValidateCheckpointDAttunementFeat()
assert(ok, table.concat(errors or {}, "; "))
print("Checkpoint D Attunement headless PASS")
