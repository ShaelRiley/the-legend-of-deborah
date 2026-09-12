function IsValid(value) return type(value) == "table" and value.valid ~= false end
function GetConVar() return nil end
concommand = {Add = function() end}
LOD = {RPG = {IdentityCatalog = {OrdinaryFeats = {}}}}
dofile("./gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_panic_feat.lua")
local ok, errors = LOD.RPG:ValidateCheckpointDPanic()
assert(ok, table.concat(errors or {}, "; "))
print("Checkpoint D Panic feat headless PASS")
