function IsValid(value) return type(value) == "table" and value.valid ~= false end
function GetConVar() return nil end
concommand = {Add = function() end}
LOD = {RPG = {IdentityCatalog = {OrdinaryFeats = {}}}}
dofile("./gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_checkpoint_d_astral_reach_feat.lua")

local feat = LOD.RPG.IdentityCatalog.OrdinaryFeats.WIS_ASTRAL_REACH
assert(feat.effectParams.cells == 2 and feat.requiredCapabilityTags[1] == "magic_form_owned")
local ok, errors = LOD.RPG:ValidateCheckpointDAstralReachFeat()
assert(ok, table.concat(errors or {}, "; "))
print("Checkpoint D Astral Reach headless PASS")
